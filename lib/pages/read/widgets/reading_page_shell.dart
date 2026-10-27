import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/components/viewport_resize_observer/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/style.dart';
import 'package:app/pages/read/widgets/auto_read_settings_button/index.dart';
import 'package:app/pages/read/widgets/main_list/index.dart';
import 'package:app/pages/read/widgets/navigation_bars/bottom/index.dart';
import 'package:app/pages/read/widgets/navigation_bars/top/index.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/index.dart';
import 'package:app/pages/read/widgets/reading_progress_mask/index.dart';
import 'package:app/pages/read/widgets/reading_progress_text/index.dart';
import 'package:app/pages/read/widgets/rewarded_ad_loading_overlay/index.dart';
import 'package:app/pages/read/widgets/skeleton/content_skeleton.dart';
import 'package:app/pages/read/widgets/skeleton/index.dart';
import 'package:app/pages/ranking_full_list/widgets/starfield_decoration.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 长篇页面主题与几何参数。
class ReadingPageTheme {
  const ReadingPageTheme({
    required this.is_dark,
    required this.background_color,
    required this.status_bar_height,
  });

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 页面背景色。
  final Color background_color;

  /// 状态栏高度。
  final double status_bar_height;
}

/// 长篇页面数据、通知器与广告状态。
///
/// 进度/开始阅读/续读历史使用 [ValueListenable] 驱动局部重建，
/// 避免滚动时整棵正文树反复重建。
class ReadingPageState {
  const ReadingPageState({
    required this.logic,
    required this.detail,
    required this.reading_items,
    required this.reading_section_key,
    required this.has_started_reading,
    required this.reading_progress,
    required this.has_reading_history,
    required this.ad_free_expire_time,
    required this.is_restoring_progress,
    required this.cached_chapter_progress,
    required this.native_ad_config,
    required this.is_native_ad_config_loading,
    required this.native_ads_enabled,
    required this.is_rewarded_ad_loading,
  });

  /// 页面逻辑层。
  final Logic logic;

  /// 组装后的展示详情。
  final ReadDetail detail;

  /// 正文内容项。
  final List<ReadingContentItem> reading_items;

  /// 正文区块定位 key。
  final GlobalKey reading_section_key;

  /// 是否已进入正文。
  final ValueListenable<bool> has_started_reading;

  /// 全书阅读进度（百分比）。
  final ValueListenable<double> reading_progress;

  /// 是否有阅读历史（续读 UI）。
  final ValueListenable<bool> has_reading_history;

  /// 免广告到期时间（null 表示不在免广告期）。
  final ValueListenable<DateTime?> ad_free_expire_time;

  /// 恢复服务器进度期间（骨架覆盖）。
  final bool is_restoring_progress;

  /// 当前章内进度（目录弹窗定位用）。
  final double cached_chapter_progress;

  /// 原生广告配置。
  final AdConfig? native_ad_config;

  /// 原生广告配置是否加载中。
  final bool is_native_ad_config_loading;

  /// 是否允许展示正文广告。
  final bool native_ads_enabled;

  /// 激励视频是否加载中。
  final bool is_rewarded_ad_loading;
}

/// 长篇页面交互回调集合。
class ReadingPageActions {
  const ReadingPageActions({
    required this.on_back,
    required this.on_refresh,
    required this.on_read,
    required this.on_open_comments,
    required this.on_favorite,
    required this.on_share,
    required this.on_native_ad_impression,
    required this.on_video_ad_hint_tap,
    required this.on_reading_tap_down,
    required this.on_paragraph_comment,
    required this.on_paragraph_comments,
    required this.on_paragraph_share,
    required this.on_paragraph_selection_changed,
    required this.on_viewport_resize_start,
    required this.on_viewport_resize_end,
    required this.on_scroll_notification,
    required this.on_progress_jump,
    required this.on_prev_chapter,
    required this.on_next_chapter,
    required this.on_catalog_chapter_tap,
    required this.on_setting_tap,
    required this.on_like_tap,
    required this.on_auto_read_settings_tap,
  });

  /// 返回。
  final VoidCallback on_back;

  /// 下拉刷新。
  final Future<void> Function() on_refresh;

  /// 开始阅读（滚动到正文）。
  final VoidCallback on_read;

  /// 打开评论。
  final VoidCallback on_open_comments;

  /// 收藏。
  final VoidCallback on_favorite;

  /// 分享（可空隐藏）。
  final VoidCallback? on_share;

  /// 原生广告真实展示上报。
  final VoidCallback on_native_ad_impression;

  /// 看视频免广告提示点击。
  final VoidCallback on_video_ad_hint_tap;

  /// 正文三段式点击。
  final GestureTapDownCallback on_reading_tap_down;

  /// 段落评论。
  final void Function(ReadingContentItem, TextSelection)? on_paragraph_comment;

  /// 段落评论列表。
  final ValueChanged<ReadingContentItem>? on_paragraph_comments;

