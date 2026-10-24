// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:app/pages/read/utils/scroll_utils.dart';
import 'package:app/pages/read/widgets/reading_settings_sheet/index.dart';
import 'package:app/pages/read/widgets/auto_read_settings_sheet/index.dart';
import 'package:app/stores/comment_navigation.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/read_ad_free_store.dart';
import 'package:app/pages/read/read_ad_unlock_controller.dart';
import 'package:app/pages/read/reading_auto_read.dart';
import 'package:app/pages/read/reading_chapter_anchor.dart';
import 'package:app/pages/read/reading_chapter_jump.dart';
import 'package:app/pages/read/reading_native_ad_gate.dart';
import 'package:app/pages/read/widgets/reading_page_shell.dart';
import 'package:app/pages/read/reading_scroll_progress.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/share_sheet/index.dart';
import 'package:app/components/share_sheet/widgets/text_selection_preview_sheet.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

import 'package:app/components/paragraph_selection/actions.dart';

import 'logic.dart';
import 'style.dart';

/// 阅读页占位页面。
class ReadPage extends StatefulWidget {
  /// 路由传入的书籍 id。
  final int story_id;

  /// 路由传入的标题。
  final String story_title;

  /// 从消息页跳转时传入的评论ID（用于自动打开评论区并定位）。
  final int initial_comment_id;

  /// 可复用页面逻辑实例；默认仍由当前路由创建，便于验证真实阅读与重排生命周期。
  final Logic? controller;

