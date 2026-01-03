//
//  OnboardingView.swift
//  Chronicles
//
//  10-step onboarding flow with Papper design system
//  Steps: Welcome, Goals, Reminder Intro, Morning, Evening, Notifications, Feature 1-3, Completion
//  Name is collected from Google/Apple sign-in after onboarding
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            OnboardingGradientBackground()
            
            VStack(spacing: 0) {
                // Progress Bar
                OnboardingProgressBar(progress: viewModel.progress)
                    .padding(.horizontal, Papper.spacing.lg)
                    .padding(.top, Papper.spacing.sm)
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStep(viewModel: viewModel).tag(0)
                    GoalsStep(viewModel: viewModel).tag(1)
                    ReminderIntroStep(viewModel: viewModel).tag(2)
                    MorningReminderStep(viewModel: viewModel).tag(3)
                    EveningReminderStep(viewModel: viewModel).tag(4)
                    NotificationStep(viewModel: viewModel).tag(5)
                    FeatureSlide1(viewModel: viewModel).tag(6)
                    FeatureSlide2(viewModel: viewModel).tag(7)
                    FeatureSlide3(viewModel: viewModel).tag(8)
                    CompletionStep(viewModel: viewModel).tag(9)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentStep)
                
                // Navigation Buttons
                navigationButtons
            }
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                dismiss()
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    /// The last step index (Completion step)
    private var lastStepIndex: Int {
        viewModel.totalSteps - 1
    }
    
    private var navigationButtons: some View {
        HStack(spacing: Papper.spacing.md) {
            // Back Button
            if viewModel.currentStep > 0 {
                Button(action: viewModel.previousStep) {
                    HStack(spacing: Papper.spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(PapperColors.neutral600)
                }
            } else {
                Spacer()
            }
            
            Spacer()
            
            // Skip Button (only on certain steps, not on completion)
            if viewModel.currentStep > 0 && viewModel.currentStep < lastStepIndex {
                OnboardingSecondaryButton(title: "Skip") {
                    viewModel.skipToEnd()
                }
            }
            
            // Next/Continue Button
            Button(action: viewModel.nextStep) {
                HStack(spacing: Papper.spacing.xs) {
                    Text(viewModel.currentStep == lastStepIndex ? "Get Started" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if viewModel.currentStep < lastStepIndex {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, Papper.spacing.xl)
                .padding(.vertical, Papper.spacing.sm)
                .background(viewModel.canProceed ? PapperColors.neutral700 : PapperColors.neutral400)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canProceed)
        }
        .padding(.horizontal, Papper.spacing.lg)
        .padding(.vertical, Papper.spacing.lg)
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            // Large circular icon
            OnboardingIconCircle(
                icon: "book.closed.fill",
                size: 140,
                iconSize: 60,
                backgroundColor: PapperColors.grayblue200,
                iconColor: PapperColors.neutral700
            )
            
            VStack(spacing: Papper.spacing.md) {
                Text("Welcome to Chronicles")
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
                    .multilineTextAlignment(.center)
                
                Text("Your personal space for reflection,\ngrowth, and self-discovery")
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Goals Step

struct GoalsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                Text("What are your goals?")
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Select up to 3 goals that matter most to you")
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral600)
            }
            .padding(.top, Papper.spacing.lg)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Papper.spacing.sm) {
                ForEach(viewModel.goalOptions, id: \.0) { goal in
                    OnboardingMultiSelectCard(
                        title: goal.1,
                        isSelected: viewModel.primaryGoals.contains(goal.0),
                        backgroundColor: PapperColors.grayblue200,
                        action: { viewModel.toggleGoal(goal.0) }
                    )
                }
            }
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Reminder Intro Step

struct ReminderIntroStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            OnboardingIconCircle(
                icon: "bell.fill",
                size: 120,
                iconSize: 50,
                backgroundColor: PapperColors.grayblue200,
                iconColor: PapperColors.neutral700
            )
            
            VStack(spacing: Papper.spacing.md) {
                Text("Stay on Track")
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Set up gentle reminders to help\nbuild your journaling habit")
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            // Info card
            HStack(spacing: Papper.spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(PapperColors.neutral600)
                
                Text("A few quiet minutes can change your whole day")
                    .font(PapperTypography.bodyText())
                    .foregroundColor(PapperColors.neutral600)
            }
            .padding(Papper.spacing.md)
            .background(PapperColors.surfaceBackgroundPlain.opacity(0.8))
            .cornerRadius(12)
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Morning Reminder Step

struct MorningReminderStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                OnboardingIconCircle(
                    icon: "sun.horizon.fill",
                    size: 80,
                    iconSize: 36,
                    backgroundColor: PapperColors.grayblue200,
                    iconColor: PapperColors.neutral700
                )
                
                Text("Morning Reminder")
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
            }
            .padding(.top, Papper.spacing.xl)
            
            // Toggle Card
            VStack(spacing: Papper.spacing.md) {
                Toggle(isOn: $viewModel.morningReminderEnabled) {
                    Text("Enable morning reminder")
                        .font(PapperTypography.cardTitle())
                        .foregroundColor(PapperColors.neutral800)
                }
                .tint(PapperColors.neutral700)
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PapperColors.neutral300, lineWidth: 1)
                )
                
                if viewModel.morningReminderEnabled {
                    VStack(spacing: Papper.spacing.sm) {
                        OnboardingTimeDisplay(time: viewModel.morningReminderTime)
                        
                        Text("Reminder Time")
                            .font(PapperTypography.bodyText())
                            .foregroundColor(PapperColors.neutral500)
                        
                        DatePicker("", selection: $viewModel.morningReminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 150)
                    }
                    .padding()
                    .background(PapperColors.grayblue200.opacity(0.3))
                    .cornerRadius(16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.morningReminderEnabled)
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Evening Reminder Step

struct EveningReminderStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                OnboardingIconCircle(
                    icon: "moon.stars.fill",
                    size: 80,
                    iconSize: 36,
                    backgroundColor: PapperColors.grayblue200,
                    iconColor: PapperColors.neutral700
                )
                
                Text("Evening Reminder")
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
            }
            .padding(.top, Papper.spacing.xl)
            
            // Toggle Card
            VStack(spacing: Papper.spacing.md) {
                Toggle(isOn: $viewModel.eveningReminderEnabled) {
                    Text("Enable evening reminder")
                        .font(PapperTypography.cardTitle())
                        .foregroundColor(PapperColors.neutral800)
                }
                .tint(PapperColors.neutral700)
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PapperColors.neutral300, lineWidth: 1)
                )
                
                if viewModel.eveningReminderEnabled {
                    VStack(spacing: Papper.spacing.sm) {
                        OnboardingTimeDisplay(time: viewModel.eveningReminderTime)
                        
                        Text("Reminder Time")
                            .font(PapperTypography.bodyText())
                            .foregroundColor(PapperColors.neutral500)
                        
                        DatePicker("", selection: $viewModel.eveningReminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 150)
                    }
                    .padding()
                    .background(PapperColors.grayblue200.opacity(0.3))
                    .cornerRadius(16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.eveningReminderEnabled)
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Notification Step

struct NotificationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            OnboardingIconCircle(
                icon: viewModel.notificationsEnabled ? "bell.badge.fill" : "bell.fill",
                size: 120,
                iconSize: 50,
                backgroundColor: PapperColors.grayblue200,
                iconColor: PapperColors.neutral700
            )
            
            VStack(spacing: Papper.spacing.md) {
                Text("Enable Notifications")
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Allow notifications to receive your\njournaling reminders")
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await viewModel.requestNotificationPermission()
                }
            }) {
                HStack(spacing: Papper.spacing.sm) {
                    if viewModel.notificationsEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }
                    
                    Text(viewModel.notificationsEnabled ? "Notifications Enabled" : "Allow Notifications")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(PapperColors.neutral700)
                .cornerRadius(14)
            }
            .padding(.horizontal, Papper.spacing.xl)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.notificationsEnabled)
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Feature Slides

