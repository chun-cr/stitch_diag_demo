package com.example.stitch_diag_demo

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facedetector.FaceDetector
import com.google.mediapipe.tasks.vision.facedetector.FaceDetectorOptions
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerOptions

class FaceDetectionHelper(private val context: Context) {
    private var detector: FaceDetector? = null

    init {
        setupDetector()
    }

    private fun setupDetector() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("face_detection_short_range.tflite")
            .setDelegate(Delegate.GPU)

        val optionsBuilder = FaceDetectorOptions.builder()
            .setBaseOptions(baseOptionsBuilder.build())
            .setMinDetectionConfidence(0.7f)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setResultListener { result, _ ->
                // Handled in callback
            }
            
        detector = FaceDetector.createFromOptions(context, optionsBuilder.build())
    }

    fun detect(imageProxy: ImageProxy, callback: (Map<String, Any?>) -> Unit) {
        val bitmap = imageProxy.toBitmap()
        // MediaPipe needs orientation-corrected bitmap
        val matrix = Matrix().apply { postRotate(imageProxy.imageInfo.rotationDegrees.toFloat()) }
        val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        
        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        detector?.detectAsync(mpImage, System.currentTimeMillis())
        // For simplicity, returning first result detected in result listener would be better approach.
        // Assuming listener is set up to pipe events back to Flutter.
    }
}
