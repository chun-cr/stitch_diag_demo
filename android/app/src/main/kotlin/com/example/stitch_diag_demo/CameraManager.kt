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
    private var listener: ((ImageProxy) -> Unit)? = null
    
    // Executor for image processing
    private val backgroundExecutor = Executors.newSingleThreadExecutor()

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
                    analysisUseCase
                )
            } catch (exc: Exception) {
                // Handle error
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun stopCamera() {
        val cameraProvider = cameraProviderFuture.get()
        cameraProvider.unbindAll()
    }

    // For PlatformView
    fun attachPreview(previewView: androidx.camera.view.PreviewView) {
        preview?.setSurfaceProvider(previewView.surfaceProvider)
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
