package com.tumble.ui.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.outlined.FolderOpen
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleResumeEffect
import com.tumble.model.PhotoDay
import com.tumble.ui.components.CircleIconButton
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType

/**
 * The Drawer home surface: header + stats, the scattered pile of today's prints,
 * collection rows for prior days, and camera access. Ported from
 * `app/Tumble/Screens/HomeScreen.swift`.
 */
@Composable
fun HomeScreen(
    onOpenPrint: (String, Boolean) -> Unit,
    onOpenDay: (Long) -> Unit,
    onOpenPaywall: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel(),
) {
    LifecycleResumeEffect(Unit) {
        viewModel.onResume()
        onPauseOrDispose { }
    }

    val days by viewModel.days.collectAsState()
    val today = days.firstOrNull { it.displayTitle == "Today" }
    val collections = days.filter { it.displayTitle != "Today" }.take(3)

    // Drawer layout reset: the pile reports when it's been pinched/rearranged, and
    // bumping the token snaps it back. Mirrors iOS `drawerCanReset`/`drawerResetToken`.
    var drawerCanReset by remember { mutableStateOf(false) }
    var drawerResetToken by remember { mutableIntStateOf(0) }

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .safeContentPadding()
                .padding(horizontal = 20.dp, vertical = 0.dp)
                .padding(top = 44.dp),
        ) {
            // Header.
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(
                        "Drawer",
                        style = TumbleType.display(26).copy(color = Palette.cream),
                        modifier = if (com.tumble.BuildConfig.DEBUG) {
                            Modifier.pointerInput(Unit) {
                                detectTapGestures(onLongPress = { viewModel.seedDebugDays() })
                            }
                        } else Modifier,
                    )
                    val developed = today?.developedCount ?: 0
                    val total = today?.totalCount ?: 0
                    Text(
                        "$total today · $developed developed · ${viewModel.remainingLabel}",
                        style = TumbleType.sans(12).copy(color = Palette.cream.copy(alpha = 0.55f)),
                    )
                    if (total > 1) {
                        Text(
                            "Drag to rearrange · pinch to spread · reset ↺ up top",
                            style = TumbleType.sans(11).copy(color = Palette.cream.copy(alpha = 0.4f)),
                        )
                    }
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    AnimatedVisibility(visible = drawerCanReset, enter = scaleIn(), exit = scaleOut()) {
                        Row {
                            CircleIconButton(Icons.Outlined.Refresh, "Reset drawer layout", { drawerResetToken++ })
                            Spacer(Modifier.size(10.dp))
                        }
                    }
                    CircleIconButton(Icons.Outlined.Info, "About & upgrade", onOpenPaywall)
                }
            }

            Spacer(Modifier.height(14.dp))

            // The pile of today's prints.
            DrawerPile(
                photos = today?.photos ?: emptyList(),
                loadBitmap = viewModel::loadBitmap,
                onTap = { onOpenPrint(it.id, it.isDeveloped) },
                modifier = Modifier.weight(1f),
                resetToken = drawerResetToken,
                onResetAvailabilityChange = { drawerCanReset = it },
            )

            // Collections (older days).
            if (collections.isNotEmpty()) {
                Spacer(Modifier.height(14.dp))
                collections.forEach { day ->
                    DayCollectionRow(day, onClick = { onOpenDay(day.dayStart.toEpochDay()) })
                    Spacer(Modifier.height(8.dp))
                }
            }

            Spacer(Modifier.height(12.dp))
        }

        // Low-roll nudge / just-in-time drawer tip, at the bottom.
        val remaining = viewModel.remaining
        var nudgeDismissed by rememberSaveable { mutableStateOf(false) }
        val todayCount = today?.totalCount ?: 0
        Box(
            Modifier.fillMaxSize().safeContentPadding().padding(bottom = 18.dp),
            contentAlignment = Alignment.BottomCenter,
        ) {
            when {
                !viewModel.isUnlimited && remaining != null && remaining in 1..3 && !nudgeDismissed ->
                    BottomChip(
                        text = "${if (remaining == 1) "1 shot" else "$remaining shots"} left today",
                        actionLabel = "Own more",
                        onAction = onOpenPaywall,
                        onDismiss = { nudgeDismissed = true },
                    )

                !viewModel.seenDrawerTips && todayCount >= 2 ->
                    BottomChip(
                        text = "Tap a print to open · pull the top for the camera",
                        actionLabel = null,
                        onAction = {},
                        onDismiss = { viewModel.dismissDrawerTips() },
                    )
            }
        }

        // The camera lives as a window you pull down from the top.
        PullDownCamera(
            remainingLabel = viewModel.remainingLabel,
            canShoot = viewModel.canShoot,
            onCapture = { bitmap, done -> viewModel.capture(bitmap) { done() } },
            onNeedMore = onOpenPaywall,
        )
    }
}

@Composable
private fun BottomChip(
    text: String,
    actionLabel: String?,
    onAction: () -> Unit,
    onDismiss: () -> Unit,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(Palette.ink.copy(alpha = 0.92f))
            .border(1.dp, Palette.gold.copy(alpha = 0.28f), RoundedCornerShape(50))
            .padding(start = 16.dp, end = 8.dp, top = 8.dp, bottom = 8.dp),
    ) {
        Text(text, style = TumbleType.sans(13, FontWeight.Medium).copy(color = Palette.cream))
        if (actionLabel != null) {
            Text(
                actionLabel,
                style = TumbleType.sans(13, FontWeight.Bold).copy(color = Palette.ink),
                modifier = Modifier.clip(CircleShape).background(Palette.amber).clickable(onClick = onAction)
                    .padding(horizontal = 12.dp, vertical = 6.dp),
            )
        }
        Text(
            "✕",
            style = TumbleType.sans(13, FontWeight.Bold).copy(color = Palette.cream.copy(alpha = 0.6f)),
            modifier = Modifier.clip(CircleShape).clickable(onClick = onDismiss).padding(8.dp),
        )
    }
}

@Composable
private fun DayCollectionRow(day: PhotoDay, onClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(Palette.charcoalDeep.copy(alpha = 0.72f))
            .border(1.dp, Palette.cream.copy(alpha = 0.08f), RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .padding(12.dp),
    ) {
        Icon(
            Icons.Outlined.FolderOpen,
            null,
            tint = Palette.gold,
            modifier = Modifier.size(28.dp),
        )
        Spacer(Modifier.size(12.dp))
        Column(Modifier.weight(1f)) {
            Text(day.displayTitle, style = TumbleType.sans(15, FontWeight.SemiBold).copy(color = Palette.cream))
            Text(
                "${day.developedCount} developed · ${day.totalCount} total",
                style = TumbleType.sans(12).copy(color = Palette.cream.copy(alpha = 0.5f)),
            )
        }
        Icon(Icons.Filled.ChevronRight, null, tint = Palette.cream.copy(alpha = 0.35f))
    }
}
