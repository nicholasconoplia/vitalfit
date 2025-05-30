//
//  SettingsView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// View for app settings and user preferences
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                profileSection
                permissionsSection
                notificationSection
                appearanceSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadSettings()
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
            .alert("Export Complete", isPresented: .constant(viewModel.exportMessage != nil)) {
                Button("OK") {
                    viewModel.exportMessage = nil
                }
            } message: {
                if let message = viewModel.exportMessage {
                    Text(message)
                }
            }
            .sheet(isPresented: $viewModel.isEditingProfile) {
                if let profile = viewModel.userProfile {
                    ProfileEditView(profile: profile) { updatedProfile in
                        viewModel.userProfile = updatedProfile
                        Task {
                            await viewModel.saveProfile()
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingPermissionExplanation) {
                if let permission = viewModel.selectedPermission {
                    PermissionExplanationView(permission: permission) {
                        viewModel.showingPermissionExplanation = false
                    }
                }
            }
            .alert("Clear All Data", isPresented: $viewModel.showingExportOptions) {
                Button("Export & Clear", role: .destructive) {
                    Task {
                        await viewModel.exportAllData()
                        await viewModel.clearAllData()
                    }
                }
                Button("Clear Only", role: .destructive) {
                    Task {
                        await viewModel.clearAllData()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your workout data. Consider exporting first.")
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section("Profile") {
            if let profile = viewModel.userProfile {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name.isEmpty ? "Add Your Name" : profile.name)
                            .font(.headline)
                            .foregroundColor(profile.name.isEmpty ? .secondaryText : .primaryText)
                        
                        Text(profile.fitnessGoal.displayName)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button("Edit") {
                        viewModel.isEditingProfile = true
                    }
                    .foregroundColor(.accent)
                }
                
                Label("\(profile.weeklyFrequency) workouts per week", systemImage: "calendar")
                    .foregroundColor(.secondaryText)
                
                Label("\(Int(profile.sessionDuration / 60)) minutes per session", systemImage: "clock")
                    .foregroundColor(.secondaryText)
                
            } else {
                HStack {
                    Text("Create Profile")
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Button("Setup") {
                        viewModel.isEditingProfile = true
                    }
                    .foregroundColor(.accent)
                }
            }
        }
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        Section("Permissions") {
            permissionRow(
                title: "Notifications",
                description: "Workout reminders and progress updates",
                isEnabled: viewModel.notificationsEnabled,
                permission: .notifications
            ) {
                Task {
                    await viewModel.toggleNotifications()
                }
            }
            
            permissionRow(
                title: "Calendar Access",
                description: "Smart workout scheduling",
                isEnabled: viewModel.calendarEnabled,
                permission: .calendar
            ) {
                Task {
                    await viewModel.toggleCalendarIntegration()
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                        .foregroundColor(.primaryText)
                    
                    Text(viewModel.permissionsSummary.statusText)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: viewModel.permissionsSummary.allGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(viewModel.permissionsSummary.allGranted ? .success : .warning)
            }
        }
    }
    
    private func permissionRow(
        title: String,
        description: String,
        isEnabled: Bool,
        permission: PermissionType,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Button("Info") {
                viewModel.showPermissionExplanation(for: permission)
            }
            .font(.caption)
            .foregroundColor(.accent)
            
            Toggle("", isOn: .init(
                get: { isEnabled },
                set: { _ in action() }
            ))
        }
    }
    
    // MARK: - Notification Section
    
    private var notificationSection: some View {
        Section("Notifications") {
            HStack {
                Text("Reminder Timing")
                Spacer()
                Picker("Minutes", selection: $viewModel.reminderTiming) {
                    ForEach(viewModel.reminderTimings, id: \.self) { timing in
                        Text("\(timing) min before").tag(timing)
                    }
                }
                .pickerStyle(.menu)
            }
            .onChange(of: viewModel.reminderTiming) { _, newValue in
                viewModel.updateReminderTiming(newValue)
            }
            
            Toggle("Weekly Check-ins", isOn: $viewModel.weeklyCheckInsEnabled)
                .onChange(of: viewModel.weeklyCheckInsEnabled) { _, _ in
                    viewModel.toggleWeeklyCheckIns()
                }
            
            Toggle("Milestone Celebrations", isOn: $viewModel.milestoneNotificationsEnabled)
                .onChange(of: viewModel.milestoneNotificationsEnabled) { _, _ in
                    viewModel.toggleMilestoneNotifications()
                }
        }
        .disabled(!viewModel.notificationsEnabled)
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        Section("Appearance") {
            HStack {
                Text("Theme")
                Spacer()
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Label(theme.displayName, systemImage: theme.icon)
                            .tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }
            .onChange(of: viewModel.selectedTheme) { _, newValue in
                viewModel.changeTheme(to: newValue)
            }
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section("Data Management") {
            Button("Export All Data") {
                Task {
                    await viewModel.exportAllData()
                }
            }
            .disabled(viewModel.isExporting)
            .overlay(alignment: .trailing) {
                if viewModel.isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if viewModel.isExporting {
                HStack {
                    Text("Exporting...")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    ProgressView(value: viewModel.exportProgress)
                        .frame(width: 100)
                }
            }
            
            Button("Clear All Data", role: .destructive) {
                viewModel.showingExportOptions = true
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondaryText)
            }
            
            Link(destination: URL(string: "https://github.com/fitvital/privacy")!) {
                Text("Privacy Policy")
            }
            
            Link(destination: URL(string: "https://github.com/fitvital/terms")!) {
                Text("Terms of Service")
            }
            
            Link(destination: URL(string: "https://github.com/fitvital/support")!) {
                Text("Support")
            }
        }
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    let profile: UserProfile
    let onSave: (UserProfile) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var fitnessGoal: FitnessGoal
    @State private var weeklyFrequency: Int
    @State private var sessionDuration: TimeInterval
    @State private var equipmentAccess: Set<EquipmentType>
    @State private var preferredTimes: Set<TimeOfDay>
    @State private var calendarSynced: Bool
    
    init(profile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        
        self._name = State(initialValue: profile.name)
        self._fitnessGoal = State(initialValue: profile.fitnessGoal)
        self._weeklyFrequency = State(initialValue: profile.weeklyFrequency)
        self._sessionDuration = State(initialValue: profile.sessionDuration)
        self._equipmentAccess = State(initialValue: Set(profile.equipmentAccess))
        self._preferredTimes = State(initialValue: Set(profile.preferredTimes))
        self._calendarSynced = State(initialValue: profile.calendarSynced)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    TextField("Your Name", text: $name)
                    
                    Picker("Fitness Goal", selection: $fitnessGoal) {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            VStack(alignment: .leading) {
                                Text(goal.displayName)
                                Text(goal.description)
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                            .tag(goal)
                        }
                    }
                }
                
                Section("Workout Preferences") {
                    Stepper(value: $weeklyFrequency, in: 1...7) {
                        Text("Weekly Frequency: \(weeklyFrequency)")
                    }
                    
                    Stepper(value: .init(
                        get: { sessionDuration / 60 },
                        set: { sessionDuration = $0 * 60 }
                    ), in: 15...120, step: 15) {
                        Text("Session Duration: \(Int(sessionDuration / 60)) minutes")
                    }
                }
                
                Section("Equipment Access") {
                    ForEach(EquipmentType.allCases, id: \.self) { equipment in
                        HStack {
                            Image(systemName: equipment.icon)
                                .foregroundColor(.accent)
                                .frame(width: 24)
                            
                            Text(equipment.displayName)
                            
                            Spacer()
                            
                            if equipmentAccess.contains(equipment) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if equipmentAccess.contains(equipment) {
                                equipmentAccess.remove(equipment)
                            } else {
                                equipmentAccess.insert(equipment)
                            }
                        }
                    }
                }
                
                Section("Preferred Workout Times") {
                    ForEach(TimeOfDay.allCases, id: \.self) { time in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(time.displayName)
                                Text(time.timeRange)
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                            
                            Spacer()
                            
                            if preferredTimes.contains(time) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if preferredTimes.contains(time) {
                                preferredTimes.remove(time)
                            } else {
                                preferredTimes.insert(time)
                            }
                        }
                    }
                }
                
                Section("Integration") {
                    Toggle("Calendar Sync", isOn: $calendarSynced)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let updatedProfile = UserProfile(
                            id: profile.id,
                            name: name,
                            fitnessGoal: fitnessGoal,
                            weeklyFrequency: weeklyFrequency,
                            sessionDuration: sessionDuration,
                            equipmentAccess: Array(equipmentAccess),
                            dislikedExercises: profile.dislikedExercises,
                            physicalLimitations: profile.physicalLimitations,
                            preferredTimes: Array(preferredTimes),
                            calendarSynced: calendarSynced,
                            createdAt: profile.createdAt,
                            updatedAt: Date()
                        )
                        onSave(updatedProfile)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || equipmentAccess.isEmpty || preferredTimes.isEmpty)
                }
            }
        }
    }
}

// MARK: - Permission Explanation View

struct PermissionExplanationView: View {
    let permission: PermissionType
    let onDismiss: () -> Void
    
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        let explanation = viewModel.getPermissionExplanation(for: permission)
        
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                Image(systemName: explanation.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.accent)
                
                VStack(spacing: Spacing.md) {
                    Text(explanation.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text(explanation.description)
                        .font(.body)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                
                VStack(spacing: Spacing.md) {
                    ForEach(explanation.benefits, id: \.self) { benefit in
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accent)
                            
                            Text(benefit)
                                .font(.body)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                
                Spacer()
                
                Button("Got It") {
                    onDismiss()
                }
                .font(.buttonLarge)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.accent)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.medium)
            }
            .padding(Spacing.lg)
            .navigationTitle(explanation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 