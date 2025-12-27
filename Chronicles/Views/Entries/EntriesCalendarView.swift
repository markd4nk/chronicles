//
//  EntriesCalendarView.swift
//  Chronicles
//
//  Calendar view of all entries
//

import SwiftUI

struct EntriesCalendarView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    
    var entriesForSelectedDate: [JournalEntry] {
        viewModel.entries.filter { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: selectedDate)
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#faf8f3")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: Papper.spacing.lg) {
                    // Calendar
                    calendarView
                    
                    // Entries for selected date
                    selectedDateEntries
                }
                .padding(.horizontal, Papper.spacing.lg)
                .padding(.vertical, Papper.spacing.md)
            }
        }
    }
    
    // MARK: - Calendar View
    
    private var calendarView: some View {
        VStack(spacing: Papper.spacing.md) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(PapperColors.neutral700)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(PapperColors.neutral800)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(PapperColors.neutral700)
                }
            }
            .padding(.horizontal, Papper.spacing.sm)
            
            // Day Headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Papper.spacing.sm) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PapperColors.neutral500)
                        .frame(height: 30)
                }
            }
            
            // Days Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Papper.spacing.xs) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEntries: hasEntries(for: date),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(Papper.spacing.lg)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Selected Date Entries
    
    private var selectedDateEntries: some View {
        VStack(alignment: .leading, spacing: Papper.spacing.md) {
            // Date Header
            Text(selectedDate.fullDateString)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(PapperColors.neutral800)
            
            if entriesForSelectedDate.isEmpty {
                // No entries
                VStack(spacing: Papper.spacing.md) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(PapperColors.neutral400)
                    
                    Text("No entries on this day")
                        .font(Papper.typography.body)
                        .foregroundColor(PapperColors.neutral600)
                }
                .frame(maxWidth: .infinity)
                .padding(Papper.spacing.xxl)
            } else {
                // Entries list
                ForEach(entriesForSelectedDate) { entry in
                    NavigationLink(destination: JournalEntryView(entry: entry)) {
                        CalendarEntryCard(entry: entry, viewModel: viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        // Add days from the start of the first week
        while currentDate < monthInterval.start {
            days.append(nil)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Add all days in the month
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Fill remaining cells to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasEntries(for date: Date) -> Bool {
        viewModel.entries.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntries: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(PapperColors.neutral700)
                            .frame(width: 36, height: 36)
                    } else if isToday {
                        Circle()
                            .stroke(PapperColors.neutral700, lineWidth: 1)
                            .frame(width: 36, height: 36)
                    }
                    
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 15, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : PapperColors.neutral800)
                }
                
                // Entry indicator
                Circle()
                    .fill(hasEntries ? PapperColors.neutral700 : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 50)
        }
    }
}

// MARK: - Calendar Entry Card

struct CalendarEntryCard: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    
    var body: some View {
        HStack(spacing: Papper.spacing.md) {
            // Time
            VStack(spacing: 2) {
                Text(entry.createdAt.timeString)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PapperColors.neutral700)
            }
            .frame(width: 60)
            
            // Divider
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: viewModel.getJournalColor(for: entry)))
                .frame(width: 3, height: 50)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(PapperColors.neutral800)
                    .lineLimit(1)
                
                Text(viewModel.getJournalName(for: entry))
                    .font(.system(size: 12))
                    .foregroundColor(PapperColors.neutral500)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(PapperColors.neutral400)
        }
        .padding(Papper.spacing.md)
        .background(PapperColors.surfaceBackgroundPlain)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Preview

#if DEBUG
struct EntriesCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EntriesCalendarView()
        }
    }
}
#endif
