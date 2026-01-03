//
//  PapperDesignSystem.swift
//  Chronicles
//
//  Unified Design System from Papper Design Library
//  Contains all design tokens: Colors, Typography, Spacing, Shadows, Components
//

import SwiftUI

// ============================================================================
// MARK: - Color Extension for Hex Support
// ============================================================================

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ============================================================================
// MARK: - Papper Colors
// ============================================================================

struct PapperColors {
    
    // MARK: - Color Palette
    
    // Peach
    static let peach200 = Color(hex: "#f7e1d7")
    static let peach300 = Color(hex: "#f4d5c7")
    static let peach400 = Color(hex: "#ffccb3")
    
    // Pink
    static let pink200 = Color(hex: "#f7d9d9")
    static let pink300 = Color(hex: "#f4c9c9")
    static let pink400 = Color(hex: "#f7baba")
    static let pink600 = Color(hex: "#e57373")  // Warning/salmon color
    
    // Grayblue
    static let grayblue200 = Color(hex: "#e1e5ef")
    static let grayblue300 = Color(hex: "#d5dae8")
    static let grayblue400 = Color(hex: "#d1dcfa")
    
    // Green
    static let green50 = Color(hex: "#f1f4ee")
    static let green200 = Color(hex: "#e6f2d9")
    static let green300 = Color(hex: "#dcedc9")
    static let green400 = Color(hex: "#daf0c1")
    
    // Purple
    static let purple200 = Color(hex: "#e8e1ef")
    static let purple300 = Color(hex: "#dfd5e8")
    static let purple400 = Color(hex: "#d9c8ea")
    
    // Mint
    static let mint200 = Color(hex: "#deede9")
    static let mint300 = Color(hex: "#d0e6e0")
    static let mint400 = Color(hex: "#c4eee3")
    
    // Lavanda
    static let lavanda200 = Color(hex: "#efe1e8")
    static let lavanda300 = Color(hex: "#e8d5df")
    static let lavanda400 = Color(hex: "#f5d6e6")
    
    // Yellow
    static let yellow200 = Color(hex: "#f2ecd9")
    static let yellow300 = Color(hex: "#ede4c9")
    static let yellow400 = Color(hex: "#f7eaba")
    
    // Blue
    static let blue200 = Color(hex: "#e1ebef")
    static let blue300 = Color(hex: "#d5e3e8")
    static let blue400 = Color(hex: "#c2e3f0")
    
    // Greenish
    static let greenish200 = Color(hex: "#e0ebe0")
    static let greenish300 = Color(hex: "#d3e3d3")
    static let greenish400 = Color(hex: "#c6ecc6")
    
    // MARK: - Neutral Colors
    
    static let neutral000 = Color(hex: "#ffffff")
    static let neutral100 = Color(hex: "#f6f6f6")
    static let neutral200b = Color(hex: "#eef0f2")
    static let neutral300 = Color(hex: "#e0e0e0")
    static let neutral400 = Color(hex: "#bdbdbd")
    static let neutral500 = Color(hex: "#828282")
    static let neutral550b = Color(hex: "#646d6d")
    static let neutral600 = Color(hex: "#4f4f4f")
    static let neutral700 = Color(hex: "#414141")
    static let neutral800 = Color(hex: "#333333")
    static let neutral900 = Color(hex: "#272727")
    static let neutral999 = Color(hex: "#111111")
    static let neutral1000 = Color(hex: "#000000")
    
    // MARK: - Translucent Colors
    
    static let black40 = Color.black.opacity(0.4)
    static let white40 = Color.white.opacity(0.4)
    static let white60 = Color.white.opacity(0.6)
    static let neutral700Translucent = Color(hex: "#414141").opacity(0.5)
    static let neutral700Translucent80 = Color(hex: "#414141").opacity(0.8)
    static let neutral600Translucent = Color(hex: "#4f4f4f").opacity(0.5)
    static let neutral550bTranslucent80 = Color(hex: "#646d6d").opacity(0.8)
    
    // MARK: - Semantic Colors - Surfaces
    
