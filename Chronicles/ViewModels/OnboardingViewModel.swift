//
//  OnboardingViewModel.swift
//  Chronicles
//
//  Onboarding flow view model
//  Works without authentication - stores data locally first
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
    @Published var primaryGoals: Set<String> = []
    @Published var morningReminderEnabled = false
    @Published var eveningReminderEnabled = false
    @Published var morningReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var eveningReminderTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var notificationsEnabled = false
    
    /// Whether we have a name from the user's account (Google/Apple sign-in)
    private(set) var hasAccountName = false
    
    // MARK: - Constants
    
    /// Base total steps in onboarding (11 steps: Welcome, Name, Goals, Reminder Intro, Morning, Evening, Notifications, Feature 1-3, Completion)
    private let baseTotalSteps = 11
    
    /// Effective total steps (10 if name step is skipped, 11 otherwise)
    var totalSteps: Int {
        hasAccountName ? baseTotalSteps - 1 : baseTotalSteps
    }
    
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
    
    // MARK: - Initialization
    
    init() {
        // Check if we have an account name from Google/Apple sign-in
        if let accountName = OnboardingViewModel.getAccountName(), !accountName.isEmpty {
            preferredName = accountName
            hasAccountName = true
        }
    }
    
    // MARK: - Navigation
    
    /// Steps (when name step is shown):
    /// 0 - Welcome
    /// 1 - Name (skipped if hasAccountName)
    /// 2 - Goals (required)
    /// 3 - Reminder Intro
    /// 4 - Morning Reminder
    /// 5 - Evening Reminder
    /// 6 - Notifications
    /// 7 - Feature Slide 1
    /// 8 - Feature Slide 2
    /// 9 - Feature Slide 3
    /// 10 - Completion
    var canProceed: Bool {
        switch currentStep {
        case 1: 
            // If we have account name and are on step 1, it's Goals step
            if hasAccountName {
                return !primaryGoals.isEmpty
            }
            // Otherwise it's Name step
            return !preferredName.isEmpty
        case 2: 
            // If we have account name, step 2 is Reminder Intro (always can proceed)
            // Otherwise it's Goals step
            return hasAccountName ? true : !primaryGoals.isEmpty
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
        
        defaults.set(preferredName, forKey: "onboarding_preferredName")
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
    
    /// Get locally stored preferred name
    static func getLocalPreferredName() -> String? {
        return UserDefaults.standard.string(forKey: "onboarding_preferredName")
    }
    
    /// Clear locally stored onboarding data (after sync)
    static func clearLocalOnboardingData() {
        let defaults = UserDefaults.standard
        let keys = [
            "onboarding_preferredName",
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
    
    // MARK: - Account Name (from Google/Apple Sign-In)
    
    private static let accountNameKey = "account_preferredName"
    
    /// Save the user's name from their Google/Apple account
    static func saveAccountName(_ name: String) {
        UserDefaults.standard.set(name, forKey: accountNameKey)
    }
    
    /// Get the user's name from their Google/Apple account
    static func getAccountName() -> String? {
        return UserDefaults.standard.string(forKey: accountNameKey)
    }
    
    /// Clear the stored account name
    static func clearAccountName() {
        UserDefaults.standard.removeObject(forKey: accountNameKey)
    }
}
