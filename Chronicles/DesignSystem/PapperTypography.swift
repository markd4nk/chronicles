//
//  PapperTypography.swift
//  Chronicles
//
//  Typography tokens from Papper Design Library
//

import SwiftUI

// MARK: - Papper Typography

struct PapperTypography {
    
    // MARK: - Font Families
    
    /// SF Pro - iOS system font (default)
    static func sfPro(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    /// New York Medium - Serif font for elegant headings
    static func newYorkMedium(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    
    /// IBM Plex Mono - Monospace font for code
    static func ibmPlexMono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    // MARK: - Font Sizes
    
    struct Sizes {
        static let header2: CGFloat = 24
        static let paywallTitle: CGFloat = 18
        static let bodyTitle: CGFloat = 16
        static let body: CGFloat = 14
        static let bodyDiscovery: CGFloat = 13
        static let paywallSubtitle: CGFloat = 12
        static let codeMono: CGFloat = 12
        static let bodySmall: CGFloat = 11
    }
    
    // MARK: - Font Weights
    
    struct Weights {
        static let regular: Font.Weight = .regular      // 400
        static let medium: Font.Weight = .medium        // 500
        static let semibold: Font.Weight = .semibold    // 600
        static let bold: Font.Weight = .bold            // 700
    }
    
    // MARK: - Text Styles (Pre-configured)
    
    /// Header 2 - SF Pro, 24px, Semibold
    static let header2: Font = .system(size: 24, weight: .semibold, design: .default)
    
    /// Body - SF Pro, 14px, Regular
    static let body: Font = .system(size: 14, weight: .regular, design: .default)
    
    /// Body Small - SF Pro, 11px, Regular
    static let bodySmall: Font = .system(size: 11, weight: .regular, design: .default)
    
    /// Body Title - SF Pro, 16px, Medium
    static let bodyTitle: Font = .system(size: 16, weight: .medium, design: .default)
    
    /// Body Discovery - SF Pro, 13px, Regular
    static let bodyDiscovery: Font = .system(size: 13, weight: .regular, design: .default)
    
    /// Paywall Title - New York Medium (Serif), 18px, Bold
    static let paywallTitle: Font = .system(size: 18, weight: .bold, design: .serif)
    
    /// Paywall Subtitle - SF Pro, 12px, Regular
    static let paywallSubtitle: Font = .system(size: 12, weight: .regular, design: .default)
    
    /// Code Mono - IBM Plex Mono (Monospaced), 12px, Regular
    static let codeMono: Font = .system(size: 12, weight: .regular, design: .monospaced)
    
    // MARK: - Line Heights
    
    struct LineHeights {
        static let header: CGFloat = 1.2
        static let bodyTitle: CGFloat = 1.3
        static let body: CGFloat = 1.4
        static let code: CGFloat = 1.5
    }
}

// MARK: - View Modifier for Text Styles

struct PapperTextStyle: ViewModifier {
    let font: Font
    let color: Color
    let lineHeightMultiplier: CGFloat
    
    init(font: Font, color: Color = PapperColors.fontMain, lineHeight: CGFloat = 1.4) {
        self.font = font
        self.color = color
        self.lineHeightMultiplier = lineHeight
    }
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .lineSpacing(4)
    }
}

// MARK: - View Extension for Easy Text Style Application

extension View {
    /// Apply header2 text style
    func papperHeader2() -> some View {
        modifier(PapperTextStyle(
            font: PapperTypography.header2,
            color: PapperColors.fontAccent,
            lineHeight: PapperTypography.LineHeights.header
        ))
    }
    
    /// Apply body text style
    func papperBody() -> some View {
        modifier(PapperTextStyle(
            font: PapperTypography.body,
            color: PapperColors.fontMain,
            lineHeight: PapperTypography.LineHeights.body
        ))
    }
    
    /// Apply body small text style
    func papperBodySmall() -> some View {
        modifier(PapperTextStyle(
            font: PapperTypography.bodySmall,
            color: PapperColors.fontSecondary,
            lineHeight: PapperTypography.LineHeights.body
        ))
    }
    
    /// Apply body title text style
    func papperBodyTitle() -> some View {
        modifier(PapperTextStyle(
            font: PapperTypography.bodyTitle,
            color: PapperColors.fontMain,
            lineHeight: PapperTypography.LineHeights.bodyTitle
        ))
    }
    
    /// Apply paywall title text style
    func papperPaywallTitle() -> some View {
        modifier(PapperTextStyle(
            font: PapperTypography.paywallTitle,
            color: PapperColors.fontPaywall,
            lineHeight: PapperTypography.LineHeights.header
        ))
    }
    
    /// Apply paywall subtitle text style
    func papperPaywallSubtitle() -> some View {
        modifier(PapperTextStyle(
            font: PapperTypography.paywallSubtitle,
            color: PapperColors.fontPaywall,
            lineHeight: PapperTypography.LineHeights.body
        ))
    }
    
    /// Apply code mono text style
    func papperCodeMono() -> some View {
        modifier(PapperTextStyle(
            font: PapperTypography.codeMono,
            color: PapperColors.fontMain,
            lineHeight: PapperTypography.LineHeights.code
        ))
    }
}

