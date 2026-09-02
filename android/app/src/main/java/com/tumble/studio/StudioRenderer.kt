package com.tumble.studio

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import java.io.ByteArrayOutputStream
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import kotlin.math.max
import kotlin.math.roundToInt
import kotlin.math.sqrt

/** One renderer for Studio previews, final saves, and shares. */
class StudioRenderer {
    fun decode(file: File, maxLongEdge: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (max(bounds.outWidth / sample, bounds.outHeight / sample) > maxLongEdge * 2) sample *= 2
        return BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        })
    }

    fun render(
        source: Bitmap,
        stock: FilmStock,
        recipe: EditRecipe,
        seed: Int,
        maxLongEdge: Int,
        capturedAt: Instant? = null,
    ): Bitmap {
        val prepared = crop(rotate(source, recipe.quarterTurns), recipe)
        val (width, height) = scaledDimensions(prepared.width, prepared.height, maxLongEdge)
        val original = if (prepared.width == width && prepared.height == height) prepared.copy(Bitmap.Config.ARGB_8888, true)
        else Bitmap.createScaledBitmap(prepared, width, height, true)
        val output = original.copy(Bitmap.Config.ARGB_8888, true)
        val row = IntArray(width)
        val originalRow = IntArray(width)
        val cx = (width - 1) / 2.0
        val cy = (height - 1) / 2.0
        val radius = sqrt(cx * cx + cy * cy).coerceAtLeast(1.0)
        for (y in 0 until height) {
            original.getPixels(originalRow, 0, width, 0, y, width, 1)
            for (x in 0 until width) {
                val radial = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / radius
                val graded = gradePixel(originalRow[x], stock.grade, y * width + x, seed, radial, x.toDouble() / width, y.toDouble() / height)
                row[x] = blend(originalRow[x], graded, recipe.intensity)
            }
            output.setPixels(row, 0, width, 0, y, width, 1)
        }
        if (stock.grade.stampsDate && capturedAt != null) drawFilmDateStamp(output, capturedAt)
        return output
    }

    fun composeFrame(image: Bitmap, recipe: EditRecipe, capturedAt: java.time.Instant, maxLongEdge: Int = 4096): Bitmap {
        if (recipe.frame == FrameStyle.NONE) return image
        val aspect = recipe.frame.aspect
        val canvasWidth = if (aspect > 1) (maxLongEdge / aspect).roundToInt() else maxLongEdge
        val canvasHeight = (canvasWidth * aspect).roundToInt().coerceAtMost(maxLongEdge)
        val output = Bitmap.createBitmap(canvasWidth, canvasHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val cream = Color.rgb(246, 239, 226)
        val ink = Color.rgb(30, 42, 52)
        canvas.drawColor(if (recipe.frame == FrameStyle.BORDERED_FILM) Color.rgb(24, 27, 29) else cream)
        val side = when (recipe.frame) {
            FrameStyle.CLASSIC_INSTANT -> canvasWidth * 0.065f
            FrameStyle.VINTAGE_POSTCARD -> canvasWidth * 0.08f
            FrameStyle.BORDERED_FILM -> canvasWidth * 0.045f
            FrameStyle.DECKLED_EDGE -> canvasWidth * 0.075f
            FrameStyle.NONE -> 0f
        }
        val bottom = when (recipe.frame) {
            FrameStyle.CLASSIC_INSTANT -> canvasHeight * 0.20f
            FrameStyle.VINTAGE_POSTCARD -> canvasHeight * 0.28f
            else -> side * 1.4f
        }
        val target = Rect(side.roundToInt(), side.roundToInt(), (canvasWidth - side).roundToInt(), (canvasHeight - bottom).roundToInt())
        drawCenterCrop(canvas, image, target)
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (recipe.frame == FrameStyle.BORDERED_FILM) Color.WHITE else ink
            textSize = canvasWidth * 0.042f
            typeface = Typeface.create("cursive", Typeface.NORMAL)
            val note = recipe.note.take(60)
            if (note.isNotBlank()) canvas.drawText(note, side, canvasHeight - bottom * 0.42f, this)
            if (recipe.frame == FrameStyle.BORDERED_FILM || recipe.frame == FrameStyle.VINTAGE_POSTCARD) {
                textSize = canvasWidth * 0.024f
                typeface = Typeface.MONOSPACE
                val date = DateTimeFormatter.ofPattern("MM dd yy").withZone(ZoneId.systemDefault()).format(capturedAt)
                canvas.drawText(date, canvasWidth - measureText(date) - side, canvasHeight - side * 0.55f, this)
            }
        }
        return output
    }

    fun jpeg(bitmap: Bitmap, quality: Int = 92): ByteArray = ByteArrayOutputStream().use {
        bitmap.compress(Bitmap.CompressFormat.JPEG, quality, it)
        it.toByteArray()
    }

    companion object {
        fun scaledDimensions(width: Int, height: Int, maxLongEdge: Int): Pair<Int, Int> {
            require(width > 0 && height > 0 && maxLongEdge > 0)
            val longEdge = max(width, height)
            if (longEdge <= maxLongEdge) return width to height
            val scale = maxLongEdge.toDouble() / longEdge
            return max(1, (width * scale).roundToInt()) to max(1, (height * scale).roundToInt())
        }

        internal fun gradePixel(argb: Int, grade: FilmGrade, index: Int, seed: Int, radial: Double, nx: Double, ny: Double): Int {
            var r = ((argb ushr 16) and 0xff) / 255.0
            var g = ((argb ushr 8) and 0xff) / 255.0
            var b = (argb and 0xff) / 255.0
            val luma = r * 0.2126 + g * 0.7152 + b * 0.0722
            r = luma + (r - luma) * grade.saturation
            g = luma + (g - luma) * grade.saturation
            b = luma + (b - luma) * grade.saturation
            r = (r - .5) * grade.contrast + .5 + grade.brightness
            g = (g - .5) * grade.contrast + .5 + grade.brightness
            b = (b - .5) * grade.contrast + .5 + grade.brightness
            r = tone(r, grade.blackLift); g = tone(g, grade.blackLift); b = tone(b, grade.blackLift)
            val sourceR = r; val sourceG = g; val sourceB = b
            val warmth = grade.warmth
            r = sourceR * (1 + warmth * .075) + sourceG * warmth * .020 - sourceB * warmth * .020 + warmth * .030
            g = sourceR * warmth * .010 + sourceG * (1 + warmth * .020) + warmth * .016
            b = sourceR * -warmth * .045 + sourceG * -warmth * .010 + sourceB * (1 - warmth * .070) - warmth * .010
            val mono = (r * .2126 + g * .7152 + b * .0722)
            r = lerp(r, mono + grade.monoTint.red, grade.monochrome)
            g = lerp(g, mono + grade.monoTint.green, grade.monochrome)
            b = lerp(b, mono + grade.monoTint.blue, grade.monochrome)
            val luminosity = (r * .2126 + g * .7152 + b * .0722).coerceIn(0.0, 1.0)
            val shadow = (1 - luminosity) * grade.shadowStrength
            val highlight = luminosity * grade.highlightStrength
            r += grade.shadowTint.red * shadow + grade.highlightTint.red * highlight
            g += grade.shadowTint.green * shadow + grade.highlightTint.green * highlight
            b += grade.shadowTint.blue * shadow + grade.highlightTint.blue * highlight
            val fade = grade.fade
            r = r * (1 - fade * .20) + fade * .10; g = g * (1 - fade * .20) + fade * .10; b = b * (1 - fade * .20) + fade * .10
            val bright = ((luminosity - .58) / .42).coerceIn(0.0, 1.0) * grade.halation
            r += bright * .085; g += bright * .032
            val haze = grade.bloom * .08
            r += haze; g += haze; b += haze
            val noise = (((mix(index xor seed) ushr 8) and 0xffff) / 65535.0 - .5) * .055 * grade.grain
            r += noise; g += noise; b += noise
            val vignette = ((radial.coerceAtLeast(.62) - .62) / .38).coerceIn(0.0, 1.0)
            val v = 1 - grade.vignette * vignette * vignette
            r *= v; g *= v; b *= v
            val leak = when (grade.leak) {
                "cornerWarm" -> ((nx + ny - 1.15) / .85).coerceIn(0.0, 1.0)
                "edgeRed" -> ((.22 - nx) / .22).coerceIn(0.0, 1.0)
                "topFlare" -> ((.30 - ny) / .30).coerceIn(0.0, 1.0)
                else -> 0.0
            } * grade.leakStrength
            r += leak * .22; g += leak * .08; b += leak * .02
            return argb((argb ushr 24) and 0xff, channel(r), channel(g), channel(b))
        }

        private fun tone(value: Double, lift: Double): Double {
            val x = value.coerceIn(0.0, 1.0)
            val xs = doubleArrayOf(0.0, .22, .52, .82, 1.0)
            val ys = doubleArrayOf(lift, .24 + lift * .35, .52, .80, .97)
            val i = when { x <= xs[1] -> 0; x <= xs[2] -> 1; x <= xs[3] -> 2; else -> 3 }
            return lerp(ys[i], ys[i + 1], (x - xs[i]) / (xs[i + 1] - xs[i]))
        }
        private fun blend(a: Int, b: Int, amount: Double) = argb(
            (a ushr 24) and 0xff,
            channel(lerp(((a ushr 16) and 0xff) / 255.0, ((b ushr 16) and 0xff) / 255.0, amount)),
            channel(lerp(((a ushr 8) and 0xff) / 255.0, ((b ushr 8) and 0xff) / 255.0, amount)),
            channel(lerp((a and 0xff) / 255.0, (b and 0xff) / 255.0, amount)),
        )
        private fun argb(a: Int, r: Int, g: Int, b: Int) = (a shl 24) or (r shl 16) or (g shl 8) or b
        private fun channel(value: Double) = (value.coerceIn(0.0, 1.0) * 255).roundToInt()
        private fun lerp(a: Double, b: Double, t: Double) = a + (b - a) * t.coerceIn(0.0, 1.0)
        private fun mix(input: Int): Int { var v = input; v = v xor (v ushr 16); v *= -0x7a143595; v = v xor (v ushr 13); v *= -0x3d4d51cb; return v xor (v ushr 16) }
    }
}

