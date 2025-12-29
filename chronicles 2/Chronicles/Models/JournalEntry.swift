//
//  JournalEntry.swift
//  Chronicles
//
//  Journal entry model for Firestore
//

import Foundation
import SwiftUI

struct JournalEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let journalId: String
    var templateId: String?
    var promptId: String?
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var inputMethod: InputMethod
    var mood: String?
    var wordCount: Int
    
    // MARK: - Input Method
    
    enum InputMethod: String, Codable, CaseIterable {
        case write = "write"
        case scan = "scan"
        case speak = "speak"
        
        var displayName: String {
            switch self {
            case .write: return "Write"
            case .scan: return "Scan"
            case .speak: return "Speak"
            }
        }
        
        var icon: String {
            switch self {
            case .write: return "pencil"
            case .scan: return "doc.text.viewfinder"
            case .speak: return "mic.fill"
            }
        }
        
        var description: String {
            switch self {
            case .write: return "Type your thoughts"
            case .scan: return "Scan text from a photo"
            case .speak: return "Speak your thoughts"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var preview: String {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanContent.count > 150 {
            return String(cleanContent.prefix(150)) + "..."
        }
        return cleanContent
    }
    
    var shortPreview: String {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanContent.count > 80 {
            return String(cleanContent.prefix(80)) + "..."
        }
        return cleanContent
    }
    
    var readingTime: String {
        let wordsPerMinute = 200
        let minutes = max(1, wordCount / wordsPerMinute)
        return "\(minutes) min read"
    }
    
    // MARK: - Sample Data
    
    static var sample: JournalEntry {
        JournalEntry(
            id: "entry_1",
            userId: "user_sample",
            journalId: "journal_1",
            templateId: nil,
            promptId: nil,
            title: "Morning Thoughts",
            content: "Today I woke up feeling refreshed and motivated. I spent some time meditating and reflecting on my goals for the week. The morning light coming through the window reminded me to be grateful for simple moments.",
            createdAt: Date(),
            updatedAt: Date(),
            inputMethod: .write,
            mood: "peaceful",
            wordCount: 42
        )
    }
    
    static var samples: [JournalEntry] {
        [
            JournalEntry(
                id: "entry_1",
                userId: "user_sample",
                journalId: "journal_1",
                templateId: nil,
                promptId: nil,
                title: "Morning Thoughts",
                content: "Today I woke up feeling refreshed and motivated. I spent some time meditating and reflecting on my goals for the week. The morning light coming through the window reminded me to be grateful for simple moments.",
                createdAt: Date(),
                updatedAt: Date(),
                inputMethod: .write,
                mood: "peaceful",
                wordCount: 42
            ),
            JournalEntry(
                id: "entry_2",
                userId: "user_sample",
                journalId: "journal_2",
                templateId: "template_1",
                promptId: nil,
                title: "Goals for Today",
                content: "1. Complete the project proposal\n2. Exercise for 30 minutes\n3. Read for 20 minutes\n4. Call mom\n5. Practice gratitude",
                createdAt: Date(),
                updatedAt: Date(),
                inputMethod: .write,
                mood: "focused",
                wordCount: 23
            ),
            JournalEntry(
                id: "entry_3",
                userId: "user_sample",
                journalId: "journal_3",
                templateId: nil,
                promptId: nil,
                title: "Grateful for Family",
                content: "Today I'm grateful for my family's support, the warm cup of coffee this morning, and the opportunity to work on meaningful projects.",
                createdAt: Date(),
                updatedAt: Date(),
                inputMethod: .speak,
                mood: "grateful",
                wordCount: 28
            ),
            JournalEntry(
                id: "entry_4",
                userId: "user_sample",
                journalId: "journal_4",
                templateId: nil,
                promptId: nil,
                title: "Meeting Notes",
                content: "Discussed Q1 objectives with the team. Key takeaways: focus on user retention, improve onboarding flow, launch new feature by end of month.",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400),
                inputMethod: .scan,
                mood: nil,
                wordCount: 26
            ),
            JournalEntry(
                id: "entry_5",
                userId: "user_sample",
                journalId: "journal_1",
                templateId: nil,
                promptId: nil,
                title: "Evening Reflection",
                content: "Today was productive. I managed to complete most of my tasks and felt a sense of accomplishment. Tomorrow I want to focus more on self-care.",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400),
                inputMethod: .write,
                mood: "accomplished",
                wordCount: 30
            ),
            JournalEntry(
                id: "entry_6",
                userId: "user_sample",
                journalId: "journal_2",
                templateId: nil,
                promptId: nil,
                title: "Weekly Review",
                content: "This week I achieved 80% of my goals. Areas to improve: time management and reducing distractions. Wins: finished reading one book, exercised 4 times.",
                createdAt: Date().addingTimeInterval(-86400 * 2),
                updatedAt: Date().addingTimeInterval(-86400 * 2),
                inputMethod: .write,
                mood: "reflective",
                wordCount: 32
            )
        ]
    }
}

