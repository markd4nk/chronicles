//
//  PromptsFeedView.swift
//  Chronicles
//
//  TikTok-style vertical scrolling prompts feed
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

struct PromptsFeedView: View {
    @StateObject private var viewModel = PromptsViewModel()
    @State private var promptForEntry: JournalPrompt?
    @State private var showCopyFeedback = false
    @State private var currentVisibleIndex = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                // Prompts Feed - Vertical scrolling
                if viewModel.isLoadingPrompts && viewModel.filteredPrompts.isEmpty {
                    // Show loading state while prompts are being fetched
                    loadingState
                } else if viewModel.filteredPrompts.isEmpty {
                    emptyState
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(viewModel.filteredPrompts.enumerated()), id: \.element.id) { index, prompt in
                                    PromptCardView(
                                        prompt: prompt,
                                        showCopyFeedback: showCopyFeedback && currentVisibleIndex == index,
                                        onLike: {
                                            Task {
                                                await viewModel.likePrompt(prompt)
                                            }
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                        },
                                        onShare: {
                                            // Copy prompt question to clipboard
                                            UIPasteboard.general.string = prompt.question
                                            let generator = UINotificationFeedbackGenerator()
                                            generator.notificationOccurred(.success)
                                            
                                            // Show copy feedback
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                showCopyFeedback = true
                                            }
                                            
                                            // Hide after 1 second
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    showCopyFeedback = false
                                                }
                                            }
                                        },
                                        onWriteItOut: {
                                            promptForEntry = prompt
                                        }
                                    )
                                    .frame(height: geometry.size.height)
                                    .id("\(prompt.id)_\(index)")
                                    .onAppear {
                                        currentVisibleIndex = index
                                        // Check if we need to load more prompts
                                        viewModel.checkIfNearEnd(currentIndex: index)
                                    }
                                }
                            }
                        }
                        .scrollTargetBehavior(.paging)
                    }
                }
                
                // Overlay segmented control at top (TikTok-style)
                VStack {
                    segmentedControl
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.onTabAppear()
        }
        // Use item: binding - guarantees prompt exists when sheet presents
        .sheet(item: $promptForEntry) { prompt in
            CreateEntryFromPromptView(prompt: prompt)
        }
    }
    
    // MARK: - Segmented Control Overlay
    
    private var segmentedControl: some View {
        Picker("Feed Type", selection: $viewModel.showLikedOnly) {
            Text("For You").tag(false)
            Text("Liked").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 100)
        .padding(.vertical, Papper.spacing.sm)
        .background(
            Color(hex: "#faf8f3").opacity(0.95)
        )
    }
    
    private var loadingState: some View {
        VStack(spacing: Papper.spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(PapperColors.neutral600)
            
            Text("Loading prompts...")
                .font(Papper.typography.body)
                .foregroundColor(PapperColors.neutral600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: Papper.spacing.lg) {
            Image(systemName: viewModel.showLikedOnly ? "heart" : "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral400)
            
            Text(viewModel.showLikedOnly ? "No liked prompts yet" : "No prompts yet")
                .font(Papper.typography.body)
                .foregroundColor(PapperColors.neutral600)
            
            if viewModel.showLikedOnly {
                Text("Tap the heart on prompts you love")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(PapperColors.neutral500)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Prompt Card View

struct PromptCardView: View {
    let prompt: JournalPrompt
    var showCopyFeedback: Bool = false
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
                    
                    // Only show hint for quotes (attribution like "- Steve Jobs")
                    if prompt.category == .quote {
                        Text(prompt.hint)
                            .font(.system(size: 16))
                            .foregroundColor(PapperColors.neutral600)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, Papper.spacing.xl)
                
                Spacer()
                
                // Action Bar - pushed up for better visibility
                HStack(spacing: Papper.spacing.xxl) {
                    // Share Button (copies prompt to clipboard)
                    ZStack {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 24))
                                .foregroundColor(PapperColors.neutral600)
                                .frame(width: 44, height: 44)
                        }
                        
                        // Copy feedback indicator
                        if showCopyFeedback {
                            CopyFeedbackView()
                                .offset(y: -50)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
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
                    
                    // Like Button (saves to Liked section)
                    Button(action: onLike) {
                        Image(systemName: prompt.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(prompt.isLiked ? PapperColors.pink600 : PapperColors.neutral600)
                            .frame(width: 44, height: 44)
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

// MARK: - Copy Feedback View

struct CopyFeedbackView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
            Text("Copied")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(PapperColors.neutral700)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
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
    
    // Permission states
    @State private var showCameraPermissionAlert = false
    @State private var showPhotoLibraryPermissionAlert = false
    @State private var showCameraUnavailableAlert = false
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Write Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .task {
                    // Non-blocking setup
                    selectedJournal = viewModel.journals.first
                    
                    // Brief delay for view to render before keyboard
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                    await MainActor.run {
                        isEditorFocused = true
                    }
                }
                .sheet(isPresented: $showScanActionSheet) {
                    ScanActionSheet(
                        cameraAvailable: cameraAvailable,
                        onTakePhoto: {
                            showScanActionSheet = false
                            requestCameraAccess()
                        },
                        onChooseFromLibrary: {
                            showScanActionSheet = false
                            requestPhotoLibraryAccess()
                        },
                        onCancel: {
                            showScanActionSheet = false
                        }
                    )
                    .presentationDetents([.height(cameraAvailable ? 220 : 160)])
                    .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
                }
                .sheet(isPresented: $showCamera) {
                    if cameraAvailable {
                        ImagePicker(image: $selectedImage, sourceType: .camera)
                    }
                }
                .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
                    Button("Open Settings") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Please allow camera access in Settings to take photos for scanning.")
                }
                .alert("Photo Library Access Required", isPresented: $showPhotoLibraryPermissionAlert) {
                    Button("Open Settings") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Please allow photo library access in Settings to choose images for scanning.")
                }
                .alert("Camera Unavailable", isPresented: $showCameraUnavailableAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Camera is not available on this device. Please use 'Choose from Library' instead.")
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
            .scrollDismissesKeyboard(.interactively)
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
                .background(PapperColors.neutral100)
                .clipShape(Circle())
        }
        
        Spacer()
        
        Button(action: {
            // Dismiss keyboard first, then show dialog after animation completes
            isEditorFocused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showScanActionSheet = true
            }
        }) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral700)
                .frame(width: 32, height: 32)
                .background(PapperColors.neutral100)
                .clipShape(Circle())
        }
        
        Button(action: { showListeningView = true }) {
            Image(systemName: "mic.fill")
                .font(.system(size: 16))
                .foregroundColor(PapperColors.neutral700)
                .frame(width: 32, height: 32)
                .background(PapperColors.neutral100)
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
    
    // MARK: - Permission Handling
    
    private func requestCameraAccess() {
        // First check if camera hardware is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailableAlert = true
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .authorized:
            showCamera = true
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            showCameraPermissionAlert = true
        }
    }
    
    private func requestPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showImagePicker = true
                    } else {
                        showPhotoLibraryPermissionAlert = true
                    }
                }
            }
        case .authorized, .limited:
            showImagePicker = true
        case .denied, .restricted:
            showPhotoLibraryPermissionAlert = true
        @unknown default:
            showPhotoLibraryPermissionAlert = true
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
