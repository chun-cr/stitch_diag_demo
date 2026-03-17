package com.example.stitch_diag_demo

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FaceScanChannel(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    
    private val cameraManager = CameraManager(context)
    private val faceDetectionHelper = FaceDetectionHelper(context)
    private val faceLandmarkerHelper = FaceLandmarkerHelper(context)

    companion object {
        private const val CHANNEL = "com.yourapp.face_scan/channel"
        private const val EVENTS = "com.yourapp.face_scan/events"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val instance = FaceScanChannel(context)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(instance)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS).setStreamHandler(instance)

            // Register Camera View
            flutterEngine.platformViewsController.registry.registerViewFactory(
                "com.yourapp.face_scan/camera_preview",
                CameraPreviewViewFactory(instance.cameraManager)
            )
            
            // Link helpers
            instance.cameraManager.setListener { frame ->
                if (instance.cameraManager.mode == "detection") {
                    instance.faceDetectionHelper.detect(frame) { result ->
                        instance.sendEvent(result.apply { put("type", "detection") })
                    }
                } else if (instance.cameraManager.mode == "landmark") {
                    instance.faceLandmarkerHelper.detect(frame) { result ->
                        instance.sendEvent(result.apply { put("type", "landmark") })
                    }
                }
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startCamera" -> {
                cameraManager.startCamera()
                result.success(null)
            }
            "stopCamera" -> {
                cameraManager.stopCamera()
                result.success(null)
            }
            "startDetection" -> {
                val mode = call.argument<String>("mode")
                cameraManager.mode = mode ?: "none"
                result.success(null)
            }
            "stopDetection" -> {
                cameraManager.mode = "none"
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    private fun sendEvent(data: Map<String, Any?>) {
        (context as? MainActivity)?.runOnUiThread {
            eventSink?.success(data)
        }
    }
}
