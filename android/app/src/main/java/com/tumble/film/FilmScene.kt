package com.tumble.film

import android.graphics.Bitmap
import android.graphics.BlendMode
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.Shader

/**
 * Synthetic "photographs" — the same gradient scenes the site paints in
 * `DrawerMockup`. Used as develop previews and, crucially, as stand-in captures
 * when there's no usable camera, so the whole capture → develop → Drawer flow
 * stays demoable. Ported from `app/TumbleKit/Film/FilmScene.swift`.
 */
enum class FilmScene {
    GOLDEN_HOUR, BLUE_HOUR_ROOFTOP, SUNLIT_PARK, BEACH_MORNING, WARM_PORTRAIT, PINK_DUSK;

    fun render(size: Int = 1024): Bitmap {
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val s = size.toFloat()
        drawLinear(canvas, s)
        drawHighlight(canvas, s)
        drawLightLeak(canvas, s)
        drawVignette(canvas, s)
        return bmp
    }

    private fun drawLinear(canvas: Canvas, s: Float) {
        val stops = linearStops()
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                s / 2f, 0f, s / 2f, s,
                stops.map { it.first }.toIntArray(),
                stops.map { it.second }.toFloatArray(),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, s, s, paint)
    }

    private fun drawHighlight(canvas: Canvas, s: Float) {
        val hl = highlight() ?: return
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                s * hl.cx, s * hl.cy, s * hl.radius,
                intArrayOf(hl.color, hl.color and 0x00FFFFFF),
                floatArrayOf(0f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, s, s, paint)
    }

    private fun drawLightLeak(canvas: Canvas, s: Float) {
        val leak = leak()
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            blendMode = BlendMode.SCREEN
            shader = RadialGradient(
                s * leak.cx, s * leak.cy, s * 0.6f,
                intArrayOf(leak.color, leak.color and 0x00FFFFFF),
                floatArrayOf(0f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, s, s, paint)
    }

    private fun drawVignette(canvas: Canvas, s: Float) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                s / 2f, s / 2f * 0.96f, s * 0.74f,
                intArrayOf(0x00000000, argb(0x0A0A0A, 0.4f)),
                floatArrayOf(0.62f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(0f, 0f, s, s, paint)
    }

    private data class Radial(val color: Int, val cx: Float, val cy: Float, val radius: Float)

    private fun leak(): Radial = when (this) {
        GOLDEN_HOUR -> Radial(argb(0xFFC178, 0.32f), 0.9f, 0.14f, 0.6f)
        BLUE_HOUR_ROOFTOP -> Radial(argb(0xFFB870, 0.24f), 0.12f, 0.16f, 0.6f)
        SUNLIT_PARK -> Radial(argb(0xFFF0B0, 0.30f), 0.85f, 0.1f, 0.6f)
        BEACH_MORNING -> Radial(argb(0xFFE8C0, 0.26f), 0.9f, 0.12f, 0.6f)
        WARM_PORTRAIT -> Radial(argb(0xFFD0A0, 0.34f), 0.14f, 0.12f, 0.6f)
        PINK_DUSK -> Radial(argb(0xFFC8A0, 0.30f), 0.86f, 0.85f, 0.6f)
    }

    private fun highlight(): Radial? = when (this) {
        GOLDEN_HOUR -> Radial(argb(0xFFD68C, 0.95f), 0.5f, 0.3f, 0.6f)
        BLUE_HOUR_ROOFTOP -> Radial(argb(0xF0B46E, 0.55f), 0.72f, 0.82f, 0.6f)
        SUNLIT_PARK -> Radial(argb(0xFFECB4, 0.80f), 0.3f, 0.18f, 0.6f)
        BEACH_MORNING -> Radial(argb(0xFFF0CD, 0.85f), 0.68f, 0.22f, 0.55f)
        WARM_PORTRAIT -> Radial(argb(0xECC39A, 0.60f), 0.48f, 0.4f, 0.5f)
        PINK_DUSK -> Radial(argb(0xFFC896, 0.70f), 0.5f, 0.78f, 0.6f)
    }

    private fun linearStops(): List<Pair<Int, Float>> = when (this) {
        GOLDEN_HOUR -> listOf(
            solid(0xF4B46A) to 0f, solid(0xE08A58) to 0.34f, solid(0x9C5A5C) to 0.54f,
            solid(0x40384A) to 0.72f, solid(0x263040) to 1f,
        )
        BLUE_HOUR_ROOFTOP -> listOf(
            solid(0x223D5C) to 0f, solid(0x315679) to 0.42f, solid(0x5C6F82) to 0.62f,
            solid(0x8A7566) to 0.82f, solid(0xC1946A) to 1f,
        )
        SUNLIT_PARK -> listOf(
            solid(0xD7E6CF) to 0f, solid(0xA9C58F) to 0.38f, solid(0x6F8D55) to 0.66f,
            solid(0x3F5738) to 1f,
        )
        BEACH_MORNING -> listOf(
            solid(0xA9CFE0) to 0f, solid(0xC9DFE4) to 0.34f, solid(0xE7DCC2) to 0.56f,
            solid(0xD0A86A) to 0.78f, solid(0xB8895C) to 1f,
        )
        WARM_PORTRAIT -> listOf(
            solid(0xECC39A) to 0f, solid(0xC08A6C) to 0.46f, solid(0x6F4A48) to 0.78f,
            solid(0x3A2B30) to 1f,
        )
        PINK_DUSK -> listOf(
            solid(0x6F7FA6) to 0f, solid(0xB98AA0) to 0.38f, solid(0xD99A86) to 0.62f,
            solid(0xCAA06E) to 1f,
        )
    }

    companion object {
        fun random(): FilmScene = entries.random()

        private fun solid(rgb: Int): Int = 0xFF000000.toInt() or (rgb and 0xFFFFFF)
        private fun argb(rgb: Int, alpha: Float): Int =
            ((alpha * 255).toInt() shl 24) or (rgb and 0xFFFFFF)
    }
}
