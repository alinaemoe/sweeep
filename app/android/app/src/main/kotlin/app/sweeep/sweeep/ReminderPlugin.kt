package app.sweeep.sweeep

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// schedule / cancel / permission for the daily reminder (see [Reminder]).
class ReminderPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "app.sweeep/reminder").also { it.setMethodCallHandler(this) }
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

    private fun granted(ctx: Context) =
        Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.success(null)
        when (call.method) {
            "hasPermission" -> result.success(granted(ctx))
            "requestPermission" -> {
                if (!granted(ctx)) activity?.let { ActivityCompat.requestPermissions(it, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4721) }
                result.success(granted(ctx))
            }
            "schedule" -> {
                Reminder.save(
                    ctx,
                    call.argument<Int>("minutes") ?: (20 * 60),
                    call.argument<String>("title") ?: "Sweeep",
                    call.argument<String>("body") ?: "",
                    call.argument<String>("channel") ?: "Reminders",
                )
                Reminder.arm(ctx)
                result.success(null)
            }
            "cancel" -> {
                Reminder.clear(ctx)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
