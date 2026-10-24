// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/components/window_content_layout/index.dart';
import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import 'package:app/api/bookshelf.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/paragraph_selection/actions.dart';
import 'package:app/models/story_paragraph.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/stores/comment_navigation.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/pages/short_story_read/story_pull_gesture.dart';
import 'package:app/pages/short_story_read/story_native_ad_gate.dart';
import 'package:app/pages/short_story_read/story_progress_keeper.dart';
import 'package:app/pages/short_story_read/story_auto_read.dart';
import 'package:app/pages/short_story_read/story_toolbar_actions.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/widgets/full_appbar.dart';
import 'package:app/pages/short_story_read/widgets/bottom_comment_bar.dart';
import 'package:app/pages/short_story_read/widgets/initialization_overlay.dart';
import 'package:app/pages/short_story_read/utils/reading_start_scroll_offset.dart';
import 'package:app/pages/ranking_full_list/widgets/starfield_decoration.dart';
import 'package:app/pages/short_story_read/widgets/skeleton_screen.dart';
import 'package:app/components/no_internet/index.dart';
import 'package:app/components/share_sheet/widgets/text_selection_preview_sheet.dart';
import 'package:app/components/inline_native_ad/index.dart';
import 'package:app/components/inline_native_ad/scroll_offset_compensation.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/pages/short_story_read/widgets/story_content_stack.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/services/ad_impression_reporter.dart';

/// 短篇小说阅读页面。
///
/// 展示单篇短篇小说的标题、标签和正文内容，
/// 支持日间/夜间主题切换和多语种适配。
///
/// 交互规则：
/// - 向下滚动正文时，自动隐藏顶部导航栏和底部评论栏，提供沉浸式阅读体验。
/// - 向上滚动时，自动显示顶部导航栏和底部评论栏。
/// - 点击正文区域时，切换顶部导航栏和底部评论栏的显示/隐藏。
///
/// 页面结构（从底到顶）：
/// 1. 背景装饰（[PageBackgroundDecor]）
/// 2. 正文内容（可滚动的阅读区域）
/// 3. 完整导航栏（[FullAppbar]，带滑入/滑出动画）
/// 4. 底部评论栏（[BottomCommentBar]，带滑入/滑出动画）
///
/// 路由参数：
/// - [story_id] - 小说 ID（必填，缺失时跳转首页）
class ShortStoryReadPage extends StatefulWidget {
  /// 小说 ID。
  final int story_id;

  /// 从消息页跳转时传入的评论ID（用于自动打开评论区并定位）。
  final int initial_comment_id;

  const ShortStoryReadPage({
    super.key,
    required this.story_id,
    this.initial_comment_id = 0,
  });

  @override
  State<ShortStoryReadPage> createState() => _ShortStoryReadPageState();
}

