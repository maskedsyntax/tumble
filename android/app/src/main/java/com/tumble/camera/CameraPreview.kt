package com.tumble.camera

import androidx.camera.view.PreviewView
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.viewinterop.AndroidView

@Composable
fun rememberCameraController(): CameraController {
    val context = LocalContext.current
    return remember { CameraController(context.applicationContext) }
}

/** Live CameraX viewfinder. Binds to the current lifecycle on first layout. */
@Composable
fun CameraPreview(controller: CameraController, modifier: Modifier = Modifier) {
    val lifecycleOwner = LocalLifecycleOwner.current
    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            PreviewView(ctx).apply {
                scaleType = PreviewView.ScaleType.FILL_CENTER
                controller.attachPreview(this)
                controller.bind(lifecycleOwner)
            }
        },
    )
}
