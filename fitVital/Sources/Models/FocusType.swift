//
//  FocusType.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation

/// Workout focus categories based on movement patterns and muscle groups
/// 
/// Sample JSON:
/// ```json
/// {
///   "focus": "push",
///   "description": "Chest, shoulders, triceps"
/// }
/// ```
enum FocusType: String, Codable, CaseIterable, Sendable {
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    case cardio = "cardio"
    case mobility = "mobility"
    
    var displayName: String {
        switch self {
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .cardio: return "Cardio"
        case .mobility: return "Mobility"
        }
    }
    
    var description: String {
        switch self {
        case .push: return "Chest, shoulders, triceps"
        case .pull: return "Back, biceps, rear delts"
        case .legs: return "Glutes, quads, hamstrings, calves"
        case .cardio: return "Heart rate training"
        case .mobility: return "Flexibility and movement quality"
        }
    }
    
    var icon: String {
        switch self {
        case .push: return "arrow.up.circle"
        case .pull: return "arrow.down.circle"
        case .legs: return "figure.walk"
        case .cardio: return "heart"
        case .mobility: return "figure.flexibility"
        }
    }
    
    var color: String {
        switch self {
        case .push: return "orange"
        case .pull: return "blue"
        case .legs: return "green"
        case .cardio: return "red"
        case .mobility: return "purple"
        }
    }
    
    /// Returns typical exercises for this focus type
    var sampleExercises: [String] {
        switch self {
        case .push:
            return ["Push-ups", "Overhead Press", "Chest Press", "Tricep Dips"]
        case .pull:
            return ["Pull-ups", "Rows", "Lat Pulldowns", "Face Pulls"]
        case .legs:
            return ["Squats", "Lunges", "Deadlifts", "Calf Raises"]
        case .cardio:
            return ["Jumping Jacks", "High Knees", "Mountain Climbers", "Burpees"]
        case .mobility:
            return ["Cat-Cow", "Hip Circles", "Shoulder Rolls", "Leg Swings"]
        }
    }
} 