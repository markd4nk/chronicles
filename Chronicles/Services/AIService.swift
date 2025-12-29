//
//  AIService.swift
//  Chronicles
//
//  AI service for journal analysis and conversational interface
//  Uses Firebase Cloud Functions to proxy OpenAI API calls securely
//

import Foundation
import Combine
import Vision
import UIKit

// MARK: - AI Service

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isAnalyzing = false
    @Published var isGeneratingResponse = false
    @Published var error: AIError?
    
    private let functionsService = FirebaseFunctionsService.shared
    
    /// Whether to use Cloud Functions for OCR (GPT-4o) or local Vision framework
    /// Set to true for better handwriting recognition, false for free on-device OCR
    var useCloudOCR = true
    
    private init() {}
    
    // MARK: - Journal Analysis
    
    /// Analyze selected journals and generate insights using GPT-4o
    /// - Parameters:
    ///   - entries: Journal entries to analyze
    ///   - journals: Journals being analyzed
    /// - Returns: Analysis summary
    func analyzeJournals(entries: [JournalEntry], journals: [Journal]) async throws -> String {
        await MainActor.run {
            isAnalyzing = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        do {
            let analysis = try await functionsService.analyzeJournals(entries: entries, journals: journals)
            return analysis
        } catch let functionsError as FirebaseFunctionsError {
            throw mapFunctionsError(functionsError)
        } catch {
            throw AIError.analysisFailed
        }
    }
    
    // MARK: - Chat Response
    
    /// Generate a response to a user message in the AI chat using GPT-4o
    /// - Parameters:
    ///   - message: User's message
    ///   - conversation: Current conversation context
    ///   - entries: Relevant journal entries for context
    /// - Returns: AI response message
    func generateResponse(
        to message: String,
        in conversation: AIConversation,
        withContext entries: [JournalEntry]
    ) async throws -> AIMessage {
        await MainActor.run {
            isGeneratingResponse = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isGeneratingResponse = false
            }
        }
        
        do {
            // Build entries context for the AI
            let entriesContext = buildEntriesContext(from: entries)
            
            // Get conversation history (excluding system messages)
            let conversationHistory = conversation.messages.filter { $0.role != .system }
            
            let responseText = try await functionsService.generateChatResponse(
                message: message,
                conversationHistory: conversationHistory,
                entriesContext: entriesContext
            )
            
            return AIMessage(
                id: UUID().uuidString,
                conversationId: conversation.id,
                role: .assistant,
                content: responseText,
                createdAt: Date()
            )
        } catch let functionsError as FirebaseFunctionsError {
            throw mapFunctionsError(functionsError)
        } catch {
            throw AIError.responseGenerationFailed
        }
    }
    
    /// Build a context string from journal entries for the AI
    private func buildEntriesContext(from entries: [JournalEntry]) -> String? {
        guard !entries.isEmpty else { return nil }
        
        let entriesSummary = entries.prefix(10).map { entry in
            let dateStr = entry.createdAt.formatted(date: .abbreviated, time: .omitted)
            return "[\(dateStr)] \(entry.title): \(entry.content.prefix(300))..."
        }.joined(separator: "\n\n")
        
        return "User's recent journal entries:\n\n\(entriesSummary)"
    }
    
    // MARK: - Prompt Generation
    
    /// Generate a personalized prompt based on user's journal history using GPT-4o
    /// - Parameter entries: Recent journal entries
    /// - Returns: Personalized prompt
    func generatePersonalizedPrompt(basedOn entries: [JournalEntry]) async throws -> JournalPrompt {
        do {
            let generatedPrompt = try await functionsService.generatePersonalizedPrompt(basedOn: entries)
            
            // Convert to JournalPrompt model
            let category = mapPromptCategory(generatedPrompt.category)
            
            return JournalPrompt(
                id: UUID().uuidString,
                question: generatedPrompt.prompt,
                hint: generatedPrompt.followUp ?? "Reflect on this prompt and write freely.",
                category: category,
                createdAt: Date(),
                likes: 0,
                shares: 0,
                isLiked: false
            )
        } catch let functionsError as FirebaseFunctionsError {
            throw mapFunctionsError(functionsError)
        } catch {
            // Fallback to sample prompt if generation fails
            return JournalPrompt.sample
        }
    }
    
    /// Map string category to JournalPrompt.PromptCategory
    private func mapPromptCategory(_ category: String) -> JournalPrompt.PromptCategory {
        switch category.lowercased() {
        case "gratitude":
            return .gratitude
        case "reflection":
            return .reflection
        case "growth":
            return .growth
        case "creative", "creativity":
            return .creative
        case "question":
            return .question
        case "quote":
            return .quote
        default:
            return .reflection
        }
    }
    
    // MARK: - Title Generation
    
    /// Generate a concise title for a journal entry using GPT-4o-mini
    /// - Parameter content: The journal entry content
    /// - Returns: A generated title (max ~50 characters)
    func generateTitle(for content: String) async throws -> String {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanContent.isEmpty else {
            throw AIError.titleGenerationFailed
        }
        
        do {
            let title = try await functionsService.generateTitle(for: cleanContent)
            return title
        } catch _ as FirebaseFunctionsError {
            // Fallback to local title generation if Cloud Function fails
            return try generateLocalTitle(for: cleanContent)
        } catch {
            return try generateLocalTitle(for: cleanContent)
        }
    }
    
    /// Local fallback for title generation
    private func generateLocalTitle(for content: String) throws -> String {
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let firstSentence = sentences.first {
            if firstSentence.count <= 50 {
                return firstSentence
            } else {
                let truncated = String(firstSentence.prefix(47))
                if let lastSpace = truncated.lastIndex(of: " ") {
                    return String(truncated[..<lastSpace]) + "..."
                }
                return truncated + "..."
            }
        }
        
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let titleWords = words.prefix(6).joined(separator: " ")
        
        if titleWords.count > 50 {
            return String(titleWords.prefix(47)) + "..."
        }
        
        return titleWords.isEmpty ? "Untitled Entry" : titleWords
    }
    
    // MARK: - OCR (Text Extraction from Image)
    
    /// Extract text from an image
    /// Uses GPT-4o via Cloud Function if useCloudOCR is true, otherwise uses local Vision framework
    /// - Parameter image: The UIImage to process
    /// - Returns: Extracted text from the image
    func extractTextFromImage(_ image: UIImage) async throws -> String {
        if useCloudOCR {
            do {
                return try await functionsService.extractTextFromImage(image)
            } catch {
                // Fallback to local OCR if Cloud Function fails
                return try await extractTextLocalVision(image)
            }
        } else {
            return try await extractTextLocalVision(image)
        }
    }
    
    /// Extract text using local iOS Vision framework (free, on-device)
    /// - Parameter image: The UIImage to process
    /// - Returns: Extracted text from the image
    func extractTextLocalVision(_ image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw AIError.ocrFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: AIError.ocrFailed)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: AIError.ocrFailed)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: AIError.ocrNoTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIError.ocrFailed)
            }
        }
    }
    
    // MARK: - Audio Transcription
    
    /// Transcribe audio using Whisper API via Cloud Function
    /// - Parameters:
    ///   - audioData: Audio file data
    ///   - mimeType: Audio MIME type (default: audio/m4a)
    /// - Returns: Transcribed text
    func transcribeAudio(audioData: Data, mimeType: String = "audio/m4a") async throws -> String {
        do {
            return try await functionsService.transcribeAudio(audioData: audioData, mimeType: mimeType)
        } catch let functionsError as FirebaseFunctionsError {
            throw mapFunctionsError(functionsError)
        } catch {
            throw AIError.transcriptionFailed
        }
    }
    
    // MARK: - Error Mapping
    
    /// Map FirebaseFunctionsError to AIError
    private func mapFunctionsError(_ error: FirebaseFunctionsError) -> AIError {
        switch error {
        case .unauthenticated:
            return .apiKeyMissing
        case .rateLimited:
            return .rateLimited
        case .networkError:
            return .networkError
        case .notFound:
            return .ocrNoTextFound
        case .invalidInput, .invalidResponse, .serverError, .unknown:
            return .unknown
        }
    }
}

// MARK: - AI Error

enum AIError: LocalizedError {
    case analysisFailed
    case responseGenerationFailed
    case contextTooLarge
    case rateLimited
    case networkError
    case apiKeyMissing
    case titleGenerationFailed
    case ocrFailed
    case ocrNoTextFound
    case transcriptionFailed
    case promptGenerationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .analysisFailed:
            return "Failed to analyze journals. Please try again."
        case .responseGenerationFailed:
            return "Failed to generate response. Please try again."
        case .contextTooLarge:
            return "Too many entries selected. Please select fewer journals."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .networkError:
            return "Network error. Please check your connection."
        case .apiKeyMissing:
            return "AI service not configured. Please sign in."
        case .titleGenerationFailed:
            return "Failed to generate title. Using fallback."
        case .ocrFailed:
            return "Failed to extract text from image. Please try again."
        case .ocrNoTextFound:
            return "No text found in the image. Please try a different image."
        case .transcriptionFailed:
            return "Failed to transcribe audio. Please try again."
        case .promptGenerationFailed:
            return "Failed to generate prompt. Please try again."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
