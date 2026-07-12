package com.tumble.ui.detail

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.ImageBitmap
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tumble.data.PhotoRepository
import com.tumble.data.TumblePrefs
import com.tumble.model.Photo
import com.tumble.review.ReviewTracker
import com.tumble.save.PhotoLibrarySaver
import com.tumble.save.SaveResult
import com.tumble.save.SaveStyle
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.ZoneId
import javax.inject.Inject

@HiltViewModel
class PrintDetailViewModel @Inject constructor(
    private val repo: PhotoRepository,
    private val saver: PhotoLibrarySaver,
    private val review: ReviewTracker,
    private val prefs: TumblePrefs,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val startPhotoId: String = checkNotNull(savedStateHandle["photoId"])

    var prints by mutableStateOf<List<Photo>>(emptyList()); private set
    var startIndex by mutableStateOf(0); private set
    var saving by mutableStateOf(false); private set
    var saveMessage by mutableStateOf<String?>(null); private set

    val postcardFrame: StateFlow<Boolean> = prefs.saveIncludesPostcardFrame
    fun setPostcardFrame(value: Boolean) = prefs.setPostcardFrame(value)

    /** Flip the save format and surface a hint about what it does. */
    fun toggleFrame() {
        val next = !postcardFrame.value
        setPostcardFrame(next)
        saveMessage = if (next) "Saving as a postcard" else "Saving photo only"
    }

    init {
        viewModelScope.launch { reload() }
    }

    private suspend fun reload() {
        val target = repo.byId(startPhotoId) ?: return
        val zone = ZoneId.systemDefault()
        val day = target.capturedAt.atZone(zone).toLocalDate()
        val developed = repo.currentPhotos()
            .filter { it.isDeveloped && it.capturedAt.atZone(zone).toLocalDate() == day }
            .sortedByDescending { it.capturedAt }
        prints = developed
        startIndex = developed.indexOfFirst { it.id == startPhotoId }.coerceAtLeast(0)
    }

    fun loadBitmap(name: String?): ImageBitmap? = repo.loadBitmap(name)

    fun save(photo: Photo) {
        if (saving) return
        viewModelScope.launch {
            saving = true
            val style = if (postcardFrame.value) SaveStyle.POSTCARD_FRAME else SaveStyle.PHOTO_ONLY
            val result = saver.saveDeveloped(photo, style)
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

    fun delete(photo: Photo, onEmpty: () -> Unit) {
        viewModelScope.launch {
            repo.delete(photo)
            reload()
            if (prints.isEmpty()) onEmpty()
        }
    }
}
