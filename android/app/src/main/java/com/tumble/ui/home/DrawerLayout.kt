package com.tumble.ui.home

import androidx.compose.ui.geometry.Offset
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Pure geometry + slot-ordering helpers for the drawer pile, extracted so they
 * can be unit-tested without composing anything. Ported from the Swift
 * `app/Tumble/Views/DrawerPile.swift` (`placements`, `normalizedSlotIDs`,
 * `swapTargetIndex`). All maths are in pixels; the composable converts widths to
 * Dp at the [com.tumble.ui.components.PrintView] boundary.
 */

/** One print's placement: a center point, a stock width, and a stacking z. */
data class Placement(val cx: Float, val cy: Float, val width: Float, val z: Float)

/**
 * Lays out [count] prints (index 0 = newest) inside a [w] x [h] area.
 *
 * - 1: a single print in the middle.
 * - 2: a horizontal pair.
 * - 3: a vertical trio.
 * - 4+: the newest print in the middle, the remaining `count - 1` on a regular
 *   polygon around it (a vertex at the top, so the ring reads as an upright
 *   triangle / diamond / pentagon … as the count grows).
 *
 * [spread] (0…1) eases the ring outward and the stock slightly smaller — driven
 * by the pinch gesture.
 */
fun drawerPlacements(count: Int, w: Float, h: Float, spread: Float): List<Placement> {
    val cx = w / 2f
    val cy = h * 0.5f
    val spacing = 1f + spread * 0.55f
    val sizeEase = 1f - spread * 0.06f

    return when {
        count <= 0 -> emptyList()
        count == 1 -> listOf(Placement(cx, cy, w * 0.50f, 0f))
        count == 2 -> {
            val pw = w * 0.46f * sizeEase
            listOf(
                Placement(cx - w * 0.21f * spacing, cy, pw, 1f),
                Placement(cx + w * 0.21f * spacing, cy, pw, 0f),
            )
        }
        count == 3 -> {
            val pw = w * 0.44f * sizeEase
            listOf(
                Placement(cx, cy - h * 0.23f * spacing, pw, 2f),
                Placement(cx, h * 0.50f, pw, 1f),
                Placement(cx, cy + h * 0.23f * spacing, pw, 0f),
            )
        }
        else -> {
            val k = count - 1 // surrounding prints
            val rx = w * (0.30f + 0.16f * spread)
            val ry = h * (0.25f + 0.13f * spread)
            val centerW = w * 0.40f * sizeEase
            val surroundW = w * min(0.38f, max(0.22f, (0.86f / sqrt(k.toFloat())))) * sizeEase

            val out = ArrayList<Placement>(count)
            // Newest sits in the middle, on top.
            out.add(Placement(cx, cy, centerW, count.toFloat()))
            for (i in 0 until k) {
                // Start at the top (-90°) and step evenly around the ring.
                val angle = (-90.0 + i * 360.0 / k) * Math.PI / 180.0
                val rawX = cx + rx * cos(angle).toFloat()
                val rawY = cy + ry * sin(angle).toFloat()
                val margin = surroundW * 0.52f
                out.add(
                    Placement(
                        cx = rawX.coerceIn(margin, w - margin),
                        cy = rawY.coerceIn(margin, h - margin),
                        width = surroundW,
                        z = (k - i).toFloat(),
                    )
                )
            }
            out
        }
    }
}

/**
 * Reconciles a saved [slotOrder] against the currently [shownIds]: keeps the
 * user's arrangement for ids that are still present (deduped), then appends any
 * new ids in their natural order. An empty [slotOrder] means "untouched" and
 * returns [shownIds] unchanged. Mirror of Swift `normalizedSlotIDs`.
 */
fun normalizedSlotOrder(slotOrder: List<String>, shownIds: List<String>): List<String> {
    if (slotOrder.isEmpty()) return shownIds

    val seen = HashSet<String>()
    val ordered = ArrayList<String>(shownIds.size)
    for (id in slotOrder) {
        if (id in shownIds && seen.add(id)) ordered.add(id)
    }
    for (id in shownIds) {
        if (seen.add(id)) ordered.add(id)
    }
    return ordered
}

/**
 * Given a dragged print's live [center], returns the placement index it should
 * swap into — the nearest other slot, but only once it's meaningfully closer
 * than the print's own slot and within a size-scaled threshold. Otherwise
 * returns [currentIndex]. Mirror of Swift `swapTargetIndex`.
 */
fun swapTargetIndex(center: Offset, placements: List<Placement>, currentIndex: Int): Int {
    if (currentIndex !in placements.indices || placements.size <= 1) return currentIndex

    val own = placements[currentIndex]
    val ownDistance = hypot(center.x - own.cx, center.y - own.cy)

    var bestIndex = currentIndex
    var bestDistance = Float.MAX_VALUE
    for (index in placements.indices) {
        if (index == currentIndex) continue
        val p = placements[index]
        val d = hypot(center.x - p.cx, center.y - p.cy)
        if (d < bestDistance) {
            bestDistance = d
            bestIndex = index
        }
    }

    val threshold = (max(own.width, placements[bestIndex].width) * 0.7f).coerceIn(62f, 145f)
    return if (bestDistance + 12f < ownDistance && bestDistance < threshold) bestIndex else currentIndex
}
