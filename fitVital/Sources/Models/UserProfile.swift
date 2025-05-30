//
//  UserProfile.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation

/// User's fitness goals
enum FitnessGoal: String, Codable, CaseIterable {
    case stayHealthy = "stayHealthy"
    case loseFat = "loseFat"
    case buildStrength = "buildStrength"
    case maintain = "maintain"
    case boostEnergy = "boostEnergy"
    
    var displayName: String {
        switch self {
        case .stayHealthy: return "Stay Healthy"
        case .loseFat: return "Lose Fat"
        case .buildStrength: return "Build Strength"
        case .maintain: return "Maintain Fitness"
        case .boostEnergy: return "Boost Energy"
        }
    }
    
    var description: String {
        switch self {
        case .stayHealthy: return "General health and wellness"
        case .loseFat: return "Fat loss and body composition"
        case .buildStrength: return "Muscle building and strength"
        case .maintain: return "Maintain current fitness level"
        case .boostEnergy: return "Increase daily energy and vitality"
        }
    }
    
    var recommendedFrequency: Int {
        switch self {
        case .stayHealthy: return 3
        case .loseFat: return 4
        case .buildStrength: return 4
        case .maintain: return 3
        case .boostEnergy: return 4
        }
    }
}

/// Available equipment types
enum EquipmentType: String, Codable, CaseIterable {
    case gym = "gym"
    case dumbbells = "dumbbells"
    case bodyweight = "bodyweight"
    case bands = "bands"
    
    var displayName: String {
        switch self {
        case .gym: return "Full Gym"
        case .dumbbells: return "Dumbbells"
        case .bodyweight: return "Bodyweight Only"
        case .bands: return "Resistance Bands"
        }
    }
    
    var description: String {
        switch self {
        case .gym: return "Full gym access with all equipment"
        case .dumbbells: return "Dumbbells and basic weights"
        case .bodyweight: return "No equipment needed"
        case .bands: return "Resistance bands and tubes"
        }
    }
    
    var icon: String {
        switch self {
        case .gym: return "building.2"
        case .dumbbells: return "dumbbell"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .bands: return "oval.portrait"
        }
    }
}

/// Preferred workout times
enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        }
    }
    
    var timeRange: String {
        switch self {
        case .morning: return "6:00 - 12:00"
        case .afternoon: return "12:00 - 17:00"
        case .evening: return "17:00 - 21:00"
        }
    }
    
    var defaultHour: Int {
        switch self {
        case .morning: return 7
        case .afternoon: return 14
        case .evening: return 18
        }
    }
}

// MARK: - User Profile

/// User profile containing fitness preferences and settings
struct UserProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var fitnessGoal: FitnessGoal
    var weeklyFrequency: Int
    var sessionDuration: TimeInterval // in seconds
    var equipmentAccess: [EquipmentType]
    var dislikedExercises: [String]
    var physicalLimitations: [String]
    var preferredTimes: [TimeOfDay]
    var calendarSynced: Bool
    
    // Additional profile data
    var fitnessLevel: FitnessLevel
    var createdAt: Date
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        fitnessGoal: FitnessGoal,
        weeklyFrequency: Int,
        sessionDuration: TimeInterval,
        equipmentAccess: [EquipmentType],
        dislikedExercises: [String] = [],
        physicalLimitations: [String] = [],
        preferredTimes: [TimeOfDay],
        calendarSynced: Bool = false,
        fitnessLevel: FitnessLevel = .beginner
    ) {
        self.id = id
        self.name = name
        self.fitnessGoal = fitnessGoal
        self.weeklyFrequency = weeklyFrequency
        self.sessionDuration = sessionDuration
        self.equipmentAccess = equipmentAccess
        self.dislikedExercises = dislikedExercises
        self.physicalLimitations = physicalLimitations
        self.preferredTimes = preferredTimes
        self.calendarSynced = calendarSynced
        self.fitnessLevel = fitnessLevel
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
}

/// User's fitness experience level
enum FitnessLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "New to regular exercise"
        case .intermediate: return "Some exercise experience"
        case .advanced: return "Regular exerciser"
        }
    }
}

// MARK: - Extensions

extension UserProfile {
    /// Formatted session duration
    var formattedDuration: String {
        let minutes = Int(sessionDuration) / 60
        return "\(minutes) minutes"
    }
    
    /// Recommended workout intensity based on goal and level
    var recommendedIntensity: Double {
        let baseIntensity: Double
        switch fitnessGoal {
        case .stayHealthy: baseIntensity = 0.6
        case .loseFat: baseIntensity = 0.7
        case .buildStrength: baseIntensity = 0.8
        case .maintain: baseIntensity = 0.6
        case .boostEnergy: baseIntensity = 0.65
        }
        
        let levelMultiplier: Double
        switch fitnessLevel {
        case .beginner: levelMultiplier = 0.8
        case .intermediate: levelMultiplier = 1.0
        case .advanced: levelMultiplier = 1.2
        }
        
        return min(baseIntensity * levelMultiplier, 1.0)
    }
}

/*
 Sample JSON:
 {
   "id": "550e8400-e29b-41d4-a716-446655440000",
   "name": "Sarah Johnson",
   "fitnessGoal": "loseFat",
   "weeklyFrequency": 4,
   "sessionDuration": 3600,
   "equipmentAccess": ["dumbbells", "bodyweight"],
   "dislikedExercises": ["burpees", "mountain_climbers"],
   "physicalLimitations": ["lower_back_sensitivity"],
   "preferredTimes": ["morning", "evening"],
   "calendarSynced": true,
   "fitnessLevel": "intermediate",
   "createdAt": "2025-05-30T10:00:00Z",
   "lastUpdated": "2025-05-30T10:00:00Z"
 }
 */ 