// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/services/short_story_tab_ad_pool.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';

/// 短篇小说列表内的 Google AdMob 原生广告卡片。
///
/// 使用 [ShortStoryTabAdPool] 进程级管理，
/// 广告 ID 从 `redis/get.ads_ids` 本地缓存获取（type=17 Android, type=18 iOS）。
class ShortStoryNativeAdCard extends StatefulWidget {
  /// 当前广告槽位的全局唯一 ID。
  final String slot_id;

  /// 是否为夜间模式。
  final bool is_dark;

  const ShortStoryNativeAdCard({
    super.key,
    required this.slot_id,
    required this.is_dark,
  });

  @override
  State<ShortStoryNativeAdCard> createState() => _ShortStoryNativeAdCardState();
}

class _ShortStoryNativeAdCardState extends State<ShortStoryNativeAdCard>
    with SingleTickerProviderStateMixin {
  late ShortStoryTabAdController _controller;
  late AnimationController _shimmer_controller;

  @override
  void initState() {
    super.initState();
    _attach_controller();
    _shimmer_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(ShortStoryNativeAdCard old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.slot_id == widget.slot_id) return;
    _controller.removeListener(_on_controller_changed);
    _attach_controller();
  }

  @override
  void dispose() {
    _controller.removeListener(_on_controller_changed);
    _shimmer_controller.dispose();
    super.dispose();
  }

  void _attach_controller() {
    _controller = ShortStoryTabAdPool.obtain(widget.slot_id);
    _controller.addListener(_on_controller_changed);
  }

  void _on_controller_changed() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!AdDisplayPolicy.can_show_ads()) {
        return const SizedBox.shrink();
      }

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

            final NativeAd? native_ad = _controller.native_ad;

            // 广告未加载时显示骨架屏
            if (native_ad == null) {
              return _build_skeleton();
            }

            return Semantics(
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
                    key: ValueKey<String>(
                      '${widget.slot_id}_${_controller.load_generation}',
                    ),
                    ad: native_ad,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  /// 骨架屏
  Widget _build_skeleton() {
    final Color base_color = widget.is_dark
        ? const Color(0xFF252836)
        : const Color(0xFFF0F1F5);
    final Color highlight_color = widget.is_dark
        ? const Color(0xFF2E3145)
        : const Color(0xFFF8F8FA);

    return AnimatedBuilder(
      animation: _shimmer_controller,
      builder: (BuildContext context, Widget? child) {
        final double p = _shimmer_controller.value;
        return Container(
          width: double.infinity,
          height: _controller.native_view_height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ShortStoryTabStyle.card_border_radius,
            ),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: <double>[
                (p - 0.3).clamp(0.0, 1.0),
                p.clamp(0.0, 1.0),
                (p + 0.3).clamp(0.0, 1.0),
              ],
              colors: <Color>[base_color, highlight_color, base_color],
            ),
          ),
        );
      },
    );
  }
}
