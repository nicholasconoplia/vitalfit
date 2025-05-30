//
//  HomeView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// Home screen view with workout card and mood-based adaptation
struct HomeView: View {
    @Bindable var vm: HomeViewModel
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // MARK: - Header Section
                    headerSection
                    
                    // MARK: - Workout Card Section
                    if let workout = vm.todayWorkout {
                        WorkoutCard(workout: workout)
                            .onTapGesture {
                                if vm.canStartWorkout {
                                    showingWorkoutDetail = true
                                }
                            }
                    } else {
                        noWorkoutCard
                    }
                    
                    // MARK: - Mood Picker Section
                    moodSection
                    
                    // MARK: - Quick Actions Section
                    quickActionsSection
                    
                    // MARK: - Stats Section
                    if let stats = vm.workoutStats {
                        statsSection(stats)
                    }
                    
                    Spacer(minLength: Spacing.xl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
            }
            .background(Color.background)
            .refreshable {
                await vm.refresh()
            }
        }
        .task {
            await vm.loadHomeData()
        }
        .fullScreenCover(isPresented: $showingWorkoutDetail) {
            workoutDetailSheet()
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") {
                vm.errorMessage = nil
            }
        } message: {
            if let error = vm.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("\(vm.greeting), \(vm.userName)")
                        .font(.heading)
                        .foregroundColor(.primaryText)
                    
                    Text(vm.motivationalMessage)
                        .font(.body)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Profile image placeholder
                Circle()
                    .fill(Color.accent.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.accent)
                    }
            }
        }
    }
    
    // MARK: - Workout Card
    
    private func WorkoutCard(workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(workout.title)
                        .font(.workoutCardTitle())
                        .foregroundColor(.primaryText)
                    
                    HStack(spacing: Spacing.sm) {
                        Label(workout.formattedDuration, systemImage: "clock")
                        Label(workout.formattedScheduledTime, systemImage: "calendar")
                        Label(workout.focus.displayName, systemImage: workout.focus.icon)
                    }
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Focus type badge
                Circle()
                    .fill(Color.focusColor(for: workout.focus).opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: workout.focus.icon)
                            .foregroundColor(Color.focusColor(for: workout.focus))
                    }
            }
            
            // Workout status
            HStack {
                if workout.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.success)
                        .font(.caption)
                } else if workout.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.warning)
                        .font(.caption)
                } else {
                    Label("Ready to start", systemImage: "play.circle.fill")
                        .foregroundColor(.accent)
                        .font(.caption)
                }
                
                Spacer()
                
                // Equipment needed
                HStack(spacing: Spacing.xs) {
                    ForEach(workout.equipment.prefix(3), id: \.self) { equipment in
                        Image(systemName: equipment.icon)
                            .foregroundColor(.secondaryText)
                            .font(.caption)
                    }
                }
            }
            
            // Start workout button
            if vm.canStartWorkout {
                Button("Start Workout") {
                    showingWorkoutDetail = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.isLoading)
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: ShadowStyle.light.color, radius: ShadowStyle.light.radius, 
                x: ShadowStyle.light.x, y: ShadowStyle.light.y)
    }
    
    // MARK: - No Workout Card
    
    private var noWorkoutCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 48))
                .foregroundColor(.accent.opacity(0.6))
            
            Text("No workout scheduled for today")
                .font(.heading)
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Take a rest day or create a custom workout")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: ShadowStyle.light.color, radius: ShadowStyle.light.radius,
                x: ShadowStyle.light.x, y: ShadowStyle.light.y)
    }
    
    // MARK: - Mood Section
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("How are you feeling?")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            Picker("Mood", selection: Binding(
                get: { vm.mood },
                set: { newMood in
                    Task {
                        await vm.updateMood(newMood)
                    }
                }
            )) {
                ForEach(MoodState.allCases, id: \.self) { mood in
                    HStack {
                        Image(systemName: mood.icon)
                        Text(mood.displayName)
                    }
                    .tag(mood)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Actions")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            HStack(spacing: Spacing.sm) {
                if vm.todayWorkout != nil && !vm.todayWorkout!.isCompleted {
                    Button("Reschedule") {
                        Task {
                            await vm.rescheduleWorkout()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Skip Today") {
                        Task {
                            await vm.skipWorkout()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Stats Section
    
    private func statsSection(_ stats: WorkoutStats) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Your Progress")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            HStack(spacing: Spacing.md) {
                StatCard(
                    title: "Streak",
                    value: "\(stats.currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Total",
                    value: "\(stats.totalWorkouts)",
                    subtitle: "workouts",
                    icon: "trophy.fill",
                    color: .accent
                )
                
                StatCard(
                    title: "Time",
                    value: stats.formattedTotalTime,
                    subtitle: "total",
                    icon: "clock.fill",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Sheet Content

    @ViewBuilder
    private func workoutDetailSheet() -> some View {
        if let workout = vm.todayWorkout {
            WorkoutDetailView(
                workout: workout,
                isPresented: $showingWorkoutDetail
            )
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .font(.metric())
                .foregroundColor(.primaryText)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Color.accent)
            .cornerRadius(CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundColor(.accent)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.accent.opacity(0.1))
            .cornerRadius(CornerRadius.small)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Placeholder Views removed - full WorkoutDetailView implemented in separate file

// MARK: - Preview

#Preview {
    let vm = HomeViewModel()
    vm.userProfile = UserProfile(name: "Sarah")
    vm.todayWorkout = Workout.sampleWorkout
    vm.workoutStats = WorkoutStats(
        totalWorkouts: 15,
        currentStreak: 5,
        totalTimeSpent: 12600, // 3.5 hours
        averageWorkoutTime: 840  // 14 minutes
    )
    
    return HomeView(vm: vm)
} 