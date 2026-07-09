package com.tumble.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * Type ramp mirroring `app/TumbleKit/Theme/Typography.swift`: a serif display
 * face for headlines/captions and a sans face for body. The iOS app ships no
 * bundled Fraunces/Inter files and falls back to the system serif ("New York")
 * and default sans, so we match that here with the platform serif/sans.
 */
val DisplayFamily = FontFamily.Serif
val BodyFamily = FontFamily.SansSerif

/** Helper builders that mirror `Typography.display(_:)` / `.sans(_:)`. */
object TumbleType {
    fun display(size: Int, weight: FontWeight = FontWeight.SemiBold): TextStyle =
        TextStyle(fontFamily = DisplayFamily, fontWeight = weight, fontSize = size.sp)

    fun sans(size: Int, weight: FontWeight = FontWeight.Normal): TextStyle =
        TextStyle(fontFamily = BodyFamily, fontWeight = weight, fontSize = size.sp)

    /** Small-caps-y kicker used above section headings. Uppercase at call site. */
    val kicker: TextStyle = TextStyle(
        fontFamily = BodyFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 12.sp,
        letterSpacing = 2.sp,
        color = Palette.amber,
    )
}

val TumbleTypography = Typography(
    displayLarge = TumbleType.display(36),
    headlineMedium = TumbleType.display(26),
    titleMedium = TumbleType.sans(15, FontWeight.SemiBold),
    bodyMedium = TumbleType.sans(14),
    labelSmall = TumbleType.sans(12, FontWeight.Medium),
)
