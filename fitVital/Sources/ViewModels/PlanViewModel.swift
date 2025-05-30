//
//  PlanViewModel.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI

/// ViewModel for weekly workout planning and customization
@MainActor
@Observable
final class PlanViewModel {
    
    // MARK: - Published Properties
    
    /// Weekly workouts (Mon-Sun)
    var weeklyWorkouts: [Workout] = []
    
    /// Currently selected workout split type
    var selectedSplit: WorkoutSplit = .pushPullLegs
    
    /// Loading state for async operations
    var isLoading = false
    
    /// Error message for UI display
    var errorMessage: String?
    
    /// User profile for plan customization
    var userProfile: UserProfile?
    
    /// Currently selected week start date
    var currentWeekStart: Date = Date().startOfWeek
    
    /// Whether plan is being customized
    var isCustomizing = false
    
    /// Selected workout for editing
    var selectedWorkout: Workout?
    
    // MARK: - Computed Properties
    
    /// Days of the week with corresponding workouts
    var dailyPlan: [(day: String, workout: Workout?)] {
        let calendar = Calendar.current
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        return weekdays.enumerated().map { index, day in
            let date = calendar.date(byAdding: .day, value: index, to: currentWeekStart) ?? currentWeekStart
            let workout = weeklyWorkouts.first { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
            return (day: day, workout: workout)
        }
    }
    
    /// Week display string
    var weekDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) ?? currentWeekStart
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endDate))"
    }
    
    /// Available workout splits
    var availableSplits: [WorkoutSplit] {
        return WorkoutSplit.allCases
    }
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let calendarService: CalendarServiceProtocol
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared,
         calendarService: CalendarServiceProtocol = CalendarService.shared) {
        self.persistenceController = persistenceController
        self.calendarService = calendarService
    }
    
    // MARK: - Public Methods
    
    /// Load weekly plan data
    @Sendable func loadWeeklyPlan() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load user profile
            userProfile = try await persistenceController.fetchUserProfile()
            
            // Load workouts for current week
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
            weeklyWorkouts = try await persistenceController.fetchWorkouts(from: currentWeekStart, to: weekEnd)
            
            // Generate plan if no workouts exist
            if weeklyWorkouts.isEmpty {
                await generateWeeklyPlan()
            }
            
        } catch {
            errorMessage = "Failed to load plan: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Generate weekly workout plan based on user preferences
    @Sendable func generateWeeklyPlan() async {
        guard let profile = userProfile else { return }
        
        isLoading = true
        
        do {
            // Generate workouts based on selected split
            let newWorkouts = generateWorkouts(for: selectedSplit, profile: profile)
            
            // Save workouts to persistence
            for workout in newWorkouts {
                try await persistenceController.saveWorkout(workout)
            }
            
            weeklyWorkouts = newWorkouts
            
        } catch {
            errorMessage = "Failed to generate plan: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Switch to different workout split
    @Sendable func changeSplit(to newSplit: WorkoutSplit) async {
        selectedSplit = newSplit
        await generateWeeklyPlan()
    }
    
    /// Move workout to different day
    @Sendable func moveWorkout(_ workout: Workout, to dayIndex: Int) async {
        let calendar = Calendar.current
        guard let newDate = calendar.date(byAdding: .day, value: dayIndex, to: currentWeekStart) else { return }
        
        // Create updated workout with new date
        let updatedWorkout = Workout(
            id: workout.id,
            title: workout.title,
            focus: workout.focus,
            exercises: workout.exercises,
            scheduledDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: newDate) ?? newDate,
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
            try await persistenceController.updateWorkoutCompletion(updatedWorkout)
            
            // Update local array
            if let index = weeklyWorkouts.firstIndex(where: { $0.id == workout.id }) {
                weeklyWorkouts[index] = updatedWorkout
            }
            
        } catch {
            errorMessage = "Failed to move workout: \(error.localizedDescription)"
        }
    }
    
    /// Customize specific workout
    @Sendable func customizeWorkout(_ workout: Workout) async {
        selectedWorkout = workout
        isCustomizing = true
    }
    
    /// Auto-schedule workouts around calendar events
    @Sendable func autoScheduleWeek() async {
        guard !weeklyWorkouts.isEmpty else { return }
        
        isLoading = true
        
        do {
            // Fetch busy blocks from calendar
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
            let busyBlocks = try await calendarService.fetchBusyBlocks(start: currentWeekStart, end: weekEnd)
            
            // Auto-schedule workouts
            let rescheduledWorkouts = await calendarService.autoSchedule(workouts: weeklyWorkouts, busy: busyBlocks)
            
            // Update workouts in persistence
            for workout in rescheduledWorkouts {
                try await persistenceController.updateWorkoutCompletion(workout)
            }
            
            weeklyWorkouts = rescheduledWorkouts
            
        } catch {
            errorMessage = "Failed to auto-schedule: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Navigate to previous week
    @Sendable func previousWeek() async {
        currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) ?? currentWeekStart
        await loadWeeklyPlan()
    }
    
    /// Navigate to next week
    @Sendable func nextWeek() async {
        currentWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
        await loadWeeklyPlan()
    }
    
    /// Reset to current week
    @Sendable func goToCurrentWeek() async {
        currentWeekStart = Date().startOfWeek
        await loadWeeklyPlan()
    }
    
    // MARK: - Private Methods
    
    /// Generate workouts based on split type and user profile
    private func generateWorkouts(for split: WorkoutSplit, profile: UserProfile) -> [Workout] {
        let calendar = Calendar.current
        var workouts: [Workout] = []
        
        let focusSchedule = split.focusSchedule
        let workoutDays = split.recommendedDays(for: profile.weeklyFrequency)
        
        for (dayIndex, focusType) in workoutDays.enumerated() {
            guard let workoutDate = calendar.date(byAdding: .day, value: dayIndex, to: currentWeekStart) else { continue }
            
            // Set workout time based on user preferences
            let preferredHour = profile.preferredTimes.first?.defaultHour ?? 9
            let scheduledDate = calendar.date(bySettingHour: preferredHour, minute: 0, second: 0, of: workoutDate) ?? workoutDate
            
            let workout = Workout(
                title: "\(focusType.displayName) Day",
                focus: focusType,
                exercises: generateExercises(for: focusType, equipment: profile.equipmentAccess),
                scheduledDate: scheduledDate,
                estimatedDuration: profile.sessionDuration,
                difficulty: .beginner,
                description: split.description(for: focusType)
            )
            
            workouts.append(workout)
        }
        
        return workouts
    }
    
    /// Generate exercises for specific focus type
    private func generateExercises(for focus: FocusType, equipment: [EquipmentType]) -> [Exercise] {
        // Filter exercises by focus and available equipment
        let availableExercises = Exercise.sampleExercises.filter { exercise in
            exercise.focus == focus && equipment.contains(exercise.equipment)
        }
        
        // Return 3-5 exercises for the workout
        return Array(availableExercises.prefix(4))
    }
}

// MARK: - Workout Split Definitions

/// Available workout split types
enum WorkoutSplit: String, CaseIterable, Identifiable {
    case pushPullLegs = "pushPullLegs"
    case upperLower = "upperLower"
    case fullBody = "fullBody"
    case circuits = "circuits"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pushPullLegs: return "Push/Pull/Legs"
        case .upperLower: return "Upper/Lower"
        case .fullBody: return "Full Body"
        case .circuits: return "Circuits"
        }
    }
    
    var description: String {
        switch self {
        case .pushPullLegs: return "Separate pushing, pulling, and leg movements"
        case .upperLower: return "Alternate between upper and lower body"
        case .fullBody: return "Work entire body each session"
        case .circuits: return "High-intensity circuit training"
        }
    }
    
    var focusSchedule: [FocusType] {
        switch self {
        case .pushPullLegs:
            return [.push, .pull, .legs, .push, .pull, .legs, .mobility]
        case .upperLower:
            return [.push, .legs, .pull, .legs, .push, .pull, .mobility]
        case .fullBody:
            return [.push, .pull, .legs, .cardio, .mobility, .push, .pull]
        case .circuits:
            return [.cardio, .push, .cardio, .legs, .cardio, .pull, .mobility]
        }
    }
    
    func recommendedDays(for frequency: Int) -> [(Int, FocusType)] {
        let schedule = focusSchedule
        var result: [(Int, FocusType)] = []
        
        // Distribute workouts across the week based on frequency
        let daySpacing = 7 / max(frequency, 1)
        
        for i in 0..<frequency {
            let dayIndex = i * daySpacing
            let focusIndex = i % schedule.count
            result.append((dayIndex, schedule[focusIndex]))
        }
        
        return result
    }
    
    func description(for focus: FocusType) -> String {
        switch (self, focus) {
        case (.pushPullLegs, .push): return "Chest, shoulders, triceps"
        case (.pushPullLegs, .pull): return "Back, biceps, rear delts"
        case (.pushPullLegs, .legs): return "Glutes, quads, hamstrings, calves"
        case (.upperLower, .push): return "Upper body strength"
        case (.upperLower, .legs): return "Lower body power"
        case (.fullBody, _): return "Total body workout"
        case (.circuits, _): return "High-intensity intervals"
        default: return focus.description
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
} 