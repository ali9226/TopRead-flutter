import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/short_story_native_ad_layout_bridge.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';

/// 原生广告素材的加载状态。
enum NativeAdLoadStatus { idle, loading, loaded, failed }

/// 原生高级广告横幅组件。
///
/// 使用 Google AdMob 原生高级广告格式，在正文段落间内嵌展示。
/// 加载成功后自动渲染广告视图，预加载阶段使用等高骨架占位。
/// 广告自动静音播放。
///
/// 夜间模式通过 [DeviceInfo.dark] 响应式读取，切换主题时容器背景色自动更新。
class NativeAdBanner extends StatefulWidget {
  /// 广告单元 ID（由对应阅读场景的广告配置接口返回）。
  final String ad_unit_id;

  /// 广告配置的唯一标识，用于服务器端验证。
  final String uuid;

  /// 点击徽章时的回调（由父组件传入）。
  final VoidCallback? on_unlock;

  /// 激励视频广告是否正在加载中（控制徽章加载动画）。
  final bool is_unlocking;

  /// 徽章文案的多语种 key，默认为解锁文案。
  final String badge_text_key;

  /// 是否允许把已加载的原生广告视图挂载到 Flutter 视图树。
  ///
  /// 阅读页会先预加载素材，到达广告位置后才设为 true，
  /// 防止平台视图首次挂载时已经位于屏幕外。
  final bool attach_ad;

  /// 广告未加载或尚未允许挂载时是否保留完整广告位高度。
  final bool reserve_space;

  /// 是否在广告卡片下方显示继续滑动提示。
  final bool show_continue_hint;

  /// 广告加载状态变化回调。
  final ValueChanged<NativeAdLoadStatus>? on_load_status_changed;

  /// 原生广告实际布局高度变化回调。
  final ValueChanged<double>? on_layout_height_changed;

  /// [AdWidget] 完成首帧挂载后的回调。
  final VoidCallback? on_ad_attached;

  /// Google Mobile Ads SDK 记录展示后的回调。
  final VoidCallback? on_ad_impression;

  const NativeAdBanner({
    super.key,
    required this.ad_unit_id,
    required this.uuid,
    this.on_unlock,
    this.is_unlocking = false,
    this.badge_text_key = 'short_story_read.unlock',
    this.attach_ad = true,
    this.reserve_space = false,
    this.show_continue_hint = true,
    this.on_load_status_changed,
    this.on_layout_height_changed,
    this.on_ad_attached,
    this.on_ad_impression,
  });

  @override
  State<NativeAdBanner> createState() => _NativeAdBannerState();
}

class _NativeAdBannerState extends State<NativeAdBanner> {
  static const String _log_prefix = '[NativeAdBanner]';

  /// 原生端尚未回传实际高度前使用的安全占位高度。
  static const double _fallback_ad_height = 460.0;

  /// 原生高度变化小于该值时不触发重建，避免浮点抖动。
  static const double _layout_height_tolerance = 0.5;

  /// 设备信息仓库（用于响应式读取当前主题模式）。
  final DeviceInfo _device_info = Get.find<DeviceInfo>();

  /// 原生广告控制器。
  NativeAd? _native_ad;

  /// 广告是否已加载完成。
  bool _is_ad_loaded = false;

  /// 最近一次通知父组件的加载状态。
  NativeAdLoadStatus _load_status = NativeAdLoadStatus.idle;

  /// 当前广告实例是否已经通知过首帧挂载完成。
  bool _has_reported_ad_attached = false;

  /// 上一次已同步的公共广告展示状态。
  late bool _can_show_ads;

  /// 项目广告开关变更监听器。
  late final Worker _ad_policy_worker;

  /// 异步加载代次，防止广告 ID 变化或组件销毁后旧任务回写状态。
  int _load_generation = 0;

  /// 当前广告实例在原生布局通道中的唯一槽位 ID。
  late final String _slot_id;

  /// 最近一次广告请求使用的卡片宽度。
  double? _requested_card_width;

  /// 最近一次广告请求使用的主题模式。
  bool? _requested_is_dark;

