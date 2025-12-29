//
//  FirebaseService.swift
//  Chronicles
//
//  Firebase/Firestore service for data operations
//

import Foundation
import Combine

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
    
    private init() {
        // Load sample data for demo
        loadSampleData()
    }
    
    private func loadSampleData() {
        journals = Journal.samples
        entries = JournalEntry.samples
        templates = JournalTemplate.samples
        prompts = JournalPrompt.samples
        conversations = AIConversation.samples
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
    
    func fetchPrompts(category: JournalPrompt.PromptCategory? = nil) async throws -> [JournalPrompt] {
        if let category = category {
            return prompts.filter { $0.category == category }
        }
        return prompts
    }
    
    func likePrompt(_ promptId: String) async throws {
        await MainActor.run {
            if let index = prompts.firstIndex(where: { $0.id == promptId }) {
                prompts[index].isLiked.toggle()
                prompts[index].likes += prompts[index].isLiked ? 1 : -1
            }
        }
    }
    
    func sharePrompt(_ promptId: String) async throws {
        await MainActor.run {
            if let index = prompts.firstIndex(where: { $0.id == promptId }) {
                prompts[index].shares += 1
            }
        }
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

