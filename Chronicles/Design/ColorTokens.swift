import SwiftUI

/// Papper Design Library - Color Tokens
/// Chronicles iOS App

struct ColorTokens {
    
    // MARK: - Primary Colors
    
    /// Primary accent color - Coral/Red (#FF6B6B)
    static let primary = Color(hex: "FF6B6B")
    
    /// Primary color with opacity variants
    static let primaryLight = Color(hex: "FF6B6B").opacity(0.2)
    static let primaryMedium = Color(hex: "FF6B6B").opacity(0.6)
    
    // MARK: - Background Colors
    
    /// Light mode background colors
    struct Light {
        static let background = Color(hex: "F5F5F7")
        static let card = Color.white
        static let cardSecondary = Color(hex: "FAFAFA")
        
        /// Gradient colors for light mode
        static let gradientPink = Color(hex: "f7d9d9")
        static let gradientLavender = Color(hex: "efe1e8")
        static let gradientBlueGray = Color(hex: "e1e5ef")
    }
    
    /// Dark mode background colors
    struct Dark {
        static let background = Color(hex: "1C1C1E")
        static let card = Color(hex: "2C2C2E")
        static let cardSecondary = Color(hex: "3A3A3C")
        
        /// Gradient colors for dark mode
        static let gradientWarmPink = Color(hex: "f7baba")
        static let gradientPurple = Color(hex: "d9c8ea")
        static let gradientPeach = Color(hex: "ffccb3")
    }
    
    // MARK: - Text Colors
    
    struct Text {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(hex: "8E8E93")
        static let onPrimary = Color.white
    }
    
    // MARK: - Widget Colors
    
    struct Widget {
        static let morning = Color(hex: "FFB347") // Warm orange/yellow
        static let evening = Color(hex: "7B68EE") // Purple/blue
        static let completed = Color(hex: "34C759") // Green
        static let pending = Color(hex: "8E8E93") // Gray
    }
    
    // MARK: - Shadow
    
    /// Slight shadow color
    static let shadowColor = Color(hex: "e00000").opacity(0.2)
}

// MARK: - Gradient Definitions

struct GradientTokens {
    
    /// Light mode background gradient
    static var lightBackground: LinearGradient {
        LinearGradient(
            colors: [
                ColorTokens.Light.gradientPink,
                ColorTokens.Light.gradientLavender,
                ColorTokens.Light.gradientBlueGray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Dark mode background gradient
    static var darkBackground: LinearGradient {
        LinearGradient(
            colors: [
                ColorTokens.Dark.gradientWarmPink.opacity(0.3),
                ColorTokens.Dark.gradientPurple.opacity(0.3),
                ColorTokens.Dark.gradientPeach.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Adaptive background gradient based on color scheme
    static func adaptiveBackground(for colorScheme: ColorScheme) -> LinearGradient {
        colorScheme == .dark ? darkBackground : lightBackground
    }
}

// MARK: - Color Extension for Hex

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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Colors

extension Color {
    /// Returns adaptive card background color
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorTokens.Dark.card : ColorTokens.Light.card
    }
    
    /// Returns adaptive main background color
    static func mainBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? ColorTokens.Dark.background : ColorTokens.Light.background
    }
}

