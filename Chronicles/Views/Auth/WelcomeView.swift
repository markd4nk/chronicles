//
//  WelcomeView.swift
//  Chronicles
//
//  Landing screen with Get Started button and Log in option
//  First screen users see - no authentication required
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showOnboarding: Bool
    @Binding var showAuth: Bool
    
    @State private var isAnimated = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            OnboardingGradientBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Central Graphic
                centralGraphic
                
                Spacer()
                
                // App Info
                appInfo
                
                Spacer()
                
                // Call to Action
                callToAction
            }
            .padding(.horizontal, Papper.spacing.xl)
            .padding(.bottom, Papper.spacing.xxxl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
    }
    
    // MARK: - Central Graphic
    
    private var centralGraphic: some View {
        ZStack {
            // Large circular icon with brain/thought emerging
            OnboardingIconCircle(
                icon: "brain.head.profile",
                size: 160,
                iconSize: 70,
                backgroundColor: PapperColors.grayblue200,
                iconColor: PapperColors.neutral700
            )
        }
        .scaleEffect(isAnimated ? 1 : 0.8)
        .opacity(isAnimated ? 1 : 0)
    }
    
    // MARK: - App Info
    
    private var appInfo: some View {
        VStack(spacing: Papper.spacing.md) {
            Text("AI-POWERED JOURNAL")
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundColor(PapperColors.neutral600)
            
            Text("Chronicles")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .foregroundColor(PapperColors.neutral800)
            
            Text("Improve your mental health,\nmindset, and cognitive skills.")
                .font(PapperTypography.cardBody())
                .foregroundColor(PapperColors.neutral600)
                .multilineTextAlignment(.center)
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 20)
    }
    
    // MARK: - Call to Action
    
    private var callToAction: some View {
        VStack(spacing: Papper.spacing.lg) {
            // Get Started Button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showOnboarding = true
                }
            }) {
                Text("Get Started")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(PapperColors.surfaceBackgroundPlain)
                    .cornerRadius(28)
            }
            .buttonStyle(.plain)
            
            // Already have an account? Log in
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showAuth = true
                }
            }) {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundColor(PapperColors.neutral600)
                    
                    Text("Log in")
                        .foregroundColor(PapperColors.neutral800)
                        .underline()
                }
                .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.plain)
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(y: isAnimated ? 0 : 30)
    }
}

// MARK: - Preview

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(showOnboarding: .constant(false), showAuth: .constant(false))
    }
}
#endif

