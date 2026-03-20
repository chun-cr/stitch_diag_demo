package com.example.stitch_diag_demo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FaceScanChannel.registerWith(flutterEngine, this)
    }

    override fun onDestroy() {
        FaceScanChannel.release()
        super.onDestroy()
    }
}
