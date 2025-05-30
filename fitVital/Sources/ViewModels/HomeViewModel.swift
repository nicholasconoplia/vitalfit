//
//  HomeViewModel.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI

/// ViewModel for the home screen with mood-based workout adaptation
@MainActor
@Observable
final class HomeViewModel {
    
    // MARK: - Published Properties
    
    /// Current user profile
    var userProfile: UserProfile?
    
    /// Today's scheduled workout
    var todayWorkout: Workout?
    
    /// User's current mood state
    var mood: MoodState = .meh
    
    /// Loading state for async operations
    var isLoading = false
    
    /// Error message for UI display
    var errorMessage: String?
    
    /// Whether workout is currently in progress
    var isWorkoutInProgress = false
    
    /// Workout completion statistics
    var workoutStats: WorkoutStats?
    
    // MARK: - Computed Properties
    
    /// User's display name with fallback
    var userName: String {
        userProfile?.name ?? "Friend"
    }
    
    /// Greeting based on time of day
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hello"
        }
    }
    
    /// Whether today's workout can be started
    var canStartWorkout: Bool {
        guard let workout = todayWorkout else { return false }
        return !workout.isCompleted && !isWorkoutInProgress
    }
    
    /// Motivational message based on stats and mood
    var motivationalMessage: String {
        guard let stats = workoutStats else {
            return "Ready to start your fitness journey?"
        }
        
        if stats.currentStreak > 0 {
            switch mood {
            case .energized:
                return "You're on fire! \(stats.currentStreak) day streak 🔥"
            case .meh:
                return "Keep the momentum going! \(stats.currentStreak) days strong"
            case .tired:
                return "Every workout counts. \(stats.currentStreak) days and counting"
            }
        } else {
            switch mood {
            case .energized:
                return "Let's get that energy flowing!"
            case .meh:
                return "A little movement goes a long way"
            case .tired:
                return "Even 10 minutes will make you feel better"
            }
        }
    }
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let notificationService: NotificationServiceProtocol
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared,
         notificationService: NotificationServiceProtocol = NotificationService.shared) {
        self.persistenceController = persistenceController
        self.notificationService = notificationService
    }
    
    // MARK: - Public Methods
    
    /// Load initial data for home screen
    @Sendable func loadHomeData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load user profile
            userProfile = try await persistenceController.fetchUserProfile()
            
            // Load today's workout
            todayWorkout = try await persistenceController.fetchTodayWorkout()
            
            // Load workout stats
            workoutStats = try await persistenceController.fetchWorkoutStats()
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Start today's workout
    @Sendable func startWorkout() async {
        guard let workout = todayWorkout else { return }
        
        isWorkoutInProgress = true
        
        // Adjust workout based on current mood
        let adjustedWorkout = workout.adjustedForMood(mood)
        
        // Update workout in persistence
        do {
            try await persistenceController.updateWorkoutCompletion(adjustedWorkout)
            todayWorkout = adjustedWorkout
        } catch {
            errorMessage = "Failed to start workout: \(error.localizedDescription)"
            isWorkoutInProgress = false
        }
    }
    
    /// Complete workout with feedback
    @Sendable func completeWorkout(rating: Int, notes: String? = nil) async {
        guard var workout = todayWorkout else { return }
        
        // Update workout completion
        workout.isCompleted = true
        workout.completedAt = Date()
        workout.userRating = rating
        workout.userNotes = notes
        
        do {
            try await persistenceController.updateWorkoutCompletion(workout)
            todayWorkout = workout
            
            // Schedule milestone notification if applicable
            if let stats = workoutStats {
                let newTotal = stats.totalWorkouts + 1
                await notificationService.scheduleMilestone(workoutCount: newTotal)
            }
            
            // Reload stats
            workoutStats = try await persistenceController.fetchWorkoutStats()
            
        } catch {
            errorMessage = "Failed to complete workout: \(error.localizedDescription)"
        }
        
        isWorkoutInProgress = false
    }
    
    /// Update mood and adjust workout if needed
    @Sendable func updateMood(_ newMood: MoodState) async {
        mood = newMood
        
        // Adjust today's workout based on new mood
        if let workout = todayWorkout, !workout.isCompleted {
            let adjustedWorkout = workout.adjustedForMood(mood)
            todayWorkout = adjustedWorkout
        }
    }
    
    /// Reschedule today's workout
    @Sendable func rescheduleWorkout() async {
        guard let workout = todayWorkout else { return }
        
        // Move workout to later today or tomorrow
        let calendar = Calendar.current
        let newDate = calendar.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
        
        var rescheduledWorkout = workout
        rescheduledWorkout = Workout(
            id: workout.id,
            title: workout.title,
            focus: workout.focus,
            exercises: workout.exercises,
            scheduledDate: newDate,
            estimatedDuration: workout.estimatedDuration,
            difficulty: workout.difficulty,
            isCompleted: workout.isCompleted,
            completedAt: workout.completedAt,
            equipment: workout.equipment,
            description: workout.description,
            phases: workout.phases,
            createdAt: workout.createdAt,
            userRating: workout.userRating,
            userNotes: workout.userNotes
        )
        
        do {
            try await persistenceController.updateWorkoutCompletion(rescheduledWorkout)
            todayWorkout = rescheduledWorkout
            
            // Schedule new notifications
            await notificationService.scheduleAllNotifications(for: rescheduledWorkout)
            
        } catch {
            errorMessage = "Failed to reschedule workout: \(error.localizedDescription)"
        }
    }
    
    /// Skip today's workout
    @Sendable func skipWorkout(reason: String? = nil) async {
        guard var workout = todayWorkout else { return }
        
        workout.userNotes = reason ?? "Workout skipped"
        
        do {
            try await persistenceController.updateWorkoutCompletion(workout)
            todayWorkout = nil // Clear today's workout
            
        } catch {
            errorMessage = "Failed to skip workout: \(error.localizedDescription)"
        }
    }
    
    /// Refresh all data
    @Sendable func refresh() async {
        await loadHomeData()
    }
}

// MARK: - Navigation Coordination

extension HomeViewModel {
    /// Navigate to workout detail
    func navigateToWorkout() -> Workout? {
        return todayWorkout
    }
    
    /// Navigate to progress view
    func navigateToProgress() -> WorkoutStats? {
        return workoutStats
    }
} 