package com.tumble.roll

import com.tumble.model.Entitlement

/**
 * Synchronous, snapshot-style persistence for the daily Roll. Kept as a small
 * interface so `RollManager` mirrors the iOS `UserDefaults`-backed logic and
 * stays unit-testable with an in-memory fake.
 *
 * The iOS app shares these three keys with its lock-screen extension via an App
 * Group; on Android the concrete implementation (Phase 4) is backed by prefs so
 * the widget/tile can read the same counter.
 */
interface RollStore {
    var consumedToday: Int
    /** `LocalDate.toEpochDay()` of the last midnight rollover, or -1 if never. */
    var lastResetEpochDay: Long
    var entitlement: Entitlement
}

/** In-memory store for tests and previews. */
class InMemoryRollStore(
    override var consumedToday: Int = 0,
    override var lastResetEpochDay: Long = -1,
    override var entitlement: Entitlement = Entitlement.FREE,
) : RollStore
