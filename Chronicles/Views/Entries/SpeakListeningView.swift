//
//  SpeakListeningView.swift
//  Chronicles
//
//  Full-screen listening page with animated blob for speech-to-text
//  Uses OpenAI Whisper API via Firebase Cloud Functions
//

import SwiftUI
import AVFoundation

struct SpeakListeningView: View {
    let onComplete: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    private let audioRecorder = WhisperAudioRecorder()
    
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var transcribedText = ""
    @State private var showPermissionAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            VStack(spacing: Papper.spacing.xxl) {
                // Top bar with cancel
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(PapperColors.neutral600)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, Papper.spacing.lg)
                .padding(.top, Papper.spacing.md)
                
                Spacer()
                
                // Animated listening blob
                listeningBlob
                
                // Status text
                VStack(spacing: Papper.spacing.sm) {
                    Text(statusText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(PapperColors.neutral800)
                    
                    if isRecording {
                        Text("Speak clearly into your device")
                            .font(.system(size: 14))
                            .foregroundColor(PapperColors.neutral600)
                    } else if isTranscribing {
                        Text("Processing with Whisper AI...")
                            .font(.system(size: 14))
                            .foregroundColor(PapperColors.neutral600)
                    }
                }
                
                // Transcription preview
                if !transcribedText.isEmpty {
                    ScrollView {
                        Text(transcribedText)
                            .font(.system(size: 16))
                            .foregroundColor(PapperColors.neutral700)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Papper.spacing.xl)
                    }
                    .frame(maxHeight: 150)
                    .padding(.top, Papper.spacing.lg)
                }
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            
            // Loading overlay for transcription
            if isTranscribing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: Papper.spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Transcribing...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(Papper.spacing.xl)
                .background(PapperColors.neutral800.opacity(0.9))
                .cornerRadius(16)
            }
        }
        .onAppear {
            checkPermissions()
        }
        .onDisappear {
            if isRecording {
                audioRecorder.stopRecording()
            }
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please enable microphone access in Settings to use voice recording.")
        }
        .alert("Transcription Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var statusText: String {
        if isTranscribing {
            return "Transcribing..."
        } else if isRecording {
            return "Listening..."
        } else if !transcribedText.isEmpty {
            return "Recording complete"
        } else {
            return "Tap to start"
        }
    }
    
    // MARK: - Listening Blob
    
    private var listeningBlob: some View {
        ZStack {
            // Outer pulse rings
            if isRecording {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(PapperColors.neutral700.opacity(0.1), lineWidth: 2)
                        .frame(width: 160 + CGFloat(index * 40), height: 160 + CGFloat(index * 40))
                        .scaleEffect(animationScale)
                        .opacity(pulseOpacity - Double(index) * 0.1)
                }
            }
            
            // Main blob
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            PapperColors.neutral600,
                            PapperColors.neutral700,
                            PapperColors.neutral800
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .scaleEffect(isRecording ? animationScale : 1.0)
                .shadow(color: PapperColors.neutral700.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Inner icon
            if isTranscribing {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else {
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: isRecording ? 40 : 50))
                    .foregroundColor(.white)
                    .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isRecording)
            }
        }
        .onTapGesture {
            if !isTranscribing {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: Papper.spacing.md) {
            if isRecording {
                // Stop button
                Button(action: stopRecording) {
                    HStack(spacing: Papper.spacing.sm) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16))
                        Text("Stop Recording")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(PapperColors.pink600)
                    .cornerRadius(14)
                }
                .padding(.horizontal, Papper.spacing.xl)
            } else if isTranscribing {
                // Transcribing state - disabled button
                HStack(spacing: Papper.spacing.sm) {
                    ProgressView()
                        .tint(.white)
                    Text("Processing...")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(PapperColors.neutral500)
                .cornerRadius(14)
                .padding(.horizontal, Papper.spacing.xl)
            } else if !transcribedText.isEmpty {
                // Done button (when we have text)
                Button(action: completeRecording) {
                    HStack(spacing: Papper.spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add to Entry")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(PapperColors.neutral700)
                    .cornerRadius(14)
                }
                .padding(.horizontal, Papper.spacing.xl)
                
                // Record more button
                Button(action: startRecording) {
                    Text("Record More")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(PapperColors.neutral600)
                }
            } else {
                // Start recording button
                Button(action: startRecording) {
                    HStack(spacing: Papper.spacing.sm) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                        Text("Start Recording")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(PapperColors.neutral700)
                    .cornerRadius(14)
                }
                .padding(.horizontal, Papper.spacing.xl)
            }
        }
        .padding(.bottom, Papper.spacing.xxxl)
    }
    
    // MARK: - Helper Methods
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            animationScale = 1.1
            pulseOpacity = 0.5
        }
    }
    
    private func checkPermissions() {
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            await MainActor.run {
                if !granted {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func startRecording() {
        do {
            try audioRecorder.startRecording()
            isRecording = true
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func stopRecording() {
        isRecording = false
        isTranscribing = true
        
        Task {
            do {
                let audioData = try audioRecorder.stopRecordingAndGetData()
                let newTranscription = try await AIService.shared.transcribeAudio(
                    audioData: audioData,
                    mimeType: "audio/m4a"
                )
                
                await MainActor.run {
                    // Append to existing text if "Record More" was used
                    if !transcribedText.isEmpty {
                        transcribedText += " " + newTranscription
                    } else {
                        transcribedText = newTranscription
                    }
                    isTranscribing = false
                }
            } catch {
                await MainActor.run {
                    isTranscribing = false
                    errorMessage = "Failed to transcribe: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func completeRecording() {
        onComplete(transcribedText)
        dismiss()
    }
}

// MARK: - Whisper Audio Recorder

class WhisperAudioRecorder {
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    
    func startRecording() throws {
        // Set up audio session first
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
        
        // Create unique file URL for recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        audioFileURL = audioFilename
        
        // Recording settings optimized for Whisper
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,  // 16kHz is optimal for Whisper
            AVNumberOfChannelsKey: 1,  // Mono
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        // Create recorder
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        
        // Prepare the recorder (this validates the settings)
        guard let recorder = audioRecorder, recorder.prepareToRecord() else {
            throw RecordingError.setupFailed
        }
        
        // Start recording
        guard recorder.record() else {
            throw RecordingError.startFailed
        }
    }
    
    func stopRecordingAndGetData() throws -> Data {
        audioRecorder?.stop()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        guard let fileURL = audioFileURL else {
            throw RecordingError.noRecording
        }
        
        // Read the audio file data
        let audioData = try Data(contentsOf: fileURL)
        
        // Clean up the file
        try? FileManager.default.removeItem(at: fileURL)
        audioFileURL = nil
        
        // Validate audio data isn't empty or too small (at least 1KB)
        guard audioData.count > 1024 else {
            throw RecordingError.noAudioData
        }
        
        return audioData
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        // Clean up any existing file
        if let fileURL = audioFileURL {
            try? FileManager.default.removeItem(at: fileURL)
            audioFileURL = nil
        }
    }
    
    enum RecordingError: LocalizedError {
        case noRecording
        case setupFailed
        case startFailed
        case noAudioData
        
        var errorDescription: String? {
            switch self {
            case .noRecording:
                return "No recording available"
            case .setupFailed:
                return "Failed to set up audio recorder. Please check your microphone permissions."
            case .startFailed:
                return "Failed to start recording. Please try again."
            case .noAudioData:
                return "Recording was too short or empty. Please try again and speak for longer."
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SpeakListeningView_Previews: PreviewProvider {
    static var previews: some View {
        SpeakListeningView(onComplete: { _ in })
    }
}
#endif
