//
//  OfflineQueueService.swift
//  Chronicles
//
//  Persistent offline queue for Firestore write operations
//  Stores operations locally and syncs when connectivity is restored
//

import Foundation
import Combine

// MARK: - Operation Types

/// Types of operations that can be queued offline
enum OfflineOperationType: String, Codable {
    // User operations
    case saveUser
    
    // Journal operations
    case createJournal
    case updateJournal
    case deleteJournal
    case reorderJournals
    
    // Entry operations
    case createEntry
    case updateEntry
    case deleteEntry
    
    // Conversation operations
    case createConversation
    case updateConversationMetadata
    case addMessageToConversation
    case deleteConversation
    
    // Prompt operations
    case likePrompt
    case sharePrompt
}

// MARK: - Queued Operation

/// Represents a single queued operation with metadata
struct QueuedOperation: Codable, Identifiable {
    let id: String
    let type: OfflineOperationType
    let timestamp: Date
    let data: Data  // JSON-encoded operation data
    var retryCount: Int
    var lastAttempt: Date?
    
    init(type: OfflineOperationType, data: Data) {
        self.id = UUID().uuidString
        self.type = type
        self.timestamp = Date()
        self.data = data
        self.retryCount = 0
        self.lastAttempt = nil
    }
}

// MARK: - Operation Data Structures

/// Data structures for encoding/decoding operation payloads

struct SaveUserData: Codable {
    let userId: String
    let email: String
    let displayName: String?
    let preferredName: String?
    let createdAt: Date
    let onboardingCompleted: Bool
    let subscriptionStatus: String
    let securityEnabled: Bool
    let dashboardLayout: [String]
    let currentStreak: Int
    let longestStreak: Int
    let totalEntries: Int
    let lastEntryDate: Date?
    let onboardingData: Data?  // Encoded OnboardingData
}

struct JournalOperationData: Codable {
    let journalId: String
    let userId: String
    let name: String
    let color: String
    let order: Int
    let createdAt: Date
    let updatedAt: Date
    let entryCount: Int
    let lastEntryDate: Date?
}

struct ReorderJournalsData: Codable {
    let journalIds: [String]
    let orders: [Int]
}

struct EntryOperationData: Codable {
    let entryId: String
    let userId: String
    let journalId: String
    let templateId: String?
    let promptId: String?
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let inputMethod: String
    let mood: String?
    let wordCount: Int
}

struct ConversationOperationData: Codable {
    let conversationId: String
    let userId: String
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let analyzedJournalIds: [String]
    let insightsSummary: String?
    let lastMessagePreview: String?
    let lastMessageAt: Date?
    let messageCount: Int?
}

struct MessageOperationData: Codable {
    let messageId: String
    let conversationId: String
    let role: String
    let content: String
    let createdAt: Date
}

struct PromptOperationData: Codable {
    let promptId: String
    let userId: String
}

struct DeleteOperationData: Codable {
    let id: String
}

struct DeleteEntryOperationData: Codable {
    let entryId: String
    let journalId: String?
}

// MARK: - Offline Queue Service

