package com.example.stitch_diag_demo

import com.google.mediapipe.tasks.components.containers.NormalizedLandmark

object TongueDetectionUtils {
    private val mouthIndices = listOf(13, 14, 17, 37, 267, 269, 270, 291)

    data class TongueResult(
        val mouthLandmarks: List<Map<String, Double>>,
        val mouthCenter: Map<String, Double>?,
    )

    fun evaluateTongue(
        landmarks: List<NormalizedLandmark>?,
    ): TongueResult {
        if (landmarks.isNullOrEmpty()) {
            return TongueResult(emptyList(), null)
        }

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
            mouthLandmarks = mouthLandmarks,
            mouthCenter = center,
        )
    }
}
