// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/services/masonry_native_ad_pool.dart';

/// 推荐瀑布流内的 Google AdMob 原生高级广告卡片。
///
/// Widget 只负责挂载当前页面的 AdWidget。对应槽位的
/// NativeAd 由 [MasonryNativeAdPool] 进程级保留，页面切换不会
/// 重新请求广告。
class MasonryNativeAdCard extends StatefulWidget {
  /// 当前瀑布流内的唯一槽位 ID。
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
  late MasonryNativeAdController _controller;

  @override
  void initState() {
    super.initState();
    _attach_controller();
  }

  @override
  void didUpdateWidget(MasonryNativeAdCard old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.slot_id == widget.slot_id) return;
    _controller.removeListener(_on_controller_changed);
    _attach_controller();
  }

  @override
  void dispose() {
    // 只解除页面监听，不释放全局槽位内的 NativeAd。
    _controller.removeListener(_on_controller_changed);
    super.dispose();
  }

  void _attach_controller() {
    _controller = MasonryNativeAdPool.obtain(widget.slot_id);
    _controller.addListener(_on_controller_changed);
  }

  void _on_controller_changed() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final String advertisement_label = easy.tr(
          'recommend_card.advertisement',
        );
        _controller.ensure_loaded(
          card_width: constraints.maxWidth,
          is_dark: widget.is_dark,
          advertisement_label: advertisement_label,
        );

        final NativeAd? native_ad = _controller.native_ad;
        if (native_ad == null) {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: advertisement_label,
          container: true,
          child: SizedBox(
            width: double.infinity,
            height: _controller.native_view_height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                RecommendBookCardStyle.card_radius,
              ),
              child: AdWidget(
                key: ValueKey<String>(
                  '${widget.slot_id}_${_controller.load_generation}',
                ),
                ad: native_ad,
              ),
            ),
          ),
        );
      },
    );
  }
}
