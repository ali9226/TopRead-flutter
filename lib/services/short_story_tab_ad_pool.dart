// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/config/color_config.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/ad_impression_reporter.dart';
import 'package:app/services/feed_native_ad_policy.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:get/get.dart';
import 'package:app/services/short_story_tab_ad_config_service.dart';
import 'package:app/services/short_story_native_ad_layout_bridge.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';

/// 短篇列表广告默认高度。
///
/// 卡片固定250dp/pt，媒体铺满，遮罩层覆盖在底部。
/// 实际高度由原生端测量后回传。
const double short_story_tab_ad_fallback_height = 250.0;

/// 单个短篇列表广告槽位的进程级控制器。
///
/// 使用 [ShortStoryTabAdConfigService] 获取广告配置。
class ShortStoryTabAdController extends ChangeNotifier {
  ShortStoryTabAdController({required this.slot_id}) {
    ShortStoryNativeAdLayoutBridge.register(slot_id, _on_layout_measured);
    AdMobConsentPermissionRequest.privacy_choice_revision.addListener(
      _on_privacy_choice_changed,
    );
    _observe_config_store();
    if (Get.isRegistered<ProjectConfigStore>()) {
      _ad_policy_worker = ever(
        Get.find<ProjectConfigStore>().config_revision,
        (_) => _on_ad_policy_changed(),
      );
    }
  }

  /// 当前广告槽位的全局唯一 ID。
  final String slot_id;

  NativeAd? _native_ad;
  bool _is_ad_loaded = false;
  bool _is_loading = false;
  bool _has_attempted = false;
  bool _is_failed = false;
  bool _layout_is_measured = false;
  bool _is_expired = false;
  Timer? _retry_timer;
  Timer? _expiry_timer;
  Timer? _preparation_timer;
  Worker? _ad_policy_worker;
  Worker? _ad_config_worker;
  AdConfigStore? _observed_config_store;
  AdConfig? _selected_config;
  Object? _attachment_owner;
  bool _attachment_release_pending = false;
  bool _is_disposed = false;

  /// 即使槽位控制器被淘汰后重建，原生布局 token 也不会与旧素材碰撞。
  static int _next_layout_token = 0;
  int _load_generation = 0;
  double? _requested_card_width;
  String? _requested_advertisement_label;
  double _native_view_height = short_story_tab_ad_fallback_height;

  /// 已加载且可以挂载到 AdWidget 的原生广告。
  NativeAd? get native_ad => _is_ad_loaded ? _native_ad : null;

  /// 原生端针对当前列宽测得的卡片高度。
  double get native_view_height => _native_view_height;

  /// 当前广告加载代次，用于隔离失效的原生回调。
  int get load_generation => _load_generation;

  /// 当前请求是否已经启动，便于广告位区分 idle 与 loading。
  bool get has_attempted => _has_attempted;

  /// 配置、隐私门禁和 SDK 的任意加载阶段均处于 loading。
  bool get is_loading => _is_loading;

  /// 最近一次加载失败；冷却期间不会重新向 SDK 请求。
  bool get is_failed => _is_failed;

  /// 当前代次是否已收到原生真实尺寸，不能沿用上个素材的 fallback。
  bool get layout_is_measured => _layout_is_measured;

  /// 全局缓存只能淘汰已经没有页面引用和平台视图挂载的控制器。
  bool get _can_evict => !hasListeners && !has_attachment;

  /// 判断素材是否仍由某个平台视图持有，包括帧末卸载的过渡阶段。
  bool get has_attachment =>
      _attachment_owner != null || _attachment_release_pending;

  /// 仅允许一个页面实例挂载同一个 SDK 广告对象。
  bool claim_attachment(Object owner) {
    if (_is_disposed || native_ad == null || !_layout_is_measured) return false;
    if (identical(_attachment_owner, owner)) return true;
    if (_attachment_owner != null || _attachment_release_pending) return false;
    _attachment_owner = owner;
    return true;
  }

