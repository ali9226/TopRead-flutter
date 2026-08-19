import 'package:flutter/material.dart';

import 'package:app/pages/read/style.dart';
import 'package:app/pages/read/widgets/reading_progress_mask/index.dart';
import 'package:app/pages/read/widgets/reading_progress_text/index.dart';
import 'package:app/pages/read/widgets/start_reading_pill/index.dart';
import 'package:app/pages/read/widgets/navigation_bars/top/index.dart';
import 'package:app/pages/read/widgets/navigation_bars/bottom/index.dart';
import 'package:app/pages/read/widgets/auto_read_settings_button/index.dart';
import 'package:app/pages/read/widgets/skeleton/content_skeleton.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/logic.dart';

/// 长篇阅读页覆盖层。
///
/// 包含进度遮罩、进度文字、开始阅读胶囊、顶部/底部导航栏、
/// 自动阅读按钮和骨架覆盖层，叠加在正文滚动区域之上。
class ReadPageOverlay extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 页面背景色。
  final Color background_color;

  /// 底部胶囊背景色。
  final Color bottom_pill_background_color;

  /// 是否已开始阅读。
  final bool has_started_reading;

  /// 阅读进度百分比（0-100）。
  final double reading_progress_percent;

  /// 是否显示导航栏。
  final bool show_navigation;

  /// 是否已收藏。
  final bool is_favorited;

  /// 收藏是否加载中。
  final bool is_favorite_loading;

  /// 是否已点赞。
  final bool is_liked;

  /// 点赞数。
  final int like_count;

  /// 点赞是否加载中。
  final bool is_like_loading;

  /// 评论数。
  final int comment_count;

  /// 是否正在自动阅读。
  final bool is_auto_reading;

  /// 是否正在恢复进度或跳转章节。
  final bool is_restoring;

  /// 章节列表。
  final List<NovelChapterInfo> chapter_list;

  /// 当前章节索引。
  final int current_chapter_index;

  /// 是否为第一章。
  final bool is_first_chapter;

  /// 是否为最后一章。
  final bool is_last_chapter;

  /// 逻辑层引用。
  final Logic logic;

  /// 缓存的章节内进度。
  final double cached_chapter_progress;

  // ========== 回调 ==========
  final VoidCallback on_scroll_to_reading_section;
  final VoidCallback on_back;
  final VoidCallback on_favorite_tap;
  final VoidCallback on_share;
  final VoidCallback on_setting_tap;
  final VoidCallback on_comment_tap;
  final VoidCallback on_like_tap;
  final VoidCallback on_auto_read_settings_tap;
  final void Function(int index) on_chapter_tap;
  final Future<void> Function(int index) on_execute_chapter_jump;
  final void Function(double value) on_progress_changed_end;

  const ReadPageOverlay({
    super.key,
    required this.is_dark,
    required this.background_color,
    required this.bottom_pill_background_color,
    required this.has_started_reading,
    required this.reading_progress_percent,
    required this.show_navigation,
    required this.is_favorited,
    required this.is_favorite_loading,
    required this.is_liked,
    required this.like_count,
    required this.is_like_loading,
    required this.comment_count,
    required this.is_auto_reading,
    required this.is_restoring,
    required this.chapter_list,
    required this.current_chapter_index,
    required this.is_first_chapter,
    required this.is_last_chapter,
    required this.logic,
    required this.cached_chapter_progress,
    required this.on_scroll_to_reading_section,
    required this.on_back,
    required this.on_favorite_tap,
    required this.on_share,
    required this.on_setting_tap,
    required this.on_comment_tap,
    required this.on_like_tap,
    required this.on_auto_read_settings_tap,
    required this.on_chapter_tap,
    required this.on_execute_chapter_jump,
    required this.on_progress_changed_end,
  });

  @override
  Widget build(BuildContext context) {
    final double bottom_safe_area = MediaQuery.viewPaddingOf(context).bottom;

    return Stack(
      children: <Widget>[
        /// 阅读进度遮罩。
        IgnorePointer(
          child: AnimatedOpacity(
            duration: Duration(
              milliseconds: Style.progress_mask_animation_duration_ms,
            ),
            opacity: has_started_reading ? 1 : 0,
            child: ReadingProgressMask(is_dark: is_dark),
          ),
        ),

        /// 阅读进度文字。
        ReadingProgressText(
          is_dark: is_dark,
          reading_progress_percent: reading_progress_percent,
          has_started_reading: has_started_reading,
        ),

        /// 开始阅读胶囊。
        ReadStartReadingPill(
          is_dark: is_dark,
          show_start_reading_pill: !has_started_reading,
          bottom_pill_background_color: bottom_pill_background_color,
          bottom_safe_area: bottom_safe_area,
          on_tap: on_scroll_to_reading_section,
        ),

        /// 顶部导航栏。
        ReadTopBar(
          is_dark: is_dark,
          show: show_navigation,
          on_back: on_back,
          on_favorite_tap: on_favorite_tap,
          on_share: on_share,
          is_favorited: is_favorited,
          is_favorite_loading: is_favorite_loading,
        ),

        /// 底部导航栏。
        ReadBottomBar(
          is_dark: is_dark,
          show: show_navigation,
          progress: reading_progress_percent / 100,
          chapter_list: chapter_list,
          chapter_index_for_progress: (double value) {
            return logic.find_chapter_index_by_progress(value * 100);
          },
          on_progress_changed_end: on_progress_changed_end,
          on_prev_chapter: () async {
            await on_execute_chapter_jump(current_chapter_index - 1);
          },
          on_next_chapter: () async {
            await on_execute_chapter_jump(current_chapter_index + 1);
          },
          is_first_chapter: is_first_chapter,
          is_last_chapter: is_last_chapter,
          on_catalog_tap: () {
            logic.show_navigation.value = false;
            on_chapter_tap(current_chapter_index);
          },
          on_setting_tap: on_setting_tap,
          comment_count: comment_count,
          on_comment_tap: on_comment_tap,
          is_liked: is_liked,
          like_count: like_count,
          is_like_loading: is_like_loading,
          on_like_tap: on_like_tap,
        ),

        /// 自动阅读设置按钮。
        if (is_auto_reading)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom_safe_area + 16,
            child: Center(
              child: AutoReadSettingsButton(
                is_dark: is_dark,
                on_tap: on_auto_read_settings_tap,
              ),
            ),
          ),

        /// 进度恢复/跳章骨架覆盖。
        if (is_restoring || logic.is_jumping_chapter.value)
          Positioned.fill(
            child: Container(
              color: background_color,
              child: ReadContentSkeleton(is_dark: is_dark),
            ),
          ),
      ],
    );
  }
}
