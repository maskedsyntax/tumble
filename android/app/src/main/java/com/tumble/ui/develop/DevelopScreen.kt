package com.tumble.ui.develop

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.FilterFrames
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tumble.model.ageFraction
import com.tumble.ui.components.CircleIconButton
import com.tumble.ui.components.PrintView
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.delay

/**
 * The develop table — a blank, face-down print you bring to life by shaking,
 * washed out at first, settling into full color. A one-time gesture demo plays
 * on arrival; a press-and-hold stands in when there's no accelerometer. Ported
 * from `app/Tumble/Screens/DevelopView.swift`.
 */
@Composable
fun DevelopScreen(
    onClose: () -> Unit,
    viewModel: DevelopViewModel = hiltViewModel(),
) {
    val haptics = LocalHapticFeedback.current
    val activity = androidx.compose.ui.platform.LocalContext.current as? android.app.Activity
    var confirmRemove by remember { mutableStateOf(false) }
    val postcardFrame by viewModel.postcardFrame.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.onDeveloped = { haptics.performHapticFeedback(HapticFeedbackType.LongPress) }
    }
    // Throttled "rattle" while the print is coming up.
    LaunchedEffect(Unit) {
        var last = 0L
        androidx.compose.runtime.snapshotFlow { viewModel.progress }.collect { p ->
            val now = System.currentTimeMillis()
            if (p in 0.001f..0.999f && now - last > 90) {
                haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                last = now
            }
        }
    }
    // Value-first review ask, once developed or saved (gated by ReviewTracker).
    LaunchedEffect(viewModel.isDeveloped, viewModel.saveMessage) {
        if (activity != null && (viewModel.isDeveloped || viewModel.saveMessage != null)) {
            viewModel.requestReview(activity)
        }
    }
    LaunchedEffect(viewModel.saveMessage) {
        if (viewModel.saveMessage != null) {
            delay(1800)
            viewModel.clearSaveMessage()
        }
    }

    // One-time "rock" that demonstrates the shake, then rests at zero.
    val rock = remember { Animatable(0f) }
    LaunchedEffect(viewModel.photo?.id, viewModel.isDeveloped) {
        if (viewModel.photo != null && !viewModel.isDeveloped) {
            delay(350)
            rock.animateTo(-5f, tween(400)); rock.animateTo(5f, tween(450))
            rock.animateTo(-4f, tween(450)); rock.animateTo(0f, tween(450))
        }
    }

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()

        Column(
            modifier = Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            val photo = viewModel.photo
            PrintView(
                image = viewModel.image,
                isDeveloped = viewModel.isDeveloped,
                developProgress = viewModel.progress,
                age = photo?.ageFraction()?.toFloat() ?: 0f,
                width = 280.dp,
                modifier = Modifier.graphicsLayer {
                    rotationZ = rock.value
                    translationX = rock.value * 1.4f
                },
            )

            Spacer(Modifier.height(28.dp))
            DevelopHint(viewModel)
        }

        // Top controls.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .safeContentPadding()
                .padding(horizontal = 20.dp)
                .padding(top = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp, Alignment.End),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CircleIconButton(
                Icons.Outlined.DeleteOutline, "Remove print", { confirmRemove = true },
                tooltip = "Remove print",
            )
            if (viewModel.isDeveloped) {
                CircleIconButton(
                    icon = if (postcardFrame) Icons.Outlined.FilterFrames else Icons.Outlined.Image,
                    contentDescription = "Save format",
                    onClick = { viewModel.toggleFrame() },
                    tint = if (postcardFrame) Palette.gold else Palette.cream,
                    tooltip = if (postcardFrame) "Save photo only" else "Save as postcard",
                )
                CircleIconButton(
                    Icons.Outlined.FileDownload, "Save print to Photos", { viewModel.save() },
                    tooltip = "Save to Photos",
                )
            }
            CircleIconButton(Icons.Rounded.Close, "Close", onClose, tooltip = "Close")
        }

        viewModel.saveMessage?.let { message ->
            Box(Modifier.fillMaxSize().padding(bottom = 58.dp), contentAlignment = Alignment.BottomCenter) {
                Text(
                    text = message,
                    style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.78f)),
                    modifier = Modifier
                        .clip(androidx.compose.foundation.shape.RoundedCornerShape(50))
                        .background(Palette.ink.copy(alpha = 0.5f))
                        .padding(horizontal = 14.dp, vertical = 9.dp),
                )
            }
        }
    }

    if (confirmRemove) {
        AlertDialog(
            onDismissRequest = { confirmRemove = false },
            title = { Text("Remove this print from your Drawer?") },
            text = { Text("This will not return the shot.") },
            confirmButton = {
                TextButton(onClick = { confirmRemove = false; viewModel.delete(onClose) }) {
                    Text("Remove", color = Palette.gold)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmRemove = false }) { Text("Cancel") }
            },
            containerColor = Palette.blueDeep,
        )
    }
}

@Composable
private fun DevelopHint(viewModel: DevelopViewModel) {
    if (viewModel.isDeveloped) {
        Text("There it is.", style = TumbleType.display(22).copy(color = Palette.cream))
        return
    }
    // Shake is primary on a real device; the hold button is always offered too
    // so it works on emulators / with reduce motion (mirrors the iOS fallback).
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            if (viewModel.usesShake) "Shake to develop" else "Hold to develop",
            style = TumbleType.display(22).copy(color = Palette.cream),
        )
        Text(
            if (viewModel.usesShake) "Give it a shake - or hold below." else "Press and hold - it comes up slowly.",
            style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.7f), textAlign = TextAlign.Center),
        )
        Spacer(Modifier.height(14.dp))
        HoldButton(viewModel)
    }
}

@Composable
private fun HoldButton(viewModel: DevelopViewModel) {
    var holding by remember { mutableStateOf(false) }
    LaunchedEffect(holding) {
        while (holding && !viewModel.isDeveloped) {
            viewModel.hold()
            delay(16)
        }
    }
    Text(
        text = if (holding) "Developing…" else "Hold to develop",
        style = TumbleType.sans(15, FontWeight.SemiBold).copy(color = Palette.ink),
        modifier = Modifier
            .clip(CircleShape)
            .background(Palette.amber)
            .padding(horizontal = 22.dp, vertical = 10.dp)
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        holding = true
                        tryAwaitRelease()
                        holding = false
                    },
                )
            },
    )
}
