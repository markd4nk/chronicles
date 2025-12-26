import SwiftUI

/// Papper Design Library - Shadow Tokens
/// Chronicles iOS App

struct ShadowTokens {
    
    // MARK: - Shadow Styles
    
    /// Slight shadow for cards and elevated elements
    struct SlightShadow {
        static let color = Color(hex: "e00000").opacity(0.13)
        static let radius: CGFloat = 4
        static let x: CGFloat = 0
        static let y: CGFloat = 1
    }
    
    /// Medium shadow for floating elements
    struct MediumShadow {
        static let color = Color.black.opacity(0.1)
        static let radius: CGFloat = 8
        static let x: CGFloat = 0
        static let y: CGFloat = 4
    }
    
    /// Large shadow for modals and sheets
    struct LargeShadow {
        static let color = Color.black.opacity(0.15)
        static let radius: CGFloat = 16
        static let x: CGFloat = 0
        static let y: CGFloat = 8
    }
}

// MARK: - Shadow Modifiers

extension View {
    /// Apply slight shadow style
    func slightShadow() -> some View {
        self.shadow(
            color: ShadowTokens.SlightShadow.color,
            radius: ShadowTokens.SlightShadow.radius,
            x: ShadowTokens.SlightShadow.x,
            y: ShadowTokens.SlightShadow.y
        )
    }
    
    /// Apply medium shadow style
    func mediumShadow() -> some View {
        self.shadow(
            color: ShadowTokens.MediumShadow.color,
            radius: ShadowTokens.MediumShadow.radius,
            x: ShadowTokens.MediumShadow.x,
            y: ShadowTokens.MediumShadow.y
        )
    }
    
    /// Apply large shadow style
    func largeShadow() -> some View {
        self.shadow(
            color: ShadowTokens.LargeShadow.color,
            radius: ShadowTokens.LargeShadow.radius,
            x: ShadowTokens.LargeShadow.x,
            y: ShadowTokens.LargeShadow.y
        )
    }
    
    /// Card style with background and shadow
    func cardStyle(colorScheme: ColorScheme) -> some View {
        self
            .background(Color.cardBackground(for: colorScheme))
            .cornerRadius(16)
            .slightShadow()
    }
}