  const ReadPage({
    super.key,
    required this.story_id,
    required this.story_title,
    this.initial_comment_id = 0,
    this.controller,
  });

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin
    implements
    ReadAdUnlockHost,
    AutoReadHost,
    ChapterAnchorHost,
    ScrollProgressHost,
    ReadingNativeAdHost,
    ChapterJumpHost {
  /// 页面逻辑层，用于承载页面数据组装与业务判断。
  late final Logic logic;

  /// 页面滚动控制器，从当前路由独享的逻辑层获取。
  ScrollController get scroll_controller => logic.scroll_controller;

  /// 设备信息仓库，用于读取当前主题模式等全局设备状态。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 用户信息仓库，用于检查登录状态。
  final UserInformation user_information = Get.find<UserInformation>();

  /// 正文区块定位锚点，用于点击底部胶囊后精确滚动到正文位置。
  final GlobalKey reading_section_key = GlobalKey();

  /// 是否已经进入正文阅读状态，用于控制底部胶囊与进度条显隐。
  bool has_started_reading = false;

  /// 已存在历史或本次已经进入正文；回滚简介不会清除续读状态。
  final ValueNotifier<bool> _has_reading_history_notifier = ValueNotifier(
    false,
  );

  /// 最近一次真实正文位置，避免回看简介后主按钮把用户送回第一章。
  ({int index, double progress, String? chapter_id}) _resume_target = (
    index: 0,
    progress: 0,
    chapter_id: null,
  );

  /// 长短篇共用的弹窗入口与当前选择状态；选区建立后暂停自动阅读。
  final ParagraphActions _paragraph_actions = ParagraphActions();
  final Set<String> _selected_paragraphs = <String>{};

  // ==================== 状态变量 ====================

  /// 是否正在恢复阅读进度（静默加载目标章节，不展示第一章内容）。
  bool _is_restoring_progress = false;

  /// 缓存的章节内进度百分比（与目录显示一致，由字数算法计算）。
  double _cached_chapter_progress = 0;

  /// FCM 推送评论导航监听器。
  Worker? _comment_navigation_worker;

  /// 详情加载失败监听器。
  Worker? _error_worker;

  /// 项目广告开关变更监听器。
  Worker? _ad_policy_worker;

  /// 页面首次数据与阅读进度初始化任务。
  late final Future<void> _initialization_future;

  /// 阅读进度展示通知器。
  ///
  /// 滚动过程中只刷新进度相关小组件，避免整页正文随每个像素重建。
  final ValueNotifier<double> _reading_progress_notifier =
      ValueNotifier<double>(0);

  // ==================== 广告相关状态 ====================




  /// 是否进入正文区域的展示通知器。
  final ValueNotifier<bool> _has_started_reading_notifier = ValueNotifier<bool>(
    false,
  );

  /// 当前滚动进度百分比，用于展示底部阅读进度文字。
  double reading_progress_percent = 0;

  /// 最近一次记录的视口高度，用于预取和滚动范围计算。
  double last_viewport_dimension = 0;

  /// 布局变化前记录的章节索引。
  int pending_restore_chapter_index = 0;

  /// 布局变化前记录的章节内进度。
  double pending_restore_chapter_progress = 0;

  /// 是否需要在下一帧恢复滚动位置。
  bool needs_restore_scroll_position = false;

  /// 正文区块是否已经贴近顶部，用于控制翻页点击区域是否生效。
  bool is_reading_section_at_top = false;




  /// 是否正在执行程序化滚动（点击翻页），此时不触发导航栏显隐。
  bool _is_programmatic_scroll = false;



  /// 是否正在执行章节窗口重建与精确定位。
  bool _is_chapter_transaction_active = false;

  /// 当前进度是否已经由稳定布局计算或恢复完成。
  bool _has_stable_progress = false;

  /// 阅读进度定时保存定时器。
  Timer? _progress_save_timer;

  /// 阅读进度保存间隔（秒）。
  static const int _progress_save_interval_seconds = 10;

  /// 用户是否有过真实阅读行为（滚动过内容）。
  bool _has_user_engaged = false;

  /// 免广告权益与激励解锁控制器。
  late final ReadAdUnlockController _ad_unlock;

  /// 自动阅读引擎。
  late final ReadingAutoReadController _auto_read;

  /// 章节锚点与滚动恢复协调器。
  late final ReadingChapterAnchor _anchor;

  /// 原生广告门控（配置拉取与章节概率）。
  late final ReadingNativeAdGate _native_ad;

  /// 章节跳转事务与服务器进度恢复。
  late final ReadingChapterJump _jump;

  /// 滚动进度识别与章节预取器。
  late final ReadingScrollProgress _scroll_progress;

  /// 长篇权益在整个应用共享，页面退出后奖励校验仍可继续。
  late final ReadAdFreeStore _ad_free_store;
  Worker? _ad_free_state_worker;

  // ==================== 生命周期 ====================

  @override
  void initState() {
    // 先执行父类初始化，确保生命周期状态可用。
    super.initState();
    // 注册屏幕尺寸变化监听，用于处理横竖屏切换后滚动位置恢复。
    WidgetsBinding.instance.addObserver(this);
    // Logic 与当前阅读路由一一对应，避免不同小说共享章节窗口和滚动控制器。
    // 普通主题重建不会销毁 State，因此无需把页面级控制器常驻到 GetX 容器。
    logic =
        widget.controller ??
        Logic(story_id: widget.story_id, story_title: widget.story_title);
    // 确保进入页面时导航栏处于关闭状态。
    logic.show_navigation.value = false;
    _anchor = ReadingChapterAnchor(host: this);
    _native_ad = ReadingNativeAdGate(host: this);
    _jump = ReadingChapterJump(host: this);
    _scroll_progress = ReadingScrollProgress(host: this);
    logic.wait_until_chapter_mutation_allowed = _anchor.wait_until_scroll_idle;
    logic.preserve_chapter_anchor = _anchor.preserve_chapter_anchor;
    logic.on_chapter_loaded = _native_ad.on_chapter_loaded;

    // 路由参数非法时回退首页，避免渲染异常状态页面。
    if (!logic.has_valid_story_id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        routerUtil(path: '/', type: 'replace');
      });
      return;
    }

    // 注册滚动监听，驱动阅读进度、底部胶囊和翻页区域状态更新。
    scroll_controller.addListener(_scroll_progress.handle_scroll);

    // 进入页面时请求接口，有阅读进度时静默加载目标章节。
    _initialization_future = _jump.init_with_progress_restore();

    // 权益按设备与认证用户共享，切换小说不会重新创建奖励生命周期。
    _ad_free_store = Get.isRegistered<ReadAdFreeStore>()
        ? Get.find<ReadAdFreeStore>()
        : Get.put(ReadAdFreeStore(), permanent: true);
    _ad_unlock = ReadAdUnlockController(
      host: this,
      ad_free_store: _ad_free_store,
    );
    _auto_read = ReadingAutoReadController(
      host: this,
      logic: logic,
      ticker_provider: this,
    );
    _ad_free_state_worker = ever(
      _ad_free_store.state_revision,
      (_) => _ad_unlock.apply_shared_ad_free_state(),
    );
    _ad_unlock.apply_shared_ad_free_state();
    unawaited(_ad_free_store.refresh());

