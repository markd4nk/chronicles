import SwiftUI

// MARK: - Weekly Calendar View
// Chronicles iOS App - Papper Design Style

struct WeeklyCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { date in
                DayCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    colorScheme: colorScheme
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = date
                    }
                }
                
                if date != weekDays.last {
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var weekDays: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return []
        }
        
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let colorScheme: ColorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 6) {
            Text(dayLabel)
                .font(PapperTypography.calendarLabel)
                .foregroundStyle(isSelected ? .primary : .secondary)
            
            Text(dayNumber)
                .font(PapperTypography.calendarDay)
                .foregroundStyle(isSelected ? .primary : .tertiary)
        }
        .frame(width: 44, height: 64)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark 
                          ? Color.white.opacity(0.08)
                          : Color.black.opacity(0.05))
            }
        }
    }
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return String(formatter.string(from: date).prefix(2))
    }
    
    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WeeklyCalendarView()
            .padding()
    }
    .preferredColorScheme(.dark)
}
