package com.tumble.ui.home

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Cameraswitch
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.lerp
import androidx.core.content.ContextCompat
import com.tumble.camera.CameraPreview
import com.tumble.camera.rememberCameraController
import com.tumble.film.FilmScene
import com.tumble.ui.components.CircleIconButton
import com.tumble.ui.components.PrintView
import com.tumble.ui.theme.Palette
import com.tumble.ui.theme.TumbleType
import kotlinx.coroutines.launch

/**
 * The camera as a window you pull down from the top — the Android adaptation of
 * the iOS Dynamic-Island camera. At rest it's a pill; drag (or tap) to expand
 * into a live viewfinder, shoot, and the blank print ejects into the Drawer.
 */
@Composable
fun PullDownCamera(
    remainingLabel: String,
    canShoot: Boolean,
    onCapture: (android.graphics.Bitmap, () -> Unit) -> Unit,
    onNeedMore: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val controller = rememberCameraController()
    val progress = remember { Animatable(0f) }
    val eject = remember { Animatable(0f) }
    var ejectImage by remember { mutableStateOf<androidx.compose.ui.graphics.ImageBitmap?>(null) }
    var capturing by remember { mutableStateOf(false) }

    var hasPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED,
        )
    }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted -> hasPermission = granted }
    val placeholder = remember { FilmScene.random().render().asImageBitmap() }

    val screenW = LocalConfiguration.current.screenWidthDp.dp
    val openW = minOf(screenW - 40.dp, 330.dp)
    val previewH = openW * 0.86f
    val openH = previewH + 96.dp
    val closedW = 126.dp
    val closedH = 37.dp

    val p = progress.value
    val windowW = lerp(closedW, openW, p)
    val windowH = lerp(closedH, openH, p)
    val corner = lerp(19.dp, 42.dp, p)
    val openDistancePx = with(LocalDensity.current) { (openH - closedH).toPx() }

    fun animateTo(target: Float) {
        scope.launch { progress.animateTo(target, tween(320)) }
        if (target > 0f && !hasPermission) permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    Box(modifier.fillMaxSize()) {
        // Dim + tap-out when open.
        if (p > 0.01f) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = p * 0.55f))
                    .pointerTap { animateTo(0f) },
            )
        }

        Column(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .width(windowW)
                    .height(windowH)
                    .clip(RoundedCornerShape(corner))
                    .background(Color.Black)
                    .border(1.dp, Palette.amber.copy(alpha = 0.3f), RoundedCornerShape(corner))
                    .verticalDrag(
                        openDistancePx = openDistancePx,
                        onDelta = { delta ->
                            scope.launch { progress.snapTo((progress.value + delta).coerceIn(0f, 1f)) }
                        },
                        onEnd = { animateTo(if (progress.value > 0.42f) 1f else 0f) },
                        onTap = { animateTo(if (progress.value < 0.5f) 1f else 0f) },
                    ),
                contentAlignment = Alignment.TopCenter,
            ) {
                if (p < 0.42f) {
                    // Closed pill: camera glyph + remaining.
                    Row(
                        Modifier.fillMaxSize().padding(horizontal = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center,
                    ) {
                        Icon(Icons.Filled.CameraAlt, null, tint = Palette.amber, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(remainingLabel, style = TumbleType.sans(12, FontWeight.SemiBold).copy(color = Palette.cream), maxLines = 1)
                    }
                } else {
                    OpenCameraContent(
                        controller = controller,
                        hasPermission = hasPermission,
                        placeholder = placeholder,
                        previewH = previewH,
                        canShoot = canShoot,
                        remainingLabel = remainingLabel,
                        capturing = capturing,
                        onShutter = {
                            if (capturing) return@OpenCameraContent
                            capturing = true
                            controller.capture { bitmap ->
                                ejectImage = bitmap.asImageBitmap()
                                onCapture(bitmap) {}
                                scope.launch {
                                    eject.snapTo(0f)
                                    eject.animateTo(1f, tween(800))
                                    animateTo(0f)
                                    ejectImage = null
                                    eject.snapTo(0f)
                                    capturing = false
                                }
                            }
                        },
                        onNeedMore = onNeedMore,
                        onClose = { animateTo(0f) },
                    )
                }
            }
        }

        // Ejected print animating down into the Drawer.
        ejectImage?.let { image ->
            val e = eject.value
            PrintView(
                image = image,
                isDeveloped = false,
                developProgress = 0f,
                width = 120.dp,
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = openH * 0.4f)
                    .graphicsLayer {
                        translationY = e * 600f
                        alpha = 1f - e
                        rotationZ = e * 8f
                    },
            )
        }
    }
}

