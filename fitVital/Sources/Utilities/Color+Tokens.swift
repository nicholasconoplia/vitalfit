//
//  Color+Tokens.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// Design system color tokens for consistent theming
extension Color {
    // MARK: - Primary Colors
    /// Main background color - warm off-white #F7F6F2
    static let background = Color("Background")
    
    /// Primary accent color - calming green #5AA469
    static let accent = Color("Accent")
    
    /// Primary text color - dark gray #333333
    static let primaryText = Color("PrimaryText")
    
    /// Secondary text color - medium gray #666666
    static let secondaryText = Color("SecondaryText")
    
    // MARK: - Semantic Colors
    /// Success/completion states
    static let success = Color("Success")
    
    /// Warning/caution states
    static let warning = Color("Warning")
    
    /// Error/danger states
    static let error = Color("Error")
    
    /// Information states
    static let info = Color("Info")
    
    // MARK: - Surface Colors
    /// Card and container backgrounds
    static let surface = Color("Surface")
    
    /// Elevated surface (modals, overlays)
    static let surfaceElevated = Color("SurfaceElevated")
    
    /// Border color
    static let border = Color("Border")
    
    /// Divider lines
    static let divider = Color("Divider")
    
    // MARK: - Focus Type Colors
    /// Push exercise color
    static let pushColor = Color.orange
    
    /// Pull exercise color
    static let pullColor = Color.blue
    
    /// Legs exercise color
    static let legsColor = Color.green
    
    /// Cardio exercise color
    static let cardioColor = Color.red
    
    /// Mobility exercise color
    static let mobilityColor = Color.purple
    
    // MARK: - Difficulty Colors
    /// Beginner difficulty
    static let beginnerColor = Color.green.opacity(0.7)
    
    /// Intermediate difficulty
    static let intermediateColor = Color.orange.opacity(0.7)
    
    /// Advanced difficulty
    static let advancedColor = Color.red.opacity(0.7)
    
    // MARK: - Mood Colors
    /// Energized mood
    static let energizedColor = Color.yellow
    
    /// Neutral/meh mood
    static let neutralColor = Color.gray
    
    /// Tired mood
    static let tiredColor = Color.blue.opacity(0.6)
}

/// Color utility functions
extension Color {
    /// Returns color for given focus type
    static func focusColor(for focus: FocusType) -> Color {
        switch focus {
        case .push: return .pushColor
        case .pull: return .pullColor
        case .legs: return .legsColor
        case .cardio: return .cardioColor
        case .mobility: return .mobilityColor
        }
    }
    
    /// Returns color for given difficulty level
    static func difficultyColor(for difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .beginnerColor
        case .intermediate: return .intermediateColor
        case .advanced: return .advancedColor
        }
    }
    
    /// Returns color for given mood state
    static func moodColor(for mood: MoodState) -> Color {
        switch mood {
        case .energized: return .energizedColor
        case .meh: return .neutralColor
        case .tired: return .tiredColor
        }
    }
}

// MARK: - Color Fallbacks
/// Fallback colors when Assets.xcassets colors are not available
extension Color {
    static var backgroundFallback: Color {
        Color(red: 0.969, green: 0.965, blue: 0.949) // #F7F6F2
    }
    
    static var accentFallback: Color {
        Color(red: 0.353, green: 0.643, blue: 0.412) // #5AA469
    }
    
    static var primaryTextFallback: Color {
        Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    }
    
    static var secondaryTextFallback: Color {
        Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
    }
} 