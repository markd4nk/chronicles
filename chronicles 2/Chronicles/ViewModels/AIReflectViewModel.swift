//
//  AIReflectViewModel.swift
//  Chronicles
//
//  AI Reflect/Analyze view model
//

import Foundation
import Combine

@MainActor
class AIReflectViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var conversations: [AIConversation] = []
    @Published var currentConversation: AIConversation?
    @Published var messages: [AIMessage] = []
    @Published var selectedJournals: Set<String> = []
    @Published var availableJournals: [Journal] = []
    
    @Published var inputText = ""
    @Published var isAnalyzing = false
    @Published var isGenerating = false
    @Published var analysisSummary: String?
    @Published var error: String?
    @Published var showError = false
    
    private let aiService = AIService.shared
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        firebaseService.$conversations
            .receive(on: DispatchQueue.main)
            .assign(to: &$conversations)
        
        firebaseService.$journals
            .receive(on: DispatchQueue.main)
            .assign(to: &$availableJournals)
    }
    
    // MARK: - Journal Selection
    
    func toggleJournalSelection(_ journalId: String) {
        if selectedJournals.contains(journalId) {
            selectedJournals.remove(journalId)
        } else {
            selectedJournals.insert(journalId)
        }
    }
    
    func selectAllJournals() {
        selectedJournals = Set(availableJournals.map { $0.id })
    }
    
    func deselectAllJournals() {
        selectedJournals.removeAll()
    }
    
    // MARK: - Analysis
    
    func startAnalysis() async {
        guard !selectedJournals.isEmpty else {
            error = "Please select at least one journal to analyze."
            showError = true
            return
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Get entries for selected journals
            let allEntries = firebaseService.entries
            let selectedEntries = allEntries.filter { selectedJournals.contains($0.journalId) }
            
            // Get journal objects
            let selectedJournalObjects = availableJournals.filter { selectedJournals.contains($0.id) }
            
            // Analyze
            let summary = try await aiService.analyzeJournals(entries: selectedEntries, journals: selectedJournalObjects)
            analysisSummary = summary
            
            // Create or update conversation
            await createOrUpdateConversation(withSummary: summary)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    private func createOrUpdateConversation(withSummary summary: String) async {
        let conversationId = currentConversation?.id ?? UUID().uuidString
        
        let systemMessage = AIMessage(
            id: UUID().uuidString,
            conversationId: conversationId,
            role: .assistant,
            content: summary,
            createdAt: Date()
        )
        
        if var conversation = currentConversation {
            // Add to existing conversation
            conversation.messages.append(systemMessage)
            conversation.updatedAt = Date()
            
            do {
                try await firebaseService.updateConversation(conversation)
                currentConversation = conversation
                messages = conversation.messages
            } catch {
                self.error = error.localizedDescription
                showError = true
            }
        } else {
            // Create new conversation
            let conversation = AIConversation(
                id: conversationId,
                userId: AuthService.shared.currentUser?.id ?? "",
                title: "Analysis - \(Date().shortDateString)",
                createdAt: Date(),
                updatedAt: Date(),
                messages: [systemMessage],
                analyzedJournalIds: Array(selectedJournals),
                insightsSummary: String(summary.prefix(100))
            )
            
            do {
                try await firebaseService.createConversation(conversation)
                currentConversation = conversation
                messages = conversation.messages
            } catch {
                self.error = error.localizedDescription
                showError = true
            }
        }
    }
    
    // MARK: - Chat
    
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let conversation = currentConversation else {
            // Start analysis first if no conversation
            await startAnalysis()
            return
        }
        
        let userMessageText = inputText
        inputText = ""
        
        // Add user message
        let userMessage = AIMessage(
            id: UUID().uuidString,
            conversationId: conversation.id,
            role: .user,
            content: userMessageText,
            createdAt: Date()
        )
        
        messages.append(userMessage)
        
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Add user message to Firestore
            try await firebaseService.addMessageToConversation(userMessage, conversationId: conversation.id)
            
            // Get entries for context
            let selectedEntries = firebaseService.entries.filter { selectedJournals.contains($0.journalId) }
            
            // Generate AI response
            let response = try await aiService.generateResponse(
                to: userMessageText,
                in: conversation,
                withContext: selectedEntries
            )
            
            // Add response
            messages.append(response)
            try await firebaseService.addMessageToConversation(response, conversationId: conversation.id)
            
            // Update current conversation
            currentConversation?.messages = messages
            currentConversation?.updatedAt = Date()
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Conversation Management
    
    func loadConversation(_ conversation: AIConversation) {
        currentConversation = conversation
        messages = conversation.messages
        selectedJournals = Set(conversation.analyzedJournalIds)
        analysisSummary = conversation.insightsSummary
    }
    
    func startNewConversation() {
        currentConversation = nil
        messages = []
        analysisSummary = nil
        inputText = ""
        selectedJournals.removeAll()
    }
    
    func deleteConversation(_ conversation: AIConversation) async {
        do {
            try await firebaseService.deleteConversation(conversation.id)
            
            if currentConversation?.id == conversation.id {
                startNewConversation()
            }
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
}

