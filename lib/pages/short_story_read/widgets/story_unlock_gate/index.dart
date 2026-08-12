import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/utils/create_story_content_preview.dart';
import 'package:app/pages/short_story_read/widgets/story_content.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'unlock_overlay.dart';

/// 短篇小说正文的激励广告解锁区域。
///
/// 解锁前只展示大约二分之一的正文，并在折叠位置使用渐变遮罩和
/// 观看广告按钮。解锁后直接展示完整正文。
class StoryUnlockGate extends StatelessWidget {
  const StoryUnlockGate({
    required this.content,
    required this.is_dark,
    required this.is_loading,
    required this.is_unlocked,
    required this.is_unlocking,
    required this.font_size,
    required this.on_unlock,
    this.native_ad_widget,
    super.key,
  });

  /// 完整正文。
  final String content;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 正文是否正在加载。
  final bool is_loading;

  /// 当前短篇是否已经解锁。
  final bool is_unlocked;

  /// 激励广告是否正在加载或展示。
  final bool is_unlocking;

  /// 当前正文字号。
  final double font_size;

  /// 用户点击观看广告按钮时执行的回调。
  final VoidCallback on_unlock;

  /// 原生广告横幅组件（可选）。
  ///
  /// 非空时在正文 1/4 位置插入原生广告。
  final Widget? native_ad_widget;

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    if (is_loading || is_unlocked || content.trim().isEmpty) {
      return StoryContent(
        content: content,
        is_dark: is_dark,
        is_loading: is_loading,
        font_size: font_size,
        native_ad_widget: native_ad_widget,
      );
    }

    final StoryContentPreviewData preview_data = create_story_content_preview(
      content: content,
      is_cjk: is_cjk,
      preview_ratio: ShortStoryReadStyle.locked_content_preview_ratio,
      fade_tail_count: is_cjk
          ? ShortStoryReadStyle.unlock_fade_tail_count_cjk
          : ShortStoryReadStyle.unlock_fade_tail_count_alphabetic,
    );
    if (preview_data.remaining_count <= 0) {
      return StoryContent(
        content: content,
        is_dark: is_dark,
        font_size: font_size,
        native_ad_widget: native_ad_widget,
      );
    }

    final double gate_height = is_cjk
        ? ShortStoryReadStyle.unlock_gate_height_cjk
        : ShortStoryReadStyle.unlock_gate_height_alphabetic;
    final double gradient_overlap_height = is_cjk
        ? ShortStoryReadStyle.unlock_gradient_overlap_height_cjk
        : ShortStoryReadStyle.unlock_gradient_overlap_height_alphabetic;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StoryContent(
              key: const ValueKey<String>('story_unlock_faded_content'),
              content: preview_data.preview_content,
              is_dark: is_dark,
              font_size: font_size,
              native_ad_widget: native_ad_widget,
            ),
            SizedBox(height: gate_height),
          ],
        ),
        Positioned(
          left: -ShortStoryReadStyle.page_horizontal_padding,
          right: -ShortStoryReadStyle.page_horizontal_padding,
          bottom: 0,
          height: gate_height + gradient_overlap_height,
          child: UnlockOverlay(
            remaining_count: preview_data.remaining_count,
            is_dark: is_dark,
            is_cjk: is_cjk,
            is_unlocking: is_unlocking,
            on_unlock: on_unlock,
          ),
        ),
      ],
    );
  }
}
