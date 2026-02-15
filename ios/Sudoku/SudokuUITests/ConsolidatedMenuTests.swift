import XCTest

/// Test the consolidated menu flows: New Game, Progress, Import
final class ConsolidatedMenuTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test 1: New Game (Difficulty list with SE sliders)

    func testNewGamePicker() throws {
        let newGameButton = app.buttons["New Game"]
        XCTAssertTrue(newGameButton.waitForExistence(timeout: 5), "New Game button should exist")
        newGameButton.tap()
        sleep(1)

        // Should see unified difficulty list
        let screenshot1 = XCUIScreen.main.screenshot()
        let attach1 = XCTAttachment(screenshot: screenshot1)
        attach1.name = "01_NewGame_DifficultyList"
        attach1.lifetime = .keepAlways
        add(attach1)

        // Tap a difficulty to expand SE slider
        let mediumButton = app.staticTexts["Medium"]
        if mediumButton.waitForExistence(timeout: 2) {
            mediumButton.tap()
            sleep(1)

            let screenshot2 = XCUIScreen.main.screenshot()
            let attach2 = XCTAttachment(screenshot: screenshot2)
            attach2.name = "02_NewGame_SESliderExpanded"
            attach2.lifetime = .keepAlways
            add(attach2)
        }

        // Dismiss
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
            sleep(1)
        }
    }

    // MARK: - Test 2: Progress (Stats + Library + Leaderboard tabs)

    func testProgressHub() throws {
        let progressButton = app.buttons["Progress"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 5), "Progress button should exist")
        progressButton.tap()
        sleep(1)

        // Stats tab (default)
        let screenshot1 = XCUIScreen.main.screenshot()
        let attach1 = XCTAttachment(screenshot: screenshot1)
        attach1.name = "03_Progress_Stats"
        attach1.lifetime = .keepAlways
        add(attach1)

        // Tap Library tab
        let libraryTab = app.buttons["Library"]
        if libraryTab.waitForExistence(timeout: 2) {
            libraryTab.tap()
            sleep(1)

            let screenshot2 = XCUIScreen.main.screenshot()
            let attach2 = XCTAttachment(screenshot: screenshot2)
            attach2.name = "04_Progress_Library"
            attach2.lifetime = .keepAlways
            add(attach2)
        }

        // Tap Leaderboard tab
        let leaderboardTab = app.buttons["Leaderboard"]
        if leaderboardTab.waitForExistence(timeout: 2) {
            leaderboardTab.tap()
            sleep(1)

            let screenshot3 = XCUIScreen.main.screenshot()
            let attach3 = XCTAttachment(screenshot: screenshot3)
            attach3.name = "05_Progress_Leaderboard"
            attach3.lifetime = .keepAlways
            add(attach3)
        }

        // Dismiss
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
            sleep(1)
        }
    }

    // MARK: - Test 3: Import (Unified Camera)

    func testImportCamera() throws {
        let importButton = app.buttons["Import"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 5), "Import button should exist")
        importButton.tap()
        sleep(2)

        // Should see the unified camera full-screen cover
        // On simulator there's no real camera, but the view should appear
        let screenshot1 = XCUIScreen.main.screenshot()
        let attach1 = XCTAttachment(screenshot: screenshot1)
        attach1.name = "06_Import_UnifiedCamera"
        attach1.lifetime = .keepAlways
        add(attach1)

        // Dismiss via X button
        let closeButton = app.buttons["xmark"]
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
            sleep(1)
        }
    }
}
