//
//  MainTabView.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

/// Main tab navigation for the FitVital app
struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(vm: HomeViewModel())
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)
            
            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar.badge.plus")
                }
                .tag(Tab.plan)
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.progress)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .accentColor(.accent)
    }
}

// MARK: - Tab Definition

enum Tab: String, CaseIterable {
    case home = "home"
    case plan = "plan"
    case calendar = "calendar"
    case progress = "progress"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .plan: return "Plan"
        case .calendar: return "Calendar"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .plan: return "calendar.badge.plus"
        case .calendar: return "calendar"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gear"
        }
    }
}

#Preview {
    MainTabView()
} 