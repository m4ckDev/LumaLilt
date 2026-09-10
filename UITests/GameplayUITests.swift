import XCTest

final class GameplayUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-swapTutorialCompleted", "NO", "-numbers", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["skip-practice"].waitForExistence(timeout: 10))
        return app
    }

    private func startPuzzle(_ app: XCUIApplication) {
        app.buttons["skip-practice"].tap()
        let start = app.buttons["Start a fresh puzzle"]
        for _ in 0..<5 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        start.tap()
        let replace = app.buttons["Start fresh"]
        if replace.waitForExistence(timeout: 2) { replace.tap() }
        XCTAssertTrue(app.buttons["tile-0"].waitForExistence(timeout: 5))
    }

    private func values(_ app: XCUIApplication) -> [String] {
        (0..<9).map { app.buttons["tile-\($0)"].value as? String ?? "missing" }
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testGuidedPracticeMovesOnlyTheChosenPair() {
        let app = launch()
        let original = values(app)
        XCTAssertEqual(original, ["2", "1", "3", "4", "5", "6", "7", "9", "8"])
        app.buttons["tile-0"].tap()
        app.buttons["tile-1"].tap()
        XCTAssertEqual(values(app), ["1", "2", "3", "4", "5", "6", "7", "9", "8"])
        app.buttons["tile-7"].tap()
        app.buttons["tile-8"].tap()
        XCTAssertTrue(app.otherElements["practice-complete"].exists || app.staticTexts["Practice complete"].exists)
        attach(app, "Completed guided practice")
    }

    func testDiagonalSwapAndSingleUndoRestoreBoard() {
        let app = launch()
        startPuzzle(app)
        let original = values(app)
        XCTAssertFalse(original.contains("missing"))
        // Choose a pair that cannot complete the puzzle so Undo remains available.
        var destination = 8
        var expected = original
        expected.swapAt(0, destination)
        if expected == (1...9).map(String.init) {
            destination = 4
            expected = original
            expected.swapAt(0, destination)
        }
        app.buttons["tile-0"].tap()
        app.buttons["tile-\(destination)"].tap()
        XCTAssertEqual(values(app), expected)
        let undo = app.buttons["undo-move"]
        for _ in 0..<3 where !undo.isHittable { app.swipeUp() }
        XCTAssertTrue(undo.isHittable)
        undo.tap()
        XCTAssertEqual(values(app), original)
        XCTAssertTrue(app.buttons["target-preview"].isHittable)
        attach(app, "Swap and single Undo")
    }

    func testHintPreservesCorrectTilesAndTargetCanOpen() {
        let app = launch()
        startPuzzle(app)
        let original = values(app)
        let hint = app.buttons["apply-hint"]
        for _ in 0..<3 where !hint.isHittable { app.swipeUp() }
        hint.tap()
        let after = values(app)
        let correctBefore = original.indices.filter { original[$0] == String($0 + 1) }
        for index in correctBefore { XCTAssertEqual(after[index], original[index]) }
        XCTAssertGreaterThan(after.indices.filter { after[$0] == String($0 + 1) }.count, correctBefore.count)
        app.buttons["target-preview"].tap()
        XCTAssertTrue(app.navigationBars["Your destination"].waitForExistence(timeout: 3))
        attach(app, "Expanded target")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["target-preview"].isHittable)
    }
}
