package com.tumble.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * The "graincore" palette, ported verbatim from
 * `app/TumbleKit/Theme/Palette.swift`. Slate-blue base (#2E4052) with a warm
 * gold glow (#DFAB68); texture comes from film grain, never blur.
 */
object Palette {
    val blue = Color(0xFF2E4052)
    val blueDeep = Color(0xFF223140)
    val blueLift = Color(0xFF3A5164)

    val cream = Color(0xFFF6EFE2)
    val creamDim = Color(0xFFE9DCC4)
    val ink = Color(0xFF1E2A34)

    val amber = Color(0xFFDFAB68)
    val gold = Color(0xFFDFAB68)
    val charcoalDeep = Color(0xFF202D39)

    /** The cream stock a developed print is mounted on. */
    val printStock = Color(0xFFF4ECDA)
}
