//
//  OnboardingView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// Onboarding flow for new users
struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.accent.opacity(0.1), Color.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: viewModel.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accent))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Content
                    TabView(selection: $viewModel.currentStep) {
                        WelcomeStepView(viewModel: viewModel)
                            .tag(OnboardingStep.welcome)
                        
                        NameStepView(viewModel: viewModel)
                            .tag(OnboardingStep.name)
                        
                        GoalStepView(viewModel: viewModel)
                            .tag(OnboardingStep.goal)
                        
                        FrequencyStepView(viewModel: viewModel)
                            .tag(OnboardingStep.frequency)
                        
                        EquipmentStepView(viewModel: viewModel)
                            .tag(OnboardingStep.equipment)
                        
                        TimesStepView(viewModel: viewModel)
                            .tag(OnboardingStep.times)
                        
                        PermissionsStepView(viewModel: viewModel)
                            .tag(OnboardingStep.permissions)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    
                    // Bottom navigation
                    HStack {
                        if !viewModel.isFirstStep {
                            Button("Back") {
                                viewModel.goToPreviousStep()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(viewModel.isLastStep ? "Get Started" : "Continue") {
                            viewModel.goToNextStep()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canProceed || viewModel.isLoading)
                    }
                    .padding()
                }
            }
        }
        .onChange(of: viewModel.isOnboardingComplete) { _, isComplete in
            if isComplete {
                isOnboardingComplete = true
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
    }
}

// MARK: - Step Views

struct WelcomeStepView: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 80))
                    .foregroundColor(.accent)
                    .symbolEffect(.pulse.byLayer, isActive: true)
                
                VStack(spacing: 12) {
                    Text("Welcome to FitVital")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("Your personalized fitness journey starts here")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                FeatureRowView(
                    icon: "calendar.badge.checkmark",
                    title: "Smart Scheduling",
                    description: "Workouts that fit your busy life"
                )
                
                FeatureRowView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Tracking",
                    description: "See your improvements over time"
                )
                
                FeatureRowView(
                    icon: "brain.head.profile",
                    title: "AI Personalization",
                    description: "Plans that adapt to your needs"
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

struct NameStepView: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                
                VStack(spacing: 12) {
                    Text("What's your name?")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("We'll use this to personalize your experience")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            TextField("Enter your name", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .multilineTextAlignment(.center)
                .submitLabel(.continue)
                .onSubmit {
                    if viewModel.canProceed {
                        viewModel.goToNextStep()
                    }
                }
            
            Spacer()
        }
        .padding()
    }
}

struct GoalStepView: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                
                VStack(spacing: 12) {
                    Text("What's your main goal?")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("This helps us create the perfect plan for you")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        GoalOptionView(
                            goal: goal,
                            isSelected: viewModel.selectedGoal == goal
                        ) {
                            viewModel.selectedGoal = goal
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct FrequencyStepView: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                
                VStack(spacing: 12) {
                    Text("How often do you want to work out?")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("We'll build your schedule around this")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 20) {
                Text("\(viewModel.selectedFrequency) time\(viewModel.selectedFrequency == 1 ? "" : "s") per week")
                    .font(.title.bold())
                    .foregroundColor(.accent)
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.selectedFrequency) },
                        set: { viewModel.selectedFrequency = Int($0) }
                    ),
                    in: 1...7,
                    step: 1
                )
                .accentColor(.accent)
                
                HStack {
                    Text("1")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("7")
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(16)
            
            Text("Duration: \(Int(viewModel.sessionDuration / 60)) minutes per session")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

struct EquipmentStepView: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Image(systemName: "dumbbell")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                
                VStack(spacing: 12) {
                    Text("What equipment do you have?")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("We'll customize exercises based on what you have")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(EquipmentType.allCases, id: \.self) { equipment in
                        EquipmentOptionView(
                            equipment: equipment,
                            isSelected: viewModel.selectedEquipment.contains(equipment)
                        ) {
                            viewModel.toggleEquipment(equipment)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TimesStepView: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Image(systemName: "clock")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                
                VStack(spacing: 12) {
                    Text("When do you prefer to work out?")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("We'll schedule workouts at your preferred times")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                ForEach(TimeOfDay.allCases, id: \.self) { time in
                    TimeOptionView(
                        time: time,
                        isSelected: viewModel.selectedTimes.contains(time)
                    ) {
                        viewModel.toggleTime(time)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct PermissionsStepView: View {
    let viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accent)
                
                VStack(spacing: 12) {
                    Text("Enable Features")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("Optional features to enhance your experience")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                PermissionRowView(
                    icon: "calendar.badge.checkmark",
                    title: "Calendar Integration",
                    description: "Sync workouts with your calendar",
                    isGranted: viewModel.calendarPermissionGranted,
                    action: {
                        Task {
                            await viewModel.requestCalendarPermission()
                        }
                    }
                )
                
                PermissionRowView(
                    icon: "bell.badge",
                    title: "Workout Reminders",
                    description: "Get notified about upcoming workouts",
                    isGranted: viewModel.notificationPermissionGranted,
                    action: {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    }
                )
            }
            
            Button("Enable All") {
                Task {
                    await viewModel.requestAllPermissions()
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.calendarPermissionGranted && viewModel.notificationPermissionGranted)
            
            Text("You can always change these settings later")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Helper Views

struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct GoalOptionView: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(goal.displayName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(isSelected ? Color.accent.opacity(0.2) : Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct EquipmentOptionView: View {
    let equipment: EquipmentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: equipment.icon)
                    .font(.largeTitle)
                    .foregroundColor(isSelected ? .accent : .secondary)
                
                Text(equipment.displayName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(equipment.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isSelected ? Color.accent.opacity(0.2) : Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accent : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct TimeOptionView: View {
    let time: TimeOfDay
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(time.displayName)
                        .font(.headline)
                    Text(time.timeRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
            }
            .padding()
            .background(isSelected ? Color.accent.opacity(0.2) : Color.surface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct PermissionRowView: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.success)
            } else {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
} 