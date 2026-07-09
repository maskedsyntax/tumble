package com.tumble

import com.tumble.model.Entitlement
import com.tumble.roll.InMemoryRollStore
import com.tumble.roll.RollManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Duration
import java.time.Instant
import java.time.ZoneOffset

/** Mirrors `RollManagerTests` in `TumbleKitTests/RollManagerTests.swift`. */
class RollManagerTest {
    private fun manager(
        entitlement: Entitlement = Entitlement.FREE,
        now: () -> Instant = { Instant.ofEpochSecond(1_700_000_000) },
    ) = RollManager(
        store = InMemoryRollStore(entitlement = entitlement),
        zone = ZoneOffset.UTC,
        now = now,
    )

    @Test fun freeTierStartsWithTwelve() {
        val roll = manager(Entitlement.FREE)
        assertEquals(12, roll.quota)
        assertEquals(12, roll.remaining)
        assertTrue(roll.canShoot)
    }

    @Test fun consumingDecrementsAndEmpties() {
        val roll = manager(Entitlement.FREE)
        repeat(12) { assertTrue(roll.consumeShot()) }
        assertEquals(0, roll.remaining)
        assertFalse(roll.canShoot)
        assertFalse(roll.consumeShot())
    }

    @Test fun plusTierGrantsSeventyTwo() {
        val roll = manager(Entitlement.PLUS)
        assertEquals(72, roll.quota)
        assertEquals(72, roll.remaining)
    }

    @Test fun shotsLeftSentencePluralizesCorrectly() {
        assertEquals("0 shots left today.", RollManager.shotsLeftSentence(0))
        assertEquals("1 shot left today.", RollManager.shotsLeftSentence(1))
        assertEquals("2 shots left today.", RollManager.shotsLeftSentence(2))
        assertEquals("72 shots left today.", RollManager.shotsLeftSentence(72))
    }

    @Test fun unlimitedNeverBlocks() {
        val roll = manager(Entitlement.UNLIMITED)
        assertTrue(roll.isUnlimited)
        assertNull(roll.remaining)
        repeat(500) { assertTrue(roll.consumeShot()) }
        assertTrue(roll.canShoot)
    }

    @Test fun rolloverAtLocalMidnightRefillsTheRoll() {
        var now = Instant.ofEpochSecond(1_700_000_000)
        val roll = RollManager(
            store = InMemoryRollStore(entitlement = Entitlement.FREE),
            zone = ZoneOffset.UTC,
            now = { now },
        )
        repeat(12) { roll.consumeShot() }
        assertEquals(0, roll.remaining)

        now = now.plus(Duration.ofDays(1))
        roll.refresh()
        assertEquals(12, roll.remaining)
        assertTrue(roll.canShoot)
    }

    @Test fun consumedCountSurvivesReload() {
        val store = InMemoryRollStore(entitlement = Entitlement.FREE)
        val now = { Instant.ofEpochSecond(1_700_000_000) }
        val a = RollManager(store, ZoneOffset.UTC, now)
        a.consumeShot(); a.consumeShot()
        // A second manager on the same store (e.g. the widget) sees the same
        // spent count within the same day.
        val b = RollManager(store, ZoneOffset.UTC, now)
        assertEquals(10, b.remaining)
    }
}
