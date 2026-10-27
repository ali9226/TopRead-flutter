import 'dart:math' as math;

import 'package:app/components/viewport_resize_observer/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/story_paragraph.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/pages/ranking_full_list/widgets/starfield_decoration.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/utils/resolve_next_story_preview_content.dart';
import 'package:app/pages/short_story_read/widgets/introduction/index.dart';
import 'package:app/pages/short_story_read/widgets/next_story_bottom_overlay.dart';
import 'package:app/pages/short_story_read/widgets/next_story_preview.dart';
import 'package:app/pages/short_story_read/widgets/reader_overlay_layer.dart';
import 'package:app/pages/short_story_read/widgets/previous_pull_header.dart';
import 'package:app/pages/short_story_read/widgets/story_scroll_metrics_observer.dart';
import 'package:app/pages/short_story_read/widgets/story_unlock_gate/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../story_pull_gesture.dart';

/// 正文区主题与排版参数。
class StoryContentTheme {
  const StoryContentTheme({
    required this.is_dark,
    required this.is_cjk,
    required this.bg_color,
    required this.title_color,
    required this.title_font_size,
  });

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 当前语种是否为 CJK。
  final bool is_cjk;

  /// 页面背景色。
  final Color bg_color;

  /// 下一篇预览标题颜色。
  final Color title_color;

  /// 下一篇预览标题字号（CJK 语系字号稍大）。
  final double title_font_size;
}

/// 正文区数据与动画状态（由页面 State 组装）。
class StoryContentState {
  const StoryContentState({
    required this.logic,
    required this.generation,
    required this.scroll_controller,
    required this.reader_scroll_physics,
    required this.page_transition_controller,
    required this.bottom_bar_slide_animation,
    required this.floating_button_fade_animation,
    required this.is_slide_up,
    required this.previous_pull_offset,
    required this.next_pull_offset,
    required this.next_story_overlay_opacity,
    required this.body_start_key,
    required this.story_end_key,
    required this.next_story_title_key,
    required this.has_reading_history,
    required this.is_paragraph_selection_active,
    required this.is_video_ad_gate_required,
    required this.is_rewarded_ad_loading,
    required this.native_ad_slot,
    required this.native_ad_insert_index,
    required this.show_floating_button,
  });

  /// 页面逻辑层。
  final ShortStoryReadLogic logic;

  /// 阅读树代数（切篇后失效）。
  final int generation;

  /// 主滚动控制器。
  final ScrollController scroll_controller;

  /// 阅读区滚动物理。
  final ScrollPhysics reader_scroll_physics;

  /// 翻页过渡动画。
  final Animation<double> page_transition_controller;

  /// 底部栏滑入滑出动画。
  final Animation<Offset> bottom_bar_slide_animation;

  /// 浮动按钮淡入淡出动画。
  final Animation<double> floating_button_fade_animation;

  /// 翻页方向（true = 向上滑出，false = 向下滑出）。
  final bool is_slide_up;

  /// 顶部下拉视觉位移。
  final double previous_pull_offset;

  /// 底部上拉视觉位移。
  final double next_pull_offset;

  /// 底部下一篇遮罩透明度。
  final double next_story_overlay_opacity;

  /// 正文起始锚点。
  final GlobalKey body_start_key;

  /// 当前篇正文结束锚点。
  final GlobalKey story_end_key;

  /// 下一篇标题定位 key。
  final GlobalKey next_story_title_key;

  /// 是否有历史（继续阅读状态）。
  final ValueNotifier<bool> has_reading_history;

  /// 段落选区是否激活。
  final bool is_paragraph_selection_active;

  /// 是否需要激励解锁。
  final bool is_video_ad_gate_required;

  /// 激励视频是否加载中。
  final bool is_rewarded_ad_loading;

  /// 就绪的原生广告卡片（未就绪为 null）。
  final Widget? native_ad_slot;

  /// 原生广告插入的段落下标。
  final int? native_ad_insert_index;

  /// 是否显示“下一篇”浮动按钮。
  final bool show_floating_button;
}

