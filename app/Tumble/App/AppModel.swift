import SwiftUI
import TumbleAnalytics
import TumbleKit

/// App-wide state: purchases, the account, and editing drafts. Lives as a
/// `@State` on the app and is handed down via environment.
@MainActor
@Observable
final class AppModel {
    let purchases = PurchaseManager()
    let account = AccountCoordinator()
    let drafts = EditDraftStore()
    private var storeStarted = false

    init() {
        TumbleAnalytics.shared.updateEntitlement(purchases.entitlement)
    }

    /// Load StoreKit state and the account's remote entitlements.
    func startStore() async {
        guard !storeStarted else { return }
        storeStarted = true
        await purchases.start()
        await account.start(purchases: purchases)
        syncEntitlement()
    }

    /// Report the resolved entitlement to analytics (call after a purchase/restore).
    func syncEntitlement() {
        TumbleAnalytics.shared.updateEntitlement(purchases.entitlement)
    }
}
