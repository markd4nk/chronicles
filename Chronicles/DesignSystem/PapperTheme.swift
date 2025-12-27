//
//  PapperTheme.swift
//  Chronicles
//
//  Unified theme access for Papper Design System
//  Import this file to access all design tokens via the `Papper` namespace
//

import SwiftUI

// MARK: - Papper Design System Namespace

/// Unified access point for all Papper design tokens
///
/// Usage:
/// ```swift
/// Text("Hello")
///     .font(Papper.typography.header2)
///     .foregroundColor(Papper.colors.fontMain)
///     .padding(Papper.spacing.md)
///     .background(Papper.colors.surfaceBackgroundPlain)
///     .cornerRadius(Papper.components.Cards.taskRadius)
/// ```
struct Papper {
    /// Color palette and semantic colors
    static let colors = PapperColors.self
    
    /// Typography styles and fonts
    static let typography = PapperTypography.self
    
    /// Spacing scale
    static let spacing = PapperSpacing.self
    
    /// Shadow definitions
    static let shadows = PapperShadows.self
    
    /// Component specifications
    static let components = PapperComponents.self
    
    /// Gradient definitions
    static let gradients = PapperGradients.self
}

// MARK: - Theme Environment Key

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
    /// Returns the appropriate gradient based on theme mode
    static func gradient(for mode: PapperThemeMode) -> AngularGradient {
        switch mode {
        case .light, .system:
            return PapperGradients.light
        case .dark:
            return PapperGradients.dark
        }
    }
    
    /// Returns the appropriate linear gradient based on theme mode
    static func linearGradient(for mode: PapperThemeMode) -> LinearGradient {
        switch mode {
        case .light, .system:
            return PapperGradients.lightLinear
        case .dark:
            return PapperGradients.darkLinear
        }
    }
}

// MARK: - Papper Styled Button

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
        case .primary:
            return Papper.colors.fontButtons
        case .secondary:
            return Papper.colors.fontMain
        case .quickAction:
            return Papper.colors.fontMain
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Papper.colors.surfaceButtonsPrimary
        case .secondary:
            return Papper.colors.surfaceBackgroundGray
        case .quickAction:
            return Papper.colors.surfaceButtonsQuickAction
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .primary:
            return Papper.components.Buttons.primaryRadius
        case .secondary, .quickAction:
            return Papper.components.Buttons.secondaryRadius
        }
    }
}

// MARK: - Papper Card View Modifier

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
    /// Apply standard Papper card styling with customizable radius
    func papperCard(radius: CGFloat = Papper.components.Cards.taskRadius, shadow: PapperShadow = Papper.shadows.slight) -> some View {
        modifier(PapperCardStyle(radius: radius, shadow: shadow))
    }
}

// MARK: - Preview Helper

#if DEBUG
struct PapperTheme_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Papper.spacing.lg) {
            Text("Header 2")
                .font(Papper.typography.header2)
                .foregroundColor(Papper.colors.fontAccent)
            
            Text("Body text in the Papper style")
                .font(Papper.typography.body)
                .foregroundColor(Papper.colors.fontMain)
            
            Text("Small body text")
                .font(Papper.typography.bodySmall)
                .foregroundColor(Papper.colors.fontSecondary)
            
            PapperButton("Primary Button", style: .primary) { }
            
            PapperButton("Secondary Button", style: .secondary) { }
            
            HStack(spacing: Papper.spacing.sm) {
                ForEach([
                    Papper.colors.pink200,
                    Papper.colors.lavanda200,
                    Papper.colors.grayblue200,
                    Papper.colors.mint200,
                    Papper.colors.green200
                ], id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(Papper.spacing.xl)
        .background(Papper.colors.surfaceBackgroundGray)
    }
}
#endif

