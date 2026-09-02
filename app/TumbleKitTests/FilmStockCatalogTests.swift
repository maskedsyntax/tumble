import Testing
import UIKit
@testable import TumbleKit

struct FilmStockCatalogTests {
    // MARK: Catalog integrity

    @Test func stockIDsAreUnique() {
        let ids = FilmStockCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyStockBelongsToAKnownPack() {
        let packIDs = Set(FilmStockCatalog.packs.map(\.id))
        for stock in FilmStockCatalog.all {
            #expect(packIDs.contains(stock.packID))
        }
    }

    @Test func packProductIDsAreUniqueAndNamespaced() {
        let productIDs = FilmStockCatalog.packs.compactMap(\.productID)
        #expect(Set(productIDs).count == productIDs.count)
        for id in productIDs {
            #expect(id.hasPrefix("com.tumble.pack."))
        }
    }

    // MARK: Bundle

    @Test func bundleIsNamespacedAndNotAPack() {
        #expect(FilmStockCatalog.bundleProductID.hasPrefix("com.tumble.pack."))
        // The bundle unlocks packs, it is never itself one.
        #expect(!FilmStockCatalog.packs.compactMap(\.productID).contains(FilmStockCatalog.bundleProductID))
    }

    @Test func everyPaidPackUnlocksViaItsOwnProductOrTheBundle() {
        for pack in FilmStockCatalog.packs where !pack.isFree {
            let ids = FilmStockCatalog.unlockProductIDs(for: pack.id)
            #expect(ids.contains(pack.productID!))
            #expect(ids.contains(FilmStockCatalog.bundleProductID))
        }
    }

    @Test func freePackNeedsNoUnlockProduct() {
        #expect(FilmStockCatalog.unlockProductIDs(for: FilmStockCatalog.PackID.core).isEmpty)
        #expect(FilmStockCatalog.unlockProductIDs(for: "nonsense").isEmpty)
    }

    @Test func allProductIDsCoversEveryPaidPackPlusTheBundle() {
        let ids = FilmStockCatalog.allProductIDs
        #expect(Set(ids).count == ids.count)
        #expect(ids.contains(FilmStockCatalog.bundleProductID))
        for pack in FilmStockCatalog.packs where !pack.isFree {
            #expect(ids.contains(pack.productID!))
        }
    }

    @Test func exactlyOnePackIsFree() {
        let free = FilmStockCatalog.packs.filter(\.isFree)
        #expect(free.count == 1)
        #expect(free.first?.id == FilmStockCatalog.PackID.core)
    }

    @Test func tumbleThreeCatalogHasSixFreeAndFifteenPremiumStocks() {
        let free = FilmStockCatalog.all.filter { $0.packID == FilmStockCatalog.PackID.core }
        #expect(FilmStockCatalog.all.count == 21)
        #expect(free.count == 6)
        #expect(FilmStockCatalog.all.count - free.count == 15)
    }

    @Test func accessStatesPreserveFreePackAndCompleteUnlock() {
        let free = AccessState.free(legacyPackIDs: [])
        #expect(free.unlocks(FilmStockCatalog.resolve("fadedInstant")))
        #expect(!free.unlocks(FilmStockCatalog.resolve("silver")))
        #expect(AccessState.complete.unlocks(FilmStockCatalog.resolve("silver")))
        #expect(AccessState.free(legacyPackIDs: ["darkroom"]).unlocks(FilmStockCatalog.resolve("silver")))
    }

    @Test func groupedByPackCoversEveryStockInPackOrder() {
        let grouped = FilmStockCatalog.groupedByPack
        #expect(grouped.map(\.pack.id) == FilmStockCatalog.packs.map(\.id))
        let flattened = grouped.flatMap { $0.stocks.map(\.id) }
        #expect(Set(flattened) == Set(FilmStockCatalog.all.map(\.id)))
    }

    // MARK: Resolution & defaults

    @Test func resolveFallsBackToDefaultForUnknownID() {
        #expect(FilmStockCatalog.resolve("does-not-exist").id == FilmStockCatalog.defaultStock.id)
        #expect(FilmStockCatalog.resolve(nil).id == FilmStockCatalog.defaultStock.id)
    }

    @Test func defaultStockIsTheV1FadedInstant() {
        // The default must stay the v1.1 look so upgrades don't silently regrade.
        #expect(FilmStockCatalog.defaultStock.id == FilmStockCatalog.LegacyID.fadedInstant)
    }

    @Test func legacyPresetIDsStillResolve() {
        // These strings are persisted on shipped devices - they must resolve forever.
        #expect(FilmStockCatalog.stock(for: FilmStockCatalog.LegacyID.fadedInstant) != nil)
        #expect(FilmStockCatalog.stock(for: FilmStockCatalog.LegacyID.warmArchive) != nil)
    }

    // MARK: Migration

    @Test func storedMigratesV1PresetKey() {
        let defaults = UserDefaults(suiteName: "test.migration.\(UUID().uuidString)")!
        defaults.set(FilmStockCatalog.LegacyID.warmArchive, forKey: FilmStockCatalog.legacyPresetKey)

        let migrated = FilmStockCatalog.stored(in: defaults)

        #expect(migrated.id == FilmStockCatalog.LegacyID.warmArchive)
        // The new key is written and the old one cleared.
        #expect(defaults.string(forKey: FilmStockCatalog.storageKey) == FilmStockCatalog.LegacyID.warmArchive)
        #expect(defaults.string(forKey: FilmStockCatalog.legacyPresetKey) == nil)
    }

    @Test func storedPrefersNewKeyOverLegacy() {
        let defaults = UserDefaults(suiteName: "test.newkey.\(UUID().uuidString)")!
        defaults.set("silver", forKey: FilmStockCatalog.storageKey)
        defaults.set(FilmStockCatalog.LegacyID.warmArchive, forKey: FilmStockCatalog.legacyPresetKey)

        #expect(FilmStockCatalog.stored(in: defaults).id == "silver")
    }

    @Test func storedFallsBackToDefaultWhenEmpty() {
        let defaults = UserDefaults(suiteName: "test.empty.\(UUID().uuidString)")!
        #expect(FilmStockCatalog.stored(in: defaults).id == FilmStockCatalog.defaultStock.id)
    }
}

struct LRUCacheTests {
    @Test func evictsLeastRecentlyUsed() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.set(1, for: "a")
        cache.set(2, for: "b")
        _ = cache.value(for: "a")     // a is now most-recent
        cache.set(3, for: "c")        // evicts b (LRU)

        #expect(cache.value(for: "a") == 1)
        #expect(cache.value(for: "b") == nil)
        #expect(cache.value(for: "c") == 3)
    }

    @Test func updatingKeyKeepsItAndDoesNotGrow() {
        let cache = LRUCache<String, Int>(capacity: 2)
        cache.set(1, for: "a")
        cache.set(2, for: "b")
        cache.set(9, for: "a")        // update, not insert
        cache.set(3, for: "c")        // evicts b, not a

        #expect(cache.value(for: "a") == 9)
        #expect(cache.value(for: "b") == nil)
        #expect(cache.value(for: "c") == 3)
    }

    @Test func removeAllClears() {
        let cache = LRUCache<String, Int>(capacity: 4)
        cache.set(1, for: "a")
        cache.removeAll()
        #expect(cache.value(for: "a") == nil)
    }
}
