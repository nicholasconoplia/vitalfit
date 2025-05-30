//
//  Workout.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation

/// Represents a complete workout session
/// 
/// Sample JSON:
/// ```json
/// {
///   "id": "550e8400-e29b-41d4-a716-446655440002",
///   "title": "Upper Body Push",
///   "focus": "push",
///   "exercises": [...],
///   "scheduledDate": "2025-05-30T09:00:00Z",
///   "estimatedDuration": 1800,
///   "difficulty": "intermediate",
///   "isCompleted": false,
///   "equipment": ["dumbbells", "bodyweight"]
/// }
/// ```
struct Workout: Identifiable, Codable, Sendable {
    /// Unique identifier for the workout
    let id: UUID
    
    /// Workout title/name
    let title: String
    
    /// Primary focus of the workout
    let focus: FocusType
    
    /// List of exercises in order
    let exercises: [Exercise]
    
    /// When this workout is scheduled
    let scheduledDate: Date
    
    /// Estimated total duration in seconds
    let estimatedDuration: TimeInterval
    
    /// Overall workout difficulty
    let difficulty: DifficultyLevel
    
    /// Whether workout has been completed
    var isCompleted: Bool
    
    /// Date when workout was completed (if applicable)
    var completedAt: Date?
    
    /// Equipment needed for this workout
    let equipment: [EquipmentType]
    
    /// Optional description or notes
    let description: String?
    
    /// Workout phases (warmup, main, cooldown)
    let phases: [WorkoutPhase]
    
    /// Created date
    let createdAt: Date
    
    /// User rating after completion (1-5)
    var userRating: Int?
    
    /// User feedback/notes
    var userNotes: String?
    
    init(id: UUID = UUID(), title: String, focus: FocusType, exercises: [Exercise],
         scheduledDate: Date, estimatedDuration: TimeInterval = 0,
         difficulty: DifficultyLevel = .beginner, isCompleted: Bool = false,
         completedAt: Date? = nil, equipment: [EquipmentType] = [],
         description: String? = nil, phases: [WorkoutPhase] = [],
         createdAt: Date = Date(), userRating: Int? = nil, userNotes: String? = nil) {
        self.id = id
        self.title = title
        self.focus = focus
        self.exercises = exercises
        self.scheduledDate = scheduledDate
        self.estimatedDuration = estimatedDuration > 0 ? estimatedDuration : exercises.reduce(0) { $0 + $1.duration }
        self.difficulty = difficulty
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.equipment = equipment.isEmpty ? Array(Set(exercises.map { $0.equipment })) : equipment
        self.description = description
        self.phases = phases.isEmpty ? Self.defaultPhases(exercises: exercises) : phases
        self.createdAt = createdAt
        self.userRating = userRating
        self.userNotes = userNotes
    }
    
    /// Creates default workout phases if none provided
    private static func defaultPhases(exercises: [Exercise]) -> [WorkoutPhase] {
        let warmupExercises = exercises.prefix(2).map { $0 }
        let mainExercises = Array(exercises.dropFirst(2).dropLast(1))
        let cooldownExercises = exercises.suffix(1).map { $0 }
        
        return [
            WorkoutPhase(name: "Warmup", exercises: warmupExercises, isRequired: true),
            WorkoutPhase(name: "Main Workout", exercises: mainExercises, isRequired: true),
            WorkoutPhase(name: "Cooldown", exercises: cooldownExercises, isRequired: false)
        ]
    }
}

/// Workout phase structure (warmup, main, cooldown)
struct WorkoutPhase: Identifiable, Codable, Sendable {
    let id: UUID
    let name: String
    let exercises: [Exercise]
    let isRequired: Bool
    let description: String?
    
    init(id: UUID = UUID(), name: String, exercises: [Exercise], 
         isRequired: Bool = true, description: String? = nil) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.isRequired = isRequired
        self.description = description
    }
}

/// User's mood state affecting workout intensity
enum MoodState: String, Codable, CaseIterable, Sendable {
    case energized = "energized"
    case meh = "meh"
    case tired = "tired"
    
    var displayName: String {
        switch self {
        case .energized: return "Energized"
        case .meh: return "Feeling Meh"
        case .tired: return "Tired"
        }
    }
    
    var intensityMultiplier: Double {
        switch self {
        case .energized: return 1.1
        case .meh: return 1.0
        case .tired: return 0.8
        }
    }
    
    var icon: String {
        switch self {
        case .energized: return "bolt.fill"
        case .meh: return "minus.circle"
        case .tired: return "zzz"
        }
    }
}

