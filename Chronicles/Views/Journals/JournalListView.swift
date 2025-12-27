//
//  JournalListView.swift
//  Chronicles
//
//  List of user's custom journals
//

import SwiftUI

struct JournalListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showCreateJournal = false
    @State private var searchText = ""
    
    var filteredJournals: [Journal] {
        if searchText.isEmpty {
            return viewModel.journals
        }
        return viewModel.journals.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            if viewModel.journals.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Papper.spacing.md) {
                        // Search Bar
                        searchBar
                        
                        // Journals List
                        ForEach(filteredJournals) { journal in
                            NavigationLink(destination: JournalDetailView(journal: journal)) {
                                JournalListCard(journal: journal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, Papper.spacing.lg)
                    .padding(.vertical, Papper.spacing.md)
                }
            }
        }
        .navigationTitle("Journals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateJournal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(PapperColors.neutral700)
                }
            }
        }
        .sheet(isPresented: $showCreateJournal) {
            CreateJournalView()
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: Papper.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral400)
            
            TextField("Search journals", text: $searchText)
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
                    .fill(PapperColors.neutral100)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 44))
                    .foregroundColor(PapperColors.neutral700)
            }
            
            VStack(spacing: Papper.spacing.xs) {
                Text("No Journals Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Create your first journal to start\ncapturing your thoughts")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showCreateJournal = true }) {
                HStack(spacing: Papper.spacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Create Journal")
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
}

// MARK: - Journal List Card

struct JournalListCard: View {
    let journal: Journal
    
    var body: some View {
        HStack(spacing: Papper.spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(journal.displayColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 22))
                    .foregroundColor(journal.displayColor)
            }
            
            // Journal info
            VStack(alignment: .leading, spacing: 4) {
                Text(journal.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                HStack(spacing: Papper.spacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 11))
                        Text("\(journal.entryCount) entries")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(PapperColors.neutral600)
                    
                    if let lastEntry = journal.lastEntryDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(lastEntry.relativeString)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(PapperColors.neutral500)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(PapperColors.neutral400)
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#if DEBUG
struct JournalListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JournalListView()
        }
    }
}
#endif
