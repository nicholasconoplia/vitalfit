//
//  ProgressView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI
import Charts

/// View for tracking workout progress and statistics
struct ProgressView: View {
    @State private var viewModel = ProgressViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    completionRingsSection
                    progressInsightsSection
                    chartSection
                    statsGridSection
                    exportSection
                }
                .padding(Spacing.md)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Export Progress", systemImage: "square.and.arrow.up") {
                            Task {
                                await viewModel.exportProgressData()
                            }
                        }
                        
                        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.loadProgressData()
            }
            .task {
                await viewModel.loadProgressData()
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
        }
    }
    
    // MARK: - Completion Rings
    
    private var completionRingsSection: some View {
        VStack(spacing: Spacing.md) {
            Text("This Week & Month")
                .font(.subheading)
                .foregroundColor(.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: Spacing.xl) {
                completionRing(
                    title: "Week",
                    progress: viewModel.weeklyGoalProgress,
                    value: Int(viewModel.currentWeekCompletion),
                    goal: 3,
                    color: .accent
                )
                
                completionRing(
                    title: "Month",
                    progress: viewModel.monthlyGoalProgress,
                    value: Int(viewModel.currentMonthCompletion),
                    goal: 12,
                    color: .blue
                )
                
                streakRing(
                    current: viewModel.currentStreak,
                    longest: viewModel.longestStreak
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
    }
    
    private func completionRing(title: String, progress: Double, value: Int, goal: Int, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progress)
                
                VStack(spacing: 2) {
                    Text("\(value)")
                        .font(.numericLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("/ \(goal)")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
    }
    
    private func streakRing(current: Int, longest: Int) -> some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: min(Double(current) / 30.0, 1.0)) // 30-day max
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: current)
                
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text("\(current)")
                        .font(.button)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                }
            }
            
            Text("Streak")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
    }
    
    // MARK: - Progress Insights
    
    private var progressInsightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Insights")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(viewModel.progressInsights, id: \.title) { insight in
                        insightCard(insight)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    private func insightCard(_ insight: ProgressInsight) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: insight.icon)
                    .foregroundColor(.accent)
                
                Spacer()
            }
            
            Text(insight.title)
                .font(.button)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text(insight.message)
                .font(.caption)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(Spacing.md)
        .frame(width: 180, height: 100, alignment: .topLeading)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Workout Trend")
                    .font(.subheading)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Picker("Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            if viewModel.chartData.isEmpty {
                chartPlaceholder
            } else {
                workoutChart
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
        .onChange(of: viewModel.selectedTimeRange) { _, newValue in
            Task {
                await viewModel.changeTimeRange(to: newValue)
            }
        }
    }
    
    private var chartPlaceholder: some View {
        Rectangle()
            .fill(Color.background)
            .frame(height: 200)
            .overlay(
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondaryText.opacity(0.5))
                    
                    Text("No data available")
                        .font(.body)
                        .foregroundColor(.secondaryText)
                }
            )
            .cornerRadius(CornerRadius.small)
    }
    
    private var workoutChart: some View {
        Chart(viewModel.chartData) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Workouts", dataPoint.value)
            )
            .foregroundStyle(.accent)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value("Workouts", dataPoint.value)
            )
            .foregroundStyle(.accent.opacity(0.1))
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
    
    // MARK: - Stats Grid
    
    private var statsGridSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Statistics")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.md) {
                statCard(
                    title: "Total Workouts",
                    value: "\(viewModel.totalWorkoutsCompleted)",
                    icon: "checkmark.circle.fill",
                    color: .success
                )
                
                statCard(
                    title: "Avg Duration",
                    value: viewModel.formattedAverageDuration,
                    icon: "clock.fill",
                    color: .blue
                )
                
                statCard(
                    title: "Longest Streak",
                    value: "\(viewModel.longestStreak) days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                if let favorite = viewModel.favoriteWorkoutFocus {
                    statCard(
                        title: "Favorite Focus",
                        value: favorite.displayName,
                        icon: favorite.icon,
                        color: .focusColor(for: favorite)
                    )
                }
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(value)
                    .font(.numericLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .cornerRadius(CornerRadius.medium)
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Data Export")
                .font(.subheading)
                .foregroundColor(.primaryText)
            
            VStack(spacing: Spacing.sm) {
                Button(action: { Task { await viewModel.exportProgressData() } }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Progress Data")
                        Spacer()
                        
                        if viewModel.isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.accent)
                    .foregroundColor(.white)
                    .cornerRadius(CornerRadius.medium)
                }
                .disabled(viewModel.isExporting)
                
                Text("Export your workout progress and statistics as a CSV file for external analysis.")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
        }
    }
}

#Preview {
    ProgressView()
} 