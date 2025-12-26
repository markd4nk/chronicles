import SwiftUI

/// Quick Entry Widget for Dashboard
/// Chronicles iOS App - Papper Design Style

enum WidgetStatus {
    case completed
    case pending(prompt: String)
    
    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }
}

struct QuickEntryWidget: View {
    let title: String
    let icon: String
    let iconColor: Color
    let status: WidgetStatus
    let colorScheme: ColorScheme
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Open journal entry creation
            print("Open entry for: \(title)")
        }) {
            widgetContent
        }
        .buttonStyle(WidgetButtonStyle())
    }
    
    // MARK: - Widget Content
    
    private var widgetContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
            
            Spacer()
            
            // Title
            Text(title)
                .widgetTitleStyle()
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.leading)
            
            // Status
            statusView
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .background(cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: status.isCompleted ? 1.5 : 0)
        )
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        Group {
            switch status {
            case .completed:
                HStack(spacing: 6) {
                    Text("Completed")
                        .widgetSubtitleStyle()
                        .foregroundColor(ColorTokens.Text.tertiary)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ColorTokens.Widget.completed)
                }
                
            case .pending(let prompt):
                Text(prompt)
                    .widgetSubtitleStyle()
                    .foregroundColor(ColorTokens.Text.tertiary)
            }
        }
    }
    
    // MARK: - Styling
    
    private var cardBackground: Color {
        if status.isCompleted {
            return colorScheme == .dark
                ? ColorTokens.Dark.background
                : ColorTokens.Light.background
        }
        return colorScheme == .dark
            ? ColorTokens.Dark.cardSecondary
            : ColorTokens.Light.card
    }
    
    private var borderColor: Color {
        if status.isCompleted {
            return colorScheme == .dark
                ? ColorTokens.Dark.cardSecondary
                : ColorTokens.Light.cardSecondary
        }
        return .clear
    }
}

// MARK: - Widget Button Style

struct WidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ColorTokens.Dark.background.ignoresSafeArea()
        
        HStack(spacing: 16) {
            QuickEntryWidget(
                title: "Morning\nreflection",
                icon: "sun.max.fill",
                iconColor: ColorTokens.Widget.morning,
                status: .completed,
                colorScheme: .dark
            )
            
            QuickEntryWidget(
                title: "Evening\nreflection",
                icon: "moon.stars.fill",
                iconColor: ColorTokens.Widget.evening,
                status: .pending(prompt: "Assess your day"),
                colorScheme: .dark
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

