//
//  SubscriptionService.swift
//  Chronicles
//
//  StoreKit 2 subscription management service
//

import Foundation
import Combine

// MARK: - Subscription Service

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var currentSubscription: Subscription?
    @Published var isSubscribed = false
    @Published var isInTrial = false
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    
    private init() {
        // Check subscription status on init
        checkSubscriptionStatus()
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() {
        // In production, this would use StoreKit 2 to check entitlements
        // For demo, we'll use UserDefaults to simulate
        
        if UserDefaults.standard.bool(forKey: "hasActiveSubscription") {
            currentSubscription = Subscription.sample
            isSubscribed = true
            isInTrial = false
        } else if UserDefaults.standard.bool(forKey: "hasActiveTrial") {
            currentSubscription = Subscription.trialSample
            isSubscribed = true
            isInTrial = true
        }
    }
    
    // MARK: - Purchase
    
    func purchase(plan: Subscription.PlanType) async throws {
        isLoading = true
        error = nil
        
        // Simulate purchase process
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            // Create subscription
            let subscription = Subscription(
                id: UUID().uuidString,
                userId: AuthService.shared.currentUser?.id ?? "",
                productId: plan.productIdentifier,
                planType: plan,
                status: .active,
                purchaseDate: Date(),
                expirationDate: plan == .yearly 
                    ? Date().addingTimeInterval(86400 * 365)
                    : Date().addingTimeInterval(86400 * 30),
                isTrialPeriod: false,
                trialExpirationDate: nil,
                autoRenewing: true,
                originalTransactionId: UUID().uuidString
            )
            
            self.currentSubscription = subscription
            self.isSubscribed = true
            self.isInTrial = false
            self.isLoading = false
            
            // Persist state
            UserDefaults.standard.set(true, forKey: "hasActiveSubscription")
            UserDefaults.standard.set(false, forKey: "hasActiveTrial")
        }
    }
    
    func startFreeTrial() async throws {
        isLoading = true
        error = nil
        
        // Simulate trial activation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            let subscription = Subscription.trialSample
            
            self.currentSubscription = subscription
            self.isSubscribed = true
            self.isInTrial = true
            self.isLoading = false
            
            // Persist state
            UserDefaults.standard.set(false, forKey: "hasActiveSubscription")
            UserDefaults.standard.set(true, forKey: "hasActiveTrial")
        }
    }
    
    // MARK: - Restore
    
    func restorePurchases() async throws {
        isLoading = true
        error = nil
        
        // Simulate restore process
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            // In production, this would verify with StoreKit 2
            // For demo, check if there's a stored subscription
            if UserDefaults.standard.bool(forKey: "hasActiveSubscription") {
                self.currentSubscription = Subscription.sample
                self.isSubscribed = true
            }
            
            self.isLoading = false
        }
    }
    
    // MARK: - Cancel
    
    func cancelSubscription() async throws {
        // In production, this would redirect to iOS subscription management
        // Subscriptions are managed through the App Store
        await MainActor.run {
            if var subscription = currentSubscription {
                subscription.autoRenewing = false
                self.currentSubscription = subscription
            }
        }
    }
    
    // MARK: - Feature Access
    
    func canAccessFeature(_ feature: SubscriptionFeature) -> Bool {
        return isSubscribed
    }
    
    func shouldShowPaywall() -> Bool {
        return !isSubscribed
    }
    
    // MARK: - Reset (for testing)
    
    func reset() {
        currentSubscription = nil
        isSubscribed = false
        isInTrial = false
        UserDefaults.standard.removeObject(forKey: "hasActiveSubscription")
        UserDefaults.standard.removeObject(forKey: "hasActiveTrial")
    }
}

// MARK: - Subscription Error

enum SubscriptionError: LocalizedError {
    case purchaseFailed
    case purchaseCancelled
    case productNotFound
    case networkError
    case verificationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .purchaseCancelled:
            return "Purchase was cancelled."
        case .productNotFound:
            return "Product not found."
        case .networkError:
            return "Network error. Please check your connection."
        case .verificationFailed:
            return "Could not verify purchase."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

