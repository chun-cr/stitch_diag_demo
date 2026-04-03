package com.example.stitch_diag_demo

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import kotlin.math.abs

object TongueDetectionUtils {
    private val mouthIndices = listOf(13, 14, 17, 37, 267, 269, 270, 291)
    private const val TONGUE_THRESHOLD = 0.35
    private const val UPPER_LIP_INNER = 13
    private const val LOWER_LIP_INNER = 14

    data class TongueResult(
        val tongueDetected: Boolean,
        val tongueOutScore: Double,
        val mouthLandmarks: List<Map<String, Double>>,
        val mouthCenter: Map<String, Double>?,
    )

    fun evaluateTongue(
        landmarks: List<NormalizedLandmark>?,
        blendshapes: Map<String, Double>,
    ): TongueResult {
        if (landmarks.isNullOrEmpty()) {
            return TongueResult(false, 0.0, emptyList(), null)
        }

        val tongueOutScore = blendshapes["tongueOut"] ?: 0.0
        val upperLip = landmarks.getOrNull(UPPER_LIP_INNER)
        val lowerLip = landmarks.getOrNull(LOWER_LIP_INNER)
        val mouthOpenRatio = if (upperLip != null && lowerLip != null) {
            abs(lowerLip.y() - upperLip.y()).toDouble()
        } else {
            0.0
        }

        val detected = tongueOutScore >= TONGUE_THRESHOLD || mouthOpenRatio >= 0.06

        val mouthLandmarks = mouthIndices.mapNotNull { index ->
            landmarks.getOrNull(index)?.let { landmark ->
                mapOf(
                    "x" to landmark.x().toDouble(),
                    "y" to landmark.y().toDouble(),
                    "z" to landmark.z().toDouble(),
                )
            }
        }

        val center = mouthLandmarks.takeIf { it.isNotEmpty() }?.let { points ->
            val avgX = points.map { it["x"] ?: 0.0 }.average()
            val avgY = points.map { it["y"] ?: 0.0 }.average()
            val avgZ = points.map { it["z"] ?: 0.0 }.average()
            mapOf("x" to avgX, "y" to avgY, "z" to avgZ)
        }

        return TongueResult(
            tongueDetected = detected,
            tongueOutScore = tongueOutScore,
            mouthLandmarks = mouthLandmarks,
            mouthCenter = center,
        )
    }
}
