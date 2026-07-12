package com.tumble.ui.home

import androidx.compose.animation.core.animate
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Inbox
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.tumble.model.Photo
import com.tumble.model.ageFraction
import com.tumble.ui.components.PrintView
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * The Drawer — an overlapping pile of prints, never a grid. The newest print
 * sits in the middle with the rest arranged on a regular polygon ring around it
 * (triangle → diamond → pentagon … as the pile grows); pinch to spread the ring,
 * drag a print to rearrange the slots. Newest is always on top. Ported from
 * `app/Tumble/Views/DrawerPile.swift`; the geometry lives in [drawerPlacements].
 */
@Composable
fun DrawerPile(
    photos: List<Photo>,
    loadBitmap: (String?) -> ImageBitmap?,
    onTap: (Photo) -> Unit,
    modifier: Modifier = Modifier,
    previewLimit: Int = 15,
    resetToken: Int = 0,
    onResetAvailabilityChange: (Boolean) -> Unit = {},
) {
    if (photos.isEmpty()) {
        LaunchedEffect(Unit) { onResetAvailabilityChange(false) }
        Box(modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Icons.Outlined.Inbox, null, tint = Palette.cream.copy(alpha = 0.4f), modifier = Modifier.size(44.dp))
                Text(
                    "Your drawer is empty.",
                    style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.55f)),
                )
            }
        }
        return
    }

    val scope = rememberCoroutineScope()
    val dragThreshold = 0.22f

    // Pinch-to-spread (0 = tight pile, 1 = fully fanned ring).
    var spread by remember { mutableFloatStateOf(0f) }
    var pinchBase by remember { mutableFloatStateOf(0f) }
    var isPinching by remember { mutableStateOf(false) }

    // Drag-to-rearrange state. `slotOrder` overrides the natural (newest-first)
    // order; empty means "untouched".
    var slotOrder by remember { mutableStateOf<List<String>>(emptyList()) }
    var activeDrag by remember { mutableStateOf<String?>(null) }
    var dragStart by remember { mutableStateOf<Offset?>(null) }
    var activeCenter by remember { mutableStateOf<Offset?>(null) }
    var recentlyDragged by remember { mutableStateOf<String?>(null) }

    val shown = remember(photos, previewLimit) { photos.take(previewLimit) }
    val shownIds = shown.map { it.id }
    val orderedIds = normalizedSlotOrder(slotOrder, shownIds)
    val byId = remember(shown) { shown.associateBy { it.id } }
    val arranged = orderedIds.mapNotNull { byId[it] }

    // Surface reset availability to the parent (the header ↺ button).
    val canReset = spread > 0.05f || orderedIds != shownIds
    LaunchedEffect(canReset) { onResetAvailabilityChange(canReset) }

    // Snap the layout back when the parent bumps the reset token.
    LaunchedEffect(resetToken) {
        if (resetToken == 0) return@LaunchedEffect
        slotOrder = emptyList()
        activeDrag = null
        dragStart = null
        activeCenter = null
        pinchBase = 0f
        animate(spread, 0f, animationSpec = spring(dampingRatio = 0.84f)) { v, _ -> spread = v }
    }

    // Keep drag/slot state coherent as the set of shown prints changes.
    LaunchedEffect(shownIds) {
        activeDrag?.let { if (it !in shownIds) { activeDrag = null; dragStart = null; activeCenter = null } }
        if (slotOrder.isNotEmpty()) {
            val normalized = normalizedSlotOrder(slotOrder, shownIds)
            slotOrder = if (normalized == shownIds) emptyList() else normalized
        }
    }

    BoxWithConstraints(
        modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                // Two-finger pinch → spread. Single-finger touches fall through to
                // the per-print drag detectors below.
                awaitEachGesture {
                    awaitFirstDown(requireUnconsumed = false)
                    var zoomAccum = 1f
                    var pinched = false
                    do {
                        val event = awaitPointerEvent()
                        if (event.changes.size >= 2) {
                            val zoom = event.calculateZoom()
                            if (zoom != 1f) {
                                zoomAccum *= zoom
                                pinched = true
                                isPinching = true
                                spread = (pinchBase + (zoomAccum - 1f) * 1.25f).coerceIn(0f, 1f)
                                event.changes.forEach { it.consume() }
                            }
                        }
                    } while (event.changes.any { it.pressed })
                    if (pinched) {
                        pinchBase = spread
                        isPinching = false
                    }
                }
            },
    ) {
        val density = LocalDensity.current
        val wPx = with(density) { maxWidth.toPx() }
        val hPx = with(density) { maxHeight.toPx() }
        val placements = drawerPlacements(arranged.size, wPx, hPx, spread)
        val activeIndex = activeDrag?.let { id -> arranged.indexOfFirst { it.id == id }.takeIf { it >= 0 } }

        // Latest values for the long-lived drag coroutines to read without
        // restarting the pointer-input pipeline mid-gesture.
        val placementsState = rememberUpdatedState(placements)
        val shownIdsState = rememberUpdatedState(shownIds)
        val boundsState = rememberUpdatedState(Offset(wPx, hPx))

        Layout(
            modifier = Modifier.fillMaxSize(),
            content = {
                arranged.forEachIndexed { index, photo ->
                    val bitmap = remember(photo.rawImageName, photo.isDeveloped) { loadBitmap(photo.rawImageName) }
                    val lifted = activeDrag == photo.id
                    val wobble = if (isPinching) sin(index * 1.7) * 2.2 * spread else 0.0

                    PrintView(
                        image = bitmap,
                        isDeveloped = photo.isDeveloped,
                        developProgress = if (photo.isDeveloped) 1f else 0f,
                        age = photo.ageFraction().toFloat(),
                        caption = photo.caption,
                        width = with(density) { placements.getOrElse(index) { placements.last() }.width.toDp() },
                        modifier = Modifier
                            .graphicsLayer {
                                rotationZ = (photo.rotation * 0.5 + wobble).toFloat()
                                val s = if (lifted) 1.055f else 1f
                                scaleX = s
                                scaleY = s
                            }
                            .pointerInput(photo.id) {
                                detectDragGestures(
                                    onDragStart = {
                                        if (spread <= dragThreshold) return@detectDragGestures
                                        val order = normalizedSlotOrder(slotOrder, shownIdsState.value)
                                        val idx = order.indexOf(photo.id)
                                        val places = placementsState.value
                                        if (idx in places.indices) {
                                            activeDrag = photo.id
                                            dragStart = Offset(places[idx].cx, places[idx].cy)
                                            activeCenter = dragStart
                                        }
                                    },
                                    onDrag = { change, amount ->
                                        if (activeDrag != photo.id) return@detectDragGestures
                                        change.consume()
                                        val from = activeCenter ?: return@detectDragGestures
                                        val places = placementsState.value
                                        val ids = shownIdsState.value
                                        val order = normalizedSlotOrder(slotOrder, ids)
                                        val currentIndex = order.indexOf(photo.id)
                                        if (currentIndex !in places.indices) return@detectDragGestures

                                        val margin = places[currentIndex].width * 0.52f
                                        val bounds = boundsState.value
                                        val proposed = Offset(
                                            (from.x + amount.x).coerceIn(margin, bounds.x - margin),
                                            (from.y + amount.y).coerceIn(margin, bounds.y - margin),
                                        )
                                        val target = swapTargetIndex(proposed, places, currentIndex)
                                        if (target != currentIndex) {
                                            val next = order.toMutableList()
                                                .also { java.util.Collections.swap(it, currentIndex, target) }
                                            slotOrder = if (next == ids) emptyList() else next
                                        } else if (slotOrder.isEmpty()) {
                                            slotOrder = order
                                        }
                                        activeCenter = proposed
                                    },
                                    onDragEnd = {
                                        val moved = activeCenter != null && dragStart != null &&
                                            (activeCenter!! - dragStart!!).getDistance() > 4f
                                        activeDrag = null
                                        dragStart = null
                                        activeCenter = null
                                        if (moved) {
                                            recentlyDragged = photo.id
                                            scope.launch {
                                                delay(180)
                                                if (recentlyDragged == photo.id) recentlyDragged = null
                                            }
                                        }
                                    },
                                    onDragCancel = {
                                        activeDrag = null
                                        dragStart = null
                                        activeCenter = null
                                    },
                                )
                            }
                            .clickable {
                                if (recentlyDragged != photo.id) onTap(photo)
                            },
                    )
                }
            },
        ) { measurables, constraints ->
            val loose = constraints.copy(minWidth = 0, minHeight = 0)
            val placeables = measurables.map { it.measure(loose) }
            layout(constraints.maxWidth, constraints.maxHeight) {
                placeables.forEachIndexed { index, placeable ->
                    val p = placements.getOrNull(index) ?: return@forEachIndexed
                    val lifted = index == activeIndex
                    val center = if (lifted) (activeCenter ?: Offset(p.cx, p.cy)) else Offset(p.cx, p.cy)
                    val x = (center.x - placeable.width / 2f).roundToInt()
                    val y = (center.y - placeable.height / 2f).roundToInt()
                    placeable.place(x, y, zIndex = if (lifted) 1000f else p.z)
                }
            }
        }
    }
}
