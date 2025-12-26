import SwiftUI

/// Papper Design Library - Typography Tokens
/// Chronicles iOS App

struct TypographyTokens {
    
    // MARK: - Font Sizes
    
    struct Size {
        static let header2: CGFloat = 24
        static let bodyTitle: CGFloat = 16
        static let body: CGFloat = 14
        static let bodyDiscovery: CGFloat = 13
        static let bodySmall: CGFloat = 11
        static let paywallTitle: CGFloat = 18
        static let paywallSubtitle: CGFloat = 12
        static let codeMono: CGFloat = 12
        
        // Additional sizes
        static let largeTitle: CGFloat = 34
        static let title: CGFloat = 28
        static let headline: CGFloat = 17
        static let caption: CGFloat = 12
    }
    
    // MARK: - Font Weights
    
    struct Weight {
        static let regular: Font.Weight = .regular
        static let medium: Font.Weight = .medium
        static let semibold: Font.Weight = .semibold
        static let bold: Font.Weight = .bold
    }
    
    // MARK: - Text Styles
    
    /// Large greeting text (Good Morning, Mark!)
    static var largeGreeting: Font {
        .system(size: Size.largeTitle, weight: .bold, design: .serif)
    }
    
    /// Header 2 style
    static var header2: Font {
        .system(size: Size.header2, weight: .semibold, design: .default)
    }
    
    /// Body title style
    static var bodyTitle: Font {
        .system(size: Size.bodyTitle, weight: .medium, design: .default)
    }
    
    /// Body text style
    static var body: Font {
        .system(size: Size.body, weight: .regular, design: .default)
    }
    
    /// Body small style
    static var bodySmall: Font {
        .system(size: Size.bodySmall, weight: .regular, design: .default)
    }
    
    /// Caption style
    static var caption: Font {
        .system(size: Size.caption, weight: .regular, design: .default)
    }
    
    /// Paywall title style (New York Medium equivalent)
    static var paywallTitle: Font {
        .system(size: Size.paywallTitle, weight: .bold, design: .serif)
    }
    
    /// Paywall subtitle style
    static var paywallSubtitle: Font {
        .system(size: Size.paywallSubtitle, weight: .regular, design: .default)
    }
    
    /// Monospace code style
    static var codeMono: Font {
        .system(size: Size.codeMono, weight: .regular, design: .monospaced)
    }
    
    /// Date subtitle (FRIDAY 26 DECEMBER 2025)
    static var dateSubtitle: Font {
        .system(size: Size.bodySmall, weight: .medium, design: .default)
    }
    
    /// Widget title
    static var widgetTitle: Font {
        .system(size: Size.bodyTitle, weight: .semibold, design: .default)
    }
    
    /// Widget subtitle
    static var widgetSubtitle: Font {
        .system(size: Size.bodySmall, weight: .regular, design: .default)
    }
    
    /// Calendar day number
    static var calendarDay: Font {
        .system(size: Size.bodyTitle, weight: .medium, design: .default)
    }
    
    /// Calendar day label (Mo, Tu, etc.)
    static var calendarDayLabel: Font {
        .system(size: Size.bodySmall, weight: .regular, design: .default)
    }
}

// MARK: - Text Style Modifiers

extension View {
    func greetingStyle() -> some View {
        self.font(TypographyTokens.largeGreeting)
    }
    
    func dateSubtitleStyle() -> some View {
        self
            .font(TypographyTokens.dateSubtitle)
            .tracking(1.5)
    }
    
    func widgetTitleStyle() -> some View {
        self.font(TypographyTokens.widgetTitle)
    }
    
    func widgetSubtitleStyle() -> some View {
        self.font(TypographyTokens.widgetSubtitle)
    }
}

