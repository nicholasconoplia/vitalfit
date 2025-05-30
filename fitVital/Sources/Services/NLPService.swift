//
//  NLPService.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import NaturalLanguage

// MARK: - Protocol Definition

/// Protocol for natural language processing and adaptive behavior
protocol NLPServiceProtocol: Sendable {
    /// Parse user check-in text for insights and busy periods
    @Sendable func parseCheckIn(_ text: String) async -> CheckInAnalysis
    
    /// Extract date intervals from natural language
    @Sendable func extractDateIntervals(from text: String) async -> [DateInterval]
    
    /// Analyze sentiment of user feedback
    @Sendable func analyzeSentiment(_ text: String) async -> SentimentAnalysis
    
    /// Extract physical limitations or injuries from text
    @Sendable func extractPhysicalLimitations(from text: String) async -> [String]
    
    /// Generate adaptive recommendations based on analysis
    @Sendable func generateRecommendations(from analysis: CheckInAnalysis) async -> [AdaptiveRecommendation]
}

// MARK: - Implementation

/// Actor-based NLP service for thread-safe text processing
actor NLPService: NLPServiceProtocol {
    
    /// Shared instance for app-wide use
    static let shared = NLPService()
    
    private init() {}
    
    /// Parse user check-in text for insights and busy periods
    @Sendable func parseCheckIn(_ text: String) async -> CheckInAnalysis {
        let sentiment = await analyzeSentiment(text)
        let dateIntervals = await extractDateIntervals(from: text)
        let physicalLimitations = await extractPhysicalLimitations(from: text)
        let workoutFeedback = await extractWorkoutFeedback(from: text)
        let busyPeriods = await extractBusyPeriods(from: text)
        
        return CheckInAnalysis(
            originalText: text,
            sentiment: sentiment,
            extractedDateIntervals: dateIntervals,
            physicalLimitations: physicalLimitations,
            workoutFeedback: workoutFeedback,
            busyPeriods: busyPeriods,
            processedAt: Date()
        )
    }
    
    /// Extract date intervals from natural language
    @Sendable func extractDateIntervals(from text: String) async -> [DateInterval] {
        var intervals: [DateInterval] = []
        
        // Use NLDataDetector to find dates
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        let calendar = Calendar.current
        
        for match in matches ?? [] {
            if let date = match.date {
                // Create a default duration for single dates
                let interval = DateInterval(start: date, duration: 24 * 60 * 60) // 1 day
                intervals.append(interval)
            }
        }
        
        // Parse common patterns like "next week", "this weekend", etc.
        let commonPatterns = parseCommonDatePatterns(text)
        intervals.append(contentsOf: commonPatterns)
        
        return intervals
    }
    
    /// Analyze sentiment of user feedback
    @Sendable func analyzeSentiment(_ text: String) async -> SentimentAnalysis {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, confidence) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        let score = Double(sentiment?.rawValue ?? "0") ?? 0.0
        let polarity: SentimentPolarity
        
        if score > 0.1 {
            polarity = .positive
        } else if score < -0.1 {
            polarity = .negative
        } else {
            polarity = .neutral
        }
        
        return SentimentAnalysis(
            polarity: polarity,
            score: score,
            confidence: confidence?.rawValue.flatMap(Double.init) ?? 0.0
        )
    }
    
    /// Extract physical limitations or injuries from text
    @Sendable func extractPhysicalLimitations(from text: String) async -> [String] {
        let lowercasedText = text.lowercased()
        var limitations: [String] = []
        
        // Common injury/limitation keywords
        let injuryKeywords = [
            "hurt", "pain", "sore", "injured", "strain", "sprain",
            "back pain", "knee pain", "shoulder pain", "ankle",
            "pulled muscle", "tight", "stiff", "ache", "aching"
        ]
        
        let bodyParts = [
            "back", "knee", "shoulder", "ankle", "wrist", "elbow",
            "hip", "neck", "lower back", "upper back"
        ]
        
        for keyword in injuryKeywords {
            if lowercasedText.contains(keyword) {
                // Try to find associated body part
                for bodyPart in bodyParts {
                    if lowercasedText.contains(bodyPart) {
                        limitations.append("\(keyword) - \(bodyPart)")
                        break
                    }
                }
                if !limitations.contains(where: { $0.contains(keyword) }) {
                    limitations.append(keyword)
                }
            }
        }
        
        return Array(Set(limitations)) // Remove duplicates
    }
    
    /// Generate adaptive recommendations based on analysis
    @Sendable func generateRecommendations(from analysis: CheckInAnalysis) async -> [AdaptiveRecommendation] {
        var recommendations: [AdaptiveRecommendation] = []
        
        // Sentiment-based recommendations
        switch analysis.sentiment.polarity {
        case .negative:
            recommendations.append(.reduceDifficulty(reason: "Recent negative feedback"))
            recommendations.append(.addRestDay(reason: "User seems overwhelmed"))
            
        case .positive:
            recommendations.append(.increaseDifficulty(reason: "User feeling confident"))
            
        case .neutral:
            recommendations.append(.maintainCurrent(reason: "Steady progress"))
        }
        
        // Physical limitation recommendations
        if !analysis.physicalLimitations.isEmpty {
            for limitation in analysis.physicalLimitations {
                if limitation.lowercased().contains("back") {
                    recommendations.append(.avoidExercises(exercises: ["deadlifts", "heavy squats"], reason: "Back pain reported"))
                }
                if limitation.lowercased().contains("knee") {
                    recommendations.append(.avoidExercises(exercises: ["jumping", "lunges"], reason: "Knee issues reported"))
                }
            }
        }
        
        // Busy period recommendations
        if analysis.busyPeriods.count > 2 {
            recommendations.append(.shortenWorkouts(reason: "Multiple busy periods detected"))
        }
        
        // Workout feedback recommendations
        for feedback in analysis.workoutFeedback {
            if feedback.contains("too hard") || feedback.contains("difficult") {
                recommendations.append(.reduceDifficulty(reason: "Workout reported as too difficult"))
            }
            if feedback.contains("too easy") || feedback.contains("boring") {
                recommendations.append(.increaseDifficulty(reason: "Workout reported as too easy"))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Private Helper Methods
    
    /// Extract workout-specific feedback from text
    private func extractWorkoutFeedback(from text: String) async -> [String] {
        let lowercasedText = text.lowercased()
        var feedback: [String] = []
        
        let workoutKeywords = [
            "workout", "exercise", "training", "session"
        ]
        
        let feedbackKeywords = [
            "too hard", "too easy", "difficult", "challenging",
            "boring", "fun", "enjoyed", "hated", "loved",
            "tired", "energized", "sore", "great"
        ]
        
        // Look for workout-related feedback
        for workoutKeyword in workoutKeywords {
            if lowercasedText.contains(workoutKeyword) {
                for feedbackKeyword in feedbackKeywords {
                    if lowercasedText.contains(feedbackKeyword) {
                        feedback.append("\(workoutKeyword) was \(feedbackKeyword)")
                    }
                }
            }
        }
        
        return feedback
    }
    
    /// Extract busy periods from text
    private func extractBusyPeriods(from text: String) async -> [String] {
        let lowercasedText = text.lowercased()
        var busyPeriods: [String] = []
        
        let busyKeywords = [
            "busy", "meetings", "travel", "conference", "deadline",
            "work trip", "vacation", "out of town", "visiting"
        ]
        
        for keyword in busyKeywords {
            if lowercasedText.contains(keyword) {
                busyPeriods.append(keyword)
            }
        }
        
        return busyPeriods
    }
    
    /// Parse common date patterns like "next week", "this weekend"
    private func parseCommonDatePatterns(_ text: String) -> [DateInterval] {
        let lowercasedText = text.lowercased()
        var intervals: [DateInterval] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Next week
        if lowercasedText.contains("next week") {
            if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) {
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: nextWeek)?.start ?? nextWeek
                let interval = DateInterval(start: startOfWeek, duration: 7 * 24 * 60 * 60)
                intervals.append(interval)
            }
        }
        
        // This weekend
        if lowercasedText.contains("this weekend") || lowercasedText.contains("weekend") {
            if let saturday = calendar.nextDate(after: now, matching: .init(weekday: 7), matchingPolicy: .nextTime) {
                let interval = DateInterval(start: saturday, duration: 2 * 24 * 60 * 60) // Sat-Sun
                intervals.append(interval)
            }
        }
        
        // Tomorrow
        if lowercasedText.contains("tomorrow") {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                let interval = DateInterval(start: tomorrow, duration: 24 * 60 * 60)
                intervals.append(interval)
            }
        }
        
        return intervals
    }
}

