package com.tumble.ui.theme

import android.graphics.Bitmap
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.ImageShader
import androidx.compose.ui.graphics.ShaderBrush
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.asImageBitmap
import kotlin.random.Random

/**
 * Film grain — the primary background texture ("graincore"). Generated once as
 * a small tileable monochrome noise image and cached, then tiled with an
 * overlay blend at low opacity. Mirrors `app/TumbleKit/Theme/Grain.swift`
 * (and the fractal-noise SVG the site paints in `body::after`).
 */
object Grain {
    private const val SIZE = 180

    val bitmap by lazy { generate(SIZE) }

    /** A repeating shader brush; tiles in pixel space like the iOS `.tile` mode. */
    val brush by lazy { ShaderBrush(ImageShader(bitmap, TileMode.Repeated, TileMode.Repeated)) }

    private fun generate(size: Int): androidx.compose.ui.graphics.ImageBitmap {
        val random = Random(0x7EED) // fixed seed → stable texture across launches
        val pixels = IntArray(size * size)
        for (i in pixels.indices) {
            // Desaturated luminance grain, contrast lifted toward mid-tones
            // (CIColorControls saturation 0, contrast 0.7) so it reads as an
            // overlay wash rather than harsh salt-and-pepper.
            val g = (0.5 + (random.nextDouble() - 0.5) * 0.7).coerceIn(0.0, 1.0)
            val v = (g * 255).toInt()
            pixels[i] = (0xFF shl 24) or (v shl 16) or (v shl 8) or v
        }
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        bmp.setPixels(pixels, 0, size, 0, 0, size, size)
        return bmp.asImageBitmap()
    }
}

/**
 * Draws tiled grain over this node's own content, blended in the same layer so
 * the overlay actually composites against what's behind it (opacity ~0.22,
 * blend `overlay`, matching the site).
 */
fun Modifier.grain(alpha: Float = 0.22f, blend: BlendMode = BlendMode.Overlay): Modifier =
    drawWithContent {
        drawContent()
        drawRect(brush = Grain.brush, alpha = alpha, blendMode = blend)
    }
