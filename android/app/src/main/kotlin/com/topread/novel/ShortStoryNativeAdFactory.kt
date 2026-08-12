package com.topread.novel

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/** 短篇正文中接近沉浸式视频卡片的原生高级广告。 */
class ShortStoryNativeAdFactory(
    private val layoutInflater: LayoutInflater,
) : NativeAdFactory {
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
        // 根据日间/夜间模式设置广告卡片颜色。
        applyTheme(adView, isDark)

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

        // Debug 模式下输出视频信息日志。
        if (BuildConfig.DEBUG) {
            Log.d(
                "ShortStoryNativeAd",
                "media hasVideoContent=${nativeAd.mediaContent?.hasVideoContent() == true}",
            )
        }

        // 将广告数据绑定到视图（必须调用，否则点击和展示追踪不生效）。
        adView.setNativeAd(nativeAd)
        return adView
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

    /**
     * 根据日间/夜间模式应用广告卡片主题色。
     *
     * 颜色与 Flutter 端 [ColorConstants] 保持一致，修改时需同步更新：
     * - Flutter: lib/config/color_config.dart
     * - iOS: ios/Runner/AppDelegate.swift (ShortStoryNativeAdFactory)
     *
     * @param adView 广告视图容器。
     * @param isDark 是否为夜间模式。
     */
    private fun applyTheme(adView: NativeAdView, isDark: Boolean) {
        // 广告卡片背景色：夜间 #1E2430，日间对应 ColorConstants.whiteColor (#FFFFFF)。
        val cardColor = if (isDark) Color.rgb(30, 36, 48) else Color.WHITE
        // 主要文字颜色：夜间白色，日间对应 ColorConstants.lightTextColor (#222222)。
        val primaryColor = if (isDark) Color.WHITE else Color.rgb(34, 34, 34)
        // 次要文字颜色：夜间 #B0B5C0，日间 #7E7660。
        val secondaryColor = if (isDark) Color.rgb(176, 181, 192) else Color.rgb(126, 118, 96)
        val density = adView.resources.displayMetrics.density

        // 卡片整体圆角背景。
        adView.background = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = 16f * density
            setColor(cardColor)
        }
        // 标题文字颜色。
        adView.findViewById<TextView>(R.id.ad_headline).setTextColor(primaryColor)
        // 广告主文字颜色。
        adView.findViewById<TextView>(R.id.ad_advertiser).setTextColor(secondaryColor)
        // Open 按钮：背景色对应 ColorConstants.themeColor (#F8D02D)，
        // 文字色对应 ColorConstants.lightTextColor (#222222)。
        adView.findViewById<TextView>(R.id.ad_call_to_action).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 23f * density
                setColor(Color.rgb(248, 208, 45))
            }
            setTextColor(Color.rgb(34, 34, 34))
        }
    }
}
