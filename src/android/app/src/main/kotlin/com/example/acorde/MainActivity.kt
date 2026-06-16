package com.example.acorde

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val WAKELOCK_CHANNEL = "com.example.acorde/wakelock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WAKELOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                }
                "disable" -> {
                    activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
