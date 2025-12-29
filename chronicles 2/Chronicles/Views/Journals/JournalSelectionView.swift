//
//  JournalSelectionView.swift
//  Chronicles
//
//  Journal selection modal for entry creation
//

import SwiftUI

struct JournalSelectionView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreateJournal = false
    @State private var selectedJournal: Journal?
    @State private var showCreateEntry = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                if viewModel.journals.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Papper.spacing.md) {
                            // Header
                            VStack(spacing: Papper.spacing.xs) {
                                Text("Where would you like to write?")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(PapperColors.neutral800)
                                
                                Text("Select a journal for your new entry")
                                    .font(Papper.typography.body)
                                    .foregroundColor(PapperColors.neutral600)
                            }
                            .padding(.top, Papper.spacing.md)
                            
                            // Journal Cards
                            ForEach(viewModel.journals) { journal in
                                JournalSelectionCard(
                                    journal: journal,
                                    onTap: {
                                        selectedJournal = journal
                                        showCreateEntry = true
                                    }
                                )
                            }
                            
                            // Add New Journal
                            Button(action: { showCreateJournal = true }) {
                                HStack(spacing: Papper.spacing.md) {
                                    ZStack {
                                        Circle()
                                            .stroke(PapperColors.neutral400, style: StrokeStyle(lineWidth: 2, dash: [6]))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(PapperColors.neutral600)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Create New Journal")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(PapperColors.neutral700)
                                        
                                        Text("Start a new collection")
                                            .font(Papper.typography.bodySmall)
                                            .foregroundColor(PapperColors.neutral500)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(Papper.spacing.md)
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(PapperColors.neutral300, style: StrokeStyle(lineWidth: 1, dash: [6]))
                                )
                            }
                        }
                        .padding(.horizontal, Papper.spacing.lg)
                        .padding(.bottom, Papper.spacing.xxxl)
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
            }
            .sheet(isPresented: $showCreateJournal) {
                CreateJournalView()
            }
            .fullScreenCover(isPresented: $showCreateEntry) {
                if let journal = selectedJournal {
                    CreateEntryView(journal: journal)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Papper.spacing.lg) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral400)
            
            VStack(spacing: Papper.spacing.xs) {
                Text("No Journals Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Create your first journal to start writing")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
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

// MARK: - Journal Selection Card

struct JournalSelectionCard: View {
    let journal: Journal
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Papper.spacing.md) {
                // Color indicator
                ZStack {
                    Circle()
                        .fill(journal.displayColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 20))
                        .foregroundColor(journal.displayColor)
                }
                
                // Journal info
                VStack(alignment: .leading, spacing: 2) {
                    Text(journal.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(PapperColors.neutral800)
                    
                    Text("\(journal.entryCount) entries")
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(PapperColors.neutral500)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PapperColors.neutral400)
            }
            .padding(Papper.spacing.md)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct JournalSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        JournalSelectionView()
    }
}
#endif

