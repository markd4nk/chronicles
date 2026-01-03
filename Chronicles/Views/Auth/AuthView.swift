//
//  AuthView.swift
//  Chronicles
//
//  Sign in screen with Google and Apple authentication
//  Shown after onboarding, right before paywall
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isAnimated = false
    
    var body: some View {
        ZStack {
            // Background
            OnboardingGradientBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Title
                VStack(spacing: Papper.spacing.lg) {
                    // App Icon
                    OnboardingIconCircle(
                        icon: "person.crop.circle.badge.checkmark",
                        size: 120,
                        iconSize: 50,
                        backgroundColor: PapperColors.grayblue200,
                        iconColor: PapperColors.neutral700
                    )
                    
                    VStack(spacing: Papper.spacing.sm) {
                        Text("Create Your Account")
                            .font(PapperTypography.listTitle())
                            .foregroundColor(PapperColors.neutral800)
                        
                        Text("Sign in to save your journal and\naccess it across all your devices")
                            .font(PapperTypography.cardBody())
                            .foregroundColor(PapperColors.neutral600)
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 20)
                
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
                        .frame(height: 56)
                        .background(PapperColors.neutral800)
                        .cornerRadius(14)
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
                        .frame(height: 56)
                        .background(PapperColors.surfaceBackgroundPlain)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(PapperColors.neutral300, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, Papper.spacing.xl)
                .opacity(isAnimated ? 1 : 0)
                .offset(y: isAnimated ? 0 : 30)
                
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
                .opacity(isAnimated ? 1 : 0)
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
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                isAnimated = true
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Sync onboarding data after authentication
                syncOnboardingData()
            }
        }
    }
    
    /// Sync locally stored onboarding data to the authenticated user
    private func syncOnboardingData() {
        Task {
            guard let onboardingData = OnboardingViewModel.getLocalOnboardingData() else {
                return
            }
            
            do {
                // Complete onboarding with the stored data
                try await AuthService.shared.completeOnboarding(data: onboardingData)
                
                // Clear local data after successful sync
                OnboardingViewModel.clearLocalOnboardingData()
            } catch {
                print("Failed to sync onboarding data: \(error)")
            }
        }
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
