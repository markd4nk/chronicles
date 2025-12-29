//
//  AIService.swift
//  Chronicles
//
//  AI service for journal analysis and conversational interface
//  Placeholder for GPT API integration
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
    
    private init() {}
    
    // MARK: - Journal Analysis
    
    /// Analyze selected journals and generate insights
    /// - Parameters:
    ///   - entries: Journal entries to analyze
    ///   - journals: Journals being analyzed
    /// - Returns: Analysis summary
    func analyzeJournals(entries: [JournalEntry], journals: [Journal]) async throws -> String {
        isAnalyzing = true
        error = nil
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        // Simulate AI processing delay
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // In production, this would call GPT API
        // For now, return a placeholder analysis
        let journalNames = journals.map { $0.name }.joined(separator: ", ")
        let entryCount = entries.count
        
        return """
        Based on analyzing \(entryCount) entries from \(journalNames):
        
        **Key Themes**
        - Personal growth and self-reflection
        - Gratitude and appreciation
        - Goal-oriented mindset
        
        **Patterns Noticed**
        - Most entries are written in the morning
        - Positive sentiment overall
        - Consistent journaling habit forming
        
        **Suggestions**
        - Consider adding more evening reflections
        - Explore deeper emotional processing
        - Your gratitude practice is strong
        
        Would you like to explore any of these themes further?
        """
    }
    
    // MARK: - Chat Response
    
    /// Generate a response to a user message in the AI chat
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
        isGeneratingResponse = true
        error = nil
        
        defer {
            Task { @MainActor in
                isGeneratingResponse = false
            }
        }
        
        // Simulate AI processing delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // In production, this would call GPT API with conversation history
        // For now, return a placeholder response
        let response = generatePlaceholderResponse(to: message, entries: entries)
        
        return AIMessage(
            id: UUID().uuidString,
            conversationId: conversation.id,
            role: .assistant,
            content: response,
            createdAt: Date()
        )
    }
    
    private func generatePlaceholderResponse(to message: String, entries: [JournalEntry]) -> String {
        let lowercaseMessage = message.lowercased()
        
        if lowercaseMessage.contains("pattern") || lowercaseMessage.contains("theme") {
            return """
            Looking at your journal entries, I notice several recurring themes:
            
            1. **Morning Productivity**: You often mention feeling most energized in the mornings.
            
            2. **Gratitude Focus**: There's a strong pattern of appreciation, especially for relationships and simple pleasures.
            
            3. **Goal Orientation**: You consistently track and reflect on your progress.
            
            Would you like me to dive deeper into any of these patterns?
            """
        } else if lowercaseMessage.contains("gratitude") || lowercaseMessage.contains("grateful") {
            return """
            Your gratitude practice is really strong. From your entries, I see you frequently express appreciation for:
            
            - **Family & Relationships**: Support from loved ones
            - **Simple Moments**: Morning coffee, quiet time, nature
            - **Opportunities**: Meaningful work and personal growth
            
            Research shows this kind of gratitude practice can significantly boost wellbeing. Keep it up!
            """
        } else if lowercaseMessage.contains("suggestion") || lowercaseMessage.contains("improve") {
            return """
            Based on your journaling patterns, here are some suggestions:
            
            1. **Add Evening Reflections**: You write mainly in mornings. Evening reviews can help process the day.
            
            2. **Explore Emotions**: Consider going deeper into how events make you feel.
            
            3. **Weekly Reviews**: A dedicated weekly reflection entry could help you see bigger patterns.
            
            Would you like me to help you create a template for any of these?
            """
        } else {
            return """
            That's a thoughtful question. Based on what I've seen in your journals, you have a strong foundation of self-reflection and mindfulness.
            
            Your entries show someone who values growth, appreciates the present moment, and is working toward meaningful goals.
            
            Is there a specific aspect of your journaling you'd like to explore or improve?
            """
        }
    }
    
    // MARK: - Prompt Generation
    
    /// Generate a personalized prompt based on user's journal history
    /// - Parameter entries: Recent journal entries
    /// - Returns: Personalized prompt
    func generatePersonalizedPrompt(basedOn entries: [JournalEntry]) async throws -> JournalPrompt {
        // In production, this would use GPT to generate personalized prompts
        // For now, return a sample prompt
        return JournalPrompt.sample
    }
    
    // MARK: - Insights
    
    /// Generate insights summary for the user's dashboard
    /// - Parameter entries: Recent entries
    /// - Returns: Brief insights summary
    func generateInsightsSummary(from entries: [JournalEntry]) async throws -> String {
        // Simulate processing
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // In production, this would call GPT API
        return "Your journaling streak is strong! This week's themes: growth, gratitude, and productivity."
    }
    
    // MARK: - Title Generation
    
    /// Generate a concise title for a journal entry based on its content
    /// - Parameter content: The journal entry content
    /// - Returns: A generated title (max ~50 characters)
    func generateTitle(for content: String) async throws -> String {
        // Simulate AI processing
        try await Task.sleep(nanoseconds: 800_000_000)
        
        // In production, this would call GPT API with a prompt like:
        // "Generate a concise, meaningful title (max 50 chars) for this journal entry: [content]"
        
        // For now, use smart extraction from content
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanContent.isEmpty else {
            throw AIError.titleGenerationFailed
        }
        
        // Extract key phrases or first meaningful sentence
        let sentences = cleanContent.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let firstSentence = sentences.first {
            // Truncate to 50 chars if needed
            if firstSentence.count <= 50 {
                return firstSentence
            } else {
                // Find a good breaking point
                let truncated = String(firstSentence.prefix(47))
                if let lastSpace = truncated.lastIndex(of: " ") {
                    return String(truncated[..<lastSpace]) + "..."
                }
                return truncated + "..."
            }
        }
        
        // Fallback: use first few words
        let words = cleanContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let titleWords = words.prefix(6).joined(separator: " ")
        
        if titleWords.count > 50 {
            return String(titleWords.prefix(47)) + "..."
        }
        
        return titleWords
    }
    
    // MARK: - OCR (Text Extraction from Image)
    
    /// Extract text from an image using Vision framework
    /// - Parameter image: The UIImage to process
    /// - Returns: Extracted text from the image
    func extractTextFromImage(_ image: UIImage) async throws -> String {
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
                
                // Extract text from observations
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: AIError.ocrNoTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // Configure for best accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIError.ocrFailed)
            }
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
            return "AI service not configured."
        case .titleGenerationFailed:
            return "Failed to generate title. Using fallback."
        case .ocrFailed:
            return "Failed to extract text from image. Please try again."
        case .ocrNoTextFound:
            return "No text found in the image. Please try a different image."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

