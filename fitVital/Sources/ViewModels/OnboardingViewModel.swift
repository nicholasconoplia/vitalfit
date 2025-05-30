//
//  OnboardingViewModel.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI
import EventKit
import UserNotifications

/// View model for managing the onboarding flow
@MainActor
@Observable
final class OnboardingViewModel {
    
    // MARK: - State
    
    /// Current onboarding step
    var currentStep: OnboardingStep = .welcome
    
    /// Whether onboarding is complete
    var isOnboardingComplete = false
    
    /// Loading state for async operations
    var isLoading = false
    
    /// Error state
    var error: OnboardingError?
    
    /// Whether to show error alert
    var showError = false
    
    // MARK: - User Input Data
    
    /// User's name input
    var name = ""
    
    /// Selected fitness goal
    var selectedGoal: FitnessGoal = .stayHealthy
    
    /// Selected weekly frequency
    var selectedFrequency = 3
    
    /// Selected equipment types
    var selectedEquipment: Set<EquipmentType> = [.bodyweight]
    
    /// Selected preferred times
    var selectedTimes: Set<TimeOfDay> = [.morning]
    
    /// Whether calendar permission was granted
    var calendarPermissionGranted = false
    
    /// Whether notification permission was granted
    var notificationPermissionGranted = false
    
    /// Session duration based on frequency
    var sessionDuration: TimeInterval {
        switch selectedFrequency {
        case 1...2: return 60 * 60 // 60 minutes
        case 3...4: return 45 * 60 // 45 minutes
        default: return 30 * 60 // 30 minutes
        }
    }
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let calendarService: CalendarService
    
    // MARK: - Initialization
    
    init(
        persistenceController: PersistenceController = .shared,
        calendarService: CalendarService = CalendarService()
    ) {
        self.persistenceController = persistenceController
        self.calendarService = calendarService
    }
    
    // MARK: - Navigation Actions
    
    /// Move to the next onboarding step
    func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .name
            case .name:
                if isNameValid {
                    currentStep = .goal
                }
            case .goal:
                currentStep = .frequency
            case .frequency:
                currentStep = .equipment
            case .equipment:
                if !selectedEquipment.isEmpty {
                    currentStep = .times
                }
            case .times:
                if !selectedTimes.isEmpty {
                    currentStep = .permissions
                }
            case .permissions:
                Task {
                    await completeOnboarding()
                }
            }
        }
    }
    
    /// Move to the previous onboarding step
    func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                break
            case .name:
                currentStep = .welcome
            case .goal:
                currentStep = .name
            case .frequency:
                currentStep = .goal
            case .equipment:
                currentStep = .frequency
            case .times:
                currentStep = .equipment
            case .permissions:
                currentStep = .times
            }
        }
    }
    
    /// Skip to specific step
    func skipToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }
    
    // MARK: - Validation
    
    /// Whether the current step can proceed
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .name:
            return isNameValid
        case .goal:
            return true
        case .frequency:
            return true
        case .equipment:
            return !selectedEquipment.isEmpty
        case .times:
            return !selectedTimes.isEmpty
        case .permissions:
            return true
        }
    }
    
    /// Whether the name is valid
    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Data Management
    
    /// Reset all onboarding data
    func resetOnboardingData() {
        name = ""
        selectedGoal = .stayHealthy
        selectedFrequency = 3
        selectedEquipment = [.bodyweight]
        selectedTimes = [.morning]
        calendarPermissionGranted = false
        notificationPermissionGranted = false
        currentStep = .welcome
        error = nil
        showError = false
        isOnboardingComplete = false
    }
    
    /// Toggle equipment selection
    func toggleEquipment(_ equipment: EquipmentType) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }
    
    /// Toggle time selection
    func toggleTime(_ time: TimeOfDay) {
        if selectedTimes.contains(time) {
            selectedTimes.remove(time)
        } else {
            selectedTimes.insert(time)
        }
    }
    
    // MARK: - Permissions
    
    /// Request calendar permission
    func requestCalendarPermission() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let granted = try await calendarService.requestPermission()
            calendarPermissionGranted = granted
            
            if !granted {
                error = .calendarPermissionDenied
                showError = true
            }
        } catch {
            self.error = .calendarPermissionFailed
            showError = true
        }
    }
    
    /// Request notification permission
    func requestNotificationPermission() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            notificationPermissionGranted = granted
            
            if !granted {
                error = .notificationPermissionDenied
                showError = true
            }
        } catch {
            self.error = .notificationPermissionFailed
            showError = true
        }
    }
    
    /// Request both permissions
    func requestAllPermissions() async {
        await requestCalendarPermission()
        await requestNotificationPermission()
    }
    
    // MARK: - Onboarding Completion
    
    /// Complete the onboarding process
    private func completeOnboarding() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create user profile
            let profile = UserProfile(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                fitnessGoal: selectedGoal,
                weeklyFrequency: selectedFrequency,
                sessionDuration: sessionDuration,
                equipmentAccess: Array(selectedEquipment),
                preferredTimes: Array(selectedTimes),
                calendarSynced: calendarPermissionGranted
            )
            
            // Save to persistence
            try await persistenceController.saveUserProfile(profile)
            
            // Mark onboarding as complete
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(profile.id.uuidString, forKey: "currentUserID")
            
            // Schedule initial notifications if permission granted
            if notificationPermissionGranted {
                await scheduleInitialNotifications()
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                isOnboardingComplete = true
            }
            
        } catch {
            self.error = .profileCreationFailed
            showError = true
        }
    }
    
    /// Schedule initial workout notifications
    private func scheduleInitialNotifications() async {
        let content = UNMutableNotificationContent()
        content.title = "Welcome to FitVital!"
        content.body = "Your fitness journey starts now. Check out your personalized workout plan."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "welcome", content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Helper Methods
    
    /// Progress percentage for current step
    var progressPercentage: Double {
        let stepIndex = OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
        return Double(stepIndex) / Double(OnboardingStep.allCases.count - 1)
    }
    
    /// Whether current step is the last step
    var isLastStep: Bool {
        currentStep == .permissions
    }
    
    /// Whether current step is the first step
    var isFirstStep: Bool {
        currentStep == .welcome
    }
    
    /// Dismiss error
    func dismissError() {
        error = nil
        showError = false
    }
}

