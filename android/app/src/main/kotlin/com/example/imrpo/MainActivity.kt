package com.yasmen.pocketly

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val methodChannelName = "imrpo/share_text"
    private val eventChannelName = "imrpo/share_text_events"

    private var pendingShareText: String? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialShareText" -> {
                    val text = pendingShareText
                    pendingShareText = null
                    result.success(text)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingShareText?.let { text ->
                        events?.success(text)
                        pendingShareText = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )

        deliverShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deliverShareIntent(intent)
    }

    private fun deliverShareIntent(intent: Intent?) {
        val text = extractShareText(intent) ?: return
        pendingShareText = text
        eventSink?.success(text)
    }

    private fun extractShareText(intent: Intent?): String? {
        if (intent == null) return null
        val action = intent.action ?: return null
        if (action != Intent.ACTION_SEND) return null
        if (intent.type != "text/plain") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()?.takeIf { it.isNotEmpty() }
    }
}
