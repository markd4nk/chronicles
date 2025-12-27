//
//  JournalTemplate.swift
//  Chronicles
//
//  Journal template model for Firestore
//

import Foundation

struct JournalTemplate: Identifiable, Codable {
    let id: String
    let userId: String
    let journalId: String
    var name: String
    var prompts: [String]
    var structure: String
    var icon: String
    var createdAt: Date
    var updatedAt: Date
    var isBuiltIn: Bool
    
    // MARK: - Computed Properties
    
    var formattedPrompts: String {
        prompts.enumerated().map { index, prompt in
            "\(index + 1). \(prompt)"
        }.joined(separator: "\n")
    }
    
    // MARK: - Built-in Templates
    
    static let builtInTemplates: [JournalTemplate] = [
        JournalTemplate(
            id: "template_morning",
            userId: "",
            journalId: "",
            name: "Morning Reflection",
            prompts: [
                "How am I feeling this morning?",
                "What am I grateful for today?",
                "What is my intention for today?"
            ],
            structure: "Start each morning with reflection and intention setting.",
            icon: "sun.horizon.fill",
            createdAt: Date(),
            updatedAt: Date(),
            isBuiltIn: true
        ),
        JournalTemplate(
            id: "template_gratitude",
            userId: "",
            journalId: "",
            name: "Gratitude",
            prompts: [
                "What are three things I'm grateful for?",
                "Who made a positive impact on my day?",
                "What simple pleasure did I enjoy today?"
            ],
            structure: "Focus on the positive aspects of your day.",
            icon: "heart.fill",
            createdAt: Date(),
            updatedAt: Date(),
            isBuiltIn: true
        ),
        JournalTemplate(
            id: "template_evening",
            userId: "",
            journalId: "",
            name: "Evening Review",
            prompts: [
                "What went well today?",
                "What could I have done better?",
                "What am I looking forward to tomorrow?"
            ],
            structure: "Reflect on your day before rest.",
            icon: "moon.stars.fill",
            createdAt: Date(),
            updatedAt: Date(),
            isBuiltIn: true
        ),
        JournalTemplate(
            id: "template_goals",
            userId: "",
            journalId: "",
            name: "Daily Goals",
            prompts: [
                "What are my top 3 priorities today?",
                "What obstacles might I face?",
                "How will I celebrate today's wins?"
            ],
            structure: "Set clear goals and plan for success.",
            icon: "target",
            createdAt: Date(),
            updatedAt: Date(),
            isBuiltIn: true
        )
    ]
    
    // MARK: - Sample Data
    
    static var sample: JournalTemplate {
        JournalTemplate(
            id: "template_1",
            userId: "user_sample",
            journalId: "journal_1",
            name: "Morning Reflection",
            prompts: [
                "How am I feeling today?",
                "What am I grateful for?",
                "What's my intention for today?"
            ],
            structure: "Start your day with mindful reflection.",
            icon: "sun.horizon.fill",
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-86400 * 5),
            isBuiltIn: false
        )
    }
    
    static var samples: [JournalTemplate] {
        [
            JournalTemplate(
                id: "template_1",
                userId: "user_sample",
                journalId: "journal_1",
                name: "Morning Reflection",
                prompts: [
                    "How am I feeling today?",
                    "What am I grateful for?",
                    "What's my intention for today?"
                ],
                structure: "Start your day with mindful reflection.",
                icon: "sun.horizon.fill",
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400 * 5),
                isBuiltIn: false
            ),
            JournalTemplate(
                id: "template_2",
                userId: "user_sample",
                journalId: "journal_2",
                name: "Daily Goals",
                prompts: [
                    "What are my top 3 priorities?",
                    "What obstacles might I face?",
                    "How will I celebrate today's wins?"
                ],
                structure: "Set clear goals for maximum productivity.",
                icon: "target",
                createdAt: Date().addingTimeInterval(-86400 * 25),
                updatedAt: Date().addingTimeInterval(-86400 * 10),
                isBuiltIn: false
            ),
            JournalTemplate(
                id: "template_3",
                userId: "user_sample",
                journalId: "journal_1",
                name: "Evening Review",
                prompts: [
                    "What went well today?",
                    "What could I improve?",
                    "What am I looking forward to tomorrow?"
                ],
                structure: "End your day with thoughtful reflection.",
                icon: "moon.stars.fill",
                createdAt: Date().addingTimeInterval(-86400 * 20),
                updatedAt: Date().addingTimeInterval(-86400 * 7),
                isBuiltIn: false
            )
        ]
    }
}

