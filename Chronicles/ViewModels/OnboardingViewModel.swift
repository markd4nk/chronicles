//
//  OnboardingViewModel.swift
//  Chronicles
//
//  Onboarding flow view model
//  Works without authentication - stores data locally first
//  Name is collected from Google/Apple sign-in after onboarding
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
    @Published var primaryGoals: Set<String> = []
    @Published var morningReminderEnabled = false
    @Published var eveningReminderEnabled = false
    @Published var morningReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var eveningReminderTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var notificationsEnabled = false
    
    // MARK: - Constants
    
    /// Total steps in onboarding (10 steps: Welcome, Goals, Reminder Intro, Morning, Evening, Notifications, Feature 1-3, Completion)
    let totalSteps = 10
    
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
    
    private let notificationService = NotificationService.shared
    
    // MARK: - Navigation
    
    /// Steps:
    /// 0 - Welcome
    /// 1 - Goals (required)
    /// 2 - Reminder Intro
    /// 3 - Morning Reminder
    /// 4 - Evening Reminder
    /// 5 - Notifications
    /// 6 - Feature Slide 1
    /// 7 - Feature Slide 2
    /// 8 - Feature Slide 3
    /// 9 - Completion
    var canProceed: Bool {
        switch currentStep {
        case 1: return !primaryGoals.isEmpty
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
    
    /// Complete onboarding - stores data locally without requiring authentication
    func completeOnboarding() {
        isLoading = true
        
        // Store onboarding data locally
        saveOnboardingDataLocally()
        
        // Setup reminders
        setupReminders()
        
        isLoading = false
        isComplete = true
    }
    
    /// Save onboarding data to UserDefaults for later sync after authentication
    private func saveOnboardingDataLocally() {
        let defaults = UserDefaults.standard
        
        defaults.set(Array(primaryGoals), forKey: "onboarding_primaryGoals")
        defaults.set(morningReminderEnabled, forKey: "onboarding_morningReminderEnabled")
        defaults.set(eveningReminderEnabled, forKey: "onboarding_eveningReminderEnabled")
        defaults.set(morningReminderTime, forKey: "onboarding_morningReminderTime")
        defaults.set(eveningReminderTime, forKey: "onboarding_eveningReminderTime")
        defaults.set(notificationsEnabled, forKey: "onboarding_notificationsEnabled")
        defaults.set(Date(), forKey: "onboarding_completedAt")
    }
    
    /// Get locally stored onboarding data (for syncing after auth)
    static func getLocalOnboardingData() -> User.OnboardingData? {
        let defaults = UserDefaults.standard
        
        guard defaults.object(forKey: "onboarding_completedAt") != nil else {
            return nil
        }
        
        return User.OnboardingData(
            journalingExperience: "", // Not collected in streamlined flow
            primaryGoals: defaults.stringArray(forKey: "onboarding_primaryGoals") ?? [],
            preferredTime: "", // Not collected in streamlined flow
            morningReminderTime: defaults.bool(forKey: "onboarding_morningReminderEnabled") ? defaults.object(forKey: "onboarding_morningReminderTime") as? Date : nil,
            eveningReminderTime: defaults.bool(forKey: "onboarding_eveningReminderEnabled") ? defaults.object(forKey: "onboarding_eveningReminderTime") as? Date : nil,
            notificationsEnabled: defaults.bool(forKey: "onboarding_notificationsEnabled"),
            interests: [], // Not collected in streamlined flow
            completedAt: defaults.object(forKey: "onboarding_completedAt") as? Date ?? Date()
        )
    }
    
    /// Clear locally stored onboarding data (after sync)
    static func clearLocalOnboardingData() {
        let defaults = UserDefaults.standard
        let keys = [
            "onboarding_primaryGoals",
            "onboarding_morningReminderEnabled",
            "onboarding_eveningReminderEnabled",
            "onboarding_morningReminderTime",
            "onboarding_eveningReminderTime",
            "onboarding_notificationsEnabled",
            "onboarding_completedAt"
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}
