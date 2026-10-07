import XCTest

final class TumbleThreeOneUITests: XCTestCase {
    @MainActor
    func testSampleIntroductionNeedsNoPermissionAndReachesConsent() {
        let app = XCUIApplication()
        app.launchArguments = ["-introductionDemo"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Give your photos the character of film."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Compare Original"].exists)
        XCTAssertTrue(app.buttons["Photo"].exists)
        XCTAssertTrue(app.buttons["Postcard"].exists)
        app.buttons["Start with my photo"].tap()
        XCTAssertTrue(app.alerts["Help improve Tumble?"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testEditingFirstHome() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboard"]
        app.launch()

        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Take a Photo"].exists)
        XCTAssertTrue(app.staticTexts["A signature finish"].exists)
    }

    @MainActor
    func testStudioRoutesToFinish() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboard", "-studioDemo", "-demoStock", "fadedInstant"]
        app.launch()
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Compare"].exists)
        XCTAssertTrue(app.buttons["Crop"].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["Film"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["Crop"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["Core"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["Adjust film amount"].frame.height, 44)
        app.buttons["Adjust film amount"].tap()
        XCTAssertTrue(app.buttons["Done adjusting film amount"].exists)
        app.buttons["Done adjusting film amount"].tap()
        app.buttons["Crop"].tap()
        XCTAssertTrue(app.buttons["Rotate"].waitForExistence(timeout: 3))
        app.buttons["Film"].tap()
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Finish"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Photo"].exists)
        XCTAssertTrue(app.buttons["Postcard"].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["Photo"].frame.height, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["Postcard"].frame.height, 44)
    }

    @MainActor
    func testNewEditOpensPickerWithoutReplacementPrompt() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboard", "-clearDraft"]
        app.launch()
        let choosePhoto = app.buttons["Choose a Photo"]
        XCTAssertTrue(choosePhoto.waitForExistence(timeout: 5))
        choosePhoto.tap()
        XCTAssertFalse(app.buttons["Start New Edit"].exists)
        XCTAssertFalse(app.staticTexts["Start a new edit?"].exists)
    }

    @MainActor
    func testPremiumFilmCanBePreviewedBeforeExportGate() {
        let app = XCUIApplication()
        app.launchArguments = ["-skipOnboard", "-finishDemo", "-demoStock", "goldenHour"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Finish"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Unlock to Save"].exists)
        app.buttons["Unlock to Save"].tap()
        XCTAssertTrue(app.staticTexts["Tumble Complete"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPostcardFinishUsesOnePreviewAndCompactStylePicker() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-skipOnboard", "-finishDemo", "-demoStock", "fadedInstant",
            "-demoFrame", "classicInstant", "-demoNote", "Wish you were here",
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Finish"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Classic Instant"].exists)
        XCTAssertTrue(app.buttons["Classic Instant"].isSelected)
        XCTAssertEqual(app.otherElements.matching(identifier: "Postcard style preview").count, 1)
        app.buttons["Vintage Postcard"].tap()
        XCTAssertTrue(app.buttons["Vintage Postcard"].isSelected)
        XCTAssertEqual(app.otherElements.matching(identifier: "Postcard style preview").count, 1)
    }

    @MainActor
    func testCropToolEditsOnTheCanvas() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-skipOnboard", "-studioDemo", "-demoStock", "fadedInstant",
            "-studioTool", "crop", "-demoCrop", "portrait",
        ]
        app.launch()

        XCTAssertTrue(app.buttons["Rotate"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Reset crop"].exists)
        XCTAssertTrue(app.buttons["4 by 5"].isSelected)
        XCTAssertTrue(app.descendants(matching: .any)["Straighten"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Crop"].firstMatch.exists)
        app.buttons["Square"].tap()
        XCTAssertTrue(app.buttons["Square"].isSelected)
        app.buttons["Film"].tap()
        XCTAssertTrue(app.buttons["Compare"].waitForExistence(timeout: 3))
    }
}
