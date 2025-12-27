//
//  JournalDetailView.swift
//  Chronicles
//
//  View entries for a specific journal
//

import SwiftUI

struct JournalDetailView: View {
    let journal: Journal
    
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreateEntry = false
    @State private var showEditJournal = false
    @State private var searchText = ""
    
    var entriesForJournal: [JournalEntry] {
        let entries = viewModel.entriesForJournal(journal.id)
        
        if searchText.isEmpty {
            return entries
        }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var groupedEntries: [(String, [JournalEntry])] {
        let grouped = Dictionary(grouping: entriesForJournal) { entry in
            entry.createdAt.relativeString
        }
        return grouped.sorted { $0.value.first!.createdAt > $1.value.first!.createdAt }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            if entriesForJournal.isEmpty && searchText.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Papper.spacing.md) {
                        // Journal Header
                        journalHeader
                        
                        // Search
                        searchBar
                        
                        // Entries
                        if entriesForJournal.isEmpty {
                            noResultsView
                        } else {
                            ForEach(groupedEntries, id: \.0) { dateGroup, entries in
                                VStack(alignment: .leading, spacing: Papper.spacing.sm) {
                                    Text(dateGroup)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(PapperColors.neutral500)
                                        .padding(.leading, 4)
                                    
                                    ForEach(entries) { entry in
                                        NavigationLink(destination: JournalEntryView(entry: entry)) {
                                            JournalDetailEntryCard(entry: entry)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    .padding(.vertical, Papper.spacing.md)
                }
            }
        }
        .navigationTitle(journal.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showCreateEntry = true }) {
                        Label("New Entry", systemImage: "plus")
                    }
                    
                    Button(action: { showEditJournal = true }) {
                        Label("Edit Journal", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(PapperColors.neutral700)
                }
            }
        }
        .fullScreenCover(isPresented: $showCreateEntry) {
            CreateEntryView(journal: journal)
        }
        .sheet(isPresented: $showEditJournal) {
            EditJournalView(journal: journal)
        }
    }
    
    // MARK: - Journal Header
    
    private var journalHeader: some View {
        HStack(spacing: Papper.spacing.md) {
            ZStack {
                Circle()
                    .fill(journal.displayColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 28))
                    .foregroundColor(journal.displayColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(journal.entryCount) entries")
                    .font(.system(size: 14))
                    .foregroundColor(PapperColors.neutral600)
                
                if let lastEntry = journal.lastEntryDate {
                    Text("Last entry: \(lastEntry.relativeString)")
                        .font(.system(size: 12))
                        .foregroundColor(PapperColors.neutral500)
                }
            }
            
            Spacer()
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
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
            ZStack {
                Circle()
                    .fill(journal.displayColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 44))
                    .foregroundColor(journal.displayColor)
            }
            
            VStack(spacing: Papper.spacing.xs) {
                Text("No Entries Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Start writing your first entry\nin this journal")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showCreateEntry = true }) {
                HStack(spacing: Papper.spacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("New Entry")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Papper.spacing.xl)
                .padding(.vertical, Papper.spacing.sm)
                .background(PapperColors.neutral700)
                .cornerRadius(12)
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
        }
        .padding(Papper.spacing.xxl)
    }
}

// MARK: - Journal Detail Entry Card

struct JournalDetailEntryCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.sm) {
            HStack {
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: entry.inputMethod.icon)
                        .font(.system(size: 11))
                    Text(entry.createdAt.timeString)
                        .font(.system(size: 11))
                }
                .foregroundColor(PapperColors.neutral500)
            }
            
            Text(entry.shortPreview)
                .font(.system(size: 14))
                .foregroundColor(PapperColors.neutral600)
                .lineLimit(2)
            
            HStack {
                Text("\(entry.wordCount) words")
                    .font(.system(size: 11))
                    .foregroundColor(PapperColors.neutral500)
                
                Spacer()
                
                Text(entry.readingTime)
                    .font(.system(size: 11))
                    .foregroundColor(PapperColors.neutral500)
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
struct JournalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JournalDetailView(journal: Journal.sample)
        }
    }
}
#endif
