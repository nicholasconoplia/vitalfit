//
//  CalendarViewModelTests.swift
//  fitVitalTests
//
//  Created by Nick Conoplia on 30/5/2025.
//

import XCTest
import EventKit
@testable import fitVital

@MainActor
final class CalendarViewModelTests: XCTestCase {
    var viewModel: CalendarViewModel!
    var mockCalendarService: MockCalendarService!
    var mockPersistenceController: MockPersistenceController!
    
    override func setUp() {
        super.setUp()
        mockCalendarService = MockCalendarService()
        mockPersistenceController = MockPersistenceController()
        viewModel = CalendarViewModel(
            persistenceController: mockPersistenceController,
            calendarService: mockCalendarService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockCalendarService = nil
        mockPersistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.viewMode, .month)
        XCTAssertEqual(viewModel.workouts.count, 0)
        XCTAssertEqual(viewModel.busyBlocks.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.calendarPermissionGranted)
        XCTAssertFalse(viewModel.showingPermissionRequest)
    }
    
    // MARK: - Calendar Data Loading Tests
    
    func testLoadCalendarData() async {
        // Given
        let workouts = [
            Workout(id: UUID(), title: "Morning Workout", focus: .strength, exercises: [], scheduledDate: Date(), estimatedDuration: 45, difficulty: .intermediate),
            Workout(id: UUID(), title: "Evening Cardio", focus: .cardio, exercises: [], scheduledDate: Date(), estimatedDuration: 30, difficulty: .beginner)
        ]
        mockPersistenceController.storedWorkouts = workouts
        mockCalendarService.shouldGrantPermission = true
        
        // When
        await viewModel.loadCalendarData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.workouts.count, 2)
        XCTAssertTrue(viewModel.calendarPermissionGranted)
    }
    
    func testLoadCalendarDataWithoutPermission() async {
        // Given
        mockCalendarService.shouldGrantPermission = false
        
        // When
        await viewModel.loadCalendarData()
        
        // Then
        XCTAssertFalse(viewModel.calendarPermissionGranted)
        XCTAssertEqual(viewModel.busyBlocks.count, 0)
    }
    
    func testLoadCalendarDataError() async {
        // Given
        mockPersistenceController.shouldFailLoad = true
        
        // When
        await viewModel.loadCalendarData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to load calendar data") == true)
    }
    
    // MARK: - Permission Tests
    
    func testRequestCalendarPermission() async {
        // Given
        mockCalendarService.shouldGrantPermission = true
        
        // When
        await viewModel.requestCalendarPermission()
        
        // Then
        XCTAssertTrue(viewModel.calendarPermissionGranted)
        XCTAssertFalse(viewModel.showingPermissionRequest)
    }
    
    func testRequestCalendarPermissionDenied() async {
        // Given
        mockCalendarService.shouldGrantPermission = false
        
        // When
        await viewModel.requestCalendarPermission()
        
        // Then
        XCTAssertFalse(viewModel.calendarPermissionGranted)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Calendar permission denied")
    }
    
    // MARK: - View Mode Tests
    
    func testSwitchViewMode() async {
        // Given
        XCTAssertEqual(viewModel.viewMode, .month)
        
        // When
        await viewModel.switchViewMode(to: .week)
        
        // Then
        XCTAssertEqual(viewModel.viewMode, .week)
    }
    
    // MARK: - Navigation Tests
    
    func testPreviousPeriodMonth() async {
        // Given
        let originalDate = viewModel.displayedPeriod
        viewModel.viewMode = .month
        
        // When
        await viewModel.previousPeriod()
        
        // Then
        XCTAssertTrue(viewModel.displayedPeriod < originalDate)
    }
    
    func testNextPeriodMonth() async {
        // Given
        let originalDate = viewModel.displayedPeriod
        viewModel.viewMode = .month
        
        // When
        await viewModel.nextPeriod()
        
        // Then
        XCTAssertTrue(viewModel.displayedPeriod > originalDate)
    }
    
    func testPreviousPeriodWeek() async {
        // Given
        let originalDate = viewModel.displayedPeriod
        viewModel.viewMode = .week
        
        // When
        await viewModel.previousPeriod()
        
        // Then
        XCTAssertTrue(viewModel.displayedPeriod < originalDate)
    }
    
    func testNextPeriodWeek() async {
        // Given
        let originalDate = viewModel.displayedPeriod
        viewModel.viewMode = .week
        
        // When
        await viewModel.nextPeriod()
        
        // Then
        XCTAssertTrue(viewModel.displayedPeriod > originalDate)
    }
    
    func testGoToToday() async {
        // Given
        let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        viewModel.displayedPeriod = futureDate
        
        // When
        await viewModel.goToToday()
        
        // Then
        XCTAssertTrue(Calendar.current.isDate(viewModel.displayedPeriod, inSameDayAs: Date()))
        XCTAssertTrue(Calendar.current.isDate(viewModel.selectedDate, inSameDayAs: Date()))
    }
    
    // MARK: - Date Selection Tests
    
    func testSelectDateWithWorkout() async {
        // Given
        let testDate = Date()
        let workout = Workout(
            id: UUID(),
            title: "Test Workout",
            focus: .strength,
            exercises: [],
            scheduledDate: testDate,
            estimatedDuration: 45,
            difficulty: .intermediate
        )
        viewModel.workouts = [workout]
        
        // When
        await viewModel.selectDate(testDate)
        
        // Then
        XCTAssertEqual(viewModel.selectedDate, testDate)
        XCTAssertNotNil(viewModel.selectedWorkout)
        XCTAssertEqual(viewModel.selectedWorkout?.id, workout.id)
        XCTAssertTrue(viewModel.showingWorkoutDetail)
    }
    
    func testSelectDateWithoutWorkout() async {
        // Given
        let testDate = Date()
        viewModel.workouts = []
        
        // When
        await viewModel.selectDate(testDate)
        
        // Then
        XCTAssertEqual(viewModel.selectedDate, testDate)
        XCTAssertNil(viewModel.selectedWorkout)
        XCTAssertFalse(viewModel.showingWorkoutDetail)
    }
    
    // MARK: - Auto-Scheduling Tests
    
    func testAutoScheduleWeekWithPermission() async {
        // Given
        viewModel.calendarPermissionGranted = true
        let testDate = Date()
        let workout = Workout(
            id: UUID(),
            title: "Test Workout",
            focus: .strength,
            exercises: [],
            scheduledDate: testDate,
            estimatedDuration: 45,
            difficulty: .intermediate
        )
        viewModel.workouts = [workout]
        viewModel.selectedDate = testDate
        
        // When
        await viewModel.autoScheduleWeek()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showingPermissionRequest)
    }
    
    func testAutoScheduleWeekWithoutPermission() async {
        // Given
        viewModel.calendarPermissionGranted = false
        
        // When
        await viewModel.autoScheduleWeek()
        
        // Then
        XCTAssertTrue(viewModel.showingPermissionRequest)
    }
    
    func testAutoScheduleWeekWithNoWorkouts() async {
        // Given
        viewModel.calendarPermissionGranted = true
        viewModel.workouts = []
        
        // When
        await viewModel.autoScheduleWeek()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "No workouts to schedule this week")
    }
    
    // MARK: - Calendar Days Generation Tests
    
    func testCalendarDaysGeneration() {
        // Given
        viewModel.viewMode = .month
        viewModel.displayedPeriod = Date()
        
        // When
        let calendarDays = viewModel.calendarDays
        
        // Then
        XCTAssertEqual(calendarDays.count, 42) // 6 weeks * 7 days
        XCTAssertTrue(calendarDays.contains { $0.isToday })
    }
    
    func testWeekCalendarDaysGeneration() {
        // Given
        viewModel.viewMode = .week
        viewModel.displayedPeriod = Date()
        
        // When
        let calendarDays = viewModel.calendarDays
        
        // Then
        XCTAssertEqual(calendarDays.count, 7)
        XCTAssertTrue(calendarDays.allSatisfy { $0.isCurrentMonth })
    }
    
    // MARK: - Conflict Detection Tests
    
    func testHasConflicts() {
        // Given
        let testDate = Date()
        let busyInterval = DateInterval(
            start: Calendar.current.startOfDay(for: testDate),
            end: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.startOfDay(for: testDate)) ?? testDate
        )
        viewModel.busyBlocks = [busyInterval]
        
        // When
        let hasConflicts = viewModel.hasConflicts(for: testDate)
        
        // Then
        XCTAssertTrue(hasConflicts)
    }
    
    func testNoConflicts() {
        // Given
        let testDate = Date()
        let differentDate = Calendar.current.date(byAdding: .day, value: 1, to: testDate) ?? testDate
        let busyInterval = DateInterval(
            start: Calendar.current.startOfDay(for: differentDate),
            end: Calendar.current.date(byAdding: .hour, value: 2, to: Calendar.current.startOfDay(for: differentDate)) ?? differentDate
        )
        viewModel.busyBlocks = [busyInterval]
        
        // When
        let hasConflicts = viewModel.hasConflicts(for: testDate)
        
        // Then
        XCTAssertFalse(hasConflicts)
    }
    
    // MARK: - Workout Lookup Tests
    
    func testWorkoutForDate() {
        // Given
        let testDate = Date()
        let workout = Workout(
            id: UUID(),
            title: "Test Workout",
            focus: .strength,
            exercises: [],
            scheduledDate: testDate,
            estimatedDuration: 45,
            difficulty: .intermediate
        )
        viewModel.workouts = [workout]
        
        // When
        let foundWorkout = viewModel.workout(for: testDate)
        
        // Then
        XCTAssertNotNil(foundWorkout)
        XCTAssertEqual(foundWorkout?.id, workout.id)
    }
    
    func testWorkoutForDateNotFound() {
        // Given
        let testDate = Date()
        let differentDate = Calendar.current.date(byAdding: .day, value: 1, to: testDate) ?? testDate
        let workout = Workout(
            id: UUID(),
            title: "Test Workout",
            focus: .strength,
            exercises: [],
            scheduledDate: differentDate,
            estimatedDuration: 45,
            difficulty: .intermediate
        )
        viewModel.workouts = [workout]
        
        // When
        let foundWorkout = viewModel.workout(for: testDate)
        
        // Then
        XCTAssertNil(foundWorkout)
    }
    
    // MARK: - Period Title Tests
    
    func testPeriodTitleMonth() {
        // Given
        viewModel.viewMode = .month
        let testDate = Calendar.current.date(from: DateComponents(year: 2023, month: 6, day: 15)) ?? Date()
        viewModel.displayedPeriod = testDate
        
        // When
        let title = viewModel.periodTitle
        
        // Then
        XCTAssertTrue(title.contains("June"))
        XCTAssertTrue(title.contains("2023"))
    }
    
    func testCanAutoSchedule() {
        // Given
        viewModel.calendarPermissionGranted = true
        viewModel.workouts = [
            Workout(id: UUID(), title: "Test", focus: .strength, exercises: [], scheduledDate: Date(), estimatedDuration: 45, difficulty: .intermediate)
        ]
        
        // When
        let canAutoSchedule = viewModel.canAutoSchedule
        
        // Then
        XCTAssertTrue(canAutoSchedule)
    }
    
    func testCannotAutoScheduleWithoutPermission() {
        // Given
        viewModel.calendarPermissionGranted = false
        viewModel.workouts = [
            Workout(id: UUID(), title: "Test", focus: .strength, exercises: [], scheduledDate: Date(), estimatedDuration: 45, difficulty: .intermediate)
        ]
        
        // When
        let canAutoSchedule = viewModel.canAutoSchedule
        
        // Then
        XCTAssertFalse(canAutoSchedule)
    }
    
    func testCannotAutoScheduleWithoutWorkouts() {
        // Given
        viewModel.calendarPermissionGranted = true
        viewModel.workouts = []
        
        // When
        let canAutoSchedule = viewModel.canAutoSchedule
        
        // Then
        XCTAssertFalse(canAutoSchedule)
    }
}

// MARK: - Mock Calendar Service

class MockCalendarService: CalendarServiceProtocol {
    var shouldGrantPermission = false
    var shouldFailRequest = false
    var busyBlocks: [DateInterval] = []
    
    func requestPermissions() async throws -> Bool {
        if shouldFailRequest {
            throw CalendarError.permissionDenied
        }
        return shouldGrantPermission
    }
    
    func getAuthorizationStatus() async -> EKAuthorizationStatus {
        return shouldGrantPermission ? .authorized : .denied
    }
    
    func fetchBusyBlocks(start: Date, end: Date) async throws -> [DateInterval] {
        return busyBlocks
    }
    
    func autoSchedule(workouts: [Workout], busy: [DateInterval]) async -> [Workout] {
        // Simple mock implementation - just return the workouts unchanged
        return workouts
    }
}

// MARK: - Calendar Error

enum CalendarError: Error {
    case permissionDenied
} 