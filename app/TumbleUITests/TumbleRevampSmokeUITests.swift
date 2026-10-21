import XCTest

/// End-to-end passes through the 3.1 interface using real interactions
/// (system photo picker, gestures, sheets, relaunches) rather than debug
/// routes alone.
final class TumbleRevampSmokeUITests: XCTestCase {
    @MainActor private var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: Helpers

    @MainActor
    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    @MainActor
    private func pickFirstLibraryPhoto(in app: XCUIApplication) {
        let photo = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10), "Photo picker did not show photos")
        photo.tap()
    }

    @MainActor
    private func waitForStudio(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 15), "Studio did not open")
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: app.buttons["Next"])
        waitForExpectations(timeout: 15)
    }

    /// Horizontal SwiftUI strips are not scrolled automatically by XCUITest.
    /// Swipes on whichever item of the strip is currently on screen (a real
    /// swipe, so nothing in the strip is tapped).
    @MainActor
    private func reveal(_ element: XCUIElement, inStripOf siblings: XCUIElementQuery) {
        let screen = XCUIApplication().windows.firstMatch.frame
        func visible(_ candidate: XCUIElement) -> Bool {
            let frame = candidate.frame
            return frame.midX > screen.minX + 20 && frame.midX < screen.maxX - 20
        }
        var attempts = 0
        while !visible(element) && attempts < 6 {
            guard let anchor = siblings.allElementsBoundByIndex.first(where: visible) else { break }
            anchor.swipeLeft(velocity: .slow)
            attempts += 1
        }
        XCTAssertTrue(visible(element), "Could not scroll \(element) into view")
    }

    @MainActor
    private func allowPhotosIfAsked() {
        for label in ["Allow Full Access", "Allow", "OK"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 3) {
                button.tap()
                return
            }
        }
    }

    // MARK: Library → Studio → Crop → Finish → Save

    @MainActor
    func testLibraryPhotoThroughStudioCropAndSave() {
        let app = launch(["-skipOnboard", "-clearDraft"])
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 8))
        app.buttons["Choose a Photo"].tap()
        pickFirstLibraryPhoto(in: app)
        waitForStudio(app)

        // Pick a free Core film, then open and cancel the amount panel.
        app.buttons["Core"].tap()
        let everyday = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Everyday'")).firstMatch
        XCTAssertTrue(everyday.waitForExistence(timeout: 5))
        // Film thumbnails are labelled "Name. Blurb".
        let strip = app.buttons.matching(NSPredicate(format: "label CONTAINS '. '"))
        reveal(everyday, inStripOf: strip)
        // The last-used film persists between runs, so it may already be
        // selected; the first tap selects, a tap on the selected film opens
        // the amount panel.
        if !everyday.isSelected { everyday.tap() }
        XCTAssertTrue(everyday.isSelected)
        everyday.tap()
        XCTAssertTrue(app.buttons["Done adjusting film amount"].waitForExistence(timeout: 3))
        let slider = app.descendants(matching: .any)["Film amount"].firstMatch
        XCTAssertTrue(slider.exists)
        slider.swipeLeft()
        app.buttons["Cancel film amount"].tap()
        XCTAssertTrue(app.buttons["Adjust film amount"].waitForExistence(timeout: 3))

        // Compare toggles and returns.
        app.buttons["Compare"].tap()
        XCTAssertEqual(app.buttons["Compare"].value as? String, "Showing original")
        app.buttons["Compare"].tap()
        XCTAssertEqual(app.buttons["Compare"].value as? String, "Showing film")

        // Crop: choose a shape, drag the crop, rotate, straighten.
        app.buttons["Crop"].tap()
        XCTAssertTrue(app.buttons["Rotate"].waitForExistence(timeout: 5))
        app.buttons["Square"].tap()
        XCTAssertTrue(app.buttons["Square"].isSelected)
        let crop = app.otherElements.matching(identifier: "Crop").firstMatch
        XCTAssertTrue(crop.waitForExistence(timeout: 5))
        let before = crop.frame
        let center = crop.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.05, thenDragTo: crop.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)))
        let corner = crop.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
            .withOffset(CGVector(dx: 2, dy: 2))
        corner.press(forDuration: 0.05, thenDragTo: crop.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)))
        XCTAssertNotEqual(crop.frame, before, "Crop rectangle did not respond to dragging")

        let ruler = app.descendants(matching: .any)["Straighten"].firstMatch
        XCTAssertTrue(ruler.exists)
        ruler.swipeLeft()
        XCTAssertNotEqual(ruler.value as? String, "0°")

        app.buttons["Rotate"].tap()
        app.buttons["Free"].tap()
        XCTAssertTrue(app.buttons["Free"].isSelected)

        // Back to Film, on to Finish, save as a photo.
        app.buttons["Film"].tap()
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Finish"].waitForExistence(timeout: 8))
        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 8))
        save.tap()
        // The confirmation is brief, so only answer a permission alert if one
        // is actually up, then watch for the confirmation.
        let saved = app.staticTexts["Saved to Photos"]
        if !saved.waitForExistence(timeout: 2), springboard.alerts.firstMatch.exists {
            allowPhotosIfAsked()
        }
        XCTAssertTrue(saved.exists || saved.waitForExistence(timeout: 8), "No save confirmation")

        // Back on Home with the draft cleared.
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue your edit'")).firstMatch.exists)
    }

    // MARK: Home

    @MainActor
    func testHomeScrollsFromTheHeroAndFilmCardOpensPicker() {
        let app = launch(["-skipOnboard", "-clearDraft"])
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 8))
        let postcard = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'A signature finish'")).firstMatch
        XCTAssertTrue(postcard.exists)

        // A horizontal drag on the before/after hero moves its divider...
        let hero = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Example photo'")).firstMatch
        XCTAssertTrue(hero.exists)
        let splitBefore = hero.value as? String
        hero.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: hero.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)))
        XCTAssertNotEqual(hero.value as? String, splitBefore, "Dragging the hero did not move its divider")

        // ...and a vertical swipe that starts on it must scroll.
        let start = hero.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.01, thenDragTo: hero.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -0.6)))
        XCTAssertLessThan(app.buttons["Choose a Photo"].frame.minY, 300, "Home did not scroll from the hero")

        // Each film card opens the picker.
        let silver = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Silver'")).firstMatch
        XCTAssertTrue(silver.waitForExistence(timeout: 5))
        let cards = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH 'Faded Instant' OR label BEGINSWITH 'Disposable' OR label BEGINSWITH 'Silver' OR label BEGINSWITH 'Golden Hour'"
        ))
        reveal(silver, inStripOf: cards)
        silver.tap()
        XCTAssertTrue(app.images.matching(identifier: "PXGGridLayout-Info").firstMatch.waitForExistence(timeout: 10))
        pickFirstLibraryPhoto(in: app)
        waitForStudio(app)
        let silverThumb = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Silver'")).firstMatch
        XCTAssertTrue(silverThumb.waitForExistence(timeout: 5))
        XCTAssertTrue(silverThumb.isSelected, "Film card did not carry its film into Studio")
    }

    @MainActor
    func testPostcardCardStartsInPostcardFinish() {
        let app = launch(["-skipOnboard", "-clearDraft"])
        let postcard = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'A signature finish'")).firstMatch
        XCTAssertTrue(postcard.waitForExistence(timeout: 8))
        app.swipeUp()
        postcard.tap()
        pickFirstLibraryPhoto(in: app)
        waitForStudio(app)
        app.buttons["Next"].tap()
        XCTAssertTrue(app.buttons["Classic Instant"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Postcard"].isSelected)
    }

    // MARK: Drafts

    @MainActor
    func testDiscardReturnsHomeWithoutADraft() {
        let app = launch(["-skipOnboard", "-clearDraft", "-studioDemo", "-demoStock", "fadedInstant"])
        waitForStudio(app)
        app.buttons["Cancel editing"].tap()
        let discard = app.buttons["Discard draft"]
        XCTAssertTrue(discard.waitForExistence(timeout: 3))
        discard.tap()
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue your edit'")).firstMatch.exists)
    }

    @MainActor
    func testDraftSurvivesRelaunchWithCropAndStraighten() {
        var app = launch([
            "-skipOnboard", "-clearDraft", "-studioDemo", "-demoStock", "silver",
            "-demoCrop", "portrait", "-demoStraighten", "6",
        ])
        waitForStudio(app)
        sleep(1) // let the debounced draft write land
        app.terminate()

        app = launch(["-skipOnboard"])
        let resume = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue your edit'")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 8), "Draft was not offered after relaunch")
        XCTAssertTrue(resume.label.contains("Silver"))
        resume.tap()
        waitForStudio(app)
        app.buttons["Crop"].tap()
        XCTAssertTrue(app.buttons["4 by 5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["4 by 5"].isSelected)
        XCTAssertEqual(app.descendants(matching: .any)["Straighten"].firstMatch.value as? String, "6°")
    }

    // MARK: Finish

    @MainActor
    func testPostcardNoteFramesAndShareSheet() {
        let app = launch([
            "-skipOnboard", "-clearDraft", "-finishDemo", "-demoStock", "fadedInstant",
            "-demoFrame", "classicInstant",
        ])
        XCTAssertTrue(app.buttons["Deckled Edge"].waitForExistence(timeout: 12))
        for frame in ["Vintage Postcard", "Bordered Film", "Deckled Edge", "Classic Instant"] {
            app.buttons[frame].tap()
            XCTAssertTrue(app.buttons[frame].isSelected, "\(frame) did not select")
        }
        let note = app.textFields["Postcard note"]
        XCTAssertTrue(note.exists)
        note.tap()
        note.typeText("Hello from Lisbon\n")
        XCTAssertTrue(app.staticTexts["17/60"].waitForExistence(timeout: 3) || app.otherElements["Postcard style preview"].exists)

        app.buttons["Photo"].tap()
        XCTAssertFalse(app.buttons["Classic Instant"].exists)
        app.buttons["Postcard"].tap()
        XCTAssertTrue(app.buttons["Classic Instant"].waitForExistence(timeout: 3))

        app.buttons["Share"].tap()
        let shareSheet = app.otherElements["ActivityListView"].firstMatch
        let close = app.buttons["Close"].firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10) || close.waitForExistence(timeout: 2), "Share sheet did not appear")
        if close.exists { close.tap() } else { app.swipeDown() }
        XCTAssertTrue(app.staticTexts["Finish"].waitForExistence(timeout: 5))

        app.buttons["Back to Studio"].tap()
        waitForStudio(app)
    }

    @MainActor
    func testPremiumGateOpensAndClosesPaywall() {
        let app = launch(["-skipOnboard", "-clearDraft", "-finishDemo", "-demoStock", "goldenHour"])
        XCTAssertTrue(app.buttons["Unlock to Save"].waitForExistence(timeout: 12))
        app.buttons["Share"].tap()
        XCTAssertTrue(app.staticTexts["Tumble Complete"].waitForExistence(timeout: 5), "Share did not gate a premium film")
        XCTAssertTrue(app.staticTexts["One-time purchase · No subscription"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Unlock to Save"].waitForExistence(timeout: 5))
        app.buttons["Unlock to Save"].tap()
        XCTAssertTrue(app.staticTexts["Tumble Complete"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.staticTexts["Finish"].waitForExistence(timeout: 5))
    }

    // MARK: Other surfaces

    @MainActor
    func testSettingsAccountAndPaywallRoundTrip() {
        let app = launch(["-skipOnboard", "-clearDraft", "-previewFreeSettings"])
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 8))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        let account = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Tumble account'")).firstMatch
        XCTAssertTrue(account.exists)
        account.tap()
        XCTAssertTrue(app.staticTexts["Keep your films with you"].waitForExistence(timeout: 5))
        app.buttons["Done"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        let upgrade = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Unlock every film'")).firstMatch
        if upgrade.exists {
            upgrade.tap()
            XCTAssertTrue(app.staticTexts["Tumble Complete"].waitForExistence(timeout: 5))
            app.buttons["Close"].tap()
        }
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        app.navigationBars["Settings"].buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFinishedPhotoLandsInDrawerAndReopensInStudio() {
        let app = launch(["-skipOnboard", "-clearDraft", "-finishDemo", "-demoStock", "fadedInstant"])
        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 15))
        save.tap()
        let saved = app.staticTexts["Saved to Photos"]
        if !saved.waitForExistence(timeout: 2), springboard.alerts.firstMatch.exists {
            allowPhotosIfAsked()
        }
        XCTAssertTrue(saved.exists || saved.waitForExistence(timeout: 8), "No save confirmation")

        let drawerCard = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Your Drawer'")).firstMatch
        XCTAssertTrue(drawerCard.waitForExistence(timeout: 10), "Home does not show the Drawer after a save")
        drawerCard.tap()

        // Newest first, so the first finished photo is the one just saved.
        let print = app.buttons.matching(NSPredicate(format: "label CONTAINS ' photo, '")).firstMatch
        XCTAssertTrue(print.waitForExistence(timeout: 5), "The saved photo is not in the Drawer")
        print.tap()
        XCTAssertTrue(app.buttons["Save to Photos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Share"].exists)
        app.buttons["Edit Again"].tap()
        waitForStudio(app)
    }

    @MainActor
    func testSavedPostcardIsFiledAsAPostcard() {
        let app = launch([
            "-skipOnboard", "-clearDraft", "-finishDemo", "-demoStock", "fadedInstant",
            "-demoFrame", "classicInstant", "-demoNote", "Lisbon, again",
        ])
        let save = app.buttons["Save"]
        XCTAssertTrue(save.waitForExistence(timeout: 15))
        save.tap()
        let saved = app.staticTexts["Saved to Photos"]
        if !saved.waitForExistence(timeout: 2), springboard.alerts.firstMatch.exists {
            allowPhotosIfAsked()
        }
        XCTAssertTrue(app.buttons["Drawer"].waitForExistence(timeout: 10))
        app.buttons["Drawer"].tap()
        let postcard = app.buttons.matching(NSPredicate(format: "label CONTAINS ' postcard, '")).firstMatch
        XCTAssertTrue(postcard.waitForExistence(timeout: 5), "The saved postcard is not in the Drawer")
    }

    @MainActor
    func testRollPrintsStayInTheDrawer() {
        let app = launch(["-skipOnboard", "-clearDraft", "-seed", "-count", "3"])
        XCTAssertTrue(app.buttons["Drawer"].waitForExistence(timeout: 8))
        app.buttons["Drawer"].tap()
        XCTAssertTrue(app.staticTexts["From the roll"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Nothing in your Drawer yet"].exists)
        app.buttons["Close Drawer"].tap()
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testReplayIntroductionFromSettings() {
        let app = launch(["-skipOnboard", "-clearDraft"])
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 8))
        app.buttons["Settings"].tap()
        let replay = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Try the introduction again'")).firstMatch
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()
        XCTAssertTrue(app.buttons["Start with my photo"].waitForExistence(timeout: 8))
        app.buttons["Disposable"].tap()
        XCTAssertTrue(app.buttons["Disposable"].isSelected)
        app.buttons["Postcard"].tap()
        app.buttons["Compare Original"].tap()
        XCTAssertTrue(app.buttons["Show Film"].waitForExistence(timeout: 3))
        app.buttons["Start with my photo"].tap()
        let notNow = app.buttons["Not now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 5))
        notNow.tap()
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testUpgradingUserSeesWhatsNewThenHome() {
        // Launch-argument defaults override the app's own writes, so this
        // checks the screen and its action rather than the following launch.
        let app = launch(["-tumble.hasOnboarded", "YES", "-tumble.v3.1.hasIntroduced", "NO", "-clearDraft"])
        XCTAssertTrue(app.staticTexts["Tumble is now a Studio"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Crop and straighten right on the photo"].exists)
        XCTAssertTrue(app.buttons["Enter the Studio"].isHittable)
        app.buttons["Enter the Studio"].tap()
    }

    @MainActor
    func testCameraOpensAndCloses() {
        let app = launch(["-skipOnboard", "-clearDraft"])
        XCTAssertTrue(app.buttons["Take a Photo"].waitForExistence(timeout: 8))
        app.buttons["Take a Photo"].tap()
        for label in ["Allow", "OK", "Don’t Allow", "Don't Allow"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 2) { button.tap(); break }
        }
        let close = app.buttons["Close camera"]
        XCTAssertTrue(close.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Take photo"].exists)
        close.tap()
        XCTAssertTrue(app.buttons["Choose a Photo"].waitForExistence(timeout: 8))
    }
}
