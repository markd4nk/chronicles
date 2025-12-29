//
//  JournalEntryView.swift
//  Chronicles
//
//  View and edit a journal entry
//

import SwiftUI

struct JournalEntryView: View {
    let entry: JournalEntry
    
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Papper.spacing.xl) {
                    // Header
                    entryHeader
                    
                    // Content
                    if isEditing {
                        editingContent
                    } else {
                        displayContent
                    }
                }
                .padding(Papper.spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if isEditing {
                        Button(action: saveChanges) {
                            Label("Save", systemImage: "checkmark")
                        }
                        
                        Button(action: cancelEditing) {
                            Label("Cancel", systemImage: "xmark")
                        }
                    } else {
                        Button(action: startEditing) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: shareEntry) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(PapperColors.neutral700)
                }
            }
        }
        .alert("Delete Entry?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            editedTitle = entry.title
            editedContent = entry.content
        }
    }
    
    // MARK: - Entry Header
    
    private var entryHeader: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.md) {
            // Journal & Date
            HStack(spacing: Papper.spacing.md) {
                HStack(spacing: Papper.spacing.xs) {
                    Circle()
                        .fill(Color(hex: viewModel.getJournalColor(for: entry)))
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.getJournalName(for: entry))
                        .font(.system(size: 13))
                        .foregroundColor(PapperColors.neutral600)
                }
                .padding(.horizontal, Papper.spacing.sm)
                .padding(.vertical, 6)
                .background(Color(hex: viewModel.getJournalColor(for: entry)).opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
                
                // Input method
                HStack(spacing: 4) {
                    Image(systemName: entry.inputMethod.icon)
                        .font(.system(size: 12))
                    Text(entry.inputMethod.displayName)
                        .font(.system(size: 12))
                }
                .foregroundColor(PapperColors.neutral500)
            }
            
            // Date
            Text(entry.createdAt.fullDateString)
                .font(.system(size: 14))
                .foregroundColor(PapperColors.neutral500)
            
            // Title
            if isEditing {
                TextField("Title", text: $editedTitle)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(PapperColors.neutral800)
            } else {
                Text(entry.title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(PapperColors.neutral800)
            }
            
            // Stats
            HStack(spacing: Papper.spacing.lg) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(entry.createdAt.timeString)
                        .font(.system(size: 12))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "text.word.spacing")
                        .font(.system(size: 12))
                    Text("\(entry.wordCount) words")
                        .font(.system(size: 12))
                }
                
                Text(entry.readingTime)
                    .font(.system(size: 12))
            }
            .foregroundColor(PapperColors.neutral500)
        }
        .padding(Papper.spacing.lg)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Display Content
    
    private var displayContent: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.md) {
            Text(entry.content)
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral700)
                .lineSpacing(6)
        }
        .padding(Papper.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Editing Content
    
    private var editingContent: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.md) {
            TextEditor(text: $editedContent)
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral700)
                .frame(minHeight: 300)
            
            // Word count
            HStack {
                Spacer()
                Text("\(wordCount) words")
                    .font(.system(size: 12))
                    .foregroundColor(PapperColors.neutral500)
            }
        }
        .padding(Papper.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Actions
    
    private var wordCount: Int {
        editedContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    private func startEditing() {
        editedTitle = entry.title
        editedContent = entry.content
        isEditing = true
    }
    
    private func cancelEditing() {
        editedTitle = entry.title
        editedContent = entry.content
        isEditing = false
    }
    
    private func saveChanges() {
        var updated = entry
        updated.title = editedTitle
        updated.content = editedContent
        updated.updatedAt = Date()
        updated.wordCount = wordCount
        
        Task {
            await viewModel.updateEntry(updated)
            isEditing = false
        }
    }
    
    private func deleteEntry() {
        Task {
            await viewModel.deleteEntry(entry)
            dismiss()
        }
    }
    
    private func shareEntry() {
        let text = "\(entry.title)\n\n\(entry.content)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct JournalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JournalEntryView(entry: JournalEntry.sample)
        }
    }
}
#endif
