package app.sweeep.sweeep

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import java.time.LocalDate
import kotlin.math.max
import kotlin.math.min

/// The numbers and texts the widgets show. Dart writes them (already translated);
/// nothing else is stored here: no photos, no file names.
class WidgetState(
    val has: Boolean,
    val done: Int,
    val goal: Int,
    val streak: Int,
    val canFreeNum: String?,
    val canFreeUnit: String,
    val ofToday: String,
    val leftText: String,
    val streakText: String,
    val cont: String,
    val swipeNow: String,
    val about: String,
    val canFree: String,
    val tapMap: String,
    val empty: String,
) {
    val fraction: Float get() = if (goal <= 0) 0f else min(1f, done.toFloat() / goal)
}

object WidgetStore {
    private const val PREFS = "sweeep_widgets"

    fun save(ctx: Context, m: Map<String, Any?>) {
        val e = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        for ((k, v) in m) {
            when (v) {
                is Int -> e.putInt(k, v)
                is Long -> e.putLong(k, v)
                is String -> e.putString(k, v)
                is Boolean -> e.putBoolean(k, v)
                null -> e.remove(k)
            }
        }
        e.apply()
    }

    /// Before the app has written anything: neat defaults, no numbers.
    fun empty(goal: Int = 50) = WidgetState(false, 0, goal, 0, null, "GB", "/ $goal today", "", "No streak yet", "Continue", "Swipe 25 now", "about 2 min", "CAN FREE", "Tap to open the storage map", "Open Sweeep to start")

    /// The numbers of the prototype, for the images the widget picker shows.
    fun sample() = WidgetState(true, 31, 50, 8, "12.4", "GB", "/ 50 today", "19 left for a 9-day streak", "8 day streak", "Continue", "Swipe 25 now", "about 2 min", "CAN FREE", "Tap to open the storage map", "Open Sweeep to start")

    /// What to draw right now. A snapshot from an earlier day reads as a new day:
    /// zero today, the streak kept when yesterday is where it was written.
    fun read(ctx: Context, today: LocalDate = LocalDate.now()): WidgetState {
        val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val day = p.getString("day", null)
        val goal = p.getInt("goal", 50)
        val str = { k: String, d: String -> p.getString(k, d) ?: d }
        if (day == null) return empty(goal)
        val written = runCatching { LocalDate.parse(day) }.getOrDefault(today)
        val sameDay = written == today
        val kept = sameDay || written == today.minusDays(1)
        var done = if (sameDay) p.getInt("done", 0) else 0
        val streak = if (kept) p.getInt("streak", 0) else 0
        val newDayLeft = if (streak > 0) str("tLeftNew", "") else str("tLeftNew0", "")
        val left = when {
            !sameDay -> newDayLeft
            done >= goal -> str("tGoalReached", "")
            else -> str("tLeftNow", "")
        }
        if (done < 0) done = 0
        return WidgetState(
            true, done, goal, streak,
            p.getString("canFreeNum", null), str("canFreeUnit", "GB"),
            str("tOf", "/ $goal today"), left,
            if (streak > 0) str("tStreak", "") else str("tStreakZero", "No streak yet"),
            str("tContinue", "Continue"), str("tSwipe", "Swipe 25 now"), str("tAbout", "about 2 min"),
            str("tCanFree", "CAN FREE"), str("tTapMap", "Tap to open the storage map"), str("tEmpty", "Open Sweeep to start"),
        )
    }
}

/// Draws the three widgets of D17 on a canvas, in dp (the canvas is scaled to the screen).
/// RemoteViews has no custom fonts, rings or soft glows, so the whole face is a bitmap
/// and the taps are transparent zones on top.
object WidgetRenderer {
    private val BG = Color.parseColor("#181920")
    private val TRACK = Color.parseColor("#262833")
    private val BRAND = Color.parseColor("#B8A6FF")
    private val MUTED = Color.parseColor("#8A8F9E")
    private val INK = Color.parseColor("#0F1015")
    private val TEXT = Color.parseColor("#F2F3F7")

    private val faces = HashMap<Int, Typeface>()
    private fun face(ctx: Context, weight: Int): Typeface = faces.getOrPut(weight) {
        runCatching { Typeface.createFromAsset(ctx.assets, "flutter_assets/assets/fonts/PlusJakartaSans-$weight.ttf") }.getOrDefault(Typeface.DEFAULT_BOLD)
    }

    private fun paint(ctx: Context, weight: Int, size: Float, color: Int, spacingPx: Float = 0f): TextPaint =
        TextPaint(Paint.ANTI_ALIAS_FLAG or Paint.SUBPIXEL_TEXT_FLAG).apply {
            typeface = face(ctx, weight)
            textSize = size
            this.color = color
            letterSpacing = if (size > 0) spacingPx / size else 0f
        }

