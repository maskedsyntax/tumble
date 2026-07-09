package com.tumble.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

/**
 * Tumble is forced-dark, no light variant (mirrors `.preferredColorScheme(.dark)`
 * on iOS). Most surfaces paint their own graincore background; the Material color
 * scheme here is just a sensible fallback for stock components.
 */
private val TumbleColors = darkColorScheme(
    primary = Palette.gold,
    onPrimary = Palette.ink,
    secondary = Palette.blueLift,
    background = Palette.blue,
    onBackground = Palette.cream,
    surface = Palette.blueDeep,
    onSurface = Palette.cream,
)

@Composable
fun TumbleTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = TumbleColors,
        typography = TumbleTypography,
        content = content,
    )
}
