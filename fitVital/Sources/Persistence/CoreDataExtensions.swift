//
//  CoreDataExtensions.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import CoreData

// MARK: - CDUserProfile Extensions

@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    
}

extension CDUserProfile {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var fitnessGoal: String?
    @NSManaged public var weeklyFrequency: Int16
    @NSManaged public var sessionDuration: Double
    @NSManaged public var calendarSynced: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    /// Convert Core Data entity to Swift model
    func toUserProfile() -> UserProfile? {
        guard let id = id,
              let name = name,
              let fitnessGoalString = fitnessGoal,
              let fitnessGoal = FitnessGoal(rawValue: fitnessGoalString),
              let createdAt = createdAt,
              let updatedAt = updatedAt else {
            return nil
        }
        
        return UserProfile(
            id: id,
            name: name,
            fitnessGoal: fitnessGoal,
            weeklyFrequency: Int(weeklyFrequency),
            sessionDuration: sessionDuration,
            equipmentAccess: [.bodyweight], // Default for now
            dislikedExercises: [],
            physicalLimitations: [],
            preferredTimes: [.morning],
            calendarSynced: calendarSynced,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Update Core Data entity from Swift model
    func update(from profile: UserProfile) {
        self.id = profile.id
        self.name = profile.name
        self.fitnessGoal = profile.fitnessGoal.rawValue
        self.weeklyFrequency = Int16(profile.weeklyFrequency)
        self.sessionDuration = profile.sessionDuration
        self.calendarSynced = profile.calendarSynced
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
    }
}

// MARK: - CDWorkout Extensions

@objc(CDWorkout)
public class CDWorkout: NSManagedObject {
    
}

extension CDWorkout {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkout> {
        return NSFetchRequest<CDWorkout>(entityName: "CDWorkout")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var focus: String?
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var estimatedDuration: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedAt: Date?
    @NSManaged public var createdAt: Date?
    
    /// Convert Core Data entity to Swift model
    func toWorkout() -> Workout? {
        guard let id = id,
              let title = title,
              let focusString = focus,
              let focusType = FocusType(rawValue: focusString),
              let scheduledDate = scheduledDate,
              let createdAt = createdAt else {
            return nil
        }
        
        return Workout(
            id: id,
            title: title,
            focus: focusType,
            exercises: Exercise.sampleExercises, // Default exercises for now
            scheduledDate: scheduledDate,
            estimatedDuration: estimatedDuration,
            difficulty: .beginner,
            isCompleted: isCompleted,
            completedAt: completedAt,
            equipment: [.bodyweight],
            description: nil,
            phases: [],
            createdAt: createdAt
        )
    }
    
    /// Update Core Data entity from Swift model
    func update(from workout: Workout) {
        self.id = workout.id
        self.title = workout.title
        self.focus = workout.focus.rawValue
        self.scheduledDate = workout.scheduledDate
        self.estimatedDuration = workout.estimatedDuration
        self.isCompleted = workout.isCompleted
        self.completedAt = workout.completedAt
        self.createdAt = workout.createdAt
    }
}

// MARK: - CDExerciseProgress Extensions

@objc(CDExerciseProgress)
public class CDExerciseProgress: NSManagedObject {
    
}

extension CDExerciseProgress {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDExerciseProgress> {
        return NSFetchRequest<CDExerciseProgress>(entityName: "CDExerciseProgress")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var exerciseId: UUID?
    @NSManaged public var completedAt: Date?
    @NSManaged public var repsCompleted: Int16
    @NSManaged public var durationCompleted: Double
    @NSManaged public var difficultyRating: Int16
    
    /// Convert Core Data entity to Swift model
    func toExerciseProgress() -> ExerciseProgress? {
        guard let id = id,
              let exerciseId = exerciseId,
              let completedAt = completedAt else {
            return nil
        }
        
        return ExerciseProgress(
            id: id,
            exerciseId: exerciseId,
            completedAt: completedAt,
            repsCompleted: repsCompleted > 0 ? Int(repsCompleted) : nil,
            durationCompleted: durationCompleted > 0 ? durationCompleted : nil,
            difficultyRating: Int(difficultyRating)
        )
    }
    
    /// Update Core Data entity from Swift model
    func update(from progress: ExerciseProgress) {
        self.id = progress.id
        self.exerciseId = progress.exerciseId
        self.completedAt = progress.completedAt
        self.repsCompleted = Int16(progress.repsCompleted ?? 0)
        self.durationCompleted = progress.durationCompleted ?? 0
        self.difficultyRating = Int16(progress.difficultyRating)
    }
} 