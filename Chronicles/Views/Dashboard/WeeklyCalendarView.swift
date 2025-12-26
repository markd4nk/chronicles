import SwiftUI

/// Weekly Calendar Selector
/// Chronicles iOS App - Papper Design Style

struct WeeklyCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.self) { date in
                DayCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    colorScheme: colorScheme
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Week Days
    
    private var weekDays: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // Calculate the start of the week (Monday)
        let daysToSubtract = (weekday + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            return []
        }
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let colorScheme: ColorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 6) {
            // Day label (Mo, Tu, etc.)
            Text(dayLabel)
                .font(TypographyTokens.calendarDayLabel)
                .foregroundColor(isSelected ? textColor : ColorTokens.Text.tertiary)
            
            // Day number
            Text(dayNumber)
                .font(TypographyTokens.calendarDay)
                .foregroundColor(textColor)
        }
        .frame(width: 44, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
    }
    
    // MARK: - Styling
    
    private var backgroundColor: Color {
        if isSelected {
            return colorScheme == .dark 
                ? ColorTokens.Dark.cardSecondary
                : ColorTokens.Light.cardSecondary
        }
        return .clear
    }
    
    private var textColor: Color {
        if isSelected || isToday {
            return colorScheme == .dark ? .white : .primary
        }
        return ColorTokens.Text.tertiary
    }
    
    // MARK: - Helpers
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return String(formatter.string(from: date).prefix(2))
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ColorTokens.Dark.background.ignoresSafeArea()
        WeeklyCalendarView()
            .padding()
    }
    .preferredColorScheme(.dark)
}

