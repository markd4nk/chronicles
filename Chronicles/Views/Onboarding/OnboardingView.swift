//
//  OnboardingView.swift
//  Chronicles
//
//  14-step onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                progressBar
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    WelcomeStep(viewModel: viewModel).tag(0)
                    NameStep(viewModel: viewModel).tag(1)
                    ExperienceStep(viewModel: viewModel).tag(2)
                    GoalsStep(viewModel: viewModel).tag(3)
                    InterestsStep(viewModel: viewModel).tag(4)
                    TimeStep(viewModel: viewModel).tag(5)
                    ReminderIntroStep(viewModel: viewModel).tag(6)
                    MorningReminderStep(viewModel: viewModel).tag(7)
                    EveningReminderStep(viewModel: viewModel).tag(8)
                    NotificationStep(viewModel: viewModel).tag(9)
                    FeatureSlide1(viewModel: viewModel).tag(10)
                    FeatureSlide2(viewModel: viewModel).tag(11)
                    FeatureSlide3(viewModel: viewModel).tag(12)
                    CompletionStep(viewModel: viewModel).tag(13)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
                
                // Navigation Buttons
                navigationButtons
            }
        }
        .onChange(of: viewModel.isComplete) { isComplete in
            if isComplete {
                dismiss()
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(PapperColors.neutral200b)
                    .frame(height: 4)
                
                Rectangle()
                    .fill(PapperColors.neutral700)
                    .frame(width: geometry.size.width * viewModel.progress, height: 4)
                    .animation(.easeInOut, value: viewModel.progress)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Navigation Buttons
    
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
            
            // Skip Button (only on certain steps)
            if viewModel.currentStep > 0 && viewModel.currentStep < 13 {
                Button("Skip") {
                    viewModel.skipToEnd()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(PapperColors.neutral500)
            }
            
            // Next/Continue Button
            Button(action: viewModel.nextStep) {
                HStack(spacing: Papper.spacing.xs) {
                    Text(viewModel.currentStep == 13 ? "Get Started" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                    
                    if viewModel.currentStep < 13 {
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
        .background(Color(hex: "#faf8f3"))
    }
}

// MARK: - Onboarding Steps

struct WelcomeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(PapperColors.neutral700)
            
            VStack(spacing: Papper.spacing.md) {
                Text("Welcome to Chronicles")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Your personal space for reflection,\ngrowth, and self-discovery")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct NameStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            VStack(spacing: Papper.spacing.md) {
                Text("What should we call you?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("We'll use this to personalize your experience")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
            }
            
            TextField("Your name", text: $viewModel.preferredName)
                .font(.system(size: 18))
                .padding()
                .background(PapperColors.surfaceBackgroundPlain)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PapperColors.neutral300, lineWidth: 1)
                )
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct ExperienceStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                Text("How experienced are you\nwith journaling?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Papper.spacing.xxl)
            
            VStack(spacing: Papper.spacing.sm) {
                ForEach(viewModel.experienceLevels, id: \.0) { level in
                    SelectionButton(
                        title: level.1,
                        isSelected: viewModel.journalingExperience == level.0,
                        action: { viewModel.journalingExperience = level.0 }
                    )
                }
            }
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct GoalsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                Text("What do you want to achieve?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Select up to 3 goals")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
            }
            .padding(.top, Papper.spacing.lg)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Papper.spacing.sm) {
                ForEach(viewModel.goalOptions, id: \.0) { goal in
                    MultiSelectButton(
                        title: goal.1,
                        isSelected: viewModel.primaryGoals.contains(goal.0),
                        action: { viewModel.toggleGoal(goal.0) }
                    )
                }
            }
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct InterestsStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                Text("What interests you?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("We'll personalize prompts for you")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
            }
            .padding(.top, Papper.spacing.lg)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Papper.spacing.sm) {
                ForEach(viewModel.interestOptions, id: \.0) { interest in
                    MultiSelectButton(
                        title: interest.1,
                        isSelected: viewModel.interests.contains(interest.0),
                        action: { viewModel.toggleInterest(interest.0) }
                    )
                }
            }
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct TimeStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                Text("When do you prefer to journal?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
            }
            .padding(.top, Papper.spacing.xxl)
            
            VStack(spacing: Papper.spacing.sm) {
                ForEach(viewModel.timeOptions, id: \.0) { time in
                    SelectionButton(
                        title: time.1,
                        isSelected: viewModel.preferredTime == time.0,
                        action: { viewModel.preferredTime = time.0 }
                    )
                }
            }
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct ReminderIntroStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral700)
            
            VStack(spacing: Papper.spacing.md) {
                Text("Stay on Track")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Set up gentle reminders to help\nbuild your journaling habit")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct MorningReminderStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 40))
                    .foregroundColor(PapperColors.neutral700)
                
                Text("Morning Reminder")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
            }
            .padding(.top, Papper.spacing.xxl)
            
            Toggle(isOn: $viewModel.morningReminderEnabled) {
                Text("Enable morning reminder")
                    .font(Papper.typography.bodyTitle)
            }
            .tint(PapperColors.neutral700)
            .padding()
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(12)
            
            if viewModel.morningReminderEnabled {
                DatePicker("Time", selection: $viewModel.morningReminderTime, displayedComponents: .hourAndMinute)
                    .padding()
                    .background(PapperColors.surfaceBackgroundPlain)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct EveningReminderStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xl) {
            VStack(spacing: Papper.spacing.md) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 40))
                    .foregroundColor(PapperColors.neutral700)
                
                Text("Evening Reminder")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
            }
            .padding(.top, Papper.spacing.xxl)
            
            Toggle(isOn: $viewModel.eveningReminderEnabled) {
                Text("Enable evening reminder")
                    .font(Papper.typography.bodyTitle)
            }
            .tint(PapperColors.neutral700)
            .padding()
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(12)
            
            if viewModel.eveningReminderEnabled {
                DatePicker("Time", selection: $viewModel.eveningReminderTime, displayedComponents: .hourAndMinute)
                    .padding()
                    .background(PapperColors.surfaceBackgroundPlain)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct NotificationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            Image(systemName: "app.badge.fill")
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral700)
            
            VStack(spacing: Papper.spacing.md) {
                Text("Enable Notifications")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Allow notifications to receive your\njournaling reminders")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await viewModel.requestNotificationPermission()
                }
            }) {
                Text(viewModel.notificationsEnabled ? "Notifications Enabled" : "Allow Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.notificationsEnabled ? PapperColors.green400 : PapperColors.neutral700)
                    .cornerRadius(12)
            }
            .padding(.horizontal, Papper.spacing.xl)
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct FeatureSlide1: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        FeatureSlideView(
            icon: "square.and.pencil",
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
            title: "Daily Inspiration",
            description: "Discover prompts and quotes to spark your creativity"
        )
    }
}

struct CompletionStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(PapperColors.green400)
            
            VStack(spacing: Papper.spacing.md) {
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text("Your journaling journey begins now.\nLet's create your first entry!")
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

// MARK: - Supporting Views

struct FeatureSlideView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: Papper.spacing.xxl) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(PapperColors.neutral700)
            
            VStack(spacing: Papper.spacing.md) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(PapperColors.neutral800)
                
                Text(description)
                    .font(Papper.typography.body)
                    .foregroundColor(PapperColors.neutral600)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(Papper.spacing.xl)
    }
}

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : PapperColors.neutral700)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? PapperColors.neutral700 : PapperColors.surfaceBackgroundPlain)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? PapperColors.neutral700 : PapperColors.neutral300, lineWidth: 1)
            )
        }
    }
}

struct MultiSelectButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : PapperColors.neutral700)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Papper.spacing.sm)
                .background(isSelected ? PapperColors.neutral700 : PapperColors.surfaceBackgroundPlain)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? PapperColors.neutral700 : PapperColors.neutral300, lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
#endif