    static let surfaceButtonsPrimary = neutral700
    static let surfaceButtonsQuickAction = white60
    static let surfaceBackgroundPlain = neutral000
    static let surfaceBackgroundGray = neutral100
    static let surfaceBackgroundLogo = neutral100
    static let surfaceBackgroundModal = neutral000
    static let surfaceFirstLayer = peach200       // Main layer background (light)
    static let surfaceSecondLayer = peach200      // Second layer background (light)
    static let surfaceFirstLayerDark = neutral800 // Main layer background (dark)
    static let surfaceSecondLayerDark = neutral700 // Second layer background (dark)
    static let surfaceAccent = neutral700
    static let surfaceDiscoveryGray = neutral100
    static let surfaceDiscoveryFirstLayer = neutral000
    static let surfaceDiscoverySecondLayer = neutral700
    static let surfaceTabsSurface = white60
    static let surfaceTabsSecondSurface = neutral550bTranslucent80
    static let surfacePaywallGray = neutral200b
    static let surfacePaywallButton = green50
    
    // MARK: - Semantic Colors - Fonts
    
    static let fontAccent = neutral1000
    static let fontMain = neutral700
    static let fontSecondary = neutral700Translucent80
    static let fontTabs = green50
    static let fontFancy = neutral550b
    static let fontButtons = neutral000
    static let fontNonColor = neutral700
    static let fontTextholder = neutral700Translucent
    static let fontPaywall = neutral900
    static let fontPaywallSamecolor = neutral900
    static let fontsPaywall = neutral900  // Alias for backwards compatibility
    
    // MARK: - Semantic Colors - Borders
    
    static let borderActive = neutral700
    static let borderInactive = neutral000
    static let borderGentle = neutral700Translucent
    static let borderDiscovery = neutral000
    static let borderSamecolor = neutral900
    
    // MARK: - Semantic Colors - Icons
    
    static let iconPrimary = neutral700Translucent80
    static let iconSecondary = neutral700Translucent
    
    // MARK: - Shadow Color
    
    static let shadowColor = Color.black.opacity(0.1)
    
    // MARK: - Gradient Convenience
    
    static let lightGradient = PapperGradients.lightLinear
}

// ============================================================================
// MARK: - Papper Gradients
// ============================================================================

struct PapperGradients {
    
    /// Light gradient - conic gradient with pink, lavanda, and grayblue
    static let light = AngularGradient(
        stops: [
            .init(color: PapperColors.lavanda200, location: 0.035),
            .init(color: PapperColors.pink200, location: 0.065),
            .init(color: PapperColors.grayblue200, location: 0.875)
        ],
        center: .center
    )
    
    /// Dark gradient - conic gradient with pink, purple, and peach
    static let dark = AngularGradient(
        stops: [
            .init(color: PapperColors.purple400, location: 0.035),
            .init(color: PapperColors.pink400, location: 0.065),
            .init(color: PapperColors.peach400, location: 0.875)
        ],
        center: .center
    )
    
