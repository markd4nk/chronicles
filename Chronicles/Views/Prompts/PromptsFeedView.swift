//
//  PromptsFeedView.swift
//  Chronicles
//
//  TikTok-style vertical scrolling prompts feed
//

import SwiftUI
import AVFoundation

struct PromptsFeedView: View {
    @StateObject private var viewModel = PromptsViewModel()
    @State private var showCreateEntry = false
    @State private var selectedPrompt: JournalPrompt?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                // Prompts Feed - Vertical scrolling
                if viewModel.prompts.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.prompts) { prompt in
                                PromptCardView(
                                    prompt: prompt,
                                    onLike: {
                                        Task {
                                            await viewModel.likePrompt(prompt)
                                        }
                                    },
                                    onShare: {
                                        Task {
                                            await viewModel.sharePrompt(prompt)
                                        }
                                    },
                                    onWriteItOut: {
                                        selectedPrompt = prompt
                                        showCreateEntry = true
                                    }
                                )
                                .frame(height: geometry.size.height)
                                .id(prompt.id)
                            }
                        }
                    }
                    .scrollTargetBehavior(.paging)
                }
            }
        }
        .sheet(isPresented: $showCreateEntry) {
            if let prompt = selectedPrompt {
                CreateEntryFromPromptView(prompt: prompt)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Papper.spacing.lg) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral400)
            
            Text("No prompts yet")
                .font(Papper.typography.body)
                .foregroundColor(PapperColors.neutral600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Prompt Card View

struct PromptCardView: View {
    let prompt: JournalPrompt
    let onLike: () -> Void
    let onShare: () -> Void
    let onWriteItOut: () -> Void
    
    var body: some View {
        ZStack {
            // Background Card
            VStack(spacing: Papper.spacing.xl) {
                Spacer()
                    .frame(height: 40)
                
                // Category Icon
                ZStack {
                    Circle()
                        .fill(PapperColors.neutral100)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: prompt.category.icon)
                        .font(.system(size: 32))
                        .foregroundColor(PapperColors.neutral700)
                }
                
                // Prompt Content
                VStack(spacing: Papper.spacing.md) {
                    Text(prompt.question)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(PapperColors.neutral800)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                    
                    Text(prompt.hint)
                        .font(.system(size: 16))
                        .foregroundColor(PapperColors.neutral600)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, Papper.spacing.xl)
                
                Spacer()
                
                // Action Bar - pushed up for better visibility
                HStack(spacing: Papper.spacing.xxl) {
                    // Share Button
                    Button(action: onShare) {
                        VStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                            Text("\(prompt.shares)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(PapperColors.neutral600)
                    }
                    
                    // Write It Out Button - prominent
                    Button(action: onWriteItOut) {
                        HStack(spacing: Papper.spacing.xs) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Write it Out")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Papper.spacing.xl)
                        .padding(.vertical, Papper.spacing.md)
                        .background(PapperColors.neutral700)
                        .cornerRadius(25)
                    }
                    
                    // Like Button
                    Button(action: onLike) {
                        VStack(spacing: 4) {
                            Image(systemName: prompt.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(prompt.isLiked ? PapperColors.pink600 : PapperColors.neutral600)
                            Text("\(prompt.likes)")
                                .font(.system(size: 12))
                                .foregroundColor(PapperColors.neutral600)
                        }
                    }
                }
                .padding(.bottom, 120) // Space for tab bar
            }
            .padding(.horizontal, Papper.spacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(PapperColors.surfaceBackgroundPlain)
                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
                .padding(.horizontal, Papper.spacing.md)
                .padding(.vertical, Papper.spacing.md)
        )
    }
}

// MARK: - Create Entry From Prompt

struct CreateEntryFromPromptView: View {
    let prompt: JournalPrompt
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedJournal: Journal?
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
            mainContent
                .navigationTitle("Write Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .onAppear {
                    selectedJournal = viewModel.journals.first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isEditorFocused = true
                    }
                }
                .confirmationDialog("Add from Photo", isPresented: $showScanActionSheet, titleVisibility: .visible) {
                    Button("Take Photo") { showCamera = true }
                    Button("Choose from Library") { showImagePicker = true }
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
                        appendText(transcribedText)
                    })
                }
                .onChange(of: selectedImage) { _, newImage in
                    if let image = newImage {
                        processOCR(image: image)
                    }
                }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            ScrollView {
                formContent
            }
            .onTapGesture {
                isEditorFocused = true
            }
            
            if isProcessingOCR {
                loadingOverlay
            }
        }
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xl) {
            promptSection
            journalSection
            responseSection
        }
        .padding(Papper.spacing.lg)
    }
    
    // MARK: - Prompt Section
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Prompt")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            Text(prompt.question)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(PapperColors.neutral800)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PapperColors.neutral100)
        .cornerRadius(12)
    }
    
    // MARK: - Journal Section
    
    private var journalSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Journal")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            journalPicker
        }
    }
    
    private var journalPicker: some View {
        Menu {
            ForEach(viewModel.journals) { journal in
                Button(action: { selectedJournal = journal }) {
                    HStack {
                        Circle()
                            .fill(journal.displayColor)
                            .frame(width: 8, height: 8)
                        Text(journal.name)
                    }
                }
            }
        } label: {
            journalPickerLabel
        }
    }
    
    private var journalPickerLabel: some View {
        HStack {
            if let journal = selectedJournal {
                Circle()
                    .fill(journal.displayColor)
                    .frame(width: 8, height: 8)
                Text(journal.name)
                    .foregroundColor(PapperColors.neutral800)
            } else {
                Text("Select a journal")
                    .foregroundColor(PapperColors.neutral500)
            }
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundColor(PapperColors.neutral400)
        }
        .padding()
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
    }
    
    // MARK: - Response Section
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.xs) {
            Text("Your response")
                .font(Papper.typography.bodySmall)
                .foregroundColor(PapperColors.neutral500)
            
            TextEditor(text: $content)
                .font(.system(size: 16))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200)
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(12)
                .focused($isEditorFocused)
        }
    }
    
    // MARK: - Toolbar Content
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
            .foregroundColor(canSave ? PapperColors.neutral700 : PapperColors.neutral400)
            .disabled(!canSave)
        }
        
        ToolbarItemGroup(placement: .keyboard) {
            keyboardToolbarContent
        }
    }
    
    @ViewBuilder
    private var keyboardToolbarContent: some View {
        Button(action: { isEditorFocused = false }) {
            Image(systemName: "chevron.down")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(PapperColors.neutral700)
                .frame(width: 32, height: 32)
                .background(PapperColors.neutral200)
                .clipShape(Circle())
        }
        
        Spacer()
        
        Button(action: { showScanActionSheet = true }) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral700)
                .frame(width: 32, height: 32)
                .background(PapperColors.neutral200)
                .clipShape(Circle())
        }
        
        Button(action: { showListeningView = true }) {
            Image(systemName: "mic.fill")
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral700)
                .frame(width: 32, height: 32)
                .background(PapperColors.neutral200)
                .clipShape(Circle())
        }
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
                
                Text("Processing image...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PapperColors.neutral700)
            }
            .padding(Papper.spacing.xl)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Helpers
    
    private var canSave: Bool {
        selectedJournal != nil && !content.isEmpty && !isSaving
    }
    
    private func appendText(_ text: String) {
        if !content.isEmpty && !content.hasSuffix("\n") {
            content += "\n\n"
        }
        content += text
    }
    
    private func processOCR(image: UIImage) {
        isProcessingOCR = true
        
        Task {
            do {
                let extractedText = try await AIService.shared.extractTextFromImage(image)
                
                await MainActor.run {
                    appendText(extractedText)
                    selectedImage = nil
                    isProcessingOCR = false
                }
            } catch {
                await MainActor.run {
                    selectedImage = nil
                    isProcessingOCR = false
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let journal = selectedJournal else { return }
        isSaving = true
        
        Task {
            await viewModel.createEntry(
                journalId: journal.id,
                title: String(prompt.question.prefix(50)),
                content: content,
                inputMethod: .write,
                promptId: prompt.id
            )
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PromptsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        PromptsFeedView()
    }
}
#endif
