package com.tumble.review

import com.tumble.data.TumblePrefs
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Decides when to ask for an app rating — value-first and rarely. Mirrors
 * `app/Tumble/App/ReviewPrompter.swift`: eligible after 3 prints developed or
 * any print saved to Photos, capped at 2 requests ever with a 90-day cooldown.
 * The actual Play In-App Review flow is launched by the UI layer (Phase 7).
 */
@Singleton
class ReviewTracker @Inject constructor(private val prefs: TumblePrefs) {

    private val cooldownMillis = 90L * 24 * 60 * 60 * 1000
    private val maxRequests = 2

    fun recordDevelopedPrint() {
        prefs.reviewDevelopedCount += 1
    }

    fun recordSavedToPhotos() {
        prefs.reviewSavedCount += 1
    }

    fun shouldRequestReview(now: Long = System.currentTimeMillis()): Boolean {
        if (prefs.reviewRequestCount >= maxRequests) return false
        val last = prefs.reviewLastRequestMillis
        if (last > 0 && now - last < cooldownMillis) return false
        return prefs.reviewDevelopedCount >= 3 || prefs.reviewSavedCount >= 1
    }

    fun markRequested(now: Long = System.currentTimeMillis()) {
        prefs.reviewRequestCount += 1
        prefs.reviewLastRequestMillis = now
    }
}
