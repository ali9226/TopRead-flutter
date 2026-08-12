import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app/config/font_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';

/// 原生高级广告横幅组件。
///
/// 使用 Google AdMob 原生高级广告格式，在正文段落间内嵌展示。
/// 加载成功后自动渲染广告视图，加载失败或未加载时返回空占位。
/// 广告自动静音播放。
class NativeAdBanner extends StatefulWidget {
  /// 广告单元 ID（由后端接口 ads/short_story_read_show_ads 返回）。
  final String ad_unit_id;

  /// 广告配置的唯一标识，用于服务器端验证。
  final String uuid;

  /// 是否为夜间模式（影响广告容器背景色）。
  final bool is_dark;

  const NativeAdBanner({
    super.key,
    required this.ad_unit_id,
    required this.uuid,
    required this.is_dark,
  });

  @override
  State<NativeAdBanner> createState() => _NativeAdBannerState();
}

class _NativeAdBannerState extends State<NativeAdBanner> {
  static const String _log_prefix = '[NativeAdBanner]';

  /// 原生广告控制器。
  NativeAd? _native_ad;

  /// 广告是否已加载完成。
  bool _is_ad_loaded = false;

  /// 异步加载代次，防止广告 ID 变化或组件销毁后旧任务回写状态。
  int _load_generation = 0;

  /// 广告视图高度（AdMob 原生广告渲染后自适应高度）。
  static const double _ad_height = 320.0;

  /// 广告区域顶部间距。
  static const double _spacing_top = 12.0;

  /// 广告区域底部间距。
  static const double _spacing_bottom = 16.0;

  /// 提示文字与广告之间的间距。
  static const double _hint_spacing = 18.0;

  /// 提示文字字号。
  static const double _hint_font_size = 12.0;

  /// 提示文字行高。
  static const double _hint_height = 1.4;

  /// 广告区域水平内边距（使广告宽度略窄于正文）。
  static const double _ad_horizontal_padding = 12.0;

  @override
  void initState() {
    super.initState();
    AdMobConsentPermissionRequest.privacy_choice_revision.addListener(
      _on_privacy_choice_changed,
    );
    unawaited(_load_native_ad());
  }

  @override
  void didUpdateWidget(NativeAdBanner old_widget) {
    super.didUpdateWidget(old_widget);
    // 广告单元 ID 变化时重新加载。
    if (old_widget.ad_unit_id != widget.ad_unit_id) {
      _dispose_ad();
      unawaited(_load_native_ad());
    }
  }

  @override
  void dispose() {
    AdMobConsentPermissionRequest.privacy_choice_revision.removeListener(
      _on_privacy_choice_changed,
    );
    _dispose_ad();
    super.dispose();
  }

  /// 用户修改广告隐私选择后释放旧广告，并按最新 UMP 结果重新尝试。
  void _on_privacy_choice_changed() {
    _dispose_ad();
    if (!mounted) return;
    setState(() {});
    unawaited(_load_native_ad());
  }

  /// 销毁广告控制器。
  void _dispose_ad() {
    _load_generation += 1;
    _native_ad?.dispose();
    _native_ad = null;
    _is_ad_loaded = false;
  }

  /// 加载 Google AdMob 原生高级广告。
  ///
  /// 使用 NativeAd 格式，在正文段落间内嵌展示。
  /// 加载完成后通过 setState 触发重建，渲染 AdWidget。
  Future<void> _load_native_ad() async {
    if (widget.ad_unit_id.isEmpty) {
      _log('ad_unit_id 为空，跳过加载');
      return;
    }

    final int generation = ++_load_generation;
    try {
      // 全 App 的所有广告位共享同一个 UMP 门禁和 SDK 初始化 Future。
      // 未来首页瀑布流同时创建多个广告卡片时也不会重复弹窗。
      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!is_initialized || !mounted || generation != _load_generation) {
        _log('UMP 未允许广告请求或组件已失效，跳过加载');
        return;
      }

      _log('开始加载原生广告, adUnitId=${widget.ad_unit_id}');

      final NativeAd native_ad = NativeAd(
        adUnitId: widget.ad_unit_id,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            _log('原生广告加载成功, responseId=${ad.responseInfo?.responseId}');
            if (mounted &&
                generation == _load_generation &&
                identical(_native_ad, ad)) {
              setState(() {
                _is_ad_loaded = true;
              });
            } else {
              ad.dispose();
            }
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _log(
              '原生广告加载失败: code=${error.code}, '
              'domain=${error.domain}, message=${error.message}',
              type: 'w',
            );
            ad.dispose();
            if (mounted && generation == _load_generation) {
              setState(() {
                _native_ad = null;
                _is_ad_loaded = false;
              });
            }
          },
          onAdOpened: (Ad ad) => _log('原生广告被点击'),
          onAdClosed: (Ad ad) => _log('原生广告被关闭'),
          onAdImpression: (Ad ad) => _log('原生广告展示'),
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: widget.is_dark
              ? const Color(0xFF1E2430)
              : const Color(0xFFF8F9FA),
          cornerRadius: 8.0,
        ),
      );
      _native_ad = native_ad;

      _log('调用 NativeAd.load()...');
      await native_ad.load();
      _log('NativeAd.load() 调用完成');
    } catch (e, stack_trace) {
      _log('原生广告加载异常: $e\n$stack_trace', type: 'e');
      if (generation == _load_generation) {
        _native_ad?.dispose();
        _native_ad = null;
        _is_ad_loaded = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 广告未加载完成或加载失败时，完全隐藏（不占任何布局空间）。
    if (!_is_ad_loaded || _native_ad == null) {
      return const SizedBox.shrink();
    }

    /// 提示文字颜色（与正文次要文字颜色一致）。
    final Color hint_color = widget.is_dark
        ? const Color(0xFF8B8B9E)
        : const Color(0xFF999999);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: _spacing_top),
        // 原生广告容器。
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _ad_horizontal_padding,
          ),
          child: Container(
            height: _ad_height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: widget.is_dark
                  ? const Color(0xFF1E2430)
                  : const Color(0xFFF8F9FA),
            ),
            clipBehavior: Clip.antiAlias,
            child: AdWidget(ad: _native_ad!),
          ),
        ),
        const SizedBox(height: _hint_spacing),
        // 底部提示文字。
        Text(
          tr('short_story_read.swipe_to_continue'),
          style: TextStyle(
            fontSize: _hint_font_size,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            color: hint_color,
            height: _hint_height,
          ),
        ),
        const SizedBox(height: _spacing_bottom),
      ],
    );
  }

  /// 输出广告流程日志。
  void _log(String message, {String? type}) {
    logUtil(msg: '$_log_prefix $message', type: type);
  }
}
