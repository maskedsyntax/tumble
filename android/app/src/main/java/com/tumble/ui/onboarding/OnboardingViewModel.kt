package com.tumble.ui.onboarding

import android.content.Context
import android.graphics.Bitmap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.ImageBitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tumble.data.PhotoRepository
import com.tumble.data.TumblePrefs
import com.tumble.develop.Develop
import com.tumble.model.Photo
import com.tumble.model.PhotoSource
import com.tumble.motion.ShakeMonitor
import com.tumble.notif.RollReminders
import com.tumble.review.ReviewTracker
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * The value-first onboarding loop: the shooter takes a real (gifted) first shot,
 * shakes it to life, sees it land, then meets the premium tiers. Mirrors
 * `app/Tumble/Screens/OnboardingScreen.swift`.
 */
@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val repo: PhotoRepository,
    private val shake: ShakeMonitor,
    private val review: ReviewTracker,
    private val prefs: TumblePrefs,
    @ApplicationContext private val context: Context,
) : ViewModel() {

    enum class Step { WELCOME, CAPTURE, DEVELOP, PAYOFF, PREMIUM }

    var step by mutableStateOf(Step.WELCOME); private set
    var image by mutableStateOf<ImageBitmap?>(null); private set
    var progress by mutableFloatStateOf(0f); private set
    private var photo: Photo? = null

    val usesShake: Boolean get() = shake.isAvailable
    val isDeveloped: Boolean get() = progress >= 1f
    var onDeveloped: (() -> Unit)? = null

    fun goTo(next: Step) { step = next }

    /** The gifted first shot — does not spend one of the daily twelve. */
    fun captureGifted(bitmap: Bitmap) {
        viewModelScope.launch {
            val stored = repo.capture(bitmap, PhotoSource.APP, consumesRoll = false)
            photo = stored
            image = repo.loadBitmap(stored?.rawImageName)
            step = Step.DEVELOP
            if (usesShake) {
                shake.onShake = { energy -> advance(Develop.shakeAdvance(energy).toFloat()) }
                shake.start()
            }
        }
    }

    fun hold() = advance(Develop.HOLD_STEP.toFloat())

    private fun advance(amount: Float) {
        if (progress >= 1f) return
        progress = Develop.advanced(progress.toDouble(), amount.toDouble()).toFloat()
        if (progress >= 1f) {
            shake.stop()
            photo?.let { p -> viewModelScope.launch { repo.updateProgress(p, 1.0) } }
            review.recordDevelopedPrint()
            onDeveloped?.invoke()
        }
    }

    fun enableNotifications() {
        prefs.notificationsAsked = true
        prefs.notificationsEnabled = true
        RollReminders.schedule(context)
    }

    fun skipNotifications() {
        prefs.notificationsAsked = true
    }

    fun finish(onDone: () -> Unit) {
        prefs.setOnboarded(true)
        onDone()
    }

    override fun onCleared() {
        shake.stop()
    }
}
