package app.sweeep.sweeep

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import androidx.core.app.NotificationCompat
import java.io.File
import java.util.Calendar

/// One local reminder a day (no server). The alarm is re-armed every time it
/// fires and after a reboot; it stays quiet on days the user already decided
/// at least one photo.
object Reminder {
    private const val PREFS = "reminder"
    private const val CHANNEL = "reminders"
    private const val NOTIFICATION_ID = 4712

    fun save(ctx: Context, minutes: Int, title: String, body: String, channel: String) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean("on", true).putInt("minutes", minutes)
            .putString("title", title).putString("body", body).putString("channel", channel)
            .apply()
    }

    fun clear(ctx: Context) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean("on", false).apply()
        alarms(ctx).cancel(pending(ctx))
    }

    private fun alarms(ctx: Context) = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun pending(ctx: Context): PendingIntent = PendingIntent.getBroadcast(
        ctx, 0, Intent(ctx, ReminderReceiver::class.java),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    /// Arms the next alarm (today if the time is still ahead, else tomorrow).
    fun arm(ctx: Context) {
        val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!p.getBoolean("on", false)) return
        val minutes = p.getInt("minutes", 19 * 60)
        val at = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, minutes / 60)
            set(Calendar.MINUTE, minutes % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis() + 30_000) add(Calendar.DAY_OF_YEAR, 1)
        }
        // inexact on purpose: no exact-alarm permission needed, a few minutes of drift is fine
        alarms(ctx).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at.timeInMillis, pending(ctx))
    }

    fun fire(ctx: Context) {
        val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!p.getBoolean("on", false)) return
        arm(ctx) // tomorrow's, whatever happens below
        if (decidedToday(ctx)) return
        if (Build.VERSION.SDK_INT >= 26) {
            ctx.getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, p.getString("channel", "Reminders"), NotificationManager.IMPORTANCE_DEFAULT),
            )
        }
        val open = PendingIntent.getActivity(
            ctx, 0, Intent(ctx, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_scan)
            .setContentTitle(p.getString("title", "Sweeep"))
            .setContentText(p.getString("body", ""))
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        try {
            ctx.getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, n)
        } catch (_: SecurityException) {
            // notifications were switched off in the meantime
        }
    }

    /// Reads the app's own database: was any photo decided since local midnight?
    private fun decidedToday(ctx: Context): Boolean {
        val file = File(ctx.getDir("flutter", Context.MODE_PRIVATE), "sweeep.sqlite")
        if (!file.exists()) return false
        val midnight = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        return try {
            SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY).use { db ->
                db.rawQuery("SELECT COUNT(*) FROM decisions WHERE decided_at_ms >= ?", arrayOf(midnight.toString())).use { c ->
                    c.moveToFirst() && c.getInt(0) > 0
                }
            }
        } catch (_: Exception) {
            false
        }
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) = Reminder.fire(context)
}

class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) Reminder.arm(context)
    }
}
