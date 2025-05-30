//
//  CheckInViewModel.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI
import NaturalLanguage

/// View model for managing weekly check-in flow
@MainActor
@Observable
final class CheckInViewModel {
    
    // MARK: - State
    
    /// Current check-in step
    var currentStep: CheckInStep = .welcome
    
    /// Whether check-in is complete
    var isCheckInComplete = false
    
    /// Loading state for processing
    var isLoading = false
    
    /// Error state
    var error: CheckInError?
    
    /// Whether to show error alert
    var showError = false
    
    // MARK: - Check-in Data
    
    /// Energy level rating (1-5)
    var energyLevel: Int = 3
    
    /// Muscle soreness rating (1-5)
    var soreness: Int = 1
    
    /// Motivation level rating (1-5)
    var motivation: Int = 3
    
    /// Free-form text feedback
    var feedback: String = ""
    
    /// Detected injuries or pain points
    var injuryKeywords: [String] = []
    
    /// User's goal for next week
    var nextWeekGoal: String = ""
    
    /// Suggested workout modifications
    var suggestedModifications: [WorkoutModification] = []
    
    /// NLP analysis results
    var nlpInsights: NLPInsights?
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let notificationService: NotificationService
    private let adaptiveService: AdaptiveBehaviorService
    
    // MARK: - Initialization
    
    init(
        persistenceController: PersistenceController = .shared,
        notificationService: NotificationService = NotificationService(),
        adaptiveService: AdaptiveBehaviorService = AdaptiveBehaviorService()
    ) {
        self.persistenceController = persistenceController
        self.notificationService = notificationService
        self.adaptiveService = adaptiveService
    }
    
    // MARK: - Navigation
    
