//
//  ProgressViewModelTests.swift
//  fitVitalTests
//
//  Created by Nick Conoplia on 30/5/2025.
//

import XCTest
@testable import fitVital

@MainActor
final class ProgressViewModelTests: XCTestCase {
    var viewModel: ProgressViewModel!
    var mockPersistenceController: MockPersistenceController!
    
    override func setUp() {
        super.setUp()
        mockPersistenceController = MockPersistenceController()
        viewModel = ProgressViewModel(persistenceController: mockPersistenceController)
    }
    
    override func tearDown() {
        viewModel = nil
        mockPersistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.weeklyStats.count, 0)
        XCTAssertEqual(viewModel.monthlyProgress.count, 0)
        XCTAssertEqual(viewModel.currentWeekCompletion, 0.0)
        XCTAssertEqual(viewModel.currentMonthCompletion, 0.0)
        XCTAssertEqual(viewModel.totalWorkoutsCompleted, 0)
        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertEqual(viewModel.longestStreak, 0)
        XCTAssertEqual(viewModel.averageWorkoutDuration, 0)
        XCTAssertNil(viewModel.favoriteWorkoutFocus)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.selectedTimeRange, .month)
        XCTAssertEqual(viewModel.chartData.count, 0)
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertNil(viewModel.exportMessage)
    }
    
    // MARK: - Progress Data Loading Tests
    
    func testLoadProgressData() async {
        // Given
        let weeklyStats = [
            WeeklyStats(weekOfYear: 1, year: 2023, completedWorkouts: 3, totalDuration: 2700, workoutsByFocus: [.strength: 2, .cardio: 1])
        ]
        let monthlyProgress = [
            MonthlyProgress(month: 1, year: 2023, completedWorkouts: 12, totalDuration: 10800, averageRating: 4.5)
        ]
        let overallStats = OverallStats(
            totalWorkouts: 50,
            currentStreak: 5,
            longestStreak: 15,
            averageDuration: 45 * 60,
            favoriteWorkoutFocus: .strength
        )
        let chartData = [
            ChartDataPoint(date: Date(), value: 3, category: "Workouts")
        ]
        
        mockPersistenceController.weeklyStats = weeklyStats
        mockPersistenceController.monthlyProgress = monthlyProgress
        mockPersistenceController.overallStats = overallStats
        mockPersistenceController.chartData = chartData
        
        // When
        await viewModel.loadProgressData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.weeklyStats.count, 1)
        XCTAssertEqual(viewModel.monthlyProgress.count, 1)
        XCTAssertEqual(viewModel.totalWorkoutsCompleted, 50)
        XCTAssertEqual(viewModel.currentStreak, 5)
        XCTAssertEqual(viewModel.longestStreak, 15)
        XCTAssertEqual(viewModel.averageWorkoutDuration, 45 * 60)
        XCTAssertEqual(viewModel.favoriteWorkoutFocus, .strength)
        XCTAssertEqual(viewModel.chartData.count, 1)
    }
    
    func testLoadProgressDataError() async {
        // Given
        mockPersistenceController.shouldFailLoad = true
        
        // When
        await viewModel.loadProgressData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to load progress data") == true)
    }
    
    // MARK: - Weekly Stats Tests
    
    func testLoadWeeklyStats() async {
        // Given
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let weeklyStats = [
            WeeklyStats(weekOfYear: currentWeek, year: currentYear, completedWorkouts: 4, totalDuration: 3600, workoutsByFocus: [.strength: 3, .cardio: 1])
        ]
        mockPersistenceController.weeklyStats = weeklyStats
        
        // When
        try await viewModel.loadWeeklyStats()
        
        // Then
        XCTAssertEqual(viewModel.weeklyStats.count, 1)
        XCTAssertEqual(viewModel.currentWeekCompletion, 4.0)
    }
    
    // MARK: - Monthly Progress Tests
    
    func testLoadMonthlyProgress() async {
        // Given
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let monthlyProgress = [
            MonthlyProgress(month: currentMonth, year: currentYear, completedWorkouts: 15, totalDuration: 13500, averageRating: 4.8)
        ]
        mockPersistenceController.monthlyProgress = monthlyProgress
        
        // When
        try await viewModel.loadMonthlyProgress()
        
        // Then
        XCTAssertEqual(viewModel.monthlyProgress.count, 1)
        XCTAssertEqual(viewModel.currentMonthCompletion, 15.0)
    }
    
    // MARK: - Chart Data Tests
    
    func testLoadChartData() async {
        // Given
        let chartData = [
            ChartDataPoint(date: Date(), value: 5, category: "Workouts"),
            ChartDataPoint(date: Date().addingTimeInterval(-86400), value: 3, category: "Workouts")
        ]
        mockPersistenceController.chartData = chartData
        
        // When
        try await viewModel.loadChartData()
        
        // Then
        XCTAssertEqual(viewModel.chartData.count, 2)
    }
    
    func testChangeTimeRange() async {
        // Given
        let chartData = [
            ChartDataPoint(date: Date(), value: 2, category: "Workouts")
        ]
        mockPersistenceController.chartData = chartData
        
        // When
        await viewModel.changeTimeRange(to: .week)
        
        // Then
        XCTAssertEqual(viewModel.selectedTimeRange, .week)
        XCTAssertEqual(viewModel.chartData.count, 1)
    }
    
    // MARK: - Export Tests
    
    func testExportProgressData() async {
        // Given
        mockPersistenceController.exportData = "test,data,export"
        
        // When
        await viewModel.exportProgressData()
        
        // Then
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertNotNil(viewModel.exportMessage)
        XCTAssertTrue(viewModel.exportMessage?.contains("Progress data exported") == true)
    }
    
    func testExportProgressDataError() async {
        // Given
        mockPersistenceController.shouldFailSave = true
        
        // When
        await viewModel.exportProgressData()
        
        // Then
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to export data") == true)
    }
    
    // MARK: - Computed Properties Tests
    
    func testWeeklyGoalProgress() {
        // Given
        viewModel.currentWeekCompletion = 3.0
        
        // When
        let progress = viewModel.weeklyGoalProgress
        
        // Then
        XCTAssertEqual(progress, 1.0, accuracy: 0.01) // 3/3 = 1.0 (100%)
    }
    
    func testWeeklyGoalProgressOverGoal() {
        // Given
        viewModel.currentWeekCompletion = 5.0
        
        // When
        let progress = viewModel.weeklyGoalProgress
        
        // Then
        XCTAssertEqual(progress, 1.0, accuracy: 0.01) // Capped at 100%
    }
    
    func testMonthlyGoalProgress() {
        // Given
        viewModel.currentMonthCompletion = 6.0
        
        // When
        let progress = viewModel.monthlyGoalProgress
        
        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.01) // 6/12 = 0.5 (50%)
    }
    
    func testFormattedAverageDuration() {
        // Given
        viewModel.averageWorkoutDuration = 45 * 60 // 45 minutes
        
        // When
        let formatted = viewModel.formattedAverageDuration
        
        // Then
        XCTAssertEqual(formatted, "45 min")
    }
    
    // MARK: - Progress Insights Tests
    
    func testProgressInsightsWithStreak() {
        // Given
        viewModel.currentStreak = 10
        viewModel.weeklyGoalProgress = 1.0
        viewModel.favoriteWorkoutFocus = .strength
        
        // When
        let insights = viewModel.progressInsights
        
        // Then
        XCTAssertTrue(insights.contains { insight in
            if case .streak(let days) = insight { return days == 10 }
            return false
        })
        XCTAssertTrue(insights.contains { insight in
            if case .weeklyGoalAchieved = insight { return true }
            return false
        })
        XCTAssertTrue(insights.contains { insight in
            if case .favoriteWorkout(.strength) = insight { return true }
            return false
        })
    }
    
    func testProgressInsightsEncouragement() {
        // Given
        viewModel.currentStreak = 0
        viewModel.weeklyGoalProgress = 0.0
        
        // When
        let insights = viewModel.progressInsights
        
        // Then
        XCTAssertTrue(insights.contains { insight in
            if case .encouragement = insight { return true }
            return false
        })
    }
    
    func testProgressInsightsHalfwayToGoal() {
        // Given
        viewModel.currentStreak = 2
        viewModel.weeklyGoalProgress = 0.6 // 60%
        
        // When
        let insights = viewModel.progressInsights
        
        // Then
        XCTAssertTrue(insights.contains { insight in
            if case .halfwayToWeeklyGoal = insight { return true }
            return false
        })
    }
    
    // MARK: - Completion Ring Data Tests
    
    func testGetCompletionRingData() {
        // Given
        viewModel.currentWeekCompletion = 3.0 // 100% of weekly goal
        viewModel.currentMonthCompletion = 6.0 // 50% of monthly goal
        viewModel.currentStreak = 15 // 50% of 30-day streak
        
        // When
        let ringData = viewModel.getCompletionRingData()
        
        // Then
        XCTAssertEqual(ringData.weeklyProgress, 1.0, accuracy: 0.01)
        XCTAssertEqual(ringData.monthlyProgress, 0.5, accuracy: 0.01)
        XCTAssertEqual(ringData.streakProgress, 0.5, accuracy: 0.01)
    }
    
    // MARK: - Workout Distribution Tests
    
    func testGetWorkoutDistribution() {
        // Given
        let weeklyStats = [
            WeeklyStats(weekOfYear: 1, year: 2023, completedWorkouts: 5, totalDuration: 4500, workoutsByFocus: [.strength: 3, .cardio: 2]),
            WeeklyStats(weekOfYear: 2, year: 2023, completedWorkouts: 4, totalDuration: 3600, workoutsByFocus: [.strength: 2, .cardio: 1, .mobility: 1])
        ]
        viewModel.weeklyStats = weeklyStats
        
        // When
        let distribution = viewModel.getWorkoutDistribution()
        
        // Then
        XCTAssertEqual(distribution.count, 3)
        
        // Should be sorted by count (strength: 5, cardio: 3, mobility: 1)
        XCTAssertEqual(distribution[0].focus, .strength)
        XCTAssertEqual(distribution[0].count, 5)
        XCTAssertEqual(distribution[1].focus, .cardio)
        XCTAssertEqual(distribution[1].count, 3)
        XCTAssertEqual(distribution[2].focus, .mobility)
        XCTAssertEqual(distribution[2].count, 1)
    }
    
    // MARK: - Weekly Progress Percentage Tests
    
    func testWeeklyProgressPercentage() {
        // Given
        let weekStats = WeeklyStats(weekOfYear: 1, year: 2023, completedWorkouts: 2, totalDuration: 1800, workoutsByFocus: [.strength: 2])
        
        // When
        let percentage = viewModel.weeklyProgressPercentage(for: weekStats, goal: 3)
        
        // Then
        XCTAssertEqual(percentage, 2.0/3.0, accuracy: 0.01)
    }
    
    func testWeeklyProgressPercentageOverGoal() {
        // Given
        let weekStats = WeeklyStats(weekOfYear: 1, year: 2023, completedWorkouts: 5, totalDuration: 4500, workoutsByFocus: [.strength: 5])
        
        // When
        let percentage = viewModel.weeklyProgressPercentage(for: weekStats, goal: 3)
        
        // Then
        XCTAssertEqual(percentage, 1.0, accuracy: 0.01) // Capped at 100%
    }
}

