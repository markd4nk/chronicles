//
//  AuthService.swift
//  Chronicles
//
//  Authentication service for Google and Apple Sign-In with Firebase Auth
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Auth Service

class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?
    
    private var cancellables = Set<AnyCancellable>()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var isConfigured = false
    
    // For Apple Sign-In
    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    private override init() {
        super.init()
        // Don't call Auth.auth() here - Firebase may not be configured yet
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Configuration
    
    /// Must be called after FirebaseApp.configure()
    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        setupAuthStateListener()
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    await self?.loadOrCreateUser(from: firebaseUser)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Load or Create User
    
    @MainActor
    private func loadOrCreateUser(from firebaseUser: FirebaseAuth.User, appleFullName: PersonNameComponents? = nil) async {
        // STEP 1: Load from cache FIRST (instant, no network wait)
        // This ensures the UI is shown immediately
        let cachedUser = loadCachedUser(from: firebaseUser, appleFullName: appleFullName)
        
        self.currentUser = cachedUser
        self.isAuthenticated = true
        self.isLoading = false
        
        print("[AuthService] Loaded cached user immediately")
        
        // STEP 2: Sync from Firestore in the BACKGROUND (non-blocking)
        Task {
            await syncUserFromFirestore(firebaseUser: firebaseUser, cachedUser: cachedUser)
        }
    }
    
    /// Load user from local cache (UserDefaults) - instant, no network
    private func loadCachedUser(from firebaseUser: FirebaseAuth.User, appleFullName: PersonNameComponents? = nil) -> User {
        let userId = firebaseUser.uid
        
        // Load cached data from UserDefaults
        let savedOnboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_\(userId)")
        let savedOnboardingData = loadOnboardingData(for: userId)
        let savedCurrentStreak = UserDefaults.standard.integer(forKey: "currentStreak_\(userId)")
        let savedLongestStreak = UserDefaults.standard.integer(forKey: "longestStreak_\(userId)")
        let savedTotalEntries = UserDefaults.standard.integer(forKey: "totalEntries_\(userId)")
        let savedPreferredName = UserDefaults.standard.string(forKey: "preferredName_\(userId)")
        let savedDisplayName = UserDefaults.standard.string(forKey: "displayName_\(userId)")
        let savedSecurityEnabled = UserDefaults.standard.bool(forKey: "securityEnabled_\(userId)")
        
        // Load dashboard layout from cache
        let savedDashboardLayout = UserDefaults.standard.stringArray(forKey: "dashboardLayout_\(userId)")
            ?? ["morning_reflection", "gratitude", "evening_review", "goals"]
        
        // Extract display name and preferred name
        let displayName: String
        let preferredName: String
        
        if let savedDisplay = savedDisplayName, let savedPreferred = savedPreferredName {
            displayName = savedDisplay
            preferredName = savedPreferred
        } else if let appleName = appleFullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            displayName = formatter.string(from: appleName)
            preferredName = appleName.givenName ?? appleName.familyName ?? "User"
        } else if let firebaseDisplayName = firebaseUser.displayName, !firebaseDisplayName.isEmpty {
            displayName = firebaseDisplayName
            preferredName = firebaseDisplayName.components(separatedBy: " ").first ?? "User"
        } else {
            displayName = "User"
            preferredName = "User"
        }
        
        return User(
            id: userId,
            email: firebaseUser.email ?? "",
            displayName: displayName,
            preferredName: preferredName,
            createdAt: firebaseUser.metadata.creationDate ?? Date(),
            onboardingCompleted: savedOnboardingCompleted,
            onboardingData: savedOnboardingData,
            subscriptionStatus: .trial,
            securityEnabled: savedSecurityEnabled,
            dashboardLayout: savedDashboardLayout,
            currentStreak: savedCurrentStreak,
            longestStreak: savedLongestStreak,
            lastEntryDate: nil,
            totalEntries: savedTotalEntries
        )
    }
    
    /// Sync user data from Firestore in the background (non-blocking)
    private func syncUserFromFirestore(firebaseUser: FirebaseAuth.User, cachedUser: User) async {
        // Check network availability first
        guard await NetworkMonitor.shared.isConnected else {
            print("[AuthService] Offline - skipping Firestore sync")
            return
        }
        
        do {
            // Try to fetch from Firestore
            if let cloudUser = try await FirebaseService.shared.fetchUser(userId: firebaseUser.uid) {
                // Cloud data exists - update local state with cloud data
                await MainActor.run {
                    self.currentUser = cloudUser
                }
                cacheUserLocally(cloudUser)
                print("[AuthService] Synced user from Firestore")
            } else {
                // No cloud data - this is a new user or migration
                // Save cached user to Firestore
                try await FirebaseService.shared.saveUser(cachedUser)
                cacheUserLocally(cachedUser)
                print("[AuthService] Saved new user to Firestore")
            }
        } catch {
            // Firestore sync failed - that's OK, we already have cached data
            print("[AuthService] Firestore sync failed (using cached data): \(error.localizedDescription)")
        }
    }
    
    /// Cache user data locally for offline access
    private func cacheUserLocally(_ user: User) {
        UserDefaults.standard.set(user.displayName, forKey: "displayName_\(user.id)")
        UserDefaults.standard.set(user.preferredName, forKey: "preferredName_\(user.id)")
        UserDefaults.standard.set(user.onboardingCompleted, forKey: "onboarding_\(user.id)")
        UserDefaults.standard.set(user.currentStreak, forKey: "currentStreak_\(user.id)")
        UserDefaults.standard.set(user.longestStreak, forKey: "longestStreak_\(user.id)")
        UserDefaults.standard.set(user.totalEntries, forKey: "totalEntries_\(user.id)")
        UserDefaults.standard.set(user.securityEnabled, forKey: "securityEnabled_\(user.id)")
        UserDefaults.standard.set(user.dashboardLayout, forKey: "dashboardLayout_\(user.id)")
        
        if let onboardingData = user.onboardingData,
           let encoded = try? JSONEncoder().encode(onboardingData) {
            UserDefaults.standard.set(encoded, forKey: "onboardingData_\(user.id)")
        }
    }
    
    private func loadOnboardingData(for userId: String) -> User.OnboardingData? {
        guard let data = UserDefaults.standard.data(forKey: "onboardingData_\(userId)"),
              let onboardingData = try? JSONDecoder().decode(User.OnboardingData.self, from: data) else {
            return nil
        }
        return onboardingData
    }
    
    // MARK: - Google Sign In
    
    @MainActor
    func signInWithGoogle() async throws {
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        // Create Google OAuth provider
        let provider = OAuthProvider(providerID: "google.com")
        provider.customParameters = [
            "prompt": "select_account"
        ]
        provider.scopes = ["email", "profile"]
        
        do {
            // Use completion handler based API wrapped in continuation
            let credential = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthCredential, Error>) in
                provider.getCredentialWith(nil) { credential, error in
                    if let error = error {
                        print("[AuthService] Google OAuth error: \(error.localizedDescription)")
                        print("[AuthService] Google OAuth error details: \(error)")
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let credential = credential else {
                        print("[AuthService] Google OAuth: No credential returned")
                        continuation.resume(throwing: AuthError.signInFailed)
                        return
                    }
                    continuation.resume(returning: credential)
                }
            }
            
            let authResult = try await Auth.auth().signIn(with: credential)
            await loadOrCreateUser(from: authResult.user)
        } catch let authError as AuthError {
            self.error = authError
            throw authError
        } catch {
            print("[AuthService] Google Sign-In failed: \(error.localizedDescription)")
            print("[AuthService] Google Sign-In error details: \(error)")
            self.error = .custom(error.localizedDescription)
            throw AuthError.custom(error.localizedDescription)
        }
    }
    
    // MARK: - Apple Sign In
    
    @MainActor
    func signInWithApple() async throws {
        // Cancel any existing sign-in continuation
        appleSignInContinuation?.resume(throwing: AuthError.signInFailed)
        appleSignInContinuation = nil
        
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
            currentNonce = nil
        }
        
        // Generate nonce for security
        let nonce = randomNonceString()
        currentNonce = nonce
        
        // Create Apple ID request
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        // Perform the request
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        do {
            let credential = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) in
                self.appleSignInContinuation = continuation
                authorizationController.performRequests()
            }
            
            // Clear continuation after use
            appleSignInContinuation = nil
            
            // Get identity token
            guard let appleIDToken = credential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let storedNonce = currentNonce else {
                print("[AuthService] Apple Sign-In: Missing identity token or nonce")
                throw AuthError.signInFailed
            }
            
            // Create Firebase credential
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: storedNonce,
                fullName: credential.fullName
            )
            
            // Sign in to Firebase
            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            
            // Pass Apple's fullName to loadOrCreateUser (only available on first sign-in)
            await loadOrCreateUser(from: authResult.user, appleFullName: credential.fullName)
            
        } catch let authError as AuthError {
            appleSignInContinuation = nil
            self.error = authError
            throw authError
        } catch let asError as ASAuthorizationError {
            appleSignInContinuation = nil
            print("[AuthService] Apple Sign-In ASAuthorizationError: \(asError.localizedDescription)")
            print("[AuthService] Apple Sign-In error code: \(asError.code.rawValue)")
            
            // Handle user cancellation gracefully
            if asError.code == .canceled {
                self.error = .userCancelled
                throw AuthError.userCancelled
            }
            
            self.error = .custom(asError.localizedDescription)
            throw AuthError.custom(asError.localizedDescription)
        } catch {
            appleSignInContinuation = nil
            print("[AuthService] Apple Sign-In failed: \(error.localizedDescription)")
            print("[AuthService] Apple Sign-In error details: \(error)")
            self.error = .custom(error.localizedDescription)
            throw AuthError.custom(error.localizedDescription)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            
            // Clear FirebaseService data
            FirebaseService.shared.clearUserData()
            
            // Reset onboarding flags for testing (allows re-testing onboarding flow)
            #if DEBUG
            UserDefaults.standard.removeObject(forKey: "hasSeenWelcome")
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            #endif
        } catch {
            self.error = .signOutFailed
        }
    }
    
    // MARK: - User Management
    
    func updateUser(_ user: User) async throws {
        await MainActor.run {
            self.currentUser = user
        }
        
        // Save to Firestore (cloud sync)
        try await FirebaseService.shared.saveUser(user)
        
        // Also cache locally for offline access
        cacheUserLocally(user)
    }
    
    func completeOnboarding(data: User.OnboardingData) async throws {
        guard var user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        user.onboardingCompleted = true
        user.onboardingData = data
        
        // Save locally
        UserDefaults.standard.set(true, forKey: "onboarding_\(user.id)")
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "onboardingData_\(user.id)")
        }
        
        await MainActor.run {
            self.currentUser = user
        }
    }
    
    func deleteAccount() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }
        
        let userId = firebaseUser.uid
        
        // Delete Firebase user
        try await firebaseUser.delete()
        
        // Clean up local data
        UserDefaults.standard.removeObject(forKey: "onboarding_\(userId)")
        UserDefaults.standard.removeObject(forKey: "onboardingData_\(userId)")
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            appleSignInContinuation?.resume(returning: appleIDCredential)
            appleSignInContinuation = nil
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case notAuthenticated
    case signInFailed
    case signOutFailed
    case networkError
    case userCancelled
    case custom(String)
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
        case .userCancelled:
            return "Sign in was cancelled."
        case .custom(let message):
            return message
        case .unknown:
            return "An unknown error occurred."
        }
    }
}