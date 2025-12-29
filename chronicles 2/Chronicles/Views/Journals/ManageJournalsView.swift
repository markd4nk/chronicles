//
//  ManageJournalsView.swift
//  Chronicles
//
//  Manage journals - rename, delete, reorder
//

import SwiftUI

struct ManageJournalsView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var editingJournal: Journal?
    @State private var showDeleteAlert = false
    @State private var journalToDelete: Journal?
    @State private var showCreateJournal = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                if viewModel.journals.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.journals) { journal in
                            JournalManageRow(
                                journal: journal,
                                onEdit: { editingJournal = journal },
                                onDelete: {
                                    journalToDelete = journal
                                    showDeleteAlert = true
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onMove(perform: moveJournals)
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, .constant(.active))
                }
            }
            .navigationTitle("Manage Journals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral700)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateJournal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(PapperColors.neutral700)
                    }
                }
            }
            .sheet(item: $editingJournal) { journal in
                EditJournalView(journal: journal)
            }
            .sheet(isPresented: $showCreateJournal) {
                CreateJournalView()
            }
            .alert("Delete Journal?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let journal = journalToDelete {
                        Task {
                            await viewModel.deleteJournal(journal)
                        }
                    }
                }
            } message: {
                Text("This will permanently delete the journal and all its entries. This action cannot be undone.")
            }
        }
    }
    
    private func moveJournals(from source: IndexSet, to destination: Int) {
        var reordered = viewModel.journals
        reordered.move(fromOffsets: source, toOffset: destination)
        
        Task {
            await viewModel.reorderJournals(reordered)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Papper.spacing.lg) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral400)
            
            Text("No journals to manage")
                .font(Papper.typography.body)
                .foregroundColor(PapperColors.neutral600)
            
            Button(action: { showCreateJournal = true }) {
                Text("Create Journal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Papper.spacing.xl)
                    .padding(.vertical, Papper.spacing.sm)
                    .background(PapperColors.neutral700)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Journal Manage Row

struct JournalManageRow: View {
    let journal: Journal
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: Papper.spacing.md) {
            // Color dot
            Circle()
                .fill(journal.displayColor)
                .frame(width: 12, height: 12)
            
            // Journal name
            VStack(alignment: .leading, spacing: 2) {
                Text(journal.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("\(journal.entryCount) entries")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(PapperColors.neutral500)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: Papper.spacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(PapperColors.neutral600)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(PapperColors.pink600)
                }
            }
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
    }
}

// MARK: - Edit Journal View

struct EditJournalView: View {
    let journal: Journal
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedColor: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                VStack(spacing: Papper.spacing.xl) {
                    // Name
                    VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                        Text("Name")
                            .font(Papper.typography.bodySmall)
                            .foregroundColor(PapperColors.neutral600)
                        
                        TextField("Journal name", text: $name)
                            .font(.system(size: 16))
                            .padding()
                            .background(PapperColors.surfaceBackgroundPlain)
                            .cornerRadius(12)
                    }
                    
                    // Color
                    VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                        Text("Color")
                            .font(Papper.typography.bodySmall)
                            .foregroundColor(PapperColors.neutral600)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Papper.spacing.md) {
                            ForEach(Journal.availableColors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 44, height: 44)
                                        
                                        if selectedColor == color {
                                            Circle()
                                                .stroke(PapperColors.neutral700, lineWidth: 3)
                                                .frame(width: 52, height: 52)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(PapperColors.surfaceBackgroundPlain)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(Papper.spacing.lg)
            }
            .navigationTitle("Edit Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral700)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = journal.name
                selectedColor = journal.color
            }
        }
    }
    
    private func saveChanges() {
        var updated = journal
        updated.name = name
        updated.color = selectedColor
        updated.updatedAt = Date()
        
        Task {
            await viewModel.updateJournal(updated)
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ManageJournalsView_Previews: PreviewProvider {
    static var previews: some View {
        ManageJournalsView()
    }
}
#endif

