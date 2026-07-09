package com.tumble

import com.tumble.model.Photo
import com.tumble.model.ageFraction
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.Instant
import kotlin.math.abs

/** Mirrors `PhotoAgingTests` in `TumbleKitTests/PhotoAgingTests.swift`. */
class PhotoAgingTest {
    @Test fun freshPrintHasNoAge() {
        val now = Instant.now()
        val photo = Photo.create(capturedAt = now)
        assertTrue(photo.ageFraction(now) < 0.001)
    }

    @Test fun agingReachesFullAtTheSpan() {
        val captured = Instant.EPOCH
        val photo = Photo.create(capturedAt = captured)
        val now = captured.plus(Photo.agingSpan)
        assertEquals(1.0, photo.ageFraction(now), 0.0)
    }

    @Test fun agingIsClampedAndMonotonic() {
        val captured = Instant.EPOCH
        val photo = Photo.create(capturedAt = captured)
        val half = photo.ageFraction(captured.plus(Photo.agingSpan.dividedBy(2)))
        val quarter = photo.ageFraction(captured.plus(Photo.agingSpan.dividedBy(4)))
        assertTrue(quarter < half)
        assertTrue(abs(half - 0.5) < 0.01)
        assertEquals(1.0, photo.ageFraction(captured.plus(Photo.agingSpan.multipliedBy(5))), 0.0)
    }
}
