package com.tumble.analytics

import android.content.Context
import com.posthog.PostHogInterface
import com.posthog.android.PostHogAndroid
import com.posthog.android.PostHogAndroidConfig
import com.tumble.BuildConfig

/** Consent boundary: no SDK instance, disk queue, identity, or network work exists before opt-in. */
class AnalyticsController(private val context: Context) {
    private val prefs = context.getSharedPreferences("tumble-v3", Context.MODE_PRIVATE)
    private var client: PostHogInterface? = null
    val enabled: Boolean get() = prefs.getBoolean(KEY, false)

    init { if (enabled) start() }

    fun setEnabled(value: Boolean) {
        prefs.edit().putBoolean(KEY, value).apply()
        if (value) start() else stopAndPurge()
    }

    fun capture(name: String, properties: Map<String, Any> = emptyMap()) {
        if (!enabled) return
        client?.capture(name, properties = properties.filterKeys { key -> FORBIDDEN.none(key.lowercase()::contains) })
    }

    private fun start() {
        if (client != null || BuildConfig.POSTHOG_API_KEY.isBlank()) return
        val config = PostHogAndroidConfig(BuildConfig.POSTHOG_API_KEY, BuildConfig.POSTHOG_HOST).apply {
            optOut = false
            captureApplicationLifecycleEvents = true
            captureScreenViews = false
            captureDeepLinks = false
            capturePushNotificationSubscriptions = false
            capturePushNotificationOpened = false
            surveys = false
            sessionReplay = true
            sessionReplayConfig.maskAllImages = true
            sessionReplayConfig.maskAllTextInputs = true
            sessionReplayConfig.captureLogcat = false
            sessionReplayConfig.screenshot = false
            sessionReplayConfig.sampleRate = .10
            errorTrackingConfig.captureNativeCrashes = true
        }
        client = PostHogAndroid.with(context.applicationContext, config)
    }

    private fun stopAndPurge() {
        client?.optOut()
        client?.reset()
        client?.close()
        client = null
        listOf("posthog-disk-queue", "posthog-disk-replay-queue", "posthog-disk-logs-queue")
            .map { java.io.File(context.cacheDir, it) }.forEach { it.deleteRecursively() }
    }

    companion object {
        private const val KEY = "analytics-enabled"
        private val FORBIDDEN = listOf("filename", "photo_id", "draft", "crop", "note", "image", "library_metadata")
    }
}