    /// Linear version of light gradient for simpler use cases
    static let lightLinear = LinearGradient(
        colors: [PapperColors.pink200, PapperColors.lavanda200, PapperColors.grayblue200],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Linear version of dark gradient for simpler use cases
    static let darkLinear = LinearGradient(
        colors: [PapperColors.pink400, PapperColors.purple400, PapperColors.peach400],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// ============================================================================
// MARK: - Papper Typography
// ============================================================================

/// Typography system from Papper Design Library
///
/// Font Families:
/// - Hacky: Display/heading font (custom font - needs to be added)
/// - New York: Serif font for elegant text (system serif on iOS)
/// - SF Pro: Sans-serif for body text (system default on iOS)
/// - IBM Plex Mono: Monospace for code (custom font - needs to be added)
struct PapperTypography {
    
    // MARK: - Serif Fonts (Hacky, New York)
    
    /// Papper Title - Hacky Medium/Italic 60px
    static func papperTitle(italic: Bool = true) -> Font {
        if italic {
            return .custom("Hacky-MediumItalic", size: 60)
        }
        return .custom("Hacky-Medium", size: 60)
    }
    
    /// List Title - Hacky Extra Bold 32px
    static func listTitle() -> Font {
        .custom("Hacky-ExtraBold", size: 32)
    }
    
    /// Discovery Title - Hacky Semi Bold 32px
    static func discoveryTitle() -> Font {
        .custom("Hacky-SemiBold", size: 32)
    }
    
    /// Header Discovery - New York Extra Large Regular 28px
    static func headerDiscovery() -> Font {
        .system(size: 28, weight: .regular, design: .serif)
    }
    
    /// Description - New York Medium Regular 13px
    static func description() -> Font {
        .system(size: 13, weight: .regular, design: .serif)
    }
    
    /// Discovery Buttons - New York Medium Bold 13px
    static func discoveryButtons() -> Font {
        .system(size: 13, weight: .semibold, design: .serif)
    }
    
    /// Price Description - New York Regular 11px
    static func priceDescription() -> Font {
        .system(size: 11, weight: .regular, design: .serif)
    }
    
    // MARK: - Sans Serif Fonts (SF Pro)
    
    /// Paywall Title - SF Pro Bold 32px
    static func paywallTitleLarge() -> Font {
        .system(size: 32, weight: .bold, design: .default)
    }
    
    /// Paywall Subtitle - SF Pro Semibold 20px
    static func paywallSubtitleLarge() -> Font {
        .system(size: 20, weight: .semibold, design: .default)
    }
    
    /// Card Title / Header 2 - SF Pro Semibold 16px
    static func cardTitle() -> Font {
        .system(size: 16, weight: .semibold, design: .default)
    }
    
    /// Card Body / Body Discovery - SF Pro Regular 16px
    static func cardBody() -> Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    
    /// Body Title - SF Pro Bold 13px
    static func bodyTitleBold() -> Font {
        .system(size: 13, weight: .bold, design: .default)
    }
    
    /// Body - SF Pro Regular 13px
    static func bodyText() -> Font {
        .system(size: 13, weight: .regular, design: .default)
    }
    
    /// Body Small - SF Pro Regular 11px
    static func bodySmallText() -> Font {
        .system(size: 11, weight: .regular, design: .default)
    }
    
    /// Code Mono - IBM Plex Mono Medium 13px
    static func codeMono() -> Font {
        .custom("IBMPlexMono-Medium", size: 13)
    }
    
    // MARK: - Legacy Named Styles (for compatibility)
    
    static let header2: Font = .system(size: 24, weight: .semibold, design: .default)
    static let body: Font = .system(size: 14, weight: .regular, design: .default)
    static let bodySmall: Font = .system(size: 11, weight: .regular, design: .default)
    static let bodyTitle: Font = .system(size: 16, weight: .medium, design: .default)
    static let bodyDiscovery: Font = .system(size: 13, weight: .regular, design: .default)
    static let paywallTitle: Font = .system(size: 18, weight: .bold, design: .serif)
    static let paywallSubtitle: Font = .system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Font Size Constants
    
    struct Sizes {
        static let papperTitle: CGFloat = 60
        static let listTitle: CGFloat = 32
        static let discoveryTitleSize: CGFloat = 32
        static let headerDiscovery: CGFloat = 28
        static let descriptionSize: CGFloat = 13
        static let discoveryButtons: CGFloat = 13
        static let priceDescription: CGFloat = 11
        static let paywallTitleSize: CGFloat = 32
        static let paywallSubtitleSize: CGFloat = 20
        static let cardTitle: CGFloat = 16
        static let cardBody: CGFloat = 16
        static let bodyTitleSize: CGFloat = 13
        static let bodySize: CGFloat = 13
        static let bodySmallSize: CGFloat = 11
        static let codeMonoSize: CGFloat = 13
        static let header2: CGFloat = 24
        static let paywallTitleLegacy: CGFloat = 18
        static let paywallSubtitleLegacy: CGFloat = 12
        static let codeMono: CGFloat = 12
    }
    
    // MARK: - Font Weights
    
    struct Weights {
        static let regular: Font.Weight = .regular
        static let medium: Font.Weight = .medium
        static let semibold: Font.Weight = .semibold
        static let bold: Font.Weight = .bold
        static let extraBold: Font.Weight = .heavy
    }
    
    // MARK: - Line Heights
    
    struct LineHeights {
        static let header: CGFloat = 1.0
        static let body: CGFloat = 1.0
        static let code: CGFloat = 1.0
    }
}

// MARK: - Typography View Modifier

struct PapperTextStyle: ViewModifier {
    let font: Font
    let color: Color
    
    init(font: Font, color: Color = PapperColors.fontMain) {
        self.font = font
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }
}

// MARK: - Typography View Extensions

extension View {
    func papperTitleStyle(italic: Bool = true) -> some View {
        modifier(PapperTextStyle(font: PapperTypography.papperTitle(italic: italic), color: PapperColors.fontMain))
    }
    
    func papperListTitle() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.listTitle(), color: PapperColors.fontMain))
    }
    
