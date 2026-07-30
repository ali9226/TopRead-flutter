package com.topread.novel

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import me.leolin.shortcutbadger.ShortcutBadger

class MainActivity : FlutterActivity() {
    companion object {
        private const val BADGE_CHANNEL_NAME = "com.topread.app/badge"
        private const val SET_BADGE_COUNT_METHOD = "setBadgeCount"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BADGE_CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            if (call.method != SET_BADGE_COUNT_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val count = call.argument<Int>("count")
            if (count == null) {
                result.error(
                    "invalid_badge_count",
                    "Badge count must be an integer.",
                    null,
                )
                return@setMethodCallHandler
            }

            val normalizedCount = count.coerceAtLeast(0)
            try {
                if (normalizedCount == 0) {
                    ShortcutBadger.removeCount(applicationContext)
                } else {
                    ShortcutBadger.applyCount(applicationContext, normalizedCount)
                }
                result.success(null)
            } catch (error: Exception) {
                result.error(
                    "badge_update_failed",
                    error.message,
                    null,
                )
            }
        }
    }
}
