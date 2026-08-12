// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/masonry_ad_config_service.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';

/// 接收原生端根据实际图片/视频比例和文字内容测量出的卡片高度。
class _MasonryNativeAdLayoutBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.topread.novel/masonry_native_ad_layout',
  );
  static final Map<String, void Function(double height, int token)> _listeners =
      <String, void Function(double height, int token)>{};
  static bool _is_initialized = false;

  static void register(
    String slot_id,
    void Function(double height, int token) listener,
  ) {
    _ensure_initialized();
    _listeners[slot_id] = listener;
  }

  static void unregister(String slot_id) {
    _listeners.remove(slot_id);
  }

  static void _ensure_initialized() {
    if (_is_initialized) return;
    _is_initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method != 'onNativeAdLayout') return;
      final Object? raw_arguments = call.arguments;
      if (raw_arguments is! Map<Object?, Object?>) return;

      final String? slot_id = raw_arguments['slotId'] as String?;
      final num? raw_height = raw_arguments['viewHeight'] as num?;
      final num? raw_token = raw_arguments['layoutToken'] as num?;
      if (slot_id == null || raw_height == null || raw_token == null) return;

      final double height = raw_height.toDouble();
      if (!height.isFinite || height <= 0) return;
      _listeners[slot_id]?.call(height, raw_token.toInt());
    });
  }
}

/// 今日推荐瀑布流内的 Google AdMob 原生高级广告卡片。
///
/// 每个广告槽位都拥有自己的 [NativeAd]，不在页面、Tab 或分页之间
/// 复用广告对象。全部槽位只共享进程级的后端配置和 UMP 门禁。
class MasonryNativeAdCard extends StatefulWidget {
  /// 当前瀑布流内的唯一槽位 ID，用于日志排查。
  final String slot_id;

  /// 是否为夜间模式。
  final bool is_dark;

  const MasonryNativeAdCard({
    super.key,
    required this.slot_id,
    required this.is_dark,
  });

  @override
  State<MasonryNativeAdCard> createState() => _MasonryNativeAdCardState();
}

class _MasonryNativeAdCardState extends State<MasonryNativeAdCard> {
  NativeAd? _native_ad;
  bool _is_ad_loaded = false;
  int _load_generation = 0;
  double? _requested_card_width;
  double _native_view_height = RecommendBookCardStyle.native_ad_fallback_height;

  String get _log_prefix => '[MasonryNativeAd:${widget.slot_id}]';

  @override
  void initState() {
    super.initState();
    _MasonryNativeAdLayoutBridge.register(
      widget.slot_id,
      _on_native_layout_measured,
    );
    AdMobConsentPermissionRequest.privacy_choice_revision.addListener(
      _on_privacy_choice_changed,
    );
  }

