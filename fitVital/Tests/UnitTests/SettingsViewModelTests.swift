//
//  SettingsViewModelTests.swift
//  fitVitalTests
//
//  Created by Nick Conoplia on 30/5/2025.
//

import XCTest
import UserNotifications
import EventKit
@testable import fitVital

@MainActor
final class SettingsViewModelTests: XCTestCase {
    var viewModel: SettingsViewModel!
    var mockPersistenceController: MockPersistenceController!
    var mockNotificationService: MockNotificationService!
    var mockCalendarService: MockCalendarService!
    
    override func setUp() {
        super.setUp()
        mockPersistenceController = MockPersistenceController()
        mockNotificationService = MockNotificationService()
        mockCalendarService = MockCalendarService()
        viewModel = SettingsViewModel(
            persistenceController: mockPersistenceController,
            notificationService: mockNotificationService,
            calendarService: mockCalendarService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockPersistenceController = nil
        mockNotificationService = nil
        mockCalendarService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertNil(viewModel.userProfile)
        XCTAssertFalse(viewModel.notificationsEnabled)
        XCTAssertFalse(viewModel.calendarEnabled)
        XCTAssertEqual(viewModel.reminderTiming, 15)
        XCTAssertTrue(viewModel.weeklyCheckInsEnabled)
        XCTAssertTrue(viewModel.milestoneNotificationsEnabled)
        XCTAssertEqual(viewModel.selectedTheme, .system)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isEditingProfile)
        XCTAssertFalse(viewModel.showingExportOptions)
        XCTAssertFalse(viewModel.showingPermissionExplanation)
        XCTAssertNil(viewModel.selectedPermission)
        XCTAssertEqual(viewModel.exportProgress, 0.0)
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertNil(viewModel.exportMessage)
    }
    
    // MARK: - Settings Loading Tests
    
