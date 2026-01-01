//
//  FirebaseService.swift
//  Chronicles
//
//  Firebase/Firestore service for data operations
//

import Foundation
import Combine
import FirebaseFirestore
import os

// MARK: - Firebase Service

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    // MARK: - Published Properties
    
    @Published var journals: [Journal] = []
    @Published var entries: [JournalEntry] = []
    @Published var templates: [JournalTemplate] = []
    @Published var prompts: [JournalPrompt] = []
    @Published var conversations: [AIConversation] = []
    @Published var isLoading = false
    @Published var isLoadingPrompts = true
    @Published var isDataLoaded = false
    
    private let db = Firestore.firestore()
    private var promptsListener: ListenerRegistration?
    private var lastPromptDocument: DocumentSnapshot?
    private let promptsBatchSize = 50
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Timeout Configuration
    
    private let defaultTimeout: TimeInterval = 5.0
    private let longTimeout: TimeInterval = 10.0
    private let maxRetries: Int = 3

    // MARK: - Debug Instrumentation (agent)

    private let agentLogger = Logger(subsystem: "chronicles.agent", category: "agentLog")

    /// Minimal debug logger for runtime evidence (prints JSON to Xcode console in DEBUG builds).
    private func agentLog(
        hypothesisId: String,
        location: String,
        message: String,
        data: [String: Any] = [:],
        runId: String = "run1"
    ) {
        #if DEBUG
        var payload: [String: Any] = [
            "sessionId": "debug-session",
            "runId": runId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "timestamp": Date().timeIntervalSince1970 * 1000
        ]
        payload["data"] = data
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
            agentLogger.info("\(jsonString, privacy: .public)")
            agentLogger.notice("\(jsonString, privacy: .public)")
            NSLog("%@", jsonString)
        }
        #endif
    }

    /// Firestore missing-index errors are typically FAILED_PRECONDITION (code 9).
    private func isMissingIndexError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let msg = nsError.localizedDescription.lowercased()
        if msg.contains("requires an index") || msg.contains("create it here") {
            return true
        }
        // Best-effort check for Firestore FAILED_PRECONDITION
        return nsError.code == 9
    }
    
    private init() {
        // Set up prompts listener
        setupPromptsListener()
        // Listen for user authentication to load data
        setupAuthListener()
    }
    
    // MARK: - Auth Listener (Auto-load data when user logs in)
    
    private func setupAuthListener() {
        AuthService.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self, let user = user else { return }
                
                // Only load if not already loaded
                if !self.isDataLoaded {
                    Task {
                        await self.loadUserData(userId: user.id)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load All User Data
    
    /// Load all user data (journals, entries) when user authenticates
    /// This fixes the critical bug where data wasn't loading on app restart
    func loadUserData(userId: String) async {
        guard !userId.isEmpty else { return }
        
        await MainActor.run {
            self.isLoading = true
        }

        // #region agent log
        agentLog(
            hypothesisId: "LD1",
            location: "FirebaseService.swift:loadUserData",
            message: "start",
            data: [
                "userIdLength": userId.count,
                "networkConnected": NetworkMonitor.shared.isConnected
            ]
        )
        // #endregion
        
        // Load journals and entries in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    let journals = try await self.fetchJournals(userId: userId)
                    print("[FirebaseService] Loaded journals for user: \(userId)")
                    // #region agent log
                    self.agentLog(
                        hypothesisId: "LD1",
                        location: "FirebaseService.swift:loadUserData",
                        message: "journalsLoaded",
                        data: [
                            "count": journals.count
                        ]
                    )
                    // #endregion
                } catch {
                    print("[FirebaseService] Failed to load journals: \(error.localizedDescription)")
                    let nsError = error as NSError
                    // #region agent log
                    self.agentLog(
                        hypothesisId: "LD1",
                        location: "FirebaseService.swift:loadUserData",
                        message: "journalsFailed",
                        data: [
                            "domain": nsError.domain,
                            "code": nsError.code,
                            "missingIndex": self.isMissingIndexError(error),
                            "permissionDenied": nsError.localizedDescription.lowercased().contains("missing or insufficient permissions")
                        ]
                    )
                    // #endregion
                }
            }
            
            group.addTask {
                do {
                    let entries = try await self.fetchEntries(userId: userId, journalId: nil)
                    print("[FirebaseService] Loaded entries for user: \(userId)")
                    // #region agent log
                    self.agentLog(
                        hypothesisId: "LD1",
                        location: "FirebaseService.swift:loadUserData",
                        message: "entriesLoaded",
                        data: [
                            "count": entries.count
                        ]
                    )
                    // #endregion
                } catch {
                    print("[FirebaseService] Failed to load entries: \(error.localizedDescription)")
                    let nsError = error as NSError
                    // #region agent log
                    self.agentLog(
                        hypothesisId: "LD1",
                        location: "FirebaseService.swift:loadUserData",
                        message: "entriesFailed",
                        data: [
                            "domain": nsError.domain,
                            "code": nsError.code,
                            "missingIndex": self.isMissingIndexError(error),
                            "permissionDenied": nsError.localizedDescription.lowercased().contains("missing or insufficient permissions")
                        ]
                    )
                    // #endregion
                }
            }
        }
        
        await MainActor.run {
            self.isLoading = false
            self.isDataLoaded = true
        }
        
        print("[FirebaseService] User data loaded successfully")

        // #region agent log
        agentLog(
            hypothesisId: "LD1",
            location: "FirebaseService.swift:loadUserData",
            message: "done",
            data: [
                "journalsCount": journals.count,
                "entriesCount": entries.count
            ]
        )
        // #endregion
    }
    
    /// Reset data when user logs out
    func clearUserData() {
        Task { @MainActor in
            self.journals = []
            self.entries = []
            self.conversations = []
            self.isDataLoaded = false
        }
    }
    
    // MARK: - Prompts Listener
    
    private func setupPromptsListener() {
        // Listen for initial prompts load
        Task {
            await loadInitialPrompts()
        }
    }
    
    // MARK: - Journal Operations
    
    func fetchJournals(userId: String) async throws -> [Journal] {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            print("[FirebaseService] Offline - using cached journals")
            // #region agent log
            agentLog(
                hypothesisId: "J1",
                location: "FirebaseService.swift:fetchJournals",
                message: "offlineReturn",
                data: [
                    "cachedCount": journals.count
                ]
            )
            // #endregion
            return journals
        }

        // #region agent log
        agentLog(
            hypothesisId: "J1",
            location: "FirebaseService.swift:fetchJournals",
            message: "start",
            data: [
                "userIdLength": userId.count,
                "useOrderByOrder": true
            ]
        )
        // #endregion
        
        do {
            let snapshot = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
                try await self.db.collection("journals")
                    .whereField("userId", isEqualTo: userId)
                    .order(by: "order")
                    .getDocuments()
            }
        
            let fetchedJournals = snapshot.documents.compactMap { doc -> Journal? in
                let data = doc.data()
                
                let createdAt: Date
                if let timestamp = data["createdAt"] as? Timestamp {
                    createdAt = timestamp.dateValue()
                } else {
                    createdAt = Date()
                }
                
                let updatedAt: Date
                if let timestamp = data["updatedAt"] as? Timestamp {
                    updatedAt = timestamp.dateValue()
                } else {
                    updatedAt = Date()
                }
                
                let lastEntryDate: Date?
                if let timestamp = data["lastEntryDate"] as? Timestamp {
                    lastEntryDate = timestamp.dateValue()
                } else {
                    lastEntryDate = nil
                }
                
                return Journal(
                    id: doc.documentID,
                    userId: data["userId"] as? String ?? userId,
                    name: data["name"] as? String ?? "Untitled",
                    color: data["color"] as? String ?? "#414141",
                    order: data["order"] as? Int ?? 0,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    entryCount: data["entryCount"] as? Int ?? 0,
                    lastEntryDate: lastEntryDate
                )
            }
            
            await MainActor.run {
                self.journals = fetchedJournals
            }
            
            // #region agent log
            agentLog(
                hypothesisId: "J1",
                location: "FirebaseService.swift:fetchJournals",
                message: "success",
                data: [
                    "returnedCount": fetchedJournals.count
                ]
            )
            // #endregion
            
            return fetchedJournals
        } catch {
            let nsError = error as NSError
            let missingIndex = isMissingIndexError(error)
            let permissionDenied = nsError.localizedDescription.lowercased().contains("missing or insufficient permissions")
            
            // #region agent log
            agentLog(
                hypothesisId: "J1",
                location: "FirebaseService.swift:fetchJournals",
                message: "failed",
                data: [
                    "domain": nsError.domain,
                    "code": nsError.code,
                    "missingIndex": missingIndex,
                    "permissionDenied": permissionDenied
                ]
            )
            // #endregion

            // If the composite index isn't created yet, fallback to a query that doesn't require it.
            if missingIndex {
                let fallbackSnapshot = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
                    try await self.db.collection("journals")
                        .whereField("userId", isEqualTo: userId)
                        .getDocuments()
                }
                
                let fetchedJournals = fallbackSnapshot.documents.compactMap { doc -> Journal? in
                    let data = doc.data()
                    
                    let createdAt: Date
                    if let timestamp = data["createdAt"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    } else {
                        createdAt = Date()
                    }
                    
                    let updatedAt: Date
                    if let timestamp = data["updatedAt"] as? Timestamp {
                        updatedAt = timestamp.dateValue()
                    } else {
                        updatedAt = Date()
                    }
                    
                    let lastEntryDate: Date?
                    if let timestamp = data["lastEntryDate"] as? Timestamp {
                        lastEntryDate = timestamp.dateValue()
                    } else {
                        lastEntryDate = nil
                    }
                    
                    return Journal(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? userId,
                        name: data["name"] as? String ?? "Untitled",
                        color: data["color"] as? String ?? "#414141",
                        order: data["order"] as? Int ?? 0,
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        entryCount: data["entryCount"] as? Int ?? 0,
                        lastEntryDate: lastEntryDate
                    )
                }
                
                // Sort in memory (stable fallback; best performance is still to create the index)
                let sorted = fetchedJournals.sorted { $0.order < $1.order }
                
                await MainActor.run {
                    self.journals = sorted
                }
                
                // #region agent log
                agentLog(
                    hypothesisId: "J1",
                    location: "FirebaseService.swift:fetchJournals",
                    message: "fallbackSuccess",
                    data: [
                        "fetchedCount": fetchedJournals.count,
                        "returnedCount": sorted.count
                    ]
                )
                // #endregion
                
                return sorted
            }
            
            throw error
        }
    }
    
    func createJournal(_ journal: Journal) async throws {
        // #region agent log
        agentLog(
            hypothesisId: "J2",
            location: "FirebaseService.swift:createJournal",
            message: "start",
            data: [
                "userIdIsEmpty": journal.userId.isEmpty,
                "nameLength": journal.name.count,
                "order": journal.order
            ]
        )
        // #endregion
        
        let data: [String: Any] = [
            "userId": journal.userId,
            "name": journal.name,
            "color": journal.color,
            "order": journal.order,
            "createdAt": Timestamp(date: journal.createdAt),
            "updatedAt": Timestamp(date: journal.updatedAt),
            "entryCount": journal.entryCount
        ]
        
        try await db.collection("journals").document(journal.id).setData(data)
        
        await MainActor.run {
            journals.append(journal)
        }

        // #region agent log
        agentLog(
            hypothesisId: "J2",
            location: "FirebaseService.swift:createJournal",
            message: "success",
            data: [
                "localJournalsCount": journals.count
            ]
        )
        // #endregion
    }
    
    func updateJournal(_ journal: Journal) async throws {
        var data: [String: Any] = [
            "name": journal.name,
            "color": journal.color,
            "order": journal.order,
            "updatedAt": Timestamp(date: Date()),
            "entryCount": journal.entryCount
        ]
        
        if let lastEntryDate = journal.lastEntryDate {
            data["lastEntryDate"] = Timestamp(date: lastEntryDate)
        }
        
        try await db.collection("journals").document(journal.id).updateData(data)
        
        await MainActor.run {
            if let index = journals.firstIndex(where: { $0.id == journal.id }) {
                journals[index] = journal
            }
        }
    }
    
    func deleteJournal(_ journalId: String) async throws {
        // Delete journal from Firestore
        try await db.collection("journals").document(journalId).delete()
        
        // Delete all entries for this journal
        let entriesSnapshot = try await db.collection("entries")
            .whereField("journalId", isEqualTo: journalId)
            .getDocuments()
        
        for doc in entriesSnapshot.documents {
            try await doc.reference.delete()
        }
        
        await MainActor.run {
            journals.removeAll { $0.id == journalId }
            entries.removeAll { $0.journalId == journalId }
        }
    }
    
    func reorderJournals(_ journals: [Journal]) async throws {
        // Update order for each journal in Firestore
        for (index, journal) in journals.enumerated() {
            try await db.collection("journals").document(journal.id).updateData([
                "order": index,
                "updatedAt": Timestamp(date: Date())
            ])
        }
        
        await MainActor.run {
            self.journals = journals
        }
    }
    
    // MARK: - Entry Operations
    
    func fetchEntries(userId: String, journalId: String? = nil) async throws -> [JournalEntry] {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            print("[FirebaseService] Offline - using cached entries")
            if let journalId = journalId {
                return entries.filter { $0.journalId == journalId }
            }
            return entries
        }

        // #region agent log
        agentLog(
            hypothesisId: "IDX1",
            location: "FirebaseService.swift:fetchEntries",
            message: "start",
            data: [
                "hasJournalId": journalId != nil,
                "useOrderByCreatedAt": true
            ]
        )
        // #endregion
        
        do {
            var query: Query = db.collection("entries")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
            
            if let journalId = journalId {
                query = query.whereField("journalId", isEqualTo: journalId)
            }
            
            let snapshot = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
                try await query.getDocuments()
            }
            
            let fetchedEntries = snapshot.documents.compactMap { doc -> JournalEntry? in
                return parseEntryFromDocument(doc)
            }
            
            await MainActor.run {
                if journalId == nil {
                    self.entries = fetchedEntries
                }
            }
            
            // #region agent log
            agentLog(
                hypothesisId: "IDX1",
                location: "FirebaseService.swift:fetchEntries",
                message: "success",
                data: [
                    "returnedCount": fetchedEntries.count,
                    "usedFallback": false
                ]
            )
            // #endregion
            
            return fetchedEntries
        } catch {
            let nsError = error as NSError
            let missingIndex = isMissingIndexError(error)
            
            // #region agent log
            agentLog(
                hypothesisId: "IDX1",
                location: "FirebaseService.swift:fetchEntries",
                message: "orderedQueryFailed",
                data: [
                    "domain": nsError.domain,
                    "code": nsError.code,
                    "missingIndex": missingIndex
                ]
            )
            // #endregion
            
            // If the composite index isn't created yet, fallback to a query that doesn't require it.
            if missingIndex {
                // Fetch all user entries without orderBy (single-field index), then filter/sort in memory.
                let fallbackSnapshot = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
                    try await self.db.collection("entries")
                        .whereField("userId", isEqualTo: userId)
                        .getDocuments()
                }
                
                let allFetched = fallbackSnapshot.documents.compactMap { doc -> JournalEntry? in
                    return parseEntryFromDocument(doc)
                }
                
                let filtered = journalId == nil ? allFetched : allFetched.filter { $0.journalId == journalId }
                let sorted = filtered.sorted { $0.createdAt > $1.createdAt }
                
                await MainActor.run {
                    if journalId == nil {
                        self.entries = sorted
                    }
                }
                
                // #region agent log
                agentLog(
                    hypothesisId: "IDX1",
                    location: "FirebaseService.swift:fetchEntries",
                    message: "fallbackSuccess",
                    data: [
                        "fetchedCount": allFetched.count,
                        "returnedCount": sorted.count
                    ]
                )
                // #endregion
                
                return sorted
            }
            
            throw error
        }
    }
    
    func fetchEntriesForDate(userId: String, date: Date) async throws -> [JournalEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Check network availability - use cached entries if offline
        guard NetworkMonitor.shared.isConnected else {
            print("[FirebaseService] Offline - filtering cached entries for date")
            return entries.filter { entry in
                entry.createdAt >= startOfDay && entry.createdAt < endOfDay
            }.sorted { $0.createdAt > $1.createdAt }
        }
        
        // Note: Removed .order(by:) to avoid Firestore index conflict with range filters
        // Sorting in memory is efficient for a single day's entries
        let snapshot = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
            try await self.db.collection("entries")
                .whereField("userId", isEqualTo: userId)
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("createdAt", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()
        }
        
        let fetchedEntries = snapshot.documents.compactMap { doc -> JournalEntry? in
            return parseEntryFromDocument(doc)
        }
        
        return fetchedEntries.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func parseEntryFromDocument(_ doc: DocumentSnapshot) -> JournalEntry? {
        guard let data = doc.data() else { return nil }
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let updatedAt: Date
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }
        
        let inputMethodString = data["inputMethod"] as? String ?? "write"
        let inputMethod = JournalEntry.InputMethod(rawValue: inputMethodString) ?? .write
        
        return JournalEntry(
            id: doc.documentID,
            userId: data["userId"] as? String ?? "",
            journalId: data["journalId"] as? String ?? "",
            templateId: data["templateId"] as? String,
            promptId: data["promptId"] as? String,
            title: data["title"] as? String ?? "Untitled",
            content: data["content"] as? String ?? "",
            createdAt: createdAt,
            updatedAt: updatedAt,
            inputMethod: inputMethod,
            mood: data["mood"] as? String,
            wordCount: data["wordCount"] as? Int ?? 0
        )
    }
    
    func createEntry(_ entry: JournalEntry) async throws {
        var data: [String: Any] = [
            "userId": entry.userId,
            "journalId": entry.journalId,
            "title": entry.title,
            "content": entry.content,
            "createdAt": Timestamp(date: entry.createdAt),
            "updatedAt": Timestamp(date: entry.updatedAt),
            "inputMethod": entry.inputMethod.rawValue,
            "wordCount": entry.wordCount
        ]
        
        if let templateId = entry.templateId {
            data["templateId"] = templateId
        }
        if let promptId = entry.promptId {
            data["promptId"] = promptId
        }
        if let mood = entry.mood {
            data["mood"] = mood
        }
        
        try await db.collection("entries").document(entry.id).setData(data)
        
        // Update journal entry count in Firestore
        try await db.collection("journals").document(entry.journalId).updateData([
            "entryCount": FieldValue.increment(Int64(1)),
            "lastEntryDate": Timestamp(date: entry.createdAt)
        ])
        
        await MainActor.run {
            entries.insert(entry, at: 0)
            
            if let index = journals.firstIndex(where: { $0.id == entry.journalId }) {
                journals[index].entryCount += 1
                journals[index].lastEntryDate = entry.createdAt
            }
        }
    }
    
    func updateEntry(_ entry: JournalEntry) async throws {
        var data: [String: Any] = [
            "title": entry.title,
            "content": entry.content,
            "updatedAt": Timestamp(date: Date()),
            "wordCount": entry.wordCount
        ]
        
        if let mood = entry.mood {
            data["mood"] = mood
        }
        
        try await db.collection("entries").document(entry.id).updateData(data)
        
        await MainActor.run {
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = entry
            }
        }
    }
    
    func deleteEntry(_ entryId: String) async throws {
        // Get the entry first to update journal count
        let entry = entries.first(where: { $0.id == entryId })
        
        // Delete from Firestore
        try await db.collection("entries").document(entryId).delete()
        
        // Update journal entry count in Firestore
        if let entry = entry {
            try await db.collection("journals").document(entry.journalId).updateData([
                "entryCount": FieldValue.increment(Int64(-1))
            ])
        }
        
        await MainActor.run {
            if let entry = entries.first(where: { $0.id == entryId }) {
                if let index = journals.firstIndex(where: { $0.id == entry.journalId }) {
                    journals[index].entryCount = max(0, journals[index].entryCount - 1)
                }
            }
            entries.removeAll { $0.id == entryId }
        }
    }
    
    func searchEntries(query: String, userId: String) async throws -> [JournalEntry] {
        let lowercaseQuery = query.lowercased()
        return entries.filter {
            $0.title.lowercased().contains(lowercaseQuery) ||
            $0.content.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Template Operations
    
    func fetchTemplates(userId: String, journalId: String? = nil) async throws -> [JournalTemplate] {
        if let journalId = journalId {
            return templates.filter { $0.journalId == journalId || $0.isBuiltIn }
        }
        return templates
    }
    
    func createTemplate(_ template: JournalTemplate) async throws {
        await MainActor.run {
            templates.append(template)
        }
    }
    
    func updateTemplate(_ template: JournalTemplate) async throws {
        await MainActor.run {
            if let index = templates.firstIndex(where: { $0.id == template.id }) {
                templates[index] = template
            }
        }
    }
    
    func deleteTemplate(_ templateId: String) async throws {
        await MainActor.run {
            templates.removeAll { $0.id == templateId }
        }
    }
    
    // MARK: - Prompt Operations
    
    /// Batch fetch all user likes in one query (instead of N+1 queries)
    private func fetchUserLikedPromptIds() async -> Set<String> {
        guard let userId = AuthService.shared.currentUser?.id else {
            return []
        }
        
        do {
            let snapshot = try await db.collection("userLikes")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            // Extract prompt IDs from the documents
            let likedIds = snapshot.documents.compactMap { doc -> String? in
                return doc.data()["promptId"] as? String
            }
            
            return Set(likedIds)
        } catch {
            print("Error fetching user likes: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Load initial batch of prompts from Firestore with timeout
    private func loadInitialPrompts() async {
        await MainActor.run {
            self.isLoadingPrompts = true
        }
        
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            print("[FirebaseService] Offline - using sample prompts")
            await MainActor.run {
                self.prompts = JournalPrompt.samples
                self.isLoadingPrompts = false
            }
            return
        }
        
        do {
            // STEP 1: Batch fetch all user likes in ONE query
            let likedPromptIds = await fetchUserLikedPromptIds()
            
            // STEP 2: Fetch ALL prompts in ONE query with timeout
            let query = db.collection("prompts")
            let snapshot = try await withTimeout(seconds: longTimeout) {
                try await query.getDocuments()
            }
            
            // STEP 3: Parse prompts using the Set for O(1) lookup (no more N+1!)
            var fetchedPrompts: [JournalPrompt] = []
            for doc in snapshot.documents {
                if let prompt = parsePromptFromDocument(doc, likedPromptIds: likedPromptIds) {
                    fetchedPrompts.append(prompt)
                }
            }
            
            // Shuffle to mix questions and statements randomly
            fetchedPrompts.shuffle()
            
            await MainActor.run {
                self.prompts = fetchedPrompts
                self.lastPromptDocument = nil // No pagination needed if we fetch all
                self.isLoadingPrompts = false
            }
        } catch {
            print("Error loading initial prompts: \(error.localizedDescription)")
            // Fallback to samples if Firestore fails
            await MainActor.run {
                self.prompts = JournalPrompt.samples
                self.isLoadingPrompts = false
            }
        }
    }
    
    /// Fetch prompts from Firestore with pagination support
    func fetchPrompts(category: JournalPrompt.PromptCategory? = nil, limit: Int = 50, startAfter: DocumentSnapshot? = nil) async throws -> ([JournalPrompt], DocumentSnapshot?) {
        // Batch fetch user likes first (single query)
        let likedPromptIds = await fetchUserLikedPromptIds()
        
        var query: Query = db.collection("prompts")
        
        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }
        
        query = query.limit(to: limit)
        
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        let snapshot = try await query.getDocuments()
        var fetchedPrompts: [JournalPrompt] = []
        for doc in snapshot.documents {
            if let prompt = parsePromptFromDocument(doc, likedPromptIds: likedPromptIds) {
                fetchedPrompts.append(prompt)
            }
        }
        
        let lastDoc = snapshot.documents.last
        return (fetchedPrompts, lastDoc)
    }
    
    /// Fetch next batch of prompts (for infinite scroll)
    func fetchNextPromptsBatch(category: JournalPrompt.PromptCategory? = nil) async throws -> [JournalPrompt] {
        let (newPrompts, lastDoc) = try await fetchPrompts(
            category: category,
            limit: promptsBatchSize,
            startAfter: lastPromptDocument
        )
        
        await MainActor.run {
            self.lastPromptDocument = lastDoc
            // Append new prompts (avoid duplicates)
            let existingIds = Set(self.prompts.map { $0.id })
            let uniqueNewPrompts = newPrompts.filter { !existingIds.contains($0.id) }
            self.prompts.append(contentsOf: uniqueNewPrompts)
        }
        
        return newPrompts
    }
    
    /// Reset pagination and fetch from beginning (for shuffle)
    func resetPromptsPagination() async {
        await MainActor.run {
            self.lastPromptDocument = nil
        }
        await loadInitialPrompts()
    }
    
    func likePrompt(_ promptId: String) async throws {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Update in Firestore
        let promptRef = db.collection("prompts").document(promptId)
        let userLikesRef = db.collection("userLikes").document("\(userId)_\(promptId)")
        
        let _: Any? = try await db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                let promptDoc = try transaction.getDocument(promptRef)
                guard var promptData = promptDoc.data() else {
                    let error = NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Prompt not found"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                let userLikesDoc = try? transaction.getDocument(userLikesRef)
                let isCurrentlyLiked = userLikesDoc?.exists ?? false
                
                if isCurrentlyLiked {
                    // Unlike
                    transaction.deleteDocument(userLikesRef)
                    if let currentLikes = promptData["likes"] as? Int, currentLikes > 0 {
                        promptData["likes"] = currentLikes - 1
                    }
                } else {
                    // Like
                    transaction.setData(["userId": userId, "promptId": promptId, "createdAt": FieldValue.serverTimestamp()], forDocument: userLikesRef)
                    let currentLikes = promptData["likes"] as? Int ?? 0
                    promptData["likes"] = currentLikes + 1
                }
                
                transaction.updateData(promptData, forDocument: promptRef)
                return nil
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
        }
        
        // Update local state
        await MainActor.run {
            if let index = prompts.firstIndex(where: { $0.id == promptId }) {
                prompts[index].isLiked.toggle()
                prompts[index].likes += prompts[index].isLiked ? 1 : -1
            }
        }
    }
    
    func sharePrompt(_ promptId: String) async throws {
        let promptRef = db.collection("prompts").document(promptId)
        
        let _: Any? = try await db.runTransaction { (transaction, errorPointer) -> Any? in
            do {
                let promptDoc = try transaction.getDocument(promptRef)
                guard var promptData = promptDoc.data() else {
                    let error = NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Prompt not found"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                let currentShares = promptData["shares"] as? Int ?? 0
                promptData["shares"] = currentShares + 1
                transaction.updateData(promptData, forDocument: promptRef)
                return nil
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
        }
        
        // Update local state
        await MainActor.run {
            if let index = prompts.firstIndex(where: { $0.id == promptId }) {
                prompts[index].shares += 1
            }
        }
    }
    
    /// Check if user has liked a prompt
    func checkUserLikes(promptId: String) async throws -> Bool {
        guard let userId = AuthService.shared.currentUser?.id else {
            return false
        }
        
        let userLikesRef = db.collection("userLikes").document("\(userId)_\(promptId)")
        let doc = try await userLikesRef.getDocument()
        return doc.exists
    }
    
    /// Load user's liked prompts
    func loadUserLikedPrompts() async throws -> [String] {
        guard let userId = AuthService.shared.currentUser?.id else {
            return []
        }
        
        let snapshot = try await db.collection("userLikes")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return snapshot.documents.map { $0.data()["promptId"] as? String ?? "" }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Helper Methods
    
    /// Parse JournalPrompt from Firestore document (optimized - no individual queries)
    /// - Parameters:
    ///   - doc: The Firestore document snapshot
    ///   - likedPromptIds: Pre-fetched Set of prompt IDs the user has liked (O(1) lookup)
    private func parsePromptFromDocument(_ doc: DocumentSnapshot, likedPromptIds: Set<String>) -> JournalPrompt? {
        guard let data = doc.data() else {
            return nil
        }
        
        let id = doc.documentID
        let question = data["question"] as? String ?? ""
        let hint = data["hint"] as? String ?? ""
        let categoryString = data["category"] as? String ?? "question"
        let category = JournalPrompt.PromptCategory(rawValue: categoryString) ?? .question
        
        // Handle Firestore Timestamp
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = data["createdAt"] as? Date {
            createdAt = date
        } else {
            createdAt = Date()
        }
        
        let likes = data["likes"] as? Int ?? 0
        let shares = data["shares"] as? Int ?? 0
        
        // O(1) lookup instead of separate Firestore query!
        let isLiked = likedPromptIds.contains(id)
        
        return JournalPrompt(
            id: id,
            question: question,
            hint: hint,
            category: category,
            createdAt: createdAt,
            likes: likes,
            shares: shares,
            isLiked: isLiked
        )
    }
    
    // MARK: - AI Conversation Operations
    
    func fetchConversations(userId: String) async throws -> [AIConversation] {
        return conversations
    }
    
    func createConversation(_ conversation: AIConversation) async throws {
        await MainActor.run {
            conversations.insert(conversation, at: 0)
        }
    }
    
    func updateConversation(_ conversation: AIConversation) async throws {
        await MainActor.run {
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations[index] = conversation
            }
        }
    }
    
    func deleteConversation(_ conversationId: String) async throws {
        await MainActor.run {
            conversations.removeAll { $0.id == conversationId }
        }
    }
    
    func addMessageToConversation(_ message: AIMessage, conversationId: String) async throws {
        await MainActor.run {
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].messages.append(message)
                conversations[index].updatedAt = Date()
            }
        }
    }
    
    // MARK: - User Operations
    
    /// Fetch user document from Firestore with timeout
    func fetchUser(userId: String) async throws -> User? {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            print("[FirebaseService] Offline - cannot fetch user from Firestore")
            return nil
        }
        
        let doc = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
            try await self.db.collection("users").document(userId).getDocument()
        }
        
        guard doc.exists else {
            return nil
        }
        
        return parseUserFromDocument(doc)
    }
    
    /// Save user document to Firestore with timeout
    func saveUser(_ user: User) async throws {
        var data: [String: Any] = [
            "email": user.email,
            "createdAt": Timestamp(date: user.createdAt),
            "onboardingCompleted": user.onboardingCompleted,
            "subscriptionStatus": user.subscriptionStatus.rawValue,
            "securityEnabled": user.securityEnabled,
            "dashboardLayout": user.dashboardLayout,
            "currentStreak": user.currentStreak,
            "longestStreak": user.longestStreak,
            "totalEntries": user.totalEntries,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let displayName = user.displayName {
            data["displayName"] = displayName
        }
        if let preferredName = user.preferredName {
            data["preferredName"] = preferredName
        }
        if let lastEntryDate = user.lastEntryDate {
            data["lastEntryDate"] = Timestamp(date: lastEntryDate)
        }
        if let onboardingData = user.onboardingData,
           let encoded = try? JSONEncoder().encode(onboardingData),
           let json = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
            data["onboardingData"] = json
        }
        
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            print("[FirebaseService] Offline - user save queued for later")
            // TODO: Implement offline queue for user saves
            return
        }
        
        try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
            try await self.db.collection("users").document(user.id).setData(data, merge: true)
        }
    }
    
    /// Parse User from Firestore document
    private func parseUserFromDocument(_ doc: DocumentSnapshot) -> User? {
        guard let data = doc.data() else { return nil }
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let lastEntryDate: Date?
        if let timestamp = data["lastEntryDate"] as? Timestamp {
            lastEntryDate = timestamp.dateValue()
        } else {
            lastEntryDate = nil
        }
        
        var onboardingData: User.OnboardingData?
        if let onboardingJson = data["onboardingData"] as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: onboardingJson),
           let decoded = try? JSONDecoder().decode(User.OnboardingData.self, from: jsonData) {
            onboardingData = decoded
        }
        
        let subscriptionStatus = User.SubscriptionStatus(rawValue: data["subscriptionStatus"] as? String ?? "trial") ?? .trial
        
        return User(
            id: doc.documentID,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String,
            preferredName: data["preferredName"] as? String,
            createdAt: createdAt,
            onboardingCompleted: data["onboardingCompleted"] as? Bool ?? false,
            onboardingData: onboardingData,
            subscriptionStatus: subscriptionStatus,
            securityEnabled: data["securityEnabled"] as? Bool ?? false,
            dashboardLayout: data["dashboardLayout"] as? [String] ?? ["morning_reflection", "gratitude", "evening_review", "goals"],
            currentStreak: data["currentStreak"] as? Int ?? 0,
            longestStreak: data["longestStreak"] as? Int ?? 0,
            lastEntryDate: lastEntryDate,
            totalEntries: data["totalEntries"] as? Int ?? 0
        )
    }
    
    // MARK: - Streak Operations
    
    func updateStreak(userId: String) async throws -> (current: Int, longest: Int) {
        // Check network availability
        guard NetworkMonitor.shared.isConnected else {
            print("[FirebaseService] Offline - calculating streak from cached entries")
            let currentStreak = calculateCurrentStreak(from: entries.map { $0.createdAt })
            let longestStreak = calculateLongestStreak(from: entries.map { $0.createdAt })
            return (currentStreak, longestStreak)
        }
        // #region agent log
        agentLog(
            hypothesisId: "IDX2",
            location: "FirebaseService.swift:updateStreak",
            message: "start",
            data: [
                "useOrderByCreatedAt": true
            ]
        )
        // #endregion

        // Fetch entries to calculate streak with timeout
        let snapshot: QuerySnapshot
        do {
            snapshot = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
                try await self.db.collection("entries")
                    .whereField("userId", isEqualTo: userId)
                    .order(by: "createdAt", descending: true)
                    .getDocuments()
            }
        } catch {
            let nsError = error as NSError
            let missingIndex = isMissingIndexError(error)
            
            // #region agent log
            agentLog(
                hypothesisId: "IDX2",
                location: "FirebaseService.swift:updateStreak",
                message: "orderedQueryFailed",
                data: [
                    "domain": nsError.domain,
                    "code": nsError.code,
                    "missingIndex": missingIndex
                ]
            )
            // #endregion
            
            if missingIndex {
                // Fallback: query without orderBy, compute streak from dates.
                snapshot = try await withTimeoutAndRetry(timeout: defaultTimeout, maxRetries: maxRetries) {
                    try await self.db.collection("entries")
                        .whereField("userId", isEqualTo: userId)
                        .getDocuments()
                }
                
                // #region agent log
                agentLog(
                    hypothesisId: "IDX2",
                    location: "FirebaseService.swift:updateStreak",
                    message: "fallbackUsed",
                    data: [
                        "docCount": snapshot.documents.count
                    ]
                )
                // #endregion
            } else {
                throw error
            }
        }
        
        let entryDates = snapshot.documents.compactMap { doc -> Date? in
            if let timestamp = doc.data()["createdAt"] as? Timestamp {
                return timestamp.dateValue()
            }
            return nil
        }
        
        let currentStreak = calculateCurrentStreak(from: entryDates)
        let longestStreak = calculateLongestStreak(from: entryDates)
        
        // Save streak to user document
        try await db.collection("users").document(userId).setData([
            "currentStreak": currentStreak,
            "longestStreak": longestStreak
        ], merge: true)
        
        return (currentStreak, longestStreak)
    }
    
    private func calculateCurrentStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Get unique days
        let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) }).sorted(by: >)
        
        for day in uniqueDays {
            if day == currentDate || day == calendar.date(byAdding: .day, value: -1, to: currentDate)! {
                streak += 1
                currentDate = day
            } else if day < calendar.date(byAdding: .day, value: -1, to: currentDate)! {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak(from dates: [Date]) -> Int {
        guard !dates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) }).sorted()
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueDays.count {
            let previousDay = uniqueDays[i - 1]
            let currentDay = uniqueDays[i]
            
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay),
               currentDay == nextDay {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    func calculateStreak(entries: [JournalEntry]) -> Int {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
        
        guard !sortedEntries.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.createdAt)
            
            if entryDate == currentDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if entryDate < currentDate {
                break
            }
        }
        
        return streak
    }
}