// MARK: - Supporting Types

/// Onboarding steps
enum OnboardingStep: String, CaseIterable {
    case welcome = "welcome"
    case name = "name"
    case goal = "goal"
    case frequency = "frequency"
    case equipment = "equipment"
    case times = "times"
    case permissions = "permissions"
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to FitVital"
        case .name:
            return "What's your name?"
        case .goal:
            return "What's your main goal?"
        case .frequency:
            return "How often do you want to work out?"
        case .equipment:
            return "What equipment do you have?"
        case .times:
            return "When do you prefer to work out?"
        case .permissions:
            return "Enable Features"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return "Your personalized fitness journey starts here"
        case .name:
            return "We'll use this to personalize your experience"
        case .goal:
            return "This helps us create the perfect plan for you"
        case .frequency:
            return "We'll build your schedule around this"
        case .equipment:
            return "We'll customize exercises based on what you have"
        case .times:
            return "We'll schedule workouts at your preferred times"
        case .permissions:
            return "Optional features to enhance your experience"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome:
            return "figure.strengthtraining.traditional"
        case .name:
            return "person.circle"
        case .goal:
            return "target"
        case .frequency:
            return "calendar"
        case .equipment:
            return "dumbbell"
        case .times:
            return "clock"
        case .permissions:
            return "checkmark.shield"
        }
    }
}

/// Onboarding-specific errors
enum OnboardingError: LocalizedError {
    case profileCreationFailed
    case calendarPermissionDenied
    case calendarPermissionFailed
    case notificationPermissionDenied
    case notificationPermissionFailed
    
    var errorDescription: String? {
        switch self {
        case .profileCreationFailed:
            return "Failed to create your profile. Please try again."
        case .calendarPermissionDenied:
            return "Calendar access was denied. You can enable it later in Settings."
        case .calendarPermissionFailed:
            return "Failed to request calendar permission. Please try again."
        case .notificationPermissionDenied:
            return "Notification access was denied. You can enable it later in Settings."
        case .notificationPermissionFailed:
            return "Failed to request notification permission. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .profileCreationFailed:
            return "Check your internet connection and try again."
        case .calendarPermissionDenied, .notificationPermissionDenied:
            return "You can change this in iOS Settings > FitVital later."
        case .calendarPermissionFailed, .notificationPermissionFailed:
            return "Please restart the app and try again."
        }
    }
} 