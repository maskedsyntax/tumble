package com.tumble.ui.capture

import android.graphics.Bitmap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tumble.data.PhotoRepository
import com.tumble.model.Photo
import com.tumble.model.PhotoSource
import com.tumble.roll.RollManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CaptureViewModel @Inject constructor(
    private val repo: PhotoRepository,
    private val roll: RollManager,
) : ViewModel() {

    var remainingLabel by mutableStateOf(roll.remainingLabel); private set
    var canShoot by mutableStateOf(roll.canShoot); private set

    init {
        roll.refresh()
        sync()
    }

    fun capture(bitmap: Bitmap, consumesRoll: Boolean = true, onResult: (Photo?) -> Unit) {
        viewModelScope.launch {
            val photo = repo.capture(bitmap, PhotoSource.APP, consumesRoll)
            sync()
            onResult(photo)
        }
    }

    private fun sync() {
        remainingLabel = roll.remainingLabel
        canShoot = roll.canShoot
    }
}
