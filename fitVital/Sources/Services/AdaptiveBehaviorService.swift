//
//  AdaptiveBehaviorService.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import Combine

/// Service for implementing adaptive behavior rules and AI-driven workout modifications
@MainActor
final class AdaptiveBehaviorService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let persistenceController: PersistenceController
    private let notificationService: NotificationService
    
    // MARK: - State
    
    @Published var adaptiveInsights: [AdaptiveInsight] = []
    @Published var behaviorPatterns: UserBehaviorPatterns?
    @Published var currentDifficultyAdjustment: Double = 1.0
    
    // MARK: - Initialization
    
    init(
        persistenceController: PersistenceController = .shared,
        notificationService: NotificationService = NotificationService()
    ) {
        self.persistenceController = persistenceController
        self.notificationService = notificationService
        
        Task {
            await loadBehaviorPatterns()
        }
    }
    
    // MARK: - Adaptive Behavior Analysis
    
    /// Analyze user behavior and trigger adaptive changes
    func analyzeUserBehavior() async {
        do {
            // Load recent workout history
            let recentWorkouts = try await persistenceController.getRecentWorkouts(days: 30)
            let completedWorkouts = recentWorkouts.filter { $0.isCompleted }
            let missedWorkouts = recentWorkouts.filter { !$0.isCompleted && $0.scheduledDate < Date() }
            
            // Analyze patterns
            let patterns = analyzeBehaviorPatterns(
                completed: completedWorkouts,
                missed: missedWorkouts
            )
            
            behaviorPatterns = patterns
            
            // Generate adaptive insights
            let insights = generateAdaptiveInsights(from: patterns)
            adaptiveInsights = insights
            
            // Apply automatic adjustments
            await applyAutomaticAdjustments(based: patterns)
            
        } catch {
            print("Error analyzing user behavior: \(error)")
        }
    }
    
    /// Analyze behavior patterns from workout history
    private func analyzeBehaviorPatterns(
        completed: [Workout],
        missed: [Workout]
    ) -> UserBehaviorPatterns {
        
        let totalWorkouts = completed.count + missed.count
        let completionRate = totalWorkouts > 0 ? Double(completed.count) / Double(totalWorkouts) : 0.0
        
        // Analyze missed workout patterns
        let missedPatterns = analyzeMissedWorkoutPatterns(missed)
        
        // Analyze preferred workout times
        let preferredTimes = analyzePreferredWorkoutTimes(completed)
        
        // Analyze workout type preferences
        let typePreferences = analyzeWorkoutTypePreferences(completed)
        
        // Analyze difficulty tolerance
        let difficultyTolerance = analyzeDifficultyTolerance(completed, missed)
        
        // Analyze streak patterns
        let streakPatterns = analyzeStreakPatterns(completed)
        
        return UserBehaviorPatterns(
            completionRate: completionRate,
            missedWorkoutPatterns: missedPatterns,
            preferredTimes: preferredTimes,
            typePreferences: typePreferences,
            difficultyTolerance: difficultyTolerance,
            streakPatterns: streakPatterns,
            lastAnalyzed: Date()
        )
    }
    
    /// Analyze patterns in missed workouts
    private func analyzeMissedWorkoutPatterns(_ missedWorkouts: [Workout]) -> MissedWorkoutPatterns {
        let calendar = Calendar.current
        
        // Days of week when workouts are most often missed
        var daysMissed: [Int: Int] = [:]
        
        // Times of day when workouts are most often missed
        var timesMissed: [Int: Int] = [:]
        
        // Workout types most often missed
        var typesMissed: [WorkoutType: Int] = [:]
        
        for workout in missedWorkouts {
            let weekday = calendar.component(.weekday, from: workout.scheduledDate)
            let hour = calendar.component(.hour, from: workout.scheduledDate)
            
            daysMissed[weekday, default: 0] += 1
            timesMissed[hour, default: 0] += 1
            typesMissed[workout.type, default: 0] += 1
        }
        
        // Find most problematic day and time
        let mostMissedDay = daysMissed.max(by: { $0.value < $1.value })?.key
        let mostMissedHour = timesMissed.max(by: { $0.value < $1.value })?.key
        let mostMissedType = typesMissed.max(by: { $0.value < $1.value })?.key
        
        return MissedWorkoutPatterns(
            daysMissed: daysMissed,
            timesMissed: timesMissed,
            typesMissed: typesMissed,
            mostProblematicDay: mostMissedDay,
            mostProblematicHour: mostMissedHour,
            mostMissedType: mostMissedType
        )
    }
    
    /// Analyze preferred workout times
    private func analyzePreferredWorkoutTimes(_ completedWorkouts: [Workout]) -> [TimeOfDay: Double] {
        var timePreferences: [TimeOfDay: Int] = [:]
        
        for workout in completedWorkouts {
            let hour = Calendar.current.component(.hour, from: workout.completedAt ?? workout.scheduledDate)
            let timeOfDay = TimeOfDay.from(hour: hour)
            timePreferences[timeOfDay, default: 0] += 1
        }
        
        let total = completedWorkouts.count
        return timePreferences.mapValues { Double($0) / Double(total) }
    }
    
    /// Analyze workout type preferences
    private func analyzeWorkoutTypePreferences(_ completedWorkouts: [Workout]) -> [WorkoutType: Double] {
        var typePreferences: [WorkoutType: Int] = [:]
        
        for workout in completedWorkouts {
            typePreferences[workout.type, default: 0] += 1
        }
        
        let total = completedWorkouts.count
        return typePreferences.mapValues { Double($0) / Double(total) }
    }
    
    /// Analyze difficulty tolerance
    private func analyzeDifficultyTolerance(
        _ completedWorkouts: [Workout],
        _ missedWorkouts: [Workout]
    ) -> DifficultyTolerance {
        
        let completedDifficulties = completedWorkouts.map { $0.difficulty.rawValue }
        let missedDifficulties = missedWorkouts.map { $0.difficulty.rawValue }
        
        let avgCompletedDifficulty = completedDifficulties.isEmpty ? 0 : 
            completedDifficulties.reduce(0, +) / completedDifficulties.count
        
        let avgMissedDifficulty = missedDifficulties.isEmpty ? 0 : 
            missedDifficulties.reduce(0, +) / missedDifficulties.count
        
        let tolerance: DifficultyTolerance.Level
        
        if avgMissedDifficulty > avgCompletedDifficulty + 1 {
            tolerance = .low
        } else if avgCompletedDifficulty > avgMissedDifficulty + 1 {
            tolerance = .high
        } else {
            tolerance = .medium
        }
        
        return DifficultyTolerance(
            level: tolerance,
            avgCompletedDifficulty: avgCompletedDifficulty,
            avgMissedDifficulty: avgMissedDifficulty
        )
    }
    
    /// Analyze streak patterns
    private func analyzeStreakPatterns(_ completedWorkouts: [Workout]) -> StreakPatterns {
        let sortedWorkouts = completedWorkouts.sorted { $0.completedAt ?? $0.scheduledDate < $1.completedAt ?? $1.scheduledDate }
        
        var streaks: [Int] = []
        var currentStreak = 0
        var lastDate: Date?
        
        for workout in sortedWorkouts {
            let workoutDate = workout.completedAt ?? workout.scheduledDate
            
            if let last = lastDate {
                let daysDifference = Calendar.current.dateComponents([.day], from: last, to: workoutDate).day ?? 0
                
                if daysDifference <= 2 { // Allow 1 day gap
                    currentStreak += 1
                } else {
                    if currentStreak > 0 {
                        streaks.append(currentStreak)
                    }
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            lastDate = workoutDate
        }
        
        if currentStreak > 0 {
            streaks.append(currentStreak)
        }
        
        let averageStreak = streaks.isEmpty ? 0 : streaks.reduce(0, +) / streaks.count
        let longestStreak = streaks.max() ?? 0
        
        return StreakPatterns(
            averageStreak: averageStreak,
            longestStreak: longestStreak,
            currentStreak: currentStreak,
            streakBreaks: streaks.count
        )
    }
    
    // MARK: - Adaptive Insights Generation
    
    /// Generate adaptive insights from behavior patterns
    private func generateAdaptiveInsights(from patterns: UserBehaviorPatterns) -> [AdaptiveInsight] {
        var insights: [AdaptiveInsight] = []
        
        // Completion rate insights
        if patterns.completionRate < 0.7 {
            insights.append(AdaptiveInsight(
                type: .completionRate,
                severity: .high,
                title: "Low Completion Rate",
                description: "You're completing \(Int(patterns.completionRate * 100))% of scheduled workouts. Consider reducing workout frequency or intensity.",
                recommendation: "Reduce weekly frequency by 1 day or switch to shorter workouts",
                confidence: 0.8
            ))
        }
        
        // Missed workout pattern insights
        if let mostMissedDay = patterns.missedWorkoutPatterns.mostProblematicDay {
            let dayName = Calendar.current.weekdaySymbols[mostMissedDay - 1]
            insights.append(AdaptiveInsight(
                type: .missedWorkouts,
                severity: .medium,
                title: "Problematic Day Detected",
                description: "You tend to miss workouts on \(dayName)s. Consider rescheduling.",
                recommendation: "Move \(dayName) workouts to a different day",
                confidence: 0.7
            ))
        }
        
        if let mostMissedHour = patterns.missedWorkoutPatterns.mostProblematicHour {
            let timeOfDay = TimeOfDay.from(hour: mostMissedHour)
            insights.append(AdaptiveInsight(
                type: .timing,
                severity: .medium,
                title: "Problematic Time Detected",
                description: "You often miss \(timeOfDay.displayName) workouts. Consider adjusting timing.",
                recommendation: "Schedule workouts at your most successful times",
                confidence: 0.6
            ))
        }
        
        // Difficulty tolerance insights
        switch patterns.difficultyTolerance.level {
        case .low:
            insights.append(AdaptiveInsight(
                type: .difficulty,
                severity: .high,
                title: "Difficulty Too High",
                description: "You're struggling with current workout difficulty.",
                recommendation: "Reduce workout intensity by 20-30%",
                confidence: 0.9
            ))
        case .high:
            insights.append(AdaptiveInsight(
                type: .difficulty,
                severity: .low,
                title: "Ready for More Challenge",
                description: "You're handling current workouts well. Consider increasing difficulty.",
                recommendation: "Gradually increase workout intensity",
                confidence: 0.7
            ))
        case .medium:
            break
        }
        
        // Streak pattern insights
        if patterns.streakPatterns.averageStreak < 3 {
            insights.append(AdaptiveInsight(
                type: .consistency,
                severity: .medium,
                title: "Consistency Challenge",
                description: "Your workout streaks are short. Focus on building consistency.",
                recommendation: "Set smaller, more achievable daily goals",
                confidence: 0.8
            ))
        }
        
        return insights
    }
    
    // MARK: - Automatic Adjustments
    
    /// Apply automatic adjustments based on behavior patterns
    private func applyAutomaticAdjustments(based patterns: UserBehaviorPatterns) async {
        // Missed workout adjustments
        if patterns.completionRate < 0.6 {
            await adjustForMissedWorkouts(patterns)
        }
        
        // Difficulty adjustments
        await adjustDifficulty(based: patterns.difficultyTolerance)
        
        // Schedule optimizations
        await optimizeSchedule(based: patterns)
        
        // Send notifications about adjustments
        await notifyUserOfAdjustments()
    }
    
    /// Adjust workout plan for users missing too many workouts
    private func adjustForMissedWorkouts(_ patterns: UserBehaviorPatterns) async {
        let adjustmentFactor = 1.0 - (0.7 - patterns.completionRate) // Reduce intensity
        currentDifficultyAdjustment = max(0.5, adjustmentFactor)
        
        // Reduce workout frequency if completion rate is very low
        if patterns.completionRate < 0.5 {
            await notificationService.sendAdaptiveScheduleAlert()
        }
        
        // Send motivational message
        await notificationService.sendMotivationMessage(
            "We've noticed you've missed some workouts. Don't worry - we're adjusting your plan to better fit your schedule."
        )
    }
    
    /// Adjust workout difficulty based on tolerance analysis
    private func adjustDifficulty(based tolerance: DifficultyTolerance) async {
        switch tolerance.level {
        case .low:
            currentDifficultyAdjustment = max(0.6, currentDifficultyAdjustment - 0.2)
            await notificationService.sendAdaptiveDifficultyAlert(increase: false)
            
        case .high:
            currentDifficultyAdjustment = min(1.4, currentDifficultyAdjustment + 0.1)
            await notificationService.sendAdaptiveDifficultyAlert(increase: true)
            
        case .medium:
            // No adjustment needed
            break
        }
    }
    
    /// Optimize workout schedule based on patterns
    private func optimizeSchedule(based patterns: UserBehaviorPatterns) async {
        // If user has problematic days, suggest rescheduling
        if let problematicDay = patterns.missedWorkoutPatterns.mostProblematicDay,
           patterns.missedWorkoutPatterns.daysMissed[problematicDay, default: 0] > 2 {
            
            // Find best performing day to suggest as alternative
            let completedByDay = patterns.preferredTimes.keys.map { _ in
                // Logic to find best day would go here
                // For now, suggest moving to next day
                return (problematicDay % 7) + 1
            }
            
            await notificationService.sendAdaptiveScheduleAlert()
        }
    }
    
    /// Notify user of adaptive adjustments
    private func notifyUserOfAdjustments() async {
        if abs(currentDifficultyAdjustment - 1.0) > 0.1 {
            let message = currentDifficultyAdjustment > 1.0 
                ? "We've increased your workout intensity based on your progress!"
                : "We've adjusted your workout intensity to better match your current capacity."
            
            await notificationService.sendMotivationMessage(message)
        }
    }
    
    // MARK: - Injury-Based Adaptations
    
    /// Adapt workout plan based on detected injuries
    func adaptForInjury(_ injuryType: String, affectedBodyParts: [String]) async {
        do {
            // Get current workout plan
            let upcomingWorkouts = try await persistenceController.getUpcomingWorkouts()
            
            // Create modified workouts that avoid injured areas
            let modifiedWorkouts = createInjuryAdaptedWorkouts(
                from: upcomingWorkouts,
                avoiding: affectedBodyParts
            )
            
            // Save modified workouts
            for workout in modifiedWorkouts {
                try await persistenceController.updateWorkout(workout)
            }
            
            // Notify user of modifications
            await notificationService.sendInjuryDetectionAlert(injuryType: injuryType)
            
        } catch {
            print("Error adapting for injury: \(error)")
        }
    }
    
    /// Create injury-adapted workouts
    private func createInjuryAdaptedWorkouts(
        from workouts: [Workout],
        avoiding bodyParts: [String]
    ) -> [Workout] {
        
        return workouts.map { workout in
            var modifiedWorkout = workout
            
            // Filter out exercises that target injured body parts
            let safeExercises = workout.exercises.filter { exercise in
                !exercise.targetMuscles.contains { muscle in
                    bodyParts.contains(muscle.rawValue.lowercased())
                }
            }
            
            // If too many exercises removed, add alternative exercises
            if safeExercises.count < workout.exercises.count / 2 {
                // Add rehabilitation exercises
                let rehabExercises = generateRehabExercises(for: bodyParts)
                modifiedWorkout.exercises = safeExercises + rehabExercises
            } else {
                modifiedWorkout.exercises = safeExercises
            }
            
            // Reduce overall intensity
            modifiedWorkout.difficulty = Difficulty(rawValue: max(1, workout.difficulty.rawValue - 1)) ?? .beginner
            
            return modifiedWorkout
        }
    }
    
    /// Generate rehabilitation exercises for injured body parts
    private func generateRehabExercises(for bodyParts: [String]) -> [Exercise] {
        var rehabExercises: [Exercise] = []
        
        for bodyPart in bodyParts {
            switch bodyPart.lowercased() {
            case "shoulder":
                rehabExercises.append(Exercise(
                    id: UUID(),
                    name: "Shoulder Rolls",
                    category: .shoulders,
                    instructions: "Gentle shoulder mobility exercise",
                    targetMuscles: [.shoulders],
                    sets: 2,
                    reps: 10,
                    duration: 0,
                    restPeriod: 30
                ))
                
            case "back", "lower back":
                rehabExercises.append(Exercise(
                    id: UUID(),
                    name: "Cat-Cow Stretch",
                    category: .back,
                    instructions: "Gentle back mobility exercise",
                    targetMuscles: [.back],
                    sets: 2,
                    reps: 10,
                    duration: 0,
                    restPeriod: 30
                ))
                
            case "knee":
                rehabExercises.append(Exercise(
                    id: UUID(),
                    name: "Seated Leg Extensions",
                    category: .legs,
                    instructions: "Gentle knee strengthening",
                    targetMuscles: [.quadriceps],
                    sets: 2,
                    reps: 8,
                    duration: 0,
                    restPeriod: 45
                ))
                
            default:
                rehabExercises.append(Exercise(
                    id: UUID(),
                    name: "Gentle Stretching",
                    category: .flexibility,
                    instructions: "Light stretching for recovery",
                    targetMuscles: [.core],
                    sets: 1,
                    reps: 0,
                    duration: 60,
                    restPeriod: 0
                ))
            }
        }
        
        return rehabExercises
    }
    
    // MARK: - Workout Modifications
    
    /// Apply workout modifications from check-in
    func applyModifications(_ modifications: [WorkoutModification]) async {
        for modification in modifications {
            await applyModification(modification)
        }
    }
    
    /// Apply individual workout modification
    private func applyModification(_ modification: WorkoutModification) async {
        switch modification.type {
        case .reduceIntensity:
            currentDifficultyAdjustment = max(0.5, currentDifficultyAdjustment - 0.2)
            
        case .increaseIntensity:
            currentDifficultyAdjustment = min(1.5, currentDifficultyAdjustment + 0.1)
            
        case .addRecovery:
            await addRecoveryDays()
            
        case .shorterWorkouts:
            await shortenWorkouts()
            
        case .varietyIncrease:
            await increaseWorkoutVariety()
            
        case .injuryModification:
            // Handle via separate injury adaptation flow
            break
        }
    }
    
    /// Add recovery days to workout plan
    private func addRecoveryDays() async {
        // Implementation would add rest days between intense workouts
        await notificationService.sendAdaptiveRestDayAlert()
    }
    
    /// Shorten workout durations
    private func shortenWorkouts() async {
        // Implementation would reduce workout duration by 20-30%
        do {
            let upcomingWorkouts = try await persistenceController.getUpcomingWorkouts()
            
            for workout in upcomingWorkouts {
                var modifiedWorkout = workout
                // Reduce exercise count or duration
                let targetExerciseCount = max(3, workout.exercises.count * 2 / 3)
                modifiedWorkout.exercises = Array(workout.exercises.prefix(targetExerciseCount))
                
                try await persistenceController.updateWorkout(modifiedWorkout)
            }
        } catch {
            print("Error shortening workouts: \(error)")
        }
    }
    
    /// Increase workout variety
    private func increaseWorkoutVariety() async {
        // Implementation would suggest different workout types
        // For now, just send a motivational message
        await notificationService.sendMotivationMessage(
            "We're adding more variety to your workouts to keep things interesting!"
        )
    }
    
    // MARK: - Data Persistence
    
    /// Load existing behavior patterns
    private func loadBehaviorPatterns() async {
        do {
            behaviorPatterns = try await persistenceController.loadBehaviorPatterns()
        } catch {
            // Create default patterns if none exist
            behaviorPatterns = UserBehaviorPatterns.default
        }
    }
    
    /// Save behavior patterns
    func saveBehaviorPatterns() async {
        guard let patterns = behaviorPatterns else { return }
        
        do {
            try await persistenceController.saveBehaviorPatterns(patterns)
        } catch {
            print("Error saving behavior patterns: \(error)")
        }
    }
}

// MARK: - Supporting Types

/// User behavior patterns analysis
struct UserBehaviorPatterns: Codable {
    let completionRate: Double
    let missedWorkoutPatterns: MissedWorkoutPatterns
    let preferredTimes: [TimeOfDay: Double]
    let typePreferences: [WorkoutType: Double]
    let difficultyTolerance: DifficultyTolerance
    let streakPatterns: StreakPatterns
    let lastAnalyzed: Date
    
    static let `default` = UserBehaviorPatterns(
        completionRate: 0.8,
        missedWorkoutPatterns: MissedWorkoutPatterns.default,
        preferredTimes: [.morning: 0.6, .evening: 0.4],
        typePreferences: [.strength: 0.5, .cardio: 0.3, .flexibility: 0.2],
        difficultyTolerance: DifficultyTolerance.default,
        streakPatterns: StreakPatterns.default,
        lastAnalyzed: Date()
    )
}

/// Patterns in missed workouts
struct MissedWorkoutPatterns: Codable {
    let daysMissed: [Int: Int]
    let timesMissed: [Int: Int]
    let typesMissed: [WorkoutType: Int]
    let mostProblematicDay: Int?
    let mostProblematicHour: Int?
    let mostMissedType: WorkoutType?
    
    static let `default` = MissedWorkoutPatterns(
        daysMissed: [:],
        timesMissed: [:],
        typesMissed: [:],
        mostProblematicDay: nil,
        mostProblematicHour: nil,
        mostMissedType: nil
    )
}

/// Difficulty tolerance analysis
struct DifficultyTolerance: Codable {
    enum Level: String, Codable {
        case low, medium, high
    }
    
    let level: Level
    let avgCompletedDifficulty: Int
    let avgMissedDifficulty: Int
    
    static let `default` = DifficultyTolerance(
        level: .medium,
        avgCompletedDifficulty: 2,
        avgMissedDifficulty: 2
    )
}

/// Workout streak patterns
struct StreakPatterns: Codable {
    let averageStreak: Int
    let longestStreak: Int
    let currentStreak: Int
    let streakBreaks: Int
    
    static let `default` = StreakPatterns(
        averageStreak: 3,
        longestStreak: 7,
        currentStreak: 0,
        streakBreaks: 0
    )
}

/// Adaptive insight
struct AdaptiveInsight: Codable, Identifiable {
    enum InsightType: String, Codable {
        case completionRate, missedWorkouts, timing, difficulty, consistency
    }
    
    enum Severity: String, Codable {
        case low, medium, high
    }
    
    let id = UUID()
    let type: InsightType
    let severity: Severity
    let title: String
    let description: String
    let recommendation: String
    let confidence: Double
}

/// Extension for TimeOfDay to support hour conversion
extension TimeOfDay {
    static func from(hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<12:
            return .morning
        case 12..<17:
            return .afternoon
        default:
            return .evening
        }
    }
} 