// MARK: - Mock Persistence Controller Extension

extension MockPersistenceController {
    var weeklyStats: [WeeklyStats] = []
    var monthlyProgress: [MonthlyProgress] = []
    var overallStats: OverallStats = OverallStats(totalWorkouts: 0, currentStreak: 0, longestStreak: 0, averageDuration: 0, favoriteWorkoutFocus: nil)
    var chartData: [ChartDataPoint] = []
    var exportData: String = ""
    
    func fetchWeeklyStats() async throws -> [WeeklyStats] {
        if shouldFailLoad {
            throw MockError.loadFailed
        }
        return weeklyStats
    }
    
    func fetchMonthlyProgress() async throws -> [MonthlyProgress] {
        if shouldFailLoad {
            throw MockError.loadFailed
        }
        return monthlyProgress
    }
    
    func fetchOverallStats() async throws -> OverallStats {
        if shouldFailLoad {
            throw MockError.loadFailed
        }
        return overallStats
    }
    
    func fetchChartData(for timeRange: TimeRange) async throws -> [ChartDataPoint] {
        if shouldFailLoad {
            throw MockError.loadFailed
        }
        return chartData
    }
    
    func exportProgressData() async throws -> String {
        if shouldFailSave {
            throw MockError.saveFailed
        }
        return exportData
    }
} 