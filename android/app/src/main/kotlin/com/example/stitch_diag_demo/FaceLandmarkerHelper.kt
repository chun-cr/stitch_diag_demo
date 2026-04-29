package com.example.stitch_diag_demo

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.components.containers.Category
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult

class FaceLandmarkerHelper(private val context: Context) {
    companion object {
        private const val TAG = "FaceLandmarkerHelper"
        private const val MIN_DETECTION_CONFIDENCE = 0.5f
        private const val MIN_PRESENCE_CONFIDENCE = 0.5f
        private const val MIN_TRACKING_CONFIDENCE = 0.5f
    }

    private var landmarker: FaceLandmarker? = null
    private var resultCallback: ((Map<String, Any?>) -> Unit)? = null
    private var currentImageWidth: Int = 0
    private var currentImageHeight: Int = 0

    init {
        setupLandmarker()
    }

    private fun setupLandmarker() {
        landmarker = createLandmarker(Delegate.GPU)
            ?: createLandmarker(Delegate.CPU)
            ?: run {
                Log.e(TAG, "Unable to initialize face landmarker with either GPU or CPU delegate.")
                null
            }
    }

    private fun createLandmarker(delegate: Delegate): FaceLandmarker? {
        return try {
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath("face_landmarker.task")
                .setDelegate(delegate)

            val optionsBuilder = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(baseOptionsBuilder.build())
                .setMinFaceDetectionConfidence(MIN_DETECTION_CONFIDENCE)
                .setMinFacePresenceConfidence(MIN_PRESENCE_CONFIDENCE)
                .setMinTrackingConfidence(MIN_TRACKING_CONFIDENCE)
                .setNumFaces(1)
                .setOutputFaceBlendshapes(true)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setResultListener { result: FaceLandmarkerResult, _: MPImage ->
                    val firstFaceLandmarks = result.faceLandmarks().firstOrNull()
                    val landmarks = firstFaceLandmarks?.map { landmark: NormalizedLandmark ->
                        mapOf(
                            "x" to landmark.x().toDouble(),
                            "y" to landmark.y().toDouble(),
                            "z" to landmark.z().toDouble(),
                        )
                    } ?: emptyList<Map<String, Double>>()

                    val blendshapes = if (result.faceBlendshapes().isPresent) {
                        val categories: List<Category>? = result.faceBlendshapes().get().firstOrNull()
                        categories?.associate { category: Category ->
                            category.categoryName() to category.score().toDouble()
                        } ?: emptyMap<String, Double>()
                    } else {
                        emptyMap<String, Double>()
                    }

                    val tongueData = TongueDetectionUtils.evaluateTongue(firstFaceLandmarks)

                    resultCallback?.invoke(
                        mapOf(
                            "detected" to !firstFaceLandmarks.isNullOrEmpty(),
                            "landmarks" to landmarks,
                            "blendshapes" to blendshapes,
                            "imageWidth" to currentImageWidth,
                            "imageHeight" to currentImageHeight,
                            "mouthLandmarks" to tongueData.mouthLandmarks,
                            "mouthCenter" to tongueData.mouthCenter,
                        )
                    )
                }

            Log.i(TAG, "Initializing face landmarker with $delegate delegate.")
            FaceLandmarker.createFromOptions(context, optionsBuilder.build())
        } catch (error: Exception) {
            Log.w(TAG, "Face landmarker init failed with $delegate delegate.", error)
            null
        }
    }

    fun detect(imageProxy: ImageProxy, callback: (Map<String, Any?>) -> Unit) {
        resultCallback = callback
        if (landmarker == null) {
            callback(
                mapOf(
                    "detected" to false,
                    "landmarks" to emptyList<Map<String, Double>>(),
                    "blendshapes" to emptyMap<String, Double>(),
                    "imageWidth" to 0,
                    "imageHeight" to 0,
                    "mouthLandmarks" to emptyList<Map<String, Double>>(),
                    "mouthCenter" to null,
                )
            )
            return
        }

        val bitmap = imageProxy.toBitmap()
        val matrix = Matrix().apply {
            postRotate(imageProxy.imageInfo.rotationDegrees.toFloat())
        }
        val rotatedBitmap = Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true,
        )

        currentImageWidth = rotatedBitmap.width
        currentImageHeight = rotatedBitmap.height

        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        landmarker?.detectAsync(mpImage, System.currentTimeMillis())
    }

    fun close() {
        landmarker?.close()
        landmarker = null
    }
}
