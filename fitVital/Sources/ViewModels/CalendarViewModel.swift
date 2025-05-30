//
//  CalendarViewModel.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI
import EventKit

/// ViewModel for calendar integration and workout scheduling
@MainActor
@Observable
final class CalendarViewModel {
    
    // MARK: - Published Properties
    
    /// Current calendar view mode
    var viewMode: CalendarViewMode = .month
    
    /// Currently selected date
    var selectedDate: Date = Date()
    
    /// Calendar workouts for the displayed period
    var workouts: [Workout] = []
    
    /// Busy time blocks from calendar
    var busyBlocks: [DateInterval] = []
    
    /// Loading state for async operations
    var isLoading = false
    
    /// Error message for UI display
    var errorMessage: String?
    
    /// Whether calendar access is granted
    var calendarPermissionGranted = false
    
    /// Whether showing permission request
    var showingPermissionRequest = false
    
    /// Currently displayed month/week
    var displayedPeriod: Date = Date()
    
    /// Selected workout for detail view
    var selectedWorkout: Workout?
    
    /// Whether showing workout detail
    var showingWorkoutDetail = false
    
    // MARK: - Computed Properties
    
    /// Calendar days for current view
    var calendarDays: [CalendarDay] {
        switch viewMode {
        case .month:
            return generateMonthDays(for: displayedPeriod)
        case .week:
            return generateWeekDays(for: displayedPeriod)
        }
    }
    
