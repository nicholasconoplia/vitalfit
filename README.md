# FitVital - Your Adaptive Fitness Coach

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-green.svg" alt="SwiftUI 5.0">
  <img src="https://img.shields.io/badge/License-MIT-red.svg" alt="MIT License">
</p>

**FitVital** is an AI-powered fitness app designed specifically for busy adults aged 30-60. It adapts to your schedule, learns from your behavior, and provides personalized workout plans that fit your life.

## 🚀 Features

### 🏠 **Home Tab**
- **Today's Workout**: Quick access to your scheduled workout
- **Progress Overview**: Weekly completion rings with visual progress tracking
- **Quick Stats**: Streak counter, weekly goal progress, and achievements
- **Recent Activity**: History of completed workouts and missed sessions

### 📅 **Plan Tab**
- **Weekly Planning**: Drag-and-drop workout scheduling
- **Workout Splits**: Choose from Push/Pull/Legs, Upper/Lower, Full Body, or Circuits
- **Auto-Scheduling**: AI automatically fits workouts around your calendar
- **Custom Workouts**: Create and edit personalized workout routines

### 📆 **Calendar Tab**
- **Calendar Integration**: Sync with iOS Calendar via EventKit
- **Smart Scheduling**: Automatically avoid busy blocks
- **Month/Week Views**: Toggle between different calendar perspectives
- **Conflict Detection**: Get notified when workouts conflict with events

### 📊 **Progress Tab**
- **Swift Charts**: Beautiful visual progress tracking
- **Completion Rings**: Animated progress indicators
- **Weekly/Monthly Stats**: Total workouts, streaks, and goal achievement
- **Data Export**: Export progress data in CSV/JSON formats
- **Insights**: AI-generated insights about your fitness journey

### ⚙️ **Settings Tab**
- **Profile Management**: Update goals, preferences, and limitations
- **Notification Settings**: Configure workout reminders and motivational messages
- **Data Management**: Export/import workout data and progress
- **Privacy Controls**: Manage calendar and notification permissions

## 🧠 AI & Adaptive Features

### **Adaptive Behavior Engine**
- **Missed Workout Analysis**: Automatically adjusts difficulty when workouts are consistently missed
- **Pattern Recognition**: Learns your preferred workout times and types
- **Smart Recommendations**: Suggests optimal workout scheduling based on past behavior
- **Difficulty Adjustment**: Dynamically modifies workout intensity based on completion rates

### **Natural Language Processing (NLP)**
- **Weekly Check-ins**: Sunday 6pm prompted reflections with sentiment analysis
- **Injury Detection**: Automatically detects pain mentions and modifies workout plans
- **Motivation Scoring**: Analyzes text feedback to gauge motivation levels
- **Keyword Extraction**: Identifies key themes in user feedback for plan optimization

### **Smart Notifications (6 Types)**
1. **Workout Reminders**: Personalized notifications at preferred times
2. **Weekly Summaries**: Progress reports every Sunday evening
3. **Streak Milestones**: Celebration notifications for achievement streaks
4. **Motivation Messages**: Context-aware encouragement based on behavior
5. **Check-in Prompts**: Weekly reflection reminders with NLP analysis
6. **Adaptive Alerts**: Real-time notifications for plan adjustments

## 🏗️ Architecture

### **MVVM + @Observable Pattern**
```
fitVital/
├── Sources/
│   ├── Models/           # Data models and business logic
│   ├── ViewModels/       # @Observable view models with @MainActor
│   ├── Views/            # SwiftUI views and components
│   ├── Services/         # Business logic and external integrations
│   ├── Persistence/      # CoreData stack and data management
│   ├── Utilities/        # Helper functions and extensions
│   └── Resources/        # Localization and assets
└── Tests/
    ├── UnitTests/        # Comprehensive ViewModel testing
    └── UITests/          # End-to-end user flow testing
```

### **Key Technologies**
- **SwiftUI + Swift Concurrency**: Modern async/await patterns throughout
- **CoreData**: Local data persistence with CloudKit sync support
- **EventKit**: Calendar integration for smart scheduling
- **UserNotifications**: Rich notification system with actionable alerts
- **NaturalLanguage**: Sentiment analysis and keyword extraction
- **Swift Charts**: Beautiful progress visualization
- **Combine**: Reactive programming for data flow

## 📱 Installation

### **Prerequisites**
- iOS 17.0+ device or simulator
- Xcode 15.0+
- Swift 5.9+

### **Setup Instructions**

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/fitvital.git
   cd fitvital
   ```

2. **Open in Xcode**
   ```bash
   open fitVital.xcodeproj
   ```

3. **Configure Capabilities** (Manual - Required)
   - Enable **Push Notifications** capability
   - Add **Calendar (EventKit)** usage description
   - Configure **Background App Refresh**
   - Enable **CoreData with CloudKit** (optional)

4. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd+R` to build and run

## 🎯 Getting Started

### **First Time Setup**
1. **Onboarding Flow**: Complete the 7-step setup process
   - Welcome screen with feature overview
   - Personal information (name)
   - Fitness goal selection (Stay Healthy, Lose Fat, Build Strength, etc.)
   - Weekly frequency preference (1-7 workouts per week)
   - Equipment access (Gym, Dumbbells, Bodyweight, Bands)
   - Preferred workout times (Morning, Afternoon, Evening)
   - Permission setup (Calendar sync, Notifications)

