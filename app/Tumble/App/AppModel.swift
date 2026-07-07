import SwiftUI
import SwiftData
import TumbleKit

/// App-wide state: the daily Roll and the capture pipeline. Purchases are wired
/// in later. Lives as a `@State` on the app and is handed down via environment.
@MainActor
@Observable
final class AppModel {
    let roll: RollManager
    let purchases = PurchaseManager()
    let cameraActivity = TumbleCameraActivityCoordinator()

    /// The just-captured print, surfaced so the UI can animate it tossing into
    /// the Drawer.
    var lastCaptured: Photo?

    /// Current number of prints in the Drawer, kept current by the home screen
    /// so the background Live Activity can show it.
    var capturedCount = 0

    init(roll: RollManager = RollManager()) {
        self.roll = roll
    }

    /// Load StoreKit state and point the Roll at the owned tier.
    func startStore() async {
        await purchases.start()
        syncEntitlement()
    }

    /// Push the resolved entitlement into the Roll (call after a purchase/restore).
    func syncEntitlement() {
        roll.entitlement = purchases.entitlement
    }

    /// Coming to the foreground: pick up a midnight rollover, and **end** the
    /// Live Activity so the Dynamic Island is a plain, fully app-owned surface -
    /// the whole island stays grabbable while you're in the app.
    func enterForeground() {
        roll.refresh()
        cameraActivity.end()
    }

    /// Going to the background: show the Live Activity as a glanceable status
    /// surface in the island / Lock Screen.
    func enterBackground() {
        cameraActivity.start(remainingLabel: roll.remainingLabel, capturedCount: capturedCount)
    }

    /// Store a freshly shot frame: spend a shot, persist the raw bytes, and drop
    /// an *undeveloped* print into the Drawer. Returns false if the roll is empty.
    @discardableResult
    func store(rawImage: UIImage, in context: ModelContext) -> Bool {
        guard let photo = CaptureService.store(rawImage: rawImage, source: .app, roll: roll, in: context) else {
            return false
        }
        lastCaptured = photo
        return true
    }
}
