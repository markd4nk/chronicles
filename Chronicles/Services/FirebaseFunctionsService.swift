//
//  FirebaseFunctionsService.swift
//  Chronicles
//
//  Service to call Firebase Cloud Functions for OpenAI API operations
//  All AI requests are proxied through Cloud Functions for security
//

import Foundation
import FirebaseFunctions
import FirebaseAuth
import UIKit

// MARK: - Firebase Functions Service

class FirebaseFunctionsService {
    static let shared = FirebaseFunctionsService()
    
    private lazy var functions = Functions.functions()
    
    private init() {
        // Use emulator in debug mode if needed
        #if DEBUG
        // Uncomment to use local emulator:
        // functions.useEmulator(withHost: "localhost", port: 5001)
        #endif
    }
    
    /// Check if user is authenticated before making a request
    private func ensureAuthenticated() throws {
        guard Auth.auth().currentUser != nil else {
            throw FirebaseFunctionsError.unauthenticated
        }
    }
    
    // MARK: - Function Types
    
    enum AIFunctionType: String {
        case extractText = "extractTextFromImage"
        case analyzeJournals = "analyzeJournals"
        case generateChatResponse = "generateChatResponse"
        case generateTitle = "generateTitle"
        case generatePersonalizedPrompt = "generatePersonalizedPrompt"
        case transcribeAudio = "transcribeAudio"
        case deleteConversation = "deleteConversation"
    }
    
    // MARK: - OCR (Text Extraction from Image)
    
    /// Extract text from an image using GPT-4o Vision via Cloud Function
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - useCloudOCR: If true, uses GPT-4o via Cloud Function. If false, returns nil to use local Vision.
    /// - Returns: Extracted text from the image
    func extractTextFromImage(_ image: UIImage) async throws -> String {
        // Compress and convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FirebaseFunctionsError.invalidInput("Failed to convert image to data")
        }
        
        let base64String = imageData.base64EncodedString()
        
        let data: [String: Any] = [
            "imageBase64": base64String,
            "mimeType": "image/jpeg"
        ]
        
        let result = try await callFunction(.extractText, data: data)
        
        guard let text = result["text"] as? String else {
            throw FirebaseFunctionsError.invalidResponse("No text in response")
        }
        