    /// Draws [text] so a CSS box of height [lineH] at [top] holds it centred, like a line box.
    private fun Canvas.line(text: String, x: Float, top: Float, lineH: Float, p: TextPaint) {
        val fm = p.fontMetrics
        val base = top + (lineH - (fm.descent - fm.ascent)) / 2f - fm.ascent
        drawText(text, x, base, p)
    }

    private fun Canvas.centered(text: String, cx: Float, top: Float, lineH: Float, p: TextPaint) {
        line(text, cx - p.measureText(text) / 2f, top, lineH, p)
    }

    private fun normalH(p: TextPaint): Float = p.fontMetrics.let { it.descent - it.ascent }

    /// Shrinks the paint until [text] fits [maxW].
    private fun fit(p: TextPaint, text: String, maxW: Float, minSize: Float = 8f) {
        var guard = 0
        while (p.measureText(text) > maxW && p.textSize > minSize && guard++ < 40) {
            val s = p.textSize - .5f
            val sp = p.letterSpacing * p.textSize
            p.textSize = s
            p.letterSpacing = if (s > 0) sp / s else 0f
        }
    }

    private fun base(w: Float, h: Float, dp: Float, glow: Boolean): Pair<Bitmap, Canvas> {
        val bmp = Bitmap.createBitmap(max(1, (w * dp).toInt()), max(1, (h * dp).toInt()), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        c.scale(dp, dp)
        val r = 32f
        val rect = RectF(0f, 0f, w, h)
        val clip = Path().apply { addRoundRect(rect, r, r, Path.Direction.CW) }
        c.save()
        c.clipPath(clip)
        c.drawColor(BG)
        if (glow) {
            // 160 circle at right -40, top -40, blurred 40: a soft lavender corner
            val cx = w - 40f
            val cy = 40f
            val p = Paint(Paint.ANTI_ALIAS_FLAG)
            p.shader = RadialGradient(cx, cy, 120f, intArrayOf(Color.argb(56, 184, 166, 255), Color.argb(34, 184, 166, 255), Color.argb(0, 184, 166, 255)), floatArrayOf(0f, .45f, 1f), Shader.TileMode.CLAMP)
            c.drawCircle(cx, cy, 120f, p)
        }
        c.restore()
        val b = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 1f
            color = Color.argb(20, 255, 255, 255)
        }
        c.drawRoundRect(RectF(.5f, .5f, w - .5f, h - .5f), r - .5f, r - .5f, b)
        return bmp to c
    }

