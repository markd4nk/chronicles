import SwiftUI

// MARK: - Papper Design Library - Typography Tokens
// Source: papper-design-tokens.json

/// Typography tokens from Papper Design Library
enum PapperTypography {
    
    // MARK: - Font Sizes (from JSON)
    
    enum Size {
        static let header2: CGFloat = 24
        static let bodyTitle: CGFloat = 16
        static let body: CGFloat = 14
        static let bodyDiscovery: CGFloat = 13
        static let paywallSubtitle: CGFloat = 12
        static let codeMono: CGFloat = 12
        static let bodySmall: CGFloat = 11
        static let paywallTitle: CGFloat = 18
    }
    
    // MARK: - Font Weights (from JSON)
    
    enum Weight {
        static let regular: Font.Weight = .regular     // 400
        static let medium: Font.Weight = .medium       // 500
        static let semibold: Font.Weight = .semibold   // 600
        static let bold: Font.Weight = .bold           // 700
    }
    
    // MARK: - Text Styles (from JSON)
    
    /// header2: SF Pro, 24px, semibold (600)
    static let header2 = Font.system(size: Size.header2, weight: .semibold, design: .default)
    
    /// bodyTitle: SF Pro, 16px, medium (500)
    static let bodyTitle = Font.system(size: Size.bodyTitle, weight: .medium, design: .default)
    
    /// body: SF Pro, 14px, regular (400)
    static let body = Font.system(size: Size.body, weight: .regular, design: .default)
    
    /// bodyDiscovery: SF Pro, 13px, regular (400)
    static let bodyDiscovery = Font.system(size: Size.bodyDiscovery, weight: .regular, design: .default)
    
    /// bodySmall: SF Pro, 11px, regular (400)
    static let bodySmall = Font.system(size: Size.bodySmall, weight: .regular, design: .default)
    
    /// paywallTitle: New York Medium (serif), 18px, bold (700)
    static let paywallTitle = Font.system(size: Size.paywallTitle, weight: .bold, design: .serif)
    
    /// paywallSubtitle: SF Pro, 12px, regular (400)
    static let paywallSubtitle = Font.system(size: Size.paywallSubtitle, weight: .regular, design: .default)
    
    /// codeMono: IBM Plex Mono (monospaced), 12px, regular (400)
    static let codeMono = Font.system(size: Size.codeMono, weight: .regular, design: .monospaced)
}

// MARK: - Custom Styles (derived from JSON)

extension PapperTypography {
    
    /// Large greeting title - derived from header2 style
    static let greeting = Font.system(size: 32, weight: .bold, design: .serif)
    
    /// Date subtitle with tracking
    static let dateSubtitle = Font.system(size: Size.bodySmall, weight: .medium, design: .default)
    
    /// Widget title
    static let widgetTitle = Font.system(size: Size.bodyTitle, weight: .semibold, design: .default)
    
    /// Widget subtitle
    static let widgetSubtitle = Font.system(size: Size.bodySmall, weight: .regular, design: .default)
    
    /// Calendar day number
    static let calendarDay = Font.system(size: Size.bodyTitle, weight: .medium, design: .default)
    
    /// Calendar day label
    static let calendarLabel = Font.system(size: Size.bodySmall, weight: .regular, design: .default)
}