/// 正文区交互回调集合。
class StoryContentActions {
  const StoryContentActions({
    required this.on_content_tap,
    required this.on_pointer_down,
    required this.on_pointer_move,
    required this.on_pointer_end,
    required this.on_viewport_resize_start,
    required this.on_viewport_resize_end,
    required this.on_layout_pending,
    required this.on_extent_changed,
    required this.on_read_story,
    required this.on_cover_replaced,
    required this.on_back,
    required this.on_favorite,
    required this.on_share,
    required this.on_comment,
    required this.on_paragraph_comment,
    required this.on_paragraph_share,
    required this.on_paragraph_selection_changed,
    required this.on_comment_count_tap,
    required this.on_unlock,
    required this.on_previous_tap,
    required this.on_next_tap,
    required this.on_progress_changed,
    required this.on_progress_change_end,
    required this.on_scroll_to_bottom,
    required this.on_auto_read_settings_tap,
    required this.on_catalog_tap,
    required this.on_like_tap,
    required this.on_setting_tap,
    required this.schedule_next_story_overlay_update,
    required this.reader_text,
  });

  /// 正文单击：切换导航栏显隐。
  final VoidCallback on_content_tap;

  /// 指针按下：记录是否从选区开始。
  final VoidCallback on_pointer_down;

  /// 指针移动：上下拉切篇手势。
  final void Function(double dy) on_pointer_move;

  /// 指针抬起/取消：结束切篇手势。
  final VoidCallback on_pointer_end;

  /// 视口尺寸变化前保留章内进度。
  final VoidCallback on_viewport_resize_start;

  /// 视口尺寸变化后恢复章内进度。
  final VoidCallback on_viewport_resize_end;

  /// 正文布局待定：清空进度高度缓存。
  final VoidCallback on_layout_pending;

  /// 正文高度变化（带代数，旧篇丢弃）。
  final void Function(double extent, int generation) on_extent_changed;

  /// 开始阅读。
  final VoidCallback on_read_story;

  /// 封面替换完成回调。
  final void Function(String url, int width, int height) on_cover_replaced;

  /// 返回。
  final VoidCallback on_back;

  /// 收藏。
  final Future<void> Function() on_favorite;

  /// 分享。
  final VoidCallback on_share;

  /// 打开评论弹窗（是否展示入口由主题开关决定，回调本身始终存在）。
  final Future<void> Function({int scroll_to_comment_id}) on_comment;

  /// 段落评论。
  final Future<void> Function(StoryParagraph, TextSelection)?
  on_paragraph_comment;

  /// 段落分享。
  final void Function(StoryParagraph, TextSelection)? on_paragraph_share;

  /// 选区状态变化。
  final void Function(bool active) on_paragraph_selection_changed;

  /// 评论数点击（段落文本、评论数、段落 ID）。
  final void Function(
    String paragraph_text,
    int comment_count,
    String? paragraph_id,
  )
  on_comment_count_tap;

  /// 激励解锁正文。
  final VoidCallback on_unlock;

  /// 上一篇。
  final VoidCallback on_previous_tap;

  /// 下一篇。
  final VoidCallback on_next_tap;

  /// 进度拖动中。
  final void Function(double progress) on_progress_changed;

  /// 进度拖动结束。
  final void Function(double progress, VoidCallback on_complete)
  on_progress_change_end;

  /// 滚到底部看下一篇。
  final VoidCallback on_scroll_to_bottom;

  /// 自动阅读设置。
  final VoidCallback on_auto_read_settings_tap;

  /// 打开目录。
  final VoidCallback on_catalog_tap;

  /// 点赞。
  final Future<void> Function() on_like_tap;

  /// 打开阅读设置。
  final Future<void> Function() on_setting_tap;

  /// 重算底部遮罩透明度。
  final VoidCallback schedule_next_story_overlay_update;

  /// 内置多语种文案查询。
  final String Function(String key) reader_text;
}

