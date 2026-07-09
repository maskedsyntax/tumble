package com.tumble.ui.develop

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.ImageBitmap
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tumble.data.PhotoRepository
import com.tumble.data.TumblePrefs
import com.tumble.develop.Develop
import com.tumble.model.Photo
import android.app.Activity
import com.tumble.motion.ShakeMonitor
import com.tumble.review.ReviewLauncher
import com.tumble.review.ReviewTracker
import com.tumble.save.PhotoLibrarySaver
import com.tumble.save.SaveResult
import com.tumble.save.SaveStyle
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DevelopViewModel @Inject constructor(
    private val repo: PhotoRepository,
    private val shake: ShakeMonitor,
    private val review: ReviewTracker,
    private val reviewLauncher: ReviewLauncher,
    private val saver: PhotoLibrarySaver,
    private val prefs: TumblePrefs,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    /** Ask for a rating if we're eligible (3 develops or a save). */
    fun requestReview(activity: Activity) = reviewLauncher.maybeRequest(activity)

    private val photoId: String = checkNotNull(savedStateHandle["photoId"])

    var photo by mutableStateOf<Photo?>(null); private set
    var image by mutableStateOf<ImageBitmap?>(null); private set
    var progress by mutableStateOf(0f); private set
    var saving by mutableStateOf(false); private set
    var saveMessage by mutableStateOf<String?>(null); private set

    val postcardFrame: StateFlow<Boolean> = prefs.saveIncludesPostcardFrame
    fun setPostcardFrame(value: Boolean) = prefs.setPostcardFrame(value)

    val usesShake: Boolean get() = shake.isAvailable
    val isDeveloped: Boolean get() = progress >= 1f

    /** Fired when a print finishes developing (so the UI can pop a success haptic). */
    var onDeveloped: (() -> Unit)? = null

    init {
        viewModelScope.launch {
            val p = repo.byId(photoId) ?: return@launch
            photo = p
            progress = p.developProgress.toFloat()
            image = repo.loadBitmap(p.rawImageName)
            if (!isDeveloped && usesShake) {
                shake.onShake = { energy -> advance(Develop.shakeAdvance(energy).toFloat()) }
                shake.start()
            }
        }
    }

    /** Advance from a hold: called on a ~16ms tick while the button is pressed. */
    fun hold() = advance(Develop.HOLD_STEP.toFloat())

    private fun advance(amount: Float) {
        if (progress >= 1f) return
        progress = Develop.advanced(progress.toDouble(), amount.toDouble()).toFloat()
        if (progress >= 1f) finish()
    }

    private fun finish() {
        shake.stop()
        val current = photo ?: return
        viewModelScope.launch { repo.updateProgress(current, 1.0) }
        review.recordDevelopedPrint()
        onDeveloped?.invoke()
    }

    fun save() {
        val current = photo ?: return
        if (!isDeveloped || saving) return
        viewModelScope.launch {
            saving = true
            val style = if (postcardFrame.value) SaveStyle.POSTCARD_FRAME else SaveStyle.PHOTO_ONLY
            val result = saver.saveDeveloped(current, style)
            saveMessage = when (result) {
                SaveResult.SAVED ->
                    if (style == SaveStyle.POSTCARD_FRAME) "Saved postcard to Photos." else "Saved photo to Photos."
                SaveResult.NO_DEVELOPED -> "Develop this print before saving."
                SaveResult.FAILED -> "Could not save. Try again."
            }
            if (result == SaveResult.SAVED) review.recordSavedToPhotos()
            saving = false
        }
    }

    fun clearSaveMessage() { saveMessage = null }

    fun delete(onDone: () -> Unit) {
        val current = photo ?: return
        shake.stop()
        viewModelScope.launch {
            repo.delete(current)
            onDone()
        }
    }

    override fun onCleared() {
        shake.stop()
        // Persist partial progress so a half-shaken print resumes next time.
        val current = photo ?: return
        if (progress < 1f && progress > current.developProgress) {
            viewModelScope.launch { repo.updateProgress(current, progress.toDouble()) }
        }
    }
}
