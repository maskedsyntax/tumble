package com.tumble.ui.capture

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import com.tumble.camera.CameraPreview
import com.tumble.camera.rememberCameraController
import com.tumble.film.FilmScene
import com.tumble.ui.components.CameraToolButton
import com.tumble.ui.components.CircleIconButton
import com.tumble.ui.theme.GraincoreBackground
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType

/**
 * Temporary full-screen camera used to exercise capture → develop → Drawer.
 * Phase 9 replaces this with the pull-down-from-the-top camera window.
 */
@Composable
fun CaptureScreen(
    onClose: () -> Unit,
    onCaptured: (String) -> Unit,
    viewModel: CaptureViewModel = hiltViewModel(),
) {
    val context = LocalContext.current
    val controller = rememberCameraController()
    var hasPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED,
        )
    }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted -> hasPermission = granted }

    LaunchedEffect(Unit) {
        if (!hasPermission) permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    // Synthetic placeholder for when there's no camera/permission.
    val placeholder = remember { FilmScene.random().render().asImageBitmap() }

    Box(Modifier.fillMaxSize()) {
        GraincoreBackground()

        Column(
            modifier = Modifier.fillMaxSize().padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(0.86f)
                    .clip(RoundedCornerShape(28.dp))
                    .border(1.dp, Palette.amber.copy(alpha = 0.3f), RoundedCornerShape(28.dp)),
                contentAlignment = Alignment.Center,
            ) {
                if (hasPermission && !controller.isSimulated) {
                    CameraPreview(controller, Modifier.fillMaxSize())
                } else {
                    Image(placeholder, null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                }

                // Flash + switch overlays — always shown, dimmed when unavailable.
                Box(Modifier.fillMaxSize().padding(12.dp)) {
                    CameraToolButton(
                        icon = if (controller.flashOn) Icons.Filled.FlashOn else Icons.Filled.FlashOff,
                        contentDescription = if (controller.flashOn) "Turn flash off" else "Turn flash on",
                        enabled = controller.supportsFlash,
                        onClick = controller::toggleFlash,
                        modifier = Modifier.align(Alignment.TopStart),
                    )
                    CameraToolButton(
                        icon = Icons.Filled.Cameraswitch,
                        contentDescription = "Switch camera",
                        enabled = controller.canSwitch && !controller.isSimulated,
                        onClick = controller::switchCamera,
                        modifier = Modifier.align(Alignment.TopEnd),
                    )
                }
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(top = 24.dp)) {
                if (viewModel.canShoot) {
                    Text(viewModel.remainingLabel, style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream))
                    Box(
                        modifier = Modifier
                            .padding(top = 12.dp)
                            .size(72.dp)
                            .clip(CircleShape)
                            .background(Palette.cream)
                            .clickable {
                                controller.capture { bitmap ->
                                    viewModel.capture(bitmap) { photo ->
                                        if (photo != null) onCaptured(photo.id) else onClose()
                                    }
                                }
                            },
                    )
                } else {
                    Text("That's the roll for today.", style = TumbleType.display(20).copy(color = Palette.cream))
                    Text(
                        "Fresh twelve at sunrise.",
                        style = TumbleType.sans(14).copy(color = Palette.cream.copy(alpha = 0.7f)),
                    )
                }
            }
        }

        Box(Modifier.fillMaxSize().padding(20.dp)) {
            CircleIconButton(
                Icons.Rounded.Close,
                "Close",
                onClose,
                modifier = Modifier.align(Alignment.TopEnd),
            )
        }
    }
}
