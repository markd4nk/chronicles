//
//  ChroniclesApp.swift
//  Chronicles
//
//  Main app entry point with routing logic
//

import SwiftUI

@main
struct ChroniclesApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var securityService = SecurityService.shared
    
    @State private var isLocked = false
    @State private var showPaywall = false
    
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
        if authService.isAuthenticated {
            if let user = authService.currentUser {
                if !user.onboardingCompleted {
                    OnboardingView()
                } else if !subscriptionService.isSubscribed {
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
        } else {
            // Auth screen
            AuthView()
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
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

// MARK: - Lock Screen View

struct LockScreenView: View {
    @StateObject private var securityService = SecurityService.shared
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            VStack(spacing: Papper.spacing.xxl) {
                Spacer()
                
                // App Icon
                VStack(spacing: Papper.spacing.lg) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(PapperColors.neutral700)
                    
                    Text("Chronicles is Locked")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(PapperColors.neutral800)
                    
                    Text("Use \(securityService.biometryName) to unlock")
                        .font(Papper.typography.body)
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
