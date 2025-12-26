import SwiftUI

// MARK: - Quick Entry Widget
// Chronicles iOS App - Papper Design Style

struct QuickEntryWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let icon: String
    let iconColor: Color
    var isCompleted: Bool = false
    var subtitle: String? = nil
    
    var body: some View {
        Button(action: { /* Open entry */ }) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(iconColor)
                
                Spacer()
                
                // Title
                Text(title)
                    .font(PapperTypography.widgetTitle)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 8)
                
                // Status
                statusView
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 180)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                if isCompleted {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: 1.5)
                }
            }
            .papperShadow()
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Status
    
    @ViewBuilder
    private var statusView: some View {
        if isCompleted {
            HStack(spacing: 6) {
                Text("Completed")
                    .font(PapperTypography.widgetSubtitle)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
            }
        } else if let subtitle {
            Text(subtitle)
                .font(PapperTypography.widgetSubtitle)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Styling
    
    private var cardBackground: Color {
        if isCompleted {
            return colorScheme == .dark ? .clear : Color(white: 0.97)
        }
        return colorScheme == .dark 
            ? Color.white.opacity(0.06)
            : .white
    }
    
    private var borderColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        HStack(spacing: 16) {
            QuickEntryWidget(
                title: "Morning\nreflection",
                icon: "sun.max.fill",
                iconColor: .orange,
                isCompleted: true
            )
            
            QuickEntryWidget(
                title: "Evening\nreflection",
                icon: "moon.stars.fill",
                iconColor: .purple,
                isCompleted: false,
                subtitle: "Assess your day"
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
