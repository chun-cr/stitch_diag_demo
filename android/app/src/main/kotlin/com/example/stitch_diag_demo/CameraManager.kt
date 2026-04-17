package com.example.stitch_diag_demo

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Rect
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class CameraManager(private val context: Context) {
    var mode: String = "none"
    private var cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    private var analysisUseCase: ImageAnalysis? = null
    private var preview: Preview? = null
    private var imageCapture: ImageCapture? = null
    private var listener: ((ImageProxy) -> Unit)? = null
    private var lastPreviewView: androidx.camera.view.PreviewView? = null

    // Executor for image processing
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

    fun hasCameraPermission(): Boolean {
        return androidx.core.content.ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.CAMERA
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    fun setListener(l: (ImageProxy) -> Unit) {
        this.listener = l
    }

    private var currentSelector: CameraSelector? = null

    private var isCameraToggled = false

    fun toggleCamera() {
        isCameraToggled = !isCameraToggled
        restartCamera()
    }

    private fun applyPreviewTransform() {
        // CameraX PreviewView automatically handles mirroring for the front camera.
        lastPreviewView?.scaleX = 1f
    }

    fun startCamera() {
        cameraProviderFuture.addListener({
            try {
                val cameraProvider = cameraProviderFuture.get()

                val cameraSelector = if (mode == "gesture") {
                    if (isCameraToggled) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
                } else {
                    if (isCameraToggled) CameraSelector.DEFAULT_BACK_CAMERA else CameraSelector.DEFAULT_FRONT_CAMERA
                }

                // 核心：防止重复绑定导致抖动。
                if (currentSelector == cameraSelector && preview != null && cameraProvider.isBound(preview!!)) {
                    android.util.Log.d("CameraManager", "Camera already bound, skipping to prevent jitter.")
                    applyPreviewTransform()
                    return@addListener
                }

                currentSelector = cameraSelector

                preview = Preview.Builder()
                    .setTargetResolution(android.util.Size(1280, 720))
                    .build()

                analysisUseCase = ImageAnalysis.Builder()
                    .setTargetResolution(android.util.Size(640, 480))
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()

                imageCapture = ImageCapture.Builder()
                    .setTargetResolution(android.util.Size(1280, 720))
                    .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                    .build()

                analysisUseCase?.setAnalyzer(backgroundExecutor) { imageProxy ->
                    listener?.invoke(imageProxy)
                    imageProxy.close()
                }

                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(
                    context as androidx.lifecycle.LifecycleOwner,
                    cameraSelector,
                    preview,
                    analysisUseCase,
                    imageCapture
                )
                
                lastPreviewView?.let { previewView ->
                    preview?.setSurfaceProvider(previewView.surfaceProvider)
                    applyPreviewTransform()
                }
            } catch (exc: Exception) {
                android.util.Log.e("CameraManager", "Start camera failed", exc)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun stopCamera(resetToggle: Boolean = true) {
        try {
            val cameraProvider = cameraProviderFuture.get()
            cameraProvider.unbindAll()
            imageCapture = null
            currentSelector = null
            if (resetToggle) {
                isCameraToggled = false
            }
        } catch (exc: Exception) {}
    }

    fun takePhoto(outputFile: java.io.File, onSuccess: (String) -> Unit, onError: (String) -> Unit) {
        val capture = imageCapture ?: run {
            onError("ImageCapture not ready")
            return
        }

        val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()
        capture.takePicture(
            outputOptions,
            backgroundExecutor,
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                    onSuccess(outputFile.absolutePath)
                }

                override fun onError(exception: ImageCaptureException) {
                    onError(exception.message ?: "Capture failed")
                }
            }
        )
    }

    fun restartCamera() {
        stopCamera(resetToggle = false)
        startCamera()
    }

    fun setMirrorPreview(enabled: Boolean) {
        lastPreviewView?.let { previewView ->
            previewView.scaleX = if (enabled) -1f else 1f
        }
    }

    fun captureVisibleRegion(
        stage: String,
        normalizedRect: RectFCompat,
        onSuccess: (Map<String, Any>) -> Unit,
        onError: (String) -> Unit,
    ) {
        val previewView = lastPreviewView ?: run {
            onError("PreviewView not ready")
            return
        }

        previewView.post {
            val previewBitmap = previewView.bitmap
            if (previewBitmap == null) {
                onError("Preview bitmap unavailable")
                return@post
            }

            backgroundExecutor.execute {
                try {
                    val cropRect = normalizedRect.toPixelRect(
                        width = previewBitmap.width,
                        height = previewBitmap.height,
                    )
                    val croppedBitmap = Bitmap.createBitmap(
                        previewBitmap,
                        cropRect.left,
                        cropRect.top,
                        cropRect.width(),
                        cropRect.height(),
                    )

                    val timestamp = System.currentTimeMillis()
                    val sourceFile = File(context.cacheDir, "${stage}_source_$timestamp.jpg")
                    val cropFile = File(context.cacheDir, "${stage}_crop_$timestamp.jpg")

                    saveBitmap(previewBitmap, sourceFile)
                    saveBitmap(croppedBitmap, cropFile)

                    onSuccess(
                        mapOf(
                            "stage" to stage,
                            "sourcePath" to sourceFile.absolutePath,
                            "croppedPath" to cropFile.absolutePath,
                            "framePath" to cropFile.absolutePath,
                            "sourceWidth" to previewBitmap.width.toDouble(),
                            "sourceHeight" to previewBitmap.height.toDouble(),
                            "cropLeft" to cropRect.left.toDouble(),
                            "cropTop" to cropRect.top.toDouble(),
                            "cropWidth" to cropRect.width().toDouble(),
                            "cropHeight" to cropRect.height().toDouble(),
                        )
                    )
                } catch (error: Exception) {
                    onError(error.message ?: "Visible region capture failed")
                }
            }
        }
    }

    fun setPreviewView(previewView: androidx.camera.view.PreviewView) {
        lastPreviewView = previewView
        preview?.setSurfaceProvider(previewView.surfaceProvider)
        applyPreviewTransform()
    }

    // For PlatformView
    fun attachPreview(previewView: androidx.camera.view.PreviewView) {
        setPreviewView(previewView)
    }

    private fun saveBitmap(bitmap: Bitmap, file: File) {
        FileOutputStream(file).use { output ->
            if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 92, output)) {
                throw IllegalStateException("Failed to write bitmap to ${file.absolutePath}")
            }
            output.flush()
        }
    }
}

data class RectFCompat(
    val left: Double,
    val top: Double,
    val width: Double,
    val height: Double,
) {
    fun toPixelRect(width: Int, height: Int): Rect {
        val safeLeft = (left.coerceIn(0.0, 1.0) * width).toInt()
        val safeTop = (top.coerceIn(0.0, 1.0) * height).toInt()
        val safeRight = ((left + this.width).coerceIn(0.0, 1.0) * width).toInt()
        val safeBottom = ((top + this.height).coerceIn(0.0, 1.0) * height).toInt()

        val rect = Rect(
            safeLeft.coerceIn(0, width - 1),
            safeTop.coerceIn(0, height - 1),
            safeRight.coerceIn(1, width),
            safeBottom.coerceIn(1, height),
        )

        if (rect.width() <= 0 || rect.height() <= 0) {
            throw IllegalArgumentException("Invalid crop rect from normalized guide: $this")
        }

        return rect
    }
}

class CameraPreviewViewFactory(private val cameraManager: CameraManager) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return CameraPreviewView(context, cameraManager)
    }
}

class CameraPreviewView(context: Context, private val cameraManager: CameraManager) : PlatformView {
    private val previewView = androidx.camera.view.PreviewView(context)

    init {
        // 使用 TextureView 兼容模式，避免 SurfaceView 把 Flutter UI 覆盖导致叠层不可见。
        previewView.implementationMode = androidx.camera.view.PreviewView.ImplementationMode.COMPATIBLE
        cameraManager.attachPreview(previewView)
    }

    override fun getView(): android.view.View = previewView

    override fun dispose() {
        // Cleaning up preview if needed
    }
}
