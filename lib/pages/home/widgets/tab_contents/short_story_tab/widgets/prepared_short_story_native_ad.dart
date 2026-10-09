// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/widgets/short_story_native_ad_card.dart';
import 'package:app/util/ad_display_policy.dart';

/// 列表保留广告位的决策，回滚或 cacheExtent 重建不会让错过的广告重新插入。
class PreparedShortStoryNativeAd extends StatelessWidget {
  final String slot_id;
  final bool is_dark;
  final ScrollController scroll_controller;
  final VoidCallback? on_skipped;
  final double initial_reserved_extent;
  final ValueChanged<double>? on_extent_changed;

  const PreparedShortStoryNativeAd({
    super.key,
    required this.slot_id,
    required this.is_dark,
    required this.scroll_controller,
    this.on_skipped,
    this.initial_reserved_extent = 0,
    this.on_extent_changed,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PreparedNativeAdSlot(
        key: ValueKey(slot_id),
        scroll_controller: scroll_controller,
        leading_extent: 0,
        trailing_extent: ShortStoryTabStyle.card_spacing,
        initial_reserved_extent: initial_reserved_extent,
        retain_attachment_offscreen: false,
        on_extent_changed: on_extent_changed,
        on_skipped: on_skipped,
        is_enabled: AdDisplayPolicy.can_show_ads(),
        builder:
            (
              context, {
              required attach_ad,
              required reserve_space,
              required on_load_status_changed,
              required on_layout_height_changed,
              required on_ad_attached,
            }) => ShortStoryNativeAdCard(
              slot_id: slot_id,
              is_dark: is_dark,
              attach_ad: attach_ad,
              reserve_space: reserve_space,
              on_load_status_changed: on_load_status_changed,
              on_layout_height_changed: on_layout_height_changed,
              on_ad_attached: on_ad_attached,
            ),
      ),
    );
  }
}
