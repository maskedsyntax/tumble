import Testing
import Foundation
@testable import TumbleKit

struct RollManagerTests {
    /// Fresh, isolated defaults per test so counters never leak between cases.
    private func makeDefaults() -> UserDefaults {
        let suite = "test.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }

    private final class Clock { var now: Date; init(_ d: Date) { now = d } }

    @Test func freeTierStartsWithTwelve() {
        let roll = RollManager(defaults: makeDefaults(), entitlement: .free)
        #expect(roll.quota == 12)
        #expect(roll.remaining == 12)
        #expect(roll.canShoot)
    }

    @Test func consumingDecrementsAndEmpties() {
        let roll = RollManager(defaults: makeDefaults(), entitlement: .free)
        for _ in 0..<12 { #expect(roll.consumeShot()) }
        #expect(roll.remaining == 0)
        #expect(!roll.canShoot)
        #expect(!roll.consumeShot()) // blocked once empty
    }

    @Test func plusTierGrantsSeventyTwo() {
        let roll = RollManager(defaults: makeDefaults(), entitlement: .plus)
        #expect(roll.quota == 72)
        #expect(roll.remaining == 72)
    }

    @Test func unlimitedNeverBlocks() {
        let roll = RollManager(defaults: makeDefaults(), entitlement: .unlimited)
        #expect(roll.isUnlimited)
        #expect(roll.remaining == nil)
        for _ in 0..<500 { #expect(roll.consumeShot()) }
        #expect(roll.canShoot)
    }

    @Test func rolloverAtLocalMidnightRefillsTheRoll() {
        let clock = Clock(Date(timeIntervalSince1970: 1_700_000_000)) // some day
        let roll = RollManager(defaults: makeDefaults(), entitlement: .free, now: { clock.now })
        for _ in 0..<12 { roll.consumeShot() }
        #expect(roll.remaining == 0)

        // Jump to the next day and refresh — a fresh roll appears.
        clock.now = clock.now.addingTimeInterval(60 * 60 * 24)
        roll.refresh()
        #expect(roll.remaining == 12)
        #expect(roll.canShoot)
    }

    @Test func consumedCountSurvivesReload() {
        let defaults = makeDefaults()
        let a = RollManager(defaults: defaults, entitlement: .free)
        a.consumeShot(); a.consumeShot()
        // A second manager on the same defaults (e.g. the capture extension)
        // sees the same spent count within the same day.
        let b = RollManager(defaults: defaults, entitlement: .free)
        #expect(b.remaining == 10)
    }
}

struct EntitlementTests {
    @Test func highestTierWins() {
        #expect(Entitlement.highest(fromProductIDs: []) == .free)
        #expect(Entitlement.highest(fromProductIDs: ["com.tumble.plus"]) == .plus)
        #expect(Entitlement.highest(fromProductIDs: ["com.tumble.unlimited"]) == .unlimited)
        // Owning both resolves to the most generous.
        #expect(Entitlement.highest(fromProductIDs: ["com.tumble.plus", "com.tumble.unlimited"]) == .unlimited)
    }

    @Test func quotasMatchThePricingTable() {
        #expect(Entitlement.free.dailyQuota == 12)
        #expect(Entitlement.plus.dailyQuota == 72)
        #expect(Entitlement.unlimited.dailyQuota == nil)
    }
}
