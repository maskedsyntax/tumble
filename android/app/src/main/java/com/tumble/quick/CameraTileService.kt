package com.tumble.quick

import android.service.quicksettings.TileService

/**
 * Quick Settings tile that jumps straight into the camera — the Android stand-in
 * for the iOS Control Center capture button.
 */
class CameraTileService : TileService() {
    override fun onClick() {
        super.onClick()
        val intent = CameraLaunch.intent(this)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                android.app.PendingIntent.getActivity(
                    this, 0, intent,
                    android.app.PendingIntent.FLAG_IMMUTABLE or android.app.PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
