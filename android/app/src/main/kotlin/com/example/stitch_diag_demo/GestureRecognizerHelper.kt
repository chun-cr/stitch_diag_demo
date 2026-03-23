package com.example.stitch_diag_demo

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizer
import com.google.mediapipe.tasks.vision.gesturerecognizer.GestureRecognizerResult
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

        val options = GestureRecognizer.GestureRecognizerOptions.builder()
            .setBaseOptions(baseOptionsBuilder.build())
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumHands(2)
            .setResultListener { result: GestureRecognizerResult, _: MPImage ->
                val gesture = result.gestures().firstOrNull()?.firstOrNull()
                val gestureName = gesture?.categoryName() ?: ""
                val score = gesture?.score()?.toDouble() ?: 0.0
                val normalizedGestureName = normalizeGestureName(gestureName)

                val handLandmarks = result.landmarks().firstOrNull()
                val landmarks = handLandmarks?.map { lm: NormalizedLandmark ->
                    mapOf("x" to lm.x().toDouble(), "y" to lm.y().toDouble(), "z" to lm.z().toDouble())
                } ?: emptyList<Map<String, Double>>()

                val detectedByModel = normalizedGestureName == "OPENPALM" && score >= 0.75
                val detectedByFallback = if (!detectedByModel) {
                    isOpenPalmByLandmarks(handLandmarks)
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
                        "imageWidth" to mpImage.width.toDouble(),
                        "imageHeight" to mpImage.height.toDouble()
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

    private fun isOpenPalmByLandmarks(landmarks: List<NormalizedLandmark>?): Boolean {
        if (landmarks == null || landmarks.size < 21) return false

        val thumb = isThumbExtended(landmarks)
        val index = isFingerExtended(landmarks, 5, 6, 7, 8)
        val middle = isFingerExtended(landmarks, 9, 10, 11, 12)
        val ring = isFingerExtended(landmarks, 13, 14, 15, 16)
        val pinky = isFingerExtended(landmarks, 17, 18, 19, 20)

        return thumb && index && middle && ring && pinky
    }

    private fun isThumbExtended(landmarks: List<NormalizedLandmark>): Boolean {
        val thumbAngle = angleBetween(
            landmarks[1],
            landmarks[2],
            landmarks[3],
            landmarks[4],
        )

        val tipToIndexMcp = distance(landmarks[4], landmarks[5])
        val ipToIndexMcp = distance(landmarks[3], landmarks[5])
        val tipToWrist = distance(landmarks[4], landmarks[0])
        val mcpToWrist = distance(landmarks[2], landmarks[0])

        return thumbAngle > 135 &&
            tipToIndexMcp > ipToIndexMcp * 1.08 &&
            tipToWrist > mcpToWrist * 1.1
    }

    private fun isFingerExtended(
        landmarks: List<NormalizedLandmark>,
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
        a: NormalizedLandmark,
        b: NormalizedLandmark,
        c: NormalizedLandmark,
        d: NormalizedLandmark,
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

    private fun distance(a: NormalizedLandmark, b: NormalizedLandmark): Double {
        val dx = (a.x() - b.x()).toDouble()
        val dy = (a.y() - b.y()).toDouble()
        val dz = (a.z() - b.z()).toDouble()
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    private fun normalizeGestureName(name: String): String {
        return name.uppercase().replace(Regex("[^A-Z]"), "")
    }

    fun close() {
        recognizer?.close()
        recognizer = null
    }
}
