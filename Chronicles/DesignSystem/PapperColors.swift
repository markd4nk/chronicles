//
//  PapperColors.swift
//  Chronicles
//
//  Design tokens from Papper Design Library
//

import SwiftUI

// MARK: - Color Extension for Hex Support

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

// MARK: - Papper Colors

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
    
    // MARK: - Special Colors
    
    static let coral700 = Color(hex: "#f97575")
    static let primary = Color(hex: "#FF6B6B")
    
    // MARK: - Semantic Colors - Surfaces
    
    static let surfaceButtonsPrimary = neutral700
    static let surfaceButtonsQuickAction = white60
    static let surfaceBackgroundPlain = neutral000
    static let surfaceBackgroundGray = neutral100
    static let surfaceBackgroundLogo = neutral100
    static let surfaceBackgroundModal = neutral000
    static let surfaceFirstLayer = primary
    static let surfaceSecondLayer = primary
    static let surfaceAccent = primary
    static let surfaceDiscoveryGray = neutral100
    static let surfaceDiscoveryFirstLayer = neutral000
    static let surfaceDiscoverySecondLayer = primary
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
    
    static let shadowColor = Color(hex: "#e00000").opacity(0.2)
}

// MARK: - Papper Gradients

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

