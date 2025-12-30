//
//  FirebaseService.swift
//  Chronicles
//
//  Firebase/Firestore service for data operations
//

import Foundation
import Combine
import FirebaseFirestore

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
    
    private let db = Firestore.firestore()
    private var promptsListener: ListenerRegistration?
    private var lastPromptDocument: DocumentSnapshot?
    private let promptsBatchSize = 50
    
    private init() {
        // Load sample data for demo (non-prompts)
        loadSampleData()
        // Set up prompts listener
        setupPromptsListener()
    }
    
    private func loadSampleData() {
        journals = Journal.samples
        entries = JournalEntry.samples
        templates = JournalTemplate.samples
        // Don't load prompts from samples - fetch from Firestore
        conversations = AIConversation.samples
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
        // In production, fetch from Firestore
        return Journal.samples
    }
    
    func createJournal(_ journal: Journal) async throws {
        await MainActor.run {
            journals.append(journal)
        }
    }
    
    func updateJournal(_ journal: Journal) async throws {
        await MainActor.run {
            if let index = journals.firstIndex(where: { $0.id == journal.id }) {
                journals[index] = journal
            }
        }
    }
    
    func deleteJournal(_ journalId: String) async throws {
        await MainActor.run {
            journals.removeAll { $0.id == journalId }
            // Also remove entries for this journal
            entries.removeAll { $0.journalId == journalId }
        }
    }
    
    func reorderJournals(_ journals: [Journal]) async throws {
        await MainActor.run {
            self.journals = journals
        }
    }
    
    // MARK: - Entry Operations
    
    func fetchEntries(userId: String, journalId: String? = nil) async throws -> [JournalEntry] {
        if let journalId = journalId {
            return entries.filter { $0.journalId == journalId }
        }
        return entries
    }
    
    func fetchEntriesForDate(userId: String, date: Date) async throws -> [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }
    
    func createEntry(_ entry: JournalEntry) async throws {
        await MainActor.run {
            entries.insert(entry, at: 0)
            
            // Update journal entry count
            if let index = journals.firstIndex(where: { $0.id == entry.journalId }) {
                journals[index].entryCount += 1
                journals[index].lastEntryDate = entry.createdAt
            }
        }
    }
    
    func updateEntry(_ entry: JournalEntry) async throws {
        await MainActor.run {
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = entry
            }
        }
    }
    
    func deleteEntry(_ entryId: String) async throws {
        await MainActor.run {
            if let entry = entries.first(where: { $0.id == entryId }) {
                // Update journal entry count
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
    
    /// Load initial batch of prompts from Firestore
    private func loadInitialPrompts() async {
        do {
            let query = db.collection("prompts")
                .limit(to: promptsBatchSize)
            
            let snapshot = try await query.getDocuments()
            var fetchedPrompts: [JournalPrompt] = []
            
            for doc in snapshot.documents {
                if let prompt = try? await parsePromptFromDocument(doc) {
                    fetchedPrompts.append(prompt)
                }
            }
            
            await MainActor.run {
                self.prompts = fetchedPrompts.shuffled()
                self.lastPromptDocument = snapshot.documents.last
            }
        } catch {
            print("Error loading initial prompts: \(error.localizedDescription)")
            // Fallback to samples if Firestore fails
            await MainActor.run {
                self.prompts = JournalPrompt.samples
            }
        }
    }
    
    /// Fetch prompts from Firestore with pagination support
    func fetchPrompts(category: JournalPrompt.PromptCategory? = nil, limit: Int = 50, startAfter: DocumentSnapshot? = nil) async throws -> ([JournalPrompt], DocumentSnapshot?) {
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
            if let prompt = try? await parsePromptFromDocument(doc) {
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
        
        try await db.runTransaction { transaction -> Void in
            let promptDoc = try transaction.getDocument(promptRef)
            guard var promptData = promptDoc.data() else {
                throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Prompt not found"])
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
        
        try await db.runTransaction { transaction -> Void in
            let promptDoc = try transaction.getDocument(promptRef)
            guard var promptData = promptDoc.data() else {
                throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Prompt not found"])
            }
            
            let currentShares = promptData["shares"] as? Int ?? 0
            promptData["shares"] = currentShares + 1
            transaction.updateData(promptData, forDocument: promptRef)
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
    
    /// Parse JournalPrompt from Firestore document
    private func parsePromptFromDocument(_ doc: DocumentSnapshot) async throws -> JournalPrompt {
        guard let data = doc.data() else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document data not found"])
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
        
        // Check if user has liked this prompt
        var isLiked = false
        if let userId = AuthService.shared.currentUser?.id {
            let userLikesRef = db.collection("userLikes").document("\(userId)_\(id)")
            do {
                let likeDoc = try await userLikesRef.getDocument()
                isLiked = likeDoc.exists
            } catch {
                // If check fails, default to false
                isLiked = false
            }
        }
        
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
    
    // MARK: - Streak Operations
    
    func updateStreak(userId: String) async throws -> (current: Int, longest: Int) {
        // In production, calculate from actual entry dates
        // For demo, return sample values
        return (7, 14)
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


