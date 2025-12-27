//
//  OnboardingViewModel.swift
//  Chronicles
//
//  Onboarding flow view model
//

import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentStep = 0
    @Published var isComplete = false
    @Published var isLoading = false
    
    // Onboarding Data
    @Published var preferredName = ""
    @Published var journalingExperience = ""
    @Published var primaryGoals: Set<String> = []
    @Published var interests: Set<String> = []
    @Published var preferredTime = ""
    @Published var morningReminderEnabled = false
    @Published var eveningReminderEnabled = false
    @Published var morningReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var eveningReminderTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var notificationsEnabled = false
    
    // MARK: - Constants
    
    let totalSteps = 14
    
    let experienceLevels = [
        ("beginner", "I'm new to journaling"),
        ("occasional", "I journal occasionally"),
        ("regular", "I journal regularly"),
        ("expert", "I'm an experienced journaler")
    ]
    
    let goalOptions = [
        ("mindfulness", "Practice mindfulness"),
        ("gratitude", "Cultivate gratitude"),
        ("productivity", "Boost productivity"),
        ("self_reflection", "Self-reflection"),
        ("stress_relief", "Reduce stress"),
        ("creativity", "Spark creativity"),
        ("memory", "Capture memories"),
        ("growth", "Personal growth")
    ]
    
    let interestOptions = [
        ("health", "Health & Wellness"),
        ("career", "Career & Work"),
        ("relationships", "Relationships"),
        ("creativity", "Creativity"),
        ("spirituality", "Spirituality"),
        ("finance", "Finance"),
        ("travel", "Travel"),
        ("learning", "Learning")
    ]
    
    let timeOptions = [
        ("morning", "Morning"),
        ("afternoon", "Afternoon"),
        ("evening", "Evening"),
        ("flexible", "Flexible")
    ]
    
    private let authService = AuthService.shared
    private let notificationService = NotificationService.shared
    
    // MARK: - Navigation
    
    var canProceed: Bool {
        switch currentStep {
        case 1: return !preferredName.isEmpty
        case 2: return !journalingExperience.isEmpty
        case 3: return !primaryGoals.isEmpty
        case 4: return !interests.isEmpty
        case 5: return !preferredTime.isEmpty
        default: return true
        }
    }
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        } else {
            completeOnboarding()
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    func skipToEnd() {
        completeOnboarding()
    }
    
    // MARK: - Goal Selection
    
    func toggleGoal(_ goal: String) {
        if primaryGoals.contains(goal) {
            primaryGoals.remove(goal)
        } else if primaryGoals.count < 3 {
            primaryGoals.insert(goal)
        }
    }
    
    func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            interests.remove(interest)
        } else if interests.count < 5 {
            interests.insert(interest)
        }
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() async {
        notificationsEnabled = await notificationService.requestAuthorization()
    }
    
    func setupReminders() {
        if morningReminderEnabled {
            notificationService.setMorningReminder(enabled: true, time: morningReminderTime)
        }
        if eveningReminderEnabled {
            notificationService.setEveningReminder(enabled: true, time: eveningReminderTime)
        }
    }
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding() {
        isLoading = true
        
        let onboardingData = User.OnboardingData(
            journalingExperience: journalingExperience,
            primaryGoals: Array(primaryGoals),
            preferredTime: preferredTime,
            morningReminderTime: morningReminderEnabled ? morningReminderTime : nil,
            eveningReminderTime: eveningReminderEnabled ? eveningReminderTime : nil,
            notificationsEnabled: notificationsEnabled,
            interests: Array(interests),
            completedAt: Date()
        )
        
        Task {
            do {
                try await authService.completeOnboarding(data: onboardingData)
                
                // Update preferred name
                if var user = authService.currentUser {
                    user.preferredName = preferredName
                    try await authService.updateUser(user)
                }
                
                // Setup reminders
                setupReminders()
                
                isLoading = false
                isComplete = true
            } catch {
                isLoading = false
            }
        }
    }
}

