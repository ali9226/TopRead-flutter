package com.topread.novel

import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.VideoController
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.NativeAdFactory
import kotlin.math.roundToInt

/** 短篇正文中接近沉浸式视频卡片的原生高级广告。 */
class ShortStoryNativeAdFactory(
    private val layoutInflater: LayoutInflater,
    private val layoutChannel: MethodChannel,
) : NativeAdFactory {
    /** 原生广告槽位最近一次加载的媒体素材状态。 */
    private data class NativeAdMediaState(
        val layoutToken: Int,
        val hasVideoContent: Boolean,
    )

    /** 供 Flutter 主动查询的媒体素材状态，解决平台视图回调时序竞争。 */
    private val mediaStateBySlotId = mutableMapOf<String, NativeAdMediaState>()

    init {
        layoutChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getNativeAdMediaType" -> {
                    val slotId = call.argument<String>("slotId")
                    val layoutToken = call.argument<Number>("layoutToken")?.toInt()
                    val mediaState = slotId?.let(mediaStateBySlotId::get)
                    result.success(
                        mediaState
                            ?.takeIf { it.layoutToken == layoutToken }
                            ?.hasVideoContent,
                    )
                }

                "clearNativeAdMediaState" -> {
                    call.argument<String>("slotId")?.let(mediaStateBySlotId::remove)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * 创建原生高级广告视图。
     *
     * 由 Google AdMob SDK 在广告加载成功后回调。
     * 布局文件为 [R.layout.short_story_native_ad]，主题色通过 [applyTheme] 动态设置。
     *
     * @param nativeAd AdMob 返回的广告数据对象。
     * @param customOptions Flutter 端传入的自定义选项，包含 isDark（是否夜间模式）。
     * @return 渲染完成的 [NativeAdView]。
     */
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.short_story_native_ad,
            null,
        ) as NativeAdView
        // 从 Flutter 端获取夜间模式标志。
        val isDark = customOptions?.get("isDark") as? Boolean ?: false
        // 本地化广告归因文案，缺失时使用 Google 认可的默认值。
        val advertisementLabel =
            customOptions?.get("advertisementLabel") as? String ?: "Ad"
        // 原生端按 Flutter 卡片宽度测量真实高度所需的布局参数。
        val slotId = customOptions?.get("slotId") as? String
        val cardWidth = (customOptions?.get("cardWidth") as? Number)?.toDouble()
        val layoutToken = (customOptions?.get("layoutToken") as? Number)?.toInt()
        // 从 Flutter 端获取随机颜色
        val tagColorRed = (customOptions?.get("tagColorRed") as? Number)?.toInt() ?: 255
        val tagColorGreen = (customOptions?.get("tagColorGreen") as? Number)?.toInt() ?: 77
        val tagColorBlue = (customOptions?.get("tagColorBlue") as? Number)?.toInt() ?: 77

        adView.findViewById<TextView>(R.id.ad_attribution).apply {
            text = advertisementLabel
            setTextColor(Color.rgb(tagColorRed, tagColorGreen, tagColorBlue))
            (background as? android.graphics.drawable.GradientDrawable)?.setColor(
                Color.argb(38, tagColorRed, tagColorGreen, tagColorBlue)
            )
        }

        // 获取广告布局中的各视图组件。
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        val callToActionView = adView.findViewById<TextView>(R.id.ad_call_to_action)

        // 将视图绑定到 NativeAdView（AdMob 点击追踪所需）。
        adView.mediaView = mediaView
        adView.adChoicesView = adView.findViewById<AdChoicesView>(R.id.ad_choices)
        adView.headlineView = headlineView
        adView.advertiserView = advertiserView
        adView.callToActionView = callToActionView

        // 填充广告数据到视图。
        mediaView.mediaContent = nativeAd.mediaContent
        mediaView.setImageScaleType(ImageView.ScaleType.CENTER_CROP)
        headlineView.text = nativeAd.headline
        bindOptionalText(advertiserView, nativeAd.advertiser)
        bindOptionalText(callToActionView, nativeAd.callToAction)

        // 遮罩层统一使用半透明黑色
        val overlayColor = Color.argb(204, 0, 0, 0)
        headlineView.setTextColor(Color.WHITE)
        advertiserView.setTextColor(Color.rgb(204, 204, 204))
        adView.findViewById<View>(R.id.ad_overlay).setBackgroundColor(overlayColor)

        // 视频静音播放
        nativeAd.mediaContent?.videoController?.mute(true)

        val hasVideoContent = nativeAd.mediaContent?.hasVideoContent() == true
        reportMediaType(
            hasVideoContent = hasVideoContent,
            slotId = slotId,
            layoutToken = layoutToken,
        )
        monitorVideoPlayback(
            nativeAd = nativeAd,
            hasVideoContent = hasVideoContent,
            slotId = slotId,
            layoutToken = layoutToken,
        )

        // Debug 模式下同步保留原生端日志，便于排查平台视图问题。
        if (BuildConfig.DEBUG) {
            val mediaType = if (hasVideoContent) {
                "视频广告"
            } else {
                "图片广告"
            }
            Log.d(
                "ShortStoryNativeAd",
                "广告素材类型: $mediaType",
            )
        }

        // 将广告数据绑定到视图（必须调用，否则点击和展示追踪不生效）。
        adView.setNativeAd(nativeAd)

        // 视频自动播放（setNativeAd 后调用）
        if (hasVideoContent) {
            nativeAd.mediaContent?.videoController?.play()
        }

        reportMeasuredHeight(
            adView = adView,
            cardWidthDp = cardWidth,
            slotId = slotId,
            layoutToken = layoutToken,
        )
        return adView
    }

    /** 将广告的媒体素材类型回传 Flutter 日志层。 */
    private fun reportMediaType(
        hasVideoContent: Boolean,
        slotId: String?,
        layoutToken: Int?,
    ) {
        if (slotId == null || layoutToken == null) return
        mediaStateBySlotId[slotId] = NativeAdMediaState(
            layoutToken = layoutToken,
            hasVideoContent = hasVideoContent,
        )
        Handler(Looper.getMainLooper()).post {
            layoutChannel.invokeMethod(
                "onNativeAdMediaType",
                mapOf(
                    "slotId" to slotId,
                    "hasVideoContent" to hasVideoContent,
                    "layoutToken" to layoutToken,
                ),
            )
        }
    }

    /** 监听视频真实的播放、暂停、结束和静音状态。 */
    private fun monitorVideoPlayback(
        nativeAd: NativeAd,
        hasVideoContent: Boolean,
        slotId: String?,
        layoutToken: Int?,
    ) {
        if (!hasVideoContent || slotId == null || layoutToken == null) return
        val videoController = nativeAd.mediaContent?.videoController ?: return
        videoController.setVideoLifecycleCallbacks(
            object : VideoController.VideoLifecycleCallbacks() {
                override fun onVideoStart() {
                    reportVideoPlayback(
                        playbackState = "started",
                        isMuted = videoController.isMuted,
                        slotId = slotId,
                        layoutToken = layoutToken,
                    )
                }

                override fun onVideoPlay() {
                    reportVideoPlayback(
                        playbackState = "playing",
                        isMuted = videoController.isMuted,
                        slotId = slotId,
                        layoutToken = layoutToken,
                    )
                }

                override fun onVideoPause() {
                    reportVideoPlayback(
                        playbackState = "paused",
                        isMuted = videoController.isMuted,
                        slotId = slotId,
                        layoutToken = layoutToken,
                    )
                }

                override fun onVideoEnd() {
                    reportVideoPlayback(
                        playbackState = "ended",
                        isMuted = videoController.isMuted,
                        slotId = slotId,
                        layoutToken = layoutToken,
                    )
                }

                override fun onVideoMute(isMuted: Boolean) {
                    reportVideoPlayback(
                        playbackState = if (isMuted) "muted" else "unmuted",
                        isMuted = isMuted,
                        slotId = slotId,
                        layoutToken = layoutToken,
                    )
                }
            },
        )
    }

    /** 将视频播放状态回传 Flutter 日志层。 */
    private fun reportVideoPlayback(
        playbackState: String,
        isMuted: Boolean,
        slotId: String,
        layoutToken: Int,
    ) {
        layoutChannel.invokeMethod(
            "onNativeAdVideoPlayback",
            mapOf(
                "slotId" to slotId,
                "playbackState" to playbackState,
                "isMuted" to isMuted,
                "layoutToken" to layoutToken,
            ),
        )
    }

    /** 使用实际标题行数测量卡片高度，并回传 Flutter 更新平台视图尺寸。 */
    private fun reportMeasuredHeight(
        adView: NativeAdView,
        cardWidthDp: Double?,
        slotId: String?,
        layoutToken: Int?,
    ) {
        val resolvedCardWidth = cardWidthDp?.takeIf { it.isFinite() && it > 0 } ?: return
        if (slotId == null || layoutToken == null) return

        val density = adView.resources.displayMetrics.density
        val widthPx = (resolvedCardWidth * density).roundToInt().coerceAtLeast(1)
        adView.measure(
            View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        )
        val measuredHeightDp = adView.measuredHeight.toDouble() / density.toDouble()
        if (!measuredHeightDp.isFinite() || measuredHeightDp <= 0) return

        Handler(Looper.getMainLooper()).post {
            layoutChannel.invokeMethod(
                "onNativeAdLayout",
                mapOf(
                    "slotId" to slotId,
                    "viewHeight" to measuredHeightDp,
                    "layoutToken" to layoutToken,
                ),
            )
        }
    }

    /**
     * 绑定可选文本到 TextView，值为空时隐藏视图。
     *
     * @param view 目标 TextView。
     * @param value 要显示的文本，null 或空白时隐藏。
     */
    private fun bindOptionalText(view: TextView, value: String?) {
        view.text = value
        view.visibility = if (value.isNullOrBlank()) View.GONE else View.VISIBLE
    }

}