    /// Move to next check-in step
    func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                currentStep = .ratings
            case .ratings:
                currentStep = .feedback
            case .feedback:
                currentStep = .goals
            case .goals:
                Task {
                    await processCheckIn()
                }
            case .insights:
                currentStep = .complete
            case .complete:
                completeCheckIn()
            }
        }
    }
    
    /// Move to previous step
    func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .welcome:
                break
            case .ratings:
                currentStep = .welcome
            case .feedback:
                currentStep = .ratings
            case .goals:
                currentStep = .feedback
            case .insights:
                currentStep = .goals
            case .complete:
                currentStep = .insights
            }
        }
    }
    
    // MARK: - Data Processing
    
    /// Process the check-in with NLP analysis
    private func processCheckIn() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Perform NLP analysis on feedback
            await performNLPAnalysis()
            
            // Detect injury keywords
            detectInjuries()
            
            // Generate adaptive insights
            await generateAdaptiveInsights()
            
            // Save check-in data
            try await saveCheckInData()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .insights
            }
            
        } catch {
            self.error = .processingFailed
            showError = true
        }
    }
    
    /// Perform natural language processing on user feedback
    private func performNLPAnalysis() async {
        guard !feedback.isEmpty else { return }
        
        let nlpInsights = NLPInsights()
        
        // Sentiment Analysis
        let sentimentPredictor = NLSentimentPredictor()
        let sentiment = sentimentPredictor.prediction(for: feedback)
        nlpInsights.sentiment = sentiment
        
        // Key phrase extraction
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = feedback
        
        var keywords: [String] = []
        let range = feedback.startIndex..<feedback.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag, tag == .noun || tag == .adjective {
                let keyword = String(feedback[tokenRange])
                if keyword.count > 3 {
                    keywords.append(keyword.lowercased())
                }
            }
            return true
        }
        
        nlpInsights.keywords = keywords
        
        // Pain/injury detection
        let painKeywords = detectPainKeywords(in: feedback)
        nlpInsights.painIndicators = painKeywords
        
        // Motivation indicators
        let motivationScore = calculateMotivationScore(from: feedback)
        nlpInsights.motivationScore = motivationScore
        
        self.nlpInsights = nlpInsights
    }
    
    /// Detect pain and injury keywords in feedback
    private func detectPainKeywords(in text: String) -> [String] {
        let painKeywords = [
            "pain", "hurt", "sore", "ache", "injury", "injured",
            "strain", "sprain", "tight", "stiff", "uncomfortable",
            "shoulder", "back", "knee", "ankle", "wrist", "neck",
            "hip", "elbow", "lower back", "upper back"
        ]
        
        let lowercaseText = text.lowercased()
        var detectedKeywords: [String] = []
        
        for keyword in painKeywords {
            if lowercaseText.contains(keyword) {
                detectedKeywords.append(keyword)
            }
        }
        
        return detectedKeywords
    }
    
    /// Calculate motivation score from text
    private func calculateMotivationScore(from text: String) -> Double {
        let positiveWords = [
            "great", "good", "amazing", "excellent", "motivated",
            "strong", "energetic", "ready", "excited", "confident"
        ]
        
        let negativeWords = [
            "tired", "exhausted", "difficult", "hard", "struggling",
            "weak", "unmotivated", "stressed", "busy", "overwhelmed"
        ]
        
        let lowercaseText = text.lowercased()
        var score = 0.5 // neutral baseline
        
        for word in positiveWords {
            if lowercaseText.contains(word) {
                score += 0.1
            }
        }
        
        for word in negativeWords {
            if lowercaseText.contains(word) {
                score -= 0.1
            }
        }
        
        return max(0.0, min(1.0, score))
    }
    
    /// Detect specific injuries from user input
    private func detectInjuries() {
        guard let insights = nlpInsights else { return }
        
        let bodyParts = ["shoulder", "back", "knee", "ankle", "wrist", "neck", "hip", "elbow"]
        let painWords = ["pain", "hurt", "sore", "ache", "injury", "strain"]
        
        var detected: [String] = []
        
        for bodyPart in bodyParts {
            for painWord in painWords {
                if feedback.lowercased().contains("\(painWord) \(bodyPart)") ||
                   feedback.lowercased().contains("\(bodyPart) \(painWord)") {
                    detected.append("\(bodyPart) \(painWord)")
                }
            }
        }
        
        injuryKeywords = detected
        
        // Send injury notification if detected
        if !detected.isEmpty {
            Task {
                await notificationService.sendInjuryDetectionAlert(
                    injuryType: detected.first ?? "general pain"
                )
            }
        }
    }
    
    /// Generate adaptive insights based on check-in data
    private func generateAdaptiveInsights() async {
        var modifications: [WorkoutModification] = []
        
        // Energy-based modifications
        if energyLevel <= 2 {
            modifications.append(WorkoutModification(
                type: .reduceIntensity,
                reason: "Low energy levels detected",
                suggestion: "Reduce workout intensity by 20-30%"
            ))
        } else if energyLevel >= 4 {
            modifications.append(WorkoutModification(
                type: .increaseIntensity,
                reason: "High energy levels detected",
                suggestion: "Consider increasing workout intensity"
            ))
        }
        
        // Soreness-based modifications
        if soreness >= 4 {
            modifications.append(WorkoutModification(
                type: .addRecovery,
                reason: "High muscle soreness reported",
                suggestion: "Add extra rest days and focus on recovery"
            ))
        }
        
        // Motivation-based modifications
        if motivation <= 2 {
            modifications.append(WorkoutModification(
                type: .shorterWorkouts,
                reason: "Low motivation detected",
                suggestion: "Switch to shorter, more achievable workouts"
            ))
        }
        
        // NLP-based modifications
        if let insights = nlpInsights {
            if insights.sentiment.label == "Negative" {
                modifications.append(WorkoutModification(
                    type: .varietyIncrease,
                    reason: "Negative sentiment detected",
                    suggestion: "Add more variety to keep workouts engaging"
                ))
            }
            
            if !insights.painIndicators.isEmpty {
                modifications.append(WorkoutModification(
                    type: .injuryModification,
                    reason: "Pain indicators found in feedback",
                    suggestion: "Modify workouts to avoid aggravating affected areas"
                ))
            }
        }
        
        // Injury-based modifications
        if !injuryKeywords.isEmpty {
            modifications.append(WorkoutModification(
                type: .injuryModification,
                reason: "Specific injuries mentioned",
                suggestion: "Create rehabilitation-focused workout plan"
            ))
        }
        
        suggestedModifications = modifications
        
        // Apply modifications to user's plan
        await adaptiveService.applyModifications(modifications)
    }
    
    /// Save check-in data to persistence
    private func saveCheckInData() async throws {
        let checkIn = WeeklyCheckIn(
            date: Date(),
            energyLevel: energyLevel,
            soreness: soreness,
            motivation: motivation,
            feedback: feedback,
            injuryKeywords: injuryKeywords,
            nextWeekGoal: nextWeekGoal,
            nlpInsights: nlpInsights,
            suggestedModifications: suggestedModifications
        )
        
        try await persistenceController.saveCheckIn(checkIn)
    }
    
    /// Complete the check-in flow
    private func completeCheckIn() {
        isCheckInComplete = true
        
        // Schedule follow-up notification
        Task {
            await notificationService.sendMotivationMessage(
                "Thanks for your check-in! Your plan has been updated based on your feedback."
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current step progress
    var progressPercentage: Double {
        let stepIndex = CheckInStep.allCases.firstIndex(of: currentStep) ?? 0
        return Double(stepIndex) / Double(CheckInStep.allCases.count - 1)
    }
    
    /// Whether current step can proceed
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .ratings:
            return true // Ratings always have default values
        case .feedback:
            return true // Feedback is optional
        case .goals:
            return true // Goals are optional
        case .insights:
            return true
        case .complete:
            return true
        }
    }
    
    /// Current step is last
    var isLastStep: Bool {
        currentStep == .complete
    }
    
    /// Energy level description
    var energyLevelDescription: String {
        switch energyLevel {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Very High"
        default: return "Moderate"
        }
    }
    
    /// Soreness level description
    var sorenessDescription: String {
        switch soreness {
        case 1: return "None"
        case 2: return "Mild"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Severe"
        default: return "None"
        }
    }
    
    /// Motivation level description
    var motivationDescription: String {
        switch motivation {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "High"
        case 5: return "Very High"
        default: return "Moderate"
        }
    }
    
    // MARK: - Actions
    
    /// Reset check-in data
    func resetCheckIn() {
        energyLevel = 3
        soreness = 1
        motivation = 3
        feedback = ""
        injuryKeywords = []
        nextWeekGoal = ""
        suggestedModifications = []
        nlpInsights = nil
        currentStep = .welcome
        isCheckInComplete = false
        error = nil
        showError = false
    }
    
    /// Dismiss error
    func dismissError() {
        error = nil
        showError = false
    }
}

