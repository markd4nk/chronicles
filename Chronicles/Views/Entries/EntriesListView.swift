//
//  EntriesListView.swift
//  Chronicles
//
//  List view of all entries
//

import SwiftUI

struct EntriesListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var searchText = ""
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return viewModel.entries.sorted { $0.createdAt > $1.createdAt }
        }
        return viewModel.entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var groupedEntries: [(String, [JournalEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            entry.createdAt.relativeString
        }
        return grouped.sorted { $0.value.first!.createdAt > $1.value.first!.createdAt }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            if viewModel.entries.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Papper.spacing.md) {
                        // Search Bar
                        searchBar
                        
                        // Entries
                        if filteredEntries.isEmpty {
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
                                            EntryListCard(entry: entry, viewModel: viewModel)
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
            
            Text("Try a different search term")
                .font(Papper.typography.body)
                .foregroundColor(PapperColors.neutral500)
        }
        .padding(Papper.spacing.xxl)
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
                HStack {
                    Text(entry.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(PapperColors.neutral800)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: entry.inputMethod.icon)
                        .font(.system(size: 12))
                        .foregroundColor(PapperColors.neutral400)
                }
                
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
            EntriesListView()
        }
    }
}
#endif
