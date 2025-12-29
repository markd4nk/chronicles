//
//  AuthView.swift
//  Chronicles
//
//  Sign in screen with Google and Apple authentication
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Title
                VStack(spacing: Papper.spacing.lg) {
                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(PapperColors.surfaceBackgroundPlain)
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 44))
                            .foregroundColor(PapperColors.neutral700)
                    }
                    
                    VStack(spacing: Papper.spacing.xs) {
                        Text("Chronicles")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundColor(PapperColors.neutral800)
                        
                        Text("Your personal journaling companion")
                            .font(Papper.typography.body)
                            .foregroundColor(PapperColors.neutral600)
                    }
                }
                
                Spacer()
                
                // Sign In Buttons
                VStack(spacing: Papper.spacing.md) {
                    // Apple Sign In
                    Button(action: {
                        viewModel.signInWithApple()
                    }) {
                        HStack(spacing: Papper.spacing.sm) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    
                    // Google Sign In
                    Button(action: {
                        viewModel.signInWithGoogle()
                    }) {
                        HStack(spacing: Papper.spacing.sm) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(PapperColors.neutral800)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(PapperColors.surfaceBackgroundPlain)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(PapperColors.neutral300, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, Papper.spacing.xl)
                
                // Terms
                VStack(spacing: Papper.spacing.xs) {
                    Text("By continuing, you agree to our")
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(PapperColors.neutral500)
                    
                    HStack(spacing: Papper.spacing.xxs) {
                        Button("Terms of Service") {}
                            .font(Papper.typography.bodySmall)
                            .foregroundColor(PapperColors.neutral700)
                        
                        Text("and")
                            .font(Papper.typography.bodySmall)
                            .foregroundColor(PapperColors.neutral500)
                        
                        Button("Privacy Policy") {}
                            .font(Papper.typography.bodySmall)
                            .foregroundColor(PapperColors.neutral700)
                    }
                }
                .padding(.top, Papper.spacing.xl)
                .padding(.bottom, Papper.spacing.xxxl)
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Check if onboarding needed
                if viewModel.currentUser?.onboardingCompleted == false {
                    showOnboarding = true
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#faf8f3"),
                Color(hex: "#f5f3ee")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#if DEBUG
struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
#endif

