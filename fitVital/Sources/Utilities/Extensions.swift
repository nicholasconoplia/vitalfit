//
//  Extensions.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI
import Foundation

// MARK: - Color Extensions

extension Color {
    /// Get focus-specific color
    static func focusColor(for focus: FocusType) -> Color {
        switch focus {
        case .push: return .red
        case .pull: return .blue
        case .legs: return .green
        case .cardio: return .orange
        case .mobility: return .purple
        }
    }
    
    /// Get difficulty-specific color
    static func difficultyColor(for difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    /// Border color for UI elements
    static var border: Color {
        return Color.gray.opacity(0.3)
    }
}

// MARK: - Workout Extensions

extension Workout {
    /// Formatted duration string
    var formattedDuration: String {
        let minutes = Int(estimatedDuration) / 60
        return "\(minutes) min"
    }
    
    /// Formatted scheduled time
    var formattedScheduledTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
    
    /// Formatted scheduled date and time
    var formattedScheduledDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
}

// MARK: - Exercise Extensions

extension Exercise {
    /// Target description for display
    var targetDescription: String {
        if let sets = sets, let reps = reps {
            return "\(sets) sets × \(reps) reps"
        } else if let duration = duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            if minutes > 0 {
                return "\(minutes):\(String(format: "%02d", seconds))"
            } else {
                return "\(seconds)s"
            }
        }
        return "As prescribed"
    }
}

// MARK: - TimeOfDay Extensions

extension TimeOfDay {
    /// Time range description
    var timeRange: String {
        switch self {
        case .morning: return "6:00 AM - 11:00 AM"
        case .afternoon: return "12:00 PM - 5:00 PM"
        case .evening: return "6:00 PM - 9:00 PM"
        }
    }
}

// MARK: - EquipmentType Extensions

extension EquipmentType {
    /// Icon for equipment type
    var icon: String {
        switch self {
        case .bodyweight: return "figure.strengthtraining.functional"
        case .dumbbells: return "dumbbell"
        case .barbell: return "barbell"
        case .kettlebell: return "kettlebell"
        case .resistanceBands: return "bandage"
        case .pullupBar: return "figure.pull.ups"
        case .yogaMat: return "figure.yoga"
        case .cardioMachine: return "figure.run"
        }
    }
}

// MARK: - DifficultyLevel Extensions

extension DifficultyLevel {
    /// Display name for difficulty
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - FocusType Extensions

extension FocusType {
    /// Description for focus type
    var description: String {
        switch self {
        case .push: return "Chest, shoulders, triceps"
        case .pull: return "Back, biceps, rear delts"
        case .legs: return "Glutes, quads, hamstrings, calves"
        case .cardio: return "Cardiovascular endurance"
        case .mobility: return "Flexibility and mobility"
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply focus modifier for text fields
    func focused() -> some View {
        self
    }
}

// MARK: - Font Extensions

extension Font {
    /// Button large font
    static var buttonLarge: Font {
        return .system(size: 18, weight: .semibold)
    }
    
    /// Numeric large font for stats
    static var numericLarge: Font {
        return .system(size: 20, weight: .bold, design: .rounded)
    }
} 