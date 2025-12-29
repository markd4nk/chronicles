//
//  DashboardViewModel.swift
//  Chronicles
//
//  Dashboard view model with streak and widgets
//

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var currentStreak = 0
    @Published var longestStreak = 0
    @Published var todaysEntries: [JournalEntry] = []
    @Published var recentEntries: [JournalEntry] = []
    @Published var activeWidgets: [DashboardWidget] = []
    @Published var isLoading = false
    
    private let authService = AuthService.shared
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadDashboard()
    }
    
    private func setupBindings() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.currentStreak = user?.currentStreak ?? 0
                self?.longestStreak = user?.longestStreak ?? 0
            }
            .store(in: &cancellables)
        
        firebaseService.$entries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.updateTodaysEntries(from: entries)
                self?.updateRecentEntries(from: entries)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Dashboard
    
    func loadDashboard() {
        loadWidgets()
        
        Task {
            await loadTodaysEntries()
        }
    }
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadTodaysEntries()
        await updateStreak()
    }
    
    // MARK: - Entries
    
    private func updateTodaysEntries(from entries: [JournalEntry]) {
        let calendar = Calendar.current
        todaysEntries = entries.filter { calendar.isDateInToday($0.createdAt) }
    }
    
    private func updateRecentEntries(from entries: [JournalEntry]) {
        recentEntries = Array(entries.prefix(5))
    }
    
    func loadTodaysEntries() async {
        let userId = authService.currentUser?.id ?? ""
        
        do {
            let entries = try await firebaseService.fetchEntriesForDate(userId: userId, date: Date())
            todaysEntries = entries
        } catch {
            // Handle silently
        }
    }
    
    // MARK: - Streak
    
    func updateStreak() async {
        let userId = authService.currentUser?.id ?? ""
        
        do {
            let (current, longest) = try await firebaseService.updateStreak(userId: userId)
            currentStreak = current
            longestStreak = longest
        } catch {
            // Handle silently
        }
    }
    
    // MARK: - Widgets
    
    func loadWidgets() {
        // Load user's configured widgets
        let widgetIds = currentUser?.dashboardLayout ?? ["morning_reflection", "gratitude", "evening_review", "goals"]
        
        activeWidgets = widgetIds.compactMap { id in
            DashboardWidget.defaultWidgets.first { $0.id == id }
        }
    }
    
    func isWidgetCompleted(_ widget: DashboardWidget) -> Bool {
        // Check if there's an entry today that matches this widget's template
        todaysEntries.contains { entry in
            entry.templateId == widget.templateId || entry.title.lowercased().contains(widget.title.lowercased())
        }
    }
    
    func reorderWidgets(_ widgets: [DashboardWidget]) {
        activeWidgets = widgets
        
        // Update user preferences
        if var user = currentUser {
            user.dashboardLayout = widgets.map { $0.id }
            Task {
                try? await authService.updateUser(user)
            }
        }
    }
    
    // MARK: - Greeting
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    var userName: String {
        currentUser?.firstName ?? "User"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Dashboard Widget

struct DashboardWidget: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let templateId: String?
    let color: String
    
    static let defaultWidgets: [DashboardWidget] = [
        DashboardWidget(
            id: "morning_reflection",
            title: "Morning Reflection",
            icon: "sun.horizon.fill",
            templateId: "template_morning",
            color: "#F7D794"
        ),
        DashboardWidget(
            id: "gratitude",
            title: "Gratitude",
            icon: "heart.fill",
            templateId: "template_gratitude",
            color: "#F8B4B4"
        ),
        DashboardWidget(
            id: "goals",
            title: "Daily Goals",
            icon: "target",
            templateId: "template_goals",
            color: "#A8E6CF"
        ),
        DashboardWidget(
            id: "evening_review",
            title: "Evening Review",
            icon: "moon.stars.fill",
            templateId: "template_evening",
            color: "#C3AED6"
        )
    ]
}

