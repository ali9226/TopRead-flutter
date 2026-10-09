// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/components/inline_native_ad/index.dart';
import 'package:app/services/short_story_tab_ad_pool.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';

/// 仅负责准备素材和原生视图，插入与首次挂载由广告位的可见性门禁决定。
class ShortStoryNativeAdCard extends StatefulWidget {
  /// 当前列表实例独占的广告槽位 ID。
  final String slot_id;
  final bool is_dark;
  final bool attach_ad;
  final bool reserve_space;
  final ValueChanged<NativeAdLoadStatus> on_load_status_changed;
  final ValueChanged<double> on_layout_height_changed;
  final VoidCallback on_ad_attached;

  const ShortStoryNativeAdCard({
    super.key,
    required this.slot_id,
    required this.is_dark,
    required this.attach_ad,
    required this.reserve_space,
    required this.on_load_status_changed,
    required this.on_layout_height_changed,
    required this.on_ad_attached,
  });

  @override
  State<ShortStoryNativeAdCard> createState() => _ShortStoryNativeAdCardState();
}

class _ShortStoryNativeAdCardState extends State<ShortStoryNativeAdCard> {
  late ShortStoryTabAdController _controller;

  /// 一帧内多个 SDK 回调合并；父级不能在子组件 build 时 setState。
  bool _notification_scheduled = false;
  int? _reported_generation;
  NativeAdLoadStatus? _reported_status;
  double? _reported_height;
  NativeAd? _attached_ad;
  NativeAd? _reported_attached_ad;

  @override
  void initState() {
    super.initState();
    _attach_controller();
  }

  @override
  void didUpdateWidget(ShortStoryNativeAdCard old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.slot_id != widget.slot_id) {
      _controller.release_attachment(this);
      _controller.removeListener(_on_controller_changed);
      _reported_generation = null;
      _reported_status = null;
      _reported_height = null;
      _attached_ad = null;
      _reported_attached_ad = null;
      _attach_controller();
    } else if (old_widget.attach_ad && !widget.attach_ad) {
      _controller.release_attachment(this);
      _attached_ad = null;
    }
  }

  @override
  void dispose() {
    _controller.release_attachment(this);
    _controller.removeListener(_on_controller_changed);
    super.dispose();
  }

  void _attach_controller() {
    _controller = ShortStoryTabAdPool.obtain(widget.slot_id);
    _controller.addListener(_on_controller_changed);
  }

  void _on_controller_changed() {
    if (!mounted) return;
    setState(() {});
    _schedule_presentation_notification();
  }

  /// 同一代次的素材与测量才能提交；fallback 等高也必须确认测量已到达。
  void _schedule_presentation_notification() {
    if (_notification_scheduled) return;
    _notification_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notification_scheduled = false;
      if (!mounted) return;
      final NativeAdLoadStatus status = _controller.is_loading
          ? NativeAdLoadStatus.loading
          : _controller.native_ad != null
          ? NativeAdLoadStatus.loaded
          : _controller.is_failed
          ? NativeAdLoadStatus.failed
          : NativeAdLoadStatus.idle;
      final double? height = _controller.layout_is_measured
          ? _controller.native_view_height
          : null;
      final int generation = _controller.load_generation;
      final bool generation_changed = _reported_generation != generation;
      final bool status_changed =
          generation_changed || _reported_status != status;
      final bool height_changed =
          generation_changed || _reported_height != height;
      if (!status_changed && !height_changed) return;
      if (generation_changed &&
          _reported_generation != null &&
          status != NativeAdLoadStatus.loading) {
        // 快速 loaded 可能先于父级的一帧，必须先撤销上一代次的挂载批准。
        widget.on_load_status_changed(NativeAdLoadStatus.loading);
      }
      if (status_changed) widget.on_load_status_changed(status);
      // height 先到 loaded 后到时，在 loaded 后重新提交同代次的测量。
      if (height != null && (height_changed || status_changed)) {
        widget.on_layout_height_changed(height);
      }
      // 记录实际完成交付的快照，而不是排队时的快照。
      _reported_generation = generation;
      _reported_status = status;
      _reported_height = height;
      setState(() {});
    });
  }

  /// 平台首帧只为当前实例确认挂载，重载或快速滚动均使旧回调失效。
  void _schedule_attached_notification(NativeAd ad) {
    if (identical(_reported_attached_ad, ad)) return;
    _reported_attached_ad = ad;
    final int generation = _controller.load_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !widget.attach_ad ||
          !AdDisplayPolicy.can_show_ads() ||
          generation != _controller.load_generation ||
          !identical(_controller.native_ad, ad) ||
          !identical(_attached_ad, ad)) {
        if (identical(_reported_attached_ad, ad)) {
          _reported_attached_ad = null;
        }
        return;
      }
      widget.on_ad_attached();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShortStoryTabStyle.list_horizontal_padding,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final String advertisement_label = easy.tr(
            'recommend_card.advertisement',
          );
          _controller.ensure_loaded(
            card_width: constraints.maxWidth,
            is_dark: widget.is_dark,
            advertisement_label: advertisement_label,
          );
          _schedule_presentation_notification();

          final NativeAd? native_ad = _controller.native_ad;
          if (!widget.reserve_space) return const SizedBox.shrink();
          if (!AdDisplayPolicy.can_show_ads() ||
              !widget.attach_ad ||
              native_ad == null ||
              !_controller.layout_is_measured ||
              _reported_generation != _controller.load_generation ||
              _reported_status != NativeAdLoadStatus.loaded ||
              _reported_height != _controller.native_view_height ||
              !_controller.claim_attachment(this)) {
            return SizedBox(
              height:
                  _controller.native_view_height +
                  ShortStoryTabStyle.card_spacing,
            );
          }

          _attached_ad = native_ad;
          _schedule_attached_notification(native_ad);
          return Padding(
            padding: const EdgeInsets.only(
              bottom: ShortStoryTabStyle.card_spacing,
            ),
            child: Semantics(
              label: advertisement_label,
              container: true,
              child: SizedBox(
                width: double.infinity,
                height: _controller.native_view_height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    ShortStoryTabStyle.card_border_radius,
                  ),
                  child: AdWidget(
                    key: ValueKey(
                      '${widget.slot_id}_${_controller.load_generation}',
                    ),
                    ad: native_ad,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