// MARK: - Supporting Types

/// Check-in flow steps
enum CheckInStep: String, CaseIterable {
    case welcome = "welcome"
    case ratings = "ratings"
    case feedback = "feedback"
    case goals = "goals"
    case insights = "insights"
    case complete = "complete"
    
    var title: String {
        switch self {
        case .welcome:
            return "Weekly Check-In"
        case .ratings:
            return "How are you feeling?"
        case .feedback:
            return "Tell us more"
        case .goals:
            return "Next week's focus"
        case .insights:
            return "Your personalized insights"
        case .complete:
            return "All set!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return "Let's see how last week went"
        case .ratings:
            return "Rate your energy, soreness, and motivation"
        case .feedback:
            return "Share any additional thoughts or concerns"
        case .goals:
            return "What do you want to focus on next week?"
        case .insights:
            return "Based on your feedback, here's what we recommend"
        case .complete:
            return "Your plan has been updated!"
        }
    }
}

/// Weekly check-in data structure
struct WeeklyCheckIn: Codable {
    let id: UUID = UUID()
    let date: Date
    let energyLevel: Int
    let soreness: Int
    let motivation: Int
    let feedback: String
    let injuryKeywords: [String]
    let nextWeekGoal: String
    let nlpInsights: NLPInsights?
    let suggestedModifications: [WorkoutModification]
}

/// NLP analysis insights
class NLPInsights: Codable {
    var sentiment: NLSentiment = NLSentiment(label: "Neutral", confidence: 0.5)
    var keywords: [String] = []
    var painIndicators: [String] = []
    var motivationScore: Double = 0.5
}

/// Workout modification suggestions
struct WorkoutModification: Codable {
    let type: ModificationType
    let reason: String
    let suggestion: String
}

/// Types of workout modifications
enum ModificationType: String, Codable, CaseIterable {
    case reduceIntensity = "reduceIntensity"
    case increaseIntensity = "increaseIntensity"
    case addRecovery = "addRecovery"
    case shorterWorkouts = "shorterWorkouts"
    case varietyIncrease = "varietyIncrease"
    case injuryModification = "injuryModification"
    
    var displayName: String {
        switch self {
        case .reduceIntensity:
            return "Reduce Intensity"
        case .increaseIntensity:
            return "Increase Intensity"
        case .addRecovery:
            return "Add Recovery"
        case .shorterWorkouts:
            return "Shorter Workouts"
        case .varietyIncrease:
            return "More Variety"
        case .injuryModification:
            return "Injury Accommodation"
        }
    }
}

/// Check-in specific errors
enum CheckInError: LocalizedError {
    case processingFailed
    case saveFailed
    case nlpAnalysisFailed
    
    var errorDescription: String? {
        switch self {
        case .processingFailed:
            return "Failed to process your check-in. Please try again."
        case .saveFailed:
            return "Failed to save your check-in data."
        case .nlpAnalysisFailed:
            return "Failed to analyze your feedback."
        }
    }
} 