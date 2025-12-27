//
//  Subscription.swift
//  Chronicles
//
//  Subscription model for StoreKit 2 integration
//

import Foundation

struct Subscription: Identifiable, Codable {
    let id: String
    let userId: String
    var productId: String
    var planType: PlanType
    var status: Status
    var purchaseDate: Date
    var expirationDate: Date
    var isTrialPeriod: Bool
    var trialExpirationDate: Date?
    var autoRenewing: Bool
    var originalTransactionId: String?
    
    // MARK: - Plan Type
    
    enum PlanType: String, Codable, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
        
        var displayName: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "$9.99"
            case .yearly: return "$79.99"
            }
        }
        
        var pricePerMonth: String {
            switch self {
            case .monthly: return "$9.99/month"
            case .yearly: return "$6.67/month"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly: return nil
            case .yearly: return "Save 33%"
            }
        }
        
        var productIdentifier: String {
            switch self {
            case .monthly: return "com.chronicles.subscription.monthly"
            case .yearly: return "com.chronicles.subscription.yearly"
            }
        }
    }
    
    // MARK: - Status
    
    enum Status: String, Codable {
        case active = "active"
        case expired = "expired"
        case cancelled = "cancelled"
        case pending = "pending"
        case inGracePeriod = "grace_period"
        case inBillingRetry = "billing_retry"
        
        var isActive: Bool {
            switch self {
            case .active, .inGracePeriod, .inBillingRetry:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var daysRemaining: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
        return max(0, days)
    }
    
    var isExpired: Bool {
        expirationDate < Date()
    }
    
    var trialDaysRemaining: Int? {
        guard isTrialPeriod, let trialEnd = trialExpirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
        return max(0, days)
    }
    
    // MARK: - Sample Data
    
    static var sample: Subscription {
        Subscription(
            id: "sub_1",
            userId: "user_sample",
            productId: "com.chronicles.subscription.yearly",
            planType: .yearly,
            status: .active,
            purchaseDate: Date().addingTimeInterval(-86400 * 30),
            expirationDate: Date().addingTimeInterval(86400 * 335),
            isTrialPeriod: false,
            trialExpirationDate: nil,
            autoRenewing: true,
            originalTransactionId: "txn_123456"
        )
    }
    
    static var trialSample: Subscription {
        Subscription(
            id: "sub_trial",
            userId: "user_sample",
            productId: "com.chronicles.subscription.monthly",
            planType: .monthly,
            status: .active,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(86400 * 3),
            isTrialPeriod: true,
            trialExpirationDate: Date().addingTimeInterval(86400 * 3),
            autoRenewing: true,
            originalTransactionId: "txn_trial_123"
        )
    }
}

// MARK: - Subscription Features

struct SubscriptionFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    
    static let features: [SubscriptionFeature] = [
        SubscriptionFeature(
            icon: "book.fill",
            title: "Unlimited Journals",
            description: "Create as many journals as you need"
        ),
        SubscriptionFeature(
            icon: "doc.text.fill",
            title: "Unlimited Entries",
            description: "Write without limits"
        ),
        SubscriptionFeature(
            icon: "brain.head.profile",
            title: "AI Reflect & Analyze",
            description: "Get insights from your journals"
        ),
        SubscriptionFeature(
            icon: "doc.text.viewfinder",
            title: "Scan & Speak",
            description: "Multiple input methods"
        ),
        SubscriptionFeature(
            icon: "rectangle.3.group.fill",
            title: "Custom Templates",
            description: "Create your own templates"
        ),
        SubscriptionFeature(
            icon: "icloud.fill",
            title: "Cloud Sync",
            description: "Access anywhere, anytime"
        )
    ]
}