/// Workout completion status
struct WorkoutCompletion: Identifiable, Codable, Sendable {
    let id: UUID
    let workoutId: UUID
    let completedAt: Date
    let actualDuration: TimeInterval
    let exercisesCompleted: Int
    let totalExercises: Int
    let moodBefore: MoodState
    let moodAfter: MoodState?
    let rating: Int // 1-5 scale
    let notes: String?
    
    init(id: UUID = UUID(), workoutId: UUID, completedAt: Date = Date(),
         actualDuration: TimeInterval, exercisesCompleted: Int, totalExercises: Int,
         moodBefore: MoodState, moodAfter: MoodState? = nil, rating: Int = 3,
         notes: String? = nil) {
        self.id = id
        self.workoutId = workoutId
        self.completedAt = completedAt
        self.actualDuration = actualDuration
        self.exercisesCompleted = exercisesCompleted
        self.totalExercises = totalExercises
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.rating = rating
        self.notes = notes
    }
}

// MARK: - Workout Extensions

extension Workout {
    /// Returns formatted duration string
    var formattedDuration: String {
        let minutes = Int(estimatedDuration) / 60
        return "\(minutes) min"
    }
    
    /// Returns completion percentage (0.0 - 1.0)
    var completionPercentage: Double {
        return isCompleted ? 1.0 : 0.0
    }
    
    /// Returns whether workout is scheduled for today
    var isScheduledForToday: Bool {
        Calendar.current.isDateInToday(scheduledDate)
    }
    
    /// Returns whether workout is overdue
    var isOverdue: Bool {
        !isCompleted && scheduledDate < Date()
    }
    
    /// Returns formatted scheduled time
    var formattedScheduledTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
    
    /// Returns total number of exercises
    var exerciseCount: Int {
        exercises.count
    }
    
    /// Adjusts workout intensity based on mood
    func adjustedForMood(_ mood: MoodState) -> Workout {
        let adjustedExercises = exercises.map { exercise in
            var adjusted = exercise
            
            // Modify duration/reps based on mood
            let multiplier = mood.intensityMultiplier
            
            if exercise.isTimeBased {
                adjusted = Exercise(
                    id: exercise.id,
                    name: exercise.name,
                    duration: exercise.duration * multiplier,
                    equipment: exercise.equipment,
                    instructions: exercise.instructions,
                    targetReps: exercise.targetReps,
                    targetSets: exercise.targetSets,
                    restTime: exercise.restTime,
                    difficulty: exercise.difficulty,
                    muscleGroups: exercise.muscleGroups,
                    isTimeBased: exercise.isTimeBased,
                    focus: exercise.focus,
                    mediaReference: exercise.mediaReference,
                    accessibilityNotes: exercise.accessibilityNotes
                )
            } else if let reps = exercise.targetReps {
                adjusted = Exercise(
                    id: exercise.id,
                    name: exercise.name,
                    duration: exercise.duration,
                    equipment: exercise.equipment,
                    instructions: exercise.instructions,
                    targetReps: Int(Double(reps) * multiplier),
                    targetSets: exercise.targetSets,
                    restTime: exercise.restTime,
                    difficulty: exercise.difficulty,
                    muscleGroups: exercise.muscleGroups,
                    isTimeBased: exercise.isTimeBased,
                    focus: exercise.focus,
                    mediaReference: exercise.mediaReference,
                    accessibilityNotes: exercise.accessibilityNotes
                )
            }
            
            return adjusted
        }
        
        return Workout(
            id: self.id,
            title: self.title,
            focus: self.focus,
            exercises: adjustedExercises,
            scheduledDate: self.scheduledDate,
            estimatedDuration: self.estimatedDuration * mood.intensityMultiplier,
            difficulty: self.difficulty,
            isCompleted: self.isCompleted,
            completedAt: self.completedAt,
            equipment: self.equipment,
            description: self.description,
            phases: self.phases,
            createdAt: self.createdAt,
            userRating: self.userRating,
            userNotes: self.userNotes
        )
    }
}

// MARK: - Sample Data

extension Workout {
    static let sampleWorkout = Workout(
        title: "Morning Energy Boost",
        focus: .push,
        exercises: Array(Exercise.sampleExercises.prefix(3)),
        scheduledDate: Date(),
        difficulty: .beginner,
        description: "A quick morning routine to energize your day"
    )
    
    static let sampleWorkouts: [Workout] = [
        sampleWorkout,
        Workout(
            title: "Leg Day Strong",
            focus: .legs,
            exercises: [Exercise.sampleExercises[1]],
            scheduledDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            difficulty: .intermediate,
            description: "Build lower body strength and stability"
        ),
        Workout(
            title: "Pull & Strengthen",
            focus: .pull,
            exercises: Array(Exercise.sampleExercises.suffix(2)),
            scheduledDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            difficulty: .advanced,
            description: "Target your back and pulling muscles"
        )
    ]
} 