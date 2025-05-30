//
//  PlanView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// View for weekly workout planning and customization
struct PlanView: View {
    @State private var viewModel = PlanViewModel()
    @State private var selectedWorkout: Workout?
    @State private var showingCustomization = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    weekHeaderView
                    splitSelectionView
                    weeklyPlanView
                    autoScheduleSection
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Previous Week", systemImage: "chevron.left") {
                            Task { await viewModel.previousWeek() }
                        }
                        Button("Next Week", systemImage: "chevron.right") {
                            Task { await viewModel.nextWeek() }
                        }
                        Button("This Week", systemImage: "calendar") {
                            Task { await viewModel.goToCurrentWeek() }
                        }
                    } label: {
                        Image(systemName: "calendar.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.loadWeeklyPlan()
            }
            .task {
                await viewModel.loadWeeklyPlan()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showingCustomization) {
                if let workout = selectedWorkout {
                    WorkoutCustomizationView(workout: workout) { updatedWorkout in
                        // Handle workout update
                        selectedWorkout = nil
                        showingCustomization = false
                    }
                }
            }
        }
    }
    
    // MARK: - Week Header
    
    private var weekHeaderView: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Button(action: { Task { await viewModel.previousWeek() } }) {
                    Image(systemName: "chevron.left.circle")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
                
                Spacer()
                
                Text(viewModel.weekDisplayString)
                    .font(.heading)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Button(action: { Task { await viewModel.nextWeek() } }) {
                    Image(systemName: "chevron.right.circle")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
            }
            
            // Week stats
            HStack(spacing: Spacing.lg) {
                statCard(
                    title: "Planned",
                    value: "\(viewModel.weeklyWorkouts.count)",
                    icon: "calendar"
                )
                
                statCard(
                    title: "Completed",
                    value: "\(viewModel.weeklyWorkouts.filter { $0.isCompleted }.count)",
                    icon: "checkmark.circle.fill"
                )
                
                statCard(
                    title: "Duration",
                    value: totalWeekDuration,
                    icon: "clock"
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.accent)
            
            Text(value)
                .font(.numericLarge)
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var totalWeekDuration: String {
        let total = viewModel.weeklyWorkouts.reduce(0) { $0 + $1.estimatedDuration }
        let minutes = Int(total) / 60
        return "\(minutes)m"
    }
    
    // MARK: - Split Selection
    
    private var splitSelectionView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Workout Split")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.availableSplits) { split in
                        splitCard(split)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    private func splitCard(_ split: WorkoutSplit) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(split.displayName)
                .font(.button)
                .foregroundColor(viewModel.selectedSplit == split ? .white : .primaryText)
            
            Text(split.description)
                .font(.caption)
                .foregroundColor(viewModel.selectedSplit == split ? .white.opacity(0.8) : .secondaryText)
                .multilineTextAlignment(.leading)
        }
        .padding(Spacing.sm)
        .frame(width: 160, height: 80, alignment: .topLeading)
        .background(viewModel.selectedSplit == split ? Color.accent : Color.surface)
        .cornerRadius(CornerRadius.medium)
        .onTapGesture {
            Task {
                await viewModel.changeSplit(to: split)
            }
        }
    }
    
    // MARK: - Weekly Plan
    
    private var weeklyPlanView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("This Week's Plan")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            LazyVStack(spacing: Spacing.sm) {
                ForEach(Array(viewModel.dailyPlan.enumerated()), id: \.offset) { index, day in
                    dailyPlanCard(day: day.day, workout: day.workout, dayIndex: index)
                }
            }
        }
    }
    
    private func dailyPlanCard(day: String, workout: Workout?, dayIndex: Int) -> some View {
        HStack(spacing: Spacing.md) {
            // Day indicator
            VStack(spacing: Spacing.xs) {
                Text(String(day.prefix(3)))
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Circle()
                    .fill(workout?.isCompleted == true ? Color.success : (workout != nil ? Color.accent : Color.surface))
                    .frame(width: 12, height: 12)
            }
            .frame(width: 40)
            
            // Workout card or rest day
            if let workout = workout {
                workoutCard(workout)
                    .onTapGesture {
                        selectedWorkout = workout
                        showingCustomization = true
                    }
                    .onDrag {
                        NSItemProvider(object: workout.id.uuidString as NSString)
                    }
            } else {
                restDayCard
            }
        }
        .dropDestination(for: String.self) { items, location in
            // Handle workout reordering
            if let workoutIdString = items.first,
               let workoutId = UUID(uuidString: workoutIdString),
               let workout = viewModel.weeklyWorkouts.first(where: { $0.id == workoutId }) {
                Task {
                    await viewModel.moveWorkout(workout, to: dayIndex)
                }
                return true
            }
            return false
        }
    }
    
    private func workoutCard(_ workout: Workout) -> some View {
        HStack(spacing: Spacing.sm) {
            // Focus type indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.focusColor(for: workout.focus))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(workout.title)
                        .font(.button)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    if workout.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.success)
                    }
                }
                
                HStack {
                    Label(workout.formattedDuration, systemImage: "clock")
                    
                    Spacer()
                    
                    Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundColor(.secondaryText)
            }
        }
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var restDayCard: some View {
        HStack {
            Image(systemName: "bed.double")
                .foregroundColor(.secondaryText)
            
            Text("Rest Day")
                .font(.button)
                .foregroundColor(.secondaryText)
            
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.surface.opacity(0.5))
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Color.border, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
    
    // MARK: - Auto Schedule Section
    
    private var autoScheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Smart Scheduling")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            Button(action: { Task { await viewModel.autoScheduleWeek() } }) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                    Text("Auto-Schedule Around Calendar")
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(Spacing.md)
                .background(Color.accent)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.medium)
            }
            .disabled(viewModel.isLoading)
            
            Text("Automatically schedule workouts around your calendar events")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
    }
}

