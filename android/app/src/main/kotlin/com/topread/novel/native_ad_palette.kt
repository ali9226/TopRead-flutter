package com.topread.novel

/**
 * 解码 Flutter 统一调色板传来的 ARGB。
 *
 * 原生工厂仅负责视图布局，不再维护颜色或主题 fallback，避免两端色值漂移。
 */
internal class NativeAdPalette(customOptions: Map<String, Any>?) {
    private val colors = requireNotNull(customOptions?.get("palette") as? Map<*, *>) {
        "Native ads require ColorConstants.native_ad_palette from Flutter"
    }

    fun color(key: String): Int = requireNotNull(colors[key] as? Number) {
        "Missing native ad palette color: $key"
    }.toLong().toInt()
}
