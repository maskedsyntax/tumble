package com.tumble

import com.tumble.model.Entitlement
import org.junit.Assert.assertEquals
import org.junit.Test

/** Mirrors `EntitlementTests` in `TumbleKitTests/RollManagerTests.swift`. */
class EntitlementTest {
    @Test fun highestTierWins() {
        assertEquals(Entitlement.FREE, Entitlement.highest(emptySet()))
        assertEquals(Entitlement.PLUS, Entitlement.highest(setOf("com.tumble.plus")))
        assertEquals(Entitlement.UNLIMITED, Entitlement.highest(setOf("com.tumble.unlimited")))
        assertEquals(
            Entitlement.UNLIMITED,
            Entitlement.highest(setOf("com.tumble.plus", "com.tumble.unlimited")),
        )
    }

    @Test fun quotasMatchThePricingTable() {
        assertEquals(12, Entitlement.FREE.dailyQuota)
        assertEquals(72, Entitlement.PLUS.dailyQuota)
        assertEquals(null, Entitlement.UNLIMITED.dailyQuota)
    }
}
