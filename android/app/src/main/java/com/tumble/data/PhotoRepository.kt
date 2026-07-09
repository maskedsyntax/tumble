package com.tumble.data

import android.graphics.Bitmap
import androidx.compose.ui.graphics.ImageBitmap
import com.tumble.model.Photo
import com.tumble.model.PhotoSource
import com.tumble.roll.RollManager
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * The Drawer's data gateway: fetches prints, captures new ones (spending a shot
 * unless gifted), advances develop progress, and deletes. Mirrors the iOS
 * `CaptureService` + `PhotoStore` split.
 */
@Singleton
class PhotoRepository @Inject constructor(
    private val dao: PhotoDao,
    private val store: PhotoStore,
    private val roll: RollManager,
) {
    fun observeAll(): Flow<List<Photo>> = dao.observeAll()

    fun observeById(id: String): Flow<Photo?> = dao.observeById(id)

    suspend fun byId(id: String): Photo? = dao.byId(id)

    suspend fun currentPhotos(): List<Photo> = dao.all()

    fun loadBitmap(name: String?): ImageBitmap? = store.loadBitmap(name)

    /**
     * Turn a captured frame into a stored, undeveloped print. Returns null when
     * the roll is empty (and [consumesRoll] is true). Pass `consumesRoll = false`
     * for the gifted onboarding shot.
     */
    suspend fun capture(
        bitmap: Bitmap,
        source: PhotoSource,
        consumesRoll: Boolean = true,
    ): Photo? {
        if (consumesRoll && !roll.consumeShot()) return null
        val photo = Photo.create(source = source)
        val rawName = store.writeImage(bitmap, photo.id, PhotoStore.ImageKind.RAW)
        val stored = photo.copy(rawImageName = rawName)
        dao.upsert(stored)
        return stored
    }

    /** Persist develop progress so a half-shaken print resumes where it was. */
    suspend fun updateProgress(photo: Photo, progress: Double) {
        val done = progress >= 1.0
        dao.upsert(
            photo.copy(
                developProgress = progress.coerceIn(0.0, 1.0),
                isDeveloped = done || photo.isDeveloped,
            ),
        )
    }

    suspend fun delete(photo: Photo) {
        store.deleteImages(photo)
        dao.delete(photo)
    }
}
