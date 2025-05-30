//
//  NotificationService.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import UserNotifications

/// Service for managing local notifications
@MainActor
final class NotificationService: ObservableObject {
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Permission Management
    
    /// Request notification permission from the user
    func requestPermission() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        case .ephemeral:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Check current notification permission status
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule all notification types for a user
    func scheduleNotifications(for profile: UserProfile) async {
        // Clear existing notifications
        await clearAllNotifications()
        
        // Schedule different notification types
        await scheduleWorkoutReminders(for: profile)
        await scheduleWeeklySummaries()
        await scheduleStreakMilestones()
        await scheduleMotivationMessages(for: profile)
        await scheduleCheckInPrompts()
        await scheduleAdaptiveAlerts()
    }
    
    /// Clear all pending notifications
    func clearAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - 1. Workout Reminders
    
    /// Schedule workout reminder notifications
    private func scheduleWorkoutReminders(for profile: UserProfile) async {
        for timeOfDay in profile.preferredTimes {
            for dayOfWeek in 1...7 {  // Monday = 2, Sunday = 1
                let identifier = "workout_reminder_\(dayOfWeek)_\(timeOfDay.rawValue)"
                
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("notification_workout_reminder_title", comment: "")
                content.body = String(format: NSLocalizedString("notification_workout_reminder_body", comment: ""), timeOfDay.displayName)
                content.sound = .default
                content.categoryIdentifier = "WORKOUT_REMINDER"
                
                // Schedule for preferred time
                var dateComponents = DateComponents()
                dateComponents.weekday = dayOfWeek
                dateComponents.hour = timeOfDay.defaultHour
                dateComponents.minute = 0
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
                
                try? await notificationCenter.add(request)
            }
        }
    }
    