  /// 先完成旧 AdWidget 的卸载，再允许另一个页面接管素材。
  void release_attachment(Object owner) {
    if (_is_disposed || !identical(_attachment_owner, owner)) return;
    _attachment_owner = null;
    _attachment_release_pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_is_disposed) return;
      _attachment_release_pending = false;
      if (_is_expired) {
        _replace_ad();
        _has_attempted = false;
      }
      notifyListeners();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// 确保当前槽位只为给定的展示条件加载一次广告。
  void ensure_loaded({
    required double card_width,
    required bool is_dark,
    required String advertisement_label,
  }) {
    if (_is_disposed) return;
    _observe_config_store();
    if (!AdDisplayPolicy.can_show_ads() ||
        !card_width.isFinite ||
        card_width <= 0) {
      return;
    }

    final bool presentation_unchanged =
        _requested_card_width != null &&
        (_requested_card_width! - card_width).abs() <
            FeedNativeAdPolicy.layout_tolerance &&
        _requested_advertisement_label == advertisement_label;

    if (presentation_unchanged && _is_selected_config_current()) {
      if (_is_loading || (_is_ad_loaded && !_is_expired)) return;
      // 已经显示的广告继续保留，过期只影响尚未展示的缓存素材。
      if (_is_ad_loaded && _attachment_owner != null) return;
      if (_retry_timer != null) return;
    }

    _replace_ad();
    _requested_card_width = card_width;
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

  /// 支持启动阶段广告缓存仓库稍晚注册，始终只监听当前有效仓库。
  void _observe_config_store() {
    final AdConfigStore? store = Get.isRegistered<AdConfigStore>()
        ? Get.find<AdConfigStore>()
        : null;
    if (identical(store, _observed_config_store)) return;
    _ad_config_worker?.dispose();
    _observed_config_store = store;
    _ad_config_worker = store == null
        ? null
        : ever(store.config_revision, (_) => _on_ad_config_changed());
  }

  /// UUID、广告单元撤销或权重归零后即时废弃素材；有效权重调整仍复用。
  void _on_ad_config_changed() {
    if (_is_disposed) return;
    if (!_is_selected_config_current() ||
        (_selected_config == null && _is_failed)) {
      _replace_ad();
      _has_attempted = false;
      notifyListeners();
    }
  }

  /// 后台开关关闭时立刻失效素材和在途请求，重新开启时由页面重试。
  void _on_ad_policy_changed() {
    if (_is_disposed) return;
    if (!AdDisplayPolicy.can_show_ads()) {
      _replace_ad();
      _has_attempted = false;
    }
    notifyListeners();
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
    if (_is_disposed || token != _load_generation || _native_ad == null) return;
    if (!height.isFinite || height <= 0) return;
    final bool was_measured = _layout_is_measured;
    _layout_is_measured = true;
    _cancel_preparation_if_ready();
    if (was_measured &&
        (_native_view_height - height).abs() <
            FeedNativeAdPolicy.layout_tolerance) {
      return;
    }
    _native_view_height = height;
    notifyListeners();
  }

  Future<void> _load_native_ad({
    required double card_width,
    required bool is_dark,
    required String advertisement_label,
  }) async {
    final int generation = _load_generation = ++_next_layout_token;

    try {
      if (!AdDisplayPolicy.can_show_ads()) {
        _finish_without_ad(generation);
        return;
      }
      // 从 redis/get 本地缓存读取短篇列表专用广告配置。
      final AdConfig? ad_config =
          await ShortStoryTabAdConfigService.get_google_ad_config();
      if (!_is_current(generation) || ad_config == null) {
        _finish_without_ad(generation);
        return;
      }
      if (!AdDisplayPolicy.can_show_ads()) {
        _finish_without_ad(generation);
        return;
      }

      _selected_config = ad_config;
      // 先等待用户完成必要的 UMP 表单，再为 SDK 与布局回调开始计时。
      final bool can_request_ads =
          await AdMobConsentPermissionRequest.request_before_ad();
      if (!_is_current(generation) ||
          !can_request_ads ||
          !AdDisplayPolicy.can_show_ads()) {
        _finish_without_ad(generation);
        return;
      }
      _start_preparation_timeout(generation);
      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!_is_current(generation) || !is_initialized) {
        _log('UMP 未允许广告请求或槽位已失效，跳过加载');
        _finish_without_ad(generation);
        return;
      }
      if (!AdDisplayPolicy.can_show_ads()) {
        _finish_without_ad(generation);
        return;
      }

      // 从 tagColorList 随机选择一个颜色
      final int color_index =
          DateTime.now().millisecondsSinceEpoch %
          ColorConstants.tagColorList.length;
      final Color tag_color = ColorConstants.tagColorList[color_index];

      late final NativeAd native_ad;
      native_ad = NativeAd(
        adUnitId: ad_config.adsId,
        factoryId: 'shortStoryNativeAdCard',
        customOptions: <String, Object>{
          'isDark': is_dark,
          'advertisementLabel': advertisement_label,
          'slotId': slot_id,
          'cardWidth': card_width,
          'layoutToken': generation,
          'tagColorRed': (tag_color.r * 255).round(),
          'tagColorGreen': (tag_color.g * 255).round(),
          'tagColorBlue': (tag_color.b * 255).round(),
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
              if (!AdDisplayPolicy.can_show_ads() ||
                  !_is_selected_config_current()) {
                _replace_ad();
                _has_attempted = false;
                notifyListeners();
                return;
              }
              _is_loading = false;
              _is_ad_loaded = true;
              _is_failed = false;
              _cancel_preparation_if_ready();
              _expiry_timer?.cancel();
              _expiry_timer = Timer(
                FeedNativeAdPolicy.maximum_cache_age,
                _on_cache_expired,
              );
              notifyListeners();
              return;
            }
            unawaited(_dispose_ad_safely(ad as NativeAd));
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _log(
              '原生广告加载失败: code=${error.code}, '
              'domain=${error.domain}, message=${error.message}',
              type: 'w',
            );
            if (_is_current(generation) && identical(_native_ad, ad)) {
              _native_ad = null;
              _finish_without_ad(generation);
            }
            unawaited(_dispose_ad_safely(ad as NativeAd));
          },
          onAdClicked: (Ad ad) => _log('原生广告被点击'),
          onAdOpened: (Ad ad) => _log('原生广告打开落地页'),
          onAdClosed: (Ad ad) => _log('原生广告落地页关闭'),
          onAdImpression: (Ad ad) {
            if (!_is_current(generation) ||
                !identical(_native_ad, ad) ||
                !AdDisplayPolicy.can_show_ads()) {
              return;
            }
            _log('原生广告展示');
            unawaited(
              AdImpressionReporter.report(
                ad_config: ad_config,
                placement: AdPlacement.short_story_tab,
              ),
            );
          },
        ),
      );

