//
//  AuthService.swift
//  Chronicles
//
//  Authentication service for Google and Apple Sign-In
//

import Foundation
import Combine

// MARK: - Auth Service

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Check for existing session
        checkAuthStatus()
    }
    
    // MARK: - Auth Status
    
    func checkAuthStatus() {
        // In production, this would check Firebase Auth state
        // For now, we'll use UserDefaults to persist demo state
        if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
            // Load user from cache or Firestore
            loadUser(userId: userId)
        }
    }
    
    private func loadUser(userId: String) {
        // In production, fetch from Firestore
        // For demo, use sample user
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.currentUser = User.sample
            self?.isAuthenticated = true
            self?.isLoading = false
        }
    }
    
    // MARK: - Sign In Methods
    
    func signInWithGoogle() async throws {
        isLoading = true
        error = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // In production, this would use GoogleSignIn SDK
            // For demo, create a sample user
            let user = User.sample
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            
            // Persist session
            UserDefaults.standard.set(user.id, forKey: "currentUserId")
        }
    }
    
    func signInWithApple() async throws {
        isLoading = true
        error = nil
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            // In production, this would use AuthenticationServices
            // For demo, create a sample user
            let user = User.sample
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            
            // Persist session
            UserDefaults.standard.set(user.id, forKey: "currentUserId")
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }
    
    // MARK: - User Management
    
    func updateUser(_ user: User) async throws {
        // In production, update Firestore document
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    func completeOnboarding(data: User.OnboardingData) async throws {
        guard var user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        user.onboardingCompleted = true
        user.onboardingData = data
        
        // In production, save to Firestore
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    func deleteAccount() async throws {
        // In production, delete from Firebase Auth and Firestore
        signOut()
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case notAuthenticated
    case signInFailed
    case signOutFailed
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .signInFailed:
            return "Sign in failed. Please try again."
        case .signOutFailed:
            return "Sign out failed. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