        return text
    }
    
    // MARK: - Journal Analysis
    
    /// Analyze journal entries using GPT-4o via Cloud Function
    /// - Parameters:
    ///   - entries: Journal entries to analyze
    ///   - journals: Journals being analyzed
    /// - Returns: Analysis summary
    func analyzeJournals(entries: [JournalEntry], journals: [Journal]) async throws -> String {
        let entriesData = entries.map { entry -> [String: Any] in
            return [
                "id": entry.id,
                "title": entry.title,
                "content": entry.content,
                "createdAt": ISO8601DateFormatter().string(from: entry.createdAt),
                "journalId": entry.journalId
            ]
        }
        
        let journalsData = journals.map { journal -> [String: Any] in
            return [
                "id": journal.id,
                "name": journal.name
            ]
        }
        
        let data: [String: Any] = [
            "entries": entriesData,
            "journals": journalsData
        ]
        
        let result = try await callFunction(.analyzeJournals, data: data)
        
        guard let analysis = result["analysis"] as? String else {
            throw FirebaseFunctionsError.invalidResponse("No analysis in response")
        }
        
        return analysis
    }
    
    // MARK: - Chat Response
    
    /// Generate AI chat response using GPT-4o via Cloud Function
    /// - Parameters:
    ///   - message: User's message
    ///   - conversationHistory: Previous messages in the conversation
    ///   - entriesContext: Optional context from journal entries
    /// - Returns: AI response text
    func generateChatResponse(
        message: String,
        conversationHistory: [AIMessage],
        entriesContext: String?
    ) async throws -> String {
        let historyData = conversationHistory.map { msg -> [String: Any] in
            return [
                "role": msg.role == .user ? "user" : "assistant",
                "content": msg.content
            ]
        }
        
        var data: [String: Any] = [
            "message": message,
            "conversationHistory": historyData
        ]
        
        if let context = entriesContext {
            data["entriesContext"] = context
        }
        
        let result = try await callFunction(.generateChatResponse, data: data)
        
        guard let response = result["response"] as? String else {
            throw FirebaseFunctionsError.invalidResponse("No response in result")
        }
        
        return response
    }
    
    // MARK: - Title Generation
    
    /// Generate a title for journal entry using GPT-4o-mini via Cloud Function
    /// - Parameter content: The journal entry content
    /// - Returns: Generated title
    func generateTitle(for content: String) async throws -> String {
        let data: [String: Any] = [
            "content": content
        ]
        
        let result = try await callFunction(.generateTitle, data: data)
        
        guard let title = result["title"] as? String else {
            throw FirebaseFunctionsError.invalidResponse("No title in response")
        }
        
        return title
    }
    
    // MARK: - Personalized Prompt Generation
    
    /// Generate personalized journal prompt using GPT-4o via Cloud Function
    /// - Parameter entries: Recent journal entries for context
    /// - Returns: Personalized prompt data
    func generatePersonalizedPrompt(basedOn entries: [JournalEntry]) async throws -> GeneratedPrompt {
        let entriesData = entries.prefix(5).map { entry -> [String: Any] in
            return [
                "content": String(entry.content.prefix(500)),
                "createdAt": ISO8601DateFormatter().string(from: entry.createdAt)
            ]
        }
        
        let data: [String: Any] = [
            "recentEntries": entriesData
        ]
        
        let result = try await callFunction(.generatePersonalizedPrompt, data: data)
        
        guard let prompt = result["prompt"] as? String,
              let category = result["category"] as? String else {
            throw FirebaseFunctionsError.invalidResponse("Invalid prompt data in response")
        }
        
        let followUp = result["followUp"] as? String
        
        return GeneratedPrompt(
            prompt: prompt,
            category: category,
            followUp: followUp
        )
    }
    
    // MARK: - Audio Transcription
    
    /// Transcribe audio using Whisper API via Cloud Function
    /// - Parameters:
    ///   - audioData: Audio file data
    ///   - mimeType: Audio MIME type (default: audio/m4a)
    /// - Returns: Transcribed text
    func transcribeAudio(audioData: Data, mimeType: String = "audio/m4a") async throws -> String {
        let base64String = audioData.base64EncodedString()
        
        let data: [String: Any] = [
            "audioBase64": base64String,
            "mimeType": mimeType
        ]
        
        let result = try await callFunction(.transcribeAudio, data: data)
        
        guard let transcription = result["transcription"] as? String else {
            throw FirebaseFunctionsError.invalidResponse("No transcription in response")
        }
        
        return transcription
    }
    
    // MARK: - Conversation Management
    
    /// Delete a conversation and all its messages via Cloud Function
    /// Uses Cloud Function for safe subcollection deletion
    /// - Parameter conversationId: The ID of the conversation to delete
    func deleteConversation(conversationId: String) async throws {
        let data: [String: Any] = [
            "conversationId": conversationId
        ]
        
        let result = try await callFunction(.deleteConversation, data: data)
        
        // Verify success
        guard let success = result["success"] as? Bool, success else {
            throw FirebaseFunctionsError.invalidResponse("Delete conversation failed")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Call a Firebase Cloud Function
    /// - Parameters:
    ///   - functionType: The function to call
    ///   - data: Data to send to the function
    /// - Returns: Response dictionary
    private func callFunction(_ functionType: AIFunctionType, data: [String: Any]) async throws -> [String: Any] {
        // Verify user is authenticated before making the call
        try ensureAuthenticated()
        
        do {
            let result = try await functions.httpsCallable(functionType.rawValue).call(data)
            
            guard let responseData = result.data as? [String: Any] else {
                throw FirebaseFunctionsError.invalidResponse("Invalid response format")
            }
            
            return responseData
        } catch let error as NSError {
            // Handle Firebase Functions errors
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code) ?? .unknown
                let message = error.localizedDescription
                
                switch code {
                case .unauthenticated:
                    throw FirebaseFunctionsError.unauthenticated
                case .invalidArgument:
                    throw FirebaseFunctionsError.invalidInput(message)
                case .notFound:
                    throw FirebaseFunctionsError.notFound(message)
                case .resourceExhausted:
                    throw FirebaseFunctionsError.rateLimited
                case .internal:
                    throw FirebaseFunctionsError.serverError(message)
                case .unavailable:
                    throw FirebaseFunctionsError.networkError
                default:
                    throw FirebaseFunctionsError.unknown(message)
                }
            }
            
            throw FirebaseFunctionsError.unknown(error.localizedDescription)
        }
    }
}

// MARK: - Generated Prompt Model

struct GeneratedPrompt {
    let prompt: String
    let category: String
    let followUp: String?
}

// MARK: - Firebase Functions Error

enum FirebaseFunctionsError: LocalizedError {
    case unauthenticated
    case invalidInput(String)
    case invalidResponse(String)
    case notFound(String)
    case rateLimited
    case networkError
    case serverError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Please sign in to use AI features."
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .notFound(let message):
            return message
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown(let message):
            return "Error: \(message)"
        }
    }
}

