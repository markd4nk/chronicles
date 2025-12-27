//
//  NotificationService.swift
//  Chronicles
//
//  Notification service for journaling reminders
//

import Foundation
import UserNotifications
import Combine

// MARK: - Notification Service

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var morningReminderEnabled = false
    @Published var eveningReminderEnabled = false
    @Published var morningReminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var eveningReminderTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
        loadPreferences()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            return false
        }
    }
    
    // MARK: - Preferences
    
    private func loadPreferences() {
        morningReminderEnabled = UserDefaults.standard.bool(forKey: "morningReminderEnabled")
        eveningReminderEnabled = UserDefaults.standard.bool(forKey: "eveningReminderEnabled")
        
        if let morningTime = UserDefaults.standard.object(forKey: "morningReminderTime") as? Date {
            morningReminderTime = morningTime
        }
        
        if let eveningTime = UserDefaults.standard.object(forKey: "eveningReminderTime") as? Date {
            eveningReminderTime = eveningTime
        }
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(morningReminderEnabled, forKey: "morningReminderEnabled")
        UserDefaults.standard.set(eveningReminderEnabled, forKey: "eveningReminderEnabled")
        UserDefaults.standard.set(morningReminderTime, forKey: "morningReminderTime")
        UserDefaults.standard.set(eveningReminderTime, forKey: "eveningReminderTime")
    }
    
    // MARK: - Morning Reminder
    
    func setMorningReminder(enabled: Bool, time: Date) {
        morningReminderEnabled = enabled
        morningReminderTime = time
        savePreferences()
        
        // Cancel existing morning reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["morning_reminder"])
        
        if enabled {
            scheduleMorningReminder()
        }
    }
    
    private func scheduleMorningReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning"
        content.body = "Start your day with a moment of reflection."
        content.sound = .default
        content.badge = 1
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: morningReminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "morning_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Evening Reminder
    
    func setEveningReminder(enabled: Bool, time: Date) {
        eveningReminderEnabled = enabled
        eveningReminderTime = time
        savePreferences()
        
        // Cancel existing evening reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["evening_reminder"])
        
        if enabled {
            scheduleEveningReminder()
        }
    }
    
    private func scheduleEveningReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Evening Reflection"
        content.body = "Take a moment to reflect on your day."
        content.sound = .default
        content.badge = 1
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: eveningReminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "evening_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - Manage All Reminders
    
    func enableAllReminders() {
        if morningReminderEnabled {
            scheduleMorningReminder()
        }
        if eveningReminderEnabled {
            scheduleEveningReminder()
        }
    }
    
    func disableAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Clear Badge
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

