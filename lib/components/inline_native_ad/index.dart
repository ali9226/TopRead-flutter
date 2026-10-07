import 'package:flutter/material.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'prepared_slot.dart';
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

  /// 是否绘制加载骨架；阅读页只为就绪广告预留尺寸，不展示加载占位。
  final bool show_placeholder;

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
    this.show_placeholder = true,
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
      show_placeholder: show_placeholder,
      show_continue_hint: show_continue_hint,
      on_load_status_changed: on_load_status_changed,
      on_layout_height_changed: on_layout_height_changed,
      on_ad_attached: on_ad_attached,
      on_ad_impression: on_ad_impression,
    );
  }
}

/// 素材提前准备，未错过段落边界时才安排广告，进入视口后首次挂载。
class ViewportAwareInlineNativeAdBanner extends StatelessWidget {
  /// 当前阅读列表的滚动控制器。
  final ScrollController scroll_controller;

  /// 广告单元 ID。
  final String ad_unit_id;

  /// 广告配置的唯一标识。
  final String uuid;

  /// 点击徽章时触发当前阅读页的解锁流程。
  final VoidCallback? on_unlock;

  /// 当前阅读页是否正在加载激励视频。
  final bool is_unlocking;

  /// 安全区下方被阅读页浮层遮挡的高度。
  final double viewport_top_inset;

  /// 正文重新排版的版本；进度重建不应撤销连续滚动中的可见性批准。
  final Object? layout_revision;

  /// 免广告或平台关闭时立即卸载素材，正文高度由广告位安全收回。
  final bool is_enabled;

  /// 广告位真正提交尺寸后通知页面更新正文进度范围。
  final ValueChanged<double>? on_extent_changed;

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
    this.on_unlock,
    this.is_unlocking = false,
    this.viewport_top_inset = 0,
    this.layout_revision,
    this.is_enabled = true,
    this.on_extent_changed,
    this.badge_text_key = 'short_story_read.ad_free',
    this.show_continue_hint = false,
    this.on_ad_impression,
  });

  @override
  Widget build(BuildContext context) {
    return PreparedNativeAdSlot(
      key: ValueKey((ad_unit_id, uuid)),
      scroll_controller: scroll_controller,
      viewport_top_inset: viewport_top_inset,
      layout_revision: layout_revision,
      is_enabled: is_enabled,
      on_extent_changed: on_extent_changed,
      trailing_extent:
          InlineNativeAdStyle.spacing_bottom +
          (show_continue_hint
              ? InlineNativeAdStyle.hint_spacing +
                    InlineNativeAdStyle.hint_font_size *
                        InlineNativeAdStyle.hint_height
              : 0),
      builder:
          (
            context, {
            required attach_ad,
            required reserve_space,
            required on_load_status_changed,
            required on_layout_height_changed,
            required on_ad_attached,
          }) => InlineNativeAdBanner(
            ad_unit_id: ad_unit_id,
            uuid: uuid,
            on_unlock: on_unlock,
            is_unlocking: is_unlocking,
            badge_text_key: badge_text_key,
            attach_ad: attach_ad,
            reserve_space: reserve_space,
            show_placeholder: false,
            show_continue_hint: show_continue_hint,
            on_load_status_changed: on_load_status_changed,
            on_layout_height_changed: on_layout_height_changed,
            on_ad_attached: on_ad_attached,
            on_ad_impression: on_ad_impression,
          ),
    );
  }
}