      if (!_is_current(generation)) {
        unawaited(_dispose_ad_safely(native_ad));
        return;
      }

      _native_ad = native_ad;
      _log('开始加载短篇列表原生广告, configId=${ad_config.id}');
      await native_ad.load();
    } catch (error, stack_trace) {
      _log('原生广告加载异常: $error\n$stack_trace', type: 'e');
      if (_is_current(generation)) {
        _replace_ad();
        _has_attempted = true;
        _finish_without_ad(_load_generation);
      }
    }
  }

  /// 配置刷新后，只废弃已被删除或广告单元/身份已经变更的素材。
  /// 权重变化不影响已经独立选中的有效广告。
  bool _is_selected_config_current() {
    final AdConfig? selected_config = _selected_config;
    if (selected_config == null || !Get.isRegistered<AdConfigStore>()) {
      return true;
    }
    final AdConfigStore config_store = Get.find<AdConfigStore>();
    // 尚未恢复本地缓存时没有权威快照，不能把未知配置误判为已删除。
    if (!config_store.is_config_loaded.value) return true;
    return config_store.configs.any(
      (config) =>
          config.id == selected_config.id &&
          config.adsId == selected_config.adsId &&
          config.uuid == selected_config.uuid &&
          config.adsType == selected_config.adsType &&
          config.advertisers == selected_config.advertisers &&
          config.weight > 0,
    );
  }

  /// 过期缓存不得在返回页面时首次展示，已挂载素材等待卸载后释放。
  void _on_cache_expired() {
    if (_is_disposed) return;
    _is_expired = true;
    if (_attachment_owner != null) return;
    _replace_ad();
    _has_attempted = false;
    notifyListeners();
  }

  bool _is_current(int generation) {
    return !_is_disposed && generation == _load_generation;
  }

  /// SDK 可能没有回调，loaded 也不能替代真实测量，二者共同受同代次期限约束。
  void _start_preparation_timeout(int generation) {
    _preparation_timer?.cancel();
    _preparation_timer = Timer(FeedNativeAdPolicy.preparation_timeout, () {
      if (!_is_current(generation)) return;
      _log('原生广告准备超时，释放当前素材并等待冷却重试', type: 'w');
      // 先失效代次，迟到的 loaded、失败与尺寸回调都不能恢复旧素材。
      _replace_ad();
      _has_attempted = true;
      _finish_without_ad(_load_generation);
    });
  }

  /// 素材与尺寸任意先后到达，均仅在两者就绪后结束准备期限。
  void _cancel_preparation_if_ready() {
    if (!_is_ad_loaded || !_layout_is_measured) return;
    _preparation_timer?.cancel();
    _preparation_timer = null;
  }

  void _finish_without_ad(int generation) {
    if (!_is_current(generation)) return;
    _preparation_timer?.cancel();
    _preparation_timer = null;
    _is_loading = false;
    _is_ad_loaded = false;
    _layout_is_measured = false;
    _is_failed = true;
    // 失败不会永久禁用槽位，也不会在每次 rebuild 时形成请求风暴。
    _retry_timer?.cancel();
    _retry_timer = Timer(FeedNativeAdPolicy.retry_delay, () {
      _retry_timer = null;
      if (!_is_disposed && hasListeners) notifyListeners();
    });
    notifyListeners();
  }

  void _replace_ad() {
    final NativeAd? previous_ad = _native_ad;
    _load_generation = ++_next_layout_token;
    _native_ad = null;
    _is_ad_loaded = false;
    _is_loading = false;
    _is_failed = false;
    _layout_is_measured = false;
    _is_expired = false;
    _selected_config = null;
    _preparation_timer?.cancel();
    _preparation_timer = null;
    _retry_timer?.cancel();
    _retry_timer = null;
    _expiry_timer?.cancel();
    _expiry_timer = null;
    _native_view_height = short_story_tab_ad_fallback_height;
    if (previous_ad != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_dispose_ad_safely(previous_ad));
      });
      WidgetsBinding.instance.scheduleFrame();
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
    _ad_policy_worker?.dispose();
    _ad_config_worker?.dispose();
    ShortStoryNativeAdLayoutBridge.unregister(slot_id);
    AdMobConsentPermissionRequest.privacy_choice_revision.removeListener(
      _on_privacy_choice_changed,
    );
    _replace_ad();
    super.dispose();
  }

  void _log(String message, {String? type}) {
    logUtil(msg: '[ShortStoryTabAd:$slot_id] $message', type: type);
  }
}