    func papperDiscoveryTitle() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.discoveryTitle(), color: PapperColors.fontMain))
    }
    
    func papperCardTitle() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.cardTitle(), color: PapperColors.fontMain))
    }
    
    func papperDescription() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.description(), color: PapperColors.fontSecondary))
    }
    
    func papperBodyText() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.bodyText(), color: PapperColors.fontMain))
    }
    
    func papperBodySmallText() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.bodySmallText(), color: PapperColors.fontSecondary))
    }
    
    func papperHeader2() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.header2, color: PapperColors.fontAccent))
    }
    
    func papperBody() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.body, color: PapperColors.fontMain))
    }
    
    func papperBodySmall() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.bodySmall, color: PapperColors.fontSecondary))
    }
    
    func papperBodyTitle() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.bodyTitle, color: PapperColors.fontMain))
    }
    
    func papperPaywallTitle() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.paywallTitle, color: PapperColors.fontPaywall))
    }
    
    func papperPaywallSubtitle() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.paywallSubtitle, color: PapperColors.fontPaywall))
    }
    
    func papperCodeMono() -> some View {
        modifier(PapperTextStyle(font: PapperTypography.codeMono(), color: PapperColors.fontMain))
    }
}

// ============================================================================
// MARK: - Papper Spacing
// ============================================================================

struct PapperSpacing {
    
    // MARK: - Spacing Scale (4pt Grid)
    
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
    static let xxxxl: CGFloat = 48
    
    // MARK: - Semantic Spacing
    
    static let cardPadding: CGFloat = md
    static let screenPadding: CGFloat = lg
    static let listGap: CGFloat = sm
    static let sectionGap: CGFloat = xl
    static let inlineGap: CGFloat = xs
    static let buttonPaddingH: CGFloat = md
    static let buttonPaddingV: CGFloat = sm
}

// MARK: - Spacing EdgeInsets Extensions

extension EdgeInsets {
    static let papperCard = EdgeInsets(top: PapperSpacing.md, leading: PapperSpacing.md, bottom: PapperSpacing.md, trailing: PapperSpacing.md)
    static let papperScreen = EdgeInsets(top: PapperSpacing.md, leading: PapperSpacing.lg, bottom: PapperSpacing.md, trailing: PapperSpacing.lg)
    static let papperButton = EdgeInsets(top: PapperSpacing.sm, leading: PapperSpacing.md, bottom: PapperSpacing.sm, trailing: PapperSpacing.md)
    static let papperCompact = EdgeInsets(top: PapperSpacing.xs, leading: PapperSpacing.xs, bottom: PapperSpacing.xs, trailing: PapperSpacing.xs)
}

// MARK: - Spacing View Extensions

extension View {
    func papperCardPadding() -> some View { padding(EdgeInsets.papperCard) }
    func papperScreenPadding() -> some View { padding(EdgeInsets.papperScreen) }
    func papperButtonPadding() -> some View { padding(EdgeInsets.papperButton) }
    func papperCompactPadding() -> some View { padding(EdgeInsets.papperCompact) }
}

