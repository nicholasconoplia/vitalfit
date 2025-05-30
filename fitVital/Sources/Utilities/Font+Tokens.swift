//
//  Font+Tokens.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// Design system font tokens for consistent typography
extension Font {
    // MARK: - Typography Scale
    
    /// Large page titles and main headings
    static let title = Font.system(size: 32, weight: .bold, design: .rounded)
    
    /// Section headings and important labels
    static let heading = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    /// Subsection headings
    static let subheading = Font.system(size: 20, weight: .medium, design: .rounded)
    
    /// Standard body text
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Emphasized body text
    static let bodyBold = Font.system(size: 16, weight: .semibold, design: .default)
    
    /// Smaller descriptive text
    static let caption = Font.system(size: 14, weight: .regular, design: .default)
    
    /// Small labels and secondary information
    static let footnote = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Button text
    static let button = Font.system(size: 16, weight: .medium, design: .rounded)
    
    /// Large button text
    static let buttonLarge = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    /// Navigation title
    static let navTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    /// Tab bar items
    static let tabItem = Font.system(size: 10, weight: .medium, design: .rounded)
    
    // MARK: - Specialized Fonts
    
    /// Numbers and metrics (using monospaced digits)
    static let numeric = Font.system(size: 16, weight: .medium, design: .monospaced)
    
    /// Large numeric displays
    static let numericLarge = Font.system(size: 24, weight: .bold, design: .monospaced)
    
    /// Timer displays
    static let timer = Font.system(size: 32, weight: .bold, design: .monospaced)
    
    /// Workout counter
    static let counter = Font.system(size: 48, weight: .bold, design: .monospaced)
}

/// Font utility functions
extension Font {
    /// Returns scaled font for accessibility
    static func scaledFont(size: CGFloat, weight: Weight = .regular, design: Design = .default) -> Font {
        return Font.system(size: size, weight: weight, design: design)
    }
    
    /// Returns font for workout phase titles
    static func phaseTitle() -> Font {
        return .system(size: 20, weight: .semibold, design: .rounded)
    }
    
    /// Returns font for exercise names
    static func exerciseName() -> Font {
        return .system(size: 18, weight: .medium, design: .rounded)
    }
    
    /// Returns font for exercise instructions
    static func exerciseInstructions() -> Font {
        return .system(size: 15, weight: .regular, design: .default)
    }
    
    /// Returns font for workout cards
    static func workoutCardTitle() -> Font {
        return .system(size: 22, weight: .semibold, design: .rounded)
    }
    
    /// Returns font for stats and metrics
    static func metric() -> Font {
        return .system(size: 20, weight: .bold, design: .monospaced)
    }
}

// MARK: - Dynamic Type Support

/// Extension to support Dynamic Type sizing
extension Font {
    /// Custom heading that scales with Dynamic Type
    static func dynamicHeading() -> Font {
        return Font.custom("SF Pro Rounded", size: 24, relativeTo: .headline)
    }
    
    /// Custom body that scales with Dynamic Type
    static func dynamicBody() -> Font {
        return Font.custom("SF Pro", size: 16, relativeTo: .body)
    }
    
    /// Custom caption that scales with Dynamic Type
    static func dynamicCaption() -> Font {
        return Font.custom("SF Pro", size: 14, relativeTo: .caption)
    }
}

// MARK: - Spacing Constants

/// Design system spacing tokens
struct Spacing {
    /// 4pt spacing
    static let xs: CGFloat = 4
    
    /// 8pt spacing
    static let sm: CGFloat = 8
    
    /// 16pt spacing
    static let md: CGFloat = 16
    
    /// 24pt spacing
    static let lg: CGFloat = 24
    
    /// 32pt spacing
    static let xl: CGFloat = 32
    
    /// 48pt spacing
    static let xxl: CGFloat = 48
    
    /// 64pt spacing
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius Constants

/// Design system corner radius tokens
struct CornerRadius {
    /// Small radius for buttons and small cards
    static let small: CGFloat = 8
    
    /// Medium radius for cards and containers
    static let medium: CGFloat = 12
    
    /// Large radius for modals and large containers
    static let large: CGFloat = 16
    
    /// Extra large radius for special elements
    static let extraLarge: CGFloat = 24
}

// MARK: - Shadow Constants

/// Design system shadow tokens
struct ShadowStyle {
    /// Light shadow for subtle elevation
    static let light = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    
    /// Medium shadow for cards
    static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    
    /// Heavy shadow for modals and overlays
    static let heavy = (color: Color.black.opacity(0.25), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
} 