/// 按广告槽位 ID 隔离的短篇列表广告全局池。
class ShortStoryTabAdPool {
  const ShortStoryTabAdPool._();

  static final Map<String, ShortStoryTabAdController> _controllers =
      <String, ShortStoryTabAdController>{};

  /// 获取槽位对应的唯一广告控制器。
  static ShortStoryTabAdController obtain(String slot_id) {
    final ShortStoryTabAdController? existing = _controllers.remove(slot_id);
    // 按最近使用顺序保留广告。淘汰时排除仍有页面监听或挂载的槽位。
    while (_controllers.length >=
        FeedNativeAdPolicy.maximum_retained_controllers) {
      final String? evictable_id = _controllers.entries
          .where((entry) => entry.value._can_evict)
          .map((entry) => entry.key)
          .firstOrNull;
      if (evictable_id == null) break;
      _controllers.remove(evictable_id)?.dispose();
    }
    final ShortStoryTabAdController controller =
        existing ?? ShortStoryTabAdController(slot_id: slot_id);
    _controllers[slot_id] = controller;
    return controller;
  }

  /// 某页面跳过广告时，只释放帧末已经没有页面使用的槽位。
  /// 同 ID 的其他页面仍在加载或展示时继续由全局池保留素材。
  static void remove_if_unattached(String slot_id) {
    final ShortStoryTabAdController? controller = _controllers[slot_id];
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (identical(_controllers[slot_id], controller) &&
          controller._can_evict) {
        _controllers.remove(slot_id);
        controller.dispose();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
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
