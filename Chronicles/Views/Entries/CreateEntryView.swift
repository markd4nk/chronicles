//
//  CreateEntryView.swift
//  Chronicles
//
//  Entry creation with unified interface - text editor always visible
//  Keyboard toolbar provides quick access to scan and speak actions
//

import SwiftUI
import AVFoundation
import Photos

struct CreateEntryView: View {
    let journal: Journal
    var template: JournalTemplate? = nil
    var prompt: JournalPrompt? = nil
    var onSaveComplete: (() -> Void)? = nil
    
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
    
    // Permission states
    @State private var showCameraPermissionAlert = false
    @State private var showPhotoLibraryPermissionAlert = false
    @State private var showCameraUnavailableAlert = false
    @State private var cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#faf8f3")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content - text editor always visible
                    ScrollView {
                        VStack(alignment: .leading, spacing: Papper.spacing.md) {
                            // Text Editor
                            TextEditor(text: $content)
                                .font(.system(size: 16))
                                .foregroundColor(PapperColors.neutral800)
                                .scrollContentBackground(.hidden)
                                .focused($isEditorFocused)
                                .frame(minHeight: 350)
                                .padding()
                                .background(PapperColors.surfaceBackgroundPlain)
                                .cornerRadius(16)
                        }
                        .padding(Papper.spacing.lg)
                        .padding(.top, Papper.spacing.md) // Minimal spacing below navigation bar
                        .padding(.bottom, 60) // Space for bottom toolbar
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isEditorFocused = true
                    }
                    
                    // Fixed bottom toolbar
                    bottomToolbar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
                
                // Journal indicator and date in center
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        HStack(spacing: Papper.spacing.xs) {
                            Circle()
                                .fill(journal.displayColor)
                                .frame(width: 8, height: 8)
                            
                            Text(journal.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(PapperColors.neutral700)
                        }
                        
                        Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.system(size: 11))
                            .foregroundColor(PapperColors.neutral500)
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
            .task {
                // Setup template content
                setupFromTemplate()
                
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
                    // Append transcribed text to content
                    if !content.isEmpty && !content.hasSuffix("\n") {
                        content += "\n\n"
                    }
                    content += transcribedText
                })
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    processOCR(image: image)
                }
            }
            .overlay {
                if isProcessingOCR {
                    loadingOverlay
                }
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: Papper.spacing.md) {
            // Dismiss keyboard button
            Button(action: {
                isEditorFocused = false
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isEditorFocused ? PapperColors.neutral700 : PapperColors.neutral400)
                    .frame(width: 40, height: 40)
                    .background(PapperColors.neutral100)
                    .clipShape(Circle())
            }
            .disabled(!isEditorFocused)
            
            Spacer()
            
            // Scan button
            Button(action: {
                isEditorFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showScanActionSheet = true
                }
            }) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 16))
                    .foregroundColor(PapperColors.neutral700)
                    .frame(width: 40, height: 40)
                    .background(PapperColors.neutral100)
                    .clipShape(Circle())
            }
            
            // Mic button
            Button(action: {
                showListeningView = true
            }) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundColor(PapperColors.neutral700)
                    .frame(width: 40, height: 40)
                    .background(PapperColors.neutral100)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Papper.spacing.lg)
        .padding(.vertical, Papper.spacing.sm)
        .background(
            Color(hex: "#faf8f3")
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
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
        
        // Generate date-based temporary title immediately (no waiting)
        let tempTitle = generateDateTitle()
        let entryContent = content
        
        Task {
            // STEP 1: Save entry immediately with date title
            let entryId = await viewModel.createEntry(
                journalId: journal.id,
                title: tempTitle,
                content: entryContent,
                inputMethod: .write,
                templateId: template?.id,
                promptId: prompt?.id
            )
            
            // STEP 2: Switch tab and dismiss sheet - fullScreenCover auto-dismisses with sheet
            await MainActor.run {
                onSaveComplete?()
            }
            
            // STEP 3: Generate AI title in background and update quietly
            if let entryId = entryId {
                await generateAndUpdateTitle(entryId: entryId, content: entryContent)
            }
        }
    }
    
    /// Generate a date-based title for instant save
    private func generateDateTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    /// Generate AI title in background and update the entry quietly
    private func generateAndUpdateTitle(entryId: String, content: String) async {
        do {
            let aiTitle = try await AIService.shared.generateTitle(for: content)
            // Update the entry title quietly in background
            await viewModel.updateEntryTitle(entryId: entryId, newTitle: aiTitle)
        } catch {
            // Silently fail - entry already saved with date title
            print("Background title generation failed: \(error.localizedDescription)")
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

// MARK: - Scan Action Sheet

struct ScanActionSheet: View {
    let cameraAvailable: Bool
    let onTakePhoto: () -> Void
    let onChooseFromLibrary: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator is handled by presentationDragIndicator
            
            VStack(spacing: Papper.spacing.sm) {
                Text("Add from Photo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(PapperColors.neutral500)
                    .padding(.top, Papper.spacing.md)
                
                VStack(spacing: 0) {
                    // Take Photo option - only show if camera is available
                    if cameraAvailable {
                        Button(action: onTakePhoto) {
                            HStack(spacing: Papper.spacing.md) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(PapperColors.neutral700)
                                    .frame(width: 24)
                                
                                Text("Take Photo")
                                    .font(.system(size: 17))
                                    .foregroundColor(PapperColors.neutral800)
                                
                                Spacer()
                            }
                            .padding(.horizontal, Papper.spacing.lg)
                            .padding(.vertical, Papper.spacing.md)
                            .background(PapperColors.surfaceBackgroundPlain)
                        }
                        
                        Divider()
                            .padding(.leading, 56)
                    }
                    
                    // Choose from Library option
                    Button(action: onChooseFromLibrary) {
                        HStack(spacing: Papper.spacing.md) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 18))
                                .foregroundColor(PapperColors.neutral700)
                                .frame(width: 24)
                            
                            Text("Choose from Library")
                                .font(.system(size: 17))
                                .foregroundColor(PapperColors.neutral800)
                            
                            Spacer()
                        }
                        .padding(.horizontal, Papper.spacing.lg)
                        .padding(.vertical, Papper.spacing.md)
                        .background(PapperColors.surfaceBackgroundPlain)
                    }
                }
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(12)
                .padding(.horizontal, Papper.spacing.lg)
                
                // Cancel button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(PapperColors.neutral700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Papper.spacing.md)
                        .background(PapperColors.surfaceBackgroundPlain)
                        .cornerRadius(12)
                }
                .padding(.horizontal, Papper.spacing.lg)
                .padding(.bottom, Papper.spacing.lg)
            }
        }
        .background(Color(hex: "#faf8f3"))
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Safely set source type - fallback to photo library if camera unavailable
        if sourceType == .camera && !UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .photoLibrary
        } else {
            picker.sourceType = sourceType
        }
        
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

