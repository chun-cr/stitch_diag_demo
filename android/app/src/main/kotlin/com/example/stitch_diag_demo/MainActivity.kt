package com.example.stitch_diag_demo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val APP_INFO_CHANNEL = "app/info"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FaceScanChannel.registerWith(flutterEngine, this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_INFO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppId" -> result.success(applicationContext.packageName)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        FaceScanChannel.release()
        super.onDestroy()
    }
}