struct FeatureSlide1: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        FeatureSlideView(
            icon: "square.and.pencil",
            iconBackground: PapperColors.grayblue200,
            title: "Write Your Story",
            description: "Capture your thoughts with text, voice, or by scanning handwritten notes"
        )
    }
}

struct FeatureSlide2: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        FeatureSlideView(
            icon: "brain.head.profile",
            iconBackground: PapperColors.grayblue200,
            title: "AI-Powered Insights",
            description: "Get personalized reflections and discover patterns in your journey"
        )
    }
}

struct FeatureSlide3: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        FeatureSlideView(
            icon: "lightbulb.fill",
            iconBackground: PapperColors.grayblue200,
            title: "Daily Inspiration",
            description: "Discover prompts and quotes to spark your creativity"
        )
    }
}

// MARK: - Completion Step

struct CompletionStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showFeatures = false
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            Spacer()
            
            // Success icon
            OnboardingIconCircle(
                icon: "checkmark",
                size: 100,
                iconSize: 44,
                backgroundColor: PapperColors.grayblue200,
                iconColor: PapperColors.neutral700
            )
            
            VStack(spacing: Papper.spacing.sm) {
                Text("Your space is ready!")
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Your journal has been set up and personalized.")
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            // Feature list
            VStack(alignment: .leading, spacing: Papper.spacing.md) {
                OnboardingFeatureListItem(
                    number: 1,
                    title: "Start Journaling",
                    description: "Record your first voice entry to begin",
                    accentColor: PapperColors.grayblue200
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
                
                OnboardingFeatureListItem(
                    number: 2,
                    title: "Get Insights",
                    description: "Receive custom analysis of your entries, powered by AI",
                    accentColor: PapperColors.grayblue200
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
                
                OnboardingFeatureListItem(
                    number: 3,
                    title: "Track Progress",
                    description: "See your self-reflection journey unfold",
                    accentColor: PapperColors.grayblue200
                )
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 20)
            }
            .padding()
            .background(PapperColors.surfaceBackgroundPlain.opacity(0.8))
            .cornerRadius(20)
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                showFeatures = true
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureSlideView: View {
    let icon: String
    var iconBackground: Color = PapperColors.grayblue200
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            OnboardingIconCircle(
                icon: icon,
                size: 120,
                iconSize: 50,
                backgroundColor: iconBackground,
                iconColor: PapperColors.neutral700
            )
            
            VStack(spacing: Papper.spacing.md) {
                Text(title)
                    .font(PapperTypography.listTitle())
                    .foregroundColor(PapperColors.neutral800)
                
                Text(description)
                    .font(PapperTypography.cardBody())
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Preview

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(OnboardingViewModel())
    }
}
#endif
