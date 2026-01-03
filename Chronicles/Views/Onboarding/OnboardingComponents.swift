//
//  OnboardingComponents.swift
//  Chronicles
//
//  Reusable components for onboarding screens using Papper design system
//

import SwiftUI

// MARK: - Onboarding Icon Circle

/// Large circular icon container with soft shadow
struct OnboardingIconCircle: View {
    let icon: String
    var size: CGFloat = 140
    var iconSize: CGFloat = 60
    var backgroundColor: Color = PapperColors.grayblue200
    var iconColor: Color = PapperColors.neutral700
    @State private var isAnimated = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.85))
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(iconColor)
        }
        .scaleEffect(isAnimated ? 1 : 0.8)
        .opacity(isAnimated ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
    }
}

// MARK: - Onboarding Selection Card

/// Single-select card with checkmark indicator
struct OnboardingSelectionCard: View {
    let title: String
    let isSelected: Bool
    var selectedColor: Color = PapperColors.grayblue200
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral800)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(PapperColors.neutral700)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Papper.spacing.lg)
            .padding(.vertical, Papper.spacing.md)
            .background(isSelected ? selectedColor : PapperColors.surfaceBackgroundPlain)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? PapperColors.borderActive : PapperColors.neutral300, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Onboarding Multi-Select Card

/// Multi-select card for grid layouts
struct OnboardingMultiSelectCard: View {
    let title: String
    let isSelected: Bool
    var backgroundColor: Color = PapperColors.grayblue200
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral800)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(PapperColors.neutral700)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Papper.spacing.md)
            .padding(.vertical, Papper.spacing.md)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(isSelected ? backgroundColor : PapperColors.surfaceBackgroundPlain)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? PapperColors.borderActive : PapperColors.neutral300, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Onboarding Feature List Item

/// Numbered feature list item for completion screen
struct OnboardingFeatureListItem: View {
    let number: Int
    let title: String
    let description: String
    var accentColor: Color = PapperColors.grayblue200
    
    var body: some View {
        HStack(alignment: .top, spacing: Papper.spacing.md) {
            // Number indicator
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(PapperTypography.cardTitle())
                    .foregroundColor(PapperColors.neutral800)
                
                Text(description)
                    .font(PapperTypography.bodyText())
                    .foregroundColor(PapperColors.neutral600)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Onboarding Background

/// Full-screen solid background matching main app
struct OnboardingGradientBackground: View {
    var body: some View {
        Color(hex: "#faf8f3")
            .ignoresSafeArea()
    }
}

// MARK: - Onboarding Primary Button

/// Primary action button for onboarding
struct OnboardingPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Papper.spacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isEnabled ? PapperColors.neutral700 : PapperColors.neutral400)
            .cornerRadius(14)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding Secondary Button

/// Secondary action button for onboarding
struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(PapperColors.neutral600)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding Progress Bar

/// Custom progress bar with Papper styling
struct OnboardingProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(PapperColors.neutral200b)
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(PapperColors.neutral700)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Onboarding Card Container

/// Card container with soft shadow
struct OnboardingCardContainer<Content: View>: View {
    let content: Content
    var backgroundColor: Color = PapperColors.surfaceBackgroundPlain
    
    init(backgroundColor: Color = PapperColors.surfaceBackgroundPlain, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Papper.spacing.lg)
            .background(backgroundColor)
            .cornerRadius(20)
            .shadow(color: PapperColors.shadowColor, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Time Display View

/// Large time display for time picker step
struct OnboardingTimeDisplay: View {
    let time: Date
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    var body: some View {
        Text(timeString)
            .font(PapperTypography.listTitle())
            .foregroundColor(PapperColors.neutral800)
            .monospacedDigit()
    }
}

// MARK: - Preview

#if DEBUG
struct OnboardingComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                OnboardingIconCircle(icon: "book.closed.fill")
                
                OnboardingSelectionCard(
                    title: "I'm new to journaling",
                    isSelected: true,
                    action: {}
                )
                
                OnboardingMultiSelectCard(
                    title: "Practice mindfulness",
                    isSelected: true,
                    backgroundColor: PapperColors.grayblue200,
                    action: {}
                )
                
                OnboardingFeatureListItem(
                    number: 1,
                    title: "Start Journaling",
                    description: "Record your first voice entry to begin"
                )
                
                OnboardingPrimaryButton(
                    title: "Continue",
                    isEnabled: true,
                    icon: "chevron.right",
                    action: {}
                )
            }
            .padding()
        }
        .background(OnboardingGradientBackground())
    }
}
#endif

