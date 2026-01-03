//
//  DashboardView.swift
//  Chronicles
//
//  Dashboard view using Papper Design System
//

import SwiftUI

// MARK: - Dashboard View

struct DashboardView: View {
    @State private var selectedDate = Date()
    @State private var userName = "Mark"
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: Date()).uppercased()
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            PapperGradients.lightLinear
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Papper.spacing.xl) {
                    // Header Section
                    headerSection
                    
                    // Weekly Calendar
                    WeeklyCalendarView(selectedDate: $selectedDate)
                    
                    // Widgets Section
                    widgetsSection
                }
                .padding(.horizontal, Papper.spacing.lg)
                .padding(.top, Papper.spacing.md)
                .padding(.bottom, Papper.spacing.xxxl)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Papper.spacing.xxs) {
                Text("\(greeting),")
                    .font(Papper.typography.header2)
                    .foregroundColor(Papper.colors.fontAccent)
                
                Text(userName)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Papper.colors.fontAccent)
                
                Text(formattedDate)
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(Papper.colors.fontSecondary)
                    .padding(.top, Papper.spacing.xxs)
            }
            
            Spacer()
            
            // Profile Button
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(Papper.colors.surfaceBackgroundPlain)
                        .frame(width: 44, height: 44)
                        .papperSlightShadow()
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Papper.colors.fontMain)
                }
            }
        }
    }
    
    // MARK: - Widgets Section
    
    private var widgetsSection: some View {
        VStack(spacing: Papper.spacing.md) {
            // Section Header
            HStack {
                Text("Today's Focus")
                    .font(Papper.typography.bodyTitle)
                    .foregroundColor(Papper.colors.fontMain)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Papper.colors.purple400)
                }
            }
            
            // Quick Entry Widgets Row
            HStack(spacing: Papper.spacing.sm) {
                QuickEntryWidget(
                    title: "Morning Reflection",
                    icon: "sun.horizon.fill",
                    iconColor: Papper.colors.yellow400,
                    isCompleted: true
                )
                
                QuickEntryWidget(
                    title: "Goals for Today",
                    icon: "target",
                    iconColor: Papper.colors.purple400,
                    isCompleted: false
                )
            }
            
            // Daily Quote Widget
            DailyQuoteWidget(
                quote: "The only way to do great work is to love what you do.",
                author: "Steve Jobs"
            )
            
            // Additional Widget Row
            HStack(spacing: Papper.spacing.sm) {
                QuickEntryWidget(
                    title: "Gratitude",
                    icon: "heart.fill",
                    iconColor: Papper.colors.pink400,
                    isCompleted: false
                )
                
                QuickEntryWidget(
                    title: "Evening Review",
                    icon: "moon.stars.fill",
                    iconColor: Papper.colors.purple400,
                    isCompleted: false
                )
            }
            
            // Streak Widget
            StreakWidget(currentStreak: 7, longestStreak: 14)
        }
    }
}

// MARK: - Weekly Calendar View

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    
    private var weekDates: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // Adjust for Monday start (weekday 1 is Sunday in Calendar)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func dayNumber(_ date: Date) -> String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    var body: some View {
        VStack(spacing: Papper.spacing.sm) {
            HStack(spacing: 0) {
                ForEach(Array(zip(daysOfWeek.indices, daysOfWeek)), id: \.0) { index, day in
                    let date = weekDates[index]
                    
                    Button(action: { selectedDate = date }) {
                        VStack(spacing: Papper.spacing.xxs) {
                            Text(day)
                                .font(Papper.typography.bodySmall)
                                .foregroundColor(Papper.colors.fontSecondary)
                            
                            ZStack {
                                if isToday(date) || isSelected(date) {
                                    Circle()
                                        .fill(isToday(date) ? Papper.colors.purple400 : Papper.colors.surfaceBackgroundPlain)
                                        .frame(width: 36, height: 36)
                                        .papperSlightShadow()
                                }
                                
                                Text(dayNumber(date))
                                    .font(Papper.typography.bodyTitle)
                                    .foregroundColor(isToday(date) ? .white : Papper.colors.fontMain)
                            }
                            
                            // Entry indicator dot
                            Circle()
                                .fill(hasEntry(for: date) ? Papper.colors.green400 : .clear)
                                .frame(width: 6, height: 6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, Papper.spacing.sm)
            .padding(.horizontal, Papper.spacing.xs)
            .background(Papper.colors.surfaceBackgroundPlain)
            .cornerRadius(Papper.components.Cards.taskRadius)
            .papperSlightShadow()
        }
    }
    
    // Mock function - would check actual entries
    private func hasEntry(for date: Date) -> Bool {
        // For preview, show dots on some days
        let day = calendar.component(.day, from: date)
        return [25, 26, 27].contains(day)
    }
}

// MARK: - Quick Entry Widget

struct QuickEntryWidget: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isCompleted: Bool
    
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: Papper.spacing.sm) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(iconColor)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Papper.colors.green400)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: Papper.spacing.xxxs) {
                    Text(title)
                        .font(Papper.typography.bodyTitle)
                        .foregroundColor(Papper.colors.fontMain)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(isCompleted ? "Completed" : "Tap to start")
                        .font(Papper.typography.bodySmall)
                        .foregroundColor(isCompleted ? Papper.colors.green400 : Papper.colors.fontSecondary)
                }
            }
            .padding(Papper.spacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(Papper.colors.surfaceBackgroundPlain)
            .cornerRadius(Papper.components.Cards.taskRadius)
            .papperSlightShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Daily Quote Widget

struct DailyQuoteWidget: View {
    let quote: String
    let author: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.md) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24))
                    .foregroundColor(Papper.colors.purple400.opacity(0.6))
                
                Spacer()
                
                Text("Daily Inspiration")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(Papper.colors.fontSecondary)
            }
            
            Text(quote)
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(Papper.colors.fontMain)
                .lineSpacing(4)
            
            HStack {
                Spacer()
                Text("— \(author)")
                    .font(Papper.typography.body)
                    .foregroundColor(Papper.colors.fontSecondary)
                    .italic()
            }
        }
        .padding(Papper.spacing.lg)
        .background(
            ZStack {
                Papper.colors.surfaceBackgroundPlain
                
                // Decorative gradient overlay
                LinearGradient(
                    colors: [
                        Papper.colors.lavanda200.opacity(0.3),
                        Papper.colors.surfaceBackgroundPlain
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(Papper.components.Cards.taskRadius)
        .papperSlightShadow()
    }
}

// MARK: - Streak Widget

struct StreakWidget: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: Papper.spacing.lg) {
            // Current Streak
            VStack(spacing: Papper.spacing.xxs) {
                HStack(spacing: Papper.spacing.xxs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Papper.colors.purple400)
                    
                    Text("\(currentStreak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Papper.colors.fontAccent)
                }
                
                Text("Day Streak")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(Papper.colors.fontSecondary)
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(Papper.colors.neutral300)
                .frame(width: 1, height: 50)
            
            // Longest Streak
            VStack(spacing: Papper.spacing.xxs) {
                HStack(spacing: Papper.spacing.xxs) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Papper.colors.yellow400)
                    
                    Text("\(longestStreak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Papper.colors.fontAccent)
                }
                
                Text("Best Streak")
                    .font(Papper.typography.bodySmall)
                    .foregroundColor(Papper.colors.fontSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Papper.spacing.lg)
        .background(Papper.colors.surfaceBackgroundPlain)
        .cornerRadius(Papper.components.Cards.taskRadius)
        .papperSlightShadow()
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif

