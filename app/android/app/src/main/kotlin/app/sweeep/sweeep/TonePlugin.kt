package app.sweeep.sweeep

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.ln
import kotlin.math.exp
import kotlin.math.sin

/// Local tone generator for the Tools tab: a sine (steady, pulsing or sweeping)
/// streamed straight to an AudioTrack. No files, no network.
class TonePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var worker: Thread? = null

    @Volatile private var running = false
    @Volatile private var freq = 165.0
    @Volatile private var pulse = false
    @Volatile private var sweep = false
    @Volatile private var side = 0 // 0 both, 1 left, 2 right

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "app.sweeep/tone").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stop()
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                apply(call)
                start()
                result.success(null)
            }
            "update" -> {
                apply(call)
                result.success(null)
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun apply(call: MethodCall) {
        call.argument<Double>("freq")?.let { freq = it.coerceIn(20.0, 20000.0) }
        call.argument<Boolean>("pulse")?.let { pulse = it }
        call.argument<Boolean>("sweep")?.let { sweep = it }
        call.argument<Int>("side")?.let { side = it.coerceIn(0, 2) }
    }

    @Synchronized
    private fun start() {
        if (running) return
        running = true
        worker = Thread {
            val rate = 44100
            val minBuf = AudioTrack.getMinBufferSize(rate, AudioFormat.CHANNEL_OUT_STEREO, AudioFormat.ENCODING_PCM_16BIT)
            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(rate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                        .build(),
                )
                .setBufferSizeInBytes(maxOf(minBuf, 8192))
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()
            track.play()
            val frames = 1024
            val buf = ShortArray(frames * 2)
            var phase = 0.0
            var t = 0L
            var gain = 0.0 // eased towards the target so starts/stops do not click
            var gl = 1.0
            var gr = 1.0
            while (running) {
                for (i in 0 until frames) {
                    val sec = t.toDouble() / rate
                    // sweep: 20 Hz -> 20 kHz on a log scale over 12 s, then again
                    val f = if (sweep) 20.0 * exp(ln(1000.0) * ((sec % 12.0) / 12.0)) else freq
                    phase += 2 * PI * f / rate
                    if (phase > 2 * PI) phase -= 2 * PI
                    // pulse: a soft on/off at about 3 Hz
                    val env = if (pulse) 0.5 + 0.5 * sin(2 * PI * 3.0 * sec - PI / 2) else 1.0
                    gain += (1.0 - gain) * 0.0006
                    gl += ((if (side == 2) 0.0 else 1.0) - gl) * 0.002
                    gr += ((if (side == 1) 0.0 else 1.0) - gr) * 0.002
                    val s = sin(phase) * env * gain * 0.8
                    buf[i * 2] = (s * gl * Short.MAX_VALUE).toInt().toShort()
                    buf[i * 2 + 1] = (s * gr * Short.MAX_VALUE).toInt().toShort()
                    t++
                }
                if (track.write(buf, 0, buf.size) < 0) break
            }
            try {
                track.stop()
            } catch (_: IllegalStateException) {
            }
            track.release()
        }.also { it.isDaemon = true; it.start() }
    }

    @Synchronized
    private fun stop() {
        running = false
        worker?.join(500)
        worker = null
    }
}
