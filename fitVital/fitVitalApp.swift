//
//  fitVitalApp.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import SwiftUI

@main
struct fitVitalApp: App {
    let persistenceController = PersistenceController.shared
    
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView(isOnboardingComplete: $hasCompletedOnboarding)
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
} 