  @override
  void didUpdateWidget(MasonryNativeAdCard old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.slot_id != widget.slot_id) {
      _MasonryNativeAdLayoutBridge.unregister(old_widget.slot_id);
      _MasonryNativeAdLayoutBridge.register(
        widget.slot_id,
        _on_native_layout_measured,
      );
    }
    if (old_widget.is_dark != widget.is_dark) {
      _dispose_ad();
      final double? card_width = _requested_card_width;
      if (card_width != null) {
        unawaited(_load_native_ad(card_width: card_width));
      }
    }
  }

  @override
  void dispose() {
    _MasonryNativeAdLayoutBridge.unregister(widget.slot_id);
    AdMobConsentPermissionRequest.privacy_choice_revision.removeListener(
      _on_privacy_choice_changed,
    );
    _dispose_ad();
    super.dispose();
  }

  /// 用户修改 UMP 隐私选择后，释放旧广告并按最新许可重新请求。
  void _on_privacy_choice_changed() {
    _dispose_ad();
    if (!mounted) return;
    setState(() {});
    final double? card_width = _requested_card_width;
    if (card_width != null) {
      unawaited(_load_native_ad(card_width: card_width));
    }
  }

  /// 原生平台测量完成后，用真实高度驱动瀑布流重新排版。
  void _on_native_layout_measured(double height, int token) {
    if (!mounted || token != _load_generation) return;
    if ((_native_view_height - height).abs() < 0.5) return;
    setState(() => _native_view_height = height);
  }

  /// NativeAd 创建前必须知道当前列宽，才能按素材比例计算媒体高度。
  void _ensure_loaded_for_width(double card_width) {
    if (!card_width.isFinite || card_width <= 0) return;
    final double normalized_width = card_width;
    final double? previous_width = _requested_card_width;
    if (previous_width != null &&
        (previous_width - normalized_width).abs() < 0.5) {
      return;
    }
    _requested_card_width = normalized_width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requested_card_width != normalized_width) return;
      _dispose_ad();
      setState(() {});
      unawaited(_load_native_ad(card_width: normalized_width));
    });
  }

  void _dispose_ad() {
    _load_generation += 1;
    _native_ad?.dispose();
    _native_ad = null;
    _is_ad_loaded = false;
    _native_view_height = RecommendBookCardStyle.native_ad_fallback_height;
  }

  Future<void> _load_native_ad({required double card_width}) async {
    final int generation = ++_load_generation;

    try {
      // 每个槽位都会调用，但服务内部只会发起一次后端请求。
      final AdConfig? ad_config =
          await MasonryAdConfigService.get_google_ad_config();
      if (ad_config == null || !mounted || generation != _load_generation) {
        return;
      }

      // 全 App 的原生、激励和瀑布流广告共享同一个 UMP/SDK Future。
      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!is_initialized || !mounted || generation != _load_generation) {
        _log('UMP 未允许广告请求或槽位已失效，跳过加载');
        return;
      }

      late final NativeAd native_ad;
      native_ad = NativeAd(
        adUnitId: ad_config.adsId,
        // 原生工厂在 Android/iOS 上创建适合瀑布流单列宽度的纵向卡片。
        factoryId: 'masonryNativeAdCard',
        customOptions: <String, Object>{
          'isDark': widget.is_dark,
          'advertisementLabel': easy.tr('recommend_card.advertisement'),
          'slotId': widget.slot_id,
          'cardWidth': card_width,
          'layoutToken': generation,
        },
        request: const AdRequest(),
        nativeAdOptions: NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.topRightCorner,
          mediaAspectRatio: MediaAspectRatio.any,
          videoOptions: VideoOptions(startMuted: true),
        ),
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            _log('原生广告加载成功, responseId=${ad.responseInfo?.responseId}');
            if (mounted &&
                generation == _load_generation &&
                identical(_native_ad, ad)) {
              setState(() => _is_ad_loaded = true);
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
          onAdClicked: (Ad ad) => _log('原生广告被点击'),
          onAdOpened: (Ad ad) => _log('原生广告打开落地页'),
          onAdClosed: (Ad ad) => _log('原生广告落地页关闭'),
          onAdImpression: (Ad ad) => _log('原生广告展示'),
        ),
      );
      _native_ad = native_ad;

      _log('开始加载独立原生广告, configUuid=${ad_config.uuid}');
      await native_ad.load();
    } catch (error, stack_trace) {
      _log('原生广告加载异常: $error\n$stack_trace', type: 'e');
      if (generation == _load_generation) {
        _native_ad?.dispose();
        _native_ad = null;
        _is_ad_loaded = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _ensure_loaded_for_width(constraints.maxWidth);

        // 配置无效、UMP 不允许或广告无填充时不占据瀑布流空间。
        if (!_is_ad_loaded || _native_ad == null) {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: easy.tr('recommend_card.advertisement'),
          container: true,
          child: SizedBox(
            // iOS PlatformView 必须有明确尺寸；高度来自原生端对当前
            // 图片/视频比例及真实标题、简介、标签内容的测量结果。
            width: double.infinity,
            height: _native_view_height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                RecommendBookCardStyle.card_radius,
              ),
              child: AdWidget(ad: _native_ad!),
            ),
          ),
        );
      },
    );
  }

  void _log(String message, {String? type}) {
    logUtil(msg: '$_log_prefix $message', type: type);
  }
}