class _ShortStoryReadPageState extends State<ShortStoryReadPage>
    with TickerProviderStateMixin, WidgetsBindingObserver     implements
    StoryPullGestureHost,
    StoryNativeAdHost,
    StoryProgressHost,
    StoryToolbarHost,
    StoryAutoReadHost {
  /// 设备信息仓库（用于获取当前主题模式）。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 用户信息仓库，用于检查登录状态。
  final UserInformation user_information = Get.find<UserInformation>();

  /// 页面逻辑层（管理数据加载、交互状态）。
  late ShortStoryReadLogic _logic;

  /// 正文滚动控制器。
  late ScrollController _scroll_controller;

  /// 底部评论栏动画控制器（控制滑入/滑出）。
  late AnimationController _bottom_bar_animation_controller;

  /// 底部评论栏滑动动画（从屏幕底部滑出/滑入）。
  late Animation<Offset> _bottom_bar_slide_animation;

  /// 浮动按钮淡入淡出动画（与底部栏同步）。
  late Animation<double> _floating_button_fade_animation;

  /// 翻页动画控制器（控制当前内容上滑和骨架屏入场）。
  late AnimationController _page_transition_controller;

  /// 当前是否正在执行翻页动画。
  bool _is_transitioning = false;

  /// 选文时不让阅读页边缘拖拽接管文字手柄。
  bool _is_paragraph_selection_active = false;

  /// 原生选区会在按下正文外空白时清除，保留按下前状态供单击确认使用。
  bool _tap_started_with_selection = false;

  /// 防止连续点击段评按钮叠加多个登录或输入弹窗。
  final ParagraphActions _paragraph_actions = ParagraphActions();

  bool get _is_paragraph_composer_open => _paragraph_actions.is_open;

  /// 翻页方向（true = 向上滑动（下一篇），false = 向下滑动（上一篇））。
  bool _is_slide_up = true;

  /// 上下拉切篇手势控制器（状态机与阻尼动画独立在 [StoryPullGestureController]）。
  late final StoryPullGestureController _pull;

  /// 原生广告与激励门控决策器。
  late final StoryNativeAdGate _ad_gate;

  /// 阅读进度保存与恢复器。
  late final StoryProgressKeeper _progress;

  /// 工具栏与目录/设置/解锁动作处理器。
  late final StoryToolbarActions _actions;

  /// 自动阅读引擎。
  late final StoryAutoReadController _auto_read;

  /// 下一篇标题的定位 key，用来判断标题是否已经进入可视区域。
  final GlobalKey _next_story_title_key = GlobalKey();

  /// 底部渐变遮罩透明度。
  ///
  /// 下一篇标题进入屏幕底部可视区域 10px 时开始淡入，离开时淡出。
  double _next_story_overlay_opacity = 0;

  /// 是否由进度条拖动触发的滚动（为 true 时跳过导航栏显隐逻辑）。
  bool _is_progress_scrolling = false;



  /// FCM 推送评论导航监听器。
  Worker? _comment_navigation_worker;

  /// 底部栏可见性监听器。
  Worker? _bottom_bar_visibility_worker;

  /// 项目广告开关变更监听器。
  Worker? _ad_policy_worker;





  /// 阅读进度定时保存定时器。
  Timer? _progress_save_timer;

  /// 阅读进度保存间隔（秒）。
  static const int _progress_save_interval_seconds = 10;

  /// 用户是否有过真实阅读行为（滚动过内容）。
  /// 预加载切换小说时不会触发滚动，因此可用来区分"用户主动阅读"和"预加载"。
  bool _has_user_engaged = false;

  /// 当前小说是否已经完成初始化和进度恢复。
  bool _is_initialization_complete = false;

  /// 当前是否正在恢复服务器阅读位置。
  bool _is_restoring_position = false;








  /// 当前逻辑实例的版本号，用于丢弃切换小说前发起的异步结果。
  int _logic_generation = 0;

  /// 当前初始化尝试编号，用于丢弃同一小说重复重试产生的旧结果。
  int _initialization_attempt = 0;

  /// 当前篇正文末尾定位点。
  ///
  /// 阅读进度只计算当前篇，不把异步加载的下一篇预览算入总长度。
  final GlobalKey _current_story_end_key = GlobalKey();

  /// 独立定位正文起点，不通过封面、标题或简介的估算高度进入阅读。
  final GlobalKey _body_start_key = GlobalKey();

  /// 续读快照只在正文区域更新，回看简介不会清空此前的阅读位置。
  LastReadRecord? _resume_record;
  final ValueNotifier<bool> _has_reading_history = ValueNotifier(false);

  /// 当前篇可用于阅读进度计算的最大滚动距离。
  double? _reading_progress_max_extent;

  /// 正文字号连续变化时只执行最后一次重新排版定位。
  int _font_relayout_generation = 0;

  /// 折叠/展开前当前篇内的位置；布局尚未稳定时不把旧像素偏移写成新进度。
  double? _viewport_resize_progress;
  int _viewport_resize_logic_generation = 0;

  // ==================== 生命周期 ====================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final bool has_valid_story_id = widget.story_id > 0;

    // 没有有效 id 时直接跳转首页。
    if (!has_valid_story_id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        routerUtil(path: '/home', type: 'go');
      });
    }

    // 初始化滚动控制器并监听滚动事件。
    _scroll_controller = ScrollController();
    _scroll_controller.addListener(_on_scroll);

    // 初始化底部评论栏动画（滑入/滑出效果）。
    _bottom_bar_animation_controller = AnimationController(
      vsync: this,
      duration: ShortStoryReadStyle.bar_animation_duration,
    );
    _bottom_bar_slide_animation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1)).animate(
          CurvedAnimation(
            parent: _bottom_bar_animation_controller,
            curve: ShortStoryReadStyle.bar_animation_curve,
          ),
        );

    // 初始化浮动按钮淡入淡出动画（与底部栏动画同步）。
    _floating_button_fade_animation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(
          CurvedAnimation(
            parent: _bottom_bar_animation_controller,
            curve: ShortStoryReadStyle.bar_animation_curve,
          ),
        );

    // 初始化翻页动画控制器。
    _page_transition_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // 上下拉切篇手势控制器（自带回弹动画控制器）。
    _pull = StoryPullGestureController(ticker: this, host: this);
    _ad_gate = StoryNativeAdGate(host: this);
    _progress = StoryProgressKeeper(host: this);
    _actions = StoryToolbarActions(host: this);
    _auto_read = StoryAutoReadController(ticker_provider: this, host: this);

    // 初始化逻辑层并开始加载数据。
    // 延迟到首帧之后执行，确保 context.locale 已就绪（iOS 上 initState 阶段可能未就绪）。
    _logic = ShortStoryReadLogic(
      context: context,
      story_id: has_valid_story_id ? widget.story_id : 1,
    );
    _logic_generation = 1;
    _ad_policy_worker = ever(
      Get.find<ProjectConfigStore>().config_revision,
      (_) => _on_ad_policy_changed(),
    );
    _bind_bottom_bar_visibility();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !has_valid_story_id) return;
      unawaited(
        _initialize_logic(
          logic: _logic,
          generation: _logic_generation,
          restore_position: true,
        ),
      );
    });

    // TODO 从消息页跳转时，自动打开评论区并定位到指定评论
    if (widget.initial_comment_id > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _actions.on_comment_tap(scroll_to_comment_id: widget.initial_comment_id);
      });
    }

    // TODO 监听 FCM 推送点击事件（用户已在当前页面时收到推送）
    _comment_navigation_worker = ever(CommentNavigation.pending_comment_id, (
      int comment_id,
    ) {
      if (!mounted || comment_id <= 0) return;
      if (CommentNavigation.pending_novel_id.value != _logic.story_id) return;
      CommentNavigation.consume();
      _actions.on_comment_tap(scroll_to_comment_id: comment_id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress_save_timer?.cancel();
    // 退出页面时保存一次阅读进度。
    _progress.save_on_exit(logic: _logic, is_initialization_complete: _is_initialization_complete, has_user_engaged: _has_user_engaged);
    _logic.dispose(clear_catalog: true);
    _auto_read.dispose();
    _comment_navigation_worker?.dispose();
    _bottom_bar_visibility_worker?.dispose();
    _ad_policy_worker?.dispose();
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    _has_reading_history.dispose();
    _bottom_bar_animation_controller.dispose();
    _page_transition_controller.dispose();
    _pull.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_auto_read.paused_by_lifecycle && _logic.is_auto_reading.value) {
        _auto_read.paused_by_lifecycle = false;
        _auto_read.begin_ticker();
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_progress.save_current(logic: _logic, is_initialization_complete: _is_initialization_complete, has_user_engaged: _has_user_engaged));
    }
    if ((state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused) &&
        _logic.is_auto_reading.value) {
      _auto_read.paused_by_lifecycle = true;
      _auto_read.pause_ticker();
    }
  }

  /// 启动阅读进度定时保存定时器。
  void _start_progress_save_timer() {
    _progress_save_timer?.cancel();
    _progress_save_timer = Timer.periodic(
      const Duration(seconds: _progress_save_interval_seconds),
      (_) => _progress.save_current(logic: _logic, is_initialization_complete: _is_initialization_complete, has_user_engaged: _has_user_engaged),
    );
  }

  /// 当前逻辑实例和版本是否仍然有效。
  bool _is_current_logic(ShortStoryReadLogic logic, int generation) {
    return mounted &&
        identical(_logic, logic) &&
        _logic_generation == generation;
  }

  /// 当前可见正文对应的完整阅读进度上限。
  ///
  /// 未解锁时只显示配置比例的正文，滚动到折叠处不能记为全文完成。
  double get _visible_story_progress_limit {
    return (_logic.is_story_unlocked.value || !_ad_gate.is_video_ad_gate_required)
        ? 1.0
        : ShortStoryReadStyle.locked_content_preview_ratio;
  }

  bool _is_current_initialization(
    ShortStoryReadLogic logic,
    int generation,
    int attempt,
  ) {
    return _is_current_logic(logic, generation) &&
        _initialization_attempt == attempt;
  }

  /// 初始化指定小说，并在需要时恢复服务器阅读位置。
  Future<void> _initialize_logic({
    required ShortStoryReadLogic logic,
    required int generation,
    required bool restore_position,
  }) async {
    final int attempt = ++_initialization_attempt;
    _is_initialization_complete = false;
    final Future<LastReadRecord?> record_future = restore_position
        ? get_last_read_record(novel_id: logic.story_id)
        : Future<LastReadRecord?>.value(null);

    final bool loaded = await logic.initialize();
    LastReadRecord? record;
    try {
      record = await record_future;
    } catch (_) {
      record = null;
    }

    if (!_is_current_initialization(logic, generation, attempt) || !loaded) {
      return;
    }

    // 概率只在每篇小说初始化后判断一次，避免重建或配置通知造成重复掷骰。
    _ad_gate.resolve_probability_decisions(generation: generation);
    if (_ad_gate.should_show_native_ad) {
      // 后台请求并预加载广告，未完成前不占用正文空间。
      unawaited(_ad_gate.load_native_ad_config(generation: generation));
    }

    if (restore_position && record != null) {
      if (record.chapter_offset > 0 || record.read_progress > 0) {
        _resume_record = record;
        _has_reading_history.value = true;
      }
      await _progress.restore_last_position(
        logic: logic,
        generation: generation,
        attempt: attempt,
        record: record,
      );
    } else {
      await _progress.wait_for_story_layout(
        logic: logic,
        generation: generation,
        attempt: attempt,
      );
    }

    if (!_is_current_initialization(logic, generation, attempt)) return;
    setState(() {
      _is_initialization_complete = true;
    });
    _start_progress_save_timer();
  }

  /// 重试当前小说的详情和正文加载。
  void _retry_current_story() {
    _progress_save_timer?.cancel();
    unawaited(
      _initialize_logic(
        logic: _logic,
        generation: _logic_generation,
        restore_position: true,
      ),
    );
  }

  // ==================== 广告管理 ====================

  /// 将远端广告平台开关同步到当前短篇的正文与广告位。
  void _on_ad_policy_changed() {
    _ad_gate.on_policy_changed(sync_ad_access_policy: _logic.sync_ad_access_policy);
  }

  /// 计算正文末尾对齐可视区域底部时的真实滚动偏移。
  double _calculate_current_story_extent() {
    return _progress.calculate_story_extent();
  }

  /// 执行滚动位置恢复。
  void _do_restore_position(LastReadRecord record) {
    _progress.do_restore_position(logic: _logic, record: record);
  }

  /// 仅在正文已到达阅读位置时保存用于主按钮的本地快照。
  /// 服务器百分比仍沿用现有算法，简介展开和设备重排不改写其含义。
  void _remember_body_reading_position() {
    _progress.remember_body_reading_position(
      logic: _logic,
      is_initialization_complete: _is_initialization_complete,
      has_user_engaged: _has_user_engaged,
    );
  }

  /// 首次点击进入真实正文锚点；续读复用既有百分比/像素恢复算法。
  Future<void> _on_read_story() async {
    if (!_is_initialization_complete || !_scroll_controller.hasClients) return;
    final logic = _logic;
    final generation = _logic_generation;
    final start_offset = reading_start_scroll_offset(
      scroll_controller: _scroll_controller,
      body_start_key: _body_start_key,
    );
    if (start_offset == null) return;
    _has_user_engaged = true;
    final record = _resume_record;
    if (_has_reading_history.value && record != null) {
      _do_restore_position(record);
      // 旧记录可能落在简介内；按钮至少展示正文，不停留在封面或分类区域。
      if (_scroll_controller.offset < start_offset) {
        if (MediaQuery.disableAnimationsOf(context)) {
          _scroll_controller.jumpTo(start_offset);
        } else {
          await _scroll_controller.animateTo(
            start_offset,
            duration: ShortStoryReadStyle.read_entry_duration,
            curve: Curves.easeInOutCubic,
          );
        }
      }
    } else {
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll_controller.jumpTo(start_offset);
      } else {
        await _scroll_controller.animateTo(
          start_offset,
          duration: ShortStoryReadStyle.read_entry_duration,
          curve: Curves.easeInOutCubic,
        );
      }
    }
    if (!_is_current_logic(logic, generation)) return;
    _logic.sync_scroll_offset(_scroll_controller.offset);
    _remember_body_reading_position();
  }

  // ==================== 滚动相关 ====================

  /// 返回阅读区的自然滚动物理效果。
  ScrollPhysics get _reader_scroll_physics {
    if (_pull.previous_pull_offset > 0 || _pull.next_pull_offset > 0) {
      return const NeverScrollableScrollPhysics();
    }

    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// 广告位真正改变正文布局后，使用下一帧的当前篇末尾重算进度。
  ///
  /// SDK 素材测量早于广告位提交，不能在测量时缓存仍未包含广告的范围。
  /// [generation] 防止切篇后旧布局回调影响新正文。
  void _on_native_ad_extent_changed(int generation) {
    if (!mounted || generation != _logic_generation) return;
    _reading_progress_max_extent = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _logic_generation ||
          !_scroll_controller.hasClients ||
          !_scroll_controller.position.hasContentDimensions) {
        return;
      }
      _on_current_story_extent_changed(
        _calculate_current_story_extent(),
        generation,
      );
    });
  }

  /// 更新新布局对应的正文范围，尺寸变化不会触发用户滚动或停止自动阅读。
  void _on_current_story_extent_changed(double extent, int generation) {
    if (!mounted ||
        generation != _logic_generation ||
        !_scroll_controller.hasClients) {
      return;
    }
    _reading_progress_max_extent = extent;
    if (_viewport_resize_progress != null) return;
    _logic.update_reading_progress(
      _scroll_controller.offset,
      extent,
      max_progress: _visible_story_progress_limit,
    );
    _update_next_story_overlay_opacity();
  }

  /// 复用长短篇共用的广告准备与挂载门禁，素材未就绪时正文保持连续。
  Widget? _build_native_ad_slot() {
    final AdConfig? ad_config = _ad_gate.native_ad_config;
    if (!_ad_gate.should_show_native_ad || ad_config == null) return null;

    final int generation = _logic_generation;
    return ViewportAwareInlineNativeAdBanner(
      // 同一广告配置可以用于多篇小说，每篇都必须重新判断插入时机。
      key: _ad_gate.native_ad_slot_key,
      scroll_controller: _scroll_controller,
      layout_revision: (
        _logic.body_font_size.value,
        _logic.is_story_unlocked.value || !_ad_gate.is_video_ad_gate_required,
        _logic.content.value,
      ),
      is_enabled:
          AdDisplayPolicy.can_show_ads() && !_logic.is_story_unlocked.value,
      ad_unit_id: ad_config.adsId,
      uuid: ad_config.uuid,
      on_unlock: _actions.on_unlock_story_tap,
      is_unlocking: _ad_gate.is_rewarded_ad_loading,
      badge_text_key: 'short_story_read.unlock',
      viewport_top_inset:
          ShortStoryReadStyle.appbar_height +
          ShortStoryReadStyle.native_ad_viewport_top_spacing,
      on_extent_changed: (_) => _on_native_ad_extent_changed(generation),
      on_ad_impression: () {
        if (!mounted || generation != _logic_generation) return;
        unawaited(
          AdImpressionReporter.report(
            ad_config: ad_config,
            placement: AdPlacement.short_story_native,
            source_id: _logic.story_id,
          ),
        );
      },
    );
  }

  // ==================== 滚动处理 ====================

  /// 处理滚动事件。
  ///
  /// - 更新阅读进度
  /// - 检测自动阅读期间的手动滑动
  /// - 检测上下篇加载触发
  void _on_scroll() {
    if (_viewport_resize_progress != null) return;
    final bool is_ad_compensation =
        _scroll_controller.hasClients &&
        is_native_ad_scroll_compensating(_scroll_controller.position);

    // 广告尺寸补偿属于程序滚动，不能误判为手动操作而停止自动阅读。
    if (_logic.is_auto_reading.value &&
        !_auto_read.is_ticking &&
        !_is_restoring_position &&
        !is_ad_compensation) {
      _auto_read.stop();
    }

    if (is_ad_compensation) {
      // 下次手动滚动以补偿后的正文位置为基准，不把广告高度差当作方向位移。
      _logic.sync_scroll_offset(_scroll_controller.offset);
    } else if (!_is_progress_scrolling && !_is_restoring_position) {
      _logic.on_scroll(_scroll_controller.offset);
    }

    // 更新阅读进度。
    if (_scroll_controller.hasClients) {
      final double max_scroll_extent =
          _reading_progress_max_extent ?? _calculate_current_story_extent();
      _logic.update_reading_progress(
        _scroll_controller.offset,
        max_scroll_extent,
        max_progress: _visible_story_progress_limit,
      );
      if (!is_ad_compensation && !_is_restoring_position) {
        _remember_body_reading_position();
      }
    }

    _schedule_next_story_overlay_update();
  }

  /// 延迟到当前帧结束后刷新下一篇标题位置。
  ///
  /// 直接在滚动回调或 setState 中读取 RenderBox，容易拿到旧布局。
  /// 放到 post frame 里，能保证标题进入/离开可视区域时渐变遮罩平滑淡入淡出。
  void _schedule_next_story_overlay_update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _update_next_story_overlay_opacity();
    });
  }

  /// 根据下一篇标题在屏幕中的位置计算底部渐变遮罩透明度。
  void _update_next_story_overlay_opacity() {
    if (_logic.next_story_item == null) {
      if (_next_story_overlay_opacity != 0) {
        setState(() => _next_story_overlay_opacity = 0);
      }
      return;
    }

    final BuildContext? title_context = _next_story_title_key.currentContext;
    if (title_context == null) return;

    final RenderObject? render_object = title_context.findRenderObject();
    if (render_object is! RenderBox || !render_object.hasSize) return;

    final double screen_height = MediaQuery.sizeOf(context).height;
    final double title_top = render_object.localToGlobal(Offset.zero).dy;

    // 标题顶部进入屏幕底部 10px 后开始淡入，向上再移动 72px 达到完整遮罩。
    final double fade_start_y = screen_height - 10;
    final double next_opacity = ((fade_start_y - title_top) / 72).clamp(
      0.0,
      1.0,
    );

    if ((next_opacity - _next_story_overlay_opacity).abs() > 0.01) {
      setState(() => _next_story_overlay_opacity = next_opacity);
    }
  }

  /// 处理正文区域点击事件。
  ///
  /// 切换导航栏和评论栏的显示/隐藏，同时停止自动阅读。
  void _on_content_tap() {
    _auto_read.stop();
    if (_tap_started_with_selection || _is_paragraph_selection_active) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    _logic.toggle_bars_visibility();
  }

  /// 记录选择状态，同时暂停自动阅读，避免选区随自动滚动移动。
  void _on_paragraph_selection_changed(bool active) {
    _is_paragraph_selection_active = active;
    if (active) _auto_read.stop();
  }

  /// 选区输入、登录提示及详情弹窗由长短篇共用组件统一处理。
  Future<void> _on_paragraph_comment(
    StoryParagraph paragraph,
    TextSelection selection,
  ) async {
    _auto_read.stop();
    final action_logic = _logic;
    final generation = _logic_generation;
    final success = await _paragraph_actions.compose(
      context: context,
      paragraph_text: paragraph.text,
      selection: selection,
      is_dark: device_info.dark.value,
      is_current: () => _is_current_logic(action_logic, generation),
      resolve_anchor: () => action_logic.resolve_paragraph_anchor(paragraph),
      on_send: (anchor, text, images) => action_logic.send_paragraph_comment(
        anchor: anchor,
        selection: selection,
        comment_content: text,
        images: images,
      ),
    );
    // 段评发送成功后，乐观更新小说总评论数
    if (success == true && mounted) {
      action_logic.update_comment_count(action_logic.comment_count + 1);
    }
  }

  /// 处理段落选中文字的分享操作。
  void _on_paragraph_share(StoryParagraph paragraph, TextSelection selection) {
    _auto_read.stop();
    final String selected_text = selected_paragraph_text(
      paragraph.text,
      selection,
    );
    if (selected_text.trim().isEmpty) return;
    showTextSelectionPreviewSheet(
      context: context,
      novel_id: _logic.story_id,
      novel_title: _logic.title,
      novel_cover_url: _logic.story_data.value?.cover_url ?? '',
      share_text: selected_text,
      is_dark: device_info.dark.value,
    );
  }

  /// 保存打开时的正文身份，换篇后旧弹窗不能修改新篇的气泡数量。
  void _on_comment_count_tap(
    String paragraph_text,
    int comment_count,
    String? paragraph_id,
  ) {
    _auto_read.stop();
    final int para_id = int.tryParse(paragraph_id ?? '') ?? 0;
    if (para_id <= 0) return;
    final ShortStoryReadLogic action_logic = _logic;
    final int story_id = action_logic.story_id;
    unawaited(
      showCommentSheet(
        context: context,
        novel_id: story_id,
        paragraph_id: para_id,
        on_close: () => Navigator.pop(context),
        on_paragraph_count_changed: (count) {
          action_logic.update_paragraph_comment_count(
            paragraph_id: paragraph_id!,
            count: count,
          );
        },
        on_novel_count_changed: (delta) {
          // 段评增删时，乐观更新小说总评论数
          action_logic.update_comment_count(action_logic.comment_count + delta);
        },
      ),
    );
  }

  // ==================== 动画控制 ====================

  /// 处理底部评论栏可见性变化。
  ///
  /// 可见时反向播放动画（滑出隐藏），不可见时正向播放动画（滑入显示）。
  void _on_bottom_bar_visibility_changed(bool is_visible) {
    if (is_visible) {
      _bottom_bar_animation_controller.reverse();
    } else {
      _bottom_bar_animation_controller.forward();
    }
  }

  /// 绑定当前逻辑实例的底部栏状态，并同步动画当前位置。
  void _bind_bottom_bar_visibility() {
    _bottom_bar_visibility_worker?.dispose();
    _bottom_bar_visibility_worker = ever(
      _logic.is_bottom_bar_visible,
      _on_bottom_bar_visibility_changed,
    );
    _bottom_bar_animation_controller.value = _logic.is_bottom_bar_visible.value
        ? 0
        : 1;
  }

  // ==================== 按钮回调 ====================

  /// 修改字号后按修改前的阅读百分比恢复位置，避免正文突然跳段。
  void _change_body_font_size(VoidCallback change_font_size) {
    if (!_scroll_controller.hasClients) {
      change_font_size();
      return;
    }

    final double old_extent =
        _reading_progress_max_extent ?? _calculate_current_story_extent();
    final double progress = old_extent <= 0
        ? 0
        : (_scroll_controller.offset / old_extent).clamp(0.0, 1.0);
    change_font_size();
    _reading_progress_max_extent = null;
    final int generation = ++_font_relayout_generation;
    unawaited(_restore_progress_after_font_relayout(progress, generation));
  }

  Future<void> _restore_progress_after_font_relayout(
    double progress,
    int generation,
  ) async {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        generation != _font_relayout_generation ||
        !_scroll_controller.hasClients) {
      return;
    }

    final double new_extent = _calculate_current_story_extent();
    _reading_progress_max_extent = new_extent;
    if (new_extent <= 0) return;

    final double target_offset = (new_extent * progress).clamp(
      _scroll_controller.position.minScrollExtent,
      _scroll_controller.position.maxScrollExtent,
    );
    _is_restoring_position = true;
    _scroll_controller.jumpTo(target_offset);
    _logic.update_reading_progress(
      target_offset,
      new_extent,
      max_progress: _visible_story_progress_limit,
    );
    _is_restoring_position = false;
  }

  /// 在旧正文还未换行时记录当前篇的进度，不能使用窗口物理像素推算。
  void _on_viewport_resize_start() {
    if (!_scroll_controller.hasClients ||
        !_is_initialization_complete ||
        _is_restoring_position) {
      return;
    }
    final old_extent =
        _reading_progress_max_extent ?? _calculate_current_story_extent();
    _viewport_resize_progress = old_extent <= 0
        ? 0
        : (_scroll_controller.offset / old_extent).clamp(0.0, 1.0);
    _viewport_resize_logic_generation = _logic_generation;
  }

  /// 收起和展开都按新的正文范围恢复同一进度，不停止自动阅读、不切换篇目。
  void _on_viewport_resize_end() {
    final progress = _viewport_resize_progress;
    _viewport_resize_progress = null;
    if (progress == null ||
        !mounted ||
        _viewport_resize_logic_generation != _logic_generation ||
        !_scroll_controller.hasClients) {
      return;
    }
    final extent = _calculate_current_story_extent();
    _reading_progress_max_extent = extent;
    final target = (extent * progress).clamp(
      _scroll_controller.position.minScrollExtent,
      _scroll_controller.position.maxScrollExtent,
    );
    _is_restoring_position = true;
    try {
      _scroll_controller.jumpTo(target);
      _logic.sync_scroll_offset(target);
      _logic.update_reading_progress(
        target,
        extent,
        max_progress: _visible_story_progress_limit,
      );
    } finally {
      _is_restoring_position = false;
    }
    _update_next_story_overlay_opacity();
  }

  /// 处理上一篇按钮点击。
  void _on_previous_tap() {
    if (_is_transitioning) return;
    final int? previous_id = _logic.previous_story_id;
    if (previous_id == null) return;
    _switch_to_story(previous_id, slide_up: false);
  }

  /// 处理下一篇按钮点击。
  void _on_next_tap() {
    if (_is_transitioning) return;
    final int? next_id = _logic.next_story_id;
    if (next_id == null) return;
    _switch_to_story(next_id, slide_up: true);
  }

  /// 切换到指定小说，执行翻页动画，复用已有目录数据。
  ///
  /// 参数：
  /// - [story_id] 目标小说 ID。
  /// - [slide_up] 动画方向，true 为上滑（下一篇），false 为下滑（上一篇），默认上滑。
  ///
  /// 返回 [Future]，动画和切换完成后 resolve。
  Future<void> _switch_to_story(int story_id, {bool slide_up = true}) async {
    if (_is_transitioning || story_id == _logic.story_id) return;

    _is_transitioning = true;
    FocusManager.instance.primaryFocus?.unfocus();
    _is_paragraph_selection_active = false;
    _auto_read.stop();
    _is_slide_up = slide_up;
    _pull.is_previous_pull_rebounding = false;
    _pull.is_previous_pull_dragging = false;
    _pull.is_next_pull_rebounding = false;
    _pull.is_next_pull_dragging = false;

    // 隐藏导航栏和评论栏。
    if (_logic.is_appbar_visible.value) {
      _logic.is_appbar_visible.value = false;
      _logic.is_bottom_bar_visible.value = false;
    }

    // 保存当前目录列表（传给新逻辑，避免重新请求）。
    final List<ShortStoryItem> existing_catalog = List<ShortStoryItem>.from(
      _logic.catalog_list,
    );
    final ShortStoryReadLogic previous_logic = _logic;
    if (_is_initialization_complete && _has_user_engaged) {
      unawaited(_progress.save_snapshot(previous_logic));
    }

    await _page_transition_controller.forward();
    if (!mounted) return;

    // 动画完成：重置滚动位置。
    if (_scroll_controller.hasClients) {
      _scroll_controller.jumpTo(0);
    }

    // 创建新的逻辑层（新 story_id），复用已有目录数据。
    final ShortStoryReadLogic next_logic = ShortStoryReadLogic(
      context: context,
      story_id: story_id,
    );
    next_logic.set_existing_catalog(existing_catalog);
    previous_logic.dispose();

    setState(() {
      _pull.previous_pull_raw_offset = 0;
      _pull.previous_pull_offset = 0;
      _pull.next_pull_raw_offset = 0;
      _pull.next_pull_offset = 0;
      _next_story_overlay_opacity = 0;
      _reading_progress_max_extent = null;
      _is_initialization_complete = false;
      _has_user_engaged = false;
      _resume_record = null;
      _has_reading_history.value = false;
      _ad_gate.is_rewarded_ad_loading = false;
      _ad_gate.mark_generation_pending();
      _ad_gate.reset_native_state();
      _ad_gate.is_video_ad_gate_required = true;
      _logic = next_logic;
      _logic_generation++;
    });

    // 重新注册底部栏可见性监听（新逻辑实例需要新绑定）。
    _bind_bottom_bar_visibility();

    // 重置翻页动画（骨架屏已显示，无需过渡）。
    _page_transition_controller.reset();
    _is_transitioning = false;

    unawaited(
      _initialize_logic(
        logic: next_logic,
        generation: _logic_generation,
        restore_position: false,
      ),
    );
  }

  /// 处理进度条拖动变化。
  ///
  /// 拖动过程中实时更新进度条显示。
  void _on_progress_changed(double progress) {
    // 拖动过程中不需要额外处理，UI 已在 BottomCommentBar 内部更新。
  }

  /// 处理进度条拖动结束。
  ///
  /// 松手后滚动到对应阅读进度位置，滚动完成后通知 BottomCommentBar 重置拖动状态。
  /// 期间标记 [_is_progress_scrolling] 为 true，阻止滚动事件触发导航栏显隐。
  void _on_progress_change_end(double progress, VoidCallback on_complete) {
    if (!_scroll_controller.hasClients) {
      on_complete();
      return;
    }

    _has_user_engaged = true;
    _is_progress_scrolling = true;

    final double max_scroll_extent =
        _reading_progress_max_extent ?? _calculate_current_story_extent();
    final double accessible_progress =
        (progress.clamp(0.0, _visible_story_progress_limit) /
                _visible_story_progress_limit)
            .clamp(0.0, 1.0);
    final double target_offset = max_scroll_extent * accessible_progress;

    _scroll_controller
        .animateTo(
          target_offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
          if (!mounted) return;
          _is_progress_scrolling = false;
          on_complete();
        });
  }

  /// 处理浮动按钮点击（加载下一篇小说）。
  void _showNextStory() {
    if (_is_transitioning) return;
    final int? next_id = _next_story_id;
    if (next_id == null) return;
    _switch_to_story(next_id, slide_up: true);
  }

  /// 获取目录列表中当前小说的下一个小说 ID。
  ///
  /// 如果目录未加载、当前小说是最后一个、或找不到当前小说，返回 null。
  int? get _next_story_id {
    final List<ShortStoryItem> list = _logic.catalog_list;
    if (list.isEmpty) return null;

    final int current_index = list.indexWhere(
      (ShortStoryItem item) => item.id == _logic.story_id,
    );

    // 当前小说不在目录中，或已是最后一个。
    if (current_index < 0 || current_index >= list.length - 1) return null;

    return list[current_index + 1].id;
  }

  /// 浮动按钮是否应该显示。
  ///
  /// 条件：
  /// - 目录列表已加载且有数据
  /// - 当前小说不是目录中的最后一个
  /// - 导航栏和评论栏可见（与顶部/底部栏同步）
  /// - 不在加载中或错误状态
  bool get _has_floating_button {
    return _next_story_id != null &&
        !_logic.is_loading.value &&
        !_logic.is_error.value;
  }

  /// 当前是否允许从正文顶部下拉切换上一篇。
  bool get _can_pull_previous_story {
    if (_is_transitioning ||
        _pull.is_previous_pull_rebounding ||
        _pull.is_next_pull_rebounding) {
      return false;
    }
    if (_logic.is_loading.value || _logic.is_error.value) return false;
    if (_logic.is_auto_reading.value) return false;
    return _logic.has_previous_story;
  }

  /// 当前正文是否位于最顶部。
  bool get _is_reader_at_top {
    if (!_scroll_controller.hasClients) return true;
    return _scroll_controller.offset <=
        _scroll_controller.position.minScrollExtent + 0.5;
  }

  /// 当前是否允许从正文底部上拉切换下一篇。
  bool get _can_pull_next_story {
    if (_is_transitioning ||
        _pull.is_previous_pull_rebounding ||
        _pull.is_next_pull_rebounding) {
      return false;
    }
    if (_logic.is_loading.value || _logic.is_error.value) return false;
    if (_logic.is_auto_reading.value) return false;
    return _logic.has_next_story;
  }

  /// 当前正文是否位于最底部。
  bool get _is_reader_at_bottom {
    if (!_scroll_controller.hasClients) return false;
    return _scroll_controller.offset >=
        _scroll_controller.position.maxScrollExtent - 0.5;
  }

  /// 内置多语种文案。
  ///
  /// 这里不用强依赖外部 json，避免只改页面源码后缺少翻译 key。
  String _readerText(String key) {
    final String lang = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    const Map<String, Map<String, String>> values =
        <String, Map<String, String>>{
          'zh': <String, String>{
            'pull_down_view': '下拉查看',
            'release_view': '松开查看',
            'view_next': '查看下一篇',
            'next_story': '下一篇',
          },
          'en': <String, String>{
            'pull_down_view': 'Pull to view',
            'release_view': 'Release to view',
            'view_next': 'View next story',
            'next_story': 'Next story',
          },
          'fr': <String, String>{
            'pull_down_view': 'Tirez pour voir',
            'release_view': 'Relâchez pour voir',
            'view_next': 'Voir la suite',
            'next_story': 'Suite',
          },
          'sw': <String, String>{
            'pull_down_view': 'Vuta ili kuona',
            'release_view': 'Achia ili kuona',
            'view_next': 'Soma inayofuata',
            'next_story': 'Inayofuata',
          },
        };

    return values[lang]?[key] ?? values['en']![key] ?? key;
  }

  // ==================== [StoryNativeAdHost] ====================

  @override
  int get story_id => _logic.story_id;

  @override
  String get content => _logic.content.value;

  @override
  bool get is_story_unlocked => _logic.is_story_unlocked.value;

  @override
  int get reader_generation => _logic_generation;

  @override
  bool get is_initialization_complete => _is_initialization_complete;

  @override
  bool get has_user_engaged => _has_user_engaged;

  @override
  bool get is_cjk_language => LanguageUtil.is_cjk_language(
    Localizations.localeOf(context).languageCode,
  );

  @override
  void refresh_ui() {
    if (mounted) setState(() {});
  }

  @override
  void invalidate_progress_extent() {
    _reading_progress_max_extent = null;
  }

  // ==================== [StoryAutoReadHost] ====================
  // resolve_story_extent / mark_user_engaged 由 StoryProgressHost、
  // StoryToolbarHost 的同名实现满足。

  @override
  bool get is_viewport_resizing => _viewport_resize_progress != null;

  // ==================== [StoryToolbarHost] ====================

  @override
  ShortStoryReadLogic get logic => _logic;

  @override
  bool is_current_logic(ShortStoryReadLogic logic, int generation) =>
      _is_current_logic(logic, generation);

  @override
  set is_rewarded_ad_loading(bool value) {
    _ad_gate.is_rewarded_ad_loading = value;
  }

  @override
  bool get is_rewarded_ad_loading => _ad_gate.is_rewarded_ad_loading;

  @override
  void start_auto_read() => _auto_read.start();

  @override
  void change_body_font_size(VoidCallback mutation) {
    _change_body_font_size(mutation);
  }

  @override
  void open_story(int story_id) {
    _switch_to_story(story_id);
  }

  @override
  void reset_next_story_overlay() {
    _next_story_overlay_opacity = 0;
  }

  @override
  double calculate_story_extent() => _calculate_current_story_extent();

  // ==================== [StoryProgressHost] ====================

  @override
  ScrollController get scroll_controller => _scroll_controller;

  @override
  GlobalKey get story_end_key => _current_story_end_key;

  @override
  double get visible_progress_limit => _visible_story_progress_limit;

  @override
  bool is_current_initialization(
    ShortStoryReadLogic logic,
    int generation,
    int attempt,
  ) =>
      _is_current_initialization(logic, generation, attempt);

  @override
  set is_restoring_position(bool value) {
    _is_restoring_position = value;
  }

  @override
  BuildContext get host_context => context;

  @override
  double resolve_story_extent() {
    return _reading_progress_max_extent ?? _calculate_current_story_extent();
  }

  @override
  void cache_story_extent(double extent) {
    _reading_progress_max_extent = extent;
  }

  // ==================== [StoryPullGestureHost] ====================

  @override
  bool get is_selection_active => _is_paragraph_selection_active;

  @override
  bool get is_composer_open => _is_paragraph_composer_open;

  @override
  bool get can_pull_previous_story => _can_pull_previous_story;

  @override
  bool get can_pull_next_story => _can_pull_next_story;

  @override
  bool get is_reader_at_top => _is_reader_at_top;

  @override
  bool get is_reader_at_bottom => _is_reader_at_bottom;

  @override
  double get viewport_height => MediaQuery.sizeOf(context).height;

  @override
  bool get host_mounted => mounted;

  @override
  int? get previous_story_id => _logic.previous_story_id;

  @override
  int? get next_story_id => _logic.next_story_id;

  @override
  void stop_auto_read() => _auto_read.stop();

  @override
  void switch_to_story(int story_id, {required bool slide_up}) {
    _switch_to_story(story_id, slide_up: slide_up);
  }

  @override
  void on_pull_offsets_changed() => setState(() {});

  @override
  void schedule_next_story_overlay_update() {
    _schedule_next_story_overlay_update();
  }

  @override
  void sync_next_preview_scroll_position() {
    _sync_next_preview_scroll_position();
  }

  @override
  void mark_user_engaged() {
    _has_user_engaged = true;
  }

  /// 底部上拉时，同步滚动位置到新的内容底部。
  ///
  /// 下一篇正文预览的高度会随着 `_pull.next_pull_offset` 增加。
  /// 如果只增高底部内容，但不调整 SingleChildScrollView 内部 offset，
  /// 新增出来的正文会长在屏幕下方，用户看到的仍然只有最开始那几行。
  ///
  /// 放到 post frame 是为了等本轮 setState 完成布局，拿到最新 maxScrollExtent。
  void _sync_next_preview_scroll_position() {
    if (!_pull.is_next_pull_dragging || _pull.next_pull_offset <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll_controller.hasClients) return;
      if (!_pull.is_next_pull_dragging || _pull.next_pull_offset <= 0) return;

      final ScrollPosition position = _scroll_controller.position;
      final double max_extent = position.maxScrollExtent;

      if ((max_extent - position.pixels).abs() > 0.5) {
        _scroll_controller.jumpTo(max_extent);
      }

      _schedule_next_story_overlay_update();
    });
  }

  /// 构建顶部下拉查看上一篇提示。
  /// 替换封面成功回调：同步本地详情与缓存并刷新封面展示。
  void _on_cover_replaced(String cover_url, int cover_width, int cover_height) {
    _logic.update_story_cover(
      cover_url: cover_url,
      cover_width: cover_width,
      cover_height: cover_height,
    );
  }



  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// 当前是否为夜间模式。
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      /// 页面背景色。
      final Color bg_color = is_dark
          ? ShortStoryReadStyle.bg_dark_color
          : ShortStoryReadStyle.bg_light_color;

      /// 状态栏高度。
      final double status_bar_height = MediaQuery.viewPaddingOf(context).top;

      final Widget page_body;
      if (_logic.is_loading.value) {
        page_body = _buildSkeleton(
          is_dark: is_dark,
          status_bar_height: status_bar_height,
        );
      } else if (_logic.is_error.value) {
        page_body = _buildError(
          is_dark: is_dark,
          status_bar_height: status_bar_height,
        );
      } else {
        final Widget content = _buildContent(
          is_dark: is_dark,
          status_bar_height: status_bar_height,
        );
        // 初始化前后保持同一棵组件树。恢复进度时正文已经在骨架层下完成
        // jumpTo；如果撤下骨架时把正文从 Stack 子节点移到 Scaffold.body，
        // Flutter 会重新挂载 ScrollPosition 并把视觉位置重置到顶部。
        page_body = ShortStoryInitializationOverlay(
          content: content,
          show_overlay: !_is_initialization_complete,
          overlay: ColoredBox(
            color: bg_color,
            child: _buildSkeleton(
              is_dark: is_dark,
              status_bar_height: status_bar_height,
            ),
          ),
        );
      }

      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: bg_color,
        body: page_body,
      );
    });
  }

  /// 构建主要内容区域。
  ///
  /// 渲染树全部收敛在 [StoryContentStack]，这里只组装主题/状态/回调三组参数。
  Widget _buildContent({
    required bool is_dark,
    required double status_bar_height,
  }) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final Color bg_color = is_dark
        ? ShortStoryReadStyle.bg_dark_color
        : ShortStoryReadStyle.bg_light_color;
    final double bottom_padding = MediaQuery.viewPaddingOf(context).bottom;

    /// 尺寸回调必须属于创建该阅读树时的小说，避免切篇后回写旧范围。
    final int generation = _logic_generation;

    return StoryContentStack(
      status_bar_height: status_bar_height,
      bottom_padding: bottom_padding,
      theme: StoryContentTheme(
        is_dark: is_dark,
        is_cjk: is_cjk,
        bg_color: bg_color,
        title_color: is_dark
            ? ShortStoryReadStyle.title_dark_color
            : ShortStoryReadStyle.title_light_color,
        title_font_size: is_cjk ? 22.0 : 20.0,
      ),
      state: StoryContentState(
        logic: _logic,
        generation: _logic_generation,
        scroll_controller: _scroll_controller,
        reader_scroll_physics: _reader_scroll_physics,
        page_transition_controller: _page_transition_controller,
        bottom_bar_slide_animation: _bottom_bar_slide_animation,
        floating_button_fade_animation: _floating_button_fade_animation,
        is_slide_up: _is_slide_up,
        previous_pull_offset: _pull.previous_pull_offset,
        next_pull_offset: _pull.next_pull_offset,
        next_story_overlay_opacity: _next_story_overlay_opacity,
        body_start_key: _body_start_key,
        story_end_key: _current_story_end_key,
        next_story_title_key: _next_story_title_key,
        has_reading_history: _has_reading_history,
        is_paragraph_selection_active: _is_paragraph_selection_active,
        is_video_ad_gate_required: _ad_gate.is_video_ad_gate_required,
        is_rewarded_ad_loading: _ad_gate.is_rewarded_ad_loading,
        native_ad_slot: _build_native_ad_slot(),
        native_ad_insert_index: _ad_gate.native_ad_insert_index,
        show_floating_button: _has_floating_button,
      ),
      actions: StoryContentActions(
        on_content_tap: _on_content_tap,
        on_pointer_down: () {
          _tap_started_with_selection = _is_paragraph_selection_active;
        },
        on_pointer_move: _pull.on_reader_pointer_move,
        on_pointer_end: _pull.on_reader_pointer_end,
        on_viewport_resize_start: _on_viewport_resize_start,
        on_viewport_resize_end: _on_viewport_resize_end,
        on_layout_pending: () {
          if (generation == _logic_generation) {
            _reading_progress_max_extent = null;
          }
        },
        on_extent_changed: _on_current_story_extent_changed,
        on_read_story: _on_read_story,
        on_cover_replaced: _on_cover_replaced,
        on_back: _actions.on_back,
        on_favorite: _actions.on_favorite_tap,
        on_share: _actions.on_share,
        on_comment: _actions.on_comment_tap,
        on_paragraph_comment: _on_paragraph_comment,
        on_paragraph_share: _on_paragraph_share,
        on_paragraph_selection_changed: _on_paragraph_selection_changed,
        on_comment_count_tap: _on_comment_count_tap,
        on_unlock: _actions.on_unlock_story_tap,
        on_previous_tap: _on_previous_tap,
        on_next_tap: _on_next_tap,
        on_progress_changed: _on_progress_changed,
        on_progress_change_end: _on_progress_change_end,
        on_scroll_to_bottom: _showNextStory,
        on_auto_read_settings_tap: _auto_read.on_settings_tap,
        on_catalog_tap: _actions.on_catalog_tap,
        on_like_tap: _actions.on_like_tap,
        on_setting_tap: _actions.on_setting_tap,
        schedule_next_story_overlay_update: _schedule_next_story_overlay_update,
        reader_text: _readerText,
      ),
    );
  }


  /// 首次加载直接使用真实海报导航位置，避免旧导航与安全区重复叠加。
  Widget _buildSkeleton({
    required bool is_dark,
    required double status_bar_height,
  }) => WindowContentLayout(
    child: SkeletonScreen(is_dark: is_dark, on_back: _actions.on_back),
  );

  /// 构建错误状态。
  ///
  /// 包含背景装饰、无网络提示组件和完整导航栏。
  Widget _buildError({
    required bool is_dark,
    required double status_bar_height,
  }) {
    return Stack(
      children: <Widget>[
        /// 背景装饰。
        StarfieldDecoration(is_dark: is_dark),
        WindowContentLayout(
          child: Stack(
            fit: StackFit.expand,
            children: [
              /// 无网络状态（居中显示图标、标题和描述，点击触发重试）。
              NoInternet(
                is_dark: is_dark,
                title: easy.tr('no_internet.title'),
                description: easy.tr('no_internet.description'),
                on_reload: _retry_current_story,
              ),
            ],
          ),
        ),

        /// 顶部导航栏。
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FullAppbar(
            is_dark: is_dark,
            on_back: _actions.on_back,
            on_favorite_tap: _actions.on_favorite_tap,
            on_share: _actions.on_share,
            is_favorited: _logic.is_favorited,
            status_bar_height: status_bar_height,
          ),
        ),
      ],
    );
  }
}
