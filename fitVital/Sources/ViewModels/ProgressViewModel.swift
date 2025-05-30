//
//  ProgressViewModel.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI
import Charts

/// ViewModel for tracking workout progress and statistics
@MainActor
@Observable
final class ProgressViewModel {
    
    // MARK: - Published Properties
    
    /// Weekly completion statistics
    var weeklyStats: [WeeklyStats] = []
    
    /// Monthly progress data
    var monthlyProgress: [MonthlyProgress] = []
    
    /// Current week completion
    var currentWeekCompletion: Double = 0.0
    
    /// Current month completion
    var currentMonthCompletion: Double = 0.0
    
    /// Total workouts completed
    var totalWorkoutsCompleted: Int = 0
    
    /// Current streak (consecutive workout days)
    var currentStreak: Int = 0
    
    /// Longest streak achieved
    var longestStreak: Int = 0
    
    /// Average workout duration
    var averageWorkoutDuration: TimeInterval = 0
    
    /// Favorite workout focus
    var favoriteWorkoutFocus: FocusType?
    
    /// Loading state for async operations
    var isLoading = false
    
    /// Error message for UI display
    var errorMessage: String?
    
    /// Selected time range for charts
    var selectedTimeRange: TimeRange = .month
    
    /// Chart data for selected time range
    var chartData: [ChartDataPoint] = []
    
    /// Export state
    var isExporting = false
    
    /// Export completion message
    var exportMessage: String?
    
    // MARK: - Computed Properties
    
    /// Weekly goal progress (0.0 - 1.0)
    var weeklyGoalProgress: Double {
        // Assuming 3 workouts per week as default goal
        return min(currentWeekCompletion / 3.0, 1.0)
    }
    
    /// Monthly goal progress (0.0 - 1.0)
    var monthlyGoalProgress: Double {
        // Assuming 12 workouts per month as default goal
        return min(currentMonthCompletion / 12.0, 1.0)
    }
    
    /// Formatted average duration
    var formattedAverageDuration: String {
        let minutes = Int(averageWorkoutDuration) / 60
        return "\(minutes) min"
    }
    
    /// Progress insights
    var progressInsights: [ProgressInsight] {
        var insights: [ProgressInsight] = []
        
        // Streak insights
        if currentStreak >= 7 {
            insights.append(.streak(currentStreak))
        } else if currentStreak == 0 {
            insights.append(.encouragement)
        }
        
        // Completion insights
        if weeklyGoalProgress >= 1.0 {
            insights.append(.weeklyGoalAchieved)
        } else if weeklyGoalProgress >= 0.5 {
            insights.append(.halfwayToWeeklyGoal)
        }
        
        // Focus insights
        if let favorite = favoriteWorkoutFocus {
            insights.append(.favoriteWorkout(favorite))
        }
        
        return insights
    }
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Public Methods
    
    /// Load all progress data
    @Sendable func loadProgressData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let weeklyStatsTask = loadWeeklyStats()
            async let monthlyProgressTask = loadMonthlyProgress()
            async let overallStatsTask = loadOverallStats()
            async let chartDataTask = loadChartData()
            
