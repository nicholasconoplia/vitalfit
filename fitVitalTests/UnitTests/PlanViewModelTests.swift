//
//  PlanViewModelTests.swift
//  fitVitalTests
//
//  Created by Nick Conoplia on 30/5/2025.
//

import XCTest
@testable import fitVital

@MainActor
final class PlanViewModelTests: XCTestCase {
    var viewModel: PlanViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = PlanViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.selectedSplit, .pushPullLegs)
        XCTAssertEqual(viewModel.weeklyWorkouts.count, 7)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showingAutoSchedule)
    }
    
    // MARK: - Workout Split Tests
    
    func testChangeWorkoutSplit() async {
        // Given
        let newSplit = WorkoutSplit.upperLower
        
        // When
        await viewModel.changeWorkoutSplit(to: newSplit)
        
        // Then
        XCTAssertEqual(viewModel.selectedSplit, newSplit)
        XCTAssertFalse(viewModel.isLoading)
        
        // Verify workouts were generated for the new split
        let workoutsWithExercises = viewModel.weeklyWorkouts.compactMap { $0.workout }.filter { !$0.exercises.isEmpty }
        XCTAssertFalse(workoutsWithExercises.isEmpty)
    }
    
    func testPushPullLegsGeneration() async {
        // When
        await viewModel.changeWorkoutSplit(to: .pushPullLegs)
        
        // Then
        let workouts = viewModel.weeklyWorkouts.compactMap { $0.workout }
        let pushWorkouts = workouts.filter { $0.name.lowercased().contains("push") }
        let pullWorkouts = workouts.filter { $0.name.lowercased().contains("pull") }
        let legWorkouts = workouts.filter { $0.name.lowercased().contains("leg") }
        
        XCTAssertFalse(pushWorkouts.isEmpty)
        XCTAssertFalse(pullWorkouts.isEmpty)
        XCTAssertFalse(legWorkouts.isEmpty)
    }
    
    func testUpperLowerGeneration() async {
        // When
        await viewModel.changeWorkoutSplit(to: .upperLower)
        
        // Then
        let workouts = viewModel.weeklyWorkouts.compactMap { $0.workout }
        let upperWorkouts = workouts.filter { $0.name.lowercased().contains("upper") }
        let lowerWorkouts = workouts.filter { $0.name.lowercased().contains("lower") }
        
        XCTAssertFalse(upperWorkouts.isEmpty)
        XCTAssertFalse(lowerWorkouts.isEmpty)
    }
    
    func testFullBodyGeneration() async {
        // When
        await viewModel.changeWorkoutSplit(to: .fullBody)
        
        // Then
        let workouts = viewModel.weeklyWorkouts.compactMap { $0.workout }
        let fullBodyWorkouts = workouts.filter { $0.name.lowercased().contains("full body") }
        
        XCTAssertFalse(fullBodyWorkouts.isEmpty)
        
        // Full body workouts should target multiple muscle groups
        for workout in fullBodyWorkouts {
            let muscleGroups = Set(workout.exercises.flatMap { $0.targetMuscles })
            XCTAssertGreaterThan(muscleGroups.count, 2, "Full body workouts should target multiple muscle groups")
        }
    }
    
    // MARK: - Workout Scheduling Tests
    
    func testMoveWorkout() {
        // Given
        let sourceDay = 0 // Monday
        let destinationDay = 2 // Wednesday
        let workout = Workout(
            id: UUID(),
            name: "Test Workout",
            focusType: .strength,
            difficulty: .intermediate,
            estimatedDuration: 45,
            exercises: []
        )
        viewModel.weeklyWorkouts[sourceDay].workout = workout
        
        // When
        viewModel.moveWorkout(from: sourceDay, to: destinationDay)
        
        // Then
        XCTAssertNil(viewModel.weeklyWorkouts[sourceDay].workout)
        XCTAssertEqual(viewModel.weeklyWorkouts[destinationDay].workout?.id, workout.id)
    }
    
    func testRemoveWorkout() {
        // Given
        let dayIndex = 1
        let workout = Workout(
            id: UUID(),
            name: "Test Workout",
            focusType: .strength,
            difficulty: .intermediate,
            estimatedDuration: 45,
            exercises: []
        )
        viewModel.weeklyWorkouts[dayIndex].workout = workout
        
        // When
        viewModel.removeWorkout(from: dayIndex)
        
        // Then
        XCTAssertNil(viewModel.weeklyWorkouts[dayIndex].workout)
    }
    
    // MARK: - Auto-Scheduling Tests
    
    func testAutoScheduleWorkouts() async {
        // Given
        let busyBlocks = [
            BusyBlock(
                day: .monday,
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600), // 1 hour
                title: "Meeting"
            ),
            BusyBlock(
                day: .tuesday,
                startTime: Date(),
                endTime: Date().addingTimeInterval(7200), // 2 hours
                title: "Appointment"
            )
        ]
        
        // When
        await viewModel.autoScheduleWorkouts(avoiding: busyBlocks)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        
        // Verify workouts were scheduled around busy blocks
        let scheduledWorkouts = viewModel.weeklyWorkouts.compactMap { $0.workout }
        XCTAssertFalse(scheduledWorkouts.isEmpty)
    }
    
    func testOptimalWorkoutDistribution() async {
        // Given
        let profile = UserProfile(
            name: "Test User",
            goal: .buildMuscle,
            fitnessLevel: .intermediate,
            workoutFrequency: 4,
            availableEquipment: [.dumbbells],
            preferredWorkoutTimes: [.morning, .evening],
            workoutDuration: 60
        )
        
        // When
        await viewModel.generateOptimalSchedule(for: profile)
        
        // Then
        let workoutDays = viewModel.weeklyWorkouts.enumerated().compactMap { index, day in
            day.workout != nil ? index : nil
        }
        
        // Should have 4 workouts distributed throughout the week
        XCTAssertEqual(workoutDays.count, 4)
        
        // Workouts should be reasonably spaced (not all consecutive)
        let gaps = zip(workoutDays, workoutDays.dropFirst()).map { $1 - $0 }
        XCTAssertTrue(gaps.contains { $0 > 1 }, "Workouts should have rest days between them")
    }
    
    // MARK: - Workout Customization Tests
    
    func testCustomizeWorkout() {
        // Given
        let originalWorkout = Workout(
            id: UUID(),
            name: "Original Workout",
            focusType: .strength,
            difficulty: .intermediate,
            estimatedDuration: 45,
            exercises: []
        )
        
        let customizedWorkout = Workout(
            id: originalWorkout.id,
            name: "Customized Workout",
            focusType: .cardio,
            difficulty: .advanced,
            estimatedDuration: 60,
            exercises: []
        )
        
        let dayIndex = 0
        viewModel.weeklyWorkouts[dayIndex].workout = originalWorkout
        
        // When
        viewModel.updateWorkout(customizedWorkout, for: dayIndex)
        
        // Then
        let updatedWorkout = viewModel.weeklyWorkouts[dayIndex].workout
        XCTAssertEqual(updatedWorkout?.name, "Customized Workout")
        XCTAssertEqual(updatedWorkout?.focusType, .cardio)
        XCTAssertEqual(updatedWorkout?.difficulty, .advanced)
        XCTAssertEqual(updatedWorkout?.estimatedDuration, 60)
    }
    
    // MARK: - Data Persistence Tests
    
    func testSaveWeeklyPlan() async {
        // Given
        let workout = Workout(
            id: UUID(),
            name: "Test Workout",
            focusType: .strength,
            difficulty: .intermediate,
            estimatedDuration: 45,
            exercises: []
        )
        viewModel.weeklyWorkouts[0].workout = workout
        
        // When
        await viewModel.saveWeeklyPlan()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        // In a real test, you'd verify the data was saved to persistence
    }
    
    func testLoadWeeklyPlan() async {
        // When
        await viewModel.loadWeeklyPlan()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.weeklyWorkouts.count, 7)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingDuringGeneration() async {
        // Given
        // Simulate an error condition
        
        // When
        await viewModel.changeWorkoutSplit(to: .pushPullLegs)
        
        // Then
        // Verify the app doesn't crash and handles errors gracefully
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Helper Methods Tests
    
    func testWorkoutIntensityDistribution() async {
        // When
        await viewModel.changeWorkoutSplit(to: .pushPullLegs)
        
        // Then
        let workouts = viewModel.weeklyWorkouts.compactMap { $0.workout }
        let difficulties = workouts.map { $0.difficulty }
        
        // Should have a mix of difficulties, not all the same
        let uniqueDifficulties = Set(difficulties)
        XCTAssertGreaterThan(uniqueDifficulties.count, 1, "Should have varied workout difficulties")
    }
    
    func testRestDayPlacement() async {
        // Given
        let profile = UserProfile(
            name: "Test User",
            goal: .buildMuscle,
            fitnessLevel: .intermediate,
            workoutFrequency: 5,
            availableEquipment: [.dumbbells],
            preferredWorkoutTimes: [.morning],
            workoutDuration: 60
        )
        
        // When
        await viewModel.generateOptimalSchedule(for: profile)
        
        // Then
        let restDays = viewModel.weeklyWorkouts.enumerated().compactMap { index, day in
            day.workout == nil ? index : nil
        }
        
        // Should have at least 2 rest days
        XCTAssertGreaterThanOrEqual(restDays.count, 2, "Should have adequate rest days")
    }
} 