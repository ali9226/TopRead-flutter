// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:app/components/work_detail_skeleton/pulse.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/discovery_grid/skeleton.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// 整个首屏共用一个光扫时钟，分类、六本书目和操作栏均匹配真实排版。
class ComicsHomeSectionsSkeleton extends StatelessWidget {
  const ComicsHomeSectionsSkeleton({super.key, required this.is_dark});

  final bool is_dark;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final cjk = ComicsStyle.is_cjk(context);
    final heading_extent =
        scaler.scale(
          cjk
              ? ComicsTabStyle.heading_size_cjk
              : ComicsTabStyle.heading_size_alphabetic,
        ) *
        (cjk
            ? ComicsTabStyle.heading_height_cjk
            : ComicsTabStyle.heading_height_alphabetic);
    final action_extent = math.max(
      ComicsTabStyle.action_min_height,
      scaler.scale(
                cjk
                    ? ComicsTabStyle.action_label_size_cjk
                    : ComicsTabStyle.action_label_size_alphabetic,
              ) *
              ComicsTabStyle.action_label_height +
          ComicsTabStyle.action_padding_v * 2,
    );
    return SkeletonPulse(
      is_dark: is_dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            var index = 0;
            index < ComicsTabStyle.skeleton_section_count;
            index++
          )
            Padding(
              padding: const EdgeInsets.only(
                bottom: ComicsTabStyle.section_gap,
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
                            ? ComicsTabStyle.skeleton_heading_width_cjk
                            : ComicsTabStyle.skeleton_heading_width_alphabetic,
                        height: scaler.scale(
                          ComicsTabStyle.skeleton_heading_height,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: ComicsTabStyle.heading_gap),
                  const ComicDiscoverySkeleton(with_pulse: false),
                  const SizedBox(height: ComicsTabStyle.actions_top_gap),
                  SkeletonBlock(
                    height: action_extent,
                    radius: ComicsTabStyle.actions_radius,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
