package app.sweeep.sweeep

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Size
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/**
 * MediaStore-backed implementation of [MediaHostApi]: permissions,
 * enumeration, grayscale thumbnails. Read-only; deletion arrives in a later phase.
 */
class MediaPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    MediaHostApi {

    private var appContext: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermission: ((PermissionState) -> Unit)? = null

    // region plugin lifecycle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        MediaHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MediaHostApi.setUp(binding.binaryMessenger, null)
        appContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = detachActivity()
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)
    override fun onDetachedFromActivity() = detachActivity()

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    // endregion

    // region permissions

    private fun granted(p: String): Boolean {
        val ctx = appContext ?: return false
        return ContextCompat.checkSelfPermission(ctx, p) == PackageManager.PERMISSION_GRANTED
    }

    override fun permissionState(): PermissionState {
        return if (Build.VERSION.SDK_INT >= 33) {
            val full = granted(Manifest.permission.READ_MEDIA_IMAGES) && granted(Manifest.permission.READ_MEDIA_VIDEO)
            when {
                full -> PermissionState.GRANTED
                Build.VERSION.SDK_INT >= 34 && granted(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED) ->
                    PermissionState.LIMITED
                else -> PermissionState.DENIED
            }
        } else {
            if (granted(Manifest.permission.READ_EXTERNAL_STORAGE)) PermissionState.GRANTED else PermissionState.DENIED
        }
    }

    override suspend fun requestPermission(): PermissionState {
        val current = permissionState()
        if (current == PermissionState.GRANTED) return current
        val act = activity ?: return current
        val perms = when {
            Build.VERSION.SDK_INT >= 34 -> arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO,
                Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED,
            )
            Build.VERSION.SDK_INT >= 33 -> arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO,
            )
            else -> arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        return suspendCoroutine { cont ->
            pendingPermission = { state -> cont.resume(state) }
            ActivityCompat.requestPermissions(act, perms, REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val cb = pendingPermission
        pendingPermission = null
        cb?.invoke(permissionState())
        return true
    }

    // endregion

    // region enumeration

    private val filesUri: Uri get() = MediaStore.Files.getContentUri("external")

    private val projection = arrayOf(
        MediaStore.Files.FileColumns._ID,
        MediaStore.Files.FileColumns.MEDIA_TYPE,
        MediaStore.Files.FileColumns.WIDTH,
        MediaStore.Files.FileColumns.HEIGHT,
        MediaStore.Files.FileColumns.SIZE,
        MediaStore.Files.FileColumns.DATE_ADDED,
        MediaStore.Files.FileColumns.DATE_MODIFIED,
        MediaStore.Files.FileColumns.DISPLAY_NAME,
        MediaStore.MediaColumns.DATE_TAKEN,
        MediaStore.MediaColumns.DURATION,
        MediaStore.MediaColumns.BUCKET_DISPLAY_NAME,
        MediaStore.MediaColumns.RELATIVE_PATH,
    )

    // MediaStore labels some documents (e.g. .djvu, image/vnd.*) as images; they are
    // not photos and cannot be decoded, so keep them out of the index.
    private val typeClause =
        "(${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (" +
            "${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}, ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO})" +
            " AND (${MediaStore.MediaColumns.MIME_TYPE} IS NULL OR " +
            "(${MediaStore.MediaColumns.MIME_TYPE} NOT LIKE 'image/vnd.%' AND ${MediaStore.MediaColumns.MIME_TYPE} NOT LIKE 'image/svg%')))"

    override suspend fun listAssets(sinceMs: Long?, cursor: String?, limit: Long): AssetPage =
        withContext(Dispatchers.IO) {
            val ctx = appContext ?: return@withContext AssetPage(emptyList(), null)
            val clauses = mutableListOf(typeClause)
            val args = mutableListOf<String>()
            if (sinceMs != null) {
                clauses += "${MediaStore.Files.FileColumns.DATE_MODIFIED} >= ?"
                args += (sinceMs / 1000).toString()
            }
            if (cursor != null) {
                // keyset pagination on (date_modified DESC, _id DESC)
                val (mod, id) = cursor.split("|").let { it[0] to it[1] }
                clauses += "(${MediaStore.Files.FileColumns.DATE_MODIFIED} < ? OR " +
                    "(${MediaStore.Files.FileColumns.DATE_MODIFIED} = ? AND ${MediaStore.Files.FileColumns._ID} < ?))"
                args += listOf(mod, mod, id)
            }
            val bundle = Bundle().apply {
                putString(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION, clauses.joinToString(" AND "))
                putStringArray(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, args.toTypedArray())
                putString(
                    android.content.ContentResolver.QUERY_ARG_SQL_SORT_ORDER,
                    "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC, ${MediaStore.Files.FileColumns._ID} DESC",
                )
                putInt(android.content.ContentResolver.QUERY_ARG_LIMIT, limit.toInt())
            }
            val out = ArrayList<AssetInfo>()
            var lastMod = 0L
            var lastId = 0L
            ctx.contentResolver.query(filesUri, projection, bundle, null)?.use { c ->
                val iId = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
                val iType = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)
                val iW = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.WIDTH)
                val iH = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.HEIGHT)
                val iSize = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
                val iAdded = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)
                val iMod = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
                val iName = c.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val iTaken = c.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_TAKEN)
                val iDur = c.getColumnIndexOrThrow(MediaStore.MediaColumns.DURATION)
                val iBucket = c.getColumnIndexOrThrow(MediaStore.MediaColumns.BUCKET_DISPLAY_NAME)
                val iPath = c.getColumnIndexOrThrow(MediaStore.MediaColumns.RELATIVE_PATH)
                while (c.moveToNext()) {
                    val id = c.getLong(iId)
                    val isVideo = c.getInt(iType) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                    val name = c.getString(iName) ?: ""
                    val path = c.getString(iPath) ?: ""
                    val bucket = c.getString(iBucket)
                    val mod = c.getLong(iMod)
                    val taken = if (c.isNull(iTaken)) 0L else c.getLong(iTaken)
                    val created = if (taken > 0) taken else c.getLong(iAdded) * 1000
                    out += AssetInfo(
                        id = id.toString(),
                        mediaType = if (isVideo) MediaType.VIDEO else MediaType.PHOTO,
                        width = c.getLong(iW),
                        height = c.getLong(iH),
                        sizeBytes = c.getLong(iSize),
                        createdAtMs = created,
                        modifiedAtMs = mod * 1000,
                        durationMs = if (isVideo && !c.isNull(iDur)) c.getLong(iDur) else null,
                        bucket = bucket,
                        isScreenshot = !isVideo && isScreenshot(name, path),
                        isScreenRecording = isVideo && isScreenRecording(name, path),
                        chatSource = chatSource(path, bucket),
                    )
                    lastMod = mod
                    lastId = id
                }
            }
            val next = if (out.size.toLong() >= limit) "$lastMod|$lastId" else null
            AssetPage(out, next)
        }

    override suspend fun allAssetIds(): List<String> = withContext(Dispatchers.IO) {
        val ctx = appContext ?: return@withContext emptyList()
        val ids = ArrayList<String>()
        ctx.contentResolver.query(
            filesUri,
            arrayOf(MediaStore.Files.FileColumns._ID),
            typeClause,
            null,
            null,
        )?.use { c ->
            while (c.moveToNext()) ids += c.getLong(0).toString()
        }
        ids
    }

    private fun isScreenshot(name: String, path: String): Boolean =
        path.contains("Screenshots", ignoreCase = true) || name.startsWith("Screenshot", ignoreCase = true)

    private fun isScreenRecording(name: String, path: String): Boolean =
        path.contains("Screen record", ignoreCase = true) ||
            path.contains("ScreenRecord", ignoreCase = true) ||
            name.startsWith("Screen_Recording", ignoreCase = true) ||
            name.startsWith("Screenrecorder", ignoreCase = true) ||
            name.startsWith("Screen Recording", ignoreCase = true)

    private fun chatSource(path: String, bucket: String?): String? {
        val hay = "$path ${bucket ?: ""}".lowercase()
        return when {
            "whatsapp" in hay -> "whatsapp"
            "telegram" in hay -> "telegram"
            "viber" in hay -> "viber"
            "messenger" in hay -> "messenger"
            "signal" in hay -> "signal"
            else -> null
        }
    }

    // endregion

    // region thumbnails and bytes

    private fun uriFor(assetId: String): Uri? {
        val ctx = appContext ?: return null
        val id = assetId.toLongOrNull() ?: return null
        // Files table id is shared with Images/Video tables; resolve media type.
        val type = ctx.contentResolver.query(
            ContentUris.withAppendedId(filesUri, id),
            arrayOf(MediaStore.Files.FileColumns.MEDIA_TYPE),
            null, null, null,
        )?.use { if (it.moveToFirst()) it.getInt(0) else null } ?: return null
        val base = if (type == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO)
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        else
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        return ContentUris.withAppendedId(base, id)
    }

    /** Decodes a thumbnail bitmap no larger than `side`, or null if unreadable. */
    private fun loadBitmap(ctx: Context, uri: Uri, side: Int): Bitmap? =
        try {
            if (Build.VERSION.SDK_INT >= 29) {
                ctx.contentResolver.loadThumbnail(uri, Size(side, side), null)
            } else if (uri.toString().contains("/video/")) {
                val r = MediaMetadataRetriever()
                try {
                    r.setDataSource(ctx, uri)
                    r.getFrameAtTime(-1)
                } finally {
                    r.release()
                }
            } else {
                decodeSampled(ctx, uri, side)
            }
        } catch (e: Exception) {
            android.util.Log.w("Sweeep", "thumbnail failed for $uri: $e")
            null
        }

    override suspend fun grayThumbnail(assetId: String, maxSide: Long): GrayThumb? =
        withContext(Dispatchers.IO) {
            val ctx = appContext ?: return@withContext null
            val uri = uriFor(assetId) ?: return@withContext null
            val side = maxSide.toInt().coerceIn(16, 1024)
            val bmp = loadBitmap(ctx, uri, side) ?: return@withContext null
            toGray(bmp, side)
        }

    override suspend fun thumbnail(assetId: String, maxSide: Long): ByteArray? =
        withContext(Dispatchers.IO) {
            val ctx = appContext ?: return@withContext null
            val uri = uriFor(assetId) ?: return@withContext null
            val side = maxSide.toInt().coerceIn(32, 2048)
            val bmp = loadBitmap(ctx, uri, side) ?: return@withContext null
            val out = java.io.ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.JPEG, 85, out)
            out.toByteArray()
        }

    private fun decodeSampled(ctx: Context, uri: Uri, side: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outWidth <= 0) return null
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= side && bounds.outHeight / (sample * 2) >= side) sample *= 2
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, opts) }
    }

    /** Scale to fit `side`, then convert to 8-bit luma (Rec. 601). */
    private fun toGray(src: Bitmap, side: Int): GrayThumb {
        val scale = minOf(1f, side.toFloat() / maxOf(src.width, src.height))
        val w = maxOf(1, (src.width * scale).toInt())
        val h = maxOf(1, (src.height * scale).toInt())
        val bmp = if (w != src.width || h != src.height) Bitmap.createScaledBitmap(src, w, h, true) else src
        val px = IntArray(w * h)
        bmp.getPixels(px, 0, w, 0, 0, w, h)
        val out = ByteArray(w * h)
        for (i in px.indices) {
            val p = px[i]
            val r = (p shr 16) and 0xFF
            val g = (p shr 8) and 0xFF
            val b = p and 0xFF
            out[i] = ((r * 299 + g * 587 + b * 114) / 1000).toByte()
        }
        return GrayThumb(w.toLong(), h.toLong(), out)
    }

    override suspend fun sha256(assetId: String): ByteArray? = withContext(Dispatchers.IO) {
        val ctx = appContext ?: return@withContext null
        val uri = uriFor(assetId) ?: return@withContext null
        try {
            val md = java.security.MessageDigest.getInstance("SHA-256")
            ctx.contentResolver.openInputStream(uri)?.use { input ->
                val buf = ByteArray(256 * 1024)
                while (true) {
                    val n = input.read(buf)
                    if (n < 0) break
                    md.update(buf, 0, n)
                }
            } ?: return@withContext null
            md.digest()
        } catch (e: Exception) {
            null
        }
    }

    // endregion

    override suspend fun deleteAssets(assetIds: List<String>): DeleteResult {
        // Phase 3: MediaStore.createDeleteRequest. Intentionally not implemented yet.
        throw UnsupportedOperationException("deleteAssets arrives in Phase 3")
    }

    companion object {
        private const val REQUEST_CODE = 4711
    }
}
