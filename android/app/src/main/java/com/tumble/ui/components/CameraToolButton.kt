package com.tumble.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.tumble.ui.theme.Palette

/**
 * A camera-preview overlay control (flash / switch). Always shown and simply
 * dimmed when unavailable — mirrors iOS `IslandCamera.cameraToolButton`, so the
 * flash toggle stays visible (disabled) on cameras with no flash unit rather
 * than vanishing.
 */
@Composable
fun CameraToolButton(
    icon: ImageVector,
    contentDescription: String,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    tint: Color = Palette.cream,
) {
    Box(
        modifier = modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = if (enabled) 0.42f else 0.22f))
            .border(1.dp, Palette.cream.copy(alpha = if (enabled) 0.16f else 0.08f), CircleShape)
            .then(if (enabled) Modifier.clickable(onClick = onClick) else Modifier),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = tint.copy(alpha = if (enabled) 0.92f else 0.42f),
            modifier = Modifier.size(16.dp),
        )
    }
}