    /// Display title for current period
    var periodTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .week:
            formatter.dateFormat = "MMM d"
            let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: displayedPeriod.startOfWeek) ?? displayedPeriod
            return "\(formatter.string(from: displayedPeriod.startOfWeek)) - \(formatter.string(from: weekEnd))"
        }
        return formatter.string(from: displayedPeriod)
    }
    
    /// Whether auto-schedule is available
    var canAutoSchedule: Bool {
        calendarPermissionGranted && !workouts.isEmpty
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
    
    /// Load calendar data for current period
    @Sendable func loadCalendarData() async {
        isLoading = true
        errorMessage = nil
        
        await checkCalendarPermission()
        
        do {
            // Load workouts for displayed period
            let (startDate, endDate) = getPeriodRange(for: displayedPeriod)
            workouts = try await persistenceController.fetchWorkouts(from: startDate, to: endDate)
            
            // Load busy blocks if permission granted
            if calendarPermissionGranted {
                busyBlocks = try await calendarService.fetchBusyBlocks(start: startDate, end: endDate)
            }
            
        } catch {
            errorMessage = "Failed to load calendar data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Request calendar permissions
    @Sendable func requestCalendarPermission() async {
        do {
            calendarPermissionGranted = try await calendarService.requestPermissions()
            if calendarPermissionGranted {
                await loadCalendarData()
            }
        } catch {
            errorMessage = "Calendar permission denied"
        }
        showingPermissionRequest = false
    }
    
    /// Switch calendar view mode
    @Sendable func switchViewMode(to mode: CalendarViewMode) async {
        viewMode = mode
        await loadCalendarData()
    }
    
    /// Navigate to previous period
    @Sendable func previousPeriod() async {
        let calendar = Calendar.current
        switch viewMode {
        case .month:
            displayedPeriod = calendar.date(byAdding: .month, value: -1, to: displayedPeriod) ?? displayedPeriod
        case .week:
            displayedPeriod = calendar.date(byAdding: .weekOfYear, value: -1, to: displayedPeriod) ?? displayedPeriod
        }
        await loadCalendarData()
    }
    
    /// Navigate to next period
    @Sendable func nextPeriod() async {
        let calendar = Calendar.current
        switch viewMode {
        case .month:
            displayedPeriod = calendar.date(byAdding: .month, value: 1, to: displayedPeriod) ?? displayedPeriod
        case .week:
            displayedPeriod = calendar.date(byAdding: .weekOfYear, value: 1, to: displayedPeriod) ?? displayedPeriod
        }
        await loadCalendarData()
    }
    
    /// Go to today
    @Sendable func goToToday() async {
        displayedPeriod = Date()
        selectedDate = Date()
        await loadCalendarData()
    }
    
    /// Select specific date
    @Sendable func selectDate(_ date: Date) async {
        selectedDate = date
        
        // Find workout for selected date
        selectedWorkout = workouts.first { workout in
            Calendar.current.isDate(workout.scheduledDate, inSameDayAs: date)
        }
        
        if selectedWorkout != nil {
            showingWorkoutDetail = true
        }
    }
    
    /// Auto-schedule this week's workouts
    @Sendable func autoScheduleWeek() async {
        guard calendarPermissionGranted else {
            showingPermissionRequest = true
            return
        }
        
        isLoading = true
        
        do {
            // Get current week's workouts
            let weekStart = selectedDate.startOfWeek
            let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            let weekWorkouts = workouts.filter { workout in
                workout.scheduledDate >= weekStart && workout.scheduledDate < weekEnd
            }
            
            guard !weekWorkouts.isEmpty else {
                errorMessage = "No workouts to schedule this week"
                isLoading = false
                return
            }
            
            // Get busy blocks for the week
            let weekBusyBlocks = try await calendarService.fetchBusyBlocks(start: weekStart, end: weekEnd)
            
            // Auto-schedule workouts
            let rescheduledWorkouts = await calendarService.autoSchedule(workouts: weekWorkouts, busy: weekBusyBlocks)
            
            // Update workouts in persistence
            for workout in rescheduledWorkouts {
                try await persistenceController.updateWorkoutCompletion(workout)
            }
            
            // Reload calendar data
            await loadCalendarData()
            
        } catch {
            errorMessage = "Failed to auto-schedule: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Check if date has conflicts
    func hasConflicts(for date: Date) -> Bool {
        return busyBlocks.contains { busyBlock in
            let dayStart = Calendar.current.startOfDay(for: date)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayInterval = DateInterval(start: dayStart, end: dayEnd)
            return busyBlock.intersects(dayInterval)
        }
    }
    
    /// Get workout for specific date
    func workout(for date: Date) -> Workout? {
        return workouts.first { workout in
            Calendar.current.isDate(workout.scheduledDate, inSameDayAs: date)
        }
    }
    
    // MARK: - Private Methods
    
    /// Check calendar permission status
    private func checkCalendarPermission() async {
        calendarPermissionGranted = await calendarService.getAuthorizationStatus() == .authorized
    }
    
    /// Get date range for current period
    private func getPeriodRange(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        
        switch viewMode {
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
            return (startOfMonth, endOfMonth)
        case .week:
            let startOfWeek = date.startOfWeek
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? startOfWeek
            return (startOfWeek, endOfWeek)
        }
    }
    
    /// Generate calendar days for month view
    private func generateMonthDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        var days: [CalendarDay] = []
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return days }
        
        // Start from the beginning of the week containing the first day of the month
        let startDate = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start ?? monthInterval.start
        
        // Generate 42 days (6 weeks) to fill calendar grid
        for i in 0..<42 {
            guard let dayDate = calendar.date(byAdding: .day, value: i, to: startDate) else { continue }
            
            let isCurrentMonth = calendar.isDate(dayDate, equalTo: date, toGranularity: .month)
            let isToday = calendar.isDateInToday(dayDate)
            let hasWorkout = workout(for: dayDate) != nil
            let hasConflict = hasConflicts(for: dayDate)
            
            let day = CalendarDay(
                date: dayDate,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                hasWorkout: hasWorkout,
                hasConflict: hasConflict,
                workout: workout(for: dayDate)
            )
            
            days.append(day)
        }
        
        return days
    }
    
    /// Generate calendar days for week view
    private func generateWeekDays(for date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        var days: [CalendarDay] = []
        
        let startOfWeek = date.startOfWeek
        
        for i in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) else { continue }
            
            let isToday = calendar.isDateInToday(dayDate)
            let hasWorkout = workout(for: dayDate) != nil
            let hasConflict = hasConflicts(for: dayDate)
            
            let day = CalendarDay(
                date: dayDate,
                isCurrentMonth: true,
                isToday: isToday,
                hasWorkout: hasWorkout,
                hasConflict: hasConflict,
                workout: workout(for: dayDate)
            )
            
            days.append(day)
        }
        
        return days
    }
}

// MARK: - Supporting Data Models

/// Calendar view mode
enum CalendarViewMode: String, CaseIterable {
    case month = "month"
    case week = "week"
    
    var displayName: String {
        switch self {
        case .month: return "Month"
        case .week: return "Week"
        }
    }
    
    var icon: String {
        switch self {
        case .month: return "calendar"
        case .week: return "calendar.day.timeline.leading"
        }
    }
}

/// Calendar day data model
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let hasWorkout: Bool
    let hasConflict: Bool
    let workout: Workout?
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var weekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - DateInterval Extension

private extension DateInterval {
    func intersects(_ other: DateInterval) -> Bool {
        return start < other.end && end > other.start
    }
} 