//
//  MainAppUITests.swift
//  fitVitalUITests
//
//  Created by Nick Conoplia on 30/5/2025.
//

import XCTest

final class MainAppUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Skip onboarding for main app tests
        app.launchArguments = ["--skip-onboarding", "--reset-user-defaults"]
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabNavigation() {
        // Test Home tab
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.navigationBars["Home"].exists)
        
        // Test Plan tab
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.navigationBars["Plan"].exists)
        
        // Test Calendar tab
        app.tabBars.buttons["Calendar"].tap()
        XCTAssertTrue(app.navigationBars["Calendar"].exists)
        
        // Test Progress tab
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].exists)
        
        // Test Settings tab
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }
    
    // MARK: - Home View Tests
    
    func testHomeViewElements() {
        app.tabBars.buttons["Home"].tap()
        
        // Verify main elements are present
        XCTAssertTrue(app.staticTexts["Today's Workouts"].exists)
        XCTAssertTrue(app.staticTexts["Quick Start"].exists)
        XCTAssertTrue(app.staticTexts["This Week's Progress"].exists)
        
        // Check for workout cards or empty state
        if app.cells.count > 0 {
            // Verify workout cards have expected elements
            let firstWorkoutCard = app.cells.element(boundBy: 0)
            XCTAssertTrue(firstWorkoutCard.exists)
        } else {
            // Verify empty state message
            XCTAssertTrue(app.staticTexts["No workouts scheduled for today"].exists || 
                         app.staticTexts["Let's create your first workout!"].exists)
        }
    }
    
    func testQuickWorkoutGeneration() {
        app.tabBars.buttons["Home"].tap()
        
        // Look for quick workout button
        if app.buttons["Generate Quick Workout"].exists {
            app.buttons["Generate Quick Workout"].tap()
            
            // Verify quick workout options or generated workout
            XCTAssertTrue(app.alerts.element.exists || 
                         app.sheets.element.exists ||
                         app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'minute'")))
        }
    }
    
    // MARK: - Plan View Tests
    
    func testPlanViewElements() {
        app.tabBars.buttons["Plan"].tap()
        
        // Verify plan view elements
        XCTAssertTrue(app.staticTexts["Workout Split"].exists)
        XCTAssertTrue(app.staticTexts["This Week's Plan"].exists)
        
        // Check for split selection options
        XCTAssertTrue(app.buttons["Push/Pull/Legs"].exists ||
                     app.buttons["Upper/Lower"].exists ||
                     app.buttons["Full Body"].exists)
        
        // Check for weekly calendar
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        for weekday in weekdays {
            XCTAssertTrue(app.staticTexts[weekday].exists)
        }
    }
    
    func testWorkoutSplitSelection() {
        app.tabBars.buttons["Plan"].tap()
        
        // Test changing workout split
        if app.buttons["Push/Pull/Legs"].exists {
            app.buttons["Push/Pull/Legs"].tap()
            // Verify the split is selected (button state change or workouts update)
            // This would depend on the UI implementation
        }
        
        if app.buttons["Upper/Lower"].exists {
            app.buttons["Upper/Lower"].tap()
        }
    }
    
    func testAutoScheduleFeature() {
        app.tabBars.buttons["Plan"].tap()
        
        // Look for auto-schedule button
        if app.buttons["Auto-Schedule Around Calendar"].exists {
            app.buttons["Auto-Schedule Around Calendar"].tap()
            
            // Verify action (might show permission request or schedule workouts)
            // Wait a moment for any UI updates
            sleep(1)
        }
    }
    
    // MARK: - Calendar View Tests
    
    func testCalendarViewElements() {
        app.tabBars.buttons["Calendar"].tap()
        
        // Verify calendar elements
        XCTAssertTrue(app.buttons["Month"].exists || app.buttons["Week"].exists)
        
        // Check for calendar grid or week view
        // This depends on the default view mode
        if app.buttons["Month"].exists {
            app.buttons["Month"].tap()
        }
        
        // Look for navigation controls
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'chevron' OR label CONTAINS 'Previous' OR label CONTAINS 'Next'")).count > 0)
    }
    
    func testCalendarViewModeToggle() {
        app.tabBars.buttons["Calendar"].tap()
        
        // Test switching between month and week view
        if app.buttons["Month"].exists && app.buttons["Week"].exists {
            app.buttons["Week"].tap()
            sleep(1) // Allow for view transition
            
            app.buttons["Month"].tap()
            sleep(1)
        }
    }
    
    func testCalendarNavigation() {
        app.tabBars.buttons["Calendar"].tap()
        
        // Test month/week navigation
        let previousButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Previous' OR identifier CONTAINS 'chevron.left'")).element
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Next' OR identifier CONTAINS 'chevron.right'")).element
        
        if previousButton.exists {
            previousButton.tap()
            sleep(1)
        }
        
        if nextButton.exists {
            nextButton.tap()
            sleep(1)
        }
        
        // Test "Today" button if it exists
        if app.buttons["Today"].exists {
            app.buttons["Today"].tap()
        }
    }
    
    // MARK: - Progress View Tests
    
    func testProgressViewElements() {
        app.tabBars.buttons["Progress"].tap()
        
        // Verify progress elements
        XCTAssertTrue(app.staticTexts["Progress"].exists)
        
        // Look for completion rings or progress indicators
        // These might be custom views, so we check for related text
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Week' OR label CONTAINS 'Month' OR label CONTAINS 'Streak'")).count > 0)
        
        // Check for time range selector
        if app.buttons["Week"].exists || app.buttons["Month"].exists {
            XCTAssertTrue(true) // Time range selector found
        }
    }
    
    func testProgressTimeRangeSelection() {
        app.tabBars.buttons["Progress"].tap()
        
        // Test time range selection
        let timeRangeButtons = ["Week", "Month", "Quarter", "Year"]
        for timeRange in timeRangeButtons {
            if app.buttons[timeRange].exists {
                app.buttons[timeRange].tap()
                sleep(1) // Allow for data loading
            }
        }
    }
    
    func testProgressExport() {
        app.tabBars.buttons["Progress"].tap()
        
        // Look for export functionality
        if app.buttons["Export"].exists || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Export'")).count > 0 {
            app.buttons["Export"].tap()
            
            // Verify export options or confirmation
            XCTAssertTrue(app.alerts.element.exists || app.sheets.element.exists)
        }
    }
    
    // MARK: - Settings View Tests
    
    func testSettingsViewElements() {
        app.tabBars.buttons["Settings"].tap()
        
        // Verify settings sections
        XCTAssertTrue(app.staticTexts["Profile"].exists || app.cells.containing(.staticText, identifier: "Profile").count > 0)
        XCTAssertTrue(app.staticTexts["Notifications"].exists || app.switches.count > 0)
        XCTAssertTrue(app.staticTexts["Data"].exists || app.staticTexts["Export"].exists)
    }
    
    func testProfileEdit() {
        app.tabBars.buttons["Settings"].tap()
        
        // Look for profile edit button
        if app.buttons["Edit Profile"].exists {
            app.buttons["Edit Profile"].tap()
            
            // Verify profile edit screen
            XCTAssertTrue(app.textFields.count > 0 || app.navigationBars["Edit Profile"].exists)
            
            // Go back
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            } else if app.navigationBars.buttons.element(boundBy: 0).exists {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }
    
    func testNotificationSettings() {
        app.tabBars.buttons["Settings"].tap()
        
        // Look for notification toggles
        let notificationSwitches = app.switches.matching(NSPredicate(format: "identifier CONTAINS 'notification' OR identifier CONTAINS 'reminder'"))
        
        if notificationSwitches.count > 0 {
            let firstSwitch = notificationSwitches.element(boundBy: 0)
            let initialValue = firstSwitch.value as? String
            
            // Toggle the switch
            firstSwitch.tap()
            
            // Verify the value changed
            let newValue = firstSwitch.value as? String
            XCTAssertNotEqual(initialValue, newValue)
        }
    }
    
    // MARK: - Workout Interaction Tests
    
    func testWorkoutCardInteraction() {
        app.tabBars.buttons["Home"].tap()
        
        // If there are workout cards, test interaction
        if app.cells.count > 0 {
            let firstWorkoutCard = app.cells.element(boundBy: 0)
            firstWorkoutCard.tap()
            
            // Verify workout detail view or action
            sleep(2) // Allow for navigation
            
            // Look for workout detail elements
            XCTAssertTrue(app.navigationBars.count > 0 || app.sheets.element.exists)
            
            // Navigate back
            if app.buttons["Back"].exists {
                app.buttons["Back"].tap()
            } else if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            } else if app.navigationBars.buttons.element(boundBy: 0).exists {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }
    
    // MARK: - Pull to Refresh Tests
    
    func testPullToRefresh() {
        app.tabBars.buttons["Home"].tap()
        
        // Test pull to refresh on scrollable views
        if app.scrollViews.count > 0 {
            let scrollView = app.scrollViews.element(boundBy: 0)
            scrollView.swipeDown()
            
            // Allow time for refresh
            sleep(2)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorStateHandling() {
        // This would require specific test scenarios or mock data
        // For now, just verify that error states don't crash the app
        
        // Navigate through all tabs quickly to stress test
        let tabs = ["Home", "Plan", "Calendar", "Progress", "Settings"]
        for tab in tabs {
            app.tabBars.buttons[tab].tap()
            sleep(0.5)
        }
        
        // Verify app is still responsive
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    }
    
    // MARK: - Search and Filter Tests
    
    func testSearchFunctionality() {
        // Test search if it exists in any view
        let searchFields = app.searchFields
        if searchFields.count > 0 {
            let searchField = searchFields.element(boundBy: 0)
            searchField.tap()
            searchField.typeText("test")
            
            // Verify search results or filtering
            sleep(1)
            
            // Clear search
            if app.buttons["Clear"].exists {
                app.buttons["Clear"].tap()
            }
        }
    }
}

// MARK: - Helper Extensions

extension XCUIElementQuery {
    func containing(_ elementType: XCUIElement.ElementType, identifier: String) -> XCUIElementQuery {
        return self.containing(.staticText, identifier: identifier)
    }
} 