            _ = try await (weeklyStatsTask, monthlyProgressTask, overallStatsTask, chartDataTask)
            
        } catch {
            errorMessage = "Failed to load progress data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load weekly statistics
    @Sendable func loadWeeklyStats() async throws {
        let stats = try await persistenceController.fetchWeeklyStats()
        weeklyStats = stats
        
        // Update current week completion
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        if let thisWeek = stats.first(where: { $0.weekOfYear == currentWeek && $0.year == currentYear }) {
            currentWeekCompletion = Double(thisWeek.completedWorkouts)
        }
    }
    
    /// Load monthly progress
    @Sendable func loadMonthlyProgress() async throws {
        let progress = try await persistenceController.fetchMonthlyProgress()
        monthlyProgress = progress
        
        // Update current month completion
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        if let thisMonth = progress.first(where: { $0.month == currentMonth && $0.year == currentYear }) {
            currentMonthCompletion = Double(thisMonth.completedWorkouts)
        }
    }
    
    /// Load overall statistics
    @Sendable func loadOverallStats() async throws {
        let stats = try await persistenceController.fetchOverallStats()
        
        totalWorkoutsCompleted = stats.totalWorkouts
        currentStreak = stats.currentStreak
        longestStreak = stats.longestStreak
        averageWorkoutDuration = stats.averageDuration
        favoriteWorkoutFocus = stats.favoriteWorkoutFocus
    }
    
    /// Load chart data for selected time range
    @Sendable func loadChartData() async throws {
        let data = try await persistenceController.fetchChartData(for: selectedTimeRange)
        chartData = data
    }
    
    /// Change selected time range
    @Sendable func changeTimeRange(to range: TimeRange) async {
        selectedTimeRange = range
        
        do {
            try await loadChartData()
        } catch {
            errorMessage = "Failed to load chart data: \(error.localizedDescription)"
        }
    }
    
    /// Export progress data to CSV
    @Sendable func exportProgressData() async {
        isExporting = true
        exportMessage = nil
        
        do {
            let csvData = try await persistenceController.exportProgressData()
            
            // Save to Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "FitVital_Progress_\(dateFormatter.string(from: Date())).csv"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
            
            exportMessage = "Progress data exported to \(fileName)"
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
        }
        
        isExporting = false
    }
    
    /// Get completion ring data
    func getCompletionRingData() -> CompletionRingData {
        return CompletionRingData(
            weeklyProgress: weeklyGoalProgress,
            monthlyProgress: monthlyGoalProgress,
            streakProgress: min(Double(currentStreak) / 30.0, 1.0) // 30-day streak as max
        )
    }
    
    /// Get workout distribution data
    func getWorkoutDistribution() -> [WorkoutDistribution] {
        let focusTypes = FocusType.allCases
        var distribution: [WorkoutDistribution] = []
        
        for focus in focusTypes {
            let count = weeklyStats.reduce(0) { total, week in
                total + (week.workoutsByFocus[focus] ?? 0)
            }
            
            if count > 0 {
                distribution.append(WorkoutDistribution(focus: focus, count: count))
            }
        }
        
        return distribution.sorted { $0.count > $1.count }
    }
    
    /// Calculate weekly progress percentage
    func weeklyProgressPercentage(for week: WeeklyStats, goal: Int = 3) -> Double {
        return min(Double(week.completedWorkouts) / Double(goal), 1.0)
    }
    
    // MARK: - Private Properties
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Supporting Data Models

/// Weekly statistics data
struct WeeklyStats: Identifiable {
    let id = UUID()
    let weekOfYear: Int
    let year: Int
    let completedWorkouts: Int
    let totalDuration: TimeInterval
    let workoutsByFocus: [FocusType: Int]
    
    var weekDateRange: String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekOfYear = weekOfYear
        components.year = year
        
        guard let weekStart = calendar.date(from: components) else { return "" }
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))"
    }
}

/// Monthly progress data
struct MonthlyProgress: Identifiable {
    let id = UUID()
    let month: Int
    let year: Int
    let completedWorkouts: Int
    let totalDuration: TimeInterval
    let averageRating: Double
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}

/// Overall statistics
struct OverallStats {
    let totalWorkouts: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageDuration: TimeInterval
    let favoriteWorkoutFocus: FocusType?
}

/// Chart data point
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let category: String?
}

/// Time range for charts
enum TimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

/// Completion ring data
struct CompletionRingData {
    let weeklyProgress: Double
    let monthlyProgress: Double
    let streakProgress: Double
}

/// Workout distribution by focus
struct WorkoutDistribution: Identifiable {
    let id = UUID()
    let focus: FocusType
    let count: Int
    
    var percentage: Double {
        // This would be calculated based on total workouts
        return 0.0
    }
}

/// Progress insights
enum ProgressInsight {
    case streak(Int)
    case weeklyGoalAchieved
    case halfwayToWeeklyGoal
    case favoriteWorkout(FocusType)
    case encouragement
    
    var title: String {
        switch self {
        case .streak(let days):
            return "\(days) Day Streak!"
        case .weeklyGoalAchieved:
            return "Weekly Goal Achieved!"
        case .halfwayToWeeklyGoal:
            return "Halfway There!"
        case .favoriteWorkout(let focus):
            return "Favorite: \(focus.displayName)"
        case .encouragement:
            return "Time to Get Moving!"
        }
    }
    
    var message: String {
        switch self {
        case .streak(let days):
            return "You've worked out \(days) days in a row. Keep it up!"
        case .weeklyGoalAchieved:
            return "You've hit your weekly workout goal. Amazing!"
        case .halfwayToWeeklyGoal:
            return "You're halfway to your weekly goal. You've got this!"
        case .favoriteWorkout(let focus):
            return "\(focus.displayName) workouts seem to be your go-to choice."
        case .encouragement:
            return "Every journey starts with a single step. Let's get started!"
        }
    }
    
    var icon: String {
        switch self {
        case .streak:
            return "flame.fill"
        case .weeklyGoalAchieved:
            return "checkmark.circle.fill"
        case .halfwayToWeeklyGoal:
            return "chart.line.uptrend.xyaxis"
        case .favoriteWorkout:
            return "heart.fill"
        case .encouragement:
            return "hand.thumbsup.fill"
        }
    }
} 