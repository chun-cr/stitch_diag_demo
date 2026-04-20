package com.example.stitch_diag_demo

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FaceScanChannel(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var gestureEventSink: EventChannel.EventSink? = null
    private var tongueEventSink: EventChannel.EventSink? = null

    private val cameraManager = CameraManager(context)
    private var faceLandmarkerHelper: FaceLandmarkerHelper? = null
    private var gestureRecognizerHelper: GestureRecognizerHelper? = null

    companion object {
        private const val CHANNEL = "face/channel"
        private const val EVENTS = "face/landmarkStream"
        private const val GESTURE_EVENTS = "gesture/resultStream"
        private const val TONGUE_EVENTS = "tongue/detectionStream"
        private const val TONGUE_CAPTURE = "tongue/capture"

        private var instance: FaceScanChannel? = null

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channelInstance = FaceScanChannel(context)
            instance = channelInstance
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler(channelInstance)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
                .setStreamHandler(channelInstance)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURE_EVENTS)
                .setStreamHandler(channelInstance.gestureStreamHandler)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, TONGUE_EVENTS)
                .setStreamHandler(channelInstance.tongueStreamHandler)

            flutterEngine.platformViewsController.registry.registerViewFactory(
                "com.yourapp.face_scan/camera_preview",
                CameraPreviewViewFactory(channelInstance.cameraManager)
            )

            channelInstance.cameraManager.setListener { frame ->
                when (channelInstance.cameraManager.mode) {
                    "landmark" -> {
                        channelInstance.ensureFaceLandmarkerHelper().detect(frame) { result ->
                            channelInstance.sendFaceEvent(result)
                            channelInstance.sendTongueEvent(result)
                        }
                    }
                    "gesture" -> {
                        channelInstance.ensureGestureRecognizerHelper().detect(frame) { result ->
                            channelInstance.sendGestureEvent(result)
                        }
                    }
                }
            }
        }

        fun release() {
            instance?.dispose()
            instance = null
        }
    }

    private val gestureStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            gestureEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            gestureEventSink = null
        }
    }

    private val tongueStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            tongueEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            tongueEventSink = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "face/startDetection" -> {
                if (!cameraManager.hasCameraPermission()) {
                    result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                    return
                }
                cameraManager.mode = "landmark"
                cameraManager.startCamera()
                result.success(null)
            }
            "face/stopDetection" -> {
                cameraManager.mode = "none"
                cameraManager.stopCamera()
                result.success(null)
            }
            "face/toggleCamera" -> {
                cameraManager.toggleCamera()
                result.success(null)
            }
            "gesture/startDetection" -> {
                if (!cameraManager.hasCameraPermission()) {
                    result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                    return
                }
                cameraManager.mode = "gesture"
                cameraManager.startCamera()
                result.success(null)
            }
            "tongue/startDetection" -> {
                if (!cameraManager.hasCameraPermission()) {
                    result.error("PERMISSION_DENIED", "Camera permission not granted", null)
                    return
                }
                cameraManager.mode = "landmark"
                cameraManager.startCamera()
                result.success(null)
            }
            "gesture/stopDetection" -> {
                cameraManager.mode = "none"
                cameraManager.stopCamera()
                result.success(null)
            }
            "tongue/stopDetection" -> {
                cameraManager.mode = "none"
                cameraManager.stopCamera()
                sendTongueEvent(
                    mapOf(
                        "blendshapes" to emptyMap<String, Double>(),
                        "mouthLandmarks" to emptyList<Map<String, Double>>(),
                        "faceLandmarks" to emptyList<Map<String, Double>>(),
                        "landmarks" to emptyList<Map<String, Double>>(),
                        "imageWidth" to 0,
                        "imageHeight" to 0,
                        "mouthCenter" to null,
                    )
                )
                result.success(null)
            }
            "scan/capture" -> {
                val stage = call.argument<String>("stage")
                val guideRect = call.argument<Map<String, Any?>>("guideRect")

                if (stage.isNullOrBlank()) {
                    result.error("INVALID_STAGE", "Missing capture stage", null)
                    return
                }

                val normalizedRect = parseNormalizedRect(guideRect)
                if (normalizedRect == null) {
                    result.error("INVALID_GUIDE_RECT", "Missing or invalid guideRect", guideRect)
                    return
                }

                cameraManager.captureVisibleRegion(
                    stage = stage,
                    normalizedRect = normalizedRect,
                    onSuccess = { payload ->
                        (context as? MainActivity)?.runOnUiThread {
                            result.success(payload)
                        }
                    },
                    onError = { error ->
                        (context as? MainActivity)?.runOnUiThread {
                            result.error("CAPTURE_FAILED", error, guideRect)
                        }
                    },
                )
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun sendFaceEvent(data: Map<String, Any?>) {
        (context as? MainActivity)?.runOnUiThread {
            eventSink?.success(data)
        }
    }

    private fun sendGestureEvent(data: Map<String, Any?>) {
        (context as? MainActivity)?.runOnUiThread {
            gestureEventSink?.success(data)
        }
    }

    private fun sendTongueEvent(data: Map<String, Any?>) {
        val blendshapePayload = (data["blendshapes"] as? Map<*, *>)
            ?.mapNotNull { (key, value) ->
                val name = key as? String
                val score = (value as? Number)?.toDouble()
                if (name != null && score != null) {
                    name to score
                } else {
                    null
                }
            }
            ?.toMap()
            ?: emptyMap<String, Double>()
        val tonguePayload = mapOf(
            "blendshapes" to blendshapePayload,
            "mouthLandmarks" to (data["mouthLandmarks"] as? List<*> ?: emptyList<Any>()),
            "faceLandmarks" to (data["faceLandmarks"] as? List<*> ?: data["landmarks"] as? List<*> ?: emptyList<Any>()),
            "landmarks" to (data["faceLandmarks"] as? List<*> ?: data["landmarks"] as? List<*> ?: emptyList<Any>()),
            "imageWidth" to ((data["imageWidth"] as? Number)?.toDouble() ?: 0.0),
            "imageHeight" to ((data["imageHeight"] as? Number)?.toDouble() ?: 0.0),
            "mouthCenter" to data["mouthCenter"],
        )

        (context as? MainActivity)?.runOnUiThread {
            tongueEventSink?.success(tonguePayload)
        }
    }

    private fun ensureFaceLandmarkerHelper(): FaceLandmarkerHelper {
        val existing = faceLandmarkerHelper
        if (existing != null) {
            return existing
        }

        return FaceLandmarkerHelper(context).also {
            faceLandmarkerHelper = it
        }
    }

    private fun ensureGestureRecognizerHelper(): GestureRecognizerHelper {
        val existing = gestureRecognizerHelper
        if (existing != null) {
            return existing
        }

        return GestureRecognizerHelper(context).also {
            gestureRecognizerHelper = it
        }
    }

    private fun dispose() {
        cameraManager.stopCamera()
        faceLandmarkerHelper?.close()
        faceLandmarkerHelper = null
        gestureRecognizerHelper?.close()
        gestureRecognizerHelper = null
        eventSink = null
        gestureEventSink = null
        tongueEventSink = null
    }

    private fun parseNormalizedRect(raw: Map<String, Any?>?): RectFCompat? {
        if (raw == null) {
            return null
        }

        fun readDouble(key: String): Double? {
            val value = raw[key]
            return when (value) {
                is Number -> value.toDouble()
                else -> null
            }
        }

        val left = readDouble("left") ?: return null
        val top = readDouble("top") ?: return null
        val width = readDouble("width") ?: return null
        val height = readDouble("height") ?: return null

        if (width <= 0 || height <= 0) {
            return null
        }

        return RectFCompat(
            left = left,
            top = top,
            width = width,
            height = height,
        )
    }
}
