package app.sweeep.sweeep

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// start / update / stop for [ScanService] from Dart.
class ScanServicePlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "app.sweeep/scan").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.success(null)
        when (call.method) {
            "start", "update" -> {
                if (call.method == "start") askNotificationPermission(ctx)
                val i = Intent(ctx, ScanService::class.java)
                    .putExtra(ScanService.EXTRA_DONE, call.argument<Int>("done") ?: 0)
                    .putExtra(ScanService.EXTRA_TOTAL, call.argument<Int>("total") ?: 0)
                    .putExtra(ScanService.EXTRA_TEXT, call.argument<String>("text") ?: "Scanning your library")
                    .putExtra(ScanService.EXTRA_TITLE, call.argument<String>("title") ?: "Sweeep is scanning")
                    .putExtra(ScanService.EXTRA_CHANNEL, call.argument<String>("channel") ?: "Library scan")
                try {
                    ContextCompat.startForegroundService(ctx, i)
                    result.success(true)
                } catch (e: Exception) {
                    // e.g. started from the background on a strict OS: the scan still runs in-app
                    result.success(false)
                }
            }
            "stop" -> {
                ctx.startService(Intent(ctx, ScanService::class.java).setAction(ScanService.ACTION_STOP))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // Android 13+: without this the progress notification stays hidden (the service itself still works).
    private fun askNotificationPermission(ctx: Context) {
        if (Build.VERSION.SDK_INT < 33) return
        if (ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return
        activity?.let { ActivityCompat.requestPermissions(it, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4720) }
    }
}
