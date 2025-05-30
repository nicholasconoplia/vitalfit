//
//  CalendarService.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import EventKit

// MARK: - Protocol Definition

/// Protocol for calendar integration and auto-scheduling
protocol CalendarServiceProtocol: Sendable {
    /// Request calendar access permissions
    @Sendable func requestPermissions() async throws -> Bool
    
    /// Fetch busy time blocks from user's calendar
    @Sendable func fetchBusyBlocks(start: Date, end: Date) async throws -> [DateInterval]
    
    /// Auto-schedule workouts around busy blocks
    @Sendable func autoSchedule(workouts: [Workout], busy: [DateInterval]) -> [Workout]
    
    /// Check if a time slot is available
    @Sendable func isTimeSlotAvailable(date: Date, duration: TimeInterval, busyBlocks: [DateInterval]) -> Bool
    
    /// Get suggested workout times based on user preferences
    @Sendable func getSuggestedTimes(for profile: UserProfile, date: Date, busyBlocks: [DateInterval]) -> [Date]
}

// MARK: - Implementation

/// Actor-based calendar service for thread-safe calendar operations
actor CalendarService: CalendarServiceProtocol {
    
    /// Shared instance for app-wide use
    static let shared = CalendarService()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    /// Request calendar access permissions
    @Sendable func requestPermissions() async throws -> Bool {
        if #available(iOS 17.0, *) {
            let status = try await eventStore.requestFullAccessToEvents()
            return status == .granted
        } else {
            // Fallback for older iOS versions
            return try await withCheckedThrowingContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    /// Fetch busy time blocks from user's calendar
    @Sendable func fetchBusyBlocks(start: Date, end: Date) async throws -> [DateInterval] {
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        return events.compactMap { event in
            guard !event.isAllDay else { return nil }
            return DateInterval(start: event.startDate, end: event.endDate)
        }
    }
    
    /// Auto-schedule workouts around busy blocks
    @Sendable func autoSchedule(workouts: [Workout], busy: [DateInterval]) -> [Workout] {
        var scheduledWorkouts: [Workout] = []
        let calendar = Calendar.current
        
        for workout in workouts {
            let targetDate = workout.scheduledDate
            let dayStart = calendar.startOfDay(for: targetDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            // Get busy blocks for this day
            let dayBusyBlocks = busy.filter { busyBlock in
                busyBlock.intersects(DateInterval(start: dayStart, end: dayEnd))
            }
            
            // Try to find the best time slot
            if let bestTime = findBestTimeSlot(
                for: workout,
                on: targetDate,
                busyBlocks: dayBusyBlocks
            ) {
                var updatedWorkout = workout
                updatedWorkout = Workout(
                    id: workout.id,
                    title: workout.title,
                    focus: workout.focus,
                    exercises: workout.exercises,
                    scheduledDate: bestTime,
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
                scheduledWorkouts.append(updatedWorkout)
            } else {
                // If no time slot found, keep original time
                scheduledWorkouts.append(workout)
            }
        }
        
        return scheduledWorkouts
    }
    
    /// Check if a time slot is available
    @Sendable func isTimeSlotAvailable(date: Date, duration: TimeInterval, busyBlocks: [DateInterval]) -> Bool {
        let workoutInterval = DateInterval(start: date, duration: duration)
        
        for busyBlock in busyBlocks {
            if workoutInterval.intersects(busyBlock) {
                return false
            }
        }
        
        return true
    }
    
    /// Get suggested workout times based on user preferences
    @Sendable func getSuggestedTimes(for profile: UserProfile, date: Date, busyBlocks: [DateInterval]) -> [Date] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        var suggestedTimes: [Date] = []
        
        for timeOfDay in profile.preferredTimes {
            let timeSlots = getTimeSlots(for: timeOfDay, date: dayStart)
            
            for timeSlot in timeSlots {
                if isTimeSlotAvailable(
                    date: timeSlot,
                    duration: profile.sessionDuration,
                    busyBlocks: busyBlocks
                ) {
                    suggestedTimes.append(timeSlot)
                }
            }
        }
        
        return suggestedTimes
    }
    
    // MARK: - Private Helper Methods
    
    /// Find the best available time slot for a workout
    private func findBestTimeSlot(for workout: Workout, on date: Date, busyBlocks: [DateInterval]) -> Date? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Define time slots throughout the day (every 30 minutes from 6 AM to 10 PM)
        let startHour = 6
        let endHour = 22
        let intervalMinutes = 30
        
        for hour in startHour..<endHour {
            for minute in stride(from: 0, to: 60, by: intervalMinutes) {
                guard let timeSlot = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayStart) else {
                    continue
                }
                
                if isTimeSlotAvailable(
                    date: timeSlot,
                    duration: workout.estimatedDuration,
                    busyBlocks: busyBlocks
                ) {
                    return timeSlot
                }
            }
        }
        
        return nil
    }
    
    /// Get time slots for a specific time of day
    private func getTimeSlots(for timeOfDay: TimeOfDay, date: Date) -> [Date] {
        let calendar = Calendar.current
        var timeSlots: [Date] = []
        
        let (startHour, endHour) = getHourRange(for: timeOfDay)
        
        for hour in startHour..<endHour {
            for minute in [0, 30] {
                if let timeSlot = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) {
                    timeSlots.append(timeSlot)
                }
            }
        }
        
        return timeSlots
    }
    
    /// Get hour range for time of day
    private func getHourRange(for timeOfDay: TimeOfDay) -> (Int, Int) {
        switch timeOfDay {
        case .morning:
            return (6, 11)   // 6:00 AM - 11:00 AM
        case .afternoon:
            return (11, 17)  // 11:00 AM - 5:00 PM
        case .evening:
            return (17, 22)  // 5:00 PM - 10:00 PM
        }
    }
}