/// Service for managing offline write operations
/// Operations are persisted locally and synced when network becomes available
class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()
    
    // MARK: - Published Properties
    
    /// Number of operations pending in the queue
    @Published private(set) var pendingCount: Int = 0
    
    /// Whether the queue is currently being processed
    @Published private(set) var isProcessing: Bool = false
    
    /// Last sync error, if any
    @Published private(set) var lastError: String?
    
    // MARK: - Private Properties
    
    private let queueKey = "com.chronicles.offlineQueue"
    private let maxRetries = 5
    private let maxQueueSize = 500
    private let baseRetryDelay: TimeInterval = 2.0  // seconds
    
    private var queue: [QueuedOperation] = []
    private var processingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadQueue()
        setupNetworkObserver()
    }
    
    // MARK: - Public Methods
    
    /// Enqueue an operation for later sync
    /// - Parameters:
    ///   - type: The type of operation
    ///   - data: The operation data (must be Codable)
    /// - Returns: The ID of the queued operation
    @discardableResult
    func enqueue<T: Codable>(type: OfflineOperationType, data: T) -> String {
        do {
            let encodedData = try JSONEncoder().encode(data)
            let operation = QueuedOperation(type: type, data: encodedData)
            
            // Check queue size limit
            if queue.count >= maxQueueSize {
                // Remove oldest operation to make room
                queue.removeFirst()
                print("[OfflineQueue] Queue at max size, removed oldest operation")
            }
            
            queue.append(operation)
            saveQueue()
            
            Task { @MainActor in
                self.pendingCount = self.queue.count
            }
            
            print("[OfflineQueue] Enqueued \(type.rawValue), queue size: \(queue.count)")
            return operation.id
            
        } catch {
            print("[OfflineQueue] Failed to encode operation data: \(error.localizedDescription)")
            return ""
        }
    }
    
    /// Process all pending operations
    /// Called automatically when network becomes available
    func processQueue() {
        guard !isProcessing else {
            print("[OfflineQueue] Already processing queue")
            return
        }
        
        guard NetworkMonitor.shared.isConnected else {
            print("[OfflineQueue] Cannot process queue - offline")
            return
        }
        
        guard !queue.isEmpty else {
            print("[OfflineQueue] Queue is empty")
            return
        }
        
        processingTask = Task {
            await processQueueInternal()
        }
    }
    
    /// Clear all pending operations
    func clearQueue() {
        queue.removeAll()
        saveQueue()
        
        Task { @MainActor in
            self.pendingCount = 0
            self.lastError = nil
        }
        
        print("[OfflineQueue] Queue cleared")
    }
    
    /// Get the count of pending operations of a specific type
    func pendingCount(for type: OfflineOperationType) -> Int {
        queue.filter { $0.type == type }.count
    }
    
    /// Check if there are any pending operations for a specific ID
    func hasPendingOperation(type: OfflineOperationType, id: String) -> Bool {
        queue.contains { operation in
            guard operation.type == type else { return false }
            
            // Try to decode the data and check the ID
            do {
                switch type {
                case .deleteJournal, .deleteEntry, .deleteConversation:
                    let data = try JSONDecoder().decode(DeleteOperationData.self, from: operation.data)
                    return data.id == id
                case .updateJournal, .createJournal:
                    let data = try JSONDecoder().decode(JournalOperationData.self, from: operation.data)
                    return data.journalId == id
                case .updateEntry, .createEntry:
                    let data = try JSONDecoder().decode(EntryOperationData.self, from: operation.data)
                    return data.entryId == id
                case .updateConversationMetadata, .createConversation:
                    let data = try JSONDecoder().decode(ConversationOperationData.self, from: operation.data)
                    return data.conversationId == id
                default:
                    return false
                }
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load queue from persistent storage
    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            queue = []
            return
        }
        
        do {
            queue = try JSONDecoder().decode([QueuedOperation].self, from: data)
            Task { @MainActor in
                self.pendingCount = self.queue.count
            }
            print("[OfflineQueue] Loaded \(queue.count) operations from storage")
        } catch {
            print("[OfflineQueue] Failed to load queue: \(error.localizedDescription)")
            queue = []
        }
    }
    
    /// Save queue to persistent storage
    private func saveQueue() {
        do {
            let data = try JSONEncoder().encode(queue)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            print("[OfflineQueue] Failed to save queue: \(error.localizedDescription)")
        }
    }
    
    /// Set up observer for network connectivity changes
    private func setupNetworkObserver() {
        NetworkMonitor.shared.$isConnected
            .dropFirst()  // Ignore initial value
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    print("[OfflineQueue] Network connected - processing queue")
                    self?.processQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Internal queue processing with retry logic
    private func processQueueInternal() async {
        await MainActor.run {
            self.isProcessing = true
            self.lastError = nil
        }
        
        print("[OfflineQueue] Starting queue processing, \(queue.count) operations pending")
        
        // Process operations in order
        while !queue.isEmpty && NetworkMonitor.shared.isConnected {
            var operation = queue.removeFirst()
            
            do {
                try await processOperation(operation)
                print("[OfflineQueue] Successfully processed \(operation.type.rawValue)")
                
            } catch {
                print("[OfflineQueue] Failed to process \(operation.type.rawValue): \(error.localizedDescription)")
                
                operation.retryCount += 1
                operation.lastAttempt = Date()
                
                if operation.retryCount < maxRetries {
                    // Re-add to queue for retry
                    queue.append(operation)
                    
                    // Calculate exponential backoff delay
                    let delay = baseRetryDelay * pow(2.0, Double(operation.retryCount - 1))
                    print("[OfflineQueue] Will retry in \(delay)s (attempt \(operation.retryCount)/\(maxRetries))")
                    
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    // Max retries exceeded, log error
                    print("[OfflineQueue] Max retries exceeded for \(operation.type.rawValue), dropping operation")
                    await MainActor.run {
                        self.lastError = "Failed to sync \(operation.type.rawValue) after \(self.maxRetries) attempts"
                    }
                }
            }
            
            // Save queue state after each operation
            saveQueue()
            
            await MainActor.run {
                self.pendingCount = self.queue.count
            }
        }
        
        await MainActor.run {
            self.isProcessing = false
        }
        
        print("[OfflineQueue] Queue processing complete, \(queue.count) operations remaining")
    }
    
    /// Process a single operation
    private func processOperation(_ operation: QueuedOperation) async throws {
        let decoder = JSONDecoder()
        
        switch operation.type {
        case .saveUser:
            let data = try decoder.decode(SaveUserData.self, from: operation.data)
            try await processUserSave(data)
            
        case .createJournal:
            let data = try decoder.decode(JournalOperationData.self, from: operation.data)
            try await processJournalCreate(data)
            
        case .updateJournal:
            let data = try decoder.decode(JournalOperationData.self, from: operation.data)
            try await processJournalUpdate(data)
            
        case .deleteJournal:
            let data = try decoder.decode(DeleteOperationData.self, from: operation.data)
            try await processJournalDelete(data)
            
        case .reorderJournals:
            let data = try decoder.decode(ReorderJournalsData.self, from: operation.data)
            try await processJournalsReorder(data)
            
        case .createEntry:
            let data = try decoder.decode(EntryOperationData.self, from: operation.data)
            try await processEntryCreate(data)
            
        case .updateEntry:
            let data = try decoder.decode(EntryOperationData.self, from: operation.data)
            try await processEntryUpdate(data)
            
        case .deleteEntry:
            let data = try decoder.decode(DeleteEntryOperationData.self, from: operation.data)
            try await processEntryDelete(data)
            
        case .createConversation:
            let data = try decoder.decode(ConversationOperationData.self, from: operation.data)
            try await processConversationCreate(data)
            
        case .updateConversationMetadata:
            let data = try decoder.decode(ConversationOperationData.self, from: operation.data)
            try await processConversationUpdate(data)
            
        case .addMessageToConversation:
            let data = try decoder.decode(MessageOperationData.self, from: operation.data)
            try await processMessageAdd(data)
            
        case .deleteConversation:
            let data = try decoder.decode(DeleteOperationData.self, from: operation.data)
            try await processConversationDelete(data)
            
        case .likePrompt:
            let data = try decoder.decode(PromptOperationData.self, from: operation.data)
            try await processPromptLike(data)
            
        case .sharePrompt:
            let data = try decoder.decode(PromptOperationData.self, from: operation.data)
            try await processPromptShare(data)
        }
    }
    
    // MARK: - Operation Processors
    
    // These methods will be called during queue processing to sync with Firestore
    // They use FirebaseService's internal write methods
    
    private func processUserSave(_ data: SaveUserData) async throws {
        // Reconstruct User and save
        var onboardingData: User.OnboardingData?
        if let encodedData = data.onboardingData {
            onboardingData = try? JSONDecoder().decode(User.OnboardingData.self, from: encodedData)
        }
        
        let user = User(
            id: data.userId,
            email: data.email,
            displayName: data.displayName,
            preferredName: data.preferredName,
            createdAt: data.createdAt,
            onboardingCompleted: data.onboardingCompleted,
            onboardingData: onboardingData,
            subscriptionStatus: User.SubscriptionStatus(rawValue: data.subscriptionStatus) ?? .trial,
            securityEnabled: data.securityEnabled,
            dashboardLayout: data.dashboardLayout,
            currentStreak: data.currentStreak,
            longestStreak: data.longestStreak,
            lastEntryDate: data.lastEntryDate,
            totalEntries: data.totalEntries
        )
        
        try await FirebaseService.shared.saveUserDirect(user)
    }
    
    private func processJournalCreate(_ data: JournalOperationData) async throws {
        let journal = Journal(
            id: data.journalId,
            userId: data.userId,
            name: data.name,
            color: data.color,
            order: data.order,
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            entryCount: data.entryCount,
            lastEntryDate: data.lastEntryDate
        )
        
        try await FirebaseService.shared.createJournalDirect(journal)
    }
    
    private func processJournalUpdate(_ data: JournalOperationData) async throws {
        let journal = Journal(
            id: data.journalId,
            userId: data.userId,
            name: data.name,
            color: data.color,
            order: data.order,
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            entryCount: data.entryCount,
            lastEntryDate: data.lastEntryDate
        )
        
        try await FirebaseService.shared.updateJournalDirect(journal)
    }
    
    private func processJournalDelete(_ data: DeleteOperationData) async throws {
        try await FirebaseService.shared.deleteJournalDirect(data.id)
    }
    
    private func processJournalsReorder(_ data: ReorderJournalsData) async throws {
        try await FirebaseService.shared.reorderJournalsDirect(ids: data.journalIds, orders: data.orders)
    }
    
    private func processEntryCreate(_ data: EntryOperationData) async throws {
        let entry = JournalEntry(
            id: data.entryId,
            userId: data.userId,
            journalId: data.journalId,
            templateId: data.templateId,
            promptId: data.promptId,
            title: data.title,
            content: data.content,
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            inputMethod: JournalEntry.InputMethod(rawValue: data.inputMethod) ?? .write,
            mood: data.mood,
            wordCount: data.wordCount
        )
        
        try await FirebaseService.shared.createEntryDirect(entry)
    }
    
    private func processEntryUpdate(_ data: EntryOperationData) async throws {
        let entry = JournalEntry(
            id: data.entryId,
            userId: data.userId,
            journalId: data.journalId,
            templateId: data.templateId,
            promptId: data.promptId,
            title: data.title,
            content: data.content,
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            inputMethod: JournalEntry.InputMethod(rawValue: data.inputMethod) ?? .write,
            mood: data.mood,
            wordCount: data.wordCount
        )
        
        try await FirebaseService.shared.updateEntryDirect(entry)
    }
    
    private func processEntryDelete(_ data: DeleteEntryOperationData) async throws {
        try await FirebaseService.shared.deleteEntryDirect(data.entryId, journalId: data.journalId)
    }
    
    private func processConversationCreate(_ data: ConversationOperationData) async throws {
        let conversation = AIConversation(
            id: data.conversationId,
            userId: data.userId,
            title: data.title,
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            messages: [],
            analyzedJournalIds: data.analyzedJournalIds,
            insightsSummary: data.insightsSummary,
            lastMessagePreview: data.lastMessagePreview,
            lastMessageAt: data.lastMessageAt,
            storedMessageCount: data.messageCount
        )
        
        try await FirebaseService.shared.createConversationDirect(conversation)
    }
    
    private func processConversationUpdate(_ data: ConversationOperationData) async throws {
        let conversation = AIConversation(
            id: data.conversationId,
            userId: data.userId,
            title: data.title,
            createdAt: data.createdAt,
            updatedAt: data.updatedAt,
            messages: [],
            analyzedJournalIds: data.analyzedJournalIds,
            insightsSummary: data.insightsSummary,
            lastMessagePreview: data.lastMessagePreview,
            lastMessageAt: data.lastMessageAt,
            storedMessageCount: data.messageCount
        )
        
        try await FirebaseService.shared.updateConversationMetadataDirect(conversation)
    }
    
    private func processMessageAdd(_ data: MessageOperationData) async throws {
        let message = AIMessage(
            id: data.messageId,
            conversationId: data.conversationId,
            role: AIMessage.MessageRole(rawValue: data.role) ?? .assistant,
            content: data.content,
            createdAt: data.createdAt
        )
        
        try await FirebaseService.shared.addMessageToConversationDirect(message, conversationId: data.conversationId)
    }
    
    private func processConversationDelete(_ data: DeleteOperationData) async throws {
        try await FirebaseService.shared.deleteConversationDirect(data.id)
    }
    
    private func processPromptLike(_ data: PromptOperationData) async throws {
        try await FirebaseService.shared.likePromptDirect(data.promptId)
    }
    
    private func processPromptShare(_ data: PromptOperationData) async throws {
        try await FirebaseService.shared.sharePromptDirect(data.promptId)
    }
}

