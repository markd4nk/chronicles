//
//  SpeakListeningView.swift
//  Chronicles
//
//  Full-screen listening page with animated blob for speech-to-text
//

import SwiftUI
import Speech
import AVFoundation
import Combine

struct SpeakListeningView: View {
    let onComplete: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var showPermissionAlert = false
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
                    Text(isRecording ? "Listening..." : "Tap to start")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(PapperColors.neutral800)
                    
                    if isRecording {
                        Text("Speak clearly into your device")
                            .font(.system(size: 14))
                            .foregroundColor(PapperColors.neutral600)
                    }
                }
                
                // Live transcription preview
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
        }
        .onAppear {
            checkPermissions()
        }
        .onDisappear {
            if isRecording {
                stopRecording()
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
        .onChange(of: speechRecognizer.transcript) { newValue in
            transcribedText = newValue
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
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: isRecording ? 40 : 50))
                .foregroundColor(.white)
                .symbolEffect(.variableColor.iterative, options: .repeating, isActive: isRecording)
        }
        .onTapGesture {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
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
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status != .authorized {
                    showPermissionAlert = true
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func startRecording() {
        do {
            try speechRecognizer.startTranscribing()
            isRecording = true
        } catch {
            // Handle error
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        speechRecognizer.stopTranscribing()
        isRecording = false
    }
    
    private func completeRecording() {
        onComplete(transcribedText)
        dismiss()
    }
}

// MARK: - Speech Recognizer

class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isTranscribing = false
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    /// Text from previous recording sessions (preserved when "Record More" is used)
    private var baseTranscript = ""
    
    func startTranscribing() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Preserve existing transcript for "Record More"
        baseTranscript = transcript
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio engine not available"])
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure for on-device recognition if available
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Get input node
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let newText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    // Append to base transcript if we have previous text
                    if self.baseTranscript.isEmpty {
                        self.transcript = newText
                    } else {
                        self.transcript = self.baseTranscript + " " + newText
                    }
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine?.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isTranscribing = false
                }
            }
        }
        
        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.isTranscribing = true
        }
    }
    
    func stopTranscribing() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        DispatchQueue.main.async {
            self.isTranscribing = false
        }
    }
    
    func reset() {
        stopTranscribing()
        transcript = ""
        baseTranscript = ""
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

