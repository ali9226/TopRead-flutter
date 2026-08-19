import 'package:flutter/material.dart';

import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/widgets/full_appbar.dart';
import 'package:app/pages/short_story_read/widgets/bottom_comment_bar.dart';
import 'package:app/pages/short_story_read/widgets/scroll_to_bottom_button.dart';
import 'package:app/pages/short_story_read/widgets/auto_read_settings_button.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';

/// 阅读页覆盖层。
///
/// 包含顶部导航栏、底部评论栏、浮动按钮和渐变遮罩，
/// 叠加在正文滚动区域之上。
class ReaderOverlayLayer extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 状态栏高度。
  final double status_bar_height;

  /// 底部安全区域高度。
  final double bottom_padding;

  /// 页面背景色。
  final Color bg_color;

  /// 导航栏是否可见。
  final bool is_appbar_visible;

  /// 底部栏滑动动画。
  final Animation<Offset> bottom_bar_slide_animation;

  /// 浮动按钮淡入淡出动画。
  final Animation<double> floating_button_fade_animation;

  /// 是否显示浮动按钮。
  final bool show_floating_button;

  /// 是否显示进度条。
  final bool show_progress_bar;

  /// 目录是否已加载。
  final bool catalog_loaded;

  /// 是否已收藏。
  final bool is_favorited;

  /// 收藏是否加载中。
  final bool is_favorite_loading;

  /// 评论数。
  final int comment_count;

  /// 点赞数。
  final int like_count;

  /// 是否已点赞。
  final bool is_liked;

  /// 点赞是否加载中。
  final bool is_like_loading;

  /// 阅读进度。
  final double reading_progress;

  /// 是否有上一篇。
  final bool has_previous;

  /// 是否有下一篇。
  final bool has_next;

  /// 底部栏是否可见。
  final bool is_bottom_bar_visible;

  /// 是否正在自动阅读。
  final bool is_auto_reading;

  // ========== 回调 ==========
  final VoidCallback on_back;
  final VoidCallback on_favorite_tap;
  final VoidCallback on_share;
  final VoidCallback on_catalog_tap;
  final VoidCallback on_comment_tap;
  final VoidCallback on_like_tap;
  final VoidCallback on_setting_tap;
  final VoidCallback on_previous_tap;
  final VoidCallback on_next_tap;
  final void Function(double progress) on_progress_changed;
  final void Function(double progress, VoidCallback on_complete) on_progress_change_end;
  final VoidCallback on_scroll_to_bottom;
  final VoidCallback on_auto_read_settings_tap;

  const ReaderOverlayLayer({
    super.key,
    required this.is_dark,
    required this.status_bar_height,
    required this.bottom_padding,
    required this.bg_color,
    required this.is_appbar_visible,
    required this.bottom_bar_slide_animation,
    required this.floating_button_fade_animation,
    required this.show_floating_button,
    required this.show_progress_bar,
    required this.catalog_loaded,
    required this.is_favorited,
    required this.is_favorite_loading,
    required this.comment_count,
    required this.like_count,
    required this.is_liked,
    required this.is_like_loading,
    required this.reading_progress,
    required this.has_previous,
    required this.has_next,
    required this.is_bottom_bar_visible,
    required this.is_auto_reading,
    required this.on_back,
    required this.on_favorite_tap,
    required this.on_share,
    required this.on_catalog_tap,
    required this.on_comment_tap,
    required this.on_like_tap,
    required this.on_setting_tap,
    required this.on_previous_tap,
    required this.on_next_tap,
    required this.on_progress_changed,
    required this.on_progress_change_end,
    required this.on_scroll_to_bottom,
    required this.on_auto_read_settings_tap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        /// 顶部渐变过渡遮罩。
        PageTopGradientOverlay(background_color: bg_color),

        /// 顶部导航栏。
        AnimatedPositioned(
          duration: ShortStoryReadStyle.bar_animation_duration,
          curve: ShortStoryReadStyle.bar_animation_curve,
          top: is_appbar_visible
              ? 0
              : -(status_bar_height + ShortStoryReadStyle.appbar_height),
          left: 0,
          right: 0,
          child: FullAppbar(
            is_dark: is_dark,
            on_back: on_back,
            on_favorite_tap: on_favorite_tap,
            on_share: on_share,
            is_favorited: is_favorited,
            is_favorite_loading: is_favorite_loading,
            status_bar_height: status_bar_height,
          ),
        ),

        /// 底部评论栏。
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: bottom_bar_slide_animation,
            child: BottomCommentBar(
              is_dark: is_dark,
              comment_count: comment_count,
              like_count: like_count,
              is_liked: is_liked,
              is_like_loading: is_like_loading,
              on_catalog_tap: on_catalog_tap,
              on_comment_tap: on_comment_tap,
              on_like_tap: on_like_tap,
              on_setting_tap: on_setting_tap,
              show_progress_bar: show_progress_bar,
              catalog_loaded: catalog_loaded,
              progress: reading_progress,
              has_previous: has_previous,
              has_next: has_next,
              on_previous_tap: on_previous_tap,
              on_next_tap: on_next_tap,
              on_progress_changed: on_progress_changed,
              on_progress_change_end: on_progress_change_end,
            ),
          ),
        ),

        /// 右下角浮动按钮。
        if (show_floating_button)
          Positioned(
            right: 16,
            bottom: (show_progress_bar
                    ? ShortStoryReadStyle.bottom_bar_height +
                        ShortStoryReadStyle.progress_bar_height
                    : ShortStoryReadStyle.bottom_bar_height) +
                bottom_padding +
                16,
            child: FadeTransition(
              opacity: floating_button_fade_animation,
              child: IgnorePointer(
                ignoring: !is_bottom_bar_visible,
                child: ScrollToBottomButton(
                  is_dark: is_dark,
                  opacity: 1.0,
                  on_tap: on_scroll_to_bottom,
                ),
              ),
            ),
          ),

        /// 自动阅读设置按钮。
        if (is_auto_reading)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom_padding + 16,
            child: Center(
              child: AutoReadSettingsButton(
                is_dark: is_dark,
                on_tap: on_auto_read_settings_tap,
              ),
            ),
          ),
      ],
    );
  }
}
