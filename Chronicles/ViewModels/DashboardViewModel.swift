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
    @Published var activeWidgets: [DashboardWidget] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Cached data for optimized lookups
    @Published private(set) var widgetCompletionCache: [String: Bool] = [:]
    
    private let authService = AuthService.shared
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Cached DateFormatter (reused for performance)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    init() {
        setupBindings()
        // Load widgets immediately with cached data (non-blocking)
        loadWidgets()
    }
    
    private func setupBindings() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.currentStreak = user?.currentStreak ?? 0
                self?.longestStreak = user?.longestStreak ?? 0
                self?.loadWidgets()
            }
            .store(in: &cancellables)
        
        // Listen for entries updates from FirebaseService (auto-updates when data loads)
        firebaseService.$entries
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.updateTodaysEntries(from: entries)
            }
            .store(in: &cancellables)
        
        // Listen for data loaded signal to refresh dashboard
        firebaseService.$isDataLoaded
            .receive(on: DispatchQueue.main)
            .filter { $0 } // Only when data is loaded
            .sink { [weak self] _ in
                self?.loadDashboard()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Dashboard
    
    func loadDashboard() {
        loadWidgets()
        
        // Load today's entries in background (non-blocking)
        Task {
            await loadTodaysEntriesInBackground()
        }
    }
    
    /// Load entries in background without blocking UI
    private func loadTodaysEntriesInBackground() async {
        guard let userId = authService.currentUser?.id, !userId.isEmpty else {
            return
        }
        
        // Don't block UI - just update when data arrives
        do {
            let entries = try await firebaseService.fetchEntriesForDate(userId: userId, date: Date())
            todaysEntries = entries
            updateWidgetCompletionCache()
        } catch {
            // Silently handle - entries are only used for widget completion tracking
            print("[DashboardViewModel] Failed to load today's entries: \(error.localizedDescription)")
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
        updateWidgetCompletionCache()
    }
    
    func loadTodaysEntries() async {
        guard let userId = authService.currentUser?.id, !userId.isEmpty else {
            return
        }
        
        do {
            let entries = try await firebaseService.fetchEntriesForDate(userId: userId, date: Date())
            todaysEntries = entries
            updateWidgetCompletionCache()
        } catch {
            // Silently handle - entries are only used for widget completion tracking
            print("[DashboardViewModel] Failed to load today's entries: \(error.localizedDescription)")
        }
    }
    
    /// Update the cached widget completion status
    private func updateWidgetCompletionCache() {
        var newCache: [String: Bool] = [:]
        
        for widget in activeWidgets {
            let isCompleted = checkWidgetCompletion(widget)
            newCache[widget.id] = isCompleted
        }
        
        widgetCompletionCache = newCache
    }
    
    /// Check if a specific widget is completed (internal check)
    private func checkWidgetCompletion(_ widget: DashboardWidget) -> Bool {
        todaysEntries.contains { entry in
            if let templateId = widget.templateId {
                return entry.templateId == templateId
            }
            return entry.title.lowercased().contains(widget.title.lowercased())
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
    
    private let customWidgetsKey = "customWidgets"
    // #region agent log
    private static var loadWidgetsCallCount = 0
    // #endregion
    
    func loadWidgets() {
        // #region agent log
        DashboardViewModel.loadWidgetsCallCount += 1
        let callCount = DashboardViewModel.loadWidgetsCallCount
        Task { @MainActor in
            var request = URLRequest(url: URL(string: "http://127.0.0.1:7243/ingest/c77dc5f7-b92e-4545-af23-f0f74127ea45")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let payload: [String: Any] = ["location": "DashboardViewModel.swift:loadWidgets", "message": "loadWidgets called", "data": ["callCount": callCount, "hasUser": self.currentUser != nil], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "hypothesisId": "E"]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            _ = try? await URLSession.shared.data(for: request)
        }
        // #endregion
        // Load custom widgets from UserDefaults
        let customWidgets = loadCustomWidgets()
        
        // Load user's configured widget IDs
        let widgetIds = currentUser?.dashboardLayout ?? ["morning_reflection", "gratitude", "evening_review", "goals"]
        
        // Build active widgets list from IDs
        activeWidgets = widgetIds.compactMap { id in
            // First check default widgets
            if let defaultWidget = DashboardWidget.defaultWidgets.first(where: { $0.id == id }) {
                return defaultWidget
            }
            // Then check custom widgets
            return customWidgets.first(where: { $0.id == id })
        }
        
        // If no widgets found, use defaults
        if activeWidgets.isEmpty {
            activeWidgets = DashboardWidget.defaultWidgets
        }
    }
    
    func isWidgetCompleted(_ widget: DashboardWidget) -> Bool {
        // Use cached value for O(1) lookup, fallback to computation if not cached
        if let cached = widgetCompletionCache[widget.id] {
            return cached
        }
        return checkWidgetCompletion(widget)
    }
    
    func reorderWidgets(_ widgets: [DashboardWidget]) {
        activeWidgets = widgets
        saveWidgetLayout()
    }
    
    // MARK: - Widget Management
    
    /// Check if widget can be removed (must have at least 1 widget)
    var canRemoveWidget: Bool {
        activeWidgets.count > 1
    }
    
    /// Remove a widget from the dashboard
    func removeWidget(_ widget: DashboardWidget) {
        guard canRemoveWidget else { return }
        
        activeWidgets.removeAll { $0.id == widget.id }
        
        // If it's a custom widget, also remove from custom widgets storage
        if widget.isCustom {
            var customWidgets = loadCustomWidgets()
            customWidgets.removeAll { $0.id == widget.id }
            saveCustomWidgets(customWidgets)
        }
        
        saveWidgetLayout()
    }
    
    /// Create a new custom widget
    func createCustomWidget(
        title: String,
        question: String,
        journalId: String,
        templateText: String?,
        icon: String,
        color: String
    ) -> DashboardWidget {
        let widget = DashboardWidget(
            id: "custom_\(UUID().uuidString)",
            title: title,
            icon: icon,
            templateId: nil,
            color: color,
            isCustom: true,
            journalId: journalId,
            question: question,
            templateText: templateText
        )
        
        // Add to active widgets
        activeWidgets.append(widget)
        
        // Save custom widget
        var customWidgets = loadCustomWidgets()
        customWidgets.append(widget)
        saveCustomWidgets(customWidgets)
        
        // Save layout
        saveWidgetLayout()
        
        return widget
    }
    
    /// Add a default widget back to the dashboard
    func addDefaultWidget(_ widget: DashboardWidget) {
        // Don't add if already exists
        guard !activeWidgets.contains(where: { $0.id == widget.id }) else { return }
        
        activeWidgets.append(widget)
        saveWidgetLayout()
    }
    
    /// Get available default widgets that are not currently active
    var availableDefaultWidgets: [DashboardWidget] {
        DashboardWidget.defaultWidgets.filter { defaultWidget in
            !activeWidgets.contains(where: { $0.id == defaultWidget.id })
        }
    }
    
    // MARK: - Widget Persistence
    
    private func saveWidgetLayout() {
        // Save widget IDs to user preferences
        if var user = currentUser {
            user.dashboardLayout = activeWidgets.map { $0.id }
            Task {
                try? await authService.updateUser(user)
            }
        }
        
        // Also save to UserDefaults for immediate access
        let widgetIds = activeWidgets.map { $0.id }
        if let userId = currentUser?.id {
            UserDefaults.standard.set(widgetIds, forKey: "widgetLayout_\(userId)")
        }
    }
    
    private func loadCustomWidgets() -> [DashboardWidget] {
        guard let userId = currentUser?.id else { return [] }
        
        guard let data = UserDefaults.standard.data(forKey: "\(customWidgetsKey)_\(userId)"),
              let widgets = try? JSONDecoder().decode([DashboardWidget].self, from: data) else {
            return []
        }
        return widgets
    }
    
    private func saveCustomWidgets(_ widgets: [DashboardWidget]) {
        guard let userId = currentUser?.id else { return }
        
        if let data = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(data, forKey: "\(customWidgetsKey)_\(userId)")
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
        Self.dateFormatter.string(from: Date())
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Dashboard Widget

struct DashboardWidget: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let icon: String
    let templateId: String?
    let color: String
    
    // Custom widget properties
    var isCustom: Bool = false
    var journalId: String?
    var question: String?
    var templateText: String?
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DashboardWidget, rhs: DashboardWidget) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Default Widgets
    
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
    
    // MARK: - Available Icons for Custom Widgets
    
    static let availableIcons: [String] = [
        "sun.horizon.fill",
        "moon.stars.fill",
        "heart.fill",
        "target",
        "star.fill",
        "bolt.fill",
        "flame.fill",
        "leaf.fill",
        "drop.fill",
        "brain.head.profile",
        "figure.run",
        "book.fill",
        "pencil",
        "lightbulb.fill",
        "sparkles",
        "cloud.fill",
        "music.note",
        "camera.fill",
        "paintbrush.fill",
        "cup.and.saucer.fill"
    ]
    
    // MARK: - Available Colors for Custom Widgets
    
    static let availableColors: [String] = [
        "#F7D794", // Yellow
        "#F8B4B4", // Pink
        "#A8E6CF", // Green
        "#C3AED6", // Purple
        "#87CEEB", // Sky Blue
        "#FFB6C1", // Light Pink
        "#DDA0DD", // Plum
        "#98D8C8", // Mint
        "#F4A460", // Sandy Brown
        "#B8860B"  // Dark Golden
    ]
}




