//
//  WorkoutDetailView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI
import AVKit

/// Full-screen workout detail view with step-by-step guidance
struct WorkoutDetailView: View {
    let workout: Workout
    @Binding var isPresented: Bool
    @State private var viewModel: WorkoutDetailViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    init(workout: Workout, isPresented: Binding<Bool>) {
        self.workout = workout
        self._isPresented = isPresented
        self._viewModel = State(initialValue: WorkoutDetailViewModel(workout: workout))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.background, Color.accent.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.workoutState == .notStarted {
                    workoutOverviewView
                } else {
                    workoutActiveView
                }
            }
            .navigationBarHidden(true)
            .statusBarHidden(viewModel.workoutState == .active)
        }
        .onAppear {
            viewModel.loadWorkout()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && viewModel.workoutState == .active {
                viewModel.pauseWorkout()
            }
        }
        .alert("Workout Complete!", isPresented: $viewModel.showCompletionAlert) {
            Button("View Summary") {
                viewModel.viewSummary()
            }
            Button("Done") {
                isPresented = false
            }
        } message: {
            Text("Great job! You've completed your workout.")
        }
    }
    
    // MARK: - Workout Overview
    
    private var workoutOverviewView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerView
                
                // Quick Stats
                quickStatsView
                
                // Exercise List
                exerciseListView
                
                // Action Buttons
                actionButtonsView
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .safeAreaInset(edge: .top) {
            topBarView
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Workout Image/Icon
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: workout.type.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.accent)
            }
            
            VStack(spacing: 8) {
                Text(workout.name)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text(workout.type.displayName)
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("\(viewModel.estimatedDuration) min", systemImage: "clock")
                    Spacer()
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                    Spacer()
                    Label(workout.difficulty.displayName, systemImage: "gauge.medium")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 20) {
            StatCardView(
                title: "Target Muscles",
                value: workout.targetMuscles.prefix(3).map { $0.displayName }.joined(separator: ", "),
                icon: "figure.strengthtraining.traditional"
            )
            
            StatCardView(
                title: "Equipment",
                value: workout.requiredEquipment.first?.displayName ?? "None",
                icon: "dumbbell"
            )
        }
    }
    
    private var exerciseListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                    ExerciseRowView(
                        exercise: exercise,
                        index: index + 1,
                        isActive: false
                    )
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            // Start Workout Button
            Button(action: {
                viewModel.startWorkout()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accent)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            
            // Preview Mode Button
            Button(action: {
                viewModel.enterPreviewMode()
            }) {
                HStack {
                    Image(systemName: "eye")
                    Text("Preview Exercises")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.surface)
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Active Workout View
    
    private var workoutActiveView: some View {
        VStack(spacing: 0) {
            // Progress Header
            workoutProgressHeader
            
            // Current Exercise
            if let currentExercise = viewModel.currentExercise {
                currentExerciseView(currentExercise)
            }
            
            // Controls
            workoutControlsView
        }
        .background(Color.background)
    }
    
    private var workoutProgressHeader: some View {
        VStack(spacing: 12) {
            // Progress Bar
            ProgressView(value: viewModel.workoutProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accent))
                .scaleEffect(x: 1, y: 3, anchor: .center)
            
            // Exercise Counter
            HStack {
                Text("\(viewModel.currentExerciseIndex + 1) of \(workout.exercises.count)")
                    .font(.headline)
                
                Spacer()
                
                Text(viewModel.formattedElapsedTime)
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.accent)
            }
        }
        .padding()
        .background(Color.surface)
    }
    
    private func currentExerciseView(_ exercise: Exercise) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Exercise Animation/Video
            exerciseVisualization(exercise)
            
            // Exercise Info
            VStack(spacing: 16) {
                Text(exercise.name)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text(exercise.instructions)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Sets/Reps/Time Info
                exerciseParametersView(exercise)
            }
            
            Spacer()
            
            // Timer View (if timed exercise)
            if viewModel.isTimedExercise {
                timerView
            }
        }
        .padding()
    }
    
    private func exerciseVisualization(_ exercise: Exercise) -> some View {
        ZStack {
            // Placeholder for animation/video
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surface)
                .frame(width: 300, height: 200)
                .overlay(
                    VStack {
                        Image(systemName: exercise.category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.accent)
                            .symbolEffect(.pulse.byLayer, isActive: viewModel.workoutState == .active)
                        
                        Text("Exercise Animation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
            
            // Play/Pause overlay for video mode
            if viewModel.animationMode == .video {
                Button(action: {
                    viewModel.toggleAnimationPlayback()
                }) {
                    Image(systemName: viewModel.isAnimationPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private func exerciseParametersView(_ exercise: Exercise) -> some View {
        HStack(spacing: 30) {
            if exercise.sets > 0 {
                VStack {
                    Text("\(exercise.sets)")
                        .font(.title.bold())
                        .foregroundColor(.accent)
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if exercise.reps > 0 {
                VStack {
                    Text("\(exercise.reps)")
                        .font(.title.bold())
                        .foregroundColor(.accent)
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if exercise.duration > 0 {
                VStack {
                    Text("\(Int(exercise.duration))")
                        .font(.title.bold())
                        .foregroundColor(.accent)
                    Text("Seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if exercise.restPeriod > 0 {
                VStack {
                    Text("\(Int(exercise.restPeriod))")
                        .font(.title.bold())
                        .foregroundColor(.secondary)
                    Text("Rest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(16)
    }
    
    private var timerView: some View {
        VStack(spacing: 16) {
            // Circular Timer
            ZStack {
                Circle()
                    .stroke(Color.surface, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: viewModel.timerProgress)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.timerProgress)
                
                VStack {
                    Text("\(viewModel.remainingTime)")
                        .font(.largeTitle.bold().monospacedDigit())
                        .foregroundColor(.accent)
                    Text("seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Timer Controls
            HStack(spacing: 30) {
                Button(action: {
                    viewModel.pauseTimer()
                }) {
                    Image(systemName: viewModel.isTimerPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
                
                Button(action: {
                    viewModel.resetTimer()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var workoutControlsView: some View {
        VStack(spacing: 16) {
            // Primary Action Button
            Button(action: {
                viewModel.nextExercise()
            }) {
                HStack {
                    Image(systemName: viewModel.nextButtonIcon)
                    Text(viewModel.nextButtonText)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accent)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            
            // Secondary Controls
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.previousExercise()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .foregroundColor(.secondary)
                }
                .disabled(viewModel.currentExerciseIndex == 0)
                
                Spacer()
                
                Button(action: {
                    viewModel.pauseWorkout()
                }) {
                    HStack {
                        Image(systemName: "pause")
                        Text("Pause")
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.stopWorkout()
                }) {
                    HStack {
                        Image(systemName: "stop")
                        Text("Stop")
                    }
                    .foregroundColor(.error)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.surface)
    }
    
    // MARK: - Top Bar
    
    private var topBarView: some View {
        HStack {
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    viewModel.toggleAnimationMode()
                }) {
                    Label("Animation Mode: \(viewModel.animationMode.displayName)", 
                          systemImage: viewModel.animationMode.icon)
                }
                
                Button(action: {
                    viewModel.adjustPlaybackSpeed()
                }) {
                    Label("Speed: \(viewModel.playbackSpeed)x", systemImage: "speedometer")
                }
                
                Divider()
                
                Button(action: {
                    viewModel.showWorkoutSettings()
                }) {
                    Label("Settings", systemImage: "gear")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.background.opacity(0.95))
    }
}

// MARK: - Supporting Views

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accent)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    let index: Int
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise Number
            ZStack {
                Circle()
                    .fill(isActive ? Color.accent : Color.surface)
                    .frame(width: 32, height: 32)
                
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(isActive ? .white : .secondary)
            }
            
            // Exercise Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(isActive ? .accent : .primary)
                
                HStack {
                    if exercise.sets > 0 {
                        Text("\(exercise.sets) sets")
                    }
                    if exercise.reps > 0 {
                        Text("× \(exercise.reps)")
                    }
                    if exercise.duration > 0 {
                        Text("\(Int(exercise.duration))s")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Exercise Category Icon
            Image(systemName: exercise.category.icon)
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isActive ? Color.accent.opacity(0.1) : Color.surface)
        .cornerRadius(12)
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class WorkoutDetailViewModel {
    // MARK: - State
    var workoutState: WorkoutState = .notStarted
    var currentExerciseIndex: Int = 0
    var workoutStartTime: Date?
    var elapsedTime: TimeInterval = 0
    var remainingTime: Int = 0
    var isTimerPaused: Bool = false
    var animationMode: AnimationMode = .animation
    var isAnimationPlaying: Bool = true
    var playbackSpeed: Double = 1.0
    var showCompletionAlert: Bool = false
    
    // MARK: - Data
    private let workout: Workout
    private var timer: Timer?
    private var exerciseTimer: Timer?
    
    init(workout: Workout) {
        self.workout = workout
    }
    
    // MARK: - Computed Properties
    
    var currentExercise: Exercise? {
        guard currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }
    
    var workoutProgress: Double {
        guard !workout.exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(workout.exercises.count)
    }
    
    var estimatedDuration: Int {
        let exerciseDuration = workout.exercises.reduce(0) { total, exercise in
            total + Int(exercise.duration) + Int(exercise.restPeriod)
        }
        return max(exerciseDuration / 60, 1)
    }
    
    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var isTimedExercise: Bool {
        currentExercise?.duration ?? 0 > 0
    }
    
    var timerProgress: Double {
        guard let exercise = currentExercise, exercise.duration > 0 else { return 0 }
        return 1.0 - (Double(remainingTime) / exercise.duration)
    }
    
    var nextButtonText: String {
        if currentExerciseIndex >= workout.exercises.count - 1 {
            return "Complete Workout"
        } else {
            return "Next Exercise"
        }
    }
    
    var nextButtonIcon: String {
        if currentExerciseIndex >= workout.exercises.count - 1 {
            return "checkmark"
        } else {
            return "chevron.right"
        }
    }
    
    // MARK: - Actions
    
    func loadWorkout() {
        // Load workout data and prepare for execution
        resetWorkoutState()
    }
    
    func startWorkout() {
        workoutState = .active
        workoutStartTime = Date()
        startMainTimer()
        startExerciseTimer()
    }
    
    func pauseWorkout() {
        workoutState = .paused
        stopTimers()
    }
    
    func resumeWorkout() {
        workoutState = .active
        startMainTimer()
        startExerciseTimer()
    }
    
    func stopWorkout() {
        workoutState = .completed
        stopTimers()
        showCompletionAlert = true
    }
    
    func nextExercise() {
        if currentExerciseIndex >= workout.exercises.count - 1 {
            completeWorkout()
        } else {
            currentExerciseIndex += 1
            startExerciseTimer()
        }
    }
    
    func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            startExerciseTimer()
        }
    }
    
    func enterPreviewMode() {
        workoutState = .preview
    }
    
    func pauseTimer() {
        isTimerPaused.toggle()
        if isTimerPaused {
            exerciseTimer?.invalidate()
        } else {
            startExerciseTimer()
        }
    }
    
    func resetTimer() {
        if let exercise = currentExercise {
            remainingTime = Int(exercise.duration)
        }
        startExerciseTimer()
    }
    
    func toggleAnimationMode() {
        animationMode = animationMode == .animation ? .video : .animation
    }
    
    func toggleAnimationPlayback() {
        isAnimationPlaying.toggle()
    }
    
    func adjustPlaybackSpeed() {
        let speeds: [Double] = [0.5, 1.0, 1.5, 2.0]
        if let currentIndex = speeds.firstIndex(of: playbackSpeed) {
            let nextIndex = (currentIndex + 1) % speeds.count
            playbackSpeed = speeds[nextIndex]
        }
    }
    
    func showWorkoutSettings() {
        // Implementation for workout settings
    }
    
    func viewSummary() {
        // Implementation for workout summary
    }
    
    // MARK: - Private Methods
    
    private func resetWorkoutState() {
        currentExerciseIndex = 0
        elapsedTime = 0
        isTimerPaused = false
        stopTimers()
        
        if let exercise = currentExercise {
            remainingTime = Int(exercise.duration)
        }
    }
    
    private func startMainTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.elapsedTime += 1
            }
        }
    }
    
    private func startExerciseTimer() {
        exerciseTimer?.invalidate()
        
        guard let exercise = currentExercise, exercise.duration > 0 else { return }
        
        remainingTime = Int(exercise.duration)
        
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.remainingTime > 0 && !self.isTimerPaused {
                    self.remainingTime -= 1
                } else if self.remainingTime == 0 {
                    self.exerciseTimer?.invalidate()
                    // Auto-advance to next exercise or rest period
                }
            }
        }
    }
    
    private func stopTimers() {
        timer?.invalidate()
        exerciseTimer?.invalidate()
    }
    
    private func completeWorkout() {
        workoutState = .completed
        stopTimers()
        
        // Save workout completion
        let completion = WorkoutCompletion(
            workoutId: workout.id,
            completedAt: Date(),
            duration: elapsedTime,
            exercisesCompleted: currentExerciseIndex + 1
        )
        
        // TODO: Save to persistence
        
        showCompletionAlert = true
    }
}

// MARK: - Supporting Types

enum WorkoutState {
    case notStarted
    case active
    case paused
    case preview
    case completed
}

enum AnimationMode {
    case animation
    case video
    
    var displayName: String {
        switch self {
        case .animation: return "Animation"
        case .video: return "Video"
        }
    }
    
    var icon: String {
        switch self {
        case .animation: return "waveform.circle"
        case .video: return "video.circle"
        }
    }
}

struct WorkoutCompletion {
    let workoutId: UUID
    let completedAt: Date
    let duration: TimeInterval
    let exercisesCompleted: Int
}

#Preview {
    WorkoutDetailView(
        workout: Workout.sampleWorkouts[0],
        isPresented: .constant(true)
    )
} 