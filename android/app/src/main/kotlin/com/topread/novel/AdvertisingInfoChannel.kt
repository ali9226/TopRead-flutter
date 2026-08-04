package com.topread.novel

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/** 向 Flutter 调试页面提供 Android GAID 及限制广告跟踪状态。 */
class AdvertisingInfoChannel(
    messenger: BinaryMessenger,
    context: Context,
) {
    companion object {
        private const val CHANNEL_NAME = "com.topread.novel/advertising_info"
        private const val GET_ADVERTISING_ID_METHOD = "getAdvertisingId"
        private const val IS_LIMIT_AD_TRACKING_ENABLED_METHOD =
            "isLimitAdTrackingEnabled"
    }

    private val applicationContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, CHANNEL_NAME)

    init {
        channel.setMethodCallHandler(::handleMethodCall)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GET_ADVERTISING_ID_METHOD -> loadAdvertisingInfo(result) { info ->
                info.id
            }

            IS_LIMIT_AD_TRACKING_ENABLED_METHOD -> loadAdvertisingInfo(result) { info ->
                info.isLimitAdTrackingEnabled
            }

            else -> result.notImplemented()
        }
    }

    /** AdvertisingIdClient 不得在主线程调用。 */
    private fun loadAdvertisingInfo(
        result: MethodChannel.Result,
        valueSelector: (AdvertisingIdClient.Info) -> Any?,
    ) {
        thread(name = "topread-advertising-info") {
            try {
                val info = AdvertisingIdClient.getAdvertisingIdInfo(applicationContext)
                val value = valueSelector(info)
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                mainHandler.post {
                    result.error(
                        "advertising_info_unavailable",
                        error.localizedMessage,
                        error.javaClass.canonicalName,
                    )
                }
            }
        }
    }
}