    private fun flame(c: Canvas, x: Float, y: Float, size: Float, color: Int) {
        val k = size / 24f
        val path = Path()
        path.moveTo(12f, 2f)
        path.rCubicTo(1f, 4f, 5f, 5.5f, 5f, 10f)
        path.arcTo(RectF(7f, 7f, 17f, 17f), 0f, 180f, false)
        path.rCubicTo(0f, -2f, 1f, -3f, 2f, -4f)
        path.rCubicTo(0f, 2f, 1f, 3f, 2f, 3f)
        path.rCubicTo(0f, -3f, -1f, -5f, 1f, -9f)
        path.close()
        c.save()
        c.translate(x, y)
        c.scale(k, k)
        c.drawPath(path, Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color; style = Paint.Style.FILL })
        c.restore()
    }

    fun description(kind: String, s: WidgetState): String = when (kind) {
        "today" -> "Sweeep. ${s.done} ${s.ofToday}. ${s.leftText}. ${s.streakText}. ${s.cont}"
        "minute" -> "Sweeep. ${s.swipeNow}, ${s.about}"
        else -> "Sweeep. ${s.canFree} ${s.canFreeNum ?: ""} ${s.canFreeUnit}. ${s.tapMap}"
    }

    fun render(ctx: Context, kind: String, s: WidgetState, wDp: Float, hDp: Float, density: Float): Bitmap = when (kind) {
        "today" -> today(ctx, s, wDp, hDp, density)
        "minute" -> minute(ctx, s, wDp, hDp, density)
        else -> canFree(ctx, s, wDp, hDp, density)
    }

    /// Everything is designed on a 150 dp tall card. A bigger widget scales the whole design up
    /// (text, ring, button) and centres it, so a tall 2x2 stays a calm square, not a stretched one.
    private fun uni(w: Float, h: Float, designW: Float): Float = min(w / designW, h / 150f).coerceIn(.8f, 1.35f)

    private fun today(ctx: Context, s: WidgetState, w0: Float, h0: Float, dp: Float): Bitmap {
        val (bmp, c) = base(w0, h0, dp, true)
        // one grid row is about 110 dp: the same card, rows packed closer
        val compact = h0 < 130f
        val dh = if (compact) 116f else 150f
        val k = min(w0 / 320f, h0 / dh).coerceIn(.7f, 1.35f)
        c.scale(k, k)
        val w = w0 / k
        val oy = max(0f, (h0 / k - dh) / 2f)
        fun y(v: Float) = v + oy
        val yWm = if (compact) 12f else 18f
        val yBig = if (compact) 33f else 50f
        val yBar = if (compact) 82f else 100f
        val yLeft = if (compact) 94f else 114f
        val yBtn = if (compact) 22f else 38f
        val btnH = if (compact) 44f else 48f
        val yStreak = if (compact) 72f else 96f
        val wm = paint(ctx, 800, 15f, TEXT, -.3f)
        val ee = paint(ctx, 800, 15f, BRAND, -.3f)
        var x = 20f
        for ((t, p) in listOf("SW" to wm, "EEE" to ee, "P" to wm)) {
            c.line(t, x, y(yWm), normalH(p), p)
            x += p.measureText(t) + p.letterSpacing * p.textSize
        }
        if (!s.has) {
            val p = paint(ctx, 700, 15f, TEXT)
            val bw = w - 40f
            fit(p, s.empty, bw)
            c.line(s.empty, 20f, y(yBig + 6f), normalH(p), p)
            return bmp
        }
        // 31 / 50 today
        val room = w - 150f - 20f
        val big = paint(ctx, 800, 38f, TEXT, -1.5f)
        val small = paint(ctx, 700, 18f, MUTED, -1.5f)
        val num = s.done.toString()
        val tail = " " + s.ofToday
        while (big.measureText(num) + small.measureText(tail) > room && small.textSize > 11f) {
            small.textSize -= .5f
        }
        c.line(num, 20f, y(yBig), 38f, big)
        // the grey tail sits on the same baseline as the number
        val fm = big.fontMetrics
        val baseline = y(yBig) + (38f - (fm.descent - fm.ascent)) / 2f - fm.ascent
        c.drawText(tail, 20f + big.measureText(num) + big.letterSpacing * big.textSize, baseline, small)
        // progress bar
        val bar = RectF(20f, y(yBar), w - 150f, y(yBar) + 8f)
        val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = TRACK }
        c.drawRoundRect(bar, 4f, 4f, tp)
        val fw = bar.width() * s.fraction
        if (fw > 0f) c.drawRoundRect(RectF(bar.left, bar.top, bar.left + max(fw, 8f), bar.bottom), 4f, 4f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = BRAND })
        // left for the streak
        val lp = paint(ctx, 600, 12f, MUTED)
        fit(lp, s.leftText, room)
        c.line(s.leftText, 20f, y(yLeft), normalH(lp), lp)
        // button
        val bp = paint(ctx, 800, 15f, INK)
        val bw = bp.measureText(s.cont) + 40f
        val br = RectF(w - 18f - bw, y(yBtn), w - 18f, y(yBtn) + btnH)
        c.drawRoundRect(br, btnH / 2f, btnH / 2f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = BRAND })
        c.centered(s.cont, br.centerX(), br.top, btnH, bp)
        // flame + streak
        val sp = paint(ctx, 700, 12f, BRAND)
        fit(sp, s.streakText, 112f - 19f)
        val total = (if (s.streak > 0) 14f + 5f else 0f) + sp.measureText(s.streakText)
        val boxCx = w - 18f - 56f
        var sx = boxCx - total / 2f
        if (s.streak > 0) {
            flame(c, sx, y(yStreak) + (normalH(sp) - 14f) / 2f, 14f, BRAND)
            sx += 19f
        }
        c.line(s.streakText, sx, y(yStreak), normalH(sp), sp)
        return bmp
    }

    private fun minute(ctx: Context, s: WidgetState, w0: Float, h0: Float, dp: Float): Bitmap {
        if (w0 / h0 > 1.3f) return minuteWide(ctx, s, w0, h0, dp)
        val (bmp, c) = base(w0, h0, dp, false)
        val k = uni(w0, h0, 150f)
        c.scale(k, k)
        val w = w0 / k
        val oy = max(0f, (h0 / k - 150f) / 2f)
        fun y(v: Float) = v + oy
        val cx = w / 2f
        val cy = y(68f)
        val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 9f
            strokeCap = Paint.Cap.ROUND
        }
        val oval = RectF(cx - 28f, cy - 28f, cx + 28f, cy + 28f)
        ring.color = TRACK
        c.drawCircle(cx, cy, 28f, ring)
        ring.color = BRAND
        val sweep = 360f * s.fraction
        if (sweep > 0f) c.drawArc(oval, -90f, sweep, false, ring)
        val np = paint(ctx, 800, 22f, TEXT, -.8f)
        c.centered("25", cx, cy - 14f, 28f, np)
        val sp = paint(ctx, 800, 13f, TEXT)
        fit(sp, s.swipeNow, w - 20f)
        c.centered(s.swipeNow, cx, y(112f), normalH(sp), sp)
        val ap = paint(ctx, 600, 11f, MUTED)
        fit(ap, s.about, w - 20f)
        c.centered(s.about, cx, y(130f), normalH(ap), ap)
        return bmp
    }

    private fun canFree(ctx: Context, s: WidgetState, w0: Float, h0: Float, dp: Float): Bitmap {
        if (w0 / h0 > 1.3f) return canFreeWide(ctx, s, w0, h0, dp)
        val (bmp, c) = base(w0, h0, dp, false)
        val k = uni(w0, h0, 150f)
        c.scale(k, k)
        val w = w0 / k
        val oy = max(0f, (h0 / k - 150f) / 2f)
        fun y(v: Float) = v + oy
        val inner = w - 36f
        val lp = paint(ctx, 700, 12f, MUTED, 1.5f)
        fit(lp, s.canFree, inner)
        c.line(s.canFree, 18f, y(18f), normalH(lp), lp)
        val top = y(18f) + normalH(lp) + 8f
        val bp = paint(ctx, 800, 34f, TEXT, -1.4f)
        val up = paint(ctx, 800, 16f, BRAND)
        val num = s.canFreeNum ?: "—"
        val tail = " " + s.canFreeUnit
        c.line(num, 18f, top, 34f, bp)
        c.line(tail, 18f + bp.measureText(num) + bp.letterSpacing * bp.textSize, top, 34f, up)
        val cp = TextPaint(paint(ctx, 600, 12f, MUTED))
        val lay = StaticLayout.Builder.obtain(s.tapMap, 0, s.tapMap.length, cp, inner.toInt().coerceAtLeast(1))
            .setLineSpacing(0f, 1.1f).setAlignment(Layout.Alignment.ALIGN_NORMAL).setMaxLines(3).build()
        c.save()
        c.translate(18f, top + 34f + 8f)
        lay.draw(c)
        c.restore()
        return bmp
    }

    /// 2x1: the ring on the left, the two lines beside it.
    private fun minuteWide(ctx: Context, s: WidgetState, w0: Float, h0: Float, dp: Float): Bitmap {
        val (bmp, c) = base(w0, h0, dp, false)
        val k = min(w0 / 170f, h0 / 100f).coerceIn(.7f, 1.3f)
        c.scale(k, k)
        val w = w0 / k
        val cy = h0 / k / 2f
        val cx = 20f + 27f
        val ring = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 8f
            strokeCap = Paint.Cap.ROUND
            color = TRACK
        }
        c.drawCircle(cx, cy, 27f, ring)
        ring.color = BRAND
        val sweep = 360f * s.fraction
        if (sweep > 0f) c.drawArc(RectF(cx - 27f, cy - 27f, cx + 27f, cy + 27f), -90f, sweep, false, ring)
        val np = paint(ctx, 800, 20f, TEXT, -.6f)
        c.centered("25", cx, cy - 13f, 26f, np)
        val x = cx + 27f + 14f
        val room = w - x - 12f
        val sp = paint(ctx, 800, 13f, TEXT)
        fit(sp, s.swipeNow, room)
        val ap = paint(ctx, 600, 11f, MUTED)
        fit(ap, s.about, room)
        val h1 = normalH(sp)
        val h2 = normalH(ap)
        val top = cy - (h1 + 2f + h2) / 2f
        c.line(s.swipeNow, x, top, h1, sp)
        c.line(s.about, x, top + h1 + 2f, h2, ap)
        return bmp
    }

    /// 2x1: label, number and the caption on one line.
    private fun canFreeWide(ctx: Context, s: WidgetState, w0: Float, h0: Float, dp: Float): Bitmap {
        val (bmp, c) = base(w0, h0, dp, false)
        val k = min(w0 / 170f, h0 / 100f).coerceIn(.7f, 1.3f)
        c.scale(k, k)
        val w = w0 / k
        val inner = w - 36f
        val lp = paint(ctx, 700, 12f, MUTED, 1.5f)
        fit(lp, s.canFree, inner)
        val cp = paint(ctx, 600, 12f, MUTED)
        fit(cp, s.tapMap, inner)
        val bp = paint(ctx, 800, 30f, TEXT, -1.2f)
        val up = paint(ctx, 800, 15f, BRAND)
        val total = normalH(lp) + 2f + 30f + 2f + normalH(cp)
        var top = (h0 / k - total) / 2f
        c.line(s.canFree, 18f, top, normalH(lp), lp)
        top += normalH(lp) + 2f
        val num = s.canFreeNum ?: "-"
        c.line(num, 18f, top, 30f, bp)
        c.line(" " + s.canFreeUnit, 18f + bp.measureText(num) + bp.letterSpacing * bp.textSize, top, 30f, up)
        top += 30f + 2f
        c.line(s.tapMap, 18f, top, normalH(cp), cp)
        return bmp
    }
}
