package com.tumble.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.PlainTooltip
import androidx.compose.material3.Text
import androidx.compose.material3.TooltipBox
import androidx.compose.material3.TooltipDefaults
import androidx.compose.material3.rememberTooltipState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.tumble.ui.theme.Palette

/**
 * The small dark circular control used on the develop/detail/collection headers.
 * Sized to echo iOS's ~15pt glyph in a ~35pt circle — a light, roomy icon rather
 * than a heavy stock one filling the whole button. Pass [tooltip] to reveal a
 * label on long-press, the Android hint for what the button does.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CircleIconButton(
    icon: ImageVector,
    contentDescription: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    tint: Color = Palette.cream,
    size: Int = 38,
    iconSize: Int = 18,
    tooltip: String? = null,
) {
    if (tooltip != null) {
        TooltipBox(
            positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
            tooltip = { PlainTooltip { Text(tooltip) } },
            state = rememberTooltipState(),
            modifier = modifier,
        ) {
            CircleButton(icon, contentDescription, onClick, Modifier, tint, size, iconSize)
        }
    } else {
        CircleButton(icon, contentDescription, onClick, modifier, tint, size, iconSize)
    }
}

@Composable
private fun CircleButton(
    icon: ImageVector,
    contentDescription: String?,
    onClick: () -> Unit,
    modifier: Modifier,
    tint: Color,
    size: Int,
    iconSize: Int,
) {
    Box(
        modifier = modifier
            .size(size.dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.28f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = tint,
            modifier = Modifier.size(iconSize.dp),
        )
    }
}
