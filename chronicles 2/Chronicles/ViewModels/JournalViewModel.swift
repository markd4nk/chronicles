//
//  JournalViewModel.swift
//  Chronicles
//
//  Journal and entry management view model
//

import Foundation
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var journals: [Journal] = []
    @Published var selectedJournal: Journal?
    @Published var entries: [JournalEntry] = []
    @Published var templates: [JournalTemplate] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    // Entry Creation
    @Published var newEntryTitle = ""
    @Published var newEntryContent = ""
    @Published var selectedInputMethod: JournalEntry.InputMethod = .write
    @Published var selectedTemplate: JournalTemplate?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        firebaseService.$journals
            .receive(on: DispatchQueue.main)
            .assign(to: &$journals)
        
        firebaseService.$entries
            .receive(on: DispatchQueue.main)
            .assign(to: &$entries)
        
        firebaseService.$templates
            .receive(on: DispatchQueue.main)
            .assign(to: &$templates)
    }
    
    // MARK: - Journal Operations
    
    func loadJournals() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userId = AuthService.shared.currentUser?.id ?? ""
            journals = try await firebaseService.fetchJournals(userId: userId)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func createJournal(name: String, color: String) async {
        let journal = Journal(
            id: UUID().uuidString,
            userId: AuthService.shared.currentUser?.id ?? "",
            name: name,
            color: color,
            order: journals.count,
            createdAt: Date(),
            updatedAt: Date(),
            entryCount: 0,
            lastEntryDate: nil
        )
        
        do {
            try await firebaseService.createJournal(journal)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func updateJournal(_ journal: Journal) async {
        do {
            try await firebaseService.updateJournal(journal)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func deleteJournal(_ journal: Journal) async {
        do {
            try await firebaseService.deleteJournal(journal.id)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func reorderJournals(_ journals: [Journal]) async {
        var reordered = journals
        for (index, _) in reordered.enumerated() {
            reordered[index].order = index
        }
        
        do {
            try await firebaseService.reorderJournals(reordered)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Entry Operations
    
    func loadEntries(for journalId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userId = AuthService.shared.currentUser?.id ?? ""
            entries = try await firebaseService.fetchEntries(userId: userId, journalId: journalId)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func entriesForJournal(_ journalId: String) -> [JournalEntry] {
        entries.filter { $0.journalId == journalId }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func entriesGroupedByDate() -> [(String, [JournalEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            entry.createdAt.relativeString
        }
        return grouped.sorted { $0.value.first!.createdAt > $1.value.first!.createdAt }
    }
    
    func createEntry(journalId: String, title: String, content: String, inputMethod: JournalEntry.InputMethod, templateId: String? = nil, promptId: String? = nil) async {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        let entry = JournalEntry(
            id: UUID().uuidString,
            userId: AuthService.shared.currentUser?.id ?? "",
            journalId: journalId,
            templateId: templateId,
            promptId: promptId,
            title: title,
            content: content,
            createdAt: Date(),
            updatedAt: Date(),
            inputMethod: inputMethod,
            mood: nil,
            wordCount: wordCount
        )
        
        do {
            try await firebaseService.createEntry(entry)
            resetEntryForm()
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func updateEntry(_ entry: JournalEntry) async {
        do {
            try await firebaseService.updateEntry(entry)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) async {
        do {
            try await firebaseService.deleteEntry(entry.id)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func searchEntries(query: String) async -> [JournalEntry] {
        do {
            let userId = AuthService.shared.currentUser?.id ?? ""
            return try await firebaseService.searchEntries(query: query, userId: userId)
        } catch {
            return []
        }
    }
    
    // MARK: - Template Operations
    
    func loadTemplates(for journalId: String? = nil) async {
        do {
            let userId = AuthService.shared.currentUser?.id ?? ""
            templates = try await firebaseService.fetchTemplates(userId: userId, journalId: journalId)
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }
    
    func templatesForJournal(_ journalId: String) -> [JournalTemplate] {
        templates.filter { $0.journalId == journalId || $0.isBuiltIn }
    }
    
    func applyTemplate(_ template: JournalTemplate) {
        selectedTemplate = template
        newEntryTitle = template.name
        newEntryContent = template.formattedPrompts
    }
    
    // MARK: - Form Reset
    
    func resetEntryForm() {
        newEntryTitle = ""
        newEntryContent = ""
        selectedInputMethod = .write
        selectedTemplate = nil
    }
    
    // MARK: - Helpers
    
    func journal(for id: String) -> Journal? {
        journals.first { $0.id == id }
    }
    
    func getJournalColor(for entry: JournalEntry) -> String {
        journal(for: entry.journalId)?.color ?? "#414141"
    }
    
    func getJournalName(for entry: JournalEntry) -> String {
        journal(for: entry.journalId)?.name ?? "Unknown"
    }
}

