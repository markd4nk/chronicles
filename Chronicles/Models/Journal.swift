//
//  Journal.swift
//  Chronicles
//
//  Custom journal model for Firestore
//

import Foundation
import SwiftUI

struct Journal: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    var name: String
    var color: String
    var order: Int
    var createdAt: Date
    var updatedAt: Date
    var entryCount: Int
    var lastEntryDate: Date?
    
    // MARK: - Computed Properties
    
    var displayColor: Color {
        Color(hex: color)
    }
    
    // MARK: - Predefined Colors
    
    static let availableColors: [String] = [
        "#8b7355", // Brown
        "#7a8b73", // Sage Green
        "#8b7373", // Dusty Rose
        "#73738b", // Slate Blue
        "#8b8573", // Khaki
        "#738b8b", // Teal
        "#7a7a7a", // Gray
        "#414141"  // Dark Gray
    ]
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Journal, rhs: Journal) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Sample Data
    
    static var sample: Journal {
        Journal(
            id: "journal_1",
            userId: "user_sample",
            name: "Daily Reflections",
            color: "#8b7355",
            order: 0,
            createdAt: Date().addingTimeInterval(-86400 * 90),
            updatedAt: Date(),
            entryCount: 47,
            lastEntryDate: Date()
        )
    }
    
    static var samples: [Journal] {
        [
            Journal(
                id: "journal_1",
                userId: "user_sample",
                name: "Daily Reflections",
                color: "#414141",
                order: 0,
                createdAt: Date().addingTimeInterval(-86400 * 90),
                updatedAt: Date(),
                entryCount: 47,
                lastEntryDate: Date()
            ),
            Journal(
                id: "journal_2",
                userId: "user_sample",
                name: "Goals & Dreams",
                color: "#7a8b73",
                order: 1,
                createdAt: Date().addingTimeInterval(-86400 * 60),
                updatedAt: Date().addingTimeInterval(-86400),
                entryCount: 23,
                lastEntryDate: Date().addingTimeInterval(-86400)
            ),
            Journal(
                id: "journal_3",
                userId: "user_sample",
                name: "Gratitude",
                color: "#8b7373",
                order: 2,
                createdAt: Date().addingTimeInterval(-86400 * 180),
                updatedAt: Date(),
                entryCount: 156,
                lastEntryDate: Date()
            ),
            Journal(
                id: "journal_4",
                userId: "user_sample",
                name: "Work Notes",
                color: "#73738b",
                order: 3,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-86400 * 3),
                entryCount: 12,
                lastEntryDate: Date().addingTimeInterval(-86400 * 3)
            )
        ]
    }
}

