//
//  OnboardingUITests.swift
//  fitVitalUITests
//
//  Created by Nick Conoplia on 30/5/2025.
//

import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Reset app state for consistent testing
        app.launchArguments = ["--reset-user-defaults"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Complete Onboarding Flow Tests
    
    func testCompleteOnboardingFlow() throws {
        // Test Welcome Screen
        testWelcomeScreen()
        
        // Test Name Input
        testNameInput()
        
        // Test Goal Selection
        testGoalSelection()
        
        // Test Frequency Selection
        testFrequencySelection()
        
        // Test Equipment Selection
        testEquipmentSelection()
        
        // Test Time Preferences
        testTimePreferences()
        
        // Test Permissions
        testPermissions()
        
        // Verify completion and navigation to main app
        verifyOnboardingCompletion()
    }
    
    func testWelcomeScreen() {
        // Verify welcome screen elements
        XCTAssertTrue(app.staticTexts["Welcome to FitVital"].exists)
        XCTAssertTrue(app.staticTexts["Your personal fitness companion"].exists)
        XCTAssertTrue(app.buttons["Get Started"].exists)
        
        // Tap Get Started
        app.buttons["Get Started"].tap()
    }
    
    func testNameInput() {
        // Verify name input screen
        XCTAssertTrue(app.staticTexts["What's your name?"].exists)
        XCTAssertTrue(app.textFields["Enter your name"].exists)
        XCTAssertTrue(app.buttons["Continue"].exists)
        
        // Enter name
        let nameField = app.textFields["Enter your name"]
        nameField.tap()
        nameField.typeText("Test User")
        
        // Verify Continue button is enabled and tap it
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
    }
    
    func testGoalSelection() {
        // Verify goal selection screen
        XCTAssertTrue(app.staticTexts["What's your primary goal?"].exists)
        
        // Verify goal options are present
        XCTAssertTrue(app.buttons["Lose Weight"].exists)
        XCTAssertTrue(app.buttons["Build Muscle"].exists)
        XCTAssertTrue(app.buttons["Improve Endurance"].exists)
        XCTAssertTrue(app.buttons["General Fitness"].exists)
        
        // Select a goal
        app.buttons["Build Muscle"].tap()
        
        // Continue to next step
        app.buttons["Continue"].tap()
    }
    
    func testFrequencySelection() {
        // Verify frequency selection screen
        XCTAssertTrue(app.staticTexts["How often do you want to work out?"].exists)
        
        // Verify frequency options
        for frequency in 1...7 {
            XCTAssertTrue(app.buttons["\(frequency)"].exists)
        }
        
        // Select frequency
        app.buttons["4"].tap()
        
        // Continue to next step
        app.buttons["Continue"].tap()
    }
    
    func testEquipmentSelection() {
        // Verify equipment selection screen
        XCTAssertTrue(app.staticTexts["What equipment do you have access to?"].exists)
        
        // Verify equipment options
        XCTAssertTrue(app.buttons["Bodyweight Only"].exists)
        XCTAssertTrue(app.buttons["Dumbbells"].exists)
        XCTAssertTrue(app.buttons["Barbell"].exists)
        XCTAssertTrue(app.buttons["Full Gym"].exists)
        
        // Select equipment (multiple selection allowed)
        app.buttons["Dumbbells"].tap()
        app.buttons["Barbell"].tap()
        
        // Continue to next step
        app.buttons["Continue"].tap()
    }
    
    func testTimePreferences() {
        // Verify time preferences screen
        XCTAssertTrue(app.staticTexts["When do you prefer to work out?"].exists)
        
        // Verify time options
        XCTAssertTrue(app.buttons["Morning"].exists)
        XCTAssertTrue(app.buttons["Afternoon"].exists)
        XCTAssertTrue(app.buttons["Evening"].exists)
        
        // Select preferred time
        app.buttons["Morning"].tap()
        
        // Continue to next step
        app.buttons["Continue"].tap()
    }
    
    func testPermissions() {
        // Verify permissions screen
        XCTAssertTrue(app.staticTexts["Enable Smart Features"].exists)
        
        // Verify permission options
        XCTAssertTrue(app.buttons["Enable Notifications"].exists)
        XCTAssertTrue(app.buttons["Enable Calendar Access"].exists)
        XCTAssertTrue(app.buttons["Skip for Now"].exists)
        
        // For testing, skip permissions to avoid system dialogs
        app.buttons["Skip for Now"].tap()
    }
    
    func verifyOnboardingCompletion() {
        // Wait for main app to load
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        
        // Verify all main tabs are present
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Plan"].exists)
        XCTAssertTrue(app.tabBars.buttons["Calendar"].exists)
        XCTAssertTrue(app.tabBars.buttons["Progress"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
    
    // MARK: - Individual Step Tests
    
    func testOnboardingStepNavigation() {
        // Start onboarding
        app.buttons["Get Started"].tap()
        
        // Test back navigation (if available)
        if app.buttons["Back"].exists {
            app.buttons["Back"].tap()
            XCTAssertTrue(app.staticTexts["Welcome to FitVital"].exists)
            app.buttons["Get Started"].tap()
        }
        
        // Proceed through steps with minimal input
        let nameField = app.textFields["Enter your name"]
        nameField.tap()
        nameField.typeText("Test")
        app.buttons["Continue"].tap()
        
        app.buttons["General Fitness"].tap()
        app.buttons["Continue"].tap()
        
        app.buttons["3"].tap()
        app.buttons["Continue"].tap()
        
        app.buttons["Bodyweight Only"].tap()
        app.buttons["Continue"].tap()
        
        app.buttons["Morning"].tap()
        app.buttons["Continue"].tap()
        
        app.buttons["Skip for Now"].tap()
        
        // Verify completion
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
    }
    
    func testOnboardingValidation() {
        // Test that Continue is disabled without required input
        app.buttons["Get Started"].tap()
        
        // Name field should require input
        let continueButton = app.buttons["Continue"]
        XCTAssertFalse(continueButton.isEnabled)
        
        // Add name and verify Continue is enabled
        let nameField = app.textFields["Enter your name"]
        nameField.tap()
        nameField.typeText("Test User")
        XCTAssertTrue(continueButton.isEnabled)
    }
    
    func testOnboardingSkip() {
        // If there's a skip option, test it
        if app.buttons["Skip"].exists {
            app.buttons["Skip"].tap()
            XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        }
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    var isEnabled: Bool {
        return self.exists && self.isHittable && value(forKey: "isEnabled") as? Bool != false
    }
} 