// ============================================================================
// MARK: - Papper Shadows
// ============================================================================

struct PapperShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

struct PapperShadows {
    static let slight = PapperShadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
    static let none = PapperShadow(color: .clear, radius: 0, x: 0, y: 0)
    static let soft = PapperShadow(color: PapperColors.neutral1000.opacity(0.08), radius: 8, x: 0, y: 2)
    static let medium = PapperShadow(color: PapperColors.neutral1000.opacity(0.12), radius: 16, x: 0, y: 4)
    static let strong = PapperShadow(color: PapperColors.neutral1000.opacity(0.16), radius: 24, x: 0, y: 8)
}

// MARK: - Shadow View Extensions

extension View {
    func papperShadow(_ shadow: PapperShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func papperSlightShadow() -> some View { papperShadow(PapperShadows.slight) }
    func papperSoftShadow() -> some View { papperShadow(PapperShadows.soft) }
    func papperMediumShadow() -> some View { papperShadow(PapperShadows.medium) }
    func papperStrongShadow() -> some View { papperShadow(PapperShadows.strong) }
}

// ============================================================================
// MARK: - Papper Components (Specifications)
// ============================================================================

struct PapperComponents {
    
    // MARK: - Card Specifications
    
    struct Cards {
        static let taskRadius: CGFloat = 16
        static let taskHeight: CGFloat = 97
        static let taskWidth: CGFloat = 266
        static let mainRadius: CGFloat = 35
        static let discoveryRadius: CGFloat = 10
    }
    
    // MARK: - Border Specifications
    
    struct Borders {
        static let thin: CGFloat = 1
        static let thick: CGFloat = 2
    }
    
    // MARK: - Checkbox Specifications
    
    struct Checkbox {
        static let thickness: CGFloat = 2
        static let checkerThickness: CGFloat = 2
        static let sizeLarge: CGFloat = 32
        static let sizeMedium: CGFloat = 26
        static let sizeSmall: CGFloat = 20
        static let size: CGFloat = 32
        static let squareRadius: CGFloat = 8
    }
    
    // MARK: - Device Specifications
    
    struct Device {
        static let iphoneRadius: CGFloat = 55
    }
    
    // MARK: - Logo Specifications
    
    struct Logo {
        static let outlineColor = PapperColors.neutral550b
        static let accentColor = PapperColors.purple400
        static let surfaceColor = PapperColors.green50
    }
    
    // MARK: - Button Specifications
    
    struct Buttons {
        static let primaryRadius: CGFloat = 12
        static let secondaryRadius: CGFloat = 10
        static let smallRadius: CGFloat = 8
        static let minHeight: CGFloat = 44
        static let standardHeight: CGFloat = 48
        static let quickActionRadius: CGFloat = 15
        static let quickActionPaddingH: CGFloat = 10
        static let quickActionPaddingV: CGFloat = 7
        static let bigRadius: CGFloat = 25
        static let bigBackdropBlur: CGFloat = 30
        static let bigBorderWidth: CGFloat = 10
        static let bigHeight: CGFloat = 50
        static let bigWidth: CGFloat = 203
        static let bigRoundSize: CGFloat = 50
        static let tabRadius: CGFloat = 35
        static let tabPadding: CGFloat = 10
        static let tabGap: CGFloat = 10
        static let actionSize: CGFloat = 30
        static let actionRadius: CGFloat = 22
    }
    
    // MARK: - Handle Specifications
    
    struct Handle {
        static let width: CGFloat = 39
        static let height: CGFloat = 4
        static let radius: CGFloat = 2.5
    }
    
    // Alias for backwards compatibility
    static let taskCardRadius: CGFloat = Cards.taskRadius
    static let mainCardRadius: CGFloat = Cards.mainRadius
    static let quickActionRadius: CGFloat = Buttons.quickActionRadius
}

// MARK: - Component View Extensions

extension View {
    func papperTaskCard() -> some View {
        self
            .frame(width: PapperComponents.Cards.taskWidth, height: PapperComponents.Cards.taskHeight)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(PapperComponents.Cards.taskRadius)
            .papperSlightShadow()
    }
    
