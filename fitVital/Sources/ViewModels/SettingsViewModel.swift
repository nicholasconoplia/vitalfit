//
//  SettingsViewModel.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI
import UserNotifications
import EventKit

/// ViewModel for app settings and user preferences
@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - Published Properties
    
    /// User profile for editing
    var userProfile: UserProfile?
    
    /// Whether notifications are enabled
    var notificationsEnabled = false
    
    /// Whether calendar integration is enabled
    var calendarEnabled = false
    
    /// Workout reminder timing (minutes before)
    var reminderTiming: Int = 15
    
    /// Whether weekly check-ins are enabled
    var weeklyCheckInsEnabled = true
    
    /// Whether milestone notifications are enabled
    var milestoneNotificationsEnabled = true
    
    /// App theme preference
    var selectedTheme: AppTheme = .system
    
    /// Loading state for async operations
    var isLoading = false
    
    /// Error message for UI display
    var errorMessage: String?
    
    /// Whether showing profile edit
    var isEditingProfile = false
    
    /// Whether showing data export options
    var showingExportOptions = false
    
    /// Whether showing permission explanations
    var showingPermissionExplanation = false
    
    /// Selected permission for explanation
    var selectedPermission: PermissionType?
    
    /// Export progress
    var exportProgress: Double = 0.0
    
    /// Whether exporting data
    var isExporting = false
    
    /// Export completion message
    var exportMessage: String?
    
    // MARK: - Computed Properties
    
    /// Available reminder timings (in minutes)
    var reminderTimings: [Int] {
        return [5, 10, 15, 30, 60]
    }
    
    /// Permission status summary
    var permissionsSummary: PermissionsSummary {
        return PermissionsSummary(
            notifications: notificationsEnabled,
            calendar: calendarEnabled
        )
    }
    
    /// App version string
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let notificationService: NotificationServiceProtocol
    private let calendarService: CalendarServiceProtocol
    
    // MARK: - Initialization
    
    init(persistenceController: PersistenceController = .shared,
         notificationService: NotificationServiceProtocol = NotificationService.shared,
         calendarService: CalendarServiceProtocol = CalendarService.shared) {
        self.persistenceController = persistenceController
        self.notificationService = notificationService
        self.calendarService = calendarService
    }
    
    // MARK: - Public Methods
    
    /// Load settings data
    @Sendable func loadSettings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load user profile
            userProfile = try await persistenceController.fetchUserProfile()
            
            // Check permission statuses
            await checkPermissionStatuses()
            
            // Load user preferences from UserDefaults
            loadUserPreferences()
            
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Save user profile changes
    @Sendable func saveProfile() async {
        guard let profile = userProfile else { return }
        
        isLoading = true
        
        do {
            try await persistenceController.saveUserProfile(profile)
            isEditingProfile = false
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Request notification permissions
    @Sendable func requestNotificationPermission() async {
        do {
            notificationsEnabled = try await notificationService.requestPermissions()
            saveUserPreferences()
        } catch {
            errorMessage = "Failed to enable notifications: \(error.localizedDescription)"
        }
    }
    
    /// Request calendar permissions
    @Sendable func requestCalendarPermission() async {
        do {
            calendarEnabled = try await calendarService.requestPermissions()
            saveUserPreferences()
        } catch {
            errorMessage = "Failed to enable calendar access: \(error.localizedDescription)"
        }
    }
    
    /// Toggle notification settings
    @Sendable func toggleNotifications() async {
        if notificationsEnabled {
            // Disable notifications
            await notificationService.cancelAll()
            notificationsEnabled = false
        } else {
            // Request permission and enable
            await requestNotificationPermission()
        }
        saveUserPreferences()
    }
    
    /// Toggle calendar integration
    @Sendable func toggleCalendarIntegration() async {
        if calendarEnabled {
            // Disable calendar integration
            calendarEnabled = false
        } else {
            // Request permission and enable
            await requestCalendarPermission()
        }
        saveUserPreferences()
    }
    
    /// Update reminder timing
    func updateReminderTiming(_ newTiming: Int) {
        reminderTiming = newTiming
        saveUserPreferences()
    }
    
    /// Toggle weekly check-ins
    func toggleWeeklyCheckIns() {
        weeklyCheckInsEnabled.toggle()
        saveUserPreferences()
        
        Task {
            if weeklyCheckInsEnabled {
                await notificationService.scheduleWeeklyCheckIn()
            }
        }
    }
    
    /// Toggle milestone notifications
    func toggleMilestoneNotifications() {
        milestoneNotificationsEnabled.toggle()
        saveUserPreferences()
    }
    
    /// Change app theme
    func changeTheme(to theme: AppTheme) {
        selectedTheme = theme
        saveUserPreferences()
        applyTheme(theme)
    }
    
    /// Export all data
    @Sendable func exportAllData() async {
        isExporting = true
        exportProgress = 0.0
        exportMessage = nil
        
        do {
            // Export progress data
            exportProgress = 0.3
            let progressData = try await persistenceController.exportProgressData()
            
            // Export workout data
            exportProgress = 0.6
            let workoutData = try await persistenceController.exportWorkoutData()
            
            // Export user profile
            exportProgress = 0.8
            let profileData = try await persistenceController.exportUserProfile()
            
            // Combine all data
            exportProgress = 0.9
            let combinedData = combineExportData(progress: progressData, workouts: workoutData, profile: profileData)
            
            // Save to file
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "FitVital_Complete_Export_\(dateFormatter.string(from: Date())).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try combinedData.write(to: fileURL, atomically: true, encoding: .utf8)
            
            exportProgress = 1.0
            exportMessage = "Complete data exported to \(fileName)"
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
        }
        
        isExporting = false
    }
    
    /// Clear all data
    @Sendable func clearAllData() async {
        isLoading = true
        
        do {
            try await persistenceController.clearAllData()
            
            // Reset local state
            userProfile = nil
            
            // Clear notifications
            await notificationService.cancelAll()
            
            exportMessage = "All data has been cleared"
            
        } catch {
            errorMessage = "Failed to clear data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Show permission explanation
    func showPermissionExplanation(for permission: PermissionType) {
        selectedPermission = permission
        showingPermissionExplanation = true
    }
    
    /// Get permission explanation
    func getPermissionExplanation(for permission: PermissionType) -> PermissionExplanation {
        switch permission {
        case .notifications:
            return PermissionExplanation(
                title: "Notifications",
                description: "Stay motivated with workout reminders, progress celebrations, and weekly check-ins.",
                benefits: [
                    "Never miss a scheduled workout",
                    "Get motivated by milestone achievements",
                    "Weekly check-ins to adjust your plan"
                ],
                icon: "bell.fill"
            )
        case .calendar:
            return PermissionExplanation(
                title: "Calendar Access",
                description: "Automatically schedule workouts around your busy calendar events.",
                benefits: [
                    "Smart workout scheduling",
                    "Avoid conflicts with meetings",
                    "Optimize your workout timing"
                ],
                icon: "calendar"
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Check current permission statuses
    private func checkPermissionStatuses() async {
        // Check notification permission
        notificationsEnabled = await notificationService.getAuthorizationStatus() == .authorized
        
        // Check calendar permission
        calendarEnabled = await calendarService.getAuthorizationStatus() == .authorized
    }
    
    /// Load user preferences from UserDefaults
    private func loadUserPreferences() {
        let defaults = UserDefaults.standard
        
        reminderTiming = defaults.object(forKey: "reminderTiming") as? Int ?? 15
        weeklyCheckInsEnabled = defaults.object(forKey: "weeklyCheckInsEnabled") as? Bool ?? true
        milestoneNotificationsEnabled = defaults.object(forKey: "milestoneNotificationsEnabled") as? Bool ?? true
        
        if let themeRawValue = defaults.object(forKey: "selectedTheme") as? String,
           let theme = AppTheme(rawValue: themeRawValue) {
            selectedTheme = theme
        }
    }
    
    /// Save user preferences to UserDefaults
    private func saveUserPreferences() {
        let defaults = UserDefaults.standard
        
        defaults.set(reminderTiming, forKey: "reminderTiming")
        defaults.set(weeklyCheckInsEnabled, forKey: "weeklyCheckInsEnabled")
        defaults.set(milestoneNotificationsEnabled, forKey: "milestoneNotificationsEnabled")
        defaults.set(selectedTheme.rawValue, forKey: "selectedTheme")
    }
    
    /// Apply theme to app
    private func applyTheme(_ theme: AppTheme) {
        // This would typically involve updating the app's color scheme
        // Implementation depends on how theming is handled in the app
    }
    
    /// Combine export data into single JSON
    private func combineExportData(progress: String, workouts: String, profile: String) -> String {
        let exportData = [
            "exportDate": dateFormatter.string(from: Date()),
            "appVersion": appVersion,
            "progressData": progress,
            "workoutData": workouts,
            "profileData": profile
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        
        return jsonString
    }
    
    // MARK: - Private Properties
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Supporting Data Models

/// App theme options
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "gear"
        }
    }
}

/// Permission types
enum PermissionType {
    case notifications
    case calendar
}

/// Permissions summary
struct PermissionsSummary {
    let notifications: Bool
    let calendar: Bool
    
    var allGranted: Bool {
        return notifications && calendar
    }
    
    var statusText: String {
        switch (notifications, calendar) {
        case (true, true):
            return "All permissions granted"
        case (true, false):
            return "Calendar access needed"
        case (false, true):
            return "Notifications disabled"
        case (false, false):
            return "Permissions needed"
        }
    }
}

/// Permission explanation data
struct PermissionExplanation {
    let title: String
    let description: String
    let benefits: [String]
    let icon: String
} 