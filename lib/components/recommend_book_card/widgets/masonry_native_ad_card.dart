// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/components/inline_native_ad/style.dart';
import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:app/services/masonry_native_ad_pool.dart';
import 'package:app/util/ad_display_policy.dart';

/// 素材和尺寸准备好后才提交瀑布流广告，错过的边界保持零高度。
class MasonryNativeAdCard extends StatelessWidget {
  /// 会话内稳定的槽位 ID，与素材池及缓存高度一一对应。
  final String slot_id;

  /// 原生卡片主题，改变时重新申请匹配背景与文字颜色的素材。
  final bool is_dark;

  /// 与外层瀑布流共用滚动位置，保证挂载检测使用实际视口。
  final ScrollController scroll_controller;

  /// 会话保存的已提交高度，返回页面时无需重新折叠卡片。
  final double? initial_reserved_extent;

  /// 列数与目标位置变化时撤销尚未生效的首次挂载许可。
  final Object? layout_revision;

  /// 已跳过的槽位关闭准备，直到新的推荐批次创建新身份。
  final bool is_enabled;

  /// 安全提交后的实际高度，用于同步会话排版。
  final ValueChanged<double>? on_extent_changed;

  /// 当前广告失效或错过展示边界后的持久化决策回调。
  final VoidCallback? on_skipped;

  const MasonryNativeAdCard({
    super.key,
    required this.slot_id,
    required this.is_dark,
    required this.scroll_controller,
    this.initial_reserved_extent,
    this.layout_revision,
    this.is_enabled = true,
    this.on_extent_changed,
    this.on_skipped,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PreparedNativeAdSlot(
        scroll_controller: scroll_controller,
        initial_reserved_extent: initial_reserved_extent,
        leading_extent: 0,
        trailing_extent: 0,
        resize_above_viewport: false,
        retain_attachment_offscreen: false,
        preload_viewport_count: InlineNativeAdStyle.feed_preload_viewports,
        layout_revision: layout_revision,
        is_enabled: is_enabled && AdDisplayPolicy.can_show_ads(),
        on_extent_changed: on_extent_changed,
        on_skipped: () {
          on_skipped?.call();
          MasonryNativeAdPool.remove_if_unattached(slot_id);
        },
        builder:
            (
              BuildContext context, {
              required bool attach_ad,
              required bool reserve_space,
              required ValueChanged<NativeAdLoadStatus> on_load_status_changed,
              required ValueChanged<double> on_layout_height_changed,
              required VoidCallback on_ad_attached,
            }) => _MasonryNativeAdContent(
              slot_id: slot_id,
              is_dark: is_dark,
              attach_ad: attach_ad,
              on_load_status_changed: on_load_status_changed,
              on_layout_height_changed: on_layout_height_changed,
              on_ad_attached: on_ad_attached,
            ),
      ),
    );
  }
}

/// 素材预加载独立于平台视图，首次真正可见后才获取独占挂载权。
class _MasonryNativeAdContent extends StatefulWidget {
  final String slot_id;
  final bool is_dark;
  final bool attach_ad;
  final ValueChanged<NativeAdLoadStatus> on_load_status_changed;
  final ValueChanged<double> on_layout_height_changed;
  final VoidCallback on_ad_attached;

  const _MasonryNativeAdContent({
    required this.slot_id,
    required this.is_dark,
    required this.attach_ad,
    required this.on_load_status_changed,
    required this.on_layout_height_changed,
    required this.on_ad_attached,
  });

  @override
  State<_MasonryNativeAdContent> createState() =>
      _MasonryNativeAdContentState();
}

class _MasonryNativeAdContentState extends State<_MasonryNativeAdContent> {
  late MasonryNativeAdController _controller;

  /// 代次、状态与真实高度共同去重，保证任意顺序的 SDK 回调均被传递。
  Object? _reported_snapshot;

  /// 仅在回调实际执行后记录，快速连续回调不会漏发 loaded。
  (int, NativeAdLoadStatus)? _delivered_status;

  /// 每个 SDK 实例只确认一次实际平台视图挂载。
  int? _attached_generation;

  @override
  void initState() {
    super.initState();
    _attach_controller();
  }

  void _attach_controller() {
    _controller = MasonryNativeAdPool.obtain(widget.slot_id);
    _controller.addListener(_on_controller_changed);
  }

  @override
  void didUpdateWidget(_MasonryNativeAdContent old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.slot_id != widget.slot_id) {
      _controller.removeListener(_on_controller_changed);
      _controller.release_attachment(this);
      _reported_snapshot = null;
      _delivered_status = null;
      _attached_generation = null;
      _attach_controller();
    }
    if (!widget.attach_ad) {
      _controller.release_attachment(this);
      _attached_generation = null;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_on_controller_changed);
    _controller.release_attachment(this);
    super.dispose();
  }

  void _on_controller_changed() {
    if (mounted) setState(() {});
  }

  /// 帧末反馈准备状态，不在 LayoutBuilder 内修改父级的排版状态。
  void _report_preparation() {
    final NativeAdLoadStatus status = _controller.native_ad != null
        ? NativeAdLoadStatus.loaded
        : _controller.is_failed
        ? NativeAdLoadStatus.failed
        : _controller.is_loading
        ? NativeAdLoadStatus.loading
        : NativeAdLoadStatus.idle;
    final double? height = _controller.layout_is_measured
        ? _controller.native_view_height
        : null;
    final int generation = _controller.load_generation;
    final Object snapshot = (generation, status, height);
    if (_reported_snapshot == snapshot) return;
    _reported_snapshot = snapshot;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _reported_snapshot != snapshot ||
          generation != _controller.load_generation)
        return;
      if (_delivered_status != (generation, status)) {
        if (_delivered_status?.$1 != generation &&
            status == NativeAdLoadStatus.loaded) {
          // 缓存素材或极快的 SDK 回调也必须撤销上一实例的挂载批准。
          widget.on_load_status_changed(NativeAdLoadStatus.loading);
        }
        _delivered_status = (generation, status);
        widget.on_load_status_changed(status);
      }
      if (height != null) widget.on_layout_height_changed(height);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final String label = easy.tr('recommend_card.advertisement');
        _controller.ensure_loaded(
          card_width: constraints.maxWidth,
          is_dark: widget.is_dark,
          advertisement_label: label,
        );
        _report_preparation();
        final NativeAd? ad = _controller.native_ad;
        if (!widget.attach_ad ||
            ad == null ||
            _delivered_status !=
                (_controller.load_generation, NativeAdLoadStatus.loaded) ||
            !_controller.claim_attachment(this)) {
          return const SizedBox.shrink();
        }
        final int generation = _controller.load_generation;
        if (_attached_generation != generation) {
          _attached_generation = generation;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                widget.attach_ad &&
                generation == _controller.load_generation) {
              widget.on_ad_attached();
            }
          });
        }
        return Semantics(
          label: label,
          container: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              RecommendBookCardStyle.card_radius,
            ),
            child: AdWidget(
              key: ValueKey<String>('${widget.slot_id}_$generation'),
              ad: ad,
            ),
          ),
        );
      },
    );
  }
}