    // 项目配置异步到达或更新时统一同步正文广告状态。
    _ad_policy_worker = ever(
      Get.find<ProjectConfigStore>().config_revision,
      (_) => _native_ad.sync_ad_policy(),
    );
    _native_ad.sync_ad_policy();

    // 从消息页跳转时，等待阅读页初始化完成后再打开评论区，避免两个路由动画
    // 与初始进度定位同时执行。
    if (widget.initial_comment_id > 0) {
      unawaited(_open_initial_comment_after_ready());
    }

    // TODO 监听 FCM 推送点击事件（用户已在当前页面时收到推送）
    _comment_navigation_worker = ever(CommentNavigation.pending_comment_id, (
      int comment_id,
    ) {
      if (!mounted || comment_id <= 0) return;
      if (CommentNavigation.pending_novel_id.value != widget.story_id) return;
      CommentNavigation.consume();
      _open_comment_sheet(scroll_to_comment_id: comment_id);
    });

    // 监听错误状态，如果失败自动后退返回上一页。
    _error_worker = ever(logic.is_error, (bool is_error) {
      if (is_error) {
        AppRouter.back();
      }
    });
  }

  // ==================== 广告管理 ====================

  /// 等待阅读页初始化完成后打开路由指定的评论。
  Future<void> _open_initial_comment_after_ready() async {
    await _initialization_future;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _open_comment_sheet(scroll_to_comment_id: widget.initial_comment_id);
  }

  // ==================== 销毁 ====================

  @override
  void dispose() {
    _progress_save_timer?.cancel();
    _ad_unlock.dispose();
    _ad_free_state_worker?.dispose();
    // 退出页面时保存一次阅读进度。
    _save_current_progress_on_exit();
    _auto_read.dispose();
    _comment_navigation_worker?.dispose();
    _error_worker?.dispose();
    _ad_policy_worker?.dispose();
    logic.wait_until_chapter_mutation_allowed = null;
    logic.preserve_chapter_anchor = null;
    logic.on_chapter_loaded = null;
    _anchor.notify_scroll_activity_ended();
    _reading_progress_notifier.dispose();
    _has_started_reading_notifier.dispose();
    _has_reading_history_notifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    scroll_controller.removeListener(_scroll_progress.handle_scroll);
    logic.onClose();
    super.dispose();
  }

  /// 真实阅读视口改变前保留章内进度。只改变宽度也会导致正文重新换行。
  void _on_viewport_resize_start() {
    if (!scroll_controller.hasClients ||
        !has_started_reading ||
        logic.is_loading.value ||
        _is_restoring_progress ||
        !_has_stable_progress) {
      return;
    }

    pending_restore_chapter_index = logic.current_chapter_index.value;
    pending_restore_chapter_progress = _cached_chapter_progress;
    needs_restore_scroll_position = true;
  }

  /// 新布局完成后沿用章节事务恢复，避免与切章或服务器续读同时写滚动位置。
  void _on_viewport_resize_end() {
    if (!mounted || !scroll_controller.hasClients) return;
    last_viewport_dimension = scroll_controller.position.viewportDimension;
    _try_restore_pending_viewport_change();
  }

  /// 当前没有章节事务时，恢复视口变化前的章节位置。
  void _try_restore_pending_viewport_change() {
    if (!mounted ||
        !needs_restore_scroll_position ||
        _is_chapter_transaction_active) {
      return;
    }
    unawaited(_anchor.restore_scroll_position_after_layout());
  }

  /// 启动阅读进度定时保存定时器。
  void _start_progress_save_timer() {
    _progress_save_timer?.cancel();
    _progress_save_timer = Timer.periodic(
      const Duration(seconds: _progress_save_interval_seconds),
      (_) => _save_current_progress(),
    );
  }

  /// 退出页面时保存阅读进度（同步执行，确保数据不丢失）。
  void _save_current_progress_on_exit() {
    unawaited(_save_current_progress(notify_bookshelf: true));
  }

  /// 保存当前阅读进度到服务器。
  Future<void> _save_current_progress({bool notify_bookshelf = false}) async {
    if (!mounted ||
        !scroll_controller.hasClients ||
        logic.is_loading.value ||
        _is_restoring_progress ||
        _is_chapter_transaction_active ||
        !_has_stable_progress ||
        !_has_user_engaged) {
      return;
    }

    final double progress = reading_progress_percent;
    final int chapter_id = logic.current_chapter_db_id;

    // 章节内百分比：用缓存的字数算法结果（与目录显示一致）。
    final double chapter_progress = _cached_chapter_progress;

    debugPrint(
      '💾 [长篇保存-定时] progress=${progress.toStringAsFixed(1)}, '
      'chapter_id=$chapter_id, chapter_progress=${chapter_progress.toStringAsFixed(1)}%',
    );

    if (!user_information.isLoggedIn.value) return;

    final int novel_language_id = logic.current_novel_language_id;
    final bool saved = await save_read_progress(
      novel_id: widget.story_id,
      novel_language_id: novel_language_id > 0 ? novel_language_id : null,
      chapter_id: chapter_id > 0 ? chapter_id : null,
      chapter_offset: chapter_progress.round(),
      read_progress: progress,
    );
    if (saved && notify_bookshelf) {
      await BookshelfSyncService.history_changed();
    }
  }

  /// 下拉刷新小说详情和当前第一章正文内容。
  Future<void> _refresh_novel_content() async {
    logic.show_navigation.value = false;
    await logic.fetch_info(
      force: true,
      show_loading: false,
      bypass_chapter_cache: true,
    );

    if (!mounted) {
      return;
    }

    _scroll_progress.handle_scroll();
  }

  /// 更新阅读进度并仅通知依赖进度的小组件。
  void _set_reading_progress(double progress_percent) {
    final double next_percent = progress_percent.clamp(0.0, 100.0);
    reading_progress_percent = next_percent;
    if ((_reading_progress_notifier.value - next_percent).abs() >
        Style.progress_update_epsilon) {
      _reading_progress_notifier.value = next_percent;
    }
  }

  /// 更新是否进入正文，并仅通知底部阅读辅助层。
  void _set_has_started_reading(bool value) {
    has_started_reading = value;
    if (value) {
      _has_reading_history_notifier.value = true;
      _resume_target = (
        index: logic.current_chapter_index.value,
        progress: _cached_chapter_progress,
        chapter_id:
            logic.current_chapter_index.value >= 0 &&
                logic.current_chapter_index.value < logic.chapter_list.length
            ? logic.chapter_list[logic.current_chapter_index.value].id
            : null,
      );
    }
    if (_has_started_reading_notifier.value != value) {
      _has_started_reading_notifier.value = value;
    }
  }

  // ==================== 滚动处理 ====================

  /// 处理正文三段式点击。
  ///
  /// 页面在点击发生时读取最新滚动和导航状态，正文段落无需随滚动重建。
  void _handle_reading_tap_down(TapDownDetails details) {
    if (!is_reading_section_at_top ||
        _is_chapter_transaction_active ||
        _paragraph_actions.is_open) {
      return;
    }
    if (_selected_paragraphs.isNotEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }

    if (logic.is_auto_reading.value) {
      _auto_read.stop();
    }
    if (logic.show_navigation.value) {
      logic.toggle_navigation();
      return;
    }

    final double screen_height = MediaQuery.sizeOf(context).height;
    final double bottom_reserved_height =
        MediaQuery.viewPaddingOf(context).bottom +
        Style.reading_tap_bottom_reserved_height;
    final double effective_height = (screen_height - bottom_reserved_height)
        .clamp(0.0, screen_height);
    final double block_height =
        effective_height / Style.reading_tap_block_count;
    final double tap_y = details.globalPosition.dy;

    if (tap_y <= block_height) {
      unawaited(_scroll_page_up());
    } else if (tap_y >= block_height * Style.reading_tap_middle_block_factor) {
      unawaited(_scroll_page_down());
    } else {
      logic.toggle_navigation();
    }
  }

  /// 跨章同一偏移的段落保持独立，失焦通知不会覆盖另一个段落的选择。
  void _on_paragraph_selection_changed(ReadingContentItem item, bool active) {
    final key =
        '${item.chapter_id}:${item.body_content_hash}:${item.start_offset}';
    if (active) {
      _selected_paragraphs.add(key);
      _auto_read.stop();
    } else {
      _selected_paragraphs.remove(key);
    }
  }

  /// 固定当前段落的原文选区，通过公共入口处理登录、输入及发送。
  Future<void> _on_paragraph_comment(
    ReadingContentItem item,
    TextSelection selection,
  ) async {
    _auto_read.stop();
    logic.show_navigation.value = false;
    final success = await _paragraph_actions.compose(
      context: context,
      paragraph_text: item.text,
      selection: selection,
      is_dark: device_info.dark.value,
      is_current: () => mounted && !_is_chapter_transaction_active,
      resolve_anchor: () =>
          logic.resolve_paragraph_anchor(item, novel_id: widget.story_id),
      on_send: (anchor, text, images) => logic.send_paragraph_comment(
        item: item,
        anchor: anchor,
        selection: selection,
        text: text,
        images: images,
        novel_id: widget.story_id,
      ),
    );
    // 段评发送成功后，乐观更新小说总评论数
    if (success == true && mounted) {
      logic.update_comment_count(logic.comment_count + 1);
    }
  }

  /// 处理段落选中文字的分享操作。
  void _on_paragraph_share(ReadingContentItem item, TextSelection selection) {
    _auto_read.stop();
    logic.show_navigation.value = false;
    final String selected_text = selected_paragraph_text(item.text, selection);
    if (selected_text.trim().isEmpty) return;
    final ReadDetail detail = logic.build_detail();
    showTextSelectionPreviewSheet(
      context: context,
      novel_id: widget.story_id,
      novel_title: detail.title,
      novel_author: detail.author_name,
      novel_cover_url: detail.cover_url,
      share_text: selected_text,
      is_dark: device_info.dark.value,
    );
  }

  /// 打开段评详情弹窗，使用统一的评论组件。
  void _on_paragraph_comments(ReadingContentItem item) {
    final anchor = item.anchor;
    if (anchor == null) return;
    final int para_id = int.tryParse(anchor.id) ?? 0;
    if (para_id <= 0) return;
    _auto_read.stop();
    logic.show_navigation.value = false;
    unawaited(
      showCommentSheet(
        context: context,
        novel_id: widget.story_id,
        paragraph_id: para_id,
        on_close: () => Navigator.pop(context),
        on_paragraph_count_changed: (count) =>
            logic.update_paragraph_comment_count(
              item: item,
              paragraph_id: anchor.id,
              count: count,
            ),
        on_novel_count_changed: (delta) {
          // 段评增删时，乐观更新小说总评论数
          logic.update_comment_count(logic.comment_count + delta);
        },
      ),
    );
  }

  /// 程序化上翻一屏。
  Future<void> _scroll_page_up() async {
    if (_is_programmatic_scroll) return;
    // 点击翻页属于真实阅读操作，不能依赖只在手势滚动时发送的通知。
    if (scroll_controller.hasClients &&
        scroll_controller.offset >
            scroll_controller.position.minScrollExtent +
                Style.scroll_offset_epsilon) {
      _has_user_engaged = true;
    }
    _is_programmatic_scroll = true;
    try {
      await ScrollUtils.scroll_page_up(
        scroll_controller: scroll_controller,
        context: context,
      );
    } finally {
      _is_programmatic_scroll = false;
    }
  }

  /// 程序化下翻一屏。
  Future<void> _scroll_page_down() async {
    if (_is_programmatic_scroll) return;
    if (scroll_controller.hasClients &&
        scroll_controller.offset <
            scroll_controller.position.maxScrollExtent -
                Style.scroll_offset_epsilon) {
      _has_user_engaged = true;
    }
    _is_programmatic_scroll = true;
    try {
      await ScrollUtils.scroll_page_down(
        scroll_controller: scroll_controller,
        context: context,
      );
    } finally {
      _is_programmatic_scroll = false;
    }
  }

  /// 自动滚动到正文阅读位置，方便用户快速从封面区域进入正文区域。
  Future<void> _scroll_to_reading_section() async {
    // 连续点击复用正在进行的定位，避免动画被后一次操作打断或覆盖续读位置。
    if (!mounted ||
        logic.is_loading.value ||
        _is_restoring_progress ||
        _is_chapter_transaction_active ||
        _is_programmatic_scroll) {
      return;
    }
    final double? previous_offset = scroll_controller.hasClients
        ? scroll_controller.offset
        : null;
    if (_has_reading_history_notifier.value && logic.chapter_list.isNotEmpty) {
      // 刷新目录后优先按章节身份恢复；目录变短时仍保证落在有效章节。
      final matched_index = _resume_target.chapter_id == null
          ? -1
          : logic.chapter_list.indexWhere(
              (chapter) => chapter.id == _resume_target.chapter_id,
            );
      final target_index = matched_index >= 0
          ? matched_index
          : _resume_target.index.clamp(0, logic.chapter_list.length - 1);
      // 历史正文位置独立于当前简介区域的滚动进度，续读不会重新开始。
      await _jump.execute_chapter_jump(
        target_index,
        chapter_progress_percent: _resume_target.progress,
        animate_scroll: true,
        reuse_loaded_chapter: true,
      );
    } else {
      // 首次阅读同样保留现有正文；程序滚动不参与手势方向检测。
      _is_programmatic_scroll = true;
      logic.show_navigation.value = false;
      try {
        await _anchor.scroll_to_chapter_title_with_top_offset(
          0,
          top_offset: Style.chapter_title_top_target_offset,
        );
      } finally {
        _is_programmatic_scroll = false;
        if (mounted && scroll_controller.hasClients) {
          logic.sync_scroll_offset(scroll_controller.offset);
        }
      }
    }
    if (mounted &&
        previous_offset != null &&
        scroll_controller.hasClients &&
        (scroll_controller.offset - previous_offset).abs() >
            Style.scroll_offset_epsilon) {
      _has_user_engaged = true;
    }
  }

  /// 显示阅读设置弹窗。
  void _showSettingsSheet() {
    logic.show_navigation.value = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: ColorConstants.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (BuildContext sheet_context) {
        return ReadSettingsSheet(
          body_font_size: logic.body_font_size,
          font_size_min: Logic.font_size_min,
          font_size_max: Logic.font_size_max,
          on_increase_font_size: () {
            unawaited(_change_font_size(logic.increase_font_size));
          },
          on_decrease_font_size: () {
            unawaited(_change_font_size(logic.decrease_font_size));
          },
          on_close: () => Navigator.of(sheet_context).pop(),
          on_auto_read: () {
            Navigator.of(sheet_context).pop();
            _auto_read.start(mark_user_engaged: () => _has_user_engaged = true);
          },
        );
      },
    );
  }

  /// 修改字号后恢复到同一章节内进度，避免排版重流导致阅读位置漂移。
  Future<void> _change_font_size(VoidCallback mutation) async {
    if (_is_chapter_transaction_active) return;

    final int chapter_index = logic.current_chapter_index.value;
    final double chapter_progress = _cached_chapter_progress;
    needs_restore_scroll_position = false;
    _is_chapter_transaction_active = true;
    mutation();

    try {
      await _anchor.wait_until_reading_layout_ready(chapter_index);
      if (!mounted) return;
      await _anchor.scroll_to_chapter_progress(
        chapter_index,
        chapter_progress_percent: chapter_progress,
      );
    } finally {
      _is_chapter_transaction_active = false;
    }
  }

  /// 显示自动阅读设置弹窗。
  void _on_auto_read_settings_tap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: ColorConstants.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (BuildContext sheet_context) {
        return AutoReadSettingsSheet(
          auto_read_speed: logic.auto_read_speed,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_exit: () {
            Navigator.of(sheet_context).pop();
            _auto_read.stop();
          },
        );
      },
    );
  }

  /// TODO 打开评论弹窗，支持定位到指定评论。
  Future<void> _open_comment_sheet({int scroll_to_comment_id = 0}) async {
    logic.show_navigation.value = false;
    final int? new_count = await showCommentSheet(
      context: context,
      novel_id: widget.story_id,
      on_close: () => Navigator.pop(context),
      scroll_to_comment_id: scroll_to_comment_id,
    );
    if (new_count != null) {
      logic.update_comment_count(new_count);
    }
  }

  // ==================== UI 构建 ====================

  /// 简介头图与正文工具栏共用原来的小说分享入口。
  void _show_novel_share(ReadDetail detail, bool is_dark) {
    showShareSheet(
      context: context,
      novel_id: widget.story_id,
      novel_title: detail.title,
      novel_author: detail.author_name,
      novel_cover_url: detail.cover_url,
      novel_intro: detail.intro_text,
      is_dark: is_dark,
    );
  }

  /// 头图和阅读工具栏共用登录检查与收藏操作，避免维护两套收藏状态。
  Future<void> _toggle_novel_favorite() async {
    final is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in || !mounted) return;
    final is_favorited = await logic.toggle_favorite();
    if (!mounted || is_favorited == null) return;
    showBottomTip(
      easy.tr(
        is_favorited ? 'favorite.add_success' : 'favorite.remove_success',
      ),
    );
  }

  // ==================== [ChapterJumpHost] ====================

  @override
  set is_restoring_progress(bool value) {
    _is_restoring_progress = value;
    // 恢复标记变化决定骨架屏是否撤下，必须同步重建。
    if (mounted) setState(() {});
  }

  @override
  set has_reading_history(bool value) {
    _has_reading_history_notifier.value = value;
  }

  @override
  void start_progress_save_timer() {
    _start_progress_save_timer();
  }

  @override
  void try_restore_pending_viewport_change() {
    _try_restore_pending_viewport_change();
  }

  @override
  void on_jump_settled() {
    _scroll_progress.handle_scroll();
  }

  @override
  Future<void> open_comment_sheet({int scroll_to_comment_id = 0}) {
    return _open_comment_sheet(scroll_to_comment_id: scroll_to_comment_id);
  }

  // ==================== [ReadingNativeAdHost] ====================

  @override
  bool get can_process_ads_now => _ad_unlock.can_process_ads_now;

  @override
  void maybe_show_unlock_popup(int chapter_index) {
    final config_store = Get.find<ProjectConfigStore>();
    _ad_unlock.maybe_show_unlock_popup(
      chapter_index: chapter_index,
      six_hour: config_store.current.read_ads_unlock_six_hour,
      three_hour: config_store.current.read_ads_unlock_three_hour,
      an_hour: config_store.current.read_ads_unlock_an_hour,
      video_ad_probability: config_store.current.ads_read_video_ad_probability,
    );
  }

  // ==================== [ScrollProgressHost] ====================

  @override
  ReadingChapterAnchor get anchor => _anchor;

  // reading_section_key / last_viewport_dimension / is_reading_section_at_top
  // 均为同名公开字段，自动满足 ScrollProgressHost 的 get/set。

  @override
  double get cached_chapter_progress => _cached_chapter_progress;

  @override
  set cached_chapter_progress(double value) {
    _cached_chapter_progress = value;
  }

  @override
  set has_stable_progress(bool value) {
    _has_stable_progress = value;
  }

  @override
  set has_user_engaged(bool value) {
    _has_user_engaged = value;
  }

  @override
  bool get is_programmatic_scroll => _is_programmatic_scroll;

  @override
  void set_reading_progress(double progress_percent) {
    _set_reading_progress(progress_percent);
  }

  @override
  void set_has_started_reading(bool value) {
    _set_has_started_reading(value);
  }

  @override
  void stop_auto_read() => _auto_read.stop();

  @override
  void try_show_deferred_unlock_popup() {
    _ad_unlock.try_show_deferred_unlock_popup();
  }

  // ==================== [ChapterAnchorHost] ====================

  @override
  bool get is_chapter_transaction_active => _is_chapter_transaction_active;

  @override
  set is_chapter_transaction_active(bool value) {
    _is_chapter_transaction_active = value;
  }

  @override
  set is_programmatic_scroll(bool value) {
    _is_programmatic_scroll = value;
  }

  @override
  void on_scroll_settled() {
    _scroll_progress.handle_scroll();
  }

  // ==================== [AutoReadHost] ====================

  // ==================== [ReadAdUnlockHost] ====================

  @override
  bool get host_mounted => mounted;

  @override
  int get novel_id => widget.story_id;

  @override
  bool get is_restoring_progress => _is_restoring_progress;

  @override
  BuildContext get host_context => context;

  @override
  void refresh_ui() {
    if (mounted) setState(() {});
  }

  @override
  void sync_ad_policy() => _native_ad.sync_ad_policy();

  @override
  Widget build(BuildContext context) {
    if (!logic.has_valid_story_id) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      // 读取字号以触发 Obx 重建（字号变化时需要刷新正文）。
      logic.body_font_size.value;

      final bool is_dark = device_info.theme.value == ThemeMode.dark;
      final Color background_color = is_dark
          ? Style.dark_background_color
          : Style.light_background_color;
      // 免广告状态未就绪或仍在有效期时，所有阅读页广告保持屏蔽。
      final bool suppress_read_ads = !_ad_unlock.can_process_ads_now;

      return ReadingPageShell(
        theme: ReadingPageTheme(
          is_dark: is_dark,
          background_color: background_color,
          status_bar_height: MediaQuery.viewPaddingOf(context).top,
        ),
        state: ReadingPageState(
          logic: logic,
          detail: logic.build_detail(),
          reading_items: logic.build_reading_items(),
          reading_section_key: reading_section_key,
          has_started_reading: _has_started_reading_notifier,
          reading_progress: _reading_progress_notifier,
          has_reading_history: _has_reading_history_notifier,
          ad_free_expire_time: _ad_unlock.expire_time_notifier,
          is_restoring_progress: _is_restoring_progress,
          cached_chapter_progress: _cached_chapter_progress,
          native_ad_config: _native_ad.native_ad_config,
          is_native_ad_config_loading: _native_ad.is_config_loading,
          native_ads_enabled:
              !suppress_read_ads && AdDisplayPolicy.can_show_ads(),
          is_rewarded_ad_loading: _ad_unlock.is_rewarded_ad_loading,
        ),
        actions: ReadingPageActions(
          on_back: () => AppRouter.back(),
          on_refresh: _refresh_novel_content,
          on_read: _scroll_to_reading_section,
          on_open_comments: () => _open_comment_sheet(),
          on_favorite: _toggle_novel_favorite,
          on_share: Get.find<ProjectConfigStore>().current.is_share_enabled
              ? () => _show_novel_share(logic.build_detail(), is_dark)
              : null,
          on_native_ad_impression: () {
            unawaited(_native_ad.record_native_ad_impression());
          },
          on_video_ad_hint_tap: _ad_unlock.on_video_ad_hint_tap,
          on_reading_tap_down: _handle_reading_tap_down,
          on_paragraph_comment: _on_paragraph_comment,
          on_paragraph_comments: _on_paragraph_comments,
          on_paragraph_share: _on_paragraph_share,
          on_paragraph_selection_changed: _on_paragraph_selection_changed,
          on_viewport_resize_start: _on_viewport_resize_start,
          on_viewport_resize_end: _on_viewport_resize_end,
          on_scroll_notification:
              _scroll_progress.handle_main_scroll_notification,
          on_progress_jump: (double target_percent) async {
            final int target_index = logic.find_chapter_index_by_progress(
              target_percent,
            );
            final double chapter_progress = logic
                .calculate_chapter_progress_percent(
                  reading_progress_percent: target_percent,
                  chapter_index: target_index,
                );
            await _jump.execute_chapter_jump(
              target_index,
              chapter_progress_percent: chapter_progress,
            );
          },
          on_prev_chapter: () async {
            await _jump.execute_chapter_jump(
              logic.current_chapter_index.value - 1,
            );
          },
          on_next_chapter: () async {
            await _jump.execute_chapter_jump(
              logic.current_chapter_index.value + 1,
            );
          },
          on_catalog_chapter_tap: (int index) {
            unawaited(_jump.execute_chapter_jump(index));
          },
          on_setting_tap: _showSettingsSheet,
          on_like_tap: () async {
            final bool is_logged_in = await showLoginRequiredDialog(
              title: easy.tr('short_story_read.login_required'),
            );
            if (!is_logged_in) return;
            unawaited(logic.toggle_like());
          },
          on_auto_read_settings_tap: _on_auto_read_settings_tap,
        ),
      );
    });
  }
}
