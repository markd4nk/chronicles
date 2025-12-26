import SwiftUI

// MARK: - Daily Quote Widget
// Chronicles iOS App - Papper Design Style

struct DailyQuoteWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    let quote: String
    let author: String
    
    init(
        quote: String = "The only way to do great work is to love what you do.",
        author: String = "Steve Jobs"
    ) {
        self.quote = quote
        self.author = author
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quote mark
            Image(systemName: "quote.opening")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(PapperColors.primary)
            
            // Quote text
            Text(quote)
                .font(PapperTypography.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
            
            // Author
            Text("— \(author)")
                .font(PapperTypography.bodySmall)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .papperShadow()
    }
    
    private var cardBackground: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.06)
            : .white
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        DailyQuoteWidget()
            .padding()
    }
    .preferredColorScheme(.dark)
}
