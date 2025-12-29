//
//  CreateEntryView.swift
//  Chronicles
//
//  Entry creation with unified interface - text editor always visible
//  Write/Scan/Speak are action buttons that enhance the editor
//

import SwiftUI
import Speech
import AVFoundation

struct CreateEntryView: View {
    let journal: Journal
    var template: JournalTemplate? = nil
    var prompt: JournalPrompt? = nil
    
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var content = ""
    @State private var isSaving = false
    @State private var showScanActionSheet = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showListeningView = false
    @State private var selectedImage: UIImage?
    @State private var isProcessingOCR = false
    
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                // Main content - text editor always visible
                ScrollView {
                    VStack(alignment: .leading, spacing: Papper.spacing.lg) {
                        // Text Editor
                        TextEditor(text: $content)
                            .font(.system(size: 16))
                            .foregroundColor(PapperColors.neutral800)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 400)
                            .padding()
                            .background(PapperColors.surfaceBackgroundPlain)
                            .cornerRadius(16)
                            .focused($isEditorFocused)
                        
                        // Word count
                        HStack {
                            Spacer()
                            Text("\(wordCount) words")
                                .font(.system(size: 12))
                                .foregroundColor(PapperColors.neutral500)
                        }
                    }
                    .padding(Papper.spacing.lg)
                }
                .onTapGesture {
                    isEditorFocused = true
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Bottom action buttons - keyboard aware
                actionButtonsBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
                
                // Journal indicator in center (replacing title)
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Papper.spacing.xs) {
                        Circle()
                            .fill(journal.displayColor)
                            .frame(width: 8, height: 8)
                        
                        Text(journal.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(PapperColors.neutral700)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(content.isEmpty || isSaving ? PapperColors.neutral400 : PapperColors.neutral700)
                    .disabled(content.isEmpty || isSaving)
                }
            }
            .onAppear {
                setupFromTemplate()
                isEditorFocused = true
            }
            .confirmationDialog("Add from Photo", isPresented: $showScanActionSheet, titleVisibility: .visible) {
                Button("Take Photo") {
                    showCamera = true
                }
                Button("Choose from Library") {
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .fullScreenCover(isPresented: $showListeningView) {
                SpeakListeningView(onComplete: { transcribedText in
                    // Append transcribed text to content
                    if !content.isEmpty && !content.hasSuffix("\n") {
                        content += "\n\n"
                    }
                    content += transcribedText
                })
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    processOCR(image: image)
                }
            }
            .overlay {
                if isSaving || isProcessingOCR {
                    loadingOverlay
                }
            }
        }
    }
    
    // MARK: - Action Buttons Bar
    
    private var actionButtonsBar: some View {
        HStack(spacing: Papper.spacing.lg) {
            // Write button (focuses editor)
            ActionButton(
                icon: "pencil",
                label: "Write",
                action: {
                    isEditorFocused = true
                }
            )
            
            // Scan button (shows action sheet)
            ActionButton(
                icon: "doc.text.viewfinder",
                label: "Scan",
                action: {
                    showScanActionSheet = true
                }
            )
            
            // Speak button (opens listening view)
            ActionButton(
                icon: "mic.fill",
                label: "Speak",
                action: {
                    showListeningView = true
                }
            )
        }
        .padding(.horizontal, Papper.spacing.xl)
        .padding(.vertical, Papper.spacing.md)
        .background(
            Rectangle()
                .fill(PapperColors.surfaceBackgroundPlain)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: Papper.spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(PapperColors.neutral700)
                
                Text(isSaving ? "Generating title..." : "Processing image...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PapperColors.neutral700)
            }
            .padding(Papper.spacing.xl)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Helpers
    
    private var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    private func setupFromTemplate() {
        if let template = template {
            content = template.formattedPrompts + "\n\n"
        }
        
        if let prompt = prompt {
            content = "Prompt: \(prompt.question)\n\n"
        }
    }
    
    private func processOCR(image: UIImage) {
        isProcessingOCR = true
        
        Task {
            do {
                let extractedText = try await AIService.shared.extractTextFromImage(image)
                
                await MainActor.run {
                    // Append extracted text to content
                    if !content.isEmpty && !content.hasSuffix("\n") {
                        content += "\n\n"
                    }
                    content += extractedText
                    selectedImage = nil
                    isProcessingOCR = false
                }
            } catch {
                await MainActor.run {
                    // Fallback - just show error state
                    selectedImage = nil
                    isProcessingOCR = false
                }
            }
        }
    }
    
    private func saveEntry() {
        isSaving = true
        
        Task {
            // Generate title using AI
            let title = await generateTitle()
            
            await viewModel.createEntry(
                journalId: journal.id,
                title: title,
                content: content,
                inputMethod: .write,
                templateId: template?.id,
                promptId: prompt?.id
            )
            
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func generateTitle() async -> String {
        do {
            let generatedTitle = try await AIService.shared.generateTitle(for: content)
            return generatedTitle
        } catch {
            // Fallback to date/time
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return formatter.string(from: Date())
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(PapperColors.neutral100)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(PapperColors.neutral700)
                }
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(PapperColors.neutral600)
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
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