private fun drawFilmDateStamp(image: Bitmap, capturedAt: Instant) {
    val canvas = Canvas(image)
    val text = DateTimeFormatter.ofPattern("MM dd yy")
        .withZone(ZoneId.systemDefault())
        .format(capturedAt)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.rgb(237, 154, 60)
        textSize = image.width * 0.035f
        typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
        setShadowLayer(image.width * 0.0025f, 0f, image.width * 0.0015f, Color.argb(115, 42, 21, 8))
    }
    val padding = image.width * 0.045f
    canvas.drawText(text, image.width - paint.measureText(text) - padding, image.height - padding, paint)
}

private fun rotate(source: Bitmap, turns: Int): Bitmap {
    val normalized = ((turns % 4) + 4) % 4
    if (normalized == 0) return source
    return Bitmap.createBitmap(source, 0, 0, source.width, source.height, Matrix().apply { postRotate(normalized * 90f) }, true)
}

private fun crop(source: Bitmap, recipe: EditRecipe): Bitmap {
    val rect = if (recipe.cropPreset == CropPreset.FREEFORM) {
        val c = recipe.crop
        Rect((source.width * c.x).roundToInt(), (source.height * c.y).roundToInt(),
            (source.width * (c.x + c.width)).roundToInt(), (source.height * (c.y + c.height)).roundToInt())
    } else {
        val ratio = recipe.cropPreset.ratio ?: return source
        val sourceRatio = source.width.toDouble() / source.height
        if (sourceRatio > ratio) {
            val width = (source.height * ratio).roundToInt(); val left = (source.width - width) / 2
            Rect(left, 0, left + width, source.height)
        } else {
            val height = (source.width / ratio).roundToInt(); val top = (source.height - height) / 2
            Rect(0, top, source.width, top + height)
        }
    }
    val left = rect.left.coerceIn(0, source.width - 1); val top = rect.top.coerceIn(0, source.height - 1)
    val right = rect.right.coerceIn(left + 1, source.width); val bottom = rect.bottom.coerceIn(top + 1, source.height)
    return Bitmap.createBitmap(source, left, top, right - left, bottom - top)
}

private fun drawCenterCrop(canvas: Canvas, image: Bitmap, target: Rect) {
    val sourceRatio = image.width.toDouble() / image.height
    val targetRatio = target.width().toDouble() / target.height()
    val source = if (sourceRatio > targetRatio) {
        val width = (image.height * targetRatio).roundToInt(); val left = (image.width - width) / 2
        Rect(left, 0, left + width, image.height)
    } else {
        val height = (image.width / targetRatio).roundToInt(); val top = (image.height - height) / 2
        Rect(0, top, image.width, top + height)
    }
    canvas.drawBitmap(image, source, target, Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG))
}
