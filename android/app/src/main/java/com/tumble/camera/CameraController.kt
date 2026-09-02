package com.tumble.camera

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.view.Surface
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.Executors

enum class CameraSide { BACK, FRONT }

sealed interface CameraStatus {
    data object Initializing : CameraStatus
    data object Ready : CameraStatus
    data class Unavailable(val reason: String) : CameraStatus
    data class Failure(val reason: String) : CameraStatus
}

sealed interface CameraCaptureResult {
    data class Success(val bitmap: Bitmap) : CameraCaptureResult
    data class Unavailable(val reason: String) : CameraCaptureResult
    data class Failure(val reason: String, val cause: Throwable? = null) : CameraCaptureResult
}

/**
 * Thin wrapper over CameraX. On a device it drives the camera and captures a
 * still. Production captures always report an explicit result: camera failures
 * can never be mistaken for real photographs or enter the user's Drawer.
 */
class CameraController(private val context: Context) {

    var status by mutableStateOf<CameraStatus>(CameraStatus.Initializing); private set
    var side by mutableStateOf(CameraSide.BACK); private set
    var flashOn by mutableStateOf(false); private set
    var supportsFlash by mutableStateOf(false); private set
    var canSwitch by mutableStateOf(false); private set
    var filteredPreview by mutableStateOf<Bitmap?>(null); private set

    private val preview = Preview.Builder().build()
    private var imageCapture: ImageCapture? = null
    private var provider: ProcessCameraProvider? = null
    private var owner: LifecycleOwner? = null
    private var previewView: PreviewView? = null
    private val mainExecutor = ContextCompat.getMainExecutor(context)
    private val captureInProgress = AtomicBoolean(false)
    private val previewInProgress = AtomicBoolean(false)
    private val previewExecutor = Executors.newSingleThreadExecutor()
    @Volatile private var previewRenderer: ((Bitmap) -> Bitmap?)? = null

    val isReady: Boolean get() = status == CameraStatus.Ready
    val isCapturing: Boolean get() = captureInProgress.get()

    fun setPreviewRenderer(renderer: ((Bitmap) -> Bitmap?)?) {
        previewRenderer = renderer
        if (renderer == null) filteredPreview = null
    }

    fun attachPreview(view: PreviewView) {
        previewView = view
        preview.setSurfaceProvider(view.surfaceProvider)
    }

    fun bind(lifecycleOwner: LifecycleOwner) {
        owner = lifecycleOwner
        if (!context.packageManager.hasSystemFeature("android.hardware.camera.any")) {
            status = CameraStatus.Unavailable("This device does not have a camera.")
            return
        }
        status = CameraStatus.Initializing
        val future = ProcessCameraProvider.getInstance(context)
        future.addListener({
            runCatching {
                val p = future.get()
                provider = p
                canSwitch = p.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA) &&
                    p.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)
                rebind()
            }.onFailure {
                imageCapture = null
                status = CameraStatus.Failure("Tumble could not start the camera.")
            }
        }, mainExecutor)
    }

    fun retry() {
        owner?.let(::bind)
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
            imageCapture = null
            status = CameraStatus.Unavailable("The selected camera is unavailable.")
            return
        }
        val capture = ImageCapture.Builder()
            .setFlashMode(if (flashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF)
            .build()
        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
        analysis.setAnalyzer(previewExecutor) { image ->
            val renderer = previewRenderer
            if (renderer == null || !previewInProgress.compareAndSet(false, true)) {
                image.close()
            } else {
                val mirror = side == CameraSide.FRONT
                val frame = runCatching {
                    renderer(image.toBitmap().oriented(image.imageInfo.rotationDegrees, mirror))
                }.getOrNull()
                image.close()
                mainExecutor.execute {
                    filteredPreview = frame
                    previewInProgress.set(false)
                }
            }
        }
        try {
            p.unbindAll()
            val camera: Camera = p.bindToLifecycle(lifecycleOwner, selector, preview, capture, analysis)
            imageCapture = capture
            supportsFlash = side == CameraSide.BACK && camera.cameraInfo.hasFlashUnit()
            if (!supportsFlash) flashOn = false
            status = CameraStatus.Ready
        } catch (_: Exception) {
            imageCapture = null
            status = CameraStatus.Failure("Tumble could not connect to the camera.")
        }
    }

    fun switchCamera() {
        if (!canSwitch || !isReady || isCapturing) return
        side = if (side == CameraSide.BACK) CameraSide.FRONT else CameraSide.BACK
        rebind()
    }

    fun toggleFlash() {
        if (!supportsFlash || !isReady || isCapturing) return
        flashOn = !flashOn
        imageCapture?.flashMode =
            if (flashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF
    }

    /** Capture a still on the main thread, oriented upright. */
    fun capture(onResult: (CameraCaptureResult) -> Unit) {
        if (!captureInProgress.compareAndSet(false, true)) {
            onResult(CameraCaptureResult.Failure("A capture is already in progress."))
            return
        }
        val capture = imageCapture
        if (!isReady || capture == null) {
            captureInProgress.set(false)
            val reason = when (val current = status) {
                is CameraStatus.Unavailable -> current.reason
                is CameraStatus.Failure -> current.reason
                else -> "The camera is not ready yet."
            }
            onResult(CameraCaptureResult.Unavailable(reason))
            return
        }
        // Orient the still to the current display, like the preview.
        capture.targetRotation = previewView?.display?.rotation ?: Surface.ROTATION_0
        val mirror = side == CameraSide.FRONT
        capture.takePicture(
            mainExecutor,
            object : ImageCapture.OnImageCapturedCallback() {
                override fun onCaptureSuccess(image: ImageProxy) {
                    val result = runCatching {
                        image.toBitmap().oriented(image.imageInfo.rotationDegrees, mirror)
                    }
                    image.close()
                    captureInProgress.set(false)
                    result.fold(
                        onSuccess = { onResult(CameraCaptureResult.Success(it)) },
                        onFailure = {
                            onResult(CameraCaptureResult.Failure("The photo could not be decoded.", it))
                        },
                    )
                }

                override fun onError(exception: ImageCaptureException) {
                    captureInProgress.set(false)
                    onResult(CameraCaptureResult.Failure("The camera could not take that photo.", exception))
                }
            },
        )
    }

    /** Rotate to upright and mirror front-camera frames so selfies match iOS. */
    private fun Bitmap.oriented(degrees: Int, mirror: Boolean): Bitmap {
        if (degrees == 0 && !mirror) return this
        val matrix = Matrix().apply {
            if (degrees != 0) postRotate(degrees.toFloat())
            if (mirror) postScale(-1f, 1f)
        }
        return Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)
    }
}
