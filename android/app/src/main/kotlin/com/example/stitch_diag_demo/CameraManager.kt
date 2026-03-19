package com.example.stitch_diag_demo

import android.content.Context
import android.graphics.Bitmap
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
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

    fun startCamera() {
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            preview = Preview.Builder().build()

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

            val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

            try {
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
                    previewView.scaleX = -1f
                }
            } catch (exc: Exception) {
                // Handle error
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun stopCamera() {
        val cameraProvider = cameraProviderFuture.get()
        cameraProvider.unbindAll()
        imageCapture = null
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
        stopCamera()
        startCamera()
    }

    fun setMirrorPreview(enabled: Boolean) {
        lastPreviewView?.let { previewView ->
            previewView.scaleX = if (enabled) -1f else 1f
        }
    }

    fun setPreviewView(previewView: androidx.camera.view.PreviewView) {
        lastPreviewView = previewView
        preview?.setSurfaceProvider(previewView.surfaceProvider)
        previewView.scaleX = -1f
    }

    // For PlatformView
    fun attachPreview(previewView: androidx.camera.view.PreviewView) {
        setPreviewView(previewView)
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
        cameraManager.attachPreview(previewView)
    }

    override fun getView(): android.view.View = previewView

    override fun dispose() {
        // Cleaning up preview if needed
    }
}
