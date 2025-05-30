//
//  TestRunner.swift
//  fitVitalTests
//
//  Created by Nick Conoplia on 30/5/2025.
//

import XCTest
@testable import fitVital

/// Test configuration and utilities for FitVital app testing
final class TestRunner {
    
    /// Shared test runner instance
    static let shared = TestRunner()
    
    private init() {}
    
    // MARK: - Test Configuration
    
    /// Configure test environment
    func configureTestEnvironment() {
        // Clear UserDefaults for consistent testing
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Set test-specific configurations
        UserDefaults.standard.set(true, forKey: "isRunningTests")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    
    /// Clean up after tests
    func cleanupTestEnvironment() {
        UserDefaults.standard.removeObject(forKey: "isRunningTests")
    }
    
    // MARK: - Mock Data Factory
    
    /// Create test user profile
    func createTestUserProfile(name: String = "Test User") -> UserProfile {
        return UserProfile(
            name: name,
            goal: .buildMuscle,
            fitnessLevel: .intermediate,
            workoutFrequency: 4,
            availableEquipment: [.dumbbells, .barbell],
            preferredWorkoutTimes: [.morning],
            workoutDuration: 60
        )
    }
    
    /// Create test workout
    func createTestWorkout(
        title: String = "Test Workout",
        focus: FocusType = .strength,
        scheduledDate: Date = Date()
    ) -> Workout {
        return Workout(
            title: title,
            focus: focus,
            exercises: createTestExercises(),
            scheduledDate: scheduledDate,
            estimatedDuration: 45,
            difficulty: .intermediate
        )
    }
    
    /// Create test exercises
    func createTestExercises() -> [Exercise] {
        return [
            Exercise(
                name: "Push-ups",
                targetMuscles: ["Chest", "Shoulders", "Triceps"],
                equipment: .bodyweight,
                difficulty: .beginner,
                instructions: ["Start in plank position", "Lower body", "Push back up"],
                sets: 3,
                reps: 15,
                duration: nil,
                restTime: 60
            ),
            Exercise(
                name: "Squats",
                targetMuscles: ["Glutes", "Quadriceps", "Hamstrings"],
                equipment: .bodyweight,
                difficulty: .beginner,
                instructions: ["Stand with feet shoulder-width apart", "Lower into squat", "Return to standing"],
                sets: 3,
                reps: 20,
                duration: nil,
                restTime: 60
            )
        ]
    }
    
    /// Create test weekly stats
    func createTestWeeklyStats() -> [WeeklyStats] {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return [
            WeeklyStats(
                weekOfYear: currentWeek,
                year: currentYear,
                completedWorkouts: 3,
                totalDuration: 2700, // 45 minutes * 3
                workoutsByFocus: [.strength: 2, .cardio: 1]
            ),
            WeeklyStats(
                weekOfYear: currentWeek - 1,
                year: currentYear,
                completedWorkouts: 4,
                totalDuration: 3600, // 45 minutes * 4
                workoutsByFocus: [.strength: 3, .cardio: 1]
            )
        ]
    }
    
    /// Create test monthly progress
    func createTestMonthlyProgress() -> [MonthlyProgress] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return [
            MonthlyProgress(
                month: currentMonth,
                year: currentYear,
                completedWorkouts: 12,
                totalDuration: 10800, // 45 minutes * 12
                averageRating: 4.5
            ),
            MonthlyProgress(
                month: currentMonth - 1,
                year: currentYear,
                completedWorkouts: 15,
                totalDuration: 13500, // 45 minutes * 15
                averageRating: 4.8
            )
        ]
    }
    
