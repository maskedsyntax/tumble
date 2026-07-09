package com.tumble.ui.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Inbox
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.foundation.clickable
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.tumble.model.Photo
import com.tumble.model.ageFraction
import com.tumble.ui.components.PrintView
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType

/**
 * The Drawer — a loosely scattered pile of prints (never a grid), each placed at
 * its stable hand-tossed scatter and rotation. Newest sits on top. Ported from
 * `app/Tumble/Views/DrawerPile.swift` (pinch-to-spread / drag-to-rearrange are
 * layered on in polish).
 */
@Composable
fun DrawerPile(
    photos: List<Photo>,
    loadBitmap: (String?) -> ImageBitmap?,
    onTap: (Photo) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (photos.isEmpty()) {
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

    BoxWithConstraints(modifier.fillMaxSize()) {
        val areaW = maxWidth
        val areaH = maxHeight
        val printW = areaW * 0.42f
        // Draw newest last so it sits on top (photos arrive newest-first).
        photos.asReversed().forEach { photo ->
            val bitmap = remember(photo.rawImageName, photo.isDeveloped) { loadBitmap(photo.rawImageName) }
            PrintView(
                image = bitmap,
                isDeveloped = photo.isDeveloped,
                developProgress = if (photo.isDeveloped) 1f else 0f,
                age = photo.ageFraction().toFloat(),
                width = printW,
                modifier = Modifier
                    .offset(
                        x = areaW * (photo.scatterX.toFloat() / 100f),
                        y = areaH * (photo.scatterY.toFloat() / 100f),
                    )
                    .graphicsLayer { rotationZ = (photo.rotation * 0.5).toFloat() }
                    .clickable { onTap(photo) },
            )
        }
    }
}
