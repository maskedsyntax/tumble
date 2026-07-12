package com.tumble.ui.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.FilterFrames
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tumble.model.ageFraction
import com.tumble.ui.components.CircleIconButton
import com.tumble.ui.components.PrintView
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.delay
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

private val timeFormat = DateTimeFormatter.ofPattern("MMM d, h:mm a", Locale.US)

/**
 * Full-screen browser of a day's developed prints: swipe left/right through
 * them, swipe down to dismiss. Ported from
 * `app/Tumble/Screens/PrintDetailView.swift`.
 */
@Composable
fun PrintDetailScreen(
    onClose: () -> Unit,
    viewModel: PrintDetailViewModel = hiltViewModel(),
) {
    val prints = viewModel.prints
    if (prints.isEmpty()) return

    val pagerState = rememberPagerState(initialPage = viewModel.startIndex) { prints.size }
    val postcardFrame by viewModel.postcardFrame.collectAsState()
    val density = LocalDensity.current
    var dragY by remember { androidx.compose.runtime.mutableFloatStateOf(0f) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(viewModel.saveMessage) {
        if (viewModel.saveMessage != null) { delay(1800); viewModel.clearSaveMessage() }
    }

    Box(
        Modifier
            .fillMaxSize()
            .graphicsLayer { translationY = dragY.coerceAtLeast(0f) }
            .pointerInput(Unit) {
                detectVerticalDragGestures(
                    onVerticalDrag = { _, delta -> dragY = (dragY + delta).coerceAtLeast(0f) },
                    onDragEnd = {
                        val threshold = with(density) { 120.dp.toPx() }
                        if (dragY > threshold) onClose() else dragY = 0f
                    },
                )
            },
    ) {
        GraincoreBackground()

        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            val photo = prints[page]
            val bitmap = remember(photo.id) { viewModel.loadBitmap(photo.rawImageName) }
            Column(
                Modifier.fillMaxSize().padding(24.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                PrintView(
                    image = bitmap,
                    isDeveloped = true,
                    developProgress = 1f,
                    age = photo.ageFraction().toFloat(),
                    caption = photo.caption,
                    width = 300.dp,
                )
            }
        }

        // Metadata timestamp.
        val current = prints.getOrNull(pagerState.currentPage)
        if (current != null) {
            Box(Modifier.fillMaxSize().safeContentPadding().padding(bottom = 20.dp), contentAlignment = Alignment.BottomCenter) {
                Text(
                    current.capturedAt.atZone(ZoneId.systemDefault()).format(timeFormat),
                    style = TumbleType.sans(12).copy(color = Palette.cream.copy(alpha = 0.55f)),
                )
            }
        }

        // Top controls for the current print.
        val photo = prints.getOrNull(pagerState.currentPage)
        Row(
            modifier = Modifier.fillMaxWidth().safeContentPadding().padding(horizontal = 20.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp, Alignment.End),
        ) {
            if (photo != null) {
                CircleIconButton(
                    Icons.Outlined.DeleteOutline, "Remove print", { viewModel.delete(photo, onClose) },
                    tooltip = "Remove print",
                )
                CircleIconButton(
                    icon = if (postcardFrame) Icons.Outlined.FilterFrames else Icons.Outlined.Image,
                    contentDescription = "Save format",
                    onClick = { viewModel.toggleFrame() },
                    tint = if (postcardFrame) Palette.gold else Palette.cream,
                    tooltip = if (postcardFrame) "Save photo only" else "Save as postcard",
                )
                CircleIconButton(
                    Icons.Outlined.FileDownload, "Save to Photos", { viewModel.save(photo) },
                    tooltip = "Save to Photos",
                )
            }
            CircleIconButton(Icons.Rounded.Close, "Close", onClose, tooltip = "Close")
        }

        viewModel.saveMessage?.let { message ->
            Box(Modifier.fillMaxSize().padding(bottom = 58.dp), contentAlignment = Alignment.BottomCenter) {
                Text(
                    message,
                    style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.78f)),
                    modifier = Modifier.clip(RoundedCornerShape(50)).background(Palette.ink.copy(alpha = 0.5f))
                        .padding(horizontal = 14.dp, vertical = 9.dp),
                )
            }
        }
    }
}