@Composable
private fun OpenCameraContent(
    controller: com.tumble.camera.CameraController,
    hasPermission: Boolean,
    placeholder: androidx.compose.ui.graphics.ImageBitmap,
    previewH: androidx.compose.ui.unit.Dp,
    canShoot: Boolean,
    remainingLabel: String,
    capturing: Boolean,
    onShutter: () -> Unit,
    onNeedMore: () -> Unit,
    onClose: () -> Unit,
) {
    Column(Modifier.fillMaxWidth().padding(10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(previewH)
                .clip(RoundedCornerShape(24.dp)),
            contentAlignment = Alignment.Center,
        ) {
            if (hasPermission && !controller.isSimulated) {
                CameraPreview(controller, Modifier.fillMaxSize())
            } else {
                Image(placeholder, null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
            }
            Box(Modifier.fillMaxSize().padding(8.dp)) {
                if (controller.supportsFlash) {
                    CircleIconButton(
                        if (controller.flashOn) Icons.Filled.FlashOn else Icons.Filled.FlashOff,
                        "Flash", controller::toggleFlash, Modifier.align(Alignment.TopStart), size = 32,
                    )
                }
                if (controller.canSwitch) {
                    CircleIconButton(
                        Icons.Filled.Cameraswitch, "Switch camera", controller::switchCamera,
                        Modifier.align(Alignment.TopEnd), size = 32,
                    )
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        if (canShoot) {
            Text(remainingLabel, style = TumbleType.sans(12, FontWeight.SemiBold).copy(color = Palette.cream))
            Spacer(Modifier.height(6.dp))
            Box(
                Modifier
                    .size(54.dp)
                    .clip(CircleShape)
                    .background(if (capturing) Palette.cream.copy(alpha = 0.6f) else Palette.cream)
                    .pointerTap(onShutter),
            )
        } else {
            Text("That's the roll for today.", style = TumbleType.sans(13, FontWeight.SemiBold).copy(color = Palette.cream))
            Spacer(Modifier.height(6.dp))
            Text(
                "Own more",
                style = TumbleType.sans(13, FontWeight.Bold).copy(color = Palette.ink),
                modifier = Modifier.clip(CircleShape).background(Palette.amber).pointerTap(onNeedMore).padding(horizontal = 18.dp, vertical = 8.dp),
            )
        }
    }
}

/** Tap without the ripple/indication plumbing of clickable. */
private fun Modifier.pointerTap(onTap: () -> Unit): Modifier =
    this.pointerInput(onTap) { detectTapGestures(onTap = { onTap() }) }

/** Vertical drag handle that also supports a tap toggle. */
private fun Modifier.verticalDrag(
    openDistancePx: Float,
    onDelta: (Float) -> Unit,
    onEnd: () -> Unit,
    onTap: () -> Unit,
): Modifier = this
    .pointerInput(openDistancePx) {
        detectVerticalDragGestures(
            onVerticalDrag = { _, dy -> onDelta(dy / openDistancePx) },
            onDragEnd = { onEnd() },
        )
    }
    .pointerInput(Unit) { detectTapGestures(onTap = { onTap() }) }