    func testLoadSettings() async {
        // Given
        let profile = UserProfile(
            name: "Test User",
            goal: .buildMuscle,
            fitnessLevel: .intermediate,
            workoutFrequency: 4,
            availableEquipment: [.dumbbells],
            preferredWorkoutTimes: [.morning],
            workoutDuration: 60
        )
        mockPersistenceController.storedProfile = profile
        mockNotificationService.shouldGrantPermission = true
        mockCalendarService.shouldGrantPermission = true
        
        // When
        await viewModel.loadSettings()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.name, "Test User")
        XCTAssertTrue(viewModel.notificationsEnabled)
        XCTAssertTrue(viewModel.calendarEnabled)
    }
    
    func testLoadSettingsError() async {
        // Given
        mockPersistenceController.shouldFailLoad = true
        
        // When
        await viewModel.loadSettings()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to load settings") == true)
    }
    
    // MARK: - Profile Management Tests
    
    func testSaveProfile() async {
        // Given
        let profile = UserProfile(
            name: "Updated User",
            goal: .loseWeight,
            fitnessLevel: .beginner,
            workoutFrequency: 3,
            availableEquipment: [.bodyweight],
            preferredWorkoutTimes: [.evening],
            workoutDuration: 45
        )
        viewModel.userProfile = profile
        
        // When
        await viewModel.saveProfile()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isEditingProfile)
        XCTAssertEqual(mockPersistenceController.storedProfile?.name, "Updated User")
    }
    
    func testSaveProfileError() async {
        // Given
        let profile = UserProfile(
            name: "Test User",
            goal: .buildMuscle,
            fitnessLevel: .intermediate,
            workoutFrequency: 4,
            availableEquipment: [.dumbbells],
            preferredWorkoutTimes: [.morning],
            workoutDuration: 60
        )
        viewModel.userProfile = profile
        mockPersistenceController.shouldFailSave = true
        
        // When
        await viewModel.saveProfile()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to save profile") == true)
    }
    
    // MARK: - Notification Permission Tests
    
    func testRequestNotificationPermission() async {
        // Given
        mockNotificationService.shouldGrantPermission = true
        
        // When
        await viewModel.requestNotificationPermission()
        
        // Then
        XCTAssertTrue(viewModel.notificationsEnabled)
    }
    
    func testRequestNotificationPermissionDenied() async {
        // Given
        mockNotificationService.shouldGrantPermission = false
        
        // When
        await viewModel.requestNotificationPermission()
        
        // Then
        XCTAssertFalse(viewModel.notificationsEnabled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to enable notifications") == true)
    }
    
    func testToggleNotificationsEnable() async {
        // Given
        viewModel.notificationsEnabled = false
        mockNotificationService.shouldGrantPermission = true
        
        // When
        await viewModel.toggleNotifications()
        
        // Then
        XCTAssertTrue(viewModel.notificationsEnabled)
    }
    
    func testToggleNotificationsDisable() async {
        // Given
        viewModel.notificationsEnabled = true
        
        // When
        await viewModel.toggleNotifications()
        
        // Then
        XCTAssertFalse(viewModel.notificationsEnabled)
    }
    
    // MARK: - Calendar Permission Tests
    
    func testRequestCalendarPermission() async {
        // Given
        mockCalendarService.shouldGrantPermission = true
        
        // When
        await viewModel.requestCalendarPermission()
        
        // Then
        XCTAssertTrue(viewModel.calendarEnabled)
    }
    
    func testRequestCalendarPermissionDenied() async {
        // Given
        mockCalendarService.shouldGrantPermission = false
        
        // When
        await viewModel.requestCalendarPermission()
        
        // Then
        XCTAssertFalse(viewModel.calendarEnabled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to enable calendar access") == true)
    }
    
    func testToggleCalendarIntegrationEnable() async {
        // Given
        viewModel.calendarEnabled = false
        mockCalendarService.shouldGrantPermission = true
        
        // When
        await viewModel.toggleCalendarIntegration()
        
        // Then
        XCTAssertTrue(viewModel.calendarEnabled)
    }
    
    func testToggleCalendarIntegrationDisable() async {
        // Given
        viewModel.calendarEnabled = true
        
        // When
        await viewModel.toggleCalendarIntegration()
        
        // Then
        XCTAssertFalse(viewModel.calendarEnabled)
    }
    
    // MARK: - Settings Updates Tests
    
    func testUpdateReminderTiming() {
        // When
        viewModel.updateReminderTiming(30)
        
        // Then
        XCTAssertEqual(viewModel.reminderTiming, 30)
    }
    
    func testToggleWeeklyCheckIns() {
        // Given
        let initialValue = viewModel.weeklyCheckInsEnabled
        
        // When
        viewModel.toggleWeeklyCheckIns()
        
        // Then
        XCTAssertNotEqual(viewModel.weeklyCheckInsEnabled, initialValue)
    }
    
    func testToggleMilestoneNotifications() {
        // Given
        let initialValue = viewModel.milestoneNotificationsEnabled
        
        // When
        viewModel.toggleMilestoneNotifications()
        
        // Then
        XCTAssertNotEqual(viewModel.milestoneNotificationsEnabled, initialValue)
    }
    
    func testChangeTheme() {
        // When
        viewModel.changeTheme(to: .dark)
        
        // Then
        XCTAssertEqual(viewModel.selectedTheme, .dark)
    }
    
    // MARK: - Data Export Tests
    
    func testExportAllData() async {
        // Given
        mockPersistenceController.exportData = "test export data"
        
        // When
        await viewModel.exportAllData()
        
        // Then
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertEqual(viewModel.exportProgress, 1.0)
        XCTAssertNotNil(viewModel.exportMessage)
        XCTAssertTrue(viewModel.exportMessage?.contains("Complete data exported") == true)
    }
    
    func testExportAllDataError() async {
        // Given
        mockPersistenceController.shouldFailSave = true
        
        // When
        await viewModel.exportAllData()
        
        // Then
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to export data") == true)
    }
    
    // MARK: - Data Clearing Tests
    
    func testClearAllData() async {
        // Given
        let profile = UserProfile(
            name: "Test User",
            goal: .buildMuscle,
            fitnessLevel: .intermediate,
            workoutFrequency: 4,
            availableEquipment: [.dumbbells],
            preferredWorkoutTimes: [.morning],
            workoutDuration: 60
        )
        viewModel.userProfile = profile
        
        // When
        await viewModel.clearAllData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.userProfile)
        XCTAssertNotNil(viewModel.exportMessage)
        XCTAssertEqual(viewModel.exportMessage, "All data has been cleared")
    }
    
    func testClearAllDataError() async {
        // Given
        mockPersistenceController.shouldFailLoad = true // Using load fail to simulate error
        
        // When
        await viewModel.clearAllData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Failed to clear data") == true)
    }
    
    // MARK: - Permission Explanation Tests
    
    func testShowPermissionExplanation() {
        // When
        viewModel.showPermissionExplanation(for: .notifications)
        
        // Then
        XCTAssertEqual(viewModel.selectedPermission, .notifications)
        XCTAssertTrue(viewModel.showingPermissionExplanation)
    }
    
    func testGetNotificationPermissionExplanation() {
        // When
        let explanation = viewModel.getPermissionExplanation(for: .notifications)
        
        // Then
        XCTAssertEqual(explanation.title, "Notifications")
        XCTAssertTrue(explanation.description.contains("Stay motivated"))
        XCTAssertFalse(explanation.benefits.isEmpty)
        XCTAssertEqual(explanation.icon, "bell.fill")
    }
    
    func testGetCalendarPermissionExplanation() {
        // When
        let explanation = viewModel.getPermissionExplanation(for: .calendar)
        
        // Then
        XCTAssertEqual(explanation.title, "Calendar Access")
        XCTAssertTrue(explanation.description.contains("Automatically schedule"))
        XCTAssertFalse(explanation.benefits.isEmpty)
        XCTAssertEqual(explanation.icon, "calendar")
    }
    
    // MARK: - Computed Properties Tests
    
    func testReminderTimings() {
        let timings = viewModel.reminderTimings
        XCTAssertEqual(timings, [5, 10, 15, 30, 60])
    }
    
    func testPermissionsSummaryAllGranted() {
        // Given
        viewModel.notificationsEnabled = true
        viewModel.calendarEnabled = true
        
        // When
        let summary = viewModel.permissionsSummary
        
        // Then
        XCTAssertTrue(summary.allGranted)
        XCTAssertEqual(summary.statusText, "All permissions granted")
    }
    
    func testPermissionsSummaryPartiallyGranted() {
        // Given
        viewModel.notificationsEnabled = true
        viewModel.calendarEnabled = false
        
        // When
        let summary = viewModel.permissionsSummary
        
        // Then
        XCTAssertFalse(summary.allGranted)
        XCTAssertEqual(summary.statusText, "Calendar access needed")
    }
    
    func testPermissionsSummaryNoneGranted() {
        // Given
        viewModel.notificationsEnabled = false
        viewModel.calendarEnabled = false
        
        // When
        let summary = viewModel.permissionsSummary
        
        // Then
        XCTAssertFalse(summary.allGranted)
        XCTAssertEqual(summary.statusText, "Permissions needed")
    }
    
    func testAppVersion() {
        let version = viewModel.appVersion
        XCTAssertTrue(version.contains("Version"))
    }
    
    // MARK: - App Theme Tests
    
    func testAppThemeDisplayNames() {
        XCTAssertEqual(AppTheme.light.displayName, "Light")
        XCTAssertEqual(AppTheme.dark.displayName, "Dark")
        XCTAssertEqual(AppTheme.system.displayName, "System")
    }
    
    func testAppThemeIcons() {
        XCTAssertEqual(AppTheme.light.icon, "sun.max")
        XCTAssertEqual(AppTheme.dark.icon, "moon")
        XCTAssertEqual(AppTheme.system.icon, "gear")
    }
}