  /// 下一帧待使用的卡片宽度。
  double? _pending_card_width;

  /// 下一帧待使用的主题模式。
  bool? _pending_is_dark;

  /// 是否已经安排下一帧重载广告。
  bool _is_reload_scheduled = false;

  /// 原生广告视图按实际标题行数测量出的高度。
  double _ad_height = _fallback_ad_height;

  /// 当前广告的媒体素材类型，由 Android/iOS AdMob SDK 回传。
  String? _media_type;

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

  @override
  void initState() {
    super.initState();
    _can_show_ads = AdDisplayPolicy.can_show_ads();
    _ad_policy_worker = ever(
      Get.find<ProjectConfigStore>().config_revision,
      (_) => _on_ad_policy_changed(),
    );
    _slot_id = ShortStoryNativeAdLayoutBridge.create_slot_id();
    ShortStoryNativeAdLayoutBridge.register(
      _slot_id,
      _on_native_layout_measured,
      media_type_listener: _on_native_media_type_detected,
      video_playback_listener: _on_native_video_playback_changed,
    );
    AdMobConsentPermissionRequest.privacy_choice_revision.addListener(
      _on_privacy_choice_changed,
    );
  }

  @override
  void didUpdateWidget(NativeAdBanner old_widget) {
    super.didUpdateWidget(old_widget);
    // 广告单元 ID 变化时重新加载。
    if (old_widget.ad_unit_id != widget.ad_unit_id) {
      _dispose_ad();
      _reset_requested_layout();
      _set_load_status(NativeAdLoadStatus.idle);
    }
    if (!old_widget.attach_ad && widget.attach_ad) {
      _has_reported_ad_attached = false;
    }
  }

  @override
  void dispose() {
    AdMobConsentPermissionRequest.privacy_choice_revision.removeListener(
      _on_privacy_choice_changed,
    );
    ShortStoryNativeAdLayoutBridge.unregister(_slot_id);
    _ad_policy_worker.dispose();
    _dispose_ad();
    super.dispose();
  }

  /// 用户修改广告隐私选择后释放旧广告，并按最新 UMP 结果重新尝试。
  void _on_privacy_choice_changed() {
    _dispose_ad();
    _reset_requested_layout();
    if (!mounted) return;
    setState(() {});
  }

  /// 广告平台开关变化时立即释放旧广告或允许下一帧重新请求。
  void _on_ad_policy_changed() {
    final bool can_show_ads = AdDisplayPolicy.can_show_ads();
    if (_can_show_ads == can_show_ads) return;
    _can_show_ads = can_show_ads;
    _dispose_ad();
    _reset_requested_layout();
    if (mounted) setState(() {});
  }

  /// 清空上一次布局请求，使下一次构建按当前宽度重新加载广告。
  void _reset_requested_layout() {
    _requested_card_width = null;
    _requested_is_dark = null;
    _pending_card_width = null;
    _pending_is_dark = null;
    _ad_height = _fallback_ad_height;
    _media_type = null;
    _has_reported_ad_attached = false;
  }

