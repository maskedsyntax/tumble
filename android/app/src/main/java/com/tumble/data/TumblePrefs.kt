package com.tumble.data

import android.content.Context
import android.content.SharedPreferences
import com.tumble.model.Entitlement
import com.tumble.roll.RollStore
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Small synchronous key-value state, backed by SharedPreferences — the Android
 * stand-in for the iOS App Group `UserDefaults`. Kept synchronous so
 * [com.tumble.roll.RollManager] mirrors the iOS logic and so the widget/tile can
 * read the same roll counter. Reactive flags expose a [StateFlow] for Compose.
 */
class TumblePrefs(context: Context) : RollStore {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("tumble", Context.MODE_PRIVATE)

    private object Key {
        const val consumed = "roll.consumedToday"
        const val lastReset = "roll.lastResetEpochDay"
        const val entitlement = "roll.entitlement"
        const val onboarded = "tumble.hasOnboarded"
        const val seenDrawerTips = "tumble.seenDrawerTips"
        const val postcardFrame = "tumble.saveIncludesPostcardFrame"
        const val notifAsked = "tumble.notif.asked"
        const val notifEnabled = "tumble.notif.enabled"
        const val reviewDeveloped = "tumble.review.developedCount"
        const val reviewSaved = "tumble.review.savedCount"
        const val reviewRequests = "tumble.review.requestCount"
        const val reviewLast = "tumble.review.lastRequest"
    }

    // MARK: RollStore (shared with the widget)

    override var consumedToday: Int
        get() = prefs.getInt(Key.consumed, 0)
        set(value) = prefs.edit().putInt(Key.consumed, value).apply()

    override var lastResetEpochDay: Long
        get() = prefs.getLong(Key.lastReset, -1)
        set(value) = prefs.edit().putLong(Key.lastReset, value).apply()

    override var entitlement: Entitlement
        get() = Entitlement.fromId(prefs.getString(Key.entitlement, null))
        set(value) = prefs.edit().putString(Key.entitlement, value.id).apply()

    // MARK: Reactive app flags

    private val _hasOnboarded = MutableStateFlow(prefs.getBoolean(Key.onboarded, false))
    val hasOnboarded: StateFlow<Boolean> = _hasOnboarded.asStateFlow()
    fun setOnboarded(value: Boolean) {
        prefs.edit().putBoolean(Key.onboarded, value).apply()
        _hasOnboarded.value = value
    }

    private val _postcardFrame = MutableStateFlow(prefs.getBoolean(Key.postcardFrame, false))
    val saveIncludesPostcardFrame: StateFlow<Boolean> = _postcardFrame.asStateFlow()
    fun setPostcardFrame(value: Boolean) {
        prefs.edit().putBoolean(Key.postcardFrame, value).apply()
        _postcardFrame.value = value
    }

    var seenDrawerTips: Boolean
        get() = prefs.getBoolean(Key.seenDrawerTips, false)
        set(value) = prefs.edit().putBoolean(Key.seenDrawerTips, value).apply()

    var notificationsAsked: Boolean
        get() = prefs.getBoolean(Key.notifAsked, false)
        set(value) = prefs.edit().putBoolean(Key.notifAsked, value).apply()

    var notificationsEnabled: Boolean
        get() = prefs.getBoolean(Key.notifEnabled, false)
        set(value) = prefs.edit().putBoolean(Key.notifEnabled, value).apply()

    // MARK: Review prompt bookkeeping (see ReviewPrompter)

    var reviewDevelopedCount: Int
        get() = prefs.getInt(Key.reviewDeveloped, 0)
        set(value) = prefs.edit().putInt(Key.reviewDeveloped, value).apply()

    var reviewSavedCount: Int
        get() = prefs.getInt(Key.reviewSaved, 0)
        set(value) = prefs.edit().putInt(Key.reviewSaved, value).apply()

    var reviewRequestCount: Int
        get() = prefs.getInt(Key.reviewRequests, 0)
        set(value) = prefs.edit().putInt(Key.reviewRequests, value).apply()

    var reviewLastRequestMillis: Long
        get() = prefs.getLong(Key.reviewLast, 0)
        set(value) = prefs.edit().putLong(Key.reviewLast, value).apply()
}