// MARK: - Mock Notification Service

class MockNotificationService: NotificationServiceProtocol {
    var shouldGrantPermission = false
    var shouldFailRequest = false
    var scheduledNotifications: [String] = []
    
    func requestPermissions() async throws -> Bool {
        if shouldFailRequest {
            throw NotificationError.permissionDenied
        }
        return shouldGrantPermission
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return shouldGrantPermission ? .authorized : .denied
    }
    
    func scheduleWorkoutReminder(for workout: Workout, minutesBefore: Int) async throws {
        scheduledNotifications.append("workout_\(workout.id.uuidString)")
    }
    
    func scheduleWeeklyCheckIn() async {
        scheduledNotifications.append("weekly_checkin")
    }
    
    func cancelAll() async {
        scheduledNotifications.removeAll()
    }
}

// MARK: - Mock Extensions

extension MockPersistenceController {
    func exportWorkoutData() async throws -> String {
        if shouldFailSave {
            throw MockError.saveFailed
        }
        return exportData
    }
    
    func exportUserProfile() async throws -> String {
        if shouldFailSave {
            throw MockError.saveFailed
        }
        return exportData
    }
    
    func clearAllData() async throws {
        if shouldFailLoad { // Using load fail to simulate clear error
            throw MockError.loadFailed
        }
        storedProfile = nil
        storedWorkouts.removeAll()
    }
}

// MARK: - Error Types

enum NotificationError: Error {
    case permissionDenied
} 