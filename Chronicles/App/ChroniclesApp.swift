//
//  ChroniclesApp.swift
//  Chronicles
//
//  Main app entry point with routing logic
//  Flow: Welcome → Onboarding → Auth → Paywall → Main App
//

import SwiftUI
import Firebase

// App delegate to configure Firebase before anything else
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // Now that Firebase is configured, set up auth listener
        AuthService.shared.configure()
        return true
    }
}

@main
struct ChroniclesApp: App {
    // Configure Firebase first via AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var securityService = SecurityService.shared
    
    // Local app state (persisted in UserDefaults)
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Navigation state
    @State private var showOnboarding = false
    @State private var showAuth = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main Content
                rootView
                
                // Lock Screen Overlay
                if securityService.isSecurityEnabled && securityService.isLocked {
                    LockScreenView()
                        .transition(.opacity)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                securityService.handleAppDidBecomeActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                securityService.handleAppWillResignActive()
            }
        }
    }
    
    @ViewBuilder
    private var rootView: some View {
        // Flow: Welcome → Onboarding → Auth → Paywall → Main App
        
        if authService.isAuthenticated {
            // User is authenticated
            if let user = authService.currentUser {
                if !subscriptionService.isSubscribed {
                    // Show paywall (user must subscribe)
                    PaywallView()
                } else {
                    // Main app
                    MainTabView()
                }
            } else {
                // Loading state
                loadingView
            }
        } else if hasCompletedOnboarding || showAuth {
            // Onboarding done, show auth screen
            AuthView()
                .transition(.opacity)
        } else if hasSeenWelcome || showOnboarding {
            // Show onboarding
            OnboardingContainerView(
                hasCompletedOnboarding: $hasCompletedOnboarding
            )
            .transition(.opacity)
        } else {
            // First time user - show welcome screen
            WelcomeView(
                showOnboarding: $showOnboarding,
                showAuth: $showAuth
            )
            .transition(.opacity)
            .onDisappear {
                hasSeenWelcome = true
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            OnboardingGradientBackground()
            
            VStack(spacing: Papper.spacing.lg) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 60))
                    .foregroundColor(PapperColors.neutral700)
                
                ProgressView()
                    .tint(PapperColors.neutral700)
            }
        }
    }
}

// MARK: - Onboarding Container View

/// Container for onboarding that doesn't require authentication
struct OnboardingContainerView: View {
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        OnboardingView()
            .environmentObject(viewModel)
            .onChange(of: viewModel.isComplete) { _, isComplete in
                if isComplete {
                    // Mark onboarding as complete (local state)
                    hasCompletedOnboarding = true
                }
            }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    @ObservedObject private var securityService = SecurityService.shared
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            // Background
            OnboardingGradientBackground()
            
            VStack(spacing: Papper.spacing.xxl) {
                Spacer()
                
                // App Icon
                VStack(spacing: Papper.spacing.lg) {
                    OnboardingIconCircle(
                        icon: "lock.fill",
                        size: 100,
                        iconSize: 44,
                        backgroundColor: PapperColors.grayblue200,
                        iconColor: PapperColors.neutral700
                    )
                    
                    Text("Chronicles is Locked")
                        .font(PapperTypography.listTitle())
                        .foregroundColor(PapperColors.neutral800)
                    
                    Text("Use \(securityService.biometryName) to unlock")
                        .font(PapperTypography.cardBody())
                        .foregroundColor(PapperColors.neutral600)
                }
                
                Spacer()
                
                // Unlock Button
                Button(action: unlock) {
                    HStack(spacing: Papper.spacing.sm) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: securityService.biometryIcon)
                                .font(.system(size: 20))
                            Text("Unlock")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(PapperColors.neutral700)
                    .cornerRadius(14)
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, Papper.spacing.xl)
                .padding(.bottom, Papper.spacing.xxxl)
            }
        }
        .onAppear {
            // Auto-prompt on appear
            unlock()
        }
    }
    
    private func unlock() {
        isAuthenticating = true
        
        Task {
            _ = await securityService.unlockApp()
            isAuthenticating = false
        }
    }
}
