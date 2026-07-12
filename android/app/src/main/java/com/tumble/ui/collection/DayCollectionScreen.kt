package com.tumble.ui.collection

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeContentPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
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

private val hourFormat = DateTimeFormatter.ofPattern("h:mm a", Locale.US)

/**
 * A day's prints in an adaptive grid. Tapping a print opens it (develop if still
 * blank, detail if developed). Ported from
 * `app/Tumble/Screens/DayCollectionView.swift`.
 */
@Composable
fun DayCollectionScreen(
    onClose: () -> Unit,
    onOpenPrint: (String) -> Unit,
    onDevelop: (String) -> Unit,
    viewModel: DayCollectionViewModel = hiltViewModel(),
) {
    LaunchedEffect(viewModel.saveMessage) {
        if (viewModel.saveMessage != null) { delay(1800); viewModel.clearSaveMessage() }
    }

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()

        Column(Modifier.fillMaxSize().safeContentPadding().padding(horizontal = 20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(viewModel.title, style = TumbleType.display(30).copy(color = Palette.cream))
                    Text(
                        "${viewModel.developedCount} developed · ${viewModel.photos.size} total",
                        style = TumbleType.sans(13).copy(color = Palette.cream.copy(alpha = 0.55f)),
                    )
                }
                CircleIconButton(Icons.Outlined.FileDownload, "Save day to Photos", { viewModel.saveDay() })
                Spacer(Modifier.width(10.dp))
                CircleIconButton(Icons.Rounded.Close, "Close", onClose)
            }

            Spacer(Modifier.size(16.dp))

            LazyVerticalGrid(
                columns = GridCells.Adaptive(150.dp),
                horizontalArrangement = Arrangement.spacedBy(18.dp),
                verticalArrangement = Arrangement.spacedBy(22.dp),
                modifier = Modifier.fillMaxSize(),
            ) {
                items(viewModel.photos, key = { it.id }) { photo ->
                    val bitmap = remember(photo.id, photo.isDeveloped) { viewModel.loadBitmap(photo.rawImageName) }
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.fillMaxWidth().clickable {
                            if (photo.isDeveloped) onOpenPrint(photo.id) else onDevelop(photo.id)
                        },
                    ) {
                        PrintView(
                            image = bitmap,
                            isDeveloped = photo.isDeveloped,
                            developProgress = if (photo.isDeveloped) 1f else 0f,
                            age = photo.ageFraction().toFloat(),
                            width = 150.dp,
                        )
                        Text(
                            photo.capturedAt.atZone(ZoneId.systemDefault()).format(hourFormat),
                            style = TumbleType.sans(11, FontWeight.Medium).copy(color = Palette.cream.copy(alpha = 0.5f)),
                            modifier = Modifier.padding(top = 6.dp),
                        )
                    }
                }
            }
        }

        viewModel.saveMessage?.let { message ->
            Box(Modifier.fillMaxSize().padding(bottom = 58.dp), contentAlignment = Alignment.BottomCenter) {
                Text(
                    message,
                    style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream.copy(alpha = 0.78f)),
                    modifier = Modifier.clip(CircleShape).background(Palette.ink.copy(alpha = 0.5f))
                        .padding(horizontal = 14.dp, vertical = 9.dp),
                )
            }
        }
    }
}
