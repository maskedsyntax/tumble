package com.tumble.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.tumble.R

/**
 * Type ramp mirroring `app/TumbleKit/Theme/Typography.swift`: a serif display
 * face for headlines/captions and a sans face for body. The design uses
 * Fraunces (the same distinctive display serif as the website); we bundle the
 * variable font and drive its weight axis per style. Body stays on the platform
 * sans (close to the site's Inter).
 */
@OptIn(ExperimentalTextApi::class)
private fun fraunces(weight: FontWeight, italic: Boolean = false): Font = Font(
    resId = if (italic) R.font.fraunces_italic else R.font.fraunces,
    weight = weight,
    style = if (italic) FontStyle.Italic else FontStyle.Normal,
    variationSettings = FontVariation.Settings(
        FontVariation.weight(weight.weight),
        // Bias toward the high-contrast display cut of the optical-size axis.
        FontVariation.Setting("opsz", 80f),
    ),
)

val DisplayFamily = FontFamily(
    fraunces(FontWeight.Normal),
    fraunces(FontWeight.Medium),
    fraunces(FontWeight.SemiBold),
    fraunces(FontWeight.Bold),
    fraunces(FontWeight.Normal, italic = true),
    fraunces(FontWeight.SemiBold, italic = true),
)
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
