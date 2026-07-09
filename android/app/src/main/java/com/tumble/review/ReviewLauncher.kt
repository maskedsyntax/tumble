package com.tumble.review

import android.app.Activity
import android.content.Context
import com.google.android.play.core.review.ReviewManagerFactory
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Launches the Play In-App Review flow when [ReviewTracker] says we're eligible.
 * The flow is a no-op quota-wise if Play decides not to show it — matching the
 * quiet, value-first intent of the iOS `SKStoreReviewController` usage.
 */
@Singleton
class ReviewLauncher @Inject constructor(
    @ApplicationContext private val context: Context,
    private val tracker: ReviewTracker,
) {
    fun maybeRequest(activity: Activity) {
        if (!tracker.shouldRequestReview()) return
        val manager = ReviewManagerFactory.create(context)
        manager.requestReviewFlow().addOnCompleteListener { request ->
            if (request.isSuccessful) {
                manager.launchReviewFlow(activity, request.result).addOnCompleteListener {
                    tracker.markRequested()
                }
            }
        }
    }
}
