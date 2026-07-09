package com.tumble.ui.collection

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
import com.tumble.model.PhotoDay
import com.tumble.review.ReviewTracker
import com.tumble.save.PhotoLibrarySaver
import com.tumble.save.SaveResult
import com.tumble.save.SaveStyle
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DayCollectionViewModel @Inject constructor(
    private val repo: PhotoRepository,
    private val saver: PhotoLibrarySaver,
    private val review: ReviewTracker,
    private val prefs: TumblePrefs,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val epochDay: Long = checkNotNull(savedStateHandle["day"])

    var title by mutableStateOf(""); private set
    var photos by mutableStateOf<List<Photo>>(emptyList()); private set
    var developedCount by mutableStateOf(0); private set
    var saveMessage by mutableStateOf<String?>(null); private set
    var saving by mutableStateOf(false); private set

    val postcardFrame: StateFlow<Boolean> = prefs.saveIncludesPostcardFrame
    fun setPostcardFrame(value: Boolean) = prefs.setPostcardFrame(value)

    init {
        viewModelScope.launch {
            val day = PhotoDay.group(repo.currentPhotos()).firstOrNull { it.dayStart.toEpochDay() == epochDay }
            title = day?.displayTitle ?: ""
            photos = day?.photos ?: emptyList()
            developedCount = day?.developedCount ?: 0
        }
    }

    fun loadBitmap(name: String?): ImageBitmap? = repo.loadBitmap(name)

    fun saveDay() {
        if (saving) return
        viewModelScope.launch {
            saving = true
            val style = if (postcardFrame.value) SaveStyle.POSTCARD_FRAME else SaveStyle.PHOTO_ONLY
            var saved = 0
            photos.filter { it.isDeveloped }.forEach { photo ->
                if (saver.saveDeveloped(photo, style) == SaveResult.SAVED) saved++
            }
            if (saved > 0) review.recordSavedToPhotos()
            saveMessage = if (saved > 0) "Saved $saved to Photos." else "Nothing developed to save yet."
            saving = false
        }
    }

    fun clearSaveMessage() { saveMessage = null }
}
