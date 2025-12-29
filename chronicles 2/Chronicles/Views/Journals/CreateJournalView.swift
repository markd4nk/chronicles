//
//  CreateJournalView.swift
//  Chronicles
//
//  Create new journal form
//

import SwiftUI

struct CreateJournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedColor = Journal.availableColors[0]
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Papper.spacing.xxl) {
                        // Preview
                        journalPreview
                        
                        // Name Input
                        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                            Text("Journal Name")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            TextField("e.g., Daily Reflections", text: $name)
                                .font(.system(size: 16))
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(12)
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: Papper.spacing.sm) {
                            Text("Color")
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(PapperColors.neutral600)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Papper.spacing.md) {
                                ForEach(Journal.availableColors, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 50, height: 50)
                                            
                                            if selectedColor == color {
                                                Circle()
                                                    .stroke(PapperColors.neutral700, lineWidth: 3)
                                                    .frame(width: 58, height: 58)
                                                
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(PapperColors.surfaceBackgroundPlain)
                            .cornerRadius(16)
                        }
                        
                        Spacer()
                    }
                    .padding(Papper.spacing.lg)
                }
            }
            .navigationTitle("New Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createJournal()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral700)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }
    
    // MARK: - Journal Preview
    
    private var journalPreview: some View {
        VStack(spacing: Papper.spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: selectedColor).opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color(hex: selectedColor))
            }
            
            Text(name.isEmpty ? "Journal Name" : name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(name.isEmpty ? PapperColors.neutral400 : PapperColors.neutral800)
        }
        .padding(.top, Papper.spacing.xl)
    }
    
    // MARK: - Create Journal
    
    private func createJournal() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true
        
        Task {
            await viewModel.createJournal(name: name, color: selectedColor)
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CreateJournalView_Previews: PreviewProvider {
    static var previews: some View {
        CreateJournalView()
    }
}
#endif
