package app.sweeep.sweeep

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        takeWidgetAction(intent)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        takeWidgetAction(intent)
        WidgetsPlugin.notifyAction()
    }

    private fun takeWidgetAction(i: android.content.Intent?) {
        i?.getStringExtra(WidgetActions.EXTRA)?.let {
            WidgetActions.pending = it
            i.removeExtra(WidgetActions.EXTRA) // a recreated activity must not replay the tap
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MediaPlugin())
        flutterEngine.plugins.add(TonePlugin())
        flutterEngine.plugins.add(ScanServicePlugin())
        flutterEngine.plugins.add(ReminderPlugin())
        flutterEngine.plugins.add(ImageSaverPlugin())
        flutterEngine.plugins.add(SystemPlugin())
        flutterEngine.plugins.add(AppsPlugin())
        flutterEngine.plugins.add(WidgetsPlugin())
    }
}
