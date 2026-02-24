//
//  Maze_100UITests.swift
//  Maze 100UITests
//
//  Created by Dmitrii on 21.02.2026.
//

import XCTest

final class Maze_100UITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testSettingsSheetOpensAndCloses() throws {
        let settingsButton = app.buttons["main.settings.button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        let settingsTitle = app.staticTexts["settings.title"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5))
        
        let doneButton = app.buttons["settings.done.button"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
        
        XCTAssertFalse(settingsTitle.waitForExistence(timeout: 2))
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 2))
    }
    
    @MainActor
    func testLevelOneLaunchPauseAndResume() throws {
        let levelOneButton = app.buttons["main.level.1"]
        XCTAssertTrue(levelOneButton.waitForExistence(timeout: 5))
        levelOneButton.tap()
        
        let pauseButton = app.buttons["game.pause.button"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 10))
        pauseButton.tap()
        
        let resumeButton = app.buttons["pause.resume.button"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 5))
        resumeButton.tap()
        
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5))
    }

}
