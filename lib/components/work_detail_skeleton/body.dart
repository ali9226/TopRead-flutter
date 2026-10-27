import 'dart:math' as math;

import 'package:app/components/expandable_synopsis/style.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_about_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_item/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_section/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'comic_body.dart';
import 'short_story_body.dart';
import 'kind.dart';
import 'pulse.dart';
import 'style.dart';
import 'text_line.dart';

/// 三类作品按真实模块顺序占位，短篇同时保留可见的阅读正文区域。
class WorkDetailSkeletonBody extends StatelessWidget {
  const WorkDetailSkeletonBody({
    super.key,
    required this.kind,
    required this.is_dark,
  });

  final WorkDetailSkeletonKind kind;
  final bool is_dark;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    if (kind == WorkDetailSkeletonKind.comic) {
      return ComicDetailSkeletonBody(
        key: const ValueKey('work_detail_skeleton_body'),
        is_dark: is_dark,
        cjk: cjk,
      );
    }
    if (kind == WorkDetailSkeletonKind.short_story) {
      return ShortStorySkeletonBody(
        key: const ValueKey('work_detail_skeleton_body'),
        is_dark: is_dark,
      );
    }
    final novel = kind == WorkDetailSkeletonKind.novel;
    return Column(
      key: const ValueKey('work_detail_skeleton_body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kind != WorkDetailSkeletonKind.short_story)
          WindowReservedRegionPadding(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                novel
                    ? IntroductionStyle.content_horizontal_padding
                    : WorkAboutSectionStyle.horizontal_padding,
                novel
                    ? IntroductionStyle.tag_section_top_spacing
                    : WorkAboutSectionStyle.module_gap,
                novel
                    ? IntroductionStyle.content_horizontal_padding
                    : WorkAboutSectionStyle.horizontal_padding,
                novel
                    ? IntroductionStyle.content_bottom_spacing
                    : WorkAboutSectionStyle.module_gap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SkeletonSynopsis(cjk: cjk),
                  if (novel) ...[
                    const SizedBox(
                      height: IntroductionStyle.comment_top_spacing,
                    ),
                    _SkeletonComments(cjk: cjk, is_dark: is_dark),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 简介保留真实标题、四行行高和展开触控区域。
class _SkeletonSynopsis extends StatelessWidget {
  const _SkeletonSynopsis({required this.cjk});
  final bool cjk;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('work_detail_skeleton_synopsis'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonTextLine(
        width: cjk
            ? WorkDetailSkeletonStyle.heading_width_cjk
            : WorkDetailSkeletonStyle.heading_width_alphabetic,
        font_size: cjk
            ? ExpandableSynopsisStyle.embedded_title_size_cjk
            : ExpandableSynopsisStyle.embedded_title_size_alphabetic,
        line_height: ExpandableSynopsisStyle.embedded_title_height,
      ),
      const SizedBox(height: ExpandableSynopsisStyle.embedded_title_gap),
      ...List.generate(
        WorkDetailSkeletonStyle.synopsis_lines,
        (index) => SkeletonTextLine(
          font_size: cjk
              ? ExpandableSynopsisStyle.embedded_font_size_cjk
              : ExpandableSynopsisStyle.embedded_font_size_alphabetic,
          line_height: cjk
              ? ExpandableSynopsisStyle.embedded_line_height_cjk
              : ExpandableSynopsisStyle.embedded_line_height_alphabetic,
          width_factor: index == WorkDetailSkeletonStyle.synopsis_lines - 1
              ? WorkDetailSkeletonStyle.synopsis_last_line_ratio
              : 1,
        ),
      ),
      const SizedBox(height: ExpandableSynopsisStyle.toggle_top_gap),
      const Center(
        child: SkeletonBlock(
          width: ExpandableSynopsisStyle.toggle_extent,
          height: ExpandableSynopsisStyle.toggle_extent,
          radius: ExpandableSynopsisStyle.toggle_extent,
        ),
      ),
    ],
  );
}

/// 评论首屏对应独立作者行和整宽正文，不再预示旧的头像侧栏卡片。
class _SkeletonComments extends StatelessWidget {
  const _SkeletonComments({required this.cjk, required this.is_dark});
  final bool cjk;
  final bool is_dark;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('work_detail_skeleton_comments'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _rule(),
      const SizedBox(height: CommentStyle.heading_top_gap),
      LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          final heading_width = scaler.scale(
            cjk
                ? WorkDetailSkeletonStyle.heading_width_cjk
                : WorkDetailSkeletonStyle.heading_width_alphabetic,
          );
          final action_width = scaler.scale(
            cjk
                ? WorkDetailSkeletonStyle.review_action_width_cjk
                : WorkDetailSkeletonStyle.review_action_width_alphabetic,
          );
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: CommentStyle.header_action_gap,
            runSpacing: CommentStyle.heading_bottom_gap,
            children: [
              SizedBox(
                width: math.min(constraints.maxWidth, heading_width),
                child: SkeletonTextLine(
                  font_size: cjk
                      ? CommentStyle.heading_size_cjk
                      : CommentStyle.heading_size_alphabetic,
                  line_height: cjk
                      ? CommentStyle.heading_height_cjk
                      : CommentStyle.heading_height_alphabetic,
                ),
              ),
              SkeletonBlock(
                width: math.min(constraints.maxWidth, action_width),
                height: CommentStyle.action_extent,
                radius: CommentStyle.action_radius,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: CommentStyle.heading_bottom_gap),
      ...List.generate(
        WorkDetailSkeletonStyle.preview_comment_count,
        (index) => Column(
          children: [
            if (index > 0) _rule(),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: CommentItemStyle.vertical_padding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const SkeletonBlock(
                        width: CommentItemStyle.avatar_size,
                        height: CommentItemStyle.avatar_size,
                        radius: CommentItemStyle.avatar_size,
                      ),
                      const SizedBox(
                        width: CommentItemStyle.avatar_content_spacing,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonTextLine(
                              width: WorkDetailSkeletonStyle.comment_name_width,
                              font_size: cjk
                                  ? CommentItemStyle.name_font_size_cjk
                                  : CommentItemStyle.name_font_size_alphabetic,
                              line_height: cjk
                                  ? CommentItemStyle.name_line_height_cjk
                                  : CommentItemStyle
                                        .name_line_height_alphabetic,
                            ),
                            const SizedBox(
                              height: CommentItemStyle.rating_top_gap,
                            ),
                            Wrap(
                              spacing: CommentItemStyle.star_spacing,
                              children: List.generate(
                                CommentItemStyle.rating_max,
                                (_) => const SkeletonBlock(
                                  width: CommentItemStyle.star_size,
                                  height: CommentItemStyle.star_size,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: CommentItemStyle.body_top_gap),
                  ...List.generate(
                    WorkDetailSkeletonStyle.comment_lines,
                    (line_index) => SkeletonTextLine(
                      font_size: cjk
                          ? CommentItemStyle.text_font_size_cjk
                          : CommentItemStyle.text_font_size_alphabetic,
                      line_height: cjk
                          ? CommentItemStyle.text_line_height_cjk
                          : CommentItemStyle.text_line_height_alphabetic,
                      width_factor:
                          line_index ==
                              WorkDetailSkeletonStyle.comment_lines - 1
                          ? WorkDetailSkeletonStyle.comment_last_line_ratio
                          : 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _rule() => ColoredBox(
    color: CommentStyle.rule(is_dark),
    child: const SizedBox(height: CommentStyle.rule_width),
  );
}
