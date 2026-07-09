package com.tumble

import com.tumble.develop.Develop
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Covers the shake-to-develop maths ported from `DevelopView`/`ShakeMonitor`. */
class DevelopTest {
    @Test fun gentleMotionIsBelowThreshold() {
        // 1.05g of total motion → jolt 0.05, under the 0.12 threshold.
        assertNull(Develop.shakeEnergy(1.05))
    }

    @Test fun realShakeProducesEnergy() {
        // 1.5g → jolt 0.5 → energy 0.25.
        assertEquals(0.25, Develop.shakeEnergy(1.5)!!, 1e-9)
    }

    @Test fun energyIsCappedAtOne() {
        assertEquals(1.0, Develop.shakeEnergy(10.0)!!, 1e-9)
    }

    @Test fun advanceClampsToOneAndCompletes() {
        var p = 0.0
        // Hold ticks accumulate toward full development.
        repeat(100) { p = Develop.advanced(p, Develop.HOLD_STEP) }
        assertEquals(1.0, p, 0.0)
        assertTrue(Develop.isDeveloped(p))
    }

    @Test fun freshPrintIsNotDeveloped() {
        assertFalse(Develop.isDeveloped(0.0))
        assertFalse(Develop.isDeveloped(0.99))
        assertTrue(Develop.isDeveloped(1.0))
    }
}
