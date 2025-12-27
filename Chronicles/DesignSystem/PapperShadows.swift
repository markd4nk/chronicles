//
//  PapperShadows.swift
//  Chronicles
//
//  Shadow tokens from Papper Design Library
//

import SwiftUI

// MARK: - Shadow Definition

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

// MARK: - Papper Shadows

struct PapperShadows {
    
    // MARK: - Defined Shadows
    
    /// Slight shadow - subtle drop shadow with red tint
    /// Color: #e00000 at 20% opacity, Blur: 4pt, Y-offset: 1pt
    static let slight = PapperShadow(
        color: Color(hex: "#e00000").opacity(0.2),
        radius: 4,
        x: 0,
        y: 1
    )
    
    // MARK: - Additional Shadows (Derived)
    
    /// No shadow
    static let none = PapperShadow(
        color: .clear,
        radius: 0,
        x: 0,
        y: 0
    )
    
    /// Soft shadow - for elevated cards
    static let soft = PapperShadow(
        color: PapperColors.neutral1000.opacity(0.08),
        radius: 8,
        x: 0,
        y: 2
    )
    
    /// Medium shadow - for modals and popovers
    static let medium = PapperShadow(
        color: PapperColors.neutral1000.opacity(0.12),
        radius: 16,
        x: 0,
        y: 4
    )
    
    /// Strong shadow - for floating elements
    static let strong = PapperShadow(
        color: PapperColors.neutral1000.opacity(0.16),
        radius: 24,
        x: 0,
        y: 8
    )
}

// MARK: - View Extension for Shadows

extension View {
    /// Apply a Papper shadow
    func papperShadow(_ shadow: PapperShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    /// Apply slight shadow (default Papper shadow)
    func papperSlightShadow() -> some View {
        papperShadow(PapperShadows.slight)
    }
    
    /// Apply soft shadow
    func papperSoftShadow() -> some View {
        papperShadow(PapperShadows.soft)
    }
    
    /// Apply medium shadow
    func papperMediumShadow() -> some View {
        papperShadow(PapperShadows.medium)
    }
    
    /// Apply strong shadow
    func papperStrongShadow() -> some View {
        papperShadow(PapperShadows.strong)
    }
}

