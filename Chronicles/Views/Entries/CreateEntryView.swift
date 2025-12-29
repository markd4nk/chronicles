//
//  CreateEntryView.swift
//  Chronicles
//
//  Entry creation with multiple input methods (Write, Scan, Speak)
//

import SwiftUI

struct CreateEntryView: View {
    let journal: Journal
    var template: JournalTemplate? = nil
    var prompt: JournalPrompt? = nil
    
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedInputMethod: JournalEntry.InputMethod = .write
    @State private var isSaving = false
    @State private var showInputMethodPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Input Method Tabs
                    inputMethodTabs
                    
                    // Content based on input method
                    ScrollView {
                        VStack(alignment: .leading, spacing: Papper.spacing.xl) {
                            // Journal indicator
                            HStack(spacing: Papper.spacing.xs) {
                                Circle()
                                    .fill(journal.displayColor)
                                    .frame(width: 8, height: 8)
                                
                                Text(journal.name)
                                    .font(.system(size: 13))
                                    .foregroundColor(PapperColors.neutral600)
                            }
                            .padding(.horizontal, Papper.spacing.sm)
                            .padding(.vertical, 6)
                            .background(journal.displayColor.opacity(0.1))
                            .cornerRadius(20)
                            
                            // Title
                            TextField("Entry title", text: $title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(PapperColors.neutral800)
                            
                            // Content based on method
                            switch selectedInputMethod {
                            case .write:
                                writeInput
                            case .scan:
                                scanInput
                            case .speak:
                                speakInput
                            }
                        }
                        .padding(Papper.spacing.lg)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PapperColors.neutral700)
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                }
            }
            .onAppear {
                setupFromTemplate()
            }
        }
    }
    
    // MARK: - Input Method Tabs
    
    private var inputMethodTabs: some View {
        HStack(spacing: 0) {
            ForEach(JournalEntry.InputMethod.allCases, id: \.self) { method in
                Button(action: { selectedInputMethod = method }) {
                    VStack(spacing: 4) {
                        Image(systemName: method.icon)
                            .font(.system(size: 18))
                        
                        Text(method.displayName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedInputMethod == method ? PapperColors.neutral700 : PapperColors.neutral400)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Papper.spacing.sm)
                    .background(selectedInputMethod == method ? PapperColors.surfaceBackgroundPlain : Color.clear)
                    .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(PapperColors.neutral100)
        .cornerRadius(12)
        .padding(.horizontal, Papper.spacing.lg)
        .padding(.vertical, Papper.spacing.sm)
    }
    
    // MARK: - Write Input
    
    private var writeInput: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            TextEditor(text: $content)
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral800)
                .frame(minHeight: 300)
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(16)
            
            // Word count
            HStack {
                Spacer()
                Text("\(wordCount) words")
                    .font(.system(size: 12))
                    .foregroundColor(PapperColors.neutral500)
            }
        }
    }
    
    // MARK: - Scan Input (Placeholder for GPT OCR)
    
    private var scanInput: some View {
        VStack(spacing: Papper.spacing.xl) {
            // Placeholder for OCR
            VStack(spacing: Papper.spacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .foregroundColor(PapperColors.neutral300)
                        .frame(height: 200)
                    
                    VStack(spacing: Papper.spacing.md) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(PapperColors.neutral400)
                        
                        Text("Scan text from a photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(PapperColors.neutral600)
                        
                        Text("Coming soon with AI integration")
                            .font(.system(size: 13))
                            .foregroundColor(PapperColors.neutral500)
                    }
                }
                
                // Camera Button (Placeholder)
                Button(action: {
                    // TODO: Implement camera for OCR
                }) {
                    HStack(spacing: Papper.spacing.xs) {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(PapperColors.neutral400)
                    .cornerRadius(12)
                }
                .disabled(true)
            }
            
            // Manual text entry fallback
            VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                Text("Or type your entry")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(PapperColors.neutral500)
                
                TextEditor(text: $content)
                    .font(.system(size: 16))
                    .frame(minHeight: 150)
                    .padding()
                    .background(PapperColors.surfaceBackgroundPlain)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Speak Input (Placeholder for GPT Speech-to-Text)
    
    private var speakInput: some View {
        VStack(spacing: Papper.spacing.xl) {
            // Placeholder for Speech
            VStack(spacing: Papper.spacing.lg) {
                ZStack {
                    Circle()
                        .fill(PapperColors.neutral100)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundColor(PapperColors.neutral400)
                }
                
                Text("Voice recording")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PapperColors.neutral600)
                
                Text("Coming soon with AI integration")
                    .font(.system(size: 13))
                    .foregroundColor(PapperColors.neutral500)
                
                // Record Button (Placeholder)
                Button(action: {
                    // TODO: Implement voice recording
                }) {
                    HStack(spacing: Papper.spacing.xs) {
                        Image(systemName: "mic.fill")
                        Text("Start Recording")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(PapperColors.neutral400)
                    .cornerRadius(12)
                }
                .disabled(true)
            }
            
            // Manual text entry fallback
            VStack(alignment: .leading, spacing: Papper.spacing.xs) {
                Text("Or type your entry")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(PapperColors.neutral500)
                
                TextEditor(text: $content)
                    .font(.system(size: 16))
                    .frame(minHeight: 150)
                    .padding()
                    .background(PapperColors.surfaceBackgroundPlain)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    private func setupFromTemplate() {
        if let template = template {
            title = template.name
            content = template.formattedPrompts + "\n\n"
        }
        
        if let prompt = prompt {
            title = String(prompt.question.prefix(50))
            content = "Prompt: \(prompt.question)\n\n"
        }
    }
    
    private func saveEntry() {
        isSaving = true
        
        Task {
            await viewModel.createEntry(
                journalId: journal.id,
                title: title,
                content: content,
                inputMethod: selectedInputMethod,
                templateId: template?.id,
                promptId: prompt?.id
            )
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CreateEntryView_Previews: PreviewProvider {
    static var previews: some View {
        CreateEntryView(journal: Journal.sample)
    }
}
#endif