2. **First Workout**: Your personalized plan will be ready immediately
3. **Weekly Check-in**: Every Sunday at 6pm, share how your week went

### **Daily Usage**
1. **Open App**: Check today's scheduled workout
2. **Start Workout**: Follow step-by-step exercise guidance with timer
3. **Complete & Track**: Mark exercises as complete and track progress
4. **Adaptive Learning**: App learns from your behavior and adjusts automatically

## 🔧 Configuration

### **User Preferences**
```swift
// Located in Settings Tab
- Fitness Goal: [stayHealthy, loseFat, buildStrength, maintain, boostEnergy]
- Weekly Frequency: 1-7 workouts per week
- Session Duration: 15-120 minutes
- Equipment Access: Multiple selection from [gym, dumbbells, bodyweight, bands]
- Preferred Times: [morning, afternoon, evening]
- Physical Limitations: Free-text input for injury considerations
- Exercise Dislikes: Exercises to avoid in workout generation
```

### **Notification Settings**
```swift
// Configurable notification types
- Workout Reminders: Daily at preferred times
- Weekly Summaries: Sunday 6pm
- Streak Milestones: Achievement-based
- Motivation Messages: Behavior-triggered
- Check-in Prompts: Weekly
- Adaptive Alerts: Real-time plan adjustments
```

## 🧪 Testing

### **Unit Tests Coverage**
- **HomeViewModel**: 63 test methods (workout generation, completion tracking)
- **PlanViewModel**: 42 test methods (scheduling, auto-planning)
- **CalendarViewModel**: 35 test methods (EventKit integration)
- **ProgressViewModel**: 25 test methods (statistics, charts, export)
- **SettingsViewModel**: 38 test methods (preferences, permissions)

### **UI Tests Coverage**
- **Onboarding Flow**: Complete 7-step user journey
- **Main App Navigation**: All 5 tabs with interaction testing
- **Workout Execution**: Full workout detail view testing

### **Running Tests**
```bash
# Unit Tests
xcodebuild test -project fitVital.xcodeproj -scheme fitVital -destination 'platform=iOS Simulator,name=iPhone 15'

# UI Tests
xcodebuild test -project fitVital.xcodeproj -scheme fitVitalUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📊 Data Models

### **Core Models**
```swift
// User Profile
struct UserProfile {
    let id: UUID
    var name: String
    var fitnessGoal: FitnessGoal
    var weeklyFrequency: Int
    var sessionDuration: TimeInterval
    var equipmentAccess: [EquipmentType]
    var preferredTimes: [TimeOfDay]
    var calendarSynced: Bool
    var fitnessLevel: FitnessLevel
}

// Workout Structure
struct Workout {
    let id: UUID
    var name: String
    var type: WorkoutType
    var difficulty: Difficulty
    var estimatedDuration: TimeInterval
    var exercises: [Exercise]
    var targetMuscles: [MuscleGroup]
    var requiredEquipment: [EquipmentType]
    var scheduledDate: Date
    var isCompleted: Bool
}

// Exercise Details
struct Exercise {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var instructions: String
    var targetMuscles: [MuscleGroup]
    var sets: Int
    var reps: Int
    var duration: TimeInterval
    var restPeriod: TimeInterval
}
```

## 🔐 Privacy & Permissions

### **Required Permissions**
- **Calendar Access**: For smart workout scheduling around events
- **Notifications**: For workout reminders and progress updates
- **HealthKit** (Future): For fitness data integration

### **Data Privacy**
- **Local Storage**: All data stored locally using CoreData
- **No Analytics**: No user behavior tracking or third-party analytics
- **Optional CloudKit**: User can enable cloud sync for data backup
- **Export Control**: Users can export all their data anytime

## 🚧 Future Enhancements

### **Planned Features**
- [ ] **HealthKit Integration**: Heart rate, calories, and workout detection
- [ ] **Apple Watch Support**: Workout tracking on Apple Watch
- [ ] **Social Features**: Share progress with friends and family
- [ ] **Premium Features**: Advanced analytics and custom coaching
- [ ] **Workout Videos**: Exercise demonstration videos
- [ ] **Nutrition Tracking**: Meal planning and calorie tracking
- [ ] **Sleep Integration**: Recovery planning based on sleep quality

### **Technical Improvements**
- [ ] **SwiftData Migration**: Transition from CoreData to SwiftData
- [ ] **Offline-First**: Enhanced offline functionality
- [ ] **Performance Optimization**: Improved app launch time and memory usage
- [ ] **Accessibility**: Enhanced VoiceOver and accessibility features

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### **Development Setup**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Submit a pull request

### **Code Style**
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain @MainActor consistency
- Write comprehensive tests for new features
- Add documentation for public APIs

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### **Getting Help**
- **Documentation**: Check this README and inline code documentation
- **Issues**: Report bugs via [GitHub Issues](https://github.com/your-username/fitvital/issues)
- **Discussions**: Join community discussions in [GitHub Discussions](https://github.com/your-username/fitvital/discussions)

### **Feature Requests**
Have an idea for FitVital? We'd love to hear it! Please open a GitHub Issue with the "enhancement" label.

---

<p align="center">
  Made with ❤️ for busy adults who want to stay fit
</p>

<p align="center">
  <a href="#top">Back to Top</a>
</p> 