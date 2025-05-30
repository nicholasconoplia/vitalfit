//
//  PersistenceController.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import CoreData

/// Core Data persistence controller for offline-first data storage
@MainActor
final class PersistenceController: ObservableObject {
    
    /// Shared instance for app-wide use
    static let shared = PersistenceController()
    
    /// Preview instance for SwiftUI previews with sample data
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        controller.createSampleData(in: context)
        
        return controller
    }()
    
    /// Core Data persistent container
    let container: NSPersistentContainer
    
    /// View context for UI operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// Background context for heavy operations
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CoreDataModels")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure persistent store
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                               forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                               forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In a real app, you would handle this error appropriately
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        
        // Configure view context
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure background context merge policy
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// MARK: - Save Operations

extension PersistenceController {
    /// Save view context with error handling
    func save() async throws {
        try await save(context: viewContext)
    }
    
    /// Save specific context with error handling
    func save(context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }
        
        do {
            try await context.perform {
                try context.save()
            }
        } catch {
            throw PersistenceError.saveFailed(error)
        }
    }
    
    /// Save on background context
    func saveInBackground(_ operation: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        try await backgroundContext.perform {
            try operation(self.backgroundContext)
            if self.backgroundContext.hasChanges {
                try self.backgroundContext.save()
            }
        }
    }
}

// MARK: - User Profile Operations

extension PersistenceController {
    /// Save user profile
    func saveUserProfile(_ profile: UserProfile) async throws {
        try await saveInBackground { context in
            let entity = CDUserProfile(context: context)
            entity.update(from: profile)
        }
    }
    
    /// Fetch user profile
    func fetchUserProfile() async throws -> UserProfile? {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.fetchLimit = 1
        
        return try await viewContext.perform {
            let results = try self.viewContext.fetch(request)
            return results.first?.toUserProfile()
        }
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await saveInBackground { context in
            let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)
            
            if let existingProfile = try context.fetch(request).first {
                existingProfile.update(from: profile)
            } else {
                let newProfile = CDUserProfile(context: context)
                newProfile.update(from: profile)
            }
        }
    }
}

// MARK: - Workout Operations

extension PersistenceController {
    /// Save workout
    func saveWorkout(_ workout: Workout) async throws {
        try await saveInBackground { context in
            let entity = CDWorkout(context: context)
            entity.update(from: workout)
        }
    }
    
    /// Fetch workouts for date range
    func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [Workout] {
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "scheduledDate >= %@ AND scheduledDate <= %@", 
                                       startDate as CVarArg, endDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDWorkout.scheduledDate, ascending: true)]
        
        return try await viewContext.perform {
            let results = try self.viewContext.fetch(request)
            return results.compactMap { $0.toWorkout() }
        }
    }
    
    /// Fetch today's workout
    func fetchTodayWorkout() async throws -> Workout? {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let workouts = try await fetchWorkouts(from: startOfDay, to: endOfDay)
        return workouts.first
    }
    
    /// Update workout completion
    func updateWorkoutCompletion(_ workout: Workout) async throws {
        try await saveInBackground { context in
            let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", workout.id as CVarArg)
            
            if let existingWorkout = try context.fetch(request).first {
                existingWorkout.update(from: workout)
            }
        }
    }
}

// MARK: - Exercise Progress Operations

extension PersistenceController {
    /// Save exercise progress
    func saveExerciseProgress(_ progress: ExerciseProgress) async throws {
        try await saveInBackground { context in
            let entity = CDExerciseProgress(context: context)
            entity.update(from: progress)
        }
    }
    
    /// Fetch exercise progress for specific exercise
    func fetchExerciseProgress(for exerciseId: UUID) async throws -> [ExerciseProgress] {
        let request: NSFetchRequest<CDExerciseProgress> = CDExerciseProgress.fetchRequest()
        request.predicate = NSPredicate(format: "exerciseId == %@", exerciseId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDExerciseProgress.completedAt, ascending: false)]
        
        return try await viewContext.perform {
            let results = try self.viewContext.fetch(request)
            return results.compactMap { $0.toExerciseProgress() }
        }
    }
}

// MARK: - Statistics Operations

extension PersistenceController {
    /// Fetch workout completion statistics
    func fetchWorkoutStats() async throws -> WorkoutStats {
        let request: NSFetchRequest<CDWorkout> = CDWorkout.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        
        return try await viewContext.perform {
            let completedWorkouts = try self.viewContext.fetch(request)
            let totalWorkouts = completedWorkouts.count
            
            // Calculate streak
            let currentStreak = self.calculateCurrentStreak(from: completedWorkouts)
            
            // Calculate total time
            let totalTime = completedWorkouts.reduce(0) { sum, workout in
                sum + (workout.completedAt?.timeIntervalSince(workout.createdAt) ?? 0)
            }
            
            return WorkoutStats(
                totalWorkouts: totalWorkouts,
                currentStreak: currentStreak,
                totalTimeSpent: totalTime,
                averageWorkoutTime: totalWorkouts > 0 ? totalTime / Double(totalWorkouts) : 0
            )
        }
    }
    
    /// Calculate current workout streak
    private func calculateCurrentStreak(from workouts: [CDWorkout]) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        var currentDate = today
        
        let workoutDates = Set(workouts.compactMap { workout in
            guard let completedDate = workout.completedAt else { return nil }
            return calendar.startOfDay(for: completedDate)
        })
        
        // Count consecutive days from today backwards
        while workoutDates.contains(calendar.startOfDay(for: currentDate)) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }
        
        return streak
    }
}

// MARK: - Sample Data Creation

extension PersistenceController {
    /// Create sample data for previews and testing
    func createSampleData(in context: NSManagedObjectContext) {
        // Sample user profile
        let userProfile = CDUserProfile(context: context)
        userProfile.id = UUID()
        userProfile.name = "Sarah Johnson"
        userProfile.fitnessGoal = FitnessGoal.buildStrength.rawValue
        userProfile.weeklyFrequency = 3
        userProfile.sessionDuration = 2700 // 45 minutes
        userProfile.calendarSynced = true
        userProfile.createdAt = Date()
        userProfile.updatedAt = Date()
        
        // Sample workouts
        let sampleWorkouts = Workout.sampleWorkouts
        for workout in sampleWorkouts {
            let cdWorkout = CDWorkout(context: context)
            cdWorkout.update(from: workout)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to create sample data: \(error)")
        }
    }
}

// MARK: - Data Models

/// Workout statistics data model
struct WorkoutStats: Codable, Sendable {
    let totalWorkouts: Int
    let currentStreak: Int
    let totalTimeSpent: TimeInterval
    let averageWorkoutTime: TimeInterval
    
    var formattedTotalTime: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = (Int(totalTimeSpent) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var formattedAverageTime: String {
        let minutes = Int(averageWorkoutTime) / 60
        return "\(minutes) min"
    }
}

// MARK: - Errors

/// Persistence-related errors
enum PersistenceError: Error, LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case objectNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .objectNotFound:
            return "Requested object was not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
} 