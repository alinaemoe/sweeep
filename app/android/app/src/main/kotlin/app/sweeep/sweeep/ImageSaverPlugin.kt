package app.sweeep.sweeep

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Saves a PNG the app drew itself (the Month wrap card) into Pictures/Sweeep.
/// Nothing is shared or uploaded; the file just lands in the user's gallery.
class ImageSaverPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "app.sweeep/imagesaver").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.success(null)
        if (call.method != "savePng") return result.notImplemented()
        val bytes = call.argument<ByteArray>("bytes") ?: return result.success(null)
        val name = call.argument<String>("name") ?: "sweeep.png"
        try {
            result.success(save(ctx, bytes, name))
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun save(ctx: Context, bytes: ByteArray, name: String): String? {
        if (Build.VERSION.SDK_INT >= 29) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Sweeep")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val resolver = ctx.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return null
            resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: return null
            resolver.update(uri, ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }, null, null)
            return "Pictures/Sweeep/$name"
        }
        // Android 8/9 would need the storage permission: keep it in the app's own pictures folder
        val dir = ctx.getExternalFilesDir(Environment.DIRECTORY_PICTURES) ?: return null
        val file = File(dir, name)
        file.writeBytes(bytes)
        return file.path
    }
}
