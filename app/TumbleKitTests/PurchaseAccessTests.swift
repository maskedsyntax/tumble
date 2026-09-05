import Testing
@testable import TumbleKit

struct PurchaseAccessTests {
    @Test @MainActor func revenueCatCompleteUnlocksTheFullCatalog() {
        let purchases = PurchaseManager()
        purchases.applyRemoteEntitlements(["complete"])

        #expect(purchases.accessState == .complete)
        #expect(FilmStockCatalog.all.allSatisfy(purchases.isUnlocked))
    }

    @Test @MainActor func legacyRevenueCatPacksRemainScoped() {
        let purchases = PurchaseManager()
        purchases.applyRemoteEntitlements(["pack_nineties", "pack_summer"])

        #expect(purchases.accessState.unlocks(FilmStockCatalog.resolve("disposable")))
        #expect(!purchases.accessState.unlocks(FilmStockCatalog.resolve("silver")))
    }

    @Test @MainActor func signingOutCanRemoveRemoteAccessWithoutTouchingStoreState() {
        let purchases = PurchaseManager()
        purchases.applyRemoteEntitlements(["complete"])
        #expect(purchases.accessState == .complete)

        purchases.applyRemoteEntitlements([])
        #expect(purchases.remoteEntitlementIDs.isEmpty)
    }
}
