import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/pages/read/utils/scroll_utils.dart';
import 'package:app/pages/ranking_full_list/widgets/starfield_decoration.dart';
import 'package:app/pages/read/widgets/main_list/index.dart';
import 'package:app/pages/read/widgets/start_reading_pill/index.dart';
import 'package:app/pages/read/widgets/reading_progress_mask/index.dart';
import 'package:app/pages/read/widgets/reading_progress_text/index.dart';
import 'package:app/pages/read/widgets/skeleton/index.dart';
import 'package:app/pages/read/widgets/skeleton/content_skeleton.dart';
import 'package:app/pages/read/widgets/navigation_bars/top/index.dart';
import 'package:app/pages/read/widgets/navigation_bars/bottom/index.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/index.dart';
import 'package:app/pages/read/widgets/reading_settings_sheet/index.dart';
import 'package:app/pages/read/widgets/auto_read_settings_sheet/index.dart';
import 'package:app/pages/read/widgets/auto_read_settings_button/index.dart';
import 'package:app/stores/comment_navigation.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/share_sheet/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

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

  const ReadPage({
    super.key,
    required this.story_id,
    required this.story_title,
    this.initial_comment_id = 0,
  });

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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

  /// 是否正在恢复阅读进度（静默加载目标章节，不展示第一章内容）。
  bool _is_restoring_progress = false;

  /// 缓存的章节内进度百分比（与目录显示一致，由字数算法计算）。
  double _cached_chapter_progress = 0;

  /// FCM 推送评论导航监听器。
  Worker? _comment_navigation_worker;

  /// 详情加载失败监听器。
  Worker? _error_worker;

  /// 页面首次数据与阅读进度初始化任务。
  late final Future<void> _initialization_future;

  /// 阅读进度展示通知器。
  ///
  /// 滚动过程中只刷新进度相关小组件，避免整页正文随每个像素重建。
  final ValueNotifier<double> _reading_progress_notifier =
      ValueNotifier<double>(0);

  /// 是否进入正文区域的展示通知器。
  final ValueNotifier<bool> _has_started_reading_notifier = ValueNotifier<bool>(
    false,
  );

  /// 当前滚动进度百分比，用于展示底部阅读进度文字。
  double reading_progress_percent = 0;

  /// 最近一次记录的视口高度，用于判断是否发生横竖屏切换。
  double last_viewport_dimension = 0;

  /// 布局变化前记录的章节索引。
  int pending_restore_chapter_index = 0;

  /// 布局变化前记录的章节内进度。
  double pending_restore_chapter_progress = 0;

  /// 是否需要在下一帧恢复滚动位置。
  bool needs_restore_scroll_position = false;

  /// 是否已经安排视口尺寸变化后的检查。
  bool _metrics_dimension_check_scheduled = false;

  /// 正文区块是否已经贴近顶部，用于控制翻页点击区域是否生效。
  bool is_reading_section_at_top = false;

  /// 自动阅读 Ticker。
  Ticker? _auto_read_ticker;

  /// 自动阅读上一帧时间戳。
  Duration? _auto_read_last_tick;

  /// 自动阅读是否正在等待下一章完成拼接。
  bool _is_auto_read_waiting_for_chapter = false;

  /// 是否正在执行程序化滚动（点击翻页），此时不触发导航栏显隐。
  bool _is_programmatic_scroll = false;

  /// 当前是否存在滚动活动。
  ///
  /// 上一章/下一章拼接会修改 ListView 内容高度，尤其上一章插入后还需要 jumpTo 修正偏移。
  /// 如果这个动作发生在拖动/惯性滚动过程中，会打断当前滚动手势，表现为"卡一下"。
  /// 因此滚动活动未结束前只做缓存预取，不直接拼接正文列表。
  bool _is_scroll_activity_active = false;

  /// 等待当前滚动活动结束的任务。
  Completer<void>? _scroll_idle_completer;

  /// 页面侧章节事务版本。
  ///
  /// 连续跳章时只有最后一次事务可以执行最终定位和清理状态。
  int _chapter_transaction_generation = 0;

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

  /// 主题背景色透明度，统一控制底部胶囊背景在夜间模式下的层次。
  static const double _night_bottom_pill_background_alpha = 0.92;

  /// 主题背景色透明度，统一控制底部胶囊背景在日间模式下的层次。
  static const double _light_bottom_pill_background_alpha = 0.92;

  @override
  void initState() {
    // 先执行父类初始化，确保生命周期状态可用。
    super.initState();
    // 注册屏幕尺寸变化监听，用于处理横竖屏切换后滚动位置恢复。
    WidgetsBinding.instance.addObserver(this);
    // Logic 与当前阅读路由一一对应，避免不同小说共享章节窗口和滚动控制器。
    // 普通主题重建不会销毁 State，因此无需把页面级控制器常驻到 GetX 容器。
    logic = Logic(story_id: widget.story_id, story_title: widget.story_title);
    // 确保进入页面时导航栏处于关闭状态。
    logic.show_navigation.value = false;
    logic.wait_until_chapter_mutation_allowed = _wait_until_scroll_idle;
    logic.preserve_chapter_anchor = _preserve_chapter_anchor;

    // 路由参数非法时回退首页，避免渲染异常状态页面。
    if (!logic.has_valid_story_id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        routerUtil(path: '/', type: 'replace');
      });
      return;
    }

    // 注册滚动监听，驱动阅读进度、底部胶囊和翻页区域状态更新。
    scroll_controller.addListener(_handle_scroll);

    // 进入页面时请求接口，有阅读进度时静默加载目标章节。
    _initialization_future = _init_with_progress_restore();

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

  /// 初始化页面，有阅读进度时静默加载目标章节。
  ///
  /// 流程：
  /// 1. 先查询阅读记录
  /// 2. 有进度 → 设置 _is_restoring_progress，阻止展示第一章内容
  /// 3. fetch_info 加载章节列表
  /// 4. 立即 jump_to_chapter 到目标章节
  /// 5. 滚动到保存的位置
  /// 6. 清除 _is_restoring_progress
  Future<void> _init_with_progress_restore() async {
    _is_restoring_progress = true;

    final Future<void> info_future = logic.fetch_info();
    final Future<LastReadRecord?> record_future =
        user_information.isLoggedIn.value
        ? get_last_read_record(novel_id: widget.story_id)
        : Future<LastReadRecord?>.value();

    final LastReadRecord? record = await record_future;
    await info_future;
    if (!mounted) return;

    final bool has_progress =
        record != null && (record.chapter_id > 0 || record.read_progress > 0);

    if (has_progress && logic.chapter_list.isNotEmpty) {
      showBottomTip(easy.tr('read.restoring_progress'));
      final int target_index = _resolve_restore_chapter_index(record);
      final double restore_chapter_progress = _resolve_restore_chapter_progress(
        record: record,
        target_chapter_index: target_index,
      );

      await _execute_chapter_jump(
        target_index,
        chapter_progress_percent: restore_chapter_progress,
        mark_user_engaged: false,
      );
    } else {
      _has_stable_progress = logic.chapter_list.isNotEmpty;
      _set_reading_progress(0);
      _set_has_started_reading(false);
    }

    if (!mounted) return;
    setState(() {
      _is_restoring_progress = false;
    });
    _start_progress_save_timer();
  }

  /// 等待阅读页初始化完成后打开路由指定的评论。
  Future<void> _open_initial_comment_after_ready() async {
    await _initialization_future;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _open_comment_sheet(scroll_to_comment_id: widget.initial_comment_id);
  }

  /// 执行一次完整章节跳转事务。
  ///
  /// 章节窗口重建、目标布局与精确定位全部完成后才撤下骨架屏。连续操作时
  /// 通过页面版本和 Logic 版本双重校验，旧任务不会覆盖最后一次选择。
  Future<void> _execute_chapter_jump(
    int target_index, {
    double chapter_progress_percent = 0,
    bool mark_user_engaged = true,
  }) async {
    if (target_index < 0 || target_index >= logic.chapter_list.length) return;

    needs_restore_scroll_position = false;
    final int transaction = ++_chapter_transaction_generation;
    _is_chapter_transaction_active = true;
    logic.is_switching_chapter.value = true;
    int? logic_generation;
    try {
      logic_generation = await logic.jump_to_chapter(target_index);
      if (!mounted ||
          transaction != _chapter_transaction_generation ||
          logic_generation == null) {
        return;
      }

      await _wait_until_reading_layout_ready(target_index);
      if (!mounted || transaction != _chapter_transaction_generation) return;

      await _scroll_to_chapter_progress(
        target_index,
        chapter_progress_percent: chapter_progress_percent,
      );
      if (!mounted || transaction != _chapter_transaction_generation) return;

      _cached_chapter_progress = chapter_progress_percent.clamp(0.0, 100.0);
      logic.update_chapter_progress(_cached_chapter_progress);
      _set_reading_progress(
        logic.calculate_total_progress_percent_for_chapter(
          chapter_index: target_index,
          chapter_progress_percent: _cached_chapter_progress,
        ),
      );
      _set_has_started_reading(
        target_index > 0 ||
            chapter_progress_percent > Style.scroll_offset_epsilon ||
            _is_first_chapter_title_past_start_threshold(),
      );
      _has_stable_progress = true;
      if (mark_user_engaged) {
        _has_user_engaged = true;
      }

      await WidgetsBinding.instance.endOfFrame;
      if (scroll_controller.hasClients) {
        logic.sync_scroll_offset(scroll_controller.offset);
      }
    } finally {
      if (logic_generation != null) {
        logic.complete_chapter_jump(logic_generation);
      }
      if (transaction == _chapter_transaction_generation) {
        _is_chapter_transaction_active = false;
        logic.is_switching_chapter.value = false;
        _try_restore_pending_viewport_change();
        // 若跳章窗口中的上一章曾短暂加载失败，结束事务后立即检查并补齐
        // 顶部缺口，不要求用户先在列表顶端反复触发无位移的过度滚动。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handle_scroll();
          }
        });
      }
    }
  }

  /// 从阅读记录中解析需要恢复到的章节索引。
  ///
  /// 优先使用后端返回的 chapter_id 精确匹配章节数据库 id。
  /// 只有完全没有章节记录时，才使用全书阅读百分比推算。
  int _resolve_restore_chapter_index(LastReadRecord record) {
    if (record.chapter_id > 0) {
      // chapter_id 是后端保存的数据库 id，直接按数据库 id 匹配。
      final int? db_id_index = _find_chapter_index_by_db_id(record.chapter_id);
      if (db_id_index != null) {
        return db_id_index;
      }

      // 数据库 id 匹配失败时，尝试将 chapter_id 视为 chapter_no 兼容旧数据。
      final int? chapter_no_index = _find_chapter_index_by_chapter_no(
        record.chapter_id,
      );
      if (chapter_no_index != null) {
        return chapter_no_index;
      }
    }

    if (record.read_progress <= 0) {
      return 0;
    }

    int target_index = logic.find_chapter_index_by_progress(
      record.read_progress,
    );
    if (record.chapter_offset < 20 && target_index > 0) {
      target_index--;
    }
    return target_index.clamp(0, logic.chapter_list.length - 1);
  }

  /// 按章节数据库 id 查找目录索引。
  int? _find_chapter_index_by_db_id(int chapter_id) {
    for (int i = 0; i < logic.chapter_list.length; i++) {
      final int current_chapter_id =
          int.tryParse(logic.chapter_list[i].id) ?? 0;
      if (current_chapter_id == chapter_id) {
        return i;
      }
    }
    return null;
  }

  /// 按章节序号查找目录索引。
  int? _find_chapter_index_by_chapter_no(int chapter_no) {
    for (int i = 0; i < logic.chapter_list.length; i++) {
      if (logic.chapter_list[i].chapter_no == chapter_no) {
        return i;
      }
    }
    return null;
  }

  /// 从阅读记录中解析章节内恢复百分比。
  ///
  /// chapter_offset 是后端保存的章节内百分比；缺失时才用全书百分比反推。
  double _resolve_restore_chapter_progress({
    required LastReadRecord record,
    required int target_chapter_index,
  }) {
    if (record.chapter_offset > 0) {
      return record.chapter_offset.toDouble().clamp(0.0, 100.0);
    }

    return logic.calculate_chapter_progress_percent(
      reading_progress_percent: record.read_progress,
      chapter_index: target_chapter_index,
    );
  }

  /// 等待目标章节完成布局。
  ///
  /// 跳章会先重建阅读窗口，下一帧 Flutter 才能拿到章节标题的位置。
  /// 这里等到目标标题已有上下文，或者达到最大尝试次数后放行。
  Future<void> _wait_until_reading_layout_ready(
    int target_chapter_index,
  ) async {
    int wait_count = 0;
    while (mounted && wait_count < Style.restore_layout_max_attempts) {
      final bool has_scroll_metrics =
          scroll_controller.hasClients &&
          scroll_controller.position.maxScrollExtent >
              Style.scroll_offset_epsilon;
      final bool has_chapter_context =
          logic.get_chapter_key(target_chapter_index).currentContext != null;
      if (has_scroll_metrics && has_chapter_context) {
        return;
      }

      await WidgetsBinding.instance.endOfFrame;
      wait_count++;
    }
  }

  @override
  void dispose() {
    _progress_save_timer?.cancel();
    // 退出页面时保存一次阅读进度。
    _save_current_progress_on_exit();
    _auto_read_ticker?.dispose();
    _comment_navigation_worker?.dispose();
    _error_worker?.dispose();
    logic.wait_until_chapter_mutation_allowed = null;
    logic.preserve_chapter_anchor = null;
    final Completer<void>? idle_completer = _scroll_idle_completer;
    if (idle_completer != null && !idle_completer.isCompleted) {
      idle_completer.complete();
    }
    _reading_progress_notifier.dispose();
    _has_started_reading_notifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    scroll_controller.removeListener(_handle_scroll);
    logic.onClose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!scroll_controller.hasClients) {
      return;
    }

    pending_restore_chapter_index = logic.current_chapter_index.value;
    pending_restore_chapter_progress = _cached_chapter_progress;
    if (_metrics_dimension_check_scheduled) {
      return;
    }
    _metrics_dimension_check_scheduled = true;
    final double previous_dimension =
        last_viewport_dimension > Style.scroll_offset_epsilon
        ? last_viewport_dimension
        : scroll_controller.position.viewportDimension;

    // didChangeMetrics 触发时 ScrollPosition 可能仍持有旧视口尺寸，必须等布局
    // 完成后再比较；键盘弹出不会改变本页 ListView 高度，因此不会误触发恢复。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metrics_dimension_check_scheduled = false;
      if (!mounted || !scroll_controller.hasClients) {
        return;
      }

      final double current_dimension =
          scroll_controller.position.viewportDimension;
      last_viewport_dimension = current_dimension;
      if ((current_dimension - previous_dimension).abs() <
          Style.scroll_offset_epsilon) {
        return;
      }

      needs_restore_scroll_position = true;
      _try_restore_pending_viewport_change();
    });
  }

  /// 当前没有章节事务时，恢复视口变化前的章节位置。
  void _try_restore_pending_viewport_change() {
    if (!mounted ||
        !needs_restore_scroll_position ||
        _is_chapter_transaction_active) {
      return;
    }
    unawaited(_restore_scroll_position_after_layout());
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
    if (!scroll_controller.hasClients ||
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
      '💾 [长篇保存-退出] progress=${progress.toStringAsFixed(1)}, '
      'chapter_id=$chapter_id, chapter_progress=${chapter_progress.toStringAsFixed(1)}%',
    );

    if (!user_information.isLoggedIn.value) return;

    save_read_progress(
      novel_id: widget.story_id,
      chapter_id: chapter_id > 0 ? chapter_id : null,
      chapter_offset: chapter_progress.round(),
      read_progress: progress,
    );
  }

  /// 保存当前阅读进度到服务器。
  Future<void> _save_current_progress() async {
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

    await save_read_progress(
      novel_id: widget.story_id,
      chapter_id: chapter_id > 0 ? chapter_id : null,
      chapter_offset: chapter_progress.round(),
      read_progress: progress,
    );
  }

  /// 按当前记录的位置或比例恢复滚动位置，避免主题切换或横竖屏切换后阅读位置重置。
  Future<void> _restore_scroll_position_after_layout() async {
    if (!mounted ||
        !needs_restore_scroll_position ||
        _is_chapter_transaction_active) {
      return;
    }

    final int transaction = ++_chapter_transaction_generation;
    _is_chapter_transaction_active = true;
    try {
      await _wait_until_reading_layout_ready(pending_restore_chapter_index);
      if (!mounted ||
          !needs_restore_scroll_position ||
          transaction != _chapter_transaction_generation) {
        return;
      }

      await _scroll_to_chapter_progress(
        pending_restore_chapter_index,
        chapter_progress_percent: pending_restore_chapter_progress,
      );
      if (transaction == _chapter_transaction_generation) {
        needs_restore_scroll_position = false;
      }
    } finally {
      if (transaction == _chapter_transaction_generation) {
        _is_chapter_transaction_active = false;
      }
    }
  }

  /// 获取指定章节标题当前在屏幕上的全局位置。
  ///
  /// [chapter_index] 章节在目录中的索引。
  /// 返回标题顶部距离屏幕顶部的距离；如果标题尚未渲染，则返回 null。
  double? _get_chapter_title_global_top(int chapter_index) {
    final BuildContext? chapter_context = logic
        .get_chapter_key(chapter_index)
        .currentContext;
    if (chapter_context == null) {
      return null;
    }

    final RenderObject? render_object = chapter_context.findRenderObject();
    if (render_object is! RenderBox || !render_object.hasSize) {
      return null;
    }

    return render_object.localToGlobal(Offset.zero).dy;
  }

  /// 计算指定章节标题滚动到“可视区域顶部 + 指定距离”时需要到达的滚动偏移量。
  ///
  /// [chapter_index] 章节在目录中的索引。
  /// [top_offset] 标题距离可视区域顶部的目标距离。
  /// 返回目标滚动偏移量；如果章节标题尚未渲染或列表不可滚动，则返回 null。
  double? _get_chapter_title_target_scroll_offset(
    int chapter_index, {
    required double top_offset,
  }) {
    if (!scroll_controller.hasClients) {
      return null;
    }

    final double? chapter_title_top = _get_chapter_title_global_top(
      chapter_index,
    );
    if (chapter_title_top == null) {
      return null;
    }

    final double screen_top_inset = MediaQuery.viewPaddingOf(context).top;
    final double target_global_top = screen_top_inset + top_offset;
    final double target_offset =
        scroll_controller.offset + chapter_title_top - target_global_top;

    return target_offset.clamp(0.0, scroll_controller.position.maxScrollExtent);
  }

  /// 判断第一章标题是否已经进入可视区域底部 20 像素以内。
  ///
  /// 该条件用于控制“上滑开始阅读”胶囊淡出；当标题继续向上滚动时仍保持淡出。
  bool _is_first_chapter_title_past_start_threshold() {
    final double? first_title_top = _get_chapter_title_global_top(0);
    if (first_title_top == null) {
      return true;
    }

    final double viewport_height = MediaQuery.sizeOf(context).height;
    final double trigger_top =
        viewport_height - Style.first_chapter_title_bottom_trigger_distance;
    return first_title_top <= trigger_top;
  }

  /// 等待章节标题完成布局，并返回其 BuildContext。
  ///
  /// [chapter_index] 章节在目录中的索引。
  /// 若当前帧还没有拿到标题上下文，会最多等待两个布局机会，避免点击胶囊时因为刚刷新而定位失败。
  Future<BuildContext?> _wait_for_chapter_title_context(
    int chapter_index,
  ) async {
    final GlobalKey chapter_key = logic.get_chapter_key(chapter_index);
    BuildContext? chapter_context = chapter_key.currentContext;
    if (chapter_context != null) {
      return chapter_context;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return null;
    }
    chapter_context = chapter_key.currentContext;
    if (chapter_context != null) {
      return chapter_context;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return null;
    }
    return chapter_key.currentContext;
  }

  /// 将指定章节标题平滑滚动到可视区域顶部下方指定距离。
  ///
  /// [chapter_index] 章节在目录中的索引。
  /// [top_offset] 标题距离可视区域顶部的目标距离。
  Future<void> _scroll_to_chapter_title_with_top_offset(
    int chapter_index, {
    required double top_offset,
  }) async {
    if (!scroll_controller.hasClients || !mounted) {
      return;
    }

    final BuildContext? chapter_context = await _wait_for_chapter_title_context(
      chapter_index,
    );
    if (chapter_context == null || !mounted || !scroll_controller.hasClients) {
      return;
    }

    final double? target_offset = _get_chapter_title_target_scroll_offset(
      chapter_index,
      top_offset: top_offset,
    );
    if (target_offset == null) {
      return;
    }

    await scroll_controller.animateTo(
      target_offset,
      duration: Duration(
        milliseconds: Style.scroll_to_reading_section_duration_ms,
      ),
      curve: Curves.easeInOutCubic,
    );
    if (mounted) {
      _handle_scroll();
    }
  }

  /// 滚动到指定章节内的百分比位置。
  ///
  /// [chapter_index] 目标章节索引。
  /// [chapter_progress_percent] 章节内百分比，取值 0 到 100。
  /// 该方法使用当前章节标题和下一章标题的真实渲染位置计算章节高度，
  /// 避免把整个页面 maxScrollExtent 当作单章高度造成恢复位置漂移。
  Future<void> _scroll_to_chapter_progress(
    int chapter_index, {
    required double chapter_progress_percent,
  }) async {
    if (!scroll_controller.hasClients || !mounted) {
      return;
    }

    final BuildContext? chapter_context = await _wait_for_chapter_title_context(
      chapter_index,
    );
    if (chapter_context == null || !mounted || !scroll_controller.hasClients) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !scroll_controller.hasClients) {
      return;
    }

    final double? chapter_start_offset =
        _get_chapter_title_target_scroll_offset(
          chapter_index,
          top_offset: Style.chapter_progress_restore_top_offset,
        );
    if (chapter_start_offset == null) {
      await _scroll_to_chapter_title_with_top_offset(
        chapter_index,
        top_offset: Style.chapter_progress_restore_top_offset,
      );
      return;
    }

    final double max_extent = scroll_controller.position.maxScrollExtent;
    double chapter_end_offset = max_extent;
    final int next_chapter_index = chapter_index + 1;
    if (next_chapter_index <= logic.loaded_chapter_index) {
      final double? next_chapter_start_offset =
          _get_chapter_title_target_scroll_offset(
            next_chapter_index,
            top_offset: Style.chapter_progress_restore_top_offset,
          );
      if (next_chapter_start_offset != null &&
          next_chapter_start_offset > chapter_start_offset) {
        chapter_end_offset = next_chapter_start_offset;
      }
    }

    final double chapter_scroll_extent =
        (chapter_end_offset - chapter_start_offset).clamp(0.0, max_extent);
    final double progress_ratio =
        chapter_progress_percent.clamp(0.0, 100.0) / 100;
    final double target_offset =
        (chapter_start_offset + chapter_scroll_extent * progress_ratio).clamp(
          0.0,
          max_extent,
        );

    scroll_controller.jumpTo(target_offset);
    logic.sync_scroll_offset(target_offset);

    if (chapter_index >= 0 && chapter_index < logic.chapter_list.length) {
      logic.current_chapter_index.value = chapter_index;
      logic.current_chapter_db_id =
          int.tryParse(logic.chapter_list[chapter_index].id) ?? 0;
    }
  }

  /// 基于真实章节标题位置计算当前章节内阅读百分比。
  ///
  /// 优先使用布局位置而不是全书字数反推，可以让定时保存的 chapter_offset
  /// 和恢复时使用的章节内百分比保持同一种坐标系。
  double? _calculate_current_chapter_progress_from_layout(int chapter_index) {
    if (!scroll_controller.hasClients || !mounted) {
      return null;
    }

    final double? chapter_start_offset =
        _get_chapter_title_target_scroll_offset(
          chapter_index,
          top_offset: Style.chapter_progress_restore_top_offset,
        );
    if (chapter_start_offset == null) {
      return null;
    }

    final double max_extent = scroll_controller.position.maxScrollExtent;
    double chapter_end_offset = max_extent;
    final int next_chapter_index = chapter_index + 1;
    if (next_chapter_index <= logic.loaded_chapter_index) {
      final double? next_chapter_start_offset =
          _get_chapter_title_target_scroll_offset(
            next_chapter_index,
            top_offset: Style.chapter_progress_restore_top_offset,
          );
      if (next_chapter_start_offset != null &&
          next_chapter_start_offset > chapter_start_offset) {
        chapter_end_offset = next_chapter_start_offset;
      }
    }

    final double chapter_scroll_extent =
        chapter_end_offset - chapter_start_offset;
    if (chapter_scroll_extent <= Style.scroll_offset_epsilon) {
      return 0;
    }

    final double progress_ratio =
        ((scroll_controller.offset - chapter_start_offset) /
                chapter_scroll_extent)
            .clamp(0.0, 1.0);
    return progress_ratio * 100;
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

    _handle_scroll();
  }

  /// 等待主列表完全停止拖动或惯性滚动。
  Future<void> _wait_until_scroll_idle() {
    if (!_is_scroll_activity_active) {
      return Future<void>.value();
    }

    final Completer<void> completer = _scroll_idle_completer ??=
        Completer<void>();
    return completer.future;
  }

  /// 在插入上一章时保持原列表顶部章节的屏幕坐标不变。
  Future<void> _preserve_chapter_anchor(
    VoidCallback mutation,
    int anchor_chapter_index,
  ) async {
    if (!mounted || !scroll_controller.hasClients) {
      mutation();
      return;
    }

    final double old_offset = scroll_controller.offset;
    final double old_max_extent = scroll_controller.position.maxScrollExtent;
    final double? old_anchor_top = _get_chapter_title_global_top(
      anchor_chapter_index,
    );

    mutation();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !scroll_controller.hasClients) return;

    final double? new_anchor_top = _get_chapter_title_global_top(
      anchor_chapter_index,
    );
    final double fallback_delta =
        scroll_controller.position.maxScrollExtent - old_max_extent;
    final double anchor_delta = old_anchor_top != null && new_anchor_top != null
        ? new_anchor_top - old_anchor_top
        : fallback_delta;
    if (anchor_delta.abs() <= Style.scroll_offset_epsilon) return;

    final ScrollPosition position = scroll_controller.position;
    final double target_offset = (old_offset + anchor_delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _is_programmatic_scroll = true;
    try {
      position.jumpTo(target_offset);
      logic.sync_scroll_offset(target_offset);
    } finally {
      _is_programmatic_scroll = false;
    }
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
    if (_has_started_reading_notifier.value != value) {
      _has_started_reading_notifier.value = value;
    }
  }

  bool _handle_main_scroll_notification(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _is_scroll_activity_active = true;
    }

    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _has_user_engaged = true;
      if (logic.is_auto_reading.value) {
        _stop_auto_read();
      }
    }

    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      _is_scroll_activity_active = false;
      final Completer<void>? idle_completer = _scroll_idle_completer;
      _scroll_idle_completer = null;
      if (idle_completer != null && !idle_completer.isCompleted) {
        idle_completer.complete();
      }

      // 滚动完全结束后再检查是否需要拼接上一章/下一章，避免在手指拖动或惯性滚动中改列表高度。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handle_scroll();
        }
      });
    }

    return false;
  }

  void _handle_scroll() {
    if (!scroll_controller.hasClients || !mounted) {
      return;
    }

    if (needs_restore_scroll_position ||
        _is_chapter_transaction_active ||
        _is_restoring_progress ||
        logic.is_jumping_chapter.value) {
      return;
    }

    final double next_scroll_offset = scroll_controller.offset;

    // 滚动方向检测：自动显示/隐藏导航栏（程序化滚动时不触发）。
    if (!_is_programmatic_scroll && !logic.is_auto_reading.value) {
      logic.on_scroll(next_scroll_offset);
    }

    final double viewport_dimension =
        scroll_controller.position.viewportDimension;
    final double max_scroll_extent = scroll_controller.position.maxScrollExtent;

    // 计算 reading_section_offset，即正文区块距离顶部的绝对偏移量
    double reading_section_offset = 0;
    final BuildContext? reading_context = reading_section_key.currentContext;
    if (reading_context != null) {
      final RenderObject? render_object = reading_context.findRenderObject();
      if (render_object is RenderBox && render_object.hasSize) {
        final double reading_section_top = render_object
            .localToGlobal(Offset.zero)
            .dy;
        final double screen_top_inset = MediaQuery.viewPaddingOf(context).top;
        reading_section_offset =
            next_scroll_offset + reading_section_top - screen_top_inset;
      }
    }

    // 先识别当前章节，再计算章节内进度，避免章节边界处使用上一章索引计算新位置。
    final double chapter_detection_line =
        MediaQuery.viewPaddingOf(context).top +
        Style.current_chapter_detection_top_offset;
    for (
      int i = logic.loaded_chapter_index;
      i >= logic.min_loaded_chapter_index;
      i--
    ) {
      final BuildContext? chapter_context = logic
          .get_chapter_key(i)
          .currentContext;
      final RenderObject? render_object = chapter_context?.findRenderObject();
      if (render_object is! RenderBox || !render_object.hasSize) continue;

      final double top = render_object.localToGlobal(Offset.zero).dy;
      if (top <= chapter_detection_line) {
        logic.current_chapter_index.value = i;
        if (i >= 0 && i < logic.chapter_list.length) {
          logic.current_chapter_db_id =
              int.tryParse(logic.chapter_list[i].id) ?? 0;
        }
        break;
      }
    }

    final bool is_near_top =
        next_scroll_offset < Style.reading_start_near_top_threshold;
    final bool is_on_first_chapter = logic.current_chapter_index.value == 0;
    final bool next_has_started_reading = (is_near_top && is_on_first_chapter)
        ? false
        : _is_first_chapter_title_past_start_threshold();

    final double? layout_progress =
        _calculate_current_chapter_progress_from_layout(
          logic.current_chapter_index.value,
        );
    if (layout_progress != null) {
      _cached_chapter_progress = layout_progress;
      logic.update_chapter_progress(_cached_chapter_progress);
      _has_stable_progress = true;
    }

    // 使用基于章节的逻辑计算全书进度。
    final double next_reading_progress_percent = logic
        .calculate_reading_progress(
          next_scroll_offset,
          max_scroll_extent,
          reading_section_offset: reading_section_offset,
        );
    final bool next_is_reading_section_at_top =
        ScrollUtils.is_reading_section_at_top(
          reading_section_key: reading_section_key,
          context: context,
        );

    // 提前预取/准备上一章。
    //
    // 关键点：这里不再要求 !_is_scroll_activity_active。
    // load_prev_chapter 内部会先请求正文并写入缓存；如果当前仍在拖动/惯性滚动，
    // 它会等待 idle 后再 prepend 到 reading_items 并修正 offset。
    // 这样既能提前 2 屏以上拿到内容，又不会在滚动过程中改列表高度导致卡顿。
    final double prev_prefetch_distance =
        (viewport_dimension * Style.chapter_prefetch_viewport_multiplier).clamp(
          Style.load_prev_chapter_threshold,
          double.infinity,
        );
    final bool can_prepare_prev =
        !logic.is_switching_chapter.value &&
        next_is_reading_section_at_top &&
        next_scroll_offset < reading_section_offset + prev_prefetch_distance &&
        logic.min_loaded_chapter_index > 0 &&
        !logic.is_loading_prev;

    if (can_prepare_prev) {
      unawaited(logic.load_prev_chapter());
    }

    // 提前预取/准备下一章。
    //
    // 同样允许在滚动活动期间触发：网络/磁盘读取会提前发生，
    // 但真正 append 到正文列表会由 Logic 等到滚动 idle 后执行。
    final double next_prefetch_distance =
        (viewport_dimension * Style.chapter_prefetch_viewport_multiplier).clamp(
          Style.load_next_chapter_threshold,
          double.infinity,
        );
    if (max_scroll_extent - next_scroll_offset < next_prefetch_distance &&
        !logic.is_loading_next) {
      unawaited(logic.load_next_chapter());
    }

    if (next_has_started_reading && !_is_scroll_activity_active) {
      unawaited(
        logic.ensure_next_chapter_appended_after(
          logic.current_chapter_index.value,
        ),
      );
    }

    _set_has_started_reading(next_has_started_reading);
    _set_reading_progress(next_reading_progress_percent);
    last_viewport_dimension = viewport_dimension;
    is_reading_section_at_top = next_is_reading_section_at_top;
  }

  /// 处理正文三段式点击。
  ///
  /// 页面在点击发生时读取最新滚动和导航状态，正文段落无需随滚动重建。
  void _handle_reading_tap_down(TapDownDetails details) {
    if (!is_reading_section_at_top || _is_chapter_transaction_active) return;

    if (logic.is_auto_reading.value) {
      _stop_auto_read();
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

  /// 程序化上翻一屏。
  Future<void> _scroll_page_up() async {
    if (_is_programmatic_scroll) return;
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
    await _scroll_to_chapter_title_with_top_offset(
      0,
      top_offset: Style.chapter_title_top_target_offset,
    );
  }

  /// 显示阅读设置弹窗。
  void _showSettingsSheet() {
    logic.show_navigation.value = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
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
            _start_auto_read();
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
      await _wait_until_reading_layout_ready(chapter_index);
      if (!mounted) return;
      await _scroll_to_chapter_progress(
        chapter_index,
        chapter_progress_percent: chapter_progress,
      );
    } finally {
      _is_chapter_transaction_active = false;
    }
  }

  /// 开始自动阅读。
  void _start_auto_read() {
    if (logic.is_auto_reading.value) return;

    logic.is_auto_reading.value = true;
    logic.show_navigation.value = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _begin_auto_read_ticker();
    });
  }

  /// 停止自动阅读。
  void _stop_auto_read() {
    _is_auto_read_waiting_for_chapter = false;
    if (logic.is_auto_reading.value) {
      logic.is_auto_reading.value = false;
      _auto_read_ticker?.stop();
      _auto_read_ticker?.dispose();
      _auto_read_ticker = null;
    }
  }

  /// 启动自动阅读 Ticker（每帧根据当前速度滚动）。
  void _begin_auto_read_ticker() {
    if (!mounted || !logic.is_auto_reading.value) return;

    _auto_read_last_tick = null;

    _auto_read_ticker?.dispose();
    _auto_read_ticker = createTicker((Duration elapsed) {
      if (!scroll_controller.hasClients || !logic.is_auto_reading.value) {
        _auto_read_ticker?.stop();
        return;
      }

      final double delta_seconds;
      if (_auto_read_last_tick == null) {
        delta_seconds = 0;
      } else {
        delta_seconds =
            (elapsed - _auto_read_last_tick!).inMicroseconds / 1000000.0;
      }
      _auto_read_last_tick = elapsed;

      // 速度映射：0.0 → 20px/s，1.0 → 300px/s。
      final double speed = logic.auto_read_speed.value;
      final double pixels_per_second = 20 + speed * 280;

      final double current = scroll_controller.offset;
      final double max_extent = scroll_controller.position.maxScrollExtent;
      final double next = current + pixels_per_second * delta_seconds;

      if (next >= max_extent) {
        scroll_controller.jumpTo(max_extent);
        _auto_read_ticker?.stop();
        if (logic.loaded_chapter_index < logic.chapter_list.length - 1) {
          unawaited(_resume_auto_read_after_next_chapter());
        } else {
          logic.is_auto_reading.value = false;
        }
      } else {
        scroll_controller.jumpTo(next);
      }
    });

    _auto_read_ticker?.start();
  }

  /// 自动阅读到达当前窗口底部后等待下一章，并在布局完成后继续。
  Future<void> _resume_auto_read_after_next_chapter() async {
    if (_is_auto_read_waiting_for_chapter || !logic.is_auto_reading.value) {
      return;
    }

    _is_auto_read_waiting_for_chapter = true;
    try {
      await logic.load_next_chapter();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !logic.is_auto_reading.value) return;
      if (scroll_controller.hasClients &&
          scroll_controller.offset <
              scroll_controller.position.maxScrollExtent) {
        _begin_auto_read_ticker();
      } else {
        logic.is_auto_reading.value = false;
      }
    } finally {
      _is_auto_read_waiting_for_chapter = false;
    }
  }

  /// 显示自动阅读设置弹窗。
  void _on_auto_read_settings_tap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheet_context) {
        return AutoReadSettingsSheet(
          auto_read_speed: logic.auto_read_speed,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_exit: () {
            Navigator.of(sheet_context).pop();
            _stop_auto_read();
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

  @override
  Widget build(BuildContext context) {
    if (!logic.has_valid_story_id) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      // 读取字号以触发 Obx 重建（字号变化时需要刷新正文）。
      logic.body_font_size.value;

      // 当前主题是否为夜间模式，后续所有配色都基于该布尔值计算。
      final bool is_dark = device_info.theme.value == ThemeMode.dark;
      // 页面背景色根据主题切换，保证正文与顶部信息在双主题下可读。
      final Color background_color = is_dark
          ? Style.dark_background_color
          : Style.light_background_color;
      // 底部胶囊背景色按主题设置半透明值，确保覆盖文本时不过分抢眼。
      final Color bottom_pill_background_color = is_dark
          ? Style.dark_navigation_bar_color.withValues(
              alpha: _night_bottom_pill_background_alpha,
            )
          : Style.light_navigation_bar_color.withValues(
              alpha: _light_bottom_pill_background_alpha,
            );
      // 状态栏高度用于计算顶部列表安全区。
      final double status_bar_height = MediaQuery.viewPaddingOf(context).top;
      // 组装页面展示详情数据。
      final ReadDetail detail = logic.build_detail();
      // 组装正文内容项。
      final List<ReadingContentItem> reading_items = logic
          .build_reading_items();
      // 首次接口尚未返回时只展示骨架屏；阅读记录恢复阶段让正文在骨架层下
      // 正常参与布局，完成精确定位后再撤下覆盖层。
      if (logic.is_loading.value) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: background_color,
          body: ReadSkeleton(is_dark: is_dark),
        );
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: background_color,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: <Widget>[
              StarfieldDecoration(is_dark: is_dark),
              // 主内容滚动组件。
              NotificationListener<ScrollNotification>(
                onNotification: _handle_main_scroll_notification,
                child: RefreshIndicator(
                  color: ColorConstants.themeColor,
                  displacement: Style.refresh_indicator_displacement,
                  notificationPredicate: (ScrollNotification notification) {
                    return notification.depth == 0 &&
                        logic.should_show_introduction &&
                        !has_started_reading &&
                        !logic.show_navigation.value;
                  },
                  onRefresh: _refresh_novel_content,
                  child: ReadMainList(
                    logic: logic,
                    scroll_controller: scroll_controller,
                    status_bar_height: status_bar_height,
                    is_dark: is_dark,
                    detail: detail,
                    reading_items: reading_items,
                    reading_section_key: reading_section_key,
                    on_reading_tap_down: _handle_reading_tap_down,
                  ),
                ),
              ),
              // 顶部渐变遮罩：提供顶部状态栏区域的视觉过渡。
              PageTopGradientOverlay(background_color: background_color),
              // 滚动过程中仅重建这些轻量阅读辅助层，不触发正文树重建。
              ValueListenableBuilder<bool>(
                valueListenable: _has_started_reading_notifier,
                builder:
                    (BuildContext context, bool has_started, Widget? child) {
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
                valueListenable: _has_started_reading_notifier,
                builder:
                    (BuildContext context, bool has_started, Widget? child) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _reading_progress_notifier,
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
              ValueListenableBuilder<bool>(
                valueListenable: _has_started_reading_notifier,
                builder:
                    (BuildContext context, bool has_started, Widget? child) {
                      return ReadStartReadingPill(
                        is_dark: is_dark,
                        show_start_reading_pill: !has_started,
                        bottom_pill_background_color:
                            bottom_pill_background_color,
                        bottom_safe_area: MediaQuery.viewPaddingOf(
                          context,
                        ).bottom,
                        on_tap: _scroll_to_reading_section,
                      );
                    },
              ),
              // 顶部导航栏
              ReadTopBar(
                is_dark: is_dark,
                show: logic.show_navigation.value,
                on_back: () => AppRouter.back(),
                on_favorite_tap: () async {
                  final bool is_logged_in = await showLoginRequiredDialog(
                    title: easy.tr('short_story_read.login_required'),
                  );
                  if (!is_logged_in) return;
                  final bool was_favorited = logic.is_favorited.value;
                  logic.toggle_favorite();
                  showBottomTip(
                    easy.tr(
                      was_favorited
                          ? 'favorite.remove_success'
                          : 'favorite.add_success',
                    ),
                  );
                },
                on_share: () {
                  showShareSheet(
                    context: context,
                    novel_id: widget.story_id,
                    novel_title: detail.title,
                    novel_author: detail.author_name,
                    novel_cover_url: detail.cover_url,
                    novel_intro: detail.intro_text,
                    is_dark: is_dark,
                  );
                },
                is_favorited: logic.is_favorited.value,
                is_favorite_loading: logic.is_favorite_loading.value,
              ),
              // 底部导航栏的进度由独立通知器驱动，正文不参与重建。
              ValueListenableBuilder<double>(
                valueListenable: _reading_progress_notifier,
                builder:
                    (
                      BuildContext context,
                      double progress_percent,
                      Widget? child,
                    ) {
                      return ReadBottomBar(
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
                          final double target_percent = value * 100;
                          final int target_index = logic
                              .find_chapter_index_by_progress(target_percent);
                          final double chapter_progress = logic
                              .calculate_chapter_progress_percent(
                                reading_progress_percent: target_percent,
                                chapter_index: target_index,
                              );
                          await _execute_chapter_jump(
                            target_index,
                            chapter_progress_percent: chapter_progress,
                          );
                        },
                        on_prev_chapter: () async {
                          await _execute_chapter_jump(
                            logic.current_chapter_index.value - 1,
                          );
                        },
                        on_next_chapter: () async {
                          await _execute_chapter_jump(
                            logic.current_chapter_index.value + 1,
                          );
                        },
                        is_first_chapter: logic.is_first_chapter,
                        is_last_chapter: logic.is_last_chapter,
                        on_catalog_tap: () {
                          logic.show_navigation.value = false;
                          ReadDirectorySheet.show(
                            context: context,
                            logic: logic,
                            is_dark: is_dark,
                            current_chapter_progress_percent:
                                _cached_chapter_progress,
                            on_chapter_tap: (int index) {
                              unawaited(_execute_chapter_jump(index));
                            },
                          );
                        },
                        on_setting_tap: _showSettingsSheet,
                        comment_count: logic.comment_count,
                        on_comment_tap: () => _open_comment_sheet(),
                        is_liked: logic.is_liked.value,
                        like_count: logic.like_count.value,
                        is_like_loading: logic.is_like_loading.value,
                        on_like_tap: () async {
                          final bool is_logged_in =
                              await showLoginRequiredDialog(
                                title: easy.tr(
                                  'short_story_read.login_required',
                                ),
                              );
                          if (!is_logged_in) return;
                          unawaited(logic.toggle_like());
                        },
                      );
                    },
              ),
              // 自动阅读设置浮动按钮（自动阅读时显示在底部居中）。
              if (logic.is_auto_reading.value)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
                  child: Center(
                    child: AutoReadSettingsButton(
                      is_dark: is_dark,
                      on_tap: _on_auto_read_settings_tap,
                    ),
                  ),
                ),
              // 初始进度恢复或目录跳转时，用骨架覆盖已经参与布局的正文及
              // 所有交互层；目标位置稳定后一次性显现，避免进度和导航穿透。
              if (_is_restoring_progress || logic.is_jumping_chapter.value)
                Positioned.fill(
                  child: Container(
                    color: background_color,
                    child: ReadContentSkeleton(is_dark: is_dark),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
