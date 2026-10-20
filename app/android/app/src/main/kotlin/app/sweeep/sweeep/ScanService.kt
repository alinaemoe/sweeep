package app.sweeep.sweeep

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/// Keeps the process (and so the Dart hashing loop) alive while the user
/// leaves the app during a scan. Shows a quiet progress notification.
class ScanService : Service() {
    private var wake: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                release()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                val done = intent?.getIntExtra(EXTRA_DONE, 0) ?: 0
                val total = intent?.getIntExtra(EXTRA_TOTAL, 0) ?: 0
                val text = intent?.getStringExtra(EXTRA_TEXT) ?: "Scanning your library"
                ensureChannel()
                val n = notification(done, total, text)
                if (Build.VERSION.SDK_INT >= 29) {
                    startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
                } else {
                    startForeground(NOTIFICATION_ID, n)
                }
                acquire()
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        release()
        super.onDestroy()
    }

    // the scan is CPU work; keep it running with the screen off
    private fun acquire() {
        if (wake?.isHeld == true) return
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wake = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "sweeep:scan").apply { acquire(2 * 60 * 60 * 1000L) }
    }

    private fun release() {
        wake?.let { if (it.isHeld) it.release() }
        wake = null
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) == null) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL, "Library scan", NotificationManager.IMPORTANCE_LOW))
        }
    }

    private fun notification(done: Int, total: Int, text: String): Notification {
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_scan)
            .setContentTitle("Sweeep is scanning")
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(open)
            .setProgress(total, done, total <= 0)
            .build()
    }

    companion object {
        const val ACTION_STOP = "app.sweeep.scan.STOP"
        const val EXTRA_DONE = "done"
        const val EXTRA_TOTAL = "total"
        const val EXTRA_TEXT = "text"
        private const val CHANNEL = "scan"
        private const val NOTIFICATION_ID = 4711
    }
}
