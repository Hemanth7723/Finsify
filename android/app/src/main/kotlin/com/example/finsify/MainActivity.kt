package com.example.finsify

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.example.finsify/file_download"
        const val METHOD_SAVE_TO_DOWNLOADS = "saveToDownloads"
        const val KEY_BYTES = "bytes"
        const val KEY_FILE_NAME = "fileName"
        const val KEY_MIME_TYPE = "mimeType"
        const val ERROR_UNSUPPORTED_ANDROID = "UNSUPPORTED_ANDROID_VERSION"
        const val ERROR_SAVE_FAILED = "SAVE_FAILED"
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != METHOD_SAVE_TO_DOWNLOADS) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bytes = call.argument<ByteArray>(KEY_BYTES)
            val fileName = call.argument<String>(KEY_FILE_NAME)
            val mimeType = call.argument<String>(KEY_MIME_TYPE)

            if (bytes == null || bytes.isEmpty()) {
                result.error(ERROR_SAVE_FAILED, "The XLSX data is empty.", null)
                return@setMethodCallHandler
            }

            if (fileName.isNullOrBlank()) {
                result.error(ERROR_SAVE_FAILED, "The file name is empty.", null)
                return@setMethodCallHandler
            }

            if (mimeType.isNullOrBlank()) {
                result.error(ERROR_SAVE_FAILED, "The MIME type is empty.", null)
                return@setMethodCallHandler
            }

            // MediaStore.Downloads was introduced in Android 10 / API 29.
            // The app currently targets modern Android, so use the scoped-storage
            // API instead of broad storage permissions.
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                result.error(
                    ERROR_UNSUPPORTED_ANDROID,
                    "Direct public Downloads saving requires Android 10 (API 29) or newer.",
                    null,
                )
                return@setMethodCallHandler
            }

            executor.execute {
                var uri: Uri? = null

                try {
                    val resolver = contentResolver
                    val values = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                        put(
                            MediaStore.MediaColumns.RELATIVE_PATH,
                            Environment.DIRECTORY_DOWNLOADS,
                        )
                        put(MediaStore.MediaColumns.IS_PENDING, 1)
                    }

                    uri = resolver.insert(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                        values,
                    )

                    if (uri == null) {
                        throw IllegalStateException(
                            "Android could not create the Downloads file.",
                        )
                    }

                    resolver.openOutputStream(uri!!).use { output ->
                        if (output == null) {
                            throw IllegalStateException(
                                "Android could not open the Downloads file for writing.",
                            )
                        }
                        output.write(bytes)
                        output.flush()
                    }

                    val publishValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.IS_PENDING, 0)
                    }
                    resolver.update(uri!!, publishValues, null, null)

                    mainHandler.post {
                        result.success(fileName)
                    }
                } catch (error: Exception) {
                    uri?.let {
                        runCatching { contentResolver.delete(it, null, null) }
                    }

                    mainHandler.post {
                        result.error(
                            ERROR_SAVE_FAILED,
                            error.message ?: "Unable to save the XLSX file to Downloads.",
                            null,
                        )
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}