    /// Create test chart data
    func createTestChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        var data: [ChartDataPoint] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let value = Double.random(in: 0...5)
            data.append(ChartDataPoint(date: date, value: value, category: "Workouts"))
        }
        
        return data.reversed()
    }
    
    // MARK: - Test Assertions
    
    /// Assert that two workouts are equivalent
    func assertWorkoutsEqual(_ workout1: Workout, _ workout2: Workout, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(workout1.id, workout2.id, file: file, line: line)
        XCTAssertEqual(workout1.title, workout2.title, file: file, line: line)
        XCTAssertEqual(workout1.focus, workout2.focus, file: file, line: line)
        XCTAssertEqual(workout1.estimatedDuration, workout2.estimatedDuration, file: file, line: line)
        XCTAssertEqual(workout1.difficulty, workout2.difficulty, file: file, line: line)
    }
    
    /// Assert that user profiles are equivalent
    func assertProfilesEqual(_ profile1: UserProfile, _ profile2: UserProfile, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(profile1.name, profile2.name, file: file, line: line)
        XCTAssertEqual(profile1.goal, profile2.goal, file: file, line: line)
        XCTAssertEqual(profile1.fitnessLevel, profile2.fitnessLevel, file: file, line: line)
        XCTAssertEqual(profile1.workoutFrequency, profile2.workoutFrequency, file: file, line: line)
        XCTAssertEqual(profile1.workoutDuration, profile2.workoutDuration, file: file, line: line)
    }
    
    // MARK: - Performance Testing Helpers
    
    /// Measure performance of async operations
    func measureAsyncPerformance<T>(
        _ operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let expectation = XCTestExpectation(description: "Async performance test")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await operation()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            XCTAssertLessThan(timeElapsed, 5.0, "Operation took too long: \(timeElapsed) seconds", file: file, line: line)
        } catch {
            XCTFail("Operation failed with error: \(error)", file: file, line: line)
        }
        
        expectation.fulfill()
    }
    
    // MARK: - UI Test Helpers
    
    /// Wait for element with timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// Take screenshot for debugging
    func takeScreenshot(name: String, app: XCUIApplication) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        XCTContext.runActivity(named: "Screenshot: \(name)") { activity in
            activity.add(attachment)
        }
    }
    
    // MARK: - Memory Testing
    
    /// Test for memory leaks in ViewModels
    func testViewModelMemoryLeak<T: AnyObject>(_ createViewModel: () -> T) {
        weak var weakViewModel: T?
        
        autoreleasepool {
            let viewModel = createViewModel()
            weakViewModel = viewModel
            // Use viewModel
        }
        
        // Wait for deallocation
        let expectation = XCTestExpectation(description: "ViewModel should be deallocated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
            expectation.fulfill()
        }
    }
}

// MARK: - Test Suite Organization

/// Base test case for unit tests
class FitVitalUnitTestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
        TestRunner.shared.configureTestEnvironment()
    }
    
    override func tearDown() {
        TestRunner.shared.cleanupTestEnvironment()
        super.tearDown()
    }
}

/// Base test case for UI tests
class FitVitalUITestCase: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
}

// MARK: - Test Data Constants

enum TestConstants {
    static let defaultTimeout: TimeInterval = 5.0
    static let longTimeout: TimeInterval = 10.0
    static let shortTimeout: TimeInterval = 2.0
    
    static let testUserName = "Test User"
    static let testWorkoutTitle = "Test Workout"
    static let testExerciseName = "Test Exercise"
    
    enum Accessibility {
        static let homeTab = "home_tab"
        static let planTab = "plan_tab"
        static let calendarTab = "calendar_tab"
        static let progressTab = "progress_tab"
        static let settingsTab = "settings_tab"
    }
}

// MARK: - Test Result Collection

/// Collect and report test results
final class TestResultCollector {
    static let shared = TestResultCollector()
    
    private var testResults: [String: Bool] = [:]
    private var testDurations: [String: TimeInterval] = [:]
    
    private init() {}
    
    func recordTest(name: String, passed: Bool, duration: TimeInterval) {
        testResults[name] = passed
        testDurations[name] = duration
    }
    
    func generateReport() -> String {
        let totalTests = testResults.count
        let passedTests = testResults.values.filter { $0 }.count
        let failedTests = totalTests - passedTests
        let totalDuration = testDurations.values.reduce(0, +)
        
        var report = """
        FitVital Test Results
        ====================
        Total Tests: \(totalTests)
        Passed: \(passedTests)
        Failed: \(failedTests)
        Success Rate: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%
        Total Duration: \(String(format: "%.2f", totalDuration))s
        
        """
        
        if failedTests > 0 {
            report += "Failed Tests:\n"
            for (name, passed) in testResults where !passed {
                report += "- \(name)\n"
            }
        }
        
        return report
    }
} 