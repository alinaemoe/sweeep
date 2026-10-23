package app.sweeep.sweeep

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.ZoneId

/// Taps from a widget wait here until the Dart side asks for them.
object WidgetActions {
    @Volatile var pending: String? = null
    const val EXTRA = "sweeep_widget_action"

    fun intent(ctx: Context, action: String): PendingIntent {
        val i = Intent(ctx, MainActivity::class.java)
            .setAction("app.sweeep.WIDGET")
            .setData(Uri.parse("sweeep://widget/$action"))
            .putExtra(EXTRA, action)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(ctx, action.hashCode(), i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
}

object Widgets {
    val kinds = listOf("today", "minute", "canfree")

    fun provider(ctx: Context, kind: String): ComponentName = ComponentName(
        ctx,
        when (kind) {
            "today" -> TodayWidget::class.java
            "minute" -> MinuteWidget::class.java
            else -> CanFreeWidget::class.java
        },
    )

    fun ids(ctx: Context, kind: String): IntArray = AppWidgetManager.getInstance(ctx).getAppWidgetIds(provider(ctx, kind))

    private fun defaults(kind: String): Pair<Float, Float> = if (kind == "today") 320f to 150f else 150f to 150f

    fun update(ctx: Context, mgr: AppWidgetManager, kind: String, id: Int) {
        val density = ctx.resources.displayMetrics.density
        val o: Bundle = mgr.getAppWidgetOptions(id)
        val d = defaults(kind)
        val w = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0).let { if (it > 0) it.toFloat() else d.first }
        val h = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0).let { if (it > 0) it.toFloat() else d.second }
        val state = WidgetStore.read(ctx)
        val bmp = WidgetRenderer.render(ctx, kind, state, w, h, density)
        val views = RemoteViews(ctx.packageName, if (kind == "today") R.layout.widget_today else R.layout.widget_simple)
        views.setImageViewBitmap(R.id.w_img, bmp)
        views.setContentDescription(R.id.w_img, WidgetRenderer.description(kind, state))
        when (kind) {
            "today" -> {
                views.setOnClickPendingIntent(R.id.w_root, WidgetActions.intent(ctx, "open"))
                views.setOnClickPendingIntent(R.id.w_btn, WidgetActions.intent(ctx, "session:${state.goal}"))
            }
            "minute" -> views.setOnClickPendingIntent(R.id.w_root, WidgetActions.intent(ctx, "session:25"))
            else -> views.setOnClickPendingIntent(R.id.w_root, WidgetActions.intent(ctx, "space"))
        }
        mgr.updateAppWidget(id, views)
    }

    fun refreshAll(ctx: Context) {
        val mgr = AppWidgetManager.getInstance(ctx)
        for (k in kinds) for (id in ids(ctx, k)) runCatching { update(ctx, mgr, k, id) }
    }

    /// One alarm just after the next midnight, so the day flips even if the app never runs.
    fun scheduleMidnight(ctx: Context) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val at = LocalDate.now().plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli() + 20_000L
        val pi = PendingIntent.getBroadcast(ctx, 4711, Intent(ctx, WidgetRefreshReceiver::class.java).setAction("app.sweeep.WIDGET_REFRESH"), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        am.setAndAllowWhileIdle(AlarmManager.RTC, at, pi)
    }
}

abstract class SweeepWidget(private val kind: String) : AppWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) Widgets.update(context, mgr, kind, id)
        Widgets.scheduleMidnight(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, mgr: AppWidgetManager, id: Int, newOptions: Bundle) {
        Widgets.update(context, mgr, kind, id)
    }

    override fun onEnabled(context: Context) = Widgets.scheduleMidnight(context)
}

class TodayWidget : SweeepWidget("today")
class MinuteWidget : SweeepWidget("minute")
class CanFreeWidget : SweeepWidget("canfree")

/// Midnight, a new date or time zone, a reboot: draw every widget again.
class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Widgets.refreshAll(context)
        Widgets.scheduleMidnight(context)
    }
}
