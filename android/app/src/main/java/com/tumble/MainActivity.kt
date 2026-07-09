package com.tumble

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.view.WindowCompat
import com.tumble.quick.CameraLaunch
import com.tumble.ui.TumbleNavHost
import com.tumble.ui.theme.TumbleTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private var openCameraSignal by mutableStateOf(0)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (wantsCamera(intent)) openCameraSignal++
        setContent {
            TumbleTheme {
                TumbleNavHost(openCameraSignal = openCameraSignal)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (wantsCamera(intent)) openCameraSignal++
    }

    /** Widget/tile/shortcut deep-link into the camera (extra may be bool or string). */
    private fun wantsCamera(intent: Intent?): Boolean {
        intent ?: return false
        return intent.getBooleanExtra(CameraLaunch.EXTRA_OPEN_CAMERA, false) ||
            intent.getStringExtra(CameraLaunch.EXTRA_OPEN_CAMERA) == "true"
    }
}
