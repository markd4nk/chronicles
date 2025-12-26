import SwiftUI

// MARK: - Dashboard View
// Chronicles iOS App - Papper Design Style

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Mock data
    private let userName = "Mark"
    
    var body: some View {
        ZStack {
            // Papper gradient background
            backgroundView
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    WeeklyCalendarView()
                    widgetSection
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        if colorScheme == .dark {
            // Dark mode: subtle gradient overlay
            ZStack {
                Color.black
                PapperGradients.darkLinear()
                    .opacity(0.15)
            }
        } else {
            // Light mode: full gradient
            PapperGradients.lightLinear()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Logo
            logoView
            
            // Date
            Text(formattedDate.uppercased())
                .font(PapperTypography.dateSubtitle)
                .tracking(1.5)
                .foregroundStyle(.secondary)
            
            // Greeting
            Text(greeting)
                .font(PapperTypography.greeting)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            profileButton
        }
    }
    
    private var logoView: some View {
        ZStack {
            // Radial lines effect
            ForEach(0..<24, id: \.self) { i in
                Rectangle()
                    .fill(.primary.opacity(0.3))
                    .frame(width: 1, height: 20)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(i) * 15))
            }
            
            // Triangle
            Image(systemName: "triangle")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(.primary)
        }
        .frame(width: 60, height: 60)
        .padding(.bottom, 8)
    }
    
    private var profileButton: some View {
        Button(action: {}) {
            Circle()
                .stroke(PapperColors.primary, lineWidth: 2)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(PapperColors.primary)
                }
        }
    }
    
    // MARK: - Widgets
    
    private var widgetSection: some View {
        HStack(spacing: 16) {
            QuickEntryWidget(
                title: "Morning\nreflection",
                icon: "sun.max.fill",
                iconColor: Color.orange,
                isCompleted: true
            )
            
            QuickEntryWidget(
                title: "Evening\nreflection",
                icon: "moon.stars.fill",
                iconColor: PapperColors.DarkGradient.purple,
                isCompleted: false,
                subtitle: "Assess your day"
            )
        }
    }
    
    // MARK: - Helpers
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let time = hour < 12 ? "Morning" : hour < 17 ? "Afternoon" : "Evening"
        return "Good \(time), \(userName)!"
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Previews

#Preview("Dark") {
    DashboardView()
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    DashboardView()
        .preferredColorScheme(.light)
}
