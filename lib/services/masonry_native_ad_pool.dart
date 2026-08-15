// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/masonry_ad_config_service.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';

/// 接收原生端根据实际素材与文案测量出的广告卡片高度。
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

/// 单个瀑布流广告槽位的进程级控制器。
///
/// [NativeAd] 不绑定任何页面 State。页面离开时只卸载
/// AdWidget，广告对象仍由该控制器保留，回到页面时不会
/// 重新请求或替换素材。
class MasonryNativeAdController extends ChangeNotifier {
  MasonryNativeAdController({required this.slot_id}) {
    _MasonryNativeAdLayoutBridge.register(slot_id, _on_layout_measured);
    AdMobConsentPermissionRequest.privacy_choice_revision.addListener(
      _on_privacy_choice_changed,
    );
  }

  /// 当前广告槽位的全局唯一 ID。
  final String slot_id;

  NativeAd? _native_ad;
  bool _is_ad_loaded = false;
  bool _is_loading = false;
  bool _has_attempted = false;
  bool _is_disposed = false;
  int _load_generation = 0;
  double? _requested_card_width;
  bool? _requested_is_dark;
  String? _requested_advertisement_label;
  double _native_view_height = RecommendBookCardStyle.native_ad_fallback_height;

  /// 已加载且可以挂载到 AdWidget 的原生广告。
  NativeAd? get native_ad => _is_ad_loaded ? _native_ad : null;

  /// 原生端针对当前列宽测得的卡片高度。
  double get native_view_height => _native_view_height;

  /// 当前广告加载代次，用于隔离失效的原生回调。
  int get load_generation => _load_generation;

  /// 确保当前槽位只为给定的展示条件加载一次广告。
  void ensure_loaded({
    required double card_width,
    required bool is_dark,
    required String advertisement_label,
  }) {
    if (_is_disposed || !card_width.isFinite || card_width <= 0) return;

    final bool presentation_unchanged =
        _requested_card_width != null &&
        (_requested_card_width! - card_width).abs() < 0.5 &&
        _requested_is_dark == is_dark &&
        _requested_advertisement_label == advertisement_label;

    if (presentation_unchanged &&
        (_is_loading || _is_ad_loaded || _has_attempted)) {
      return;
    }

    _replace_ad();
    _requested_card_width = card_width;
    _requested_is_dark = is_dark;
    _requested_advertisement_label = advertisement_label;
    _has_attempted = true;
    _is_loading = true;
    unawaited(
      _load_native_ad(
        card_width: card_width,
        is_dark: is_dark,
        advertisement_label: advertisement_label,
      ),
    );
  }

  /// 隐私选择变更后废弃旧广告，由当前可见卡片触发新请求。
  void _on_privacy_choice_changed() {
    if (_is_disposed) return;
    _replace_ad();
    _has_attempted = false;
    notifyListeners();
  }

  /// 原生广告视图创建后保存实际高度，供页面重建时直接复用。
  void _on_layout_measured(double height, int token) {
    if (_is_disposed || token != _load_generation) return;
    if ((_native_view_height - height).abs() < 0.5) return;
    _native_view_height = height;
    notifyListeners();
  }

