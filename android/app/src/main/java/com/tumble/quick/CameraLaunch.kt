package com.tumble.quick

import android.content.Context
import android.content.Intent
import com.tumble.MainActivity
import com.tumble.data.TumblePrefs
import com.tumble.roll.RollManager

/**
 * Shared plumbing for the quick-capture surfaces (widget, QS tile, launcher
 * shortcut) — the Android replacements for the iOS lock-screen camera / Control
 * Center button / Dynamic Island. All of them just deep-link into the app's
 * camera and read the same roll counter the app uses.
 */
object CameraLaunch {
    const val EXTRA_OPEN_CAMERA = "com.tumble.OPEN_CAMERA"

    fun intent(context: Context): Intent =
        Intent(context, MainActivity::class.java)
            .putExtra(EXTRA_OPEN_CAMERA, true)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

    /** The same "N left today" copy the app shows, computed from shared prefs. */
    fun remainingLabel(context: Context): String {
        val prefs = TumblePrefs(context.applicationContext)
        return RollManager(prefs).remainingLabel
    }
}
