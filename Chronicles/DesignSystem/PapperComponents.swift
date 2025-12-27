//
//  PapperComponents.swift
//  Chronicles
//
//  Component tokens from Papper Design Library
//

import SwiftUI

// MARK: - Papper Components

struct PapperComponents {
    
    // MARK: - Card Specifications
    
    struct Cards {
        /// Task card corner radius (16pt)
        static let taskRadius: CGFloat = 16
        
        /// Task card height (97pt)
        static let taskHeight: CGFloat = 97
        
        /// Task card width (266pt)
        static let taskWidth: CGFloat = 266
        
        /// Main card corner radius (35pt)
        static let mainRadius: CGFloat = 35
        
        /// Discovery card corner radius (10pt)
        static let discoveryRadius: CGFloat = 10
    }
    
    // MARK: - Border Specifications
    
    struct Borders {
        /// Thin border width (1pt)
        static let thin: CGFloat = 1
        
        /// Thick border width (2pt)
        static let thick: CGFloat = 2
    }
    
    // MARK: - Checkbox Specifications
    
    struct Checkbox {
        /// Checkbox border thickness (3pt)
        static let thickness: CGFloat = 3
        
        /// Checkmark stroke thickness (2pt)
        static let checkerThickness: CGFloat = 2
        
        /// Default checkbox size
        static let size: CGFloat = 24
    }
    
    // MARK: - Device Specifications
    
    struct Device {
        /// iPhone corner radius for mockups (55pt)
        static let iphoneRadius: CGFloat = 55
    }
    
    // MARK: - Logo Specifications
    
    struct Logo {
        /// Logo outline color
        static let outlineColor = PapperColors.neutral550b
        
        /// Logo accent color
        static let accentColor = PapperColors.coral700
        
        /// Logo surface/background color
        static let surfaceColor = PapperColors.green50
    }
    
    // MARK: - Button Specifications
    
    struct Buttons {
        /// Primary button corner radius
        static let primaryRadius: CGFloat = 12
        
        /// Secondary button corner radius
        static let secondaryRadius: CGFloat = 10
        
        /// Small button corner radius
        static let smallRadius: CGFloat = 8
        
        /// Minimum button height
        static let minHeight: CGFloat = 44
        
        /// Standard button height
        static let standardHeight: CGFloat = 48
    }
}

// MARK: - View Extensions for Card Styling

extension View {
    /// Apply task card styling
    func papperTaskCard() -> some View {
        self
            .frame(width: PapperComponents.Cards.taskWidth, height: PapperComponents.Cards.taskHeight)
            .background(PapperColors.surfaceBackgroundPlain)
            .cornerRadius(PapperComponents.Cards.taskRadius)
            .papperSlightShadow()
    }
    
    /// Apply main card corner radius
    func papperMainCardRadius() -> some View {
        self.cornerRadius(PapperComponents.Cards.mainRadius)
    }
    
    /// Apply discovery card corner radius
    func papperDiscoveryCardRadius() -> some View {
        self.cornerRadius(PapperComponents.Cards.discoveryRadius)
    }
    
    /// Apply task card corner radius
    func papperTaskCardRadius() -> some View {
        self.cornerRadius(PapperComponents.Cards.taskRadius)
    }
}

// MARK: - View Extensions for Borders

extension View {
    /// Apply thin border
    func papperThinBorder(color: Color = PapperColors.borderGentle) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: PapperComponents.Cards.taskRadius)
                .stroke(color, lineWidth: PapperComponents.Borders.thin)
        )
    }
    
    /// Apply thick border
    func papperThickBorder(color: Color = PapperColors.borderActive) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: PapperComponents.Cards.taskRadius)
                .stroke(color, lineWidth: PapperComponents.Borders.thick)
        )
    }
}

