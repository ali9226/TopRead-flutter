package com.topread.novel

import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import android.util.Log
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.NativeAdFactory
import kotlin.math.roundToInt

/** 为手机双列瀑布流创建单列宽度的纵向原生广告卡。 */
class MasonryNativeAdFactory(
    private val layoutInflater: LayoutInflater,
    private val layoutChannel: MethodChannel,
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.masonry_native_ad,
            null,
        ) as NativeAdView
        val palette = NativeAdPalette(customOptions)
        val advertisementLabel =
            customOptions?.get("advertisementLabel") as? String ?: "Ad"
        val slotId = customOptions?.get("slotId") as? String
        val cardWidth = (customOptions?.get("cardWidth") as? Number)?.toDouble()
        val layoutToken = (customOptions?.get("layoutToken") as? Number)?.toInt()
        applyTheme(adView, palette)
        adView.findViewById<TextView>(R.id.ad_attribution).text = advertisementLabel

        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        val mediaContainer = adView.findViewById<FrameLayout>(R.id.ad_media_container)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        val callToActionView = adView.findViewById<TextView>(R.id.ad_call_to_action)

        adView.mediaView = mediaView
        adView.adChoicesView = adView.findViewById<AdChoicesView>(R.id.ad_choices)
        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.advertiserView = advertiserView
        adView.callToActionView = callToActionView

        mediaView.mediaContent = nativeAd.mediaContent
        mediaView.setImageScaleType(android.widget.ImageView.ScaleType.FIT_CENTER)
        val density = adView.resources.displayMetrics.density
        val mediaAspectRatio = nativeAd.mediaContent?.aspectRatio
            ?.toDouble()
            ?.takeIf { it.isFinite() && it > 0 }
            ?: DEFAULT_MEDIA_ASPECT_RATIO
        val resolvedCardWidth = cardWidth
            ?.takeIf { it.isFinite() && it > 0 }
            ?: DEFAULT_CARD_WIDTH_DP
        val mediaHeightDp = (resolvedCardWidth / mediaAspectRatio)
            .coerceIn(MIN_MEDIA_HEIGHT_DP, MAX_MEDIA_HEIGHT_DP)
        mediaContainer.layoutParams = mediaContainer.layoutParams.apply {
            height = (mediaHeightDp * density).roundToInt()
        }
        if (BuildConfig.DEBUG) {
            Log.d(
                "MasonryNativeAd",
                "media hasVideoContent=${nativeAd.mediaContent?.hasVideoContent() == true}",
            )
        }
        headlineView.text = nativeAd.headline
        bindOptionalText(bodyView, nativeAd.body)
        bindOptionalText(advertiserView, nativeAd.advertiser)
        bindOptionalText(callToActionView, nativeAd.callToAction)

        // 所有素材注册完成后再关联 NativeAd，由 SDK 统一处理点击、
        // 曝光、AdChoices 和广告报告入口。
        adView.setNativeAd(nativeAd)
        reportMeasuredHeight(
            adView = adView,
            cardWidthDp = resolvedCardWidth,
            slotId = slotId,
            layoutToken = layoutToken,
        )
        return adView
    }

    /** 使用实际素材和文案测量卡片，回传 Flutter 后驱动瀑布流重排。 */
    private fun reportMeasuredHeight(
        adView: NativeAdView,
        cardWidthDp: Double,
        slotId: String?,
        layoutToken: Int?,
    ) {
        if (slotId == null || layoutToken == null) return
        val density = adView.resources.displayMetrics.density
        val widthPx = (cardWidthDp * density).roundToInt().coerceAtLeast(1)
        adView.measure(
            View.MeasureSpec.makeMeasureSpec(widthPx, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
        )
        val measuredHeightDp = adView.measuredHeight / density
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

    private fun bindOptionalText(view: TextView, value: String?) {
        if (value.isNullOrBlank()) {
            view.visibility = View.GONE
            return
        }
        view.text = value
        view.visibility = View.VISIBLE
    }

    private fun applyTheme(adView: NativeAdView, palette: NativeAdPalette) {
        adView.background = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = 18f * adView.resources.displayMetrics.density
            setColor(palette.color("card_background"))
        }
        adView.findViewById<TextView>(R.id.ad_attribution).apply {
            setTextColor(palette.color("attribution_text"))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 999f * adView.resources.displayMetrics.density
                setColor(palette.color("attribution_background"))
            }
        }
        adView.findViewById<TextView>(R.id.ad_headline)
            .setTextColor(palette.color("primary_text"))
        adView.findViewById<TextView>(R.id.ad_body)
            .setTextColor(palette.color("secondary_text"))
        adView.findViewById<TextView>(R.id.ad_advertiser).apply {
            setTextColor(palette.color("advertiser_text"))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 999f * adView.resources.displayMetrics.density
                setColor(palette.color("advertiser_background"))
            }
        }
        adView.findViewById<TextView>(R.id.ad_call_to_action).apply {
            setTextColor(palette.color("cta_text"))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 10f * adView.resources.displayMetrics.density
                setColor(palette.color("cta_background"))
            }
        }
    }

    private companion object {
        const val DEFAULT_CARD_WIDTH_DP = 180.0
        const val DEFAULT_MEDIA_ASPECT_RATIO = 1.0
        const val MIN_MEDIA_HEIGHT_DP = 120.0
        const val MAX_MEDIA_HEIGHT_DP = 320.0
    }
}