    func papperMainCardRadius() -> some View {
        self.cornerRadius(PapperComponents.Cards.mainRadius)
    }
    
    func papperDiscoveryCardRadius() -> some View {
        self.cornerRadius(PapperComponents.Cards.discoveryRadius)
    }
    
    func papperTaskCardRadius() -> some View {
        self.cornerRadius(PapperComponents.Cards.taskRadius)
    }
    
    func papperThinBorder(color: Color = PapperColors.borderGentle) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: PapperComponents.Cards.taskRadius)
                .stroke(color, lineWidth: PapperComponents.Borders.thin)
        )
    }
    
    func papperThickBorder(color: Color = PapperColors.borderActive) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: PapperComponents.Cards.taskRadius)
                .stroke(color, lineWidth: PapperComponents.Borders.thick)
        )
    }
}

// ============================================================================
// MARK: - Papper Design System Namespace
// ============================================================================

/// Unified access point for all Papper design tokens
struct Papper {
    static let colors = PapperColors.self
    static let typography = PapperTypography.self
    static let spacing = PapperSpacing.self
    static let shadows = PapperShadows.self
    static let components = PapperComponents.self
    static let gradients = PapperGradients.self
}

// ============================================================================
// MARK: - Theme Environment
// ============================================================================

private struct PapperThemeKey: EnvironmentKey {
    static let defaultValue: PapperThemeMode = .light
}

enum PapperThemeMode {
    case light
    case dark
    case system
}

extension EnvironmentValues {
    var papperTheme: PapperThemeMode {
        get { self[PapperThemeKey.self] }
        set { self[PapperThemeKey.self] = newValue }
    }
}

// MARK: - Theme-Aware Colors

extension PapperColors {
    static func gradient(for mode: PapperThemeMode) -> AngularGradient {
        switch mode {
        case .light, .system: return PapperGradients.light
        case .dark: return PapperGradients.dark
        }
    }
    
    static func linearGradient(for mode: PapperThemeMode) -> LinearGradient {
        switch mode {
        case .light, .system: return PapperGradients.lightLinear
        case .dark: return PapperGradients.darkLinear
        }
    }
}

// ============================================================================
// MARK: - Papper Button (Legacy)
// ============================================================================

/// Legacy button component - prefer using PapperQuickActionButton or PapperBigButton
struct PapperButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case quickAction
    }
    
    init(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Papper.typography.bodyTitle)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: Papper.components.Buttons.standardHeight)
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return Papper.colors.fontButtons
        case .secondary, .quickAction: return Papper.colors.fontMain
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return Papper.colors.surfaceButtonsPrimary
        case .secondary: return Papper.colors.surfaceBackgroundGray
        case .quickAction: return Papper.colors.surfaceButtonsQuickAction
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .primary: return Papper.components.Buttons.primaryRadius
        case .secondary, .quickAction: return Papper.components.Buttons.secondaryRadius
        }
    }
}

// ============================================================================
// MARK: - Papper Card Style
// ============================================================================

struct PapperCardStyle: ViewModifier {
    let radius: CGFloat
    let shadow: PapperShadow
    
    func body(content: Content) -> some View {
        content
            .background(Papper.colors.surfaceBackgroundPlain)
            .cornerRadius(radius)
            .papperShadow(shadow)
    }
}

extension View {
    func papperCard(radius: CGFloat = Papper.components.Cards.taskRadius, shadow: PapperShadow = Papper.shadows.slight) -> some View {
        modifier(PapperCardStyle(radius: radius, shadow: shadow))
    }
}

// ============================================================================
// MARK: - Conditional View Extension
// ============================================================================

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// ============================================================================
// MARK: - Helper Shapes
// ============================================================================

/// Helper for rounded corners on specific sides
struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

