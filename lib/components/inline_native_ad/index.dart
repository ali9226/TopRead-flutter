import 'package:flutter/material.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:app/util/native_ad_visibility.dart';

import 'style.dart';

export 'package:app/pages/short_story_read/widgets/native_ad_banner.dart'
    show NativeAdLoadStatus;

/// 长短篇阅读页共用的原生高级广告卡片入口。
///
/// 原生布局、视频静音播放、明暗主题、圆角和阴影统一由底层
/// [NativeAdBanner] 实现，各阅读页只负责广告业务状态。
class InlineNativeAdBanner extends StatelessWidget {
  /// 广告单元 ID。
  final String ad_unit_id;

  /// 广告配置的唯一标识。
  final String uuid;

  /// 点击徽章时的回调。
  final VoidCallback? on_unlock;

  /// 激励视频是否正在加载。
  final bool is_unlocking;

  /// 徽章文案多语种 key。
  final String badge_text_key;

  /// 是否允许挂载原生平台视图。
  final bool attach_ad;

  /// 加载期间是否保留稳定广告位高度。
  final bool reserve_space;

  /// 是否展示继续滑动提示。
  final bool show_continue_hint;

  /// 广告产生真实展示后的回调。
  final VoidCallback? on_ad_impression;

  /// 广告加载状态变化回调。
  final ValueChanged<NativeAdLoadStatus>? on_load_status_changed;

  /// 原生广告实际布局高度变化回调。
  final ValueChanged<double>? on_layout_height_changed;

  /// 广告平台视图完成首帧挂载后的回调。
  final VoidCallback? on_ad_attached;

  const InlineNativeAdBanner({
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
  Widget build(BuildContext context) {
    return NativeAdBanner(
      ad_unit_id: ad_unit_id,
      uuid: uuid,
      on_unlock: on_unlock,
      is_unlocking: is_unlocking,
      badge_text_key: badge_text_key,
      attach_ad: attach_ad,
      reserve_space: reserve_space,
      show_continue_hint: show_continue_hint,
      on_load_status_changed: on_load_status_changed,
      on_layout_height_changed: on_layout_height_changed,
      on_ad_attached: on_ad_attached,
      on_ad_impression: on_ad_impression,
    );
  }
}

/// 到达安全可视范围前只预加载素材、不挂载平台视图的原生广告位。
class ViewportAwareInlineNativeAdBanner extends StatefulWidget {
  /// 当前阅读列表的滚动控制器。
  final ScrollController scroll_controller;

  /// 广告单元 ID。
  final String ad_unit_id;

  /// 广告配置的唯一标识。
  final String uuid;

  /// 徽章文案多语种 key。
  final String badge_text_key;

  /// 是否展示继续滑动提示。
  final bool show_continue_hint;

  /// 广告产生真实展示后的回调。
  final VoidCallback? on_ad_impression;

  const ViewportAwareInlineNativeAdBanner({
    super.key,
    required this.scroll_controller,
    required this.ad_unit_id,
    required this.uuid,
    this.badge_text_key = 'short_story_read.ad_free',
    this.show_continue_hint = false,
    this.on_ad_impression,
  });

  @override
  State<ViewportAwareInlineNativeAdBanner> createState() =>
      _ViewportAwareInlineNativeAdBannerState();
}

class _ViewportAwareInlineNativeAdBannerState
    extends State<ViewportAwareInlineNativeAdBanner> {
  /// 广告位的布局定位锚点。
  GlobalKey _slot_key = GlobalKey();

  /// 是否已经允许挂载平台广告视图。
  bool _can_attach_ad = false;

  /// 当前广告是否加载失败。
  bool _has_failed = false;

  /// 是否已经安排下一帧可见性检查。
  bool _visibility_update_scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.scroll_controller.addListener(_schedule_visibility_update);
    _schedule_visibility_update();
  }

  @override
  void didUpdateWidget(ViewportAwareInlineNativeAdBanner old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.scroll_controller != widget.scroll_controller) {
      old_widget.scroll_controller.removeListener(_schedule_visibility_update);
      widget.scroll_controller.addListener(_schedule_visibility_update);
    }
    if (old_widget.ad_unit_id != widget.ad_unit_id ||
        old_widget.uuid != widget.uuid) {
      _slot_key = GlobalKey();
      _can_attach_ad = false;
      _has_failed = false;
    }
    _schedule_visibility_update();
  }

  @override
  void dispose() {
    widget.scroll_controller.removeListener(_schedule_visibility_update);
    super.dispose();
  }

  /// 将可见性测量延迟到当前布局帧结束后执行。
  void _schedule_visibility_update() {
    if (_visibility_update_scheduled || _can_attach_ad || _has_failed) return;
    _visibility_update_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibility_update_scheduled = false;
      if (!mounted) return;
      _update_visibility();
    });
  }

  /// 广告位刚进入视口边缘时即允许挂载，避免必须滚到屏幕中央才出现。
  void _update_visibility() {
    if (_can_attach_ad || _has_failed) return;

    final RenderObject? render_object = _slot_key.currentContext
        ?.findRenderObject();
    if (render_object is! RenderBox || !render_object.hasSize) return;

    final MediaQueryData media_query = MediaQuery.of(context);
    final double slot_top = render_object.localToGlobal(Offset.zero).dy;
    final bool should_attach = should_attach_native_ad(
      slot_top: slot_top,
      slot_height: render_object.size.height,
      viewport_top: media_query.viewPadding.top,
      viewport_bottom: media_query.size.height - media_query.viewPadding.bottom,
      minimum_visible_extent: InlineNativeAdStyle.minimum_visible_extent,
    );
    if (!should_attach) return;

    setState(() {
      _can_attach_ad = true;
    });
  }

  /// 广告失败后移除预留位；加载完成后再次检查当前可见范围。
  void _on_load_status_changed(NativeAdLoadStatus status) {
    if (!mounted) return;
    if (status == NativeAdLoadStatus.failed) {
      if (_has_failed) return;
      setState(() {
        _has_failed = true;
      });
      return;
    }
    if (status == NativeAdLoadStatus.loaded) {
      _schedule_visibility_update();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_has_failed) return const SizedBox.shrink();

    return KeyedSubtree(
      key: _slot_key,
      child: InlineNativeAdBanner(
        ad_unit_id: widget.ad_unit_id,
        uuid: widget.uuid,
        badge_text_key: widget.badge_text_key,
        attach_ad: _can_attach_ad,
        reserve_space: true,
        show_continue_hint: widget.show_continue_hint,
        on_load_status_changed: _on_load_status_changed,
        on_layout_height_changed: (_) => _schedule_visibility_update(),
        on_ad_impression: widget.on_ad_impression,
      ),
    );
  }
}