  /// 段落分享。
  final void Function(ReadingContentItem, TextSelection)? on_paragraph_share;

  /// 段落选区变化。
  final void Function(ReadingContentItem, bool)? on_paragraph_selection_changed;

  /// 视口变化前保留进度。
  final VoidCallback on_viewport_resize_start;

  /// 视口变化后恢复进度。
  final VoidCallback on_viewport_resize_end;

  /// 主滚动通知。
  final bool Function(ScrollNotification notification) on_scroll_notification;

  /// 进度条拖到目标百分比（0-100）后的跳转。
  final Future<void> Function(double target_percent) on_progress_jump;

  /// 上一章。
  final VoidCallback on_prev_chapter;

  /// 下一章。
  final VoidCallback on_next_chapter;

  /// 目录点击某章。
  final void Function(int index) on_catalog_chapter_tap;

  /// 打开阅读设置。
  final VoidCallback on_setting_tap;

  /// 点赞。
  final Future<void> Function() on_like_tap;

  /// 自动阅读设置。
  final VoidCallback on_auto_read_settings_tap;
}

/// 长篇阅读页渲染树：骨架 / 正文栈 / 导读辅助层 / 导航与覆盖层。
///
/// 页面 State 只组装 [ReadingPageTheme] / [ReadingPageState] /
/// [ReadingPageActions]，Widget 组合全部收敛在本组件内。
class ReadingPageShell extends StatelessWidget {
  const ReadingPageShell({
    super.key,
    required this.theme,
    required this.state,
    required this.actions,
  });

  /// 主题与几何参数。
  final ReadingPageTheme theme;

  /// 数据与通知器状态。
  final ReadingPageState state;

  /// 交互回调。
  final ReadingPageActions actions;

