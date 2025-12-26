import SwiftUI

// MARK: - Papper Design Library - Color Tokens
// Source: papper-design-tokens.json

/// Color tokens from Papper Design Library
enum PapperColors {
    
    // MARK: - Primary (from JSON)
    
    /// Primary accent color: #FF6B6B (coral/red)
    static let primary = Color(hex: "FF6B6B")
    
    // MARK: - Light Gradient (from JSON)
    
    /// Light gradient: conic-gradient(#f7d9d9 6.5%, #efe1e8 3.5%, #e1e5ef 87.5%)
    enum LightGradient {
        static let pink = Color(hex: "f7d9d9")       // 6.5%
        static let lavender = Color(hex: "efe1e8")   // 3.5%
        static let blueGray = Color(hex: "e1e5ef")   // 87.5%
    }
    
    // MARK: - Dark Gradient (from JSON)
    
    /// Dark gradient: conic-gradient(#f7baba 6.5%, #d9c8ea 3.5%, #ffccb3 87.5%)
    enum DarkGradient {
        static let warmPink = Color(hex: "f7baba")   // 6.5%
        static let purple = Color(hex: "d9c8ea")     // 3.5%
        static let peach = Color(hex: "ffccb3")      // 87.5%
    }
}

// MARK: - Papper Gradients

enum PapperGradients {
    
    /// Light mode conic gradient (from JSON)
    static func light() -> AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: PapperColors.LightGradient.blueGray, location: 0.0),
                .init(color: PapperColors.LightGradient.pink, location: 0.065),
                .init(color: PapperColors.LightGradient.lavender, location: 0.10),
                .init(color: PapperColors.LightGradient.blueGray, location: 0.875),
                .init(color: PapperColors.LightGradient.blueGray, location: 1.0)
            ]),
            center: .center
        )
    }
    
    /// Dark mode conic gradient (from JSON)
    static func dark() -> AngularGradient {
        AngularGradient(
            gradient: Gradient(stops: [
                .init(color: PapperColors.DarkGradient.peach, location: 0.0),
                .init(color: PapperColors.DarkGradient.warmPink, location: 0.065),
                .init(color: PapperColors.DarkGradient.purple, location: 0.10),
                .init(color: PapperColors.DarkGradient.peach, location: 0.875),
                .init(color: PapperColors.DarkGradient.peach, location: 1.0)
            ]),
            center: .center
        )
    }
    
    /// Linear gradient alternative for smoother appearance
    static func lightLinear() -> LinearGradient {
        LinearGradient(
            colors: [
                PapperColors.LightGradient.pink,
                PapperColors.LightGradient.lavender,
                PapperColors.LightGradient.blueGray
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func darkLinear() -> LinearGradient {
        LinearGradient(
            colors: [
                PapperColors.DarkGradient.warmPink,
                PapperColors.DarkGradient.purple,
                PapperColors.DarkGradient.peach
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Papper Shadow (from JSON)

enum PapperShadow {
    /// slight-shadow: color #e0000033, x: 0, y: 1, blur: 4
    static let color = Color(hex: "e00000").opacity(0.2) // 33 hex = 0.2 alpha
    static let radius: CGFloat = 4
    static let x: CGFloat = 0
    static let y: CGFloat = 1
}

// MARK: - View Extension for Shadow

extension View {
    /// Apply Papper slight-shadow from JSON
    func papperShadow() -> some View {
        self.shadow(
            color: PapperShadow.color,
            radius: PapperShadow.radius,
            x: PapperShadow.x,
            y: PapperShadow.y
        )
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1.0
        )
    }
}