// MARK: - Calendar Extensions

extension CalendarService {
    /// Get weekly schedule with auto-scheduling
    @Sendable func getWeeklySchedule(for profile: UserProfile, startDate: Date) async throws -> [Workout] {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: startDate) else {
            return []
        }
        
        // Fetch busy blocks for the week
        let busyBlocks = try await fetchBusyBlocks(start: startDate, end: weekEnd)
        
        // Generate sample workouts for the week
        let sampleWorkouts = generateWeeklyWorkouts(for: profile, startDate: startDate)
        
        // Auto-schedule around busy blocks
        return autoSchedule(workouts: sampleWorkouts, busy: busyBlocks)
    }
    
    /// Generate weekly workouts based on user profile
    private func generateWeeklyWorkouts(for profile: UserProfile, startDate: Date) -> [Workout] {
        let calendar = Calendar.current
        var workouts: [Workout] = []
        let focusTypes: [FocusType] = [.push, .pull, .legs, .cardio, .mobility]
        
        for day in 0..<profile.weeklyFrequency {
            guard let workoutDate = calendar.date(byAdding: .day, value: day, to: startDate) else {
                continue
            }
            
            let focus = focusTypes[day % focusTypes.count]
            let workout = Workout(
                title: "\(focus.displayName) Workout",
                focus: focus,
                exercises: Exercise.sampleExercises.filter { $0.focus == focus },
                scheduledDate: workoutDate,
                estimatedDuration: profile.sessionDuration,
                difficulty: .beginner
            )
            
            workouts.append(workout)
        }
        
        return workouts
    }
    
    /// Check if user has busy schedule (for difficulty adjustment)
    @Sendable func hasBusySchedule(for date: Date) async throws -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        let busyBlocks = try await fetchBusyBlocks(start: dayStart, end: dayEnd)
        
        // Consider busy if more than 6 hours of events in a day
        let totalBusyTime = busyBlocks.reduce(0) { $0 + $1.duration }
        return totalBusyTime > 6 * 60 * 60 // 6 hours
    }
}

// MARK: - Errors

/// Calendar-related errors
enum CalendarError: Error, LocalizedError, Sendable {
    case permissionDenied
    case fetchFailed
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar access was denied"
        case .fetchFailed:
            return "Failed to fetch calendar events"
        case .invalidDateRange:
            return "Invalid date range provided"
        }
    }
}

// MARK: - DateInterval Extension

private extension DateInterval {
    /// Check if two date intervals intersect
    func intersects(_ other: DateInterval) -> Bool {
        return start < other.end && end > other.start
    }
} 