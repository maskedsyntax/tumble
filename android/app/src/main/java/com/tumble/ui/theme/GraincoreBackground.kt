package com.tumble.ui.theme

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/**
 * The atmospheric backdrop shared across the app — a direct port of the site's
 * `body` background: a diagonal slate gradient, off-center gold and lifted-blue
 * radial "blobs" pushed past the edges for an organic contour, and a film-grain
 * overlay. No blur; texture comes from grain.
 *
 * Ported from `app/TumbleKit/Theme/GraincoreBackground.swift`.
 */
@Composable
fun GraincoreBackground(modifier: Modifier = Modifier) {
    Canvas(
        modifier
            .fillMaxSize()
            .background(Palette.blue)
            .grain(0.22f),
    ) {
        val w = size.width
        val h = size.height

        // Base diagonal slate gradient (linear-gradient 158deg on the site).
        drawRect(
            brush = Brush.linearGradient(
                colors = listOf(Color(0xFF2B3C4C), Color(0xFF263646), Color(0xFF21303F)),
                start = Offset.Zero,
                end = Offset(w, h),
            ),
        )

        // Off-center glow blobs — gold lower-left, gold upper-right, and
        // lifted-blue on the loose corners.
        blob(Palette.gold.copy(alpha = 0.42f), Offset(0.04f * w, 0.92f * h), 0.70f * w)
        blob(Palette.gold.copy(alpha = 0.30f), Offset(0.98f * w, 0.02f * h), 0.62f * w)
        blob(Palette.blueLift.copy(alpha = 0.42f), Offset(1.02f * w, 0.80f * h), 0.70f * w)
        blob(Palette.blueLift.copy(alpha = 0.34f), Offset(-0.02f * w, 0.12f * h), 0.60f * w)
    }
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.blob(
    color: Color,
    center: Offset,
    radius: Float,
) {
    drawRect(
        brush = Brush.radialGradient(
            colors = listOf(color, color.copy(alpha = 0f)),
            center = center,
            radius = radius,
        ),
    )
}