// MARK: - Workout Customization View

struct WorkoutCustomizationView: View {
    let workout: Workout
    let onSave: (Workout) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var workoutTitle: String
    @State private var selectedFocus: FocusType
    @State private var estimatedDuration: TimeInterval
    
    init(workout: Workout, onSave: @escaping (Workout) -> Void) {
        self.workout = workout
        self.onSave = onSave
        self._workoutTitle = State(initialValue: workout.title)
        self._selectedFocus = State(initialValue: workout.focus)
        self._estimatedDuration = State(initialValue: workout.estimatedDuration)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Workout Title", text: $workoutTitle)
                    
                    Picker("Focus", selection: $selectedFocus) {
                        ForEach(FocusType.allCases, id: \.self) { focus in
                            Label(focus.displayName, systemImage: focus.icon)
                                .tag(focus)
                        }
                    }
                    
                    Stepper(value: .init(
                        get: { estimatedDuration / 60 },
                        set: { estimatedDuration = $0 * 60 }
                    ), in: 15...120, step: 15) {
                        Text("Duration: \(Int(estimatedDuration / 60)) minutes")
                    }
                }
                
                Section("Exercises") {
                    ForEach(workout.exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            Text(exercise.targetDescription)
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
            }
            .navigationTitle("Customize Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let updatedWorkout = Workout(
                            id: workout.id,
                            title: workoutTitle,
                            focus: selectedFocus,
                            exercises: workout.exercises,
                            scheduledDate: workout.scheduledDate,
                            estimatedDuration: estimatedDuration,
                            difficulty: workout.difficulty,
                            isCompleted: workout.isCompleted,
                            completedAt: workout.completedAt,
                            equipment: workout.equipment,
                            description: workout.description,
                            phases: workout.phases,
                            createdAt: workout.createdAt,
                            userRating: workout.userRating,
                            userNotes: workout.userNotes
                        )
                        onSave(updatedWorkout)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    PlanView()
} 