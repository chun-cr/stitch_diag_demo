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
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerOptions

class FaceLandmarkerHelper(private val context: Context) {
    private var landmarker: FaceLandmarker? = null
    private var resultCallback: ((Map<String, Any?>) -> Unit)? = null

    init {
        setupLandmarker()
    }

    private fun setupLandmarker() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("face_landmarker.task")
            .setDelegate(Delegate.GPU)

        val optionsBuilder = FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptionsBuilder.build())
            .setMinFaceDetectionConfidence(0.7f)
            .setMinFacePresenceConfidence(0.7f)
            .setMinTrackingConfidence(0.7f)
            .setNumFaces(1)
            .setOutputFaceBlendshapes(true)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setResultListener { result, _ ->
                val firstFaceLandmarks = result.faceLandmarks().firstOrNull()
                val landmarks = firstFaceLandmarks?.map { landmark ->
                    mapOf(
                        "x" to landmark.x(),
                        "y" to landmark.y(),
                        "z" to landmark.z(),
                    )
                } ?: emptyList<Map<String, Float>>()

                val blendshapes = result.faceBlendshapes().firstOrNull()?.categories()?.associate { category ->
                    category.categoryName() to category.score().toDouble()
                } ?: emptyMap()

                val tongueData = TongueDetectionUtils.evaluateTongue(firstFaceLandmarks, blendshapes)

                resultCallback?.invoke(
                    mapOf(
                        "detected" to firstFaceLandmarks.isNullOrEmpty().not(),
                        "landmarks" to landmarks,
                        "blendshapes" to blendshapes,
                        "imageWidth" to result.inputImageWidth(),
                        "imageHeight" to result.inputImageHeight(),
                        "tongueDetected" to tongueData.tongueDetected,
                        "tongueOutScore" to tongueData.tongueOutScore,
                        "mouthLandmarks" to tongueData.mouthLandmarks,
                    )
                )
            }

        landmarker = FaceLandmarker.createFromOptions(context, optionsBuilder.build())
    }

    fun detect(imageProxy: ImageProxy, callback: (Map<String, Any?>) -> Unit) {
        resultCallback = callback
        val bitmap = imageProxy.toBitmap()
        val matrix = Matrix().apply { postRotate(imageProxy.imageInfo.rotationDegrees.toFloat()) }
        val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        landmarker?.detectAsync(mpImage, System.currentTimeMillis())
    }

    fun close() {
        landmarker?.close()
        landmarker = null
    }
}