  /// 销毁广告控制器。
  void _dispose_ad() {
    _load_generation += 1;
    final NativeAd? previous_ad = _native_ad;
    _native_ad = null;
    _is_ad_loaded = false;
    _media_type = null;
    _has_reported_ad_attached = false;
    if (previous_ad != null) {
      // 先让当前帧卸载 AdWidget，再释放广告对象，避免插件残留已挂载 ID。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(previous_ad.dispose());
      });
    }
  }

  /// 更新加载状态，并只在状态真正变化时通知父组件。
  void _set_load_status(NativeAdLoadStatus status) {
    if (_load_status == status) return;
    _load_status = status;
    widget.on_load_status_changed?.call(status);
  }

  /// 加载 Google AdMob 原生高级广告。
  ///
  /// 使用 NativeAd 格式，在正文段落间内嵌展示。
  /// 加载完成后通过 setState 触发重建，渲染 AdWidget。
  Future<void> _load_native_ad({
    required double card_width,
    required bool is_dark,
  }) async {
    if (!AdDisplayPolicy.can_show_ads() || widget.ad_unit_id.isEmpty) {
      _log('ad_unit_id 为空，跳过加载');
      return;
    }

    final int generation = ++_load_generation;
    _set_load_status(NativeAdLoadStatus.loading);
    try {
      // 全 App 的所有广告位共享同一个 UMP 门禁和 SDK 初始化 Future。
      // 未来首页瀑布流同时创建多个广告卡片时也不会重复弹窗。
      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!is_initialized ||
          !AdDisplayPolicy.can_show_ads() ||
          !mounted ||
          generation != _load_generation) {
        _log('UMP 未允许广告请求或组件已失效，跳过加载');
        if (mounted && generation == _load_generation) {
          _set_load_status(NativeAdLoadStatus.failed);
        }
        return;
      }

      _log('开始加载原生广告, adUnitId=${widget.ad_unit_id}');

      final NativeAd native_ad = NativeAd(
        adUnitId: widget.ad_unit_id,
        factoryId: 'shortStoryNativeAdCard',
        customOptions: <String, Object>{
          'isDark': is_dark,
          'advertisementLabel': tr('recommend_card.advertisement'),
          'slotId': _slot_id,
          'cardWidth': card_width,
          'layoutToken': generation,
        },
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            final String media_type_text = _media_type == null
                ? ''
                : ', 素材类型=$_media_type';
            _log(
              '原生广告加载成功$media_type_text, '
              'responseId=${ad.responseInfo?.responseId}',
            );
            if (mounted &&
                generation == _load_generation &&
                identical(_native_ad, ad)) {
              setState(() {
                _is_ad_loaded = true;
              });
              _set_load_status(NativeAdLoadStatus.loaded);
            } else {
              unawaited(ad.dispose());
            }
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _log(
              '原生广告加载失败: code=${error.code}, '
              'domain=${error.domain}, message=${error.message}',
              type: 'w',
            );
            unawaited(ad.dispose());
            if (mounted && generation == _load_generation) {
              setState(() {
                _native_ad = null;
                _is_ad_loaded = false;
              });
              _set_load_status(NativeAdLoadStatus.failed);
            }
          },
          onAdOpened: (Ad ad) => _log('原生广告被点击'),
          onAdClosed: (Ad ad) => _log('原生广告被关闭'),
          onAdImpression: (Ad ad) {
            unawaited(_log_native_ad_impression(generation));
            widget.on_ad_impression?.call();
          },
        ),
        nativeAdOptions: NativeAdOptions(
          adChoicesPlacement: AdChoicesPlacement.topRightCorner,
          mediaAspectRatio: MediaAspectRatio.any,
          videoOptions: VideoOptions(startMuted: true),
        ),
      );
      _native_ad = native_ad;

      _log('调用 NativeAd.load()...');
      await native_ad.load();
      _log('NativeAd.load() 调用完成');
    } catch (e, stack_trace) {
      _log('原生广告加载异常: $e\n$stack_trace', type: 'e');
      if (generation == _load_generation) {
        final NativeAd? failed_ad = _native_ad;
        _native_ad = null;
        _is_ad_loaded = false;
        if (failed_ad != null) {
          unawaited(failed_ad.dispose());
        }
        if (mounted) {
          _set_load_status(NativeAdLoadStatus.failed);
        }
      }
    }
  }

  /// 在布局宽度或主题变化后，于当前构建帧结束时重建原生广告。
  void _ensure_native_ad_requested({
    required double card_width,
    required bool is_dark,
  }) {
    if (!AdDisplayPolicy.can_show_ads() ||
        widget.ad_unit_id.isEmpty ||
        !card_width.isFinite ||
        card_width <= 0) {
      return;
    }

    final bool request_unchanged =
        _requested_card_width != null &&
        (_requested_card_width! - card_width).abs() <
            _layout_height_tolerance &&
        _requested_is_dark == is_dark;
    if (request_unchanged) return;

    _pending_card_width = card_width;
    _pending_is_dark = is_dark;
    if (_is_reload_scheduled) return;
    _is_reload_scheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _is_reload_scheduled = false;
      if (!mounted) return;

      final double? pending_card_width = _pending_card_width;
      final bool? pending_is_dark = _pending_is_dark;
      if (pending_card_width == null || pending_is_dark == null) return;

      final bool pending_request_unchanged =
          _requested_card_width != null &&
          (_requested_card_width! - pending_card_width).abs() <
              _layout_height_tolerance &&
          _requested_is_dark == pending_is_dark;
      if (pending_request_unchanged) return;

      _dispose_ad();
      setState(() {
        _requested_card_width = pending_card_width;
        _requested_is_dark = pending_is_dark;
        _ad_height = _fallback_ad_height;
      });
      unawaited(
        _load_native_ad(
          card_width: pending_card_width,
          is_dark: pending_is_dark,
        ),
      );
    });
  }

  /// 应用原生端按标题、广告主和按钮实际内容测量出的安全高度。
  void _on_native_layout_measured(double height, int token) {
    if (!mounted || token != _load_generation) return;
    if ((_ad_height - height).abs() < _layout_height_tolerance) return;
    final double resolved_height = height.ceilToDouble();
    setState(() {
      _ad_height = resolved_height;
    });
    widget.on_layout_height_changed?.call(resolved_height);
  }

  /// 记录 AdMob 原生 SDK 实际返回的媒体素材类型。
  void _on_native_media_type_detected(bool is_video, int token) {
    if (!mounted || token != _load_generation) return;
    final String media_type = is_video ? '视频广告' : '图片广告';
    if (_media_type == media_type) return;
    _media_type = media_type;
    _log('广告素材类型: $_media_type');
  }

  /// 主动查询当前广告的媒体素材类型，避免单次原生回调时序竞争。
  Future<void> _resolve_native_media_type(int token) async {
    if (!mounted || token != _load_generation || _media_type != null) return;
    final bool? is_video = await ShortStoryNativeAdLayoutBridge.get_media_type(
      _slot_id,
      token,
    );
    if (is_video == null) return;
    _on_native_media_type_detected(is_video, token);
  }

  /// 在确认素材类型后输出展示日志，不再输出误导性的“未知素材”。
  Future<void> _log_native_ad_impression(int token) async {
    await _resolve_native_media_type(token);
    if (!mounted || token != _load_generation) return;
    final String? media_type = _media_type;
    if (media_type == null) {
      _log('原生广告展示, 素材类型查询失败', type: 'w');
      return;
    }
    _log('原生广告展示, 素材类型=$media_type');
  }

  /// 输出原生 SDK 回调的真实视频播放状态。
  void _on_native_video_playback_changed(
    String playback_state,
    bool? is_muted,
    int token,
  ) {
    if (!mounted || token != _load_generation) return;
    final String state_text = switch (playback_state) {
      'started' => '开始播放',
      'playing' => '正在播放',
      'paused' => '已暂停',
      'ended' => '播放结束',
      'muted' => '已静音',
      'unmuted' => '已取消静音',
      _ => playback_state,
    };
    final String muted_text = is_muted == null
        ? ''
        : ', 静音=${is_muted ? '是' : '否'}';
    _log('视频播放状态: $state_text$muted_text');
  }

  /// 在真实广告视图完成首帧布局后通知父组件。
  void _schedule_ad_attached_notification() {
    if (_has_reported_ad_attached) return;
    _has_reported_ad_attached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !widget.attach_ad ||
          !_is_ad_loaded ||
          _native_ad == null) {
        _has_reported_ad_attached = false;
        return;
      }
      unawaited(_resolve_native_media_type(_load_generation));
      widget.on_ad_attached?.call();
    });
  }

  /// 构建加载中或等待安全挂载时使用的原生广告骨架。
  Widget _build_placeholder({
    required Color ad_bg_color,
    required Color hint_color,
  }) {
    final Color skeleton_color = hint_color.withValues(alpha: 0.12);
    final Color media_skeleton_color = hint_color.withValues(alpha: 0.08);

    Widget skeleton_line({
      required double width_factor,
      required double height,
    }) {
      return FractionallySizedBox(
        widthFactor: width_factor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: skeleton_color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: _spacing_top),
        Container(
          height: _ad_height,
          decoration: BoxDecoration(
            color: ad_bg_color,
            borderRadius: BorderRadius.circular(16.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              Container(height: 260, color: media_skeleton_color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    children: <Widget>[
                      skeleton_line(width_factor: 0.72, height: 18),
                      const SizedBox(height: 10),
                      skeleton_line(width_factor: 0.36, height: 12),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 34,
                          height: 20,
                          decoration: BoxDecoration(
                            color: skeleton_color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: skeleton_color,
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.show_continue_hint) ...<Widget>[
          const SizedBox(height: _hint_spacing),
          SizedBox(
            height: _hint_font_size * _hint_height,
            child: _is_ad_loaded
                ? Text(
                    tr('short_story_read.swipe_to_continue'),
                    style: TextStyle(
                      fontSize: _hint_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: hint_color,
                      height: _hint_height,
                    ),
                  )
                : null,
          ),
        ],
        const SizedBox(height: _spacing_bottom),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Obx 响应式读取主题状态，切换夜间模式时容器背景色自动更新。
    return Obx(() {
      if (!AdDisplayPolicy.can_show_ads()) {
        return const SizedBox.shrink();
      }

      /// 当前是否为夜间模式。
      final bool is_dark = _device_info.dark.value;

      /// 提示文字颜色（夜间偏蓝灰，日间偏灰，与正文次要文字颜色一致）。
      final Color hint_color = is_dark
          ? const Color(0xFF8B8B9E)
          : const Color(0xFF999999);

      /// 广告容器背景色（日间使用 whiteColor，夜间使用深色背景，兼容暗色模式）。
      /// 注意：原生端（Android/iOS）的广告内部背景色需保持一致，
      /// 修改时需同步更新 ShortStoryNativeAdFactory。
      final Color ad_bg_color = is_dark
          ? const Color(0xFF1E2430)
          : ColorConstants.whiteColor;

      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double available_width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final double card_width = available_width;
          _ensure_native_ad_requested(card_width: card_width, is_dark: is_dark);

          // 广告加载前默认不占空间，避免正文中出现大块加载空白。
          if (!_is_ad_loaded || _native_ad == null) {
            return widget.reserve_space
                ? _build_placeholder(
                    ad_bg_color: ad_bg_color,
                    hint_color: hint_color,
                  )
                : const SizedBox.shrink();
          }

          // 素材已在后台加载，平台视图只在广告位进入安全可视区域后挂载。
          if (!widget.attach_ad) {
            if (!widget.reserve_space) {
              return const SizedBox.shrink();
            }
            return _build_placeholder(
              ad_bg_color: ad_bg_color,
              hint_color: hint_color,
            );
          }

          _schedule_ad_attached_notification();

          final bool is_ios = Theme.of(context).platform == TargetPlatform.iOS;
          final Color card_border_color = is_dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: _spacing_top),
              // iOS 使用负扩散、向下偏移的柔和阴影，阴影不进入
              // PlatformView 圆角内部，避免左右出现被裁断的黑边。
              Container(
                height: _ad_height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: is_ios
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: is_dark ? 0.22 : 0.09,
                            ),
                            blurRadius: 20,
                            spreadRadius: -5,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 14,
                            spreadRadius: -2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: card_border_color, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: ColoredBox(
                    color: ad_bg_color,
                    child: AdWidget(ad: _native_ad!),
                  ),
                ),
              ),
              if (widget.show_continue_hint) ...<Widget>[
                const SizedBox(height: _hint_spacing),
                // 底部"继续滑动"提示文字。
                Text(
                  tr('short_story_read.swipe_to_continue'),
                  style: TextStyle(
                    fontSize: _hint_font_size,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    color: hint_color,
                    height: _hint_height,
                  ),
                ),
              ],
              const SizedBox(height: _spacing_bottom),
            ],
          );
        },
      );
    });
  }

  /// 输出广告流程日志。
  void _log(String message, {String? type}) {
    logUtil(msg: '$_log_prefix $message', type: type);
  }
}
