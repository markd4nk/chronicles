//
//  EntriesListView.swift
//  Chronicles
//
//  List view of all entries
//

import SwiftUI

struct EntriesListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Binding var selectedJournalId: String?
    @State private var searchText = ""
    // #region agent log
    @State private var filterCallCount = 0
    // #endregion
    
    var filteredEntries: [JournalEntry] {
        // #region agent log
        Task { @MainActor in
            var request = URLRequest(url: URL(string: "http://127.0.0.1:7243/ingest/c77dc5f7-b92e-4545-af23-f0f74127ea45")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let payload: [String: Any] = ["location": "EntriesListView.swift:filteredEntries", "message": "filteredEntries computed", "data": ["entryCount": viewModel.entries.count, "hasJournalFilter": selectedJournalId != nil, "hasSearchText": !searchText.isEmpty], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "hypothesisId": "C"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            _ = try? await URLSession.shared.data(for: request)
        }
        // #endregion
        var entries = viewModel.entries
        
        // First filter by journal if a specific journal is selected
        if let journalId = selectedJournalId {
            entries = entries.filter { $0.journalId == journalId }
        }
        
        // Then filter by search text if not empty
        if !searchText.isEmpty {
            entries = entries.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort by date (newest first)
        return entries.sorted { $0.createdAt > $1.createdAt }
    }
    
    // Check if journal filter is active
    private var isJournalFilterActive: Bool {
        selectedJournalId != nil
    }
    
    // Get selected journal name for display
    private var selectedJournalName: String? {
        guard let journalId = selectedJournalId else { return nil }
        return viewModel.journals.first(where: { $0.id == journalId })?.name
    }
    
    var groupedEntries: [(String, [JournalEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            entry.createdAt.relativeString
        }
        return grouped.sorted { $0.value.first!.createdAt > $1.value.first!.createdAt }
    }
    
    // Check if there are any entries at all (ignoring filters)
    private var hasAnyEntries: Bool {
        !viewModel.entries.isEmpty
    }
    
    // Check if there are entries for the selected journal (when filter is active)
    private var hasEntriesInSelectedJournal: Bool {
        guard let journalId = selectedJournalId else { return true }
        return viewModel.entries.contains { $0.journalId == journalId }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            if !hasAnyEntries {
                emptyState
            } else if isJournalFilterActive && !hasEntriesInSelectedJournal {
                // Journal is selected but has no entries
                noEntriesInJournalView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Papper.spacing.md) {
                        // Search Bar
                        searchBar
                        
                        // Entries
                        if filteredEntries.isEmpty {
                            noResultsView
                        } else {
                            ForEach(Array(groupedEntries.enumerated()), id: \.offset) { _, group in
                                let (dateGroup, entries) = group
                                VStack(alignment: .leading, spacing: Papper.spacing.sm) {
                                    Text(dateGroup)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(PapperColors.neutral500)
                                        .padding(.leading, 4)
                                    
                                    ForEach(entries) { entry in
                                        NavigationLink(destination: JournalEntryView(entry: entry)) {
                                            EntryListCard(entry: entry, viewModel: viewModel)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    .padding(.top, Papper.spacing.xs)
                    .padding(.bottom, Papper.spacing.md)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: Papper.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral400)
            
            TextField("Search entries", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(PapperColors.neutral800)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(PapperColors.neutral400)
                }
            }
        }
        .padding(Papper.spacing.sm)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Papper.spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral400)
            
            VStack(spacing: Papper.spacing.xs) {
                Text("No Entries Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Tap the + button to create\nyour first entry")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Papper.spacing.xl)
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: Papper.spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(PapperColors.neutral400)
            
            Text("No entries found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(PapperColors.neutral600)
            
            if isJournalFilterActive {
                Text("Try a different search term\nor select \"All Journals\"")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral500)
                    .multilineTextAlignment(.center)
            } else {
                Text("Try a different search term")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral500)
            }
        }
        .padding(Papper.spacing.xxl)
    }
    
    // MARK: - No Entries in Selected Journal
    
    private var noEntriesInJournalView: some View {
        VStack(spacing: Papper.spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral400)
            
            VStack(spacing: Papper.spacing.xs) {
                Text("No Entries in \(selectedJournalName ?? "this journal")")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                    .multilineTextAlignment(.center)
                
                Text("Tap the + button to create\nan entry in this journal")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Entry List Card

struct EntryListCard: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    
    var body: some View {
        HStack(spacing: Papper.spacing.md) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: viewModel.getJournalColor(for: entry)))
                .frame(width: 4, height: 60)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PapperColors.neutral800)
                    .lineLimit(1)
                
                Text(entry.shortPreview)
                    .font(.system(size: 14))
                    .foregroundColor(PapperColors.neutral600)
                    .lineLimit(2)
                
                HStack(spacing: Papper.spacing.md) {
                    Text(viewModel.getJournalName(for: entry))
                        .font(.system(size: 11))
                        .foregroundColor(PapperColors.neutral500)
                    
                    Spacer()
                    
                    Text(entry.createdAt.timeString)
                        .font(.system(size: 11))
                        .foregroundColor(PapperColors.neutral500)
                }
            }
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Preview

#if DEBUG
struct EntriesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EntriesListView(selectedJournalId: .constant(nil))
        }
    }
}
#endif
