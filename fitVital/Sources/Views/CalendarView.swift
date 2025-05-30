//
//  CalendarView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// View for calendar integration and workout scheduling
struct CalendarView: View {
    @State private var viewModel = CalendarViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading calendar...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.calendarPermissionGranted {
                    permissionPromptView
                } else {
                    calendarContentView
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadCalendarData()
            }
            .refreshable {
                await viewModel.loadCalendarData()
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
            .sheet(isPresented: $viewModel.showingPermissionRequest) {
                CalendarPermissionView { granted in
                    if granted {
                        Task {
                            await viewModel.requestCalendarPermission()
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingWorkoutDetail) {
                if let workout = viewModel.selectedWorkout {
                    WorkoutDetailView(workout: workout)
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: Spacing.sm) {
            // View mode toggle and navigation
            HStack {
                Button(action: { Task { await viewModel.previousPeriod() } }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accent)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(viewModel.periodTitle)
                        .font(.heading)
                        .foregroundColor(.primaryText)
                    
                    if viewModel.canAutoSchedule {
                        Button("Auto-Schedule") {
                            Task {
                                await viewModel.autoScheduleWeek()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.accent)
                    }
                }
                
                Spacer()
                
                Button(action: { Task { await viewModel.nextPeriod() } }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.accent)
                }
            }
            .padding(.horizontal, Spacing.md)
            
            // View mode picker
            HStack(spacing: Spacing.sm) {
                ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                    Button(action: {
                        Task {
                            await viewModel.switchViewMode(to: mode)
                        }
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                        }
                        .font(.button)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(viewModel.viewMode == mode ? Color.accent : Color.surface)
                        .foregroundColor(viewModel.viewMode == mode ? .white : .primaryText)
                        .cornerRadius(CornerRadius.small)
                    }
                }
                
                Spacer()
                
                Button("Today") {
                    Task {
                        await viewModel.goToToday()
                    }
                }
                .font(.button)
                .foregroundColor(.accent)
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.vertical, Spacing.sm)
        .background(Color.background)
    }
    
    // MARK: - Permission Prompt
    
    private var permissionPromptView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.accent)
            
            VStack(spacing: Spacing.sm) {
                Text("Calendar Access Needed")
                    .font(.heading)
                    .foregroundColor(.primaryText)
                
                Text("Enable calendar access to automatically schedule workouts around your events and avoid conflicts.")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            Button("Enable Calendar Access") {
                viewModel.showingPermissionRequest = true
            }
            .font(.button)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.accent)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.medium)
            
            Spacer()
        }
        .padding(Spacing.lg)
    }
    
    // MARK: - Calendar Content
    
    private var calendarContentView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                if viewModel.viewMode == .month {
                    monthCalendarView
                } else {
                    weekCalendarView
                }
            }
            .padding(Spacing.md)
        }
    }
    
    // MARK: - Month Calendar
    
    private var monthCalendarView: some View {
        VStack(spacing: Spacing.sm) {
            // Weekday headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Spacing.xs)
            
            // Calendar grid
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(viewModel.calendarDays) { day in
                    monthDayCell(day)
                }
            }
        }
    }
    
    private func monthDayCell(_ day: CalendarDay) -> some View {
        VStack(spacing: 2) {
            Text(day.dayNumber)
                .font(.caption)
                .foregroundColor(day.isCurrentMonth ? .primaryText : .secondaryText.opacity(0.5))
                .fontWeight(day.isToday ? .bold : .regular)
            
            // Workout indicator
            if day.hasWorkout {
                Circle()
                    .fill(day.workout?.isCompleted == true ? Color.success : Color.accent)
                    .frame(width: 6, height: 6)
            } else if day.hasConflict {
                Circle()
                    .fill(Color.warning)
                    .frame(width: 4, height: 4)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.small)
                .fill(day.isToday ? Color.accent.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            Task {
                await viewModel.selectDate(day.date)
            }
        }
    }
    
    // MARK: - Week Calendar
    
    private var weekCalendarView: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(viewModel.calendarDays) { day in
                weekDayRow(day)
            }
        }
    }
    
    private func weekDayRow(_ day: CalendarDay) -> some View {
        HStack(spacing: Spacing.md) {
            // Day info
            VStack(alignment: .leading, spacing: 2) {
                Text(day.weekday)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text(day.dayNumber)
                    .font(.heading)
                    .foregroundColor(day.isToday ? .accent : .primaryText)
                    .fontWeight(day.isToday ? .bold : .semibold)
            }
            .frame(width: 50, alignment: .leading)
            
            // Workout or status
            if let workout = day.workout {
                workoutCardCompact(workout)
                    .onTapGesture {
                        viewModel.selectedWorkout = workout
                        viewModel.showingWorkoutDetail = true
                    }
            } else if day.hasConflict {
                conflictIndicator
            } else {
                emptyDayIndicator
            }
        }
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
    }
    
    private func workoutCardCompact(_ workout: Workout) -> some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.focusColor(for: workout.focus))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(workout.title)
                        .font(.button)
                        .foregroundColor(.primaryText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if workout.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.success)
                            .font(.caption)
                    }
                }
                
                HStack {
                    Text(workout.formattedScheduledTime)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Text(workout.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.background)
        .cornerRadius(CornerRadius.small)
    }
    
    private var conflictIndicator: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warning)
            
            Text("Busy")
                .font(.button)
                .foregroundColor(.secondaryText)
            
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.warning.opacity(0.1))
        .cornerRadius(CornerRadius.small)
    }
    
    private var emptyDayIndicator: some View {
        HStack {
            Text("No workout planned")
                .font(.button)
                .foregroundColor(.secondaryText)
            
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.surface.opacity(0.5))
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Calendar Permission View

struct CalendarPermissionView: View {
    let onComplete: (Bool) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundColor(.accent)
                
                VStack(spacing: Spacing.md) {
                    Text("Calendar Integration")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("FitVital can automatically schedule your workouts around your calendar events, ensuring you never miss a session.")
                        .font(.body)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                
                VStack(spacing: Spacing.md) {
                    benefitRow(icon: "calendar.badge.clock", text: "Smart scheduling around events")
                    benefitRow(icon: "exclamationmark.triangle", text: "Avoid workout conflicts")
                    benefitRow(icon: "clock", text: "Optimize workout timing")
                }
                .padding(.horizontal, Spacing.lg)
                
                Spacer()
                
                VStack(spacing: Spacing.sm) {
                    Button("Allow Calendar Access") {
                        onComplete(true)
                        dismiss()
                    }
                    .font(.buttonLarge)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.medium)
                    
                    Button("Not Now") {
                        onComplete(false)
                        dismiss()
                    }
                    .font(.button)
                    .foregroundColor(.secondaryText)
                }
            }
            .padding(Spacing.lg)
            .navigationTitle("Calendar Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        onComplete(false)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(.accent)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primaryText)
            
            Spacer()
        }
    }
}