    /// Schedule immediate workout reminder
    func scheduleWorkoutReminder(for workout: Workout, at scheduledTime: Date) async {
        let identifier = "immediate_workout_\(workout.id.uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = "Workout Time!"
        content.body = "Time for your \(workout.name) workout"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        content.userInfo = ["workoutId": workout.id.uuidString]
        
        let timeInterval = scheduledTime.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    // MARK: - 2. Weekly Summaries
    
    /// Schedule weekly progress summary notifications
    private func scheduleWeeklySummaries() async {
        let identifier = "weekly_summary"
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_weekly_summary_title", comment: "")
        content.body = "Check out your weekly progress and plan ahead!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"
        
        // Schedule for Sunday evening at 6 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 18    // 6 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    /// Send immediate weekly summary with workout count
    func sendWeeklySummary(workoutCount: Int) async {
        let identifier = "weekly_summary_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_weekly_summary_title", comment: "")
        content.body = String(format: NSLocalizedString("notification_weekly_summary_body", comment: ""), workoutCount)
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    // MARK: - 3. Streak Milestones
    
    /// Schedule streak milestone notifications
    private func scheduleStreakMilestones() async {
        // These are triggered programmatically when milestones are reached
        // Pre-schedule some common milestones for motivation
        let milestones = [3, 7, 14, 30, 60, 90, 180, 365]
        
        for milestone in milestones {
            let identifier = "streak_milestone_\(milestone)"
            
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification_streak_milestone_title", comment: "")
            content.body = String(format: NSLocalizedString("notification_streak_milestone_body", comment: ""), milestone)
            content.sound = .default
            content.categoryIdentifier = "STREAK_MILESTONE"
            
            // Store as a template - will be triggered programmatically
        }
    }
    
    /// Send streak milestone notification
    func sendStreakMilestone(days: Int) async {
        let identifier = "streak_achieved_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_streak_milestone_title", comment: "")
        content.body = String(format: NSLocalizedString("notification_streak_milestone_body", comment: ""), days)
        content.sound = .default
        content.categoryIdentifier = "STREAK_MILESTONE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    // MARK: - 4. Motivation Messages
    
    /// Schedule motivational notifications
    private func scheduleMotivationMessages(for profile: UserProfile) async {
        let messages = [
            NSLocalizedString("motivation_great_start", comment: ""),
            NSLocalizedString("motivation_keep_going", comment: ""),
            NSLocalizedString("motivation_almost_there", comment: ""),
            NSLocalizedString("motivation_consistency", comment: "")
        ]
        
        // Schedule motivation messages for days when user typically misses workouts
        for (index, message) in messages.enumerated() {
            let identifier = "motivation_\(index)"
            
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification_motivation_title", comment: "")
            content.body = message
            content.sound = .default
            content.categoryIdentifier = "MOTIVATION"
            
            // Schedule randomly throughout the week
            var dateComponents = DateComponents()
            dateComponents.weekday = (index % 7) + 1
            dateComponents.hour = profile.preferredTimes.first?.defaultHour ?? 9
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            try? await notificationCenter.add(request)
        }
    }
    
    /// Send personalized motivation message
    func sendMotivationMessage(_ message: String) async {
        let identifier = "motivation_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notification_motivation_title", comment: "")
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "MOTIVATION"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    // MARK: - 5. Check-in Prompts
    
    /// Schedule weekly check-in prompt notifications
    private func scheduleCheckInPrompts() async {
        let identifier = "weekly_checkin"
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("checkin_title", comment: "")
        content.body = NSLocalizedString("checkin_subtitle", comment: "")
        content.sound = .default
        content.categoryIdentifier = "CHECKIN_PROMPT"
        
        // Schedule for Sunday at 6 PM (NLP check-in time)
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 18    // 6 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    /// Send immediate check-in prompt
    func sendCheckInPrompt() async {
        let identifier = "checkin_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("checkin_title", comment: "")
        content.body = NSLocalizedString("checkin_subtitle", comment: "")
        content.sound = .default
        content.categoryIdentifier = "CHECKIN_PROMPT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    // MARK: - 6. Adaptive Alerts
    
    /// Schedule adaptive behavior notifications
    private func scheduleAdaptiveAlerts() async {
        // These are triggered programmatically based on user behavior
        // Pre-configure notification categories for different adaptive scenarios
        
        let categories = [
            createNotificationCategory(
                identifier: "ADAPTIVE_DIFFICULTY",
                actions: [
                    UNNotificationAction(identifier: "ACCEPT", title: "Accept", options: []),
                    UNNotificationAction(identifier: "DECLINE", title: "Keep Current", options: [])
                ]
            ),
            createNotificationCategory(
                identifier: "ADAPTIVE_REST",
                actions: [
                    UNNotificationAction(identifier: "TAKE_REST", title: "Take Rest Day", options: []),
                    UNNotificationAction(identifier: "CONTINUE", title: "Continue Plan", options: [])
                ]
            ),
            createNotificationCategory(
                identifier: "ADAPTIVE_SCHEDULE",
                actions: [
                    UNNotificationAction(identifier: "RESCHEDULE", title: "Reschedule", options: []),
                    UNNotificationAction(identifier: "SKIP", title: "Skip Today", options: [])
                ]
            )
        ]
        
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    /// Send adaptive difficulty adjustment notification
    func sendAdaptiveDifficultyAlert(increase: Bool) async {
        let identifier = "adaptive_difficulty_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = "Workout Adjustment"
        content.body = increase 
            ? NSLocalizedString("adaptive_difficulty_increased", comment: "")
            : NSLocalizedString("adaptive_difficulty_decreased", comment: "")
        content.sound = .default
        content.categoryIdentifier = "ADAPTIVE_DIFFICULTY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    /// Send adaptive rest day suggestion
    func sendAdaptiveRestDayAlert() async {
        let identifier = "adaptive_rest_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = "Recovery Recommendation"
        content.body = NSLocalizedString("adaptive_rest_day_suggested", comment: "")
        content.sound = .default
        content.categoryIdentifier = "ADAPTIVE_REST"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    /// Send adaptive schedule modification alert
    func sendAdaptiveScheduleAlert() async {
        let identifier = "adaptive_schedule_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = "Schedule Conflict"
        content.body = "We noticed a calendar conflict. Would you like to reschedule your workout?"
        content.sound = .default
        content.categoryIdentifier = "ADAPTIVE_SCHEDULE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    // MARK: - Injury Detection Notifications
    
    /// Send injury detection alert
    func sendInjuryDetectionAlert(injuryType: String) async {
        let identifier = "injury_detection_\(Date().timeIntervalSince1970)"
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("injury_detected_title", comment: "")
        content.body = NSLocalizedString("injury_detected_message", comment: "")
        content.sound = .default
        content.categoryIdentifier = "INJURY_DETECTION"
        content.userInfo = ["injuryType": injuryType]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
    
    // MARK: - Helper Methods
    
    private func createNotificationCategory(identifier: String, actions: [UNNotificationAction]) -> UNNotificationCategory {
        return UNNotificationCategory(
            identifier: identifier,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
    }
    
    /// Handle notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        let actionIdentifier = response.actionIdentifier
        
        switch categoryIdentifier {
        case "ADAPTIVE_DIFFICULTY":
            handleAdaptiveDifficultyResponse(actionIdentifier)
        case "ADAPTIVE_REST":
            handleAdaptiveRestResponse(actionIdentifier)
        case "ADAPTIVE_SCHEDULE":
            handleAdaptiveScheduleResponse(actionIdentifier)
        case "WORKOUT_REMINDER":
            handleWorkoutReminderResponse(response)
        case "CHECKIN_PROMPT":
            handleCheckInResponse(response)
        default:
            break
        }
    }
    
    private func handleAdaptiveDifficultyResponse(_ actionIdentifier: String) {
        switch actionIdentifier {
        case "ACCEPT":
            // Apply difficulty adjustment
            NotificationCenter.default.post(name: .adaptiveDifficultyAccepted, object: nil)
        case "DECLINE":
            // Keep current difficulty
            NotificationCenter.default.post(name: .adaptiveDifficultyDeclined, object: nil)
        default:
            break
        }
    }
    
    private func handleAdaptiveRestResponse(_ actionIdentifier: String) {
        switch actionIdentifier {
        case "TAKE_REST":
            NotificationCenter.default.post(name: .adaptiveRestAccepted, object: nil)
        case "CONTINUE":
            NotificationCenter.default.post(name: .adaptiveRestDeclined, object: nil)
        default:
            break
        }
    }
    
    private func handleAdaptiveScheduleResponse(_ actionIdentifier: String) {
        switch actionIdentifier {
        case "RESCHEDULE":
            NotificationCenter.default.post(name: .adaptiveRescheduleRequested, object: nil)
        case "SKIP":
            NotificationCenter.default.post(name: .adaptiveSkipRequested, object: nil)
        default:
            break
        }
    }
    
    private func handleWorkoutReminderResponse(_ response: UNNotificationResponse) {
        if let workoutId = response.notification.request.content.userInfo["workoutId"] as? String {
            NotificationCenter.default.post(
                name: .workoutReminderTapped,
                object: nil,
                userInfo: ["workoutId": workoutId]
            )
        }
    }
    
    private func handleCheckInResponse(_ response: UNNotificationResponse) {
        NotificationCenter.default.post(name: .checkInPromptTapped, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let adaptiveDifficultyAccepted = Notification.Name("adaptiveDifficultyAccepted")
    static let adaptiveDifficultyDeclined = Notification.Name("adaptiveDifficultyDeclined")
    static let adaptiveRestAccepted = Notification.Name("adaptiveRestAccepted")
    static let adaptiveRestDeclined = Notification.Name("adaptiveRestDeclined")
    static let adaptiveRescheduleRequested = Notification.Name("adaptiveRescheduleRequested")
    static let adaptiveSkipRequested = Notification.Name("adaptiveSkipRequested")
    static let workoutReminderTapped = Notification.Name("workoutReminderTapped")
    static let checkInPromptTapped = Notification.Name("checkInPromptTapped")
} 