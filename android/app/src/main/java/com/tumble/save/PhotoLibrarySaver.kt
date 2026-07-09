package com.tumble.save

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.os.Build
import android.provider.MediaStore
import com.tumble.data.PhotoStore
import com.tumble.model.Photo
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

enum class SaveStyle { PHOTO_ONLY, POSTCARD_FRAME }

enum class SaveResult { SAVED, NO_DEVELOPED, FAILED }

/**
 * Writes a developed print to the device gallery via MediaStore. On API 31+ no
 * runtime permission is needed to add our own images. Mirrors
 * `app/Tumble/App/PhotoLibrarySaver.swift`.
 */
@Singleton
class PhotoLibrarySaver @Inject constructor(
    @ApplicationContext private val context: Context,
    private val store: PhotoStore,
) {
    suspend fun saveDeveloped(photo: Photo, style: SaveStyle): SaveResult =
        withContext(Dispatchers.IO) {
            if (!photo.isDeveloped) return@withContext SaveResult.NO_DEVELOPED
            val source = decodeRaw(photo) ?: return@withContext SaveResult.NO_DEVELOPED
            val output = if (style == SaveStyle.POSTCARD_FRAME) postcard(source, photo.caption) else source
            if (writeToGallery(output, "tumble-${photo.id}")) SaveResult.SAVED else SaveResult.FAILED
        }

    private fun decodeRaw(photo: Photo): Bitmap? {
        val bytes = store.loadBytes(photo.rawImageName) ?: return null
        return android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    }

    /** Mount the square photo on cream stock with a caption strip below. */
    private fun postcard(photo: Bitmap, caption: String?): Bitmap {
        val size = 1280
        val margin = (size * 0.06f)
        val bottom = size * 0.14f
        val canvasBmp = Bitmap.createBitmap(size, (size + bottom).toInt(), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(canvasBmp)
        canvas.drawColor(Color.parseColor("#F4ECDA")) // printStock

        val dst = RectF(margin, margin, size - margin, size - margin)
        val src = Rect(0, 0, photo.width, photo.height)
        canvas.drawBitmap(photo, src, dst, Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG))

        if (!caption.isNullOrBlank()) {
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#B31E2A34")
                textAlign = Paint.Align.CENTER
                textSize = size * 0.05f
                isFakeBoldText = false
            }
            canvas.drawText(caption, size / 2f, size + bottom * 0.45f, paint)
        }
        return canvasBmp
    }

    private fun writeToGallery(bitmap: Bitmap, name: String): Boolean {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$name.jpg")
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Tumble")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return false
        return try {
            resolver.openOutputStream(uri)?.use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 92, out)
            } ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
            true
        } catch (_: Exception) {
            resolver.delete(uri, null, null)
            false
        }
    }
}