  Future<void> _load_native_ad({
    required double card_width,
    required bool is_dark,
    required String advertisement_label,
  }) async {
    final int generation = ++_load_generation;

    try {
      // 每个新槽位独立请求后端配置，不共享上一批数据的结果。
      final AdConfig? ad_config =
          await MasonryAdConfigService.get_google_ad_config();
      if (!_is_current(generation) || ad_config == null) {
        _finish_without_ad(generation);
        return;
      }

      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!_is_current(generation) || !is_initialized) {
        _log('UMP 未允许广告请求或槽位已失效，跳过加载');
        _finish_without_ad(generation);
        return;
      }

      late final NativeAd native_ad;
      native_ad = NativeAd(
        adUnitId: ad_config.adsId,
        factoryId: 'masonryNativeAdCard',
        customOptions: <String, Object>{
          'isDark': is_dark,
          'advertisementLabel': advertisement_label,
          'slotId': slot_id,
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
            if (_is_current(generation) && identical(_native_ad, ad)) {
              _is_loading = false;
              _is_ad_loaded = true;
              notifyListeners();
              return;
            }
            ad.dispose();
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _log(
              '原生广告加载失败: code=${error.code}, '
              'domain=${error.domain}, message=${error.message}',
              type: 'w',
            );
            ad.dispose();
            if (_is_current(generation)) {
              _native_ad = null;
              _is_loading = false;
              _is_ad_loaded = false;
              notifyListeners();
            }
          },
          onAdClicked: (Ad ad) => _log('原生广告被点击'),
          onAdOpened: (Ad ad) => _log('原生广告打开落地页'),
          onAdClosed: (Ad ad) => _log('原生广告落地页关闭'),
          onAdImpression: (Ad ad) => _log('原生广告展示'),
        ),
      );

      if (!_is_current(generation)) {
        native_ad.dispose();
        return;
      }

      _native_ad = native_ad;
      _log('开始加载独立原生广告, configUuid=${ad_config.uuid}');
      await native_ad.load();
    } catch (error, stack_trace) {
      _log('原生广告加载异常: $error\n$stack_trace', type: 'e');
      if (_is_current(generation)) {
        _replace_ad();
        notifyListeners();
      }
    }
  }

  bool _is_current(int generation) {
    return !_is_disposed && generation == _load_generation;
  }

  void _finish_without_ad(int generation) {
    if (!_is_current(generation)) return;
    _is_loading = false;
    _is_ad_loaded = false;
    notifyListeners();
  }

  void _replace_ad() {
    final NativeAd? previous_ad = _native_ad;
    _load_generation += 1;
    _native_ad = null;
    _is_ad_loaded = false;
    _is_loading = false;
    _native_view_height = RecommendBookCardStyle.native_ad_fallback_height;
    if (previous_ad != null) {
      // 先让当前帧卸载 AdWidget，再释放广告对象，避免
      // google_mobile_ads 内部残留“已挂载”的广告 ID。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_dispose_ad_safely(previous_ad));
      });
    }
  }

  Future<void> _dispose_ad_safely(NativeAd ad) async {
    try {
      await ad.dispose();
    } catch (error, stack_trace) {
      _log('释放原生广告异常: $error\n$stack_trace', type: 'e');
    }
  }

  @override
  void dispose() {
    if (_is_disposed) return;
    _is_disposed = true;
    _MasonryNativeAdLayoutBridge.unregister(slot_id);
    AdMobConsentPermissionRequest.privacy_choice_revision.removeListener(
      _on_privacy_choice_changed,
    );
    _replace_ad();
    super.dispose();
  }

  void _log(String message, {String? type}) {
    logUtil(msg: '[MasonryNativeAd:$slot_id] $message', type: type);
  }
}

/// 按广告槽位 ID 隔离的全局原生广告池。
class MasonryNativeAdPool {
  const MasonryNativeAdPool._();

  static final Map<String, MasonryNativeAdController> _controllers =
      <String, MasonryNativeAdController>{};

  /// 获取槽位对应的唯一广告控制器。
  static MasonryNativeAdController obtain(String slot_id) {
    return _controllers.putIfAbsent(
      slot_id,
      () => MasonryNativeAdController(slot_id: slot_id),
    );
  }

  /// 在语种刷新等明确废弃数据的场景中释放旧槽位。
  static void remove_all(Iterable<String> slot_ids) {
    for (final String slot_id in slot_ids.toSet()) {
      _controllers.remove(slot_id)?.dispose();
    }
  }

  /// 已保留的独立广告槽位数，仅供测试或调试。
  @visibleForTesting
  static int get controller_count => _controllers.length;
}
