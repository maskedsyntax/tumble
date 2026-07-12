package com.tumble

import androidx.compose.ui.geometry.Offset
import com.tumble.ui.home.Placement
import com.tumble.ui.home.drawerPlacements
import com.tumble.ui.home.normalizedSlotOrder
import com.tumble.ui.home.swapTargetIndex
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Covers the pure drawer geometry + slot helpers ported from Swift
 * `DrawerPile` (`placements`, `normalizedSlotIDs`, `swapTargetIndex`).
 */
class DrawerLayoutTest {
    private val w = 400f
    private val h = 600f

    @Test fun placementCountMatchesInput() {
        for (n in 0..8) {
            assertEquals(n, drawerPlacements(n, w, h, 0f).size)
        }
    }

    @Test fun ringAnchorsNewestInCenterOnTop() {
        val places = drawerPlacements(6, w, h, 0f)
        // Index 0 (newest) sits dead center...
        assertEquals(w / 2f, places[0].cx, 0.001f)
        assertEquals(h / 2f, places[0].cy, 0.001f)
        // ...and on top of the stack.
        val maxZ = places.maxOf { it.z }
        assertEquals(maxZ, places[0].z, 0.001f)
    }

    @Test fun ringStartsAtTopVertex() {
        val n = 5
        val places = drawerPlacements(n, w, h, 0f)
        val k = n - 1
        // Surrounding prints are index 1..k.
        assertEquals(k, places.size - 1)
        // First surrounding print sits above center (top vertex, -90°).
        val first = places[1]
        assertEquals(w / 2f, first.cx, 0.5f)
        assertTrue("expected top vertex above center", first.cy < places[0].cy)
    }

    @Test fun spreadWidensTheRing() {
        val tight = drawerPlacements(6, w, h, 0f)
        val wide = drawerPlacements(6, w, h, 1f)
        // The top vertex should sit higher (smaller y) as the ring fans out.
        assertTrue(wide[1].cy < tight[1].cy)
    }

    @Test fun allPlacementsStayInsideBounds() {
        for (n in 1..8) {
            for (s in listOf(0f, 0.5f, 1f)) {
                for (p in drawerPlacements(n, w, h, s)) {
                    assertTrue("cx in bounds", p.cx in 0f..w)
                    assertTrue("cy in bounds", p.cy in 0f..h)
                }
            }
        }
    }

    @Test fun normalizedSlotOrderIsIdentityWhenUntouched() {
        val ids = listOf("a", "b", "c")
        assertEquals(ids, normalizedSlotOrder(emptyList(), ids))
    }

    @Test fun normalizedSlotOrderKeepsArrangementDropsMissingAppendsNew() {
        // Saved order [c, a] against shown [a, b, c] → keep c, a, then append b.
        val ordered = normalizedSlotOrder(listOf("c", "a", "gone"), listOf("a", "b", "c"))
        assertEquals(listOf("c", "a", "b"), ordered)
    }

    @Test fun normalizedSlotOrderDedupes() {
        val ordered = normalizedSlotOrder(listOf("a", "a", "b"), listOf("a", "b"))
        assertEquals(listOf("a", "b"), ordered)
    }

    @Test fun swapTargetIsCurrentWhenNotMoved() {
        val places = drawerPlacements(6, w, h, 0f)
        val here = Offset(places[2].cx, places[2].cy)
        assertEquals(2, swapTargetIndex(here, places, 2))
    }

    @Test fun swapTargetPicksNeighborWhenDraggedOntoIt() {
        // Two prints close together; dragging index 0 onto index 1's slot swaps.
        val places = listOf(
            Placement(100f, 100f, 120f, 1f),
            Placement(160f, 100f, 120f, 0f),
        )
        val ontoNeighbor = Offset(160f, 100f)
        assertNotEquals(0, swapTargetIndex(ontoNeighbor, places, 0))
        assertEquals(1, swapTargetIndex(ontoNeighbor, places, 0))
    }
}
