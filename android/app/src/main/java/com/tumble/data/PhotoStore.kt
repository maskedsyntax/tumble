package com.tumble.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import com.tumble.model.Photo
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Owns the image files that back each [Photo]. Bytes live in the app's private
 * files dir; names are `{id}-raw.jpg` / `{id}-dev.jpg`, matching the iOS scheme
 * in `app/TumbleKit/Storage/PhotoStore.swift`.
 */
class PhotoStore(private val context: Context) {

    enum class ImageKind(val suffix: String) { RAW("raw"), DEVELOPED("dev") }

    private val dir: File by lazy {
        File(context.filesDir, "images").apply { mkdirs() }
    }

    fun imageFile(name: String): File = File(dir, name)

    /** Persist image bytes and return the file name to store on the [Photo]. */
    fun writeImage(bytes: ByteArray, id: String, kind: ImageKind): String {
        val name = "$id-${kind.suffix}.jpg"
        imageFile(name).writeBytes(bytes)
        return name
    }

    /** Compress a bitmap to JPEG at 90% quality (matches iOS) and persist it. */
    fun writeImage(bitmap: Bitmap, id: String, kind: ImageKind): String {
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        return writeImage(out.toByteArray(), id, kind)
    }

    fun loadBytes(name: String?): ByteArray? {
        if (name == null) return null
        val file = imageFile(name)
        return if (file.exists()) file.readBytes() else null
    }

    fun loadBitmap(name: String?): ImageBitmap? {
        val bytes = loadBytes(name) ?: return null
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)?.asImageBitmap()
    }

    fun deleteImage(name: String?) {
        if (name == null) return
        imageFile(name).delete()
    }

    fun deleteImages(photo: Photo) {
        deleteImage(photo.rawImageName)
        deleteImage(photo.developedImageName)
    }
}
