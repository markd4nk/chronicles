import SwiftUI

/// Main Dashboard View
/// Chronicles iOS App - Papper Design Style

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Mock data
    private let userName = "Mark"
    private let currentDate = Date()
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header section
                    headerSection
                    
                    // Weekly calendar
                    WeeklyCalendarView()
                    
                    // Quick entry widgets
                    widgetSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .preferredColorScheme(.dark) // Preview in dark mode by default
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                // Dark mode: solid dark background with subtle gradient overlay
                ZStack {
                    ColorTokens.Dark.background
                    
                    LinearGradient(
                        colors: [
                            ColorTokens.Dark.gradientWarmPink.opacity(0.08),
                            ColorTokens.Dark.gradientPurple.opacity(0.05),
                            ColorTokens.Dark.gradientPeach.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                // Light mode: soft gradient
                GradientTokens.lightBackground
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // App logo placeholder
            Image(systemName: "triangle")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.bottom, 8)
            
            // Date subtitle
            Text(formattedDate.uppercased())
                .dateSubtitleStyle()
                .foregroundColor(ColorTokens.Text.tertiary)
            
            // Greeting
            Text(greeting)
                .greetingStyle()
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            // Profile button
            profileButton
        }
    }
    
    // MARK: - Profile Button
    
    private var profileButton: some View {
        Button(action: {
            // Profile action
        }) {
            Image(systemName: "person.circle")
                .font(.system(size: 28))
                .foregroundColor(ColorTokens.Widget.morning)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Widget Section
    
    private var widgetSection: some View {
        HStack(spacing: 16) {
            QuickEntryWidget(
                title: "Morning\nreflection",
                icon: "sun.max.fill",
                iconColor: ColorTokens.Widget.morning,
                status: .completed,
                colorScheme: colorScheme
            )
            
            QuickEntryWidget(
                title: "Evening\nreflection",
                icon: "moon.stars.fill",
                iconColor: ColorTokens.Widget.evening,
                status: .pending(prompt: "Assess your day"),
                colorScheme: colorScheme
            )
        }
    }
    
    // MARK: - Helpers
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        let timeOfDay: String
        
        switch hour {
        case 0..<12:
            timeOfDay = "Good Morning"
        case 12..<17:
            timeOfDay = "Good Afternoon"
        default:
            timeOfDay = "Good Evening"
        }
        
        return "\(timeOfDay), \(userName)!"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: currentDate)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}

#Preview("Light Mode") {
    DashboardView()
        .preferredColorScheme(.light)
}

