//
//  PapperSpacing.swift
//  Chronicles
//
//  Spacing tokens from Papper Design Library
//  Based on 4pt grid system
//

import SwiftUI

// MARK: - Papper Spacing

struct PapperSpacing {
    
    // MARK: - Spacing Scale (4pt Grid)
    
    /// 2pt - Extra extra extra small
    static let xxxs: CGFloat = 2
    
    /// 4pt - Extra extra small
    static let xxs: CGFloat = 4
    
    /// 8pt - Extra small
    static let xs: CGFloat = 8
    
    /// 12pt - Small
    static let sm: CGFloat = 12
    
    /// 16pt - Medium (base unit)
    static let md: CGFloat = 16
    
    /// 20pt - Large
    static let lg: CGFloat = 20
    
    /// 24pt - Extra large
    static let xl: CGFloat = 24
    
    /// 32pt - Extra extra large
    static let xxl: CGFloat = 32
    
    /// 40pt - Extra extra extra large
    static let xxxl: CGFloat = 40
    
    /// 48pt - Extra extra extra extra large
    static let xxxxl: CGFloat = 48
    
    // MARK: - Semantic Spacing
    
    /// Padding inside cards
    static let cardPadding: CGFloat = md
    
    /// Padding for screen edges
    static let screenPadding: CGFloat = lg
    
    /// Gap between list items
    static let listGap: CGFloat = sm
    
    /// Gap between sections
    static let sectionGap: CGFloat = xl
    
    /// Gap between inline elements
    static let inlineGap: CGFloat = xs
    
    /// Button padding horizontal
    static let buttonPaddingH: CGFloat = md
    
    /// Button padding vertical
    static let buttonPaddingV: CGFloat = sm
}

// MARK: - EdgeInsets Extensions

extension EdgeInsets {
    /// Standard card padding (16pt all around)
    static let papperCard = EdgeInsets(
        top: PapperSpacing.md,
        leading: PapperSpacing.md,
        bottom: PapperSpacing.md,
        trailing: PapperSpacing.md
    )
    
    /// Screen edge padding (20pt horizontal, 16pt vertical)
    static let papperScreen = EdgeInsets(
        top: PapperSpacing.md,
        leading: PapperSpacing.lg,
        bottom: PapperSpacing.md,
        trailing: PapperSpacing.lg
    )
    
    /// Button padding (12pt vertical, 16pt horizontal)
    static let papperButton = EdgeInsets(
        top: PapperSpacing.sm,
        leading: PapperSpacing.md,
        bottom: PapperSpacing.sm,
        trailing: PapperSpacing.md
    )
    
    /// Compact padding (8pt all around)
    static let papperCompact = EdgeInsets(
        top: PapperSpacing.xs,
        leading: PapperSpacing.xs,
        bottom: PapperSpacing.xs,
        trailing: PapperSpacing.xs
    )
}

// MARK: - View Extensions for Spacing

extension View {
    /// Apply card padding
    func papperCardPadding() -> some View {
        padding(EdgeInsets.papperCard)
    }
    
    /// Apply screen edge padding
    func papperScreenPadding() -> some View {
        padding(EdgeInsets.papperScreen)
    }
    
    /// Apply button padding
    func papperButtonPadding() -> some View {
        padding(EdgeInsets.papperButton)
    }
    
    /// Apply compact padding
    func papperCompactPadding() -> some View {
        padding(EdgeInsets.papperCompact)
    }
}

