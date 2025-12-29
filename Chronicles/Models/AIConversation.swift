//
//  AIConversation.swift
//  Chronicles
//
//  AI conversation model for the Reflect/Analyze feature
//

import Foundation

struct AIConversation: Identifiable, Codable {
    let id: String
    let userId: String
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var messages: [AIMessage]
    var analyzedJournalIds: [String]
    var insightsSummary: String?
    
    // MARK: - Computed Properties
    
    var lastMessage: AIMessage? {
        messages.last
    }
    
    var messageCount: Int {
        messages.count
    }
    
    var preview: String {
        if let lastMsg = lastMessage {
            return String(lastMsg.content.prefix(100)) + (lastMsg.content.count > 100 ? "..." : "")
        }
        return "No messages yet"
    }
    
    // MARK: - Sample Data
    
    static var sample: AIConversation {
        AIConversation(
            id: "conv_1",
            userId: "user_sample",
            title: "Weekly Reflection",
            createdAt: Date().addingTimeInterval(-86400 * 2),
            updatedAt: Date(),
            messages: AIMessage.samples,
            analyzedJournalIds: ["journal_1", "journal_3"],
            insightsSummary: "Your entries show a positive trend in mindfulness and gratitude practices."
        )
    }
    
    static var samples: [AIConversation] {
        [
            AIConversation(
                id: "conv_1",
                userId: "user_sample",
                title: "Weekly Reflection",
                createdAt: Date().addingTimeInterval(-86400 * 2),
                updatedAt: Date(),
                messages: AIMessage.samples,
                analyzedJournalIds: ["journal_1", "journal_3"],
                insightsSummary: "Your entries show a positive trend in mindfulness and gratitude practices."
            ),
            AIConversation(
                id: "conv_2",
                userId: "user_sample",
                title: "Goal Progress Analysis",
                createdAt: Date().addingTimeInterval(-86400 * 7),
                updatedAt: Date().addingTimeInterval(-86400 * 5),
                messages: [],
                analyzedJournalIds: ["journal_2"],
                insightsSummary: "Strong progress on productivity goals. Consider adding more rest-related entries."
            ),
            AIConversation(
                id: "conv_3",
                userId: "user_sample",
                title: "Monthly Review",
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400 * 28),
                messages: [],
                analyzedJournalIds: ["journal_1", "journal_2", "journal_3"],
                insightsSummary: "Great consistency this month. Themes: growth, gratitude, and professional development."
            )
        ]
    }
}

// MARK: - AI Message

struct AIMessage: Identifiable, Codable {
    let id: String
    let conversationId: String
    let role: MessageRole
    var content: String
    var createdAt: Date
    
    // MARK: - Message Role
    
    enum MessageRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
    
    // MARK: - Sample Data
    
    static var sample: AIMessage {
        AIMessage(
            id: "msg_1",
            conversationId: "conv_1",
            role: .user,
            content: "What patterns do you see in my journal entries from this week?",
            createdAt: Date().addingTimeInterval(-3600)
        )
    }
    
    static var samples: [AIMessage] {
        [
            AIMessage(
                id: "msg_1",
                conversationId: "conv_1",
                role: .user,
                content: "What patterns do you see in my journal entries from this week?",
                createdAt: Date().addingTimeInterval(-3600)
            ),
            AIMessage(
                id: "msg_2",
                conversationId: "conv_1",
                role: .assistant,
                content: "Based on your entries from this week, I noticed several patterns:\n\n1. **Morning productivity**: You consistently mention feeling most energized in the mornings.\n\n2. **Gratitude focus**: There's a strong theme of appreciation for family and simple pleasures.\n\n3. **Goal orientation**: You've been tracking progress on your reading and exercise goals effectively.\n\nWould you like to explore any of these patterns more deeply?",
                createdAt: Date().addingTimeInterval(-3500)
            ),
            AIMessage(
                id: "msg_3",
                conversationId: "conv_1",
                role: .user,
                content: "Tell me more about the gratitude patterns.",
                createdAt: Date().addingTimeInterval(-3000)
            ),
            AIMessage(
                id: "msg_4",
                conversationId: "conv_1",
                role: .assistant,
                content: "Your gratitude entries reveal a beautiful appreciation for:\n\n- **Relationships**: You frequently mention family support and meaningful connections\n- **Simple moments**: Coffee, morning light, quiet time for reflection\n- **Opportunities**: Work projects that feel meaningful\n\nThis focus on gratitude is linked to higher wellbeing. You might consider a dedicated gratitude practice - even just 3 things each morning can compound positive effects.",
                createdAt: Date().addingTimeInterval(-2900)
            )
        ]
    }
}

