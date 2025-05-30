//
//  Exercise.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation

/// Represents a single exercise within a workout
/// 
/// Sample JSON:
/// ```json
/// {
///   "id": "550e8400-e29b-41d4-a716-446655440001",
///   "name": "Push-ups",
///   "duration": 60,
///   "equipment": "bodyweight",
///   "instructions": ["Start in plank position", "Lower body to ground", "Push back up"],
///   "targetReps": 12,
///   "targetSets": 3,
///   "restTime": 30,
///   "difficulty": "beginner",
///   "muscleGroups": ["chest", "triceps", "shoulders"],
///   "isTimeBased": false
/// }
/// ```
struct Exercise: Identifiable, Codable, Sendable {
    /// Unique identifier for the exercise
    let id: UUID
    
    /// Exercise name
    let name: String
    
    /// Duration for time-based exercises (in seconds)
    let duration: TimeInterval
    
    /// Required equipment type
    let equipment: EquipmentType
    
    /// Step-by-step instructions
    let instructions: [String]
    
    /// Target number of repetitions (if rep-based)
    let targetReps: Int?
    
    /// Target number of sets
    let targetSets: Int
    
    /// Rest time between sets (in seconds)
    let restTime: TimeInterval
    
    /// Exercise difficulty level
    let difficulty: DifficultyLevel
    
    /// Primary muscle groups targeted
    let muscleGroups: [String]
    
    /// Whether this exercise is time-based vs rep-based
    let isTimeBased: Bool
    
    /// Exercise category/focus
    let focus: FocusType
    
    /// Optional video URL or animation identifier
    let mediaReference: String?
    
    /// Accessibility considerations
    let accessibilityNotes: String?
    
    init(id: UUID = UUID(), name: String, duration: TimeInterval = 60,
         equipment: EquipmentType, instructions: [String] = [],
         targetReps: Int? = nil, targetSets: Int = 1, restTime: TimeInterval = 30,
         difficulty: DifficultyLevel = .beginner, muscleGroups: [String] = [],
         isTimeBased: Bool = true, focus: FocusType, mediaReference: String? = nil,
         accessibilityNotes: String? = nil) {
        self.id = id
        self.name = name
        self.duration = duration
        self.equipment = equipment
        self.instructions = instructions
        self.targetReps = targetReps
        self.targetSets = targetSets
        self.restTime = restTime
        self.difficulty = difficulty
        self.muscleGroups = muscleGroups
        self.isTimeBased = isTimeBased
        self.focus = focus
        self.mediaReference = mediaReference
        self.accessibilityNotes = accessibilityNotes
    }
}

/// Exercise difficulty levels
enum DifficultyLevel: String, Codable, CaseIterable, Sendable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "New to exercise or movement pattern"
        case .intermediate: return "Comfortable with basic movements"
        case .advanced: return "Experienced with complex movements"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "1.circle"
        case .intermediate: return "2.circle"
        case .advanced: return "3.circle"
        }
    }
}

/// Exercise progression tracking
struct ExerciseProgress: Identifiable, Codable, Sendable {
    let id: UUID
    let exerciseId: UUID
    let completedAt: Date
    let repsCompleted: Int?
    let durationCompleted: TimeInterval?
    let difficultyRating: Int // 1-5 scale
    let notes: String?
    
    init(id: UUID = UUID(), exerciseId: UUID, completedAt: Date = Date(),
         repsCompleted: Int? = nil, durationCompleted: TimeInterval? = nil,
         difficultyRating: Int = 3, notes: String? = nil) {
        self.id = id
        self.exerciseId = exerciseId
        self.completedAt = completedAt
        self.repsCompleted = repsCompleted
        self.durationCompleted = durationCompleted
        self.difficultyRating = difficultyRating
        self.notes = notes
    }
}

// MARK: - Exercise Extensions

extension Exercise {
    /// Returns formatted duration string
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Returns formatted target description
    var targetDescription: String {
        if isTimeBased {
            return formattedDuration
        } else if let reps = targetReps {
            return "\(reps) reps"
        } else {
            return "Complete"
        }
    }
    
    /// Returns whether this exercise requires jumping movements
    var hasJumpingMovements: Bool {
        let jumpingKeywords = ["jump", "hop", "bound", "plyometric", "explosive"]
        return jumpingKeywords.contains { name.lowercased().contains($0) }
    }
}

// MARK: - Sample Data

extension Exercise {
    static let sampleExercises: [Exercise] = [
        Exercise(
            name: "Push-ups",
            duration: 60,
            equipment: .bodyweight,
            instructions: [
                "Start in a plank position with hands shoulder-width apart",
                "Lower your body until your chest nearly touches the floor",
                "Push back up to starting position",
                "Keep your core tight throughout the movement"
            ],
            targetReps: 12,
            targetSets: 3,
            difficulty: .beginner,
            muscleGroups: ["chest", "triceps", "shoulders", "core"],
            isTimeBased: false,
            focus: .push
        ),
        Exercise(
            name: "Squats",
            duration: 45,
            equipment: .bodyweight,
            instructions: [
                "Stand with feet shoulder-width apart",
                "Lower your body as if sitting back into a chair",
                "Keep your knees behind your toes",
                "Return to standing position"
            ],
            targetReps: 15,
            targetSets: 3,
            difficulty: .beginner,
            muscleGroups: ["quadriceps", "glutes", "hamstrings"],
            isTimeBased: false,
            focus: .legs
        ),
        Exercise(
            name: "Plank Hold",
            duration: 30,
            equipment: .bodyweight,
            instructions: [
                "Start in a push-up position",
                "Lower to forearms",
                "Keep body in straight line from head to heels",
                "Engage core and hold position"
            ],
            targetSets: 3,
            difficulty: .beginner,
            muscleGroups: ["core", "shoulders"],
            isTimeBased: true,
            focus: .push
        )
    ]
} 