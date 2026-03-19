package com.example.stitch_diag_demo

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizer
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizerOptions
import kotlin.math.acos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

class GestureRecognizerHelper(private val context: Context) {
    private var recognizer: GestureRecognizer? = null
    private var resultCallback: ((Map<String, Any?>) -> Unit)? = null

    private var lastGestureName: String? = null
    private var consecutiveCount = 0

    init {
        setupRecognizer()
    }

    private fun setupRecognizer() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("gesture_recognizer.task")
            .setDelegate(Delegate.GPU)

        val options = GestureRecognizerOptions.builder()
            .setBaseOptions(baseOptionsBuilder.build())
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumHands(2)
            .setResultListener { result, _ ->
                val gesture = result.gestures().firstOrNull()?.firstOrNull()
                val gestureName = gesture?.categoryName() ?: ""
                val score = gesture?.score()?.toDouble() ?: 0.0

                val landmarks = result.handLandmarks().firstOrNull()?.map { lm ->
                    mapOf("x" to lm.x(), "y" to lm.y(), "z" to lm.z())
                } ?: emptyList<Map<String, Float>>()

                val detectedByModel = gestureName == "Open_Palm" && score >= 0.75
                val detectedByFallback = if (!detectedByModel) {
                    isOpenPalmByLandmarks(result.handLandmarks().firstOrNull())
                } else {
                    false
                }

                val detected = detectedByModel || detectedByFallback
                val finalName = if (detected) "Open_Palm" else gestureName
                val finalScore = if (detectedByModel) score else if (detectedByFallback) 0.75 else score

                val debouncedDetected = debounce(finalName, detected)

                resultCallback?.invoke(
                    mapOf(
                        "gestureDetected" to debouncedDetected,
                        "gestureName" to finalName,
                        "score" to finalScore,
                        "handLandmarks" to landmarks,
                    )
                )
            }

        recognizer = GestureRecognizer.createFromOptions(context, options.build())
    }

    fun detect(imageProxy: ImageProxy, callback: (Map<String, Any?>) -> Unit) {
        resultCallback = callback
        val bitmap = imageProxy.toBitmap()
        val matrix = Matrix().apply { postRotate(imageProxy.imageInfo.rotationDegrees.toFloat()) }
        val rotatedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        recognizer?.recognizeAsync(mpImage, System.currentTimeMillis())
    }

    private fun debounce(gestureName: String, detected: Boolean): Boolean {
        if (!detected) {
            lastGestureName = null
            consecutiveCount = 0
            return false
        }

        if (gestureName == lastGestureName) {
            consecutiveCount += 1
        } else {
            lastGestureName = gestureName
            consecutiveCount = 1
        }

        return consecutiveCount >= 3
    }

    private fun isOpenPalmByLandmarks(landmarks: List<com.google.mediapipe.tasks.components.containers.NormalizedLandmark>?): Boolean {
        if (landmarks == null || landmarks.size < 21) return false

        val thumb = isFingerExtended(landmarks, 1, 2, 3, 4)
        val index = isFingerExtended(landmarks, 5, 6, 7, 8)
        val middle = isFingerExtended(landmarks, 9, 10, 11, 12)
        val ring = isFingerExtended(landmarks, 13, 14, 15, 16)
        val pinky = isFingerExtended(landmarks, 17, 18, 19, 20)

        return thumb && index && middle && ring && pinky
    }

    private fun isFingerExtended(
        landmarks: List<com.google.mediapipe.tasks.components.containers.NormalizedLandmark>,
        mcp: Int,
        pip: Int,
        dip: Int,
        tip: Int,
    ): Boolean {
        val angle = angleBetween(
            landmarks[mcp],
            landmarks[pip],
            landmarks[dip],
            landmarks[tip],
        )
        return angle > 160
    }

    private fun angleBetween(
        a: com.google.mediapipe.tasks.components.containers.NormalizedLandmark,
        b: com.google.mediapipe.tasks.components.containers.NormalizedLandmark,
        c: com.google.mediapipe.tasks.components.containers.NormalizedLandmark,
        d: com.google.mediapipe.tasks.components.containers.NormalizedLandmark,
    ): Double {
        val v1 = floatArrayOf(a.x() - b.x(), a.y() - b.y(), a.z() - b.z())
        val v2 = floatArrayOf(c.x() - b.x(), c.y() - b.y(), c.z() - b.z())
        val v3 = floatArrayOf(d.x() - c.x(), d.y() - c.y(), d.z() - c.z())

        val angle1 = vectorAngle(v1, v2)
        val angle2 = vectorAngle(v2, v3)
        return (angle1 + angle2) / 2
    }

    private fun vectorAngle(v1: FloatArray, v2: FloatArray): Double {
        val dot = (v1[0] * v2[0]) + (v1[1] * v2[1]) + (v1[2] * v2[2])
        val mag1 = sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2])
        val mag2 = sqrt(v2[0] * v2[0] + v2[1] * v2[1] + v2[2] * v2[2])
        val denom = max(1e-6, (mag1 * mag2).toDouble())
        val cos = min(1.0, max(-1.0, dot / denom))
        return Math.toDegrees(acos(cos))
    }

    fun close() {
        recognizer?.close()
        recognizer = null
    }
}

