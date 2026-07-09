package com.tumble.camera

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.tumble.film.FilmScene

enum class CameraSide { BACK, FRONT }

/**
 * Thin wrapper over CameraX. On a device it drives the camera and captures a
 * still; when there's no usable camera it hands back a synthetic [FilmScene] so
 * the whole flow stays exercisable (never a black viewfinder). Ported from
 * `app/TumbleKit/Camera/CameraController.swift`.
 */
class CameraController(private val context: Context) {

    var isSimulated by mutableStateOf(false); private set
    var side by mutableStateOf(CameraSide.BACK); private set
    var flashOn by mutableStateOf(false); private set
    var supportsFlash by mutableStateOf(false); private set
    var canSwitch by mutableStateOf(false); private set

    private val preview = Preview.Builder().build()
    private var imageCapture: ImageCapture? = null
    private var provider: ProcessCameraProvider? = null
    private var owner: LifecycleOwner? = null
    private val mainExecutor = ContextCompat.getMainExecutor(context)

    fun attachPreview(view: PreviewView) {
        preview.setSurfaceProvider(view.surfaceProvider)
    }

    fun bind(lifecycleOwner: LifecycleOwner) {
        owner = lifecycleOwner
        if (!context.packageManager.hasSystemFeature("android.hardware.camera.any")) {
            isSimulated = true
            return
        }
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            runCatching {
                val p = future.get()
                provider = p
                canSwitch = p.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA) &&
                    p.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)
                rebind()
            }.onFailure { isSimulated = true }
        }, mainExecutor)
    }

    private fun rebind() {
        val p = provider ?: return
        val lifecycleOwner = owner ?: return
        val selector = if (side == CameraSide.BACK) {
            CameraSelector.DEFAULT_BACK_CAMERA
        } else {
            CameraSelector.DEFAULT_FRONT_CAMERA
        }
        if (!p.hasCamera(selector)) {
            isSimulated = true
            return
        }
        val capture = ImageCapture.Builder()
            .setFlashMode(if (flashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF)
            .build()
        try {
            p.unbindAll()
            val camera: Camera = p.bindToLifecycle(lifecycleOwner, selector, preview, capture)
            imageCapture = capture
            supportsFlash = side == CameraSide.BACK && camera.cameraInfo.hasFlashUnit()
            if (!supportsFlash) flashOn = false
            isSimulated = false
        } catch (_: Exception) {
            isSimulated = true
        }
    }

    fun switchCamera() {
        if (!canSwitch || isSimulated) return
        side = if (side == CameraSide.BACK) CameraSide.FRONT else CameraSide.BACK
        rebind()
    }

    fun toggleFlash() {
        if (!supportsFlash || isSimulated) return
        flashOn = !flashOn
        imageCapture?.flashMode =
            if (flashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF
    }

    /** Capture a still, delivered as a Bitmap on the main thread. */
    fun capture(onImage: (Bitmap) -> Unit) {
        val capture = imageCapture
        if (isSimulated || capture == null) {
            onImage(FilmScene.random().render())
            return
        }
        capture.takePicture(
            mainExecutor,
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(image: ImageProxy) {
                    val bitmap = image.toBitmap().rotated(image.imageInfo.rotationDegrees)
                    image.close()
                    onImage(bitmap)
                }

                override fun onError(exception: ImageCaptureException) {
                    onImage(FilmScene.random().render())
                }
            },
        )
    }

    private fun Bitmap.rotated(degrees: Int): Bitmap {
        if (degrees == 0) return this
        val matrix = Matrix().apply { postRotate(degrees.toFloat()) }
        return Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)
    }
}
