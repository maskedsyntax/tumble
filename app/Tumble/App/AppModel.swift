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

    /// The just-captured print, surfaced so the UI can animate it tossing into
    /// the Drawer.
    var lastCaptured: Photo?

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

    /// Pick up a midnight rollover whenever the app returns to the foreground.
    func refresh() { roll.refresh() }

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