// MARK: - Data Models

/// Analysis result of user check-in text
struct CheckInAnalysis: Codable, Sendable {
    let originalText: String
    let sentiment: SentimentAnalysis
    let extractedDateIntervals: [DateInterval]
    let physicalLimitations: [String]
    let workoutFeedback: [String]
    let busyPeriods: [String]
    let processedAt: Date
}

/// Sentiment analysis result
struct SentimentAnalysis: Codable, Sendable {
    let polarity: SentimentPolarity
    let score: Double // -1.0 to 1.0
    let confidence: Double // 0.0 to 1.0
}

/// Sentiment polarity
enum SentimentPolarity: String, Codable, Sendable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    
    var emoji: String {
        switch self {
        case .positive: return "😊"
        case .negative: return "😔"
        case .neutral: return "😐"
        }
    }
}

/// Adaptive recommendations based on NLP analysis
enum AdaptiveRecommendation: Codable, Sendable {
    case reduceDifficulty(reason: String)
    case increaseDifficulty(reason: String)
    case addRestDay(reason: String)
    case shortenWorkouts(reason: String)
    case avoidExercises(exercises: [String], reason: String)
    case maintainCurrent(reason: String)
    
    var title: String {
        switch self {
        case .reduceDifficulty: return "Reduce Difficulty"
        case .increaseDifficulty: return "Increase Challenge"
        case .addRestDay: return "Add Rest Day"
        case .shortenWorkouts: return "Shorter Workouts"
        case .avoidExercises: return "Modify Exercises"
        case .maintainCurrent: return "Keep Current Plan"
        }
    }
    
    var description: String {
        switch self {
        case .reduceDifficulty(let reason): return reason
        case .increaseDifficulty(let reason): return reason
        case .addRestDay(let reason): return reason
        case .shortenWorkouts(let reason): return reason
        case .avoidExercises(_, let reason): return reason
        case .maintainCurrent(let reason): return reason
        }
    }
}

// MARK: - Extension for DateInterval Codable

extension DateInterval: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let start = try container.decode(Date.self, forKey: .start)
        let duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.init(start: start, duration: duration)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(start, forKey: .start)
        try container.encode(duration, forKey: .duration)
    }
    
    private enum CodingKeys: String, CodingKey {
        case start, duration
    }
} 