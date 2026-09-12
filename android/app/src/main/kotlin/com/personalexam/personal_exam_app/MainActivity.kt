package com.personalexam.personal_exam_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "personal_exam/storage",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getFilesDirectory") {
                result.success(filesDir.absolutePath)
            } else {
                result.notImplemented()
            }
        }
    }
}