/// 短篇正文滚动区组件树：背景 → 可滚动正文 → 底部遮罩 → 覆盖层。
///
/// 页面 State 只负责组装 [StoryContentTheme] / [StoryContentState] /
/// [StoryContentActions]，渲染树全部收敛在本组件内。
class StoryContentStack extends StatelessWidget {
  const StoryContentStack({
    super.key,
    required this.theme,
    required this.state,
    required this.actions,
    required this.status_bar_height,
    required this.bottom_padding,
  });

  /// 主题与排版参数。
  final StoryContentTheme theme;

  /// 数据与动画状态。
  final StoryContentState state;

  /// 交互回调。
  final StoryContentActions actions;

  /// 状态栏高度。
  final double status_bar_height;

  /// 底部安全区高度。
  final double bottom_padding;

  @override
  Widget build(BuildContext context) {
    final ShortStoryReadLogic logic = state.logic;
    final bool is_dark = theme.is_dark;

    /// 标签列表。
    final List<String> tags = logic.category_list;

    /// 分享等业务开关继续由项目配置决定，封面统计已替换为简介。
    final project_config = Get.find<ProjectConfigStore>().current;

    /// 是否需要在正文底部展示下一篇预览。
    final bool has_next_preview = logic.next_story_item != null;

    /// 有下一篇预览时，底部不要再保留过大的普通正文留白。
    final double scroll_bottom_padding =
        (has_next_preview ? 18.0 : ShortStoryReadStyle.page_bottom_padding) +
        bottom_padding;

    final double next_pull_hint_opacity =
        ((state.next_pull_offset - 22.0) / 96.0).clamp(0.0, 1.0);
    final bool next_pull_ready =
        state.next_pull_offset >=
        StoryPullGestureController.next_pull_trigger_distance;

    /// 下一篇的预览文字：优先用目录简介，预加载失败也不断层。
    final String next_story_preview_content =
        resolve_next_story_preview_content(
          description: logic.next_story_item?.description ?? '',
          preloaded_content: logic.next_story_content.value,
        );

    // 下一篇简介预览不能用固定高度：上拉时可见高度随真实位移增长。
    final double next_preview_line_height = theme.is_cjk
        ? ShortStoryReadStyle.body_height_cjk
        : ShortStoryReadStyle.body_height_alphabetic;
    final int next_preview_visible_line_count = theme.is_cjk
        ? ShortStoryReadStyle.next_preview_visible_line_count_cjk
        : ShortStoryReadStyle.next_preview_visible_line_count_alphabetic;
    final double next_preview_body_height =
        (logic.body_font_size.value *
            next_preview_line_height *
            next_preview_visible_line_count) +
        bottom_padding +
        state.next_pull_offset;
    final int next_preview_max_lines = math.max(
      next_preview_visible_line_count,
      (next_preview_body_height /
                  (logic.body_font_size.value * next_preview_line_height))
              .ceil() +
          ShortStoryReadStyle.next_preview_overflow_buffer_line_count,
    );

    final bool show_next_bottom_overlay =
        has_next_preview && state.next_story_overlay_opacity > 0.01;

    if (has_next_preview) {
      actions.schedule_next_story_overlay_update();
    }

    return Stack(
      children: <Widget>[
        /// 背景装饰（底层）。
        StarfieldDecoration(is_dark: is_dark),
        WindowContentLayout(
          child: Stack(
            fit: StackFit.expand,
            children: [
              /// 顶部下拉查看上一篇提示（露出在当前页面背后）。
              PreviousPullHeader(
                is_dark: is_dark,
                status_bar_height: status_bar_height,
                pull_offset: state.previous_pull_offset,
                trigger_distance:
                    StoryPullGestureController.previous_pull_trigger_distance,
                previous_title: logic.previous_story_item?.title ?? '',
                localized_texts: <String, String>{
                  'pull_down_view': actions.reader_text('pull_down_view'),
                  'release_view': actions.reader_text('release_view'),
                },
              ),

              /// 正文内容（可滚动，点击切换导航栏显隐，翻页时滑动消失）。
              AnimatedBuilder(
                animation: state.page_transition_controller,
                builder: (BuildContext context, Widget? child) {
                  final double progress =
                      state.page_transition_controller.value;
                  final double transition_offset_y = state.is_slide_up
                      ? -progress * MediaQuery.sizeOf(context).height
                      : progress * MediaQuery.sizeOf(context).height;
                  // 底部上拉的露出由 `_sync_next_preview_scroll_position` 同步
                  // 内部滚动位置实现，这里只叠加翻页位移与顶部下拉位移。
                  final double offset_y =
                      transition_offset_y + state.previous_pull_offset;

                  return Transform.translate(
                    offset: Offset(0, offset_y),
                    child: child,
                  );
                },
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => actions.on_pointer_down(),
                  onPointerMove: (PointerMoveEvent event) =>
                      actions.on_pointer_move(event.delta.dy),
                  onPointerUp: (_) => actions.on_pointer_end(),
                  onPointerCancel: (_) => actions.on_pointer_end(),
                  child: GestureDetector(
                    onTap: actions.on_content_tap,
                    behavior: HitTestBehavior.translucent,
                    child: ViewportResizeObserver(
                      on_resize_start: actions.on_viewport_resize_start,
                      on_resize_end: actions.on_viewport_resize_end,
                      child: StoryScrollMetricsObserver(
                        scroll_controller: state.scroll_controller,
                        story_end_key: state.story_end_key,
                        on_layout_pending: actions.on_layout_pending,
                        on_extent_changed: (extent) =>
                            actions.on_extent_changed(extent, state.generation),
                        child: SingleChildScrollView(
                          controller: state.scroll_controller,
                          physics: state.reader_scroll_physics,
                          padding: EdgeInsets.only(
                            bottom: scroll_bottom_padding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (logic.story_data.value != null)
                                ValueListenableBuilder<bool>(
                                  valueListenable: state.has_reading_history,
                                  builder: (context, continuing, _) =>
                                      ShortStoryIntroduction(
                                        on_read: actions.on_read_story,
                                        continuing: continuing,
                                        detail: logic.story_data.value!,
                                        is_dark: is_dark,
                                        tags: tags,
                                        catalog_entries: logic.catalog_list
                                            .toList(),
                                        favorite_loading:
                                            logic.is_favorite_loading.value,
                                        on_back: actions.on_back,
                                        on_favorite: actions.on_favorite,
                                        on_share:
                                            project_config.is_share_enabled
                                            ? actions.on_share
                                            : null,
                                        on_cover_replaced:
                                            actions.on_cover_replaced,
                                      ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: ShortStoryReadStyle
                                      .page_horizontal_padding,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// 零高度正文锚点与业务门控独立，既有结束锚点保持原位。
                                    SizedBox(
                                      key: state.body_start_key,
                                      height: 0,
                                    ),

                                    /// 正文内容。
                                    StoryUnlockGate(
                                      key: ValueKey(logic.story_id),
                                      content: logic.content.value,
                                      is_dark: is_dark,
                                      is_loading:
                                          logic.is_content_loading.value,
                                      is_unlocked:
                                          logic.is_story_unlocked.value ||
                                          !state.is_video_ad_gate_required,
                                      is_unlocking:
                                          state.is_rewarded_ad_loading,
                                      font_size: logic.body_font_size.value,
                                      on_unlock: actions.on_unlock,
                                      native_ad_widget: state.native_ad_slot,
                                      native_ad_insert_index:
                                          state.native_ad_insert_index,
                                      paragraph_anchors: logic.paragraph_anchors
                                          .toList(),
                                      on_paragraph_comment:
                                          project_config.is_comment_enabled
                                          ? actions.on_paragraph_comment
                                          : null,
                                      on_paragraph_share:
                                          project_config.is_share_enabled
                                          ? actions.on_paragraph_share
                                          : null,
                                      on_selection_changed: actions
                                          .on_paragraph_selection_changed,
                                      on_content_tap: actions.on_content_tap,
                                      on_comment_count_tap:
                                          actions.on_comment_count_tap,
                                    ),

                                    /// 当前篇正文结束位置，用于准确计算进度和恢复位置。
                                    SizedBox(
                                      key: state.story_end_key,
                                      height: 0,
                                    ),

                                    /// 下一篇小说预览（固定显示在正文下方）。
                                    if (has_next_preview)
                                      NextStoryPreview(
                                        next_story: logic.next_story_item!,
                                        body_font_size:
                                            logic.body_font_size.value,
                                        is_dark: is_dark,
                                        is_cjk: theme.is_cjk,
                                        title_font_size: theme.title_font_size,
                                        title_color: theme.title_color,
                                        body_color: is_dark
                                            ? ShortStoryReadStyle
                                                  .body_dark_color
                                            : ShortStoryReadStyle
                                                  .body_light_color,
                                        secondary_color: is_dark
                                            ? ShortStoryReadStyle
                                                  .secondary_dark_color
                                            : ShortStoryReadStyle
                                                  .secondary_light_color,
                                        preview_body_height:
                                            next_preview_body_height,
                                        preview_max_lines:
                                            next_preview_max_lines,
                                        preview_line_height:
                                            next_preview_line_height,
                                        preview_content:
                                            next_story_preview_content,
                                        title_key: state.next_story_title_key,
                                        reader_text: actions.reader_text,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /// 底部下一篇渐变遮罩（贯穿屏幕底部，文案固定在安全区内）。
              if (show_next_bottom_overlay)
                NextStoryBottomOverlay(
                  is_dark: is_dark,
                  bg_color: theme.bg_color,
                  bottom_padding: bottom_padding,
                  overlay_opacity: state.next_story_overlay_opacity,
                  hint_opacity: next_pull_hint_opacity,
                  pull_ready: next_pull_ready,
                  view_next_label: actions.reader_text('view_next'),
                ),
            ],
          ),
        ),

        /// 覆盖层（导航栏+评论栏+浮动按钮）。
        AnimatedBuilder(
          animation: state.scroll_controller,
          builder: (context, _) => Obx(
            () => ReaderOverlayLayer(
              title: logic.title,
              show_top_bar:
                  state.scroll_controller.hasClients &&
                  state.scroll_controller.offset >
                      status_bar_height + ShortStoryReadStyle.appbar_height,
              is_dark: is_dark,
              status_bar_height: status_bar_height,
              bottom_padding: bottom_padding,
              bg_color: theme.bg_color,
              is_appbar_visible: logic.is_appbar_visible.value,
              bottom_bar_slide_animation: state.bottom_bar_slide_animation,
              floating_button_fade_animation:
                  state.floating_button_fade_animation,
              show_floating_button: state.show_floating_button,
              show_progress_bar:
                  !logic.is_loading.value && !logic.is_error.value,
              catalog_loaded:
                  !logic.is_catalog_loading.value &&
                  logic.catalog_list.isNotEmpty,
              is_favorited: logic.is_favorited,
              is_favorite_loading: logic.is_favorite_loading.value,
              comment_count: logic.comment_count,
              like_count: logic.like_count,
              is_liked: logic.is_liked,
              is_like_loading: logic.is_like_loading.value,
              reading_progress: logic.reading_progress.value,
              has_previous: logic.has_previous_story,
              has_next: logic.has_next_story,
              is_bottom_bar_visible: logic.is_bottom_bar_visible.value,
              is_auto_reading: logic.is_auto_reading.value,
              on_back: actions.on_back,
              on_favorite_tap: actions.on_favorite,
              on_share: actions.on_share,
              on_catalog_tap: actions.on_catalog_tap,
              on_comment_tap: actions.on_comment,
              on_like_tap: actions.on_like_tap,
              on_setting_tap: actions.on_setting_tap,
              on_previous_tap: actions.on_previous_tap,
              on_next_tap: actions.on_next_tap,
              on_progress_changed: actions.on_progress_changed,
              on_progress_change_end: actions.on_progress_change_end,
              on_scroll_to_bottom: actions.on_scroll_to_bottom,
              on_auto_read_settings_tap: actions.on_auto_read_settings_tap,
            ),
          ),
        ),
      ],
    );
  }
}
