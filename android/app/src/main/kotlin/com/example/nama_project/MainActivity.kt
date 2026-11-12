package com.example.nama_project

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "findit/device_image_picker"
    private val imageRequestCode = 4931
    private var pendingImageResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "pickImage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingImageResult != null) {
                    result.error("picker_busy", "Pemilih foto sedang digunakan.", null)
                    return@setMethodCallHandler
                }

                pendingImageResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "image/*"
                }
                try {
                    startActivityForResult(intent, imageRequestCode)
                } catch (error: Exception) {
                    pendingImageResult = null
                    result.error("picker_failed", error.message, null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != imageRequestCode) return

        val result = pendingImageResult ?: return
        pendingImageResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.success(null)
            return
        }

        try {
            val imageBytes = contentResolver.openInputStream(data.data!!)?.use {
                it.readBytes()
            }
            if (imageBytes == null) {
                result.error("image_unavailable", "Foto tidak dapat dibaca.", null)
            } else {
                result.success(imageBytes)
            }
        } catch (error: Exception) {
            result.error("image_read_failed", error.message, null)
        }
    }
}
