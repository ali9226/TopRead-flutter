// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:app/components/work_detail_skeleton/pulse.dart';
import 'package:app/pages/novel_discovery/style.dart';
import 'package:app/pages/novel_discovery/widgets/discovery_grid/skeleton.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// 整个首屏共用一个光扫时钟，分类、六本书目和操作栏均匹配真实排版。
class NovelsHomeSectionsSkeleton extends StatelessWidget {
  const NovelsHomeSectionsSkeleton({super.key, required this.is_dark});

  final bool is_dark;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final cjk = NovelDiscoveryStyle.is_cjk(context);
    final heading_extent =
        scaler.scale(
          cjk
              ? NovelsTabStyle.heading_size_cjk
              : NovelsTabStyle.heading_size_alphabetic,
        ) *
        (cjk
            ? NovelsTabStyle.heading_height_cjk
            : NovelsTabStyle.heading_height_alphabetic);
    final action_extent = math.max(
      NovelsTabStyle.action_min_height,
      scaler.scale(
                cjk
                    ? NovelsTabStyle.action_label_size_cjk
                    : NovelsTabStyle.action_label_size_alphabetic,
              ) *
              NovelsTabStyle.action_label_height +
          NovelsTabStyle.action_padding_v * 2,
    );
    return SkeletonPulse(
      is_dark: is_dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            var index = 0;
            index < NovelsTabStyle.skeleton_section_count;
            index++
          )
            Padding(
              padding: const EdgeInsets.only(
                bottom: NovelsTabStyle.section_gap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: heading_extent,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SkeletonBlock(
                        width: cjk
                            ? NovelsTabStyle.skeleton_heading_width_cjk
                            : NovelsTabStyle.skeleton_heading_width_alphabetic,
                        height: scaler.scale(
                          NovelsTabStyle.skeleton_heading_height,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: NovelsTabStyle.heading_gap),
                  const NovelDiscoverySkeleton(with_pulse: false),
                  const SizedBox(height: NovelsTabStyle.actions_top_gap),
                  SkeletonBlock(
                    height: action_extent,
                    radius: NovelsTabStyle.actions_radius,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