  @override
  Widget build(BuildContext context) {
    final Logic logic = state.logic;
    final bool is_dark = theme.is_dark;
    final Color background_color = theme.background_color;
    final ReadDetail detail = state.detail;

    // 首次接口尚未返回时只展示骨架屏；阅读记录恢复阶段让正文在骨架层下
    // 正常参与布局，完成精确定位后再撤下覆盖层。
    if (logic.is_loading.value) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: background_color,
        body: WindowContentLayout(
          child: ReadSkeleton(is_dark: is_dark, on_back: actions.on_back),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: background_color,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: ColorConstants.transparent,
        body: Stack(
          children: <Widget>[
            StarfieldDecoration(is_dark: is_dark),
            WindowContentLayout(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 主内容滚动组件。
                  NotificationListener<ScrollNotification>(
                    onNotification: actions.on_scroll_notification,
                    child: RefreshIndicator(
                      color: ColorConstants.themeColor,
                      displacement: Style.refresh_indicator_displacement,
                      notificationPredicate: (ScrollNotification notification) {
                        return notification.depth == 0 &&
                            logic.should_show_introduction &&
                            !state.has_started_reading.value &&
                            !logic.show_navigation.value;
                      },
                      onRefresh: actions.on_refresh,
                      child: ViewportResizeObserver(
                        on_resize_start: actions.on_viewport_resize_start,
                        on_resize_end: actions.on_viewport_resize_end,
                        child: ReadMainList(
                          logic: logic,
                          scroll_controller: logic.scroll_controller,
                          status_bar_height: theme.status_bar_height,
                          is_dark: is_dark,
                          detail: detail,
                          on_read: actions.on_read,
                          on_comments: actions.on_open_comments,
                          on_favorite: actions.on_favorite,
                          favorited: logic.is_favorited.value,
                          favorite_loading: logic.is_favorite_loading.value,
                          continuing_listenable: state.has_reading_history,
                          on_back: actions.on_back,
                          on_share: actions.on_share,
                          reading_items: state.reading_items,
                          reading_section_key: state.reading_section_key,
                          on_reading_tap_down: actions.on_reading_tap_down,
                          on_paragraph_comment: actions.on_paragraph_comment,
                          on_paragraph_comments: actions.on_paragraph_comments,
                          on_paragraph_share: actions.on_paragraph_share,
                          on_paragraph_selection_changed:
                              actions.on_paragraph_selection_changed,
                          // 关闭广告保留已提交插位的身份，由插位安全回收上方高度。
                          native_ad_config: state.native_ad_config,
                          is_native_ad_config_loading:
                              state.is_native_ad_config_loading,
                          native_ads_enabled: state.native_ads_enabled,
                          on_native_ad_impression:
                              actions.on_native_ad_impression,
                          ads_read_video_ad_probability:
                              state.native_ads_enabled
                              ? Get.find<ProjectConfigStore>()
                                    .current
                                    .ads_read_video_ad_probability
                              : 0,
                          ad_free_expire_time_listenable:
                              state.ad_free_expire_time,
                          on_video_ad_hint_tap: actions.on_video_ad_hint_tap,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 封面头图使用自己的深色渐变；进入正文后才启用状态栏遮罩。
            ValueListenableBuilder<bool>(
              valueListenable: state.has_started_reading,
              builder: (context, has_started, _) => PageTopGradientOverlay(
                background_color: background_color,
                visible: has_started || !logic.should_show_introduction,
              ),
            ),
            WindowContentLayout(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 滚动过程中仅重建轻量阅读辅助层，不触发正文树重建。
                  ValueListenableBuilder<bool>(
                    valueListenable: state.has_started_reading,
                    builder:
                        (
                          BuildContext context,
                          bool has_started,
                          Widget? child,
                        ) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                duration: Duration(
                                  milliseconds:
                                      Style.progress_mask_animation_duration_ms,
                                ),
                                opacity: has_started ? 1 : 0,
                                child: child,
                              ),
                            ),
                          );
                        },
                    child: ReadingProgressMask(is_dark: is_dark),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: state.has_started_reading,
                    builder:
                        (
                          BuildContext context,
                          bool has_started,
                          Widget? child,
                        ) {
                          return ValueListenableBuilder<double>(
                            valueListenable: state.reading_progress,
                            builder:
                                (
                                  BuildContext context,
                                  double progress,
                                  Widget? child,
                                ) {
                                  return ReadingProgressText(
                                    is_dark: is_dark,
                                    reading_progress_percent: progress,
                                    has_started_reading: has_started,
                                  );
                                },
                          );
                        },
                  ),
                ],
              ),
            ),
            // 导航显隐单独订阅，不能依赖正文或进度变化带动本组件刷新。
            Obx(
              () => ReadTopBar(
                is_dark: is_dark,
                title:
                    logic.current_chapter_index.value >= 0 &&
                        logic.current_chapter_index.value <
                            logic.chapter_list.length
                    ? logic
                          .chapter_list[logic.current_chapter_index.value]
                          .title
                    : '',
                show: logic.show_navigation.value,
                on_back: actions.on_back,
                on_favorite_tap: actions.on_favorite,
                on_share: actions.on_share ?? () {},
                is_favorited: logic.is_favorited.value,
                is_favorite_loading: logic.is_favorite_loading.value,
              ),
            ),
            // 底部导航栏的进度由独立通知器驱动，正文不参与重建。
            ValueListenableBuilder<double>(
              valueListenable: state.reading_progress,
              builder:
                  (
                    BuildContext context,
                    double progress_percent,
                    Widget? child,
                  ) {
                    return Obx(
                      () => ReadBottomBar(
                        is_dark: is_dark,
                        show: logic.show_navigation.value,
                        progress: progress_percent / 100,
                        chapter_list: logic.chapter_list,
                        chapter_index_for_progress: (double value) {
                          return logic.find_chapter_index_by_progress(
                            value * 100,
                          );
                        },
                        on_progress_changed_end: (double value) async {
                          await actions.on_progress_jump(value * 100);
                        },
                        on_prev_chapter: actions.on_prev_chapter,
                        on_next_chapter: actions.on_next_chapter,
                        is_first_chapter: logic.is_first_chapter,
                        is_last_chapter: logic.is_last_chapter,
                        on_catalog_tap: () {
                          logic.show_navigation.value = false;
                          ReadDirectorySheet.show(
                            context: context,
                            logic: logic,
                            is_dark: is_dark,
                            current_chapter_progress_percent:
                                state.cached_chapter_progress,
                            on_chapter_tap: actions.on_catalog_chapter_tap,
                          );
                        },
                        on_setting_tap: actions.on_setting_tap,
                        comment_count: logic.comment_count,
                        on_comment_tap: actions.on_open_comments,
                        is_liked: logic.is_liked.value,
                        like_count: logic.like_count.value,
                        is_like_loading: logic.is_like_loading.value,
                        on_like_tap: actions.on_like_tap,
                      ),
                    );
                  },
            ),
            WindowContentLayout(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 自动阅读设置浮动按钮（自动阅读时显示在底部居中）。
                  if (logic.is_auto_reading.value)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
                      child: Center(
                        child: AutoReadSettingsButton(
                          is_dark: is_dark,
                          on_tap: actions.on_auto_read_settings_tap,
                        ),
                      ),
                    ),
                  // 初始进度恢复或目录跳转时，用骨架覆盖已参与布局的正文及
                  // 所有交互层；目标位置稳定后一次性显现。
                  if (state.is_restoring_progress ||
                      logic.is_jumping_chapter.value)
                    Positioned.fill(
                      child: Container(
                        color: background_color,
                        child: ReadContentSkeleton(
                          is_dark: is_dark,
                          font_size: logic.body_font_size.value,
                        ),
                      ),
                    ),
                  // 激励视频准备期间显示转圈并吸收点击，防止重复触发。
                  if (state.is_rewarded_ad_loading)
                    Positioned.fill(
                      child: RewardedAdLoadingOverlay(is_dark: is_dark),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
