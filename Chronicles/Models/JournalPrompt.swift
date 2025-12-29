//
//  JournalPrompt.swift
//  Chronicles
//
//  Journal prompt model for TikTok-style prompts feed
//

import Foundation

struct JournalPrompt: Identifiable, Codable {
    let id: String
    var question: String
    var hint: String
    var category: PromptCategory
    var createdAt: Date
    var likes: Int
    var shares: Int
    var isLiked: Bool
    
    // MARK: - Prompt Category
    
    enum PromptCategory: String, Codable, CaseIterable {
        case question = "question"
        case reflection = "reflection"
        case quote = "quote"
        case gratitude = "gratitude"
        case creative = "creative"
        case growth = "growth"
        
        var displayName: String {
            switch self {
            case .question: return "Question"
            case .reflection: return "Reflection"
            case .quote: return "Quote"
            case .gratitude: return "Gratitude"
            case .creative: return "Creative"
            case .growth: return "Growth"
            }
        }
        
        var icon: String {
            switch self {
            case .question: return "questionmark.circle.fill"
            case .reflection: return "bubble.left.and.bubble.right.fill"
            case .quote: return "quote.opening"
            case .gratitude: return "heart.fill"
            case .creative: return "paintbrush.fill"
            case .growth: return "leaf.fill"
            }
        }
    }
    
    // MARK: - Sample Data
    
    static var sample: JournalPrompt {
        JournalPrompt(
            id: "prompt_1",
            question: "What would you do if you knew you couldn't fail?",
            hint: "Dream big and explore the possibilities without fear of failure.",
            category: .question,
            createdAt: Date(),
            likes: 234,
            shares: 45,
            isLiked: false
        )
    }
    
    static var samples: [JournalPrompt] {
        [
            JournalPrompt(
                id: "prompt_1",
                question: "What would you do if you knew you couldn't fail?",
                hint: "Dream big and explore the possibilities without fear of failure.",
                category: .question,
                createdAt: Date(),
                likes: 234,
                shares: 45,
                isLiked: false
            ),
            JournalPrompt(
                id: "prompt_2",
                question: "Describe a moment today that made you smile.",
                hint: "Even small moments of joy can illuminate our days.",
                category: .gratitude,
                createdAt: Date(),
                likes: 189,
                shares: 32,
                isLiked: true
            ),
            JournalPrompt(
                id: "prompt_3",
                question: "The only way to do great work is to love what you do.",
                hint: "- Steve Jobs. Reflect on what work brings you joy.",
                category: .quote,
                createdAt: Date(),
                likes: 567,
                shares: 123,
                isLiked: false
            ),
            JournalPrompt(
                id: "prompt_4",
                question: "What lesson did you learn this week that you want to remember?",
                hint: "Growth often comes from reflection on our experiences.",
                category: .growth,
                createdAt: Date(),
                likes: 312,
                shares: 67,
                isLiked: false
            ),
            JournalPrompt(
                id: "prompt_5",
                question: "If your life was a book, what would this chapter be called?",
                hint: "Step back and see the bigger picture of your journey.",
                category: .creative,
                createdAt: Date(),
                likes: 445,
                shares: 89,
                isLiked: true
            ),
            JournalPrompt(
                id: "prompt_6",
                question: "What are you holding onto that no longer serves you?",
                hint: "Sometimes letting go is the first step to moving forward.",
                category: .reflection,
                createdAt: Date(),
                likes: 378,
                shares: 78,
                isLiked: false
            ),
            JournalPrompt(
                id: "prompt_7",
                question: "Write about someone who believed in you when you didn't believe in yourself.",
                hint: "Acknowledge the people who've supported your journey.",
                category: .gratitude,
                createdAt: Date(),
                likes: 521,
                shares: 112,
                isLiked: false
            ),
            JournalPrompt(
                id: "prompt_8",
                question: "What would your younger self think of who you've become?",
                hint: "Reflect on your growth and the person you've evolved into.",
                category: .reflection,
                createdAt: Date(),
                likes: 634,
                shares: 145,
                isLiked: true
            ),
            JournalPrompt(
                id: "prompt_9",
                question: "In the middle of difficulty lies opportunity.",
                hint: "- Albert Einstein. What challenges are presenting hidden opportunities?",
                category: .quote,
                createdAt: Date(),
                likes: 423,
                shares: 91,
                isLiked: false
            ),
            JournalPrompt(
                id: "prompt_10",
                question: "What would you create if you had unlimited resources?",
                hint: "Let your imagination run wild without constraints.",
                category: .creative,
                createdAt: Date(),
                likes: 298,
                shares: 54,
                isLiked: false
            )
        ]
    }
}

