package app.sweeep.sweeep

import android.app.Activity
import android.app.AppOpsManager
import android.app.usage.StorageStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.storage.StorageManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

/// App cleaner: user-installed launcher apps with size and last launch, their icons,
/// and one-at-a-time uninstall through the system dialog.
///
/// Package visibility comes from a <queries> entry for MAIN/LAUNCHER activities, not
/// from QUERY_ALL_PACKAGES, so only apps that have a launcher icon are visible.
class AppsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var pendingUninstall: MethodChannel.Result? = null
    private var pendingPackage: String? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "app.sweeep/apps").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        this.binding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        binding?.removeActivityResultListener(this)
        binding = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: return result.success(null)
        when (call.method) {
            "usageGranted" -> result.success(usageGranted(ctx))
            "openUsageSettings" -> result.success(openUsageSettings(ctx))
            "list" -> worker.execute {
                val rows = try { list(ctx) } catch (e: Exception) { emptyList() }
                main.post { result.success(rows) }
            }
            "icon" -> {
                val pkg = call.argument<String>("package") ?: return result.success(null)
                worker.execute {
                    val bytes = try { icon(ctx, pkg) } catch (e: Exception) { null }
                    main.post { result.success(bytes) }
                }
            }
            "uninstall" -> uninstall(ctx, call.argument<String>("package"), result)
            else -> result.notImplemented()
        }
    }

    private fun usageGranted(ctx: Context): Boolean {
        val ops = ctx.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= 29) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), ctx.packageName)
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), ctx.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings(ctx: Context): Boolean {
        val flags = Intent.FLAG_ACTIVITY_NEW_TASK
        // Android 10+ can jump straight to this app's switch; older ones show the list.
        val direct = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, Uri.fromParts("package", ctx.packageName, null)).addFlags(flags)
        return try {
            ctx.startActivity(direct)
            true
        } catch (e: Exception) {
            try {
                ctx.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).addFlags(flags))
                true
            } catch (e2: Exception) {
                false
            }
        }
    }

    private fun list(ctx: Context): List<Map<String, Any>> {
        val pm = ctx.packageManager
        val granted = usageGranted(ctx)
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val packages = pm.queryIntentActivities(launcher, 0).map { it.activityInfo.packageName }.distinct()
        val now = System.currentTimeMillis()
        val usage = if (granted) {
            val usm = ctx.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            usm.queryAndAggregateUsageStats(now - 365L * 24 * 3600 * 1000, now)
        } else {
            emptyMap()
        }
        val storage = if (granted) ctx.getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager else null
        val out = ArrayList<Map<String, Any>>()
        for (pkg in packages) {
            if (pkg == ctx.packageName) continue
            val info = try { pm.getApplicationInfo(pkg, 0) } catch (e: PackageManager.NameNotFoundException) { continue }
            if (info.flags and ApplicationInfo.FLAG_SYSTEM != 0) continue
            val pkgInfo = try { pm.getPackageInfo(pkg, 0) } catch (e: PackageManager.NameNotFoundException) { null }
            var size = apkBytes(info)
            var exact = false
            if (storage != null) {
                try {
                    val s = storage.queryStatsForPackage(StorageManager.UUID_DEFAULT, pkg, Process.myUserHandle())
                    size = s.appBytes + s.dataBytes + s.cacheBytes
                    exact = true
                } catch (e: Exception) {
                    // keep the apk size
                }
            }
            val last = usage[pkg]?.lastTimeUsed ?: 0L
            out.add(
                mapOf(
                    "package" to pkg,
                    "name" to pm.getApplicationLabel(info).toString(),
                    "size" to size,
                    "exact" to exact,
                    "lastUsed" to last,
                    "installed" to (pkgInfo?.firstInstallTime ?: 0L),
                ),
            )
        }
        return out
    }

    private fun apkBytes(info: ApplicationInfo): Long {
        var total = File(info.sourceDir).length()
        info.splitSourceDirs?.forEach { total += File(it).length() }
        return total
    }

    private fun icon(ctx: Context, pkg: String): ByteArray? {
        val d = ctx.packageManager.getApplicationIcon(pkg)
        val side = 96
        val bmp = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        d.setBounds(0, 0, side, side)
        d.draw(canvas)
        val bos = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, bos)
        bmp.recycle()
        return bos.toByteArray()
    }

    private fun uninstall(ctx: Context, pkg: String?, result: MethodChannel.Result) {
        val act = activity
        if (pkg == null || act == null || pendingUninstall != null) return result.success(false)
        pendingUninstall = result
        pendingPackage = pkg
        try {
            val i = Intent(Intent.ACTION_DELETE, Uri.fromParts("package", pkg, null)).putExtra(Intent.EXTRA_RETURN_RESULT, true)
            act.startActivityForResult(i, REQUEST_UNINSTALL)
        } catch (e: Exception) {
            pendingUninstall = null
            pendingPackage = null
            result.success(false)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_UNINSTALL) return false
        val pkg = pendingPackage
        val r = pendingUninstall
        pendingUninstall = null
        pendingPackage = null
        // The result code is not reliable across Android versions; the package being gone is.
        val gone = pkg != null && try {
            context?.packageManager?.getPackageInfo(pkg, 0)
            false
        } catch (e: PackageManager.NameNotFoundException) {
            true
        }
        r?.success(gone)
        return true
    }

    companion object {
        private const val REQUEST_UNINSTALL = 7301
    }
}
