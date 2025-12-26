import SwiftUI

/// Daily Quote Widget for Dashboard
/// Chronicles iOS App - Papper Design Style

struct DailyQuoteWidget: View {
    let colorScheme: ColorScheme
    
    // Mock quote data
    private let quote = "The only way to do great work is to love what you do."
    private let author = "Steve Jobs"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quote icon
            Image(systemName: "quote.opening")
                .font(.system(size: 24))
                .foregroundColor(ColorTokens.primary)
            
            // Quote text
            Text(quote)
                .font(TypographyTokens.body)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .lineSpacing(4)
            
            // Author
            Text("— \(author)")
                .font(TypographyTokens.bodySmall)
                .foregroundColor(ColorTokens.Text.tertiary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            colorScheme == .dark
                ? ColorTokens.Dark.cardSecondary
                : ColorTokens.Light.card
        )
        .cornerRadius(20)
        .slightShadow()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ColorTokens.Dark.background.ignoresSafeArea()
        
        DailyQuoteWidget(colorScheme: .dark)
            .padding()
    }
    .preferredColorScheme(.dark)
}

