//
//  User.swift
//  Chronicles
//
//  User data model for Firestore
//

import Foundation
import SwiftUI

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String?
    var preferredName: String?
    var createdAt: Date
    var onboardingCompleted: Bool
    var onboardingData: OnboardingData?
    var subscriptionStatus: SubscriptionStatus
    var securityEnabled: Bool
    var dashboardLayout: [String]
    var currentStreak: Int
    var longestStreak: Int
    var lastEntryDate: Date?
    var totalEntries: Int
    
    // MARK: - Subscription Status
    
    enum SubscriptionStatus: String, Codable {
        case none = "none"
        case trial = "trial"
        case active = "active"
        case expired = "expired"
        case cancelled = "cancelled"
        
        var isActive: Bool {
            switch self {
            case .active, .trial:
                return true
            default:
                return false
            }
        }
        
        var displayText: String {
            switch self {
            case .none: return "No Subscription"
            case .trial: return "Free Trial"
            case .active: return "Premium Member"
            case .expired: return "Subscription Expired"
            case .cancelled: return "Cancelled"
            }
        }
        
        var color: Color {
            switch self {
            case .active: return PapperColors.green400
            case .trial: return PapperColors.purple400
            case .expired, .cancelled: return PapperColors.pink400
            case .none: return PapperColors.neutral500
            }
        }
    }
    
    // MARK: - Onboarding Data
    
    struct OnboardingData: Codable {
        var journalingExperience: String?
        var primaryGoals: [String]
        var preferredTime: String?
        var morningReminderTime: Date?
        var eveningReminderTime: Date?
        var notificationsEnabled: Bool
        var interests: [String]
        var completedAt: Date?
    }
    
    // MARK: - Computed Properties
    
    var firstName: String {
        preferredName ?? displayName?.components(separatedBy: " ").first ?? "User"
    }
    
    // MARK: - Default User
    
    static var empty: User {
        User(
            id: "",
            email: "",
            displayName: nil,
            preferredName: nil,
            createdAt: Date(),
            onboardingCompleted: false,
            onboardingData: nil,
            subscriptionStatus: .none,
            securityEnabled: false,
            dashboardLayout: ["morning_reflection", "gratitude", "evening_review", "goals"],
            currentStreak: 0,
            longestStreak: 0,
            lastEntryDate: nil,
            totalEntries: 0
        )
    }
    
    // MARK: - Sample User
    
    static var sample: User {
        User(
            id: "user_sample",
            email: "mark@example.com",
            displayName: "Mark Johnson",
            preferredName: "Mark",
            createdAt: Date().addingTimeInterval(-86400 * 90),
            onboardingCompleted: true,
            onboardingData: OnboardingData(
                journalingExperience: "beginner",
                primaryGoals: ["mindfulness", "productivity", "gratitude"],
                preferredTime: "morning",
                morningReminderTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                eveningReminderTime: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()),
                notificationsEnabled: true,
                interests: ["personal_growth", "health", "creativity"],
                completedAt: Date().addingTimeInterval(-86400 * 89)
            ),
            subscriptionStatus: .active,
            securityEnabled: false,
            dashboardLayout: ["morning_reflection", "gratitude", "evening_review", "goals"],
            currentStreak: 7,
            longestStreak: 14,
            lastEntryDate: Date(),
            totalEntries: 238
        )
    }
}

