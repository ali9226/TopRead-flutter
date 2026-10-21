package com.topread.novel

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import me.leolin.shortcutbadger.ShortcutBadger

class MainActivity : FlutterActivity() {
    companion object {
        private const val BADGE_CHANNEL_NAME = "com.topread.app/badge"
        private const val SET_BADGE_COUNT_METHOD = "setBadgeCount"
        private const val MASONRY_NATIVE_AD_LAYOUT_CHANNEL_NAME =
            "com.topread.novel/masonry_native_ad_layout"
        private const val SHORT_STORY_NATIVE_AD_LAYOUT_CHANNEL_NAME =
            "com.topread.novel/short_story_native_ad_layout"
        private const val MASONRY_NATIVE_AD_FACTORY_ID = "masonryNativeAdCard"
        private const val SHORT_STORY_NATIVE_AD_FACTORY_ID = "shortStoryNativeAdCard"
    }

    private var advertisingInfoChannel: AdvertisingInfoChannel? = null
    private var readerBrightnessChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            MASONRY_NATIVE_AD_FACTORY_ID,
            MasonryNativeAdFactory(
                layoutInflater,
                MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    MASONRY_NATIVE_AD_LAYOUT_CHANNEL_NAME,
                ),
            ),
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            SHORT_STORY_NATIVE_AD_FACTORY_ID,
            ShortStoryNativeAdFactory(
                layoutInflater,
                MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    SHORT_STORY_NATIVE_AD_LAYOUT_CHANNEL_NAME,
                ),
            ),
        )

        advertisingInfoChannel = AdvertisingInfoChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext,
        )

        // 仅使用当前 Activity 的窗口亮度，不修改系统亮度，也不需要写系统设置权限。
        readerBrightnessChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.topread.novel/reader_brightness",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBrightness" -> {
                        val override = window.attributes.screenBrightness
                        val systemBrightness = Settings.System.getInt(
                            contentResolver, Settings.System.SCREEN_BRIGHTNESS, 128,
                        ) / 255.0
                        result.success(mapOf(
                            "brightness" to if (override >= 0) override.toDouble() else systemBrightness,
                            "override" to override.toDouble(),
                        ))
                    }
                    "setBrightness", "restoreBrightness" -> {
                        val value = call.argument<Number>("value")?.toDouble()
                        if (value == null || !value.isFinite()) {
                            result.error("invalid_brightness", "Brightness must be finite.", null)
                        } else {
                            val attributes = window.attributes
                            attributes.screenBrightness = if (value < 0) -1f else value.coerceIn(0.01, 1.0).toFloat()
                            window.attributes = attributes
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

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

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            MASONRY_NATIVE_AD_FACTORY_ID,
        )
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            SHORT_STORY_NATIVE_AD_FACTORY_ID,
        )
        readerBrightnessChannel?.setMethodCallHandler(null)
        readerBrightnessChannel = null
        advertisingInfoChannel?.dispose()
        advertisingInfoChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
