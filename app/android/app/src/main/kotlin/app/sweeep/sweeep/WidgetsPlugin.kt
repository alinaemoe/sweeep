package app.sweeep.sweeep

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.Bitmap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/// Dart writes the widget numbers here, asks for a preview drawn by the same
/// renderer, and picks up the tap that started the app.
class WidgetsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "app.sweeep/widgets").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.success(null)
        when (call.method) {
            "save" -> {
                WidgetStore.save(ctx, (call.arguments as Map<String, Any?>))
                Widgets.refreshAll(ctx)
                result.success(true)
            }
            "takeAction" -> {
                result.success(WidgetActions.pending)
                WidgetActions.pending = null
            }
            "render" -> {
                val kind = call.argument<String>("kind") ?: "today"
                val w = (call.argument<Number>("w") ?: 320).toFloat()
                val h = (call.argument<Number>("h") ?: 150).toFloat()
                val density = (call.argument<Number>("density") ?: 3).toFloat()
                val state = if (call.argument<Boolean>("empty") == true) WidgetStore.empty() else WidgetStore.read(ctx)
                val bmp = WidgetRenderer.render(ctx, kind, state, w, h, density)
                val bos = ByteArrayOutputStream()
                bmp.compress(Bitmap.CompressFormat.PNG, 100, bos)
                result.success(bos.toByteArray())
            }
            "isAdded" -> result.success(Widgets.ids(ctx, call.argument<String>("kind") ?: "today").isNotEmpty())
            "pin" -> {
                val mgr = AppWidgetManager.getInstance(ctx)
                val kind = call.argument<String>("kind") ?: "today"
                if (!mgr.isRequestPinAppWidgetSupported) return result.success(false)
                result.success(mgr.requestPinAppWidget(Widgets.provider(ctx, kind), null, null))
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        var channel: MethodChannel? = null

        /// A widget was tapped while the app was already running.
        fun notifyAction() {
            channel?.invokeMethod("action", null)
        }
    }
}