// MARK: - Workout Detail View

struct WorkoutDetailView: View {
    let workout: Workout
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(workout.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                        
                        HStack {
                            Label(workout.focus.displayName, systemImage: workout.focus.icon)
                                .foregroundColor(.focusColor(for: workout.focus))
                            
                            Spacer()
                            
                            if workout.isCompleted {
                                Label("Completed", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.success)
                            }
                        }
                        .font(.button)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        detailRow(title: "Scheduled", value: workout.formattedScheduledTime, icon: "clock")
                        detailRow(title: "Duration", value: workout.formattedDuration, icon: "timer")
                        detailRow(title: "Exercises", value: "\(workout.exercises.count)", icon: "list.bullet")
                    }
                    
                    // Exercises
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Exercises")
                            .font(.subheading)
                            .foregroundColor(.primaryText)
                        
                        ForEach(workout.exercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accent)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.button)
                .foregroundColor(.primaryText)
        }
    }
    
    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.button)
                    .foregroundColor(.primaryText)
                
                Text(exercise.targetDescription)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text(exercise.difficulty.displayName)
                .font(.caption)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.difficultyColor(for: exercise.difficulty))
                .cornerRadius(CornerRadius.small)
        }
        .padding(Spacing.sm)
        .background(Color.surface)
        .cornerRadius(CornerRadius.small)
    }
}

#Preview {
    CalendarView()
} 