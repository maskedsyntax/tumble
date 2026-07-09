package com.tumble.ui.home

import android.graphics.Bitmap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.ImageBitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tumble.data.PhotoRepository
import com.tumble.data.TumblePrefs
import com.tumble.model.Photo
import com.tumble.model.PhotoDay
import com.tumble.model.PhotoSource
import com.tumble.roll.RollManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val repo: PhotoRepository,
    private val roll: RollManager,
    private val prefs: TumblePrefs,
) : ViewModel() {

    val days: StateFlow<List<PhotoDay>> = repo.observeAll()
        .map { PhotoDay.group(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    var remainingLabel by mutableStateOf(roll.remainingLabel); private set
    var canShoot by mutableStateOf(roll.canShoot); private set
    var remaining by mutableStateOf(roll.remaining); private set
    val isUnlimited: Boolean get() = roll.isUnlimited

    var seenDrawerTips by mutableStateOf(prefs.seenDrawerTips); private set

    fun onResume() {
        roll.refresh()
        syncRoll()
    }

    private fun syncRoll() {
        remainingLabel = roll.remainingLabel
        canShoot = roll.canShoot
        remaining = roll.remaining
    }

    fun dismissDrawerTips() {
        prefs.seenDrawerTips = true
        seenDrawerTips = true
    }

    /** Debug: seed sample prints across several days so Collections is testable. */
    fun seedDebugDays() {
        viewModelScope.launch { repo.seedSampleDays() }
    }

    /** Capture from the pull-down camera; the blank print lands in the Drawer. */
    fun capture(bitmap: Bitmap, onResult: (Photo?) -> Unit) {
        viewModelScope.launch {
            val photo = repo.capture(bitmap, PhotoSource.APP)
            syncRoll()
            onResult(photo)
        }
    }

    fun loadBitmap(name: String?): ImageBitmap? = repo.loadBitmap(name)
}
