package app.sweeep.sweeep

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors

/// Where a photo was taken, for Moments. Android hides this from apps unless the user allows
/// ACCESS_MEDIA_LOCATION, and the original file (not the system copy) has to be opened to
/// read it. The MediaStore LATITUDE/LONGITUDE columns are deprecated and not used.
/// Nothing is sent anywhere; the numbers go to the app's own database.
class PlacesPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var pending: MethodChannel.Result? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "app.sweeep/places").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        this.binding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        binding?.removeRequestPermissionsResultListener(this)
        binding = null
        activity = null
    }

    private fun granted(ctx: Context): Boolean =
        Build.VERSION.SDK_INT < 29 || ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_MEDIA_LOCATION) == PackageManager.PERMISSION_GRANTED

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.success(null)
        when (call.method) {
            "hasPermission" -> result.success(granted(ctx))
            "request" -> {
                val act = activity
                android.util.Log.i("SweeepPlaces", "request: granted=${granted(ctx)} activity=${act != null} pending=${pending != null}")
                if (granted(ctx)) return result.success(true)
                if (act == null || pending != null) {
                    pending = null
                    return result.success(false)
                }
                pending = result
                ActivityCompat.requestPermissions(act, arrayOf(Manifest.permission.ACCESS_MEDIA_LOCATION), REQUEST)
            }
            "read" -> {
                val ids = call.argument<List<String>>("ids") ?: return result.success(emptyMap<String, List<Double>>())
                worker.execute {
                    val out = HashMap<String, List<Double>>()
                    for (id in ids) {
                        val ll = try { latLong(ctx, id) } catch (e: Exception) { null }
                        if (ll != null) out[id] = ll
                    }
                    main.post { result.success(out) }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun latLong(ctx: Context, id: String): List<Double>? {
        val n = id.toLongOrNull() ?: return null
        var uri: Uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, n)
        if (Build.VERSION.SDK_INT >= 29) uri = MediaStore.setRequireOriginal(uri)
        ctx.contentResolver.openInputStream(uri)?.use { s ->
            val out = FloatArray(2)
            if (ExifInterface(s).getLatLong(out)) {
                if (out[0] == 0f && out[1] == 0f) return null
                return listOf(out[0].toDouble(), out[1].toDouble())
            }
        }
        return null
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST) return false
        val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        android.util.Log.i("SweeepPlaces", "result: ok=$ok results=${grantResults.toList()}")
        pending?.success(ok)
        pending = null
        return true
    }

    companion object {
        private const val REQUEST = 7302
    }
}
