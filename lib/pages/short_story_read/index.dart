import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:app/api/bookshelf.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/stores/comment_navigation.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/widgets/full_appbar.dart';
import 'package:app/pages/short_story_read/widgets/bottom_comment_bar.dart';
import 'package:app/pages/short_story_read/widgets/tag_list.dart';
import 'package:app/pages/short_story_read/widgets/story_unlock_gate/index.dart';
import 'package:app/pages/short_story_read/widgets/initialization_overlay.dart';
import 'package:app/pages/ranking_full_list/widgets/starfield_decoration.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/pages/short_story_read/widgets/skeleton_screen.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_sheet.dart';
import 'package:app/pages/short_story_read/widgets/reading_settings_sheet.dart';
import 'package:app/pages/short_story_read/widgets/auto_read_settings_sheet.dart';
import 'package:app/components/no_internet/index.dart';
import 'package:app/components/share_sheet/index.dart';
import 'package:app/components/inline_native_ad/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/native_ad_visibility.dart';
import 'package:app/pages/short_story_read/utils/resolve_next_story_preview_content.dart';
import 'package:app/util/native_ad_insert_index.dart';
import 'package:app/pages/short_story_read/widgets/next_story_preview.dart';
import 'package:app/pages/short_story_read/widgets/reader_overlay_layer.dart';
import 'package:app/pages/short_story_read/widgets/previous_pull_header.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/models/ad_verify_result.dart';
import 'package:app/util/rewarded_ad_util.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/percentage_probability.dart';
import 'package:app/stores/ad_config_store.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  /// 翻页方向（true = 向上滑动（下一篇），false = 向下滑动（上一篇））。
  bool _is_slide_up = true;

  /// 顶部下拉查看上一篇的原始拖拽距离。
  ///
  /// 这个值直接来自手指移动距离，不直接用于布局。
  double _previous_pull_raw_offset = 0;

  /// 顶部下拉查看上一篇的视觉位移距离。
  ///
  /// 这个值经过阻尼处理，直接绑定到正文 Transform，保证手指移动时页面持续跟随。
  double _previous_pull_offset = 0;

  /// 顶部下拉查看上一篇的触发距离。
  static const double _previous_pull_trigger_distance = 118.0;

  /// 顶部下拉查看上一篇的最大视觉下拉距离。
  static const double _previous_pull_max_distance = 230.0;

  /// 顶部下拉手势是否已经接管当前拖拽。
  bool _is_previous_pull_dragging = false;

  /// 是否正在执行顶部下拉回弹动画。
  bool _is_previous_pull_rebounding = false;

  /// 顶部下拉回弹动画控制器。
  late AnimationController _previous_pull_animation_controller;

  /// 底部上拉查看下一篇的原始拖拽距离。
  double _next_pull_raw_offset = 0;

  /// 底部上拉查看下一篇的视觉位移距离。
  double _next_pull_offset = 0;

  /// 底部上拉查看下一篇的触发距离。
  static const double _next_pull_trigger_distance = 138.0;

  /// 底部上拉查看下一篇的最大视觉上拉比例。
  ///
  /// 这里不能用很小的固定值，否则下一篇正文预览最多只能露出几行。
  /// 按屏幕高度计算，保证用户一直上拉不松手时，下一篇标题和正文能继续跟手上移。
  static const double _next_pull_max_viewport_ratio = 0.82;

  /// 底部上拉手势是否已经接管当前拖拽。
  bool _is_next_pull_dragging = false;

  /// 是否正在执行底部上拉回弹动画。
  bool _is_next_pull_rebounding = false;

  /// 底部上拉回弹动画控制器。
  late AnimationController _next_pull_animation_controller;

  /// 下一篇标题的定位 key，用来判断标题是否已经进入可视区域。
  final GlobalKey _next_story_title_key = GlobalKey();

  /// 底部渐变遮罩透明度。
  ///
  /// 下一篇标题进入屏幕底部可视区域 10px 时开始淡入，离开时淡出。
  double _next_story_overlay_opacity = 0;

  /// 是否由进度条拖动触发的滚动（为 true 时跳过导航栏显隐逻辑）。
  bool _is_progress_scrolling = false;

  /// 当前小说的广告概率是否已经完成一次性判断。
  int? _ad_probability_generation;

  /// 短篇小说视频广告概率是否命中（需要展示解锁门控）。
  ///
  /// true = 需要观看广告才能解锁，false = 免广告直接阅读全文。
  /// 在小说初始化时根据 ads_short_story_video_ad_probability 掷骰子决定。
  bool _is_video_ad_gate_required = true;

  /// FCM 推送评论导航监听器。
  Worker? _comment_navigation_worker;

  /// 底部栏可见性监听器。
  Worker? _bottom_bar_visibility_worker;

  /// 项目广告开关变更监听器。
  Worker? _ad_policy_worker;

  /// 自动阅读滚动 Ticker（每帧调用，实现平滑滚动）。
  Ticker? _auto_read_ticker;

  /// 上一帧时间戳（用于计算每帧滚动距离）。
  Duration? _auto_read_last_tick;

  /// Ticker 是否正在执行滚动（用于区分 Ticker 滚动和用户手动滚动）。
  bool _is_auto_read_ticking = false;

  /// 自动阅读是否因应用进入后台而暂停。
  bool _auto_read_paused_by_lifecycle = false;

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

  /// 当前短篇的激励视频广告是否正在加载或展示。
  bool _is_rewarded_ad_loading = false;

  /// 当前小说是否命中原生高级广告展示概率。
  bool _should_show_native_ad = false;

  /// 当前小说的原生高级广告配置。
  AdConfig? _native_ad_config;

  /// 正在请求广告配置的逻辑代次集合，避免旧请求阻塞新小说。
  final Set<int> _native_ad_config_loading_generations = <int>{};

  /// 原生广告素材当前的加载状态。
  NativeAdLoadStatus _native_ad_load_status = NativeAdLoadStatus.idle;

  /// 是否允许 NativeAdBanner 挂载平台广告视图。
  bool _can_attach_native_ad = false;

  /// 广告概率命中后是否已在正文中预留稳定高度。
  bool _is_native_ad_slot_reserved = false;

  /// 广告位定位锚点，每篇小说使用独立实例。
  GlobalKey _native_ad_slot_key = GlobalKey();

  /// 是否已安排下一帧检查广告与视口的交叠状态。
  bool _is_native_ad_visibility_update_scheduled = false;

  /// 正在保存进度的小说 ID；不同小说允许并行，同一小说按顺序提交。
  final Set<int> _progress_save_in_flight_ids = <int>{};

  /// 同一小说保存期间只保留最新进度快照，避免旧请求覆盖新进度。
  final Map<
    int,
    ({int chapter_offset, double read_progress, bool notify_bookshelf})
  >
  _queued_progress_snapshots =
      <
        int,
        ({int chapter_offset, double read_progress, bool notify_bookshelf})
      >{};

  /// 当前逻辑实例的版本号，用于丢弃切换小说前发起的异步结果。
  int _logic_generation = 0;

  /// 当前初始化尝试编号，用于丢弃同一小说重复重试产生的旧结果。
  int _initialization_attempt = 0;

  /// 当前篇正文末尾定位点。
  ///
  /// 阅读进度只计算当前篇，不把异步加载的下一篇预览算入总长度。
  final GlobalKey _current_story_end_key = GlobalKey();

  /// 当前篇可用于阅读进度计算的最大滚动距离。
  double? _reading_progress_max_extent;

  /// 正文字号连续变化时只执行最后一次重新排版定位。
  int _font_relayout_generation = 0;

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

    // 初始化顶部下拉回弹动画控制器。
    _previous_pull_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // 初始化底部上拉回弹动画控制器。
    _next_pull_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

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
        _on_comment_tap(scroll_to_comment_id: widget.initial_comment_id);
      });
    }

    // TODO 监听 FCM 推送点击事件（用户已在当前页面时收到推送）
    _comment_navigation_worker = ever(CommentNavigation.pending_comment_id, (
      int comment_id,
    ) {
      if (!mounted || comment_id <= 0) return;
      if (CommentNavigation.pending_novel_id.value != _logic.story_id) return;
      CommentNavigation.consume();
      _on_comment_tap(scroll_to_comment_id: comment_id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress_save_timer?.cancel();
    // 退出页面时保存一次阅读进度。
    _save_current_progress_on_exit();
    _logic.dispose(clear_catalog: true);
    _auto_read_ticker?.dispose();
    _comment_navigation_worker?.dispose();
    _bottom_bar_visibility_worker?.dispose();
    _ad_policy_worker?.dispose();
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    _bottom_bar_animation_controller.dispose();
    _page_transition_controller.dispose();
    _previous_pull_animation_controller.dispose();
    _next_pull_animation_controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_auto_read_paused_by_lifecycle && _logic.is_auto_reading.value) {
        _auto_read_paused_by_lifecycle = false;
        _begin_auto_read_ticker();
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_save_current_progress());
    }
    if ((state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused) &&
        _logic.is_auto_reading.value) {
      _auto_read_paused_by_lifecycle = true;
      _auto_read_ticker?.stop();
      _auto_read_last_tick = null;
    }
  }

  /// 启动阅读进度定时保存定时器。
  void _start_progress_save_timer() {
    _progress_save_timer?.cancel();
    _progress_save_timer = Timer.periodic(
      const Duration(seconds: _progress_save_interval_seconds),
      (_) => _save_current_progress(),
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
  /// 未解锁时只显示约三分之一正文，因此滚动到折叠处不能记为全文完成。
  double get _visible_story_progress_limit {
    return (_logic.is_story_unlocked.value || !_is_video_ad_gate_required)
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
    _resolve_ad_probability_decisions(logic: logic, generation: generation);
    if (_should_show_native_ad) {
      // 后台请求并预加载广告，未完成前不占用正文空间。
      unawaited(_load_native_ad_config(logic: logic, generation: generation));
    }

    if (restore_position && record != null) {
      await _restore_last_read_position(
        logic: logic,
        generation: generation,
        attempt: attempt,
        record: record,
      );
    } else {
      await _wait_for_story_layout(
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

  /// 后台加载原生高级广告配置。
  ///
  /// 从 `redis/get.ads_ids` 本地缓存获取广告单元 ID，
  /// 成功且广告商为谷歌 AdMob 时创建 NativeAdBanner 组件。
  /// 加载失败不影响页面正常展示。
  Future<void> _load_native_ad_config({
    required ShortStoryReadLogic logic,
    required int generation,
  }) async {
    const String log_prefix = '[NativeAdConfig]';
    if (!AdDisplayPolicy.can_show_ads() ||
        !_should_show_native_ad ||
        _ad_probability_generation != generation ||
        !_native_ad_config_loading_generations.add(generation)) {
      return;
    }
    try {
      logUtil(msg: '$log_prefix 开始读取本地广告配置, source_id=${logic.story_id}');

      final AdConfig? ad_config = Get.isRegistered<AdConfigStore>()
          ? Get.find<AdConfigStore>().select_google_config(
              AdPlacement.short_story_native,
            )
          : null;

      // 页面已切换或已销毁，丢弃结果。
      if (_logic_generation != generation ||
          !mounted ||
          !AdDisplayPolicy.can_show_ads() ||
          !_should_show_native_ad ||
          _ad_probability_generation != generation) {
        logUtil(msg: '$log_prefix 页面已切换或销毁，丢弃结果');
        return;
      }

      if (ad_config == null) {
        logUtil(msg: '$log_prefix 本地缓存没有可用配置，跳过', type: 'w');
        _discard_native_ad_for_generation(generation);
        return;
      }
      logUtil(
        msg:
            '$log_prefix 广告配置: '
            'id=${ad_config.id}, '
            'adsId=${ad_config.adsId}, '
            'advertisers=${ad_config.advertisers}, '
            'advertisersStr=${ad_config.advertisersStr}, '
            'adsType=${ad_config.adsType}, '
            'adsTypeStr=${ad_config.adsTypeStr}, '
            'uuid=${ad_config.uuid}',
      );

      // advertisers=1 表示谷歌 AdMob，且 ads_id 必须有值。
      if (ad_config.advertisers != AdTypeConfig.google_advertiser ||
          ad_config.adsId.isEmpty) {
        logUtil(
          msg:
              '$log_prefix 广告商不是谷歌或adsId为空，跳过: '
              'advertisers=${ad_config.advertisers}, '
              'adsId="${ad_config.adsId}"',
          type: 'w',
        );
        _discard_native_ad_for_generation(generation);
        return;
      }

      logUtil(msg: '$log_prefix 创建NativeAdBanner, adUnitId=${ad_config.adsId}');

      setState(() {
        _native_ad_config = ad_config;
      });
    } catch (e, stack_trace) {
      logUtil(msg: '$log_prefix 广告配置加载异常: $e\n$stack_trace', type: 'e');
      _discard_native_ad_for_generation(generation);
    } finally {
      _native_ad_config_loading_generations.remove(generation);
    }
  }

  /// 为当前小说一次性判断原生广告和激励视频广告概率。
  void _resolve_ad_probability_decisions({
    required ShortStoryReadLogic logic,
    required int generation,
  }) {
    if (_ad_probability_generation == generation) return;

    // 配置尚未解析时保持待定，等 config_revision 通知后再判断；
    // 明确关闭广告时才把当前小说固定为免广告。
    if (!AdDisplayPolicy.can_show_ads() &&
        !AdDisplayPolicy.is_config_resolved()) {
      return;
    }

    _ad_probability_generation = generation;
    _reset_native_ad_state();

    if (!AdDisplayPolicy.can_show_ads()) {
      _is_video_ad_gate_required = false;
      return;
    }

    final current_config = Get.find<ProjectConfigStore>().current;
    _is_video_ad_gate_required = PercentageProbability.is_hit(
      current_config.ads_short_story_video_ad_probability,
    );

    final bool content_supports_native_ad = can_insert_native_ad(
      logic.content.value,
    );
    final bool reader_has_not_started =
        !_is_initialization_complete || !_has_user_engaged;
    _should_show_native_ad =
        content_supports_native_ad &&
        reader_has_not_started &&
        PercentageProbability.is_hit(
          current_config.ads_short_story_show_interstitial_ads_probability,
        );
    _is_native_ad_slot_reserved = _should_show_native_ad;
    logUtil(
      msg:
          '[NativeAdConfig] 概率判断完成: '
          'generation=$generation, '
          'nativeProbability='
          '${current_config.ads_short_story_show_interstitial_ads_probability}, '
          'showNative=$_should_show_native_ad, '
          'videoProbability=${current_config.ads_short_story_video_ad_probability}, '
          'requireVideo=$_is_video_ad_gate_required',
    );
    if (mounted) setState(() {});
  }

  /// 清空当前原生广告的配置、预留位置和挂载状态。
  void _reset_native_ad_state() {
    _should_show_native_ad = false;
    _native_ad_config = null;
    _native_ad_load_status = NativeAdLoadStatus.idle;
    _can_attach_native_ad = false;
    _is_native_ad_slot_reserved = false;
    _native_ad_slot_key = GlobalKey();
    _is_native_ad_visibility_update_scheduled = false;
    _reading_progress_max_extent = null;
  }

  /// 当前广告配置不可用时移除广告位。
  void _discard_native_ad_for_generation(int generation) {
    if (!mounted || _logic_generation != generation) return;
    setState(_reset_native_ad_state);
  }

  /// 将远端广告平台开关同步到当前短篇的正文与广告位。
  void _on_ad_policy_changed() {
    _logic.sync_ad_access_policy();
    if (!AdDisplayPolicy.can_show_ads()) {
      _is_rewarded_ad_loading = false;
      _is_video_ad_gate_required = false;
      _ad_probability_generation = _logic_generation;
      if (mounted) setState(_reset_native_ad_state);
      return;
    }

    if (_logic.content.value.isNotEmpty) {
      _resolve_ad_probability_decisions(
        logic: _logic,
        generation: _logic_generation,
      );
    }
    if (_should_show_native_ad && _native_ad_config == null) {
      unawaited(
        _load_native_ad_config(logic: _logic, generation: _logic_generation),
      );
    }
    if (mounted) setState(() {});
  }

  /// 退出页面时保存阅读进度。
  void _save_current_progress_on_exit() {
    if (!_is_initialization_complete || !_has_user_engaged) return;
    unawaited(_save_progress_snapshot(_logic, notify_bookshelf: true));
  }

  /// 保存当前阅读进度到服务器。
  Future<void> _save_current_progress() async {
    if (!_is_initialization_complete || !_has_user_engaged) return;
    await _save_progress_snapshot(_logic);
  }

  /// 保存指定逻辑实例对应的进度快照。
  Future<void> _save_progress_snapshot(
    ShortStoryReadLogic logic, {
    bool notify_bookshelf = false,
  }) async {
    if (!_scroll_controller.hasClients || !user_information.isLoggedIn.value) {
      return;
    }

    final int novel_id = logic.story_id;
    final int novel_language_id =
        int.tryParse(logic.story_data.value?.novel_language_id ?? '') ?? 0;
    final previous_snapshot = _queued_progress_snapshots[novel_id];
    _queued_progress_snapshots[novel_id] = (
      chapter_offset: _scroll_controller.offset.round(),
      read_progress: logic.reading_progress.value * 100,
      notify_bookshelf:
          notify_bookshelf || (previous_snapshot?.notify_bookshelf ?? false),
    );
    if (!_progress_save_in_flight_ids.add(novel_id)) return;

    try {
      while (_queued_progress_snapshots.containsKey(novel_id)) {
        final snapshot = _queued_progress_snapshots.remove(novel_id)!;
        try {
          final bool saved = await save_read_progress(
            novel_id: novel_id,
            novel_language_id: novel_language_id > 0 ? novel_language_id : null,
            chapter_offset: snapshot.chapter_offset,
            read_progress: snapshot.read_progress,
          );
          if (saved && snapshot.notify_bookshelf) {
            await BookshelfSyncService.history_changed();
          }
        } catch (_) {
          // 保存失败不影响阅读；下一次定时保存会提交更新后的快照。
        }
      }
    } finally {
      _progress_save_in_flight_ids.remove(novel_id);
    }
  }

  /// 根据真实加载结果和正文布局恢复上次阅读位置。
  Future<void> _restore_last_read_position({
    required ShortStoryReadLogic logic,
    required int generation,
    required int attempt,
    required LastReadRecord record,
  }) async {
    final bool has_offset = record.chapter_offset > 0;
    final bool has_progress = record.read_progress > 0;
    await _wait_for_story_layout(
      logic: logic,
      generation: generation,
      attempt: attempt,
    );
    if (!_is_current_initialization(logic, generation, attempt) ||
        (!has_offset && !has_progress)) {
      return;
    }

    _do_restore_position(record);
  }

  /// 等待正文真实挂载，并计算只属于当前篇的滚动范围。
  Future<void> _wait_for_story_layout({
    required ShortStoryReadLogic logic,
    required int generation,
    required int attempt,
  }) async {
    for (int frame = 0; frame < 12; frame++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!_is_current_initialization(logic, generation, attempt)) return;

      if (_scroll_controller.hasClients &&
          _scroll_controller.position.hasContentDimensions &&
          _current_story_end_key.currentContext != null) {
        _reading_progress_max_extent = _calculate_current_story_extent();
        return;
      }
    }
  }

  /// 计算正文末尾对齐可视区域底部时的真实滚动偏移。
  double _calculate_current_story_extent() {
    if (!_scroll_controller.hasClients) return 0;

    final BuildContext? marker_context = _current_story_end_key.currentContext;
    final RenderObject? marker = marker_context?.findRenderObject();
    if (marker == null || !marker.attached) {
      return _scroll_controller.position.maxScrollExtent;
    }

    final RenderAbstractViewport viewport = RenderAbstractViewport.of(marker);
    final double reveal_offset = viewport.getOffsetToReveal(marker, 1).offset;
    return reveal_offset.clamp(
      _scroll_controller.position.minScrollExtent,
      _scroll_controller.position.maxScrollExtent,
    );
  }

  /// 执行滚动位置恢复。
  void _do_restore_position(LastReadRecord record) {
    if (!_scroll_controller.hasClients) return;

    final double max_extent =
        _reading_progress_max_extent ?? _calculate_current_story_extent();
    if (max_extent <= 0) return;
    double target_offset = 0;

    // 优先使用百分比恢复，像素偏移在屏幕尺寸或字号变化后会失效。
    if (record.read_progress > 0) {
      final double visible_progress =
          (record.read_progress / 100 / _visible_story_progress_limit).clamp(
            0.0,
            1.0,
          );
      target_offset = (visible_progress * max_extent).clamp(0.0, max_extent);
    } else if (record.chapter_offset > 0) {
      target_offset = record.chapter_offset
          .clamp(0, max_extent.toInt())
          .toDouble();
    }

    if (target_offset > 0) {
      _is_restoring_position = true;
      _scroll_controller.jumpTo(target_offset);
      _logic.update_reading_progress(
        target_offset,
        max_extent,
        max_progress: _visible_story_progress_limit,
      );
      _is_restoring_position = false;
    }
  }

  // ==================== 滚动相关 ====================

  /// 停止自动阅读（停止 Ticker）。
  void _stop_auto_read() {
    _auto_read_paused_by_lifecycle = false;
    if (_logic.is_auto_reading.value) {
      _logic.is_auto_reading.value = false;
      _auto_read_ticker?.stop();
      _auto_read_ticker?.dispose();
      _auto_read_ticker = null;
    }
  }

  /// 返回阅读区的自然滚动物理效果。
  ScrollPhysics get _reader_scroll_physics {
    if (_previous_pull_offset > 0 || _next_pull_offset > 0) {
      return const NeverScrollableScrollPhysics();
    }

    return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  /// 在当前布局帧结束后检查原生广告是否需要挂载。
  void _schedule_native_ad_visibility_update() {
    if (!_should_show_native_ad ||
        _native_ad_load_status != NativeAdLoadStatus.loaded ||
        _can_attach_native_ad ||
        _is_native_ad_visibility_update_scheduled) {
      return;
    }

    _is_native_ad_visibility_update_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _is_native_ad_visibility_update_scheduled = false;
      if (!mounted ||
          !_should_show_native_ad ||
          _native_ad_load_status != NativeAdLoadStatus.loaded ||
          _can_attach_native_ad) {
        return;
      }
      _update_native_ad_visibility(_logic_generation);
    });
  }

  /// 广告进入可视区域时挂载已预加载的原生平台视图。
  void _update_native_ad_visibility(int generation) {
    if (!mounted ||
        generation != _logic_generation ||
        !_should_show_native_ad ||
        _native_ad_load_status != NativeAdLoadStatus.loaded ||
        _can_attach_native_ad) {
      return;
    }

    final BuildContext? slot_context = _native_ad_slot_key.currentContext;
    final RenderObject? slot_render_object = slot_context?.findRenderObject();
    if (slot_render_object is! RenderBox || !slot_render_object.hasSize) return;

    final MediaQueryData media_query = MediaQuery.of(context);
    final double viewport_top =
        media_query.viewPadding.top +
        ShortStoryReadStyle.appbar_height +
        ShortStoryReadStyle.native_ad_viewport_top_spacing;
    final double viewport_bottom =
        media_query.size.height - media_query.viewPadding.bottom;
    final double slot_top = slot_render_object.localToGlobal(Offset.zero).dy;

    final bool should_attach = should_attach_native_ad(
      slot_top: slot_top,
      slot_height: slot_render_object.size.height,
      viewport_top: viewport_top,
      viewport_bottom: viewport_bottom,
      minimum_visible_extent:
          ShortStoryReadStyle.native_ad_minimum_visible_extent,
    );
    if (!should_attach) return;

    setState(() {
      _can_attach_native_ad = true;
    });
  }

  /// 同步 NativeAdBanner 的预加载状态。
  void _on_native_ad_load_status_changed(
    NativeAdLoadStatus status,
    int generation,
  ) {
    if (!mounted || generation != _logic_generation) return;
    _native_ad_load_status = status;
    if (status == NativeAdLoadStatus.failed) {
      _discard_native_ad_for_generation(generation);
      return;
    }
    if (status == NativeAdLoadStatus.loaded) {
      _schedule_native_ad_visibility_update();
    }
  }

  /// 构建带滚动定位锚点的原生广告位。
  Widget? _build_native_ad_slot() {
    if (!_should_show_native_ad) return null;

    final int generation = _logic_generation;
    final AdConfig? ad_config = _native_ad_config;
    return KeyedSubtree(
      key: _native_ad_slot_key,
      child: InlineNativeAdBanner(
        ad_unit_id: ad_config?.adsId ?? '',
        uuid: ad_config?.uuid ?? '',
        on_unlock: _on_unlock_story_tap,
        is_unlocking: _is_rewarded_ad_loading,
        attach_ad: _can_attach_native_ad,
        reserve_space: _is_native_ad_slot_reserved,
        show_continue_hint: false,
        on_load_status_changed: (NativeAdLoadStatus status) {
          _on_native_ad_load_status_changed(status, generation);
        },
        on_layout_height_changed: (_) {
          if (mounted && generation == _logic_generation) {
            _reading_progress_max_extent = null;
          }
        },
        on_ad_impression: () {
          if (ad_config == null || generation != _logic_generation) return;
          unawaited(
            AdImpressionReporter.report(
              ad_config: ad_config,
              placement: AdPlacement.short_story_native,
              source_id: _logic.story_id,
            ),
          );
        },
      ),
    );
  }

  /// 处理滚动事件。
  ///
  /// - 更新阅读进度
  /// - 检测自动阅读期间的手动滑动
  /// - 检测上下篇加载触发
  void _on_scroll() {
    _schedule_native_ad_visibility_update();

    // 自动阅读期间，如果滚动不是由 Ticker 触发的，说明用户手动滑动，退出自动阅读。
    if (_logic.is_auto_reading.value && !_is_auto_read_ticking) {
      _stop_auto_read();
    }

    if (!_is_progress_scrolling && !_is_restoring_position) {
      _logic.on_scroll(_scroll_controller.offset);
    }

    // 更新阅读进度。
    if (_scroll_controller.hasClients) {
      final double max_scroll_extent =
          _reading_progress_max_extent ??
          _scroll_controller.position.maxScrollExtent;
      _logic.update_reading_progress(
        _scroll_controller.offset,
        max_scroll_extent,
        max_progress: _visible_story_progress_limit,
      );
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
    _stop_auto_read();
    _logic.toggle_bars_visibility();
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

  /// 处理返回按钮点击。
  void _on_back() {
    AppRouter.pop();
  }

  /// 处理分享按钮点击。
  ///
  /// 弹出分享弹窗，传递当前小说的基本信息。
  void _on_share() {
    showShareSheet(
      context: context,
      novel_id: _logic.story_id,
      novel_title: _logic.title,
      novel_cover_url: _logic.story_data.value?.cover_url ?? '',
      novel_intro: _logic.story_data.value?.introduction ?? '',
      is_dark: device_info.dark.value,
    );
  }

  /// 处理评论输入框点击。
  ///
  /// 弹窗关闭后若有新增评论，同步更新底部评论栏的数量。
  Future<void> _on_comment_tap({int scroll_to_comment_id = 0}) async {
    _stop_auto_read();
    final ShortStoryReadLogic comment_logic = _logic;
    final int? new_count = await showCommentSheet(
      context: context,
      novel_id: comment_logic.story_id,
      on_close: () => Navigator.pop(context),
      scroll_to_comment_id: scroll_to_comment_id,
    );
    if (new_count != null && mounted) {
      comment_logic.update_comment_count(new_count);
    }
  }

  /// 处理收藏按钮点击（带登录检查）。
  ///
  /// 未登录时弹出登录提示弹窗，已登录时调用收藏接口。
  Future<void> _on_favorite_tap() async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;
    final ShortStoryReadLogic action_logic = _logic;
    final bool? is_favorited = await action_logic.toggle_favorite();
    if (!mounted || is_favorited == null) return;
    showBottomTip(
      easy.tr(
        is_favorited ? 'favorite.add_success' : 'favorite.remove_success',
      ),
    );
  }

  /// 处理底部栏点赞按钮点击（带登录检查）。
  ///
  /// 未登录时弹出登录提示弹窗，已登录时调用点赞接口。
  Future<void> _on_like_tap() async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;
    final ShortStoryReadLogic action_logic = _logic;
    await action_logic.toggle_like();
  }

  /// 处理目录弹窗中卡片点赞（乐观更新）。
  ///
  /// 立即切换本地状态，然后静默发起请求。
  /// 请求失败时回退状态，不显示任何提示。
  void _on_catalog_like_tap(int story_id) async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;

    final ShortStoryReadLogic action_logic = _logic;
    final int catalog_index = action_logic.catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == story_id,
    );
    if (catalog_index < 0) return;

    // 记录乐观更新前的状态，用于失败时回退。
    final bool previous_catalog_status =
        action_logic.catalog_list[catalog_index].is_liked;
    final bool optimistic_status = !previous_catalog_status;

    // 乐观更新：立即切换目录列表状态。
    action_logic.sync_like_to_catalog(
      story_id,
      optimistic_status,
      optimistic_status ? 1 : -1,
    );

    // 如果点赞的是当前阅读的小说，同步乐观更新正文页面数据。
    bool previous_detail_status = false;
    int previous_detail_count = 0;
    final bool is_current_story =
        story_id == action_logic.story_id &&
        action_logic.story_data.value != null;
    if (is_current_story) {
      previous_detail_status = action_logic.story_data.value!.is_liked;
      previous_detail_count = action_logic.story_data.value!.like_count;
      final int next_detail_count = optimistic_status
          ? previous_detail_count + 1
          : (previous_detail_count > 0 ? previous_detail_count - 1 : 0);
      action_logic.story_data.value = action_logic.story_data.value!.copyWith(
        is_liked: optimistic_status,
        like_count: next_detail_count < 0 ? 0 : next_detail_count,
      );
      action_logic.sync_current_story_cache();
    }

    // 回退用的 delta（撤销乐观更新的增量）。
    final int revert_delta = optimistic_status ? -1 : 1;

    // 静默发起请求。
    try {
      final ResultsType<Map<String, dynamic>> results =
          await postRequest<Map<String, dynamic>>(
            path: 'novel_like/click',
            parameter: <String, dynamic>{'novel_id': story_id},
            fromJson: (Map<String, dynamic> json) => json,
          );

      if (!results.status || results.content == null) {
        // 请求失败，回退目录列表状态。
        action_logic.sync_like_to_catalog(
          story_id,
          previous_catalog_status,
          revert_delta,
        );
        // 回退正文页面数据。
        if (is_current_story) {
          action_logic.story_data.value = action_logic.story_data.value!
              .copyWith(
                is_liked: previous_detail_status,
                like_count: previous_detail_count,
              );
          action_logic.sync_current_story_cache();
        }
        return;
      }

      // 以服务端状态为准，修正乐观更新。
      final dynamic server_like = results.content!['like'];
      final bool server_status = server_like == true || server_like == 1;
      if (server_status != optimistic_status) {
        action_logic.sync_like_to_catalog(
          story_id,
          server_status,
          revert_delta,
        );
        if (is_current_story) {
          action_logic.story_data.value = action_logic.story_data.value!
              .copyWith(
                is_liked: server_status,
                like_count: previous_detail_count,
              );
          action_logic.sync_current_story_cache();
        }
      }
    } catch (_) {
      // 异常时回退目录列表状态。
      action_logic.sync_like_to_catalog(
        story_id,
        previous_catalog_status,
        revert_delta,
      );
      // 回退正文页面数据。
      if (is_current_story) {
        action_logic.story_data.value = action_logic.story_data.value!.copyWith(
          is_liked: previous_detail_status,
          like_count: previous_detail_count,
        );
        action_logic.sync_current_story_cache();
      }
    }
  }

  /// 处理目录按钮点击。
  ///
  /// 从底部弹出目录弹窗，使用预加载的目录数据（小说详情加载后立即请求）。
  /// 点击某一项时跳转到对应小说的阅读页面。
  void _on_catalog_tap() {
    _stop_auto_read();
    final ShortStoryReadLogic sheet_logic = _logic;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (BuildContext sheet_context) {
        return CatalogSheet(
          current_story_id: sheet_logic.story_id,
          catalog_list: sheet_logic.catalog_list,
          is_catalog_loading: sheet_logic.is_catalog_loading,
          is_catalog_error: sheet_logic.is_catalog_error,
          reading_progress: sheet_logic.reading_progress.value,
          on_item_tap: (int story_id) {
            Navigator.of(sheet_context).pop();
            if (story_id == sheet_logic.story_id) return;
            _switch_to_story(story_id);
          },
          on_like_tap: _on_catalog_like_tap,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_reload: sheet_logic.reload_catalog,
        );
      },
    );
  }

  /// 处理设置按钮点击。
  ///
  /// 从底部弹出阅读设置弹窗。
  Future<void> _on_setting_tap() async {
    bool should_start_auto_read = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (BuildContext sheet_context) {
        return ReadingSettingsSheet(
          logic: _logic,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_decrease_font_size: () {
            _change_body_font_size(_logic.decrease_font_size);
          },
          on_increase_font_size: () {
            _change_body_font_size(_logic.increase_font_size);
          },
          on_auto_read: () {
            should_start_auto_read = true;
            Navigator.of(sheet_context).pop();
          },
        );
      },
    );
    if (!mounted || !should_start_auto_read) return;
    _start_auto_read();
  }

  /// 观看激励视频广告并解锁当前短篇的全部正文。
  Future<void> _on_unlock_story_tap() async {
    if (_is_rewarded_ad_loading || _logic.is_story_unlocked.value) return;

    if (!AdDisplayPolicy.can_show_ads()) {
      _logic.sync_ad_access_policy();
      if (mounted) setState(_reset_native_ad_state);
      if (!AdDisplayPolicy.should_bypass_ads()) {
        showBottomTip(easy.tr('short_story_read.ad_not_available'));
      }
      return;
    }

    _stop_auto_read();
    final ShortStoryReadLogic action_logic = _logic;
    final int action_generation = _logic_generation;

    setState(() => _is_rewarded_ad_loading = true);
    try {
      // 从后端获取广告配置。
      final adConfigResult = await postRequest<AdConfig>(
        path: 'ads/short_story_read',
        parameter: <String, dynamic>{'source_id': _logic.story_id},
        showTips: false,
        fromJson: (json) => AdConfig.fromJson(json),
      );
      if (!_is_current_logic(action_logic, action_generation)) return;

      // 后端广告配置请求期间开关可能被远程更新，调用 SDK 前再次校验。
      if (!AdDisplayPolicy.can_show_ads()) {
        action_logic.sync_ad_access_policy();
        if (mounted) setState(_reset_native_ad_state);
        return;
      }

      if (!adConfigResult.status || adConfigResult.content == null) {
        showBottomTip(easy.tr('short_story_read.ad_not_available'));
        return;
      }

      final AdConfig adConfig = adConfigResult.content!;
      if (adConfig.advertisers != AdTypeConfig.google_advertiser ||
          adConfig.adsId.isEmpty) {
        showBottomTip(easy.tr('short_story_read.ad_not_available'));
        return;
      }

      final GoogleRewardedAdResult result = await GoogleRewardedAdUtil.instance
          .show_rewarded_ad(
            adUnitId: adConfig.adsId,
            custom_data: adConfig.uuid,
            can_show: () => _is_current_logic(action_logic, action_generation),
          );
      if (!_is_current_logic(action_logic, action_generation)) return;

      switch (result) {
        case GoogleRewardedAdResult.disabled:
          action_logic.sync_ad_access_policy();
          _reset_native_ad_state();
          if (!AdDisplayPolicy.should_bypass_ads()) {
            showBottomTip(easy.tr('short_story_read.ad_not_available'));
          }
          break;
        case GoogleRewardedAdResult.rewarded:
          // 广告播放完成，直接解锁全文（后台异步验证，不阻塞用户）。
          unawaited(
            postRequest<AdVerifyResult>(
              path: 'novel_ads/search_results',
              showTips: false,
              parameter: {'uuid': adConfig.uuid},
              fromJson: (json) => AdVerifyResult.fromJson(json),
            ),
          );
          action_logic.unlock_current_story();
          _reset_native_ad_state();
          _has_user_engaged = true;
          _reading_progress_max_extent = null;
          _next_story_overlay_opacity = 0;
          setState(() {});
          await WidgetsBinding.instance.endOfFrame;
          await WidgetsBinding.instance.endOfFrame;
          if (!_is_current_logic(action_logic, action_generation) ||
              !_scroll_controller.hasClients) {
            return;
          }
          final double full_extent = _calculate_current_story_extent();
          _reading_progress_max_extent = full_extent;
          action_logic.update_reading_progress(
            _scroll_controller.offset,
            full_extent,
          );
          showBottomTip(easy.tr('short_story_read.content_unlocked'));
          break;
        case GoogleRewardedAdResult.dismissed:
          showBottomTip(easy.tr('short_story_read.ad_not_completed'));
          break;
        case GoogleRewardedAdResult.load_failed:
          showBottomTip(easy.tr('short_story_read.ad_load_failed'));
          break;
        case GoogleRewardedAdResult.consent_unavailable:
          showBottomTip(easy.tr('short_story_read.ad_consent_unavailable'));
          break;
        case GoogleRewardedAdResult.show_failed:
          showBottomTip(easy.tr('short_story_read.ad_show_failed'));
          break;
        case GoogleRewardedAdResult.unsupported:
          showBottomTip(easy.tr('short_story_read.ad_unsupported'));
          break;
        case GoogleRewardedAdResult.busy:
          showBottomTip(easy.tr('short_story_read.ad_in_progress'));
          break;
        case GoogleRewardedAdResult.cancelled:
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _is_rewarded_ad_loading = false);
      }
    }
  }

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

  /// 开始自动阅读。
  ///
  /// 关闭弹窗后隐藏导航栏和底部栏，正文内容缓慢滚动到最底部。
  /// 速度由 [_logic.auto_read_speed] 控制（0.0 最慢，1.0 最快）。
  void _start_auto_read() {
    if (_logic.is_auto_reading.value) return;

    _has_user_engaged = true;
    _logic.is_auto_reading.value = true;

    // 隐藏导航栏和评论栏。
    _logic.is_appbar_visible.value = false;
    _logic.is_bottom_bar_visible.value = false;

    _begin_auto_read_ticker();
  }

  /// 启动自动阅读 Ticker（每帧根据当前速度滚动）。
  void _begin_auto_read_ticker() {
    if (!mounted || !_logic.is_auto_reading.value) return;

    _auto_read_last_tick = null;

    _auto_read_ticker?.dispose();
    _auto_read_ticker = createTicker((Duration elapsed) {
      if (!_scroll_controller.hasClients || !_logic.is_auto_reading.value) {
        _auto_read_ticker?.stop();
        return;
      }

      // 计算距上一帧的时间差（秒）。
      final double delta_seconds;
      if (_auto_read_last_tick == null) {
        delta_seconds = 0;
      } else {
        delta_seconds =
            (elapsed - _auto_read_last_tick!).inMicroseconds / 1000000.0;
      }
      _auto_read_last_tick = elapsed;

      // 速度映射：0.0 → 20px/s，1.0 → 300px/s。
      final double speed = _logic.auto_read_speed.value;
      final double pixels_per_second = 20 + speed * 280;

      final double current = _scroll_controller.offset;
      final double max_extent =
          _reading_progress_max_extent ?? _calculate_current_story_extent();
      final double next = current + pixels_per_second * delta_seconds;

      _is_auto_read_ticking = true;
      if (next >= max_extent) {
        _scroll_controller.jumpTo(max_extent);
        _logic.is_auto_reading.value = false;
        _logic.is_appbar_visible.value = true;
        _logic.is_bottom_bar_visible.value = true;
        _auto_read_ticker?.stop();
      } else {
        _scroll_controller.jumpTo(next);
      }
      _is_auto_read_ticking = false;
    });

    _auto_read_ticker?.start();
  }

  /// 显示自动阅读设置弹窗。
  Future<void> _on_auto_read_settings_tap() async {
    final ShortStoryReadLogic sheet_logic = _logic;
    final bool should_resume = sheet_logic.is_auto_reading.value;
    _auto_read_ticker?.stop();
    _auto_read_last_tick = null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      builder: (BuildContext sheet_context) {
        return AutoReadSettingsSheet(
          logic: _logic,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_exit: () {
            Navigator.of(sheet_context).pop();
            _stop_auto_read();
          },
        );
      },
    );
    if (!mounted ||
        !should_resume ||
        !identical(_logic, sheet_logic) ||
        !sheet_logic.is_auto_reading.value) {
      return;
    }
    _begin_auto_read_ticker();
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
    _stop_auto_read();
    _is_slide_up = slide_up;
    _is_previous_pull_rebounding = false;
    _is_previous_pull_dragging = false;
    _is_next_pull_rebounding = false;
    _is_next_pull_dragging = false;

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
      unawaited(_save_progress_snapshot(previous_logic));
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
      _previous_pull_raw_offset = 0;
      _previous_pull_offset = 0;
      _next_pull_raw_offset = 0;
      _next_pull_offset = 0;
      _next_story_overlay_opacity = 0;
      _reading_progress_max_extent = null;
      _is_initialization_complete = false;
      _has_user_engaged = false;
      _is_rewarded_ad_loading = false;
      _ad_probability_generation = null;
      _reset_native_ad_state();
      _is_video_ad_gate_required = true;
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
        _reading_progress_max_extent ??
        _scroll_controller.position.maxScrollExtent;
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
        _is_previous_pull_rebounding ||
        _is_next_pull_rebounding)
      return false;
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
        _is_previous_pull_rebounding ||
        _is_next_pull_rebounding) {
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

  /// 把真实手指拖拽距离转换成视觉位移。
  ///
  /// 前半段基本跟手，超过触发阈值后增加阻尼，避免页面被拉得过远。
  double _compute_previous_pull_visual_offset(double raw_offset) {
    if (raw_offset <= 0) return 0;
    if (raw_offset <= _previous_pull_trigger_distance) {
      return raw_offset;
    }

    final double extra = raw_offset - _previous_pull_trigger_distance;
    final double resisted_extra = extra * 0.38;
    return (_previous_pull_trigger_distance + resisted_extra).clamp(
      0.0,
      _previous_pull_max_distance,
    );
  }

  /// 把底部真实上拉距离转换成视觉位移。
  double _compute_next_pull_visual_offset(double raw_offset) {
    if (raw_offset <= 0) return 0;
    if (raw_offset <= _next_pull_trigger_distance) {
      return raw_offset;
    }

    final double viewport_height = MediaQuery.sizeOf(context).height;
    final double max_visual_offset =
        (viewport_height * _next_pull_max_viewport_ratio).clamp(
          _next_pull_trigger_distance,
          viewport_height - 24.0,
        );

    final double extra = raw_offset - _next_pull_trigger_distance;

    // 超过触发距离之后仍然保留一点阻尼，但不能阻尼过重；
    // 否则用户继续上拉时，下一篇正文看起来还是被固定裁剪在几行。
    final double resisted_extra = extra * 0.82;

    return (_next_pull_trigger_distance + resisted_extra).clamp(
      0.0,
      max_visual_offset,
    );
  }

  /// 指针移动：在顶部向下拖拽切上一篇，在底部向上拖拽切下一篇。
  void _on_reader_pointer_move(PointerMoveEvent event) {
    final double dy = event.delta.dy;
    if (dy != 0) {
      _has_user_engaged = true;
    }

    if (_is_previous_pull_dragging || _previous_pull_offset > 0) {
      _handle_previous_pull_move(dy);
      return;
    }

    if (_is_next_pull_dragging || _next_pull_offset > 0) {
      _handle_next_pull_move(dy);
      return;
    }

    if (_can_pull_previous_story && _is_reader_at_top && dy > 0) {
      _handle_previous_pull_move(dy);
      return;
    }

    if (_can_pull_next_story && _is_reader_at_bottom && dy < 0) {
      _handle_next_pull_move(dy);
    }
  }

  /// 顶部下拉上一篇的拖拽处理。
  void _handle_previous_pull_move(double dy) {
    if (!_can_pull_previous_story && _previous_pull_offset <= 0) return;

    _stop_auto_read();
    _previous_pull_animation_controller.stop();
    _is_previous_pull_rebounding = false;

    final double next_raw = (_previous_pull_raw_offset + dy).clamp(
      0.0,
      _previous_pull_max_distance * 2.2,
    );
    final double next_visual = _compute_previous_pull_visual_offset(next_raw);

    setState(() {
      // 一旦进入顶部下拉手势，在本次按压释放前都保持手势态。
      // 否则用户拉出提示后又推回 0，再继续下拉时容易被普通滚动接管。
      _is_previous_pull_dragging = true;
      _previous_pull_raw_offset = next_raw;
      _previous_pull_offset = next_visual;
    });
  }

  /// 底部上拉下一篇的拖拽处理。
  void _handle_next_pull_move(double dy) {
    if (!_can_pull_next_story && _next_pull_offset <= 0) return;

    _stop_auto_read();
    _next_pull_animation_controller.stop();
    _is_next_pull_rebounding = false;

    // dy < 0 表示手指向上拖动，所以用 -dy 转为正数距离。
    final double viewport_height = MediaQuery.sizeOf(context).height;
    final double next_raw = (_next_pull_raw_offset - dy).clamp(
      0.0,
      viewport_height * 1.35,
    );
    final double next_visual = _compute_next_pull_visual_offset(next_raw);

    setState(() {
      // 一旦进入底部上拉手势，在本次按压释放前都保持手势态。
      // 这样用户上拉看到提示后推回去，再继续上拉，仍然可以重新出现提示并触发下一篇。
      _is_next_pull_dragging = true;
      _next_pull_raw_offset = next_raw;
      _next_pull_offset = next_visual;
    });
    _schedule_next_story_overlay_update();
    _sync_next_preview_scroll_position();
  }

  /// 底部上拉时，同步滚动位置到新的内容底部。
  ///
  /// 下一篇正文预览的高度会随着 `_next_pull_offset` 增加。
  /// 如果只增高底部内容，但不调整 SingleChildScrollView 内部 offset，
  /// 新增出来的正文会长在屏幕下方，用户看到的仍然只有最开始那几行。
  ///
  /// 放到 post frame 是为了等本轮 setState 完成布局，拿到最新 maxScrollExtent。
  void _sync_next_preview_scroll_position() {
    if (!_is_next_pull_dragging || _next_pull_offset <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll_controller.hasClients) return;
      if (!_is_next_pull_dragging || _next_pull_offset <= 0) return;

      final ScrollPosition position = _scroll_controller.position;
      final double max_extent = position.maxScrollExtent;

      if ((max_extent - position.pixels).abs() > 0.5) {
        _scroll_controller.jumpTo(max_extent);
      }

      _schedule_next_story_overlay_update();
    });
  }

  /// 指针释放/取消：距离足够切换，否则回弹。
  void _on_reader_pointer_end(PointerEvent event) {
    if (_is_previous_pull_dragging || _previous_pull_offset > 0) {
      _is_previous_pull_dragging = false;
      _finish_previous_pull_gesture();
      return;
    }

    if (_is_next_pull_dragging || _next_pull_offset > 0) {
      _is_next_pull_dragging = false;
      _finish_next_pull_gesture();
    }
  }

  /// 顶部下拉手势结束：距离足够则切换上一篇，不够则回弹。
  void _finish_previous_pull_gesture() {
    if (_previous_pull_offset >= _previous_pull_trigger_distance) {
      final int? previous_id = _logic.previous_story_id;
      if (previous_id == null) {
        _animate_previous_pull_back();
        return;
      }
      _switch_to_story(previous_id, slide_up: false);
      return;
    }

    _animate_previous_pull_back();
  }

  /// 底部上拉手势结束：距离足够则切换下一篇，不够则回弹。
  void _finish_next_pull_gesture() {
    if (_next_pull_offset >= _next_pull_trigger_distance) {
      final int? next_id = _logic.next_story_id;
      if (next_id == null) {
        _animate_next_pull_back();
        return;
      }
      _switch_to_story(next_id, slide_up: true);
      return;
    }

    _animate_next_pull_back();
  }

  /// 轻微下拉时回弹到当前小说顶部。
  void _animate_previous_pull_back() {
    if (_previous_pull_offset <= 0 || _is_previous_pull_rebounding) return;

    _previous_pull_animation_controller.stop();
    _previous_pull_animation_controller.reset();
    _is_previous_pull_rebounding = true;

    final double begin_visual = _previous_pull_offset;
    final Animation<double> animation =
        Tween<double>(begin: begin_visual, end: 0).animate(
          CurvedAnimation(
            parent: _previous_pull_animation_controller,
            curve: Curves.easeOutCubic,
          ),
        );

    void listener() {
      if (!mounted) return;
      setState(() {
        _previous_pull_offset = animation.value;
        _previous_pull_raw_offset = animation.value;
      });
    }

    void status_listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeListener(listener);
      _previous_pull_animation_controller.removeStatusListener(status_listener);
      if (!mounted) return;
      setState(() {
        _previous_pull_raw_offset = 0;
        _previous_pull_offset = 0;
        _is_previous_pull_dragging = false;
        _is_previous_pull_rebounding = false;
      });
    }

    animation.addListener(listener);
    _previous_pull_animation_controller.addStatusListener(status_listener);
    _previous_pull_animation_controller.forward();
  }

  /// 轻微上拉时回弹到当前小说底部。
  void _animate_next_pull_back() {
    if (_next_pull_offset <= 0 || _is_next_pull_rebounding) return;

    _next_pull_animation_controller.stop();
    _next_pull_animation_controller.reset();
    _is_next_pull_rebounding = true;

    final double begin_visual = _next_pull_offset;
    final Animation<double> animation =
        Tween<double>(begin: begin_visual, end: 0).animate(
          CurvedAnimation(
            parent: _next_pull_animation_controller,
            curve: Curves.easeOutCubic,
          ),
        );

    void listener() {
      if (!mounted) return;
      setState(() {
        _next_pull_offset = animation.value;
        _next_pull_raw_offset = animation.value;
      });
      _schedule_next_story_overlay_update();
    }

    void status_listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeListener(listener);
      _next_pull_animation_controller.removeStatusListener(status_listener);
      if (!mounted) return;
      setState(() {
        _next_pull_raw_offset = 0;
        _next_pull_offset = 0;
        _is_next_pull_dragging = false;
        _is_next_pull_rebounding = false;
      });
      _schedule_next_story_overlay_update();
    }

    animation.addListener(listener);
    _next_pull_animation_controller.addStatusListener(status_listener);
    _next_pull_animation_controller.forward();
  }

  /// 构建顶部下拉查看上一篇提示。
  Widget _buildPreviousPullHeader({
    required bool is_dark,
    required double status_bar_height,
  }) {
    return PreviousPullHeader(
      is_dark: is_dark,
      status_bar_height: status_bar_height,
      pull_offset: _previous_pull_offset,
      trigger_distance: _previous_pull_trigger_distance,
      previous_title: _logic.previous_story_item?.title ?? '',
      localized_texts: <String, String>{
        'pull_down_view': _readerText('pull_down_view'),
        'release_view': _readerText('release_view'),
      },
    );
  }

  /// 构建贯穿屏幕底部的下一篇渐变遮罩和固定提示。
  Widget _buildNextStoryBottomOverlay({
    required bool is_dark,
    required Color bg_color,
    required double bottom_padding,
    required double overlay_opacity,
    required double next_pull_hint_opacity,
    required bool next_pull_ready,
  }) {
    final Color text_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: bottom_padding + 132,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: overlay_opacity,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  bg_color,
                  bg_color.withValues(alpha: 0.94),
                  bg_color.withValues(alpha: 0.62),
                  bg_color.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.42, 0.72, 1.0],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottom_padding + 14),
                child: AnimatedOpacity(
                  opacity: next_pull_hint_opacity,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: is_dark
                          ? Colors.black.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: is_dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _readerText('view_next'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                            color: text_color,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: next_pull_ready ? 0.25 : -0.25,
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          child: SvgPicture.asset(
                            'assets/svg/right.svg',
                            width: 13,
                            height: 13,
                            colorFilter: ColorFilter.mode(
                              text_color,
                              BlendMode.srcIn,
                            ),
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
      ),
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
  /// 包含背景装饰、可滚动的正文内容、完整导航栏和底部评论栏。
  Widget _buildContent({
    required bool is_dark,
    required double status_bar_height,
  }) {
    /// 页面背景色。
    final Color bg_color = is_dark
        ? ShortStoryReadStyle.bg_dark_color
        : ShortStoryReadStyle.bg_light_color;

    /// 标题文字颜色。
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    /// 当前语种是否为 CJK。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );

    /// 标题字号（CJK 语系字号稍大）。
    final double title_font_size = is_cjk ? 22.0 : 20.0;

    /// 标签列表。
    final List<String> tags = _logic.category_list;

    /// 底部安全区域高度。
    final double bottom_padding = MediaQuery.viewPaddingOf(context).bottom;

    /// 是否需要在正文底部展示下一篇预览。
    final bool has_next_preview = _logic.next_story_item != null;

    /// 有下一篇预览时，底部不要再保留过大的普通正文留白。
    ///
    /// 这样用户读完正文后，能直接看到下一篇的标题和分类，
    /// 简介只在可视区域底部露出一点点；继续上拉时再逐步展开。
    final double scroll_bottom_padding =
        (has_next_preview ? 18.0 : ShortStoryReadStyle.page_bottom_padding) +
        bottom_padding;

    final double next_pull_hint_opacity = ((_next_pull_offset - 22.0) / 96.0)
        .clamp(0.0, 1.0);
    final bool next_pull_ready =
        _next_pull_offset >= _next_pull_trigger_distance;

    /// 下一篇的预览文字。
    ///
    /// 优先使用目录数据中已有的简介，避免正文预加载未完成或失败时
    /// 只显示下一篇标题而预览区域为空。
    final String next_story_preview_content =
        resolve_next_story_preview_content(
          description: _logic.next_story_item?.description ?? '',
          preloaded_content: _logic.next_story_content.value,
        );

    // 下一篇简介预览不能用固定高度。
    // 默认稳定展示数行简介；一旦用户上拉，它的可见高度就按真实上拉距离增长。
    final double next_preview_line_height = is_cjk
        ? ShortStoryReadStyle.body_height_cjk
        : ShortStoryReadStyle.body_height_alphabetic;
    final int next_preview_visible_line_count = is_cjk
        ? ShortStoryReadStyle.next_preview_visible_line_count_cjk
        : ShortStoryReadStyle.next_preview_visible_line_count_alphabetic;
    final double next_preview_body_height =
        (_logic.body_font_size.value *
            next_preview_line_height *
            next_preview_visible_line_count) +
        bottom_padding +
        _next_pull_offset;
    final int next_preview_max_lines = math.max(
      next_preview_visible_line_count,
      (next_preview_body_height /
                  (_logic.body_font_size.value * next_preview_line_height))
              .ceil() +
          ShortStoryReadStyle.next_preview_overflow_buffer_line_count,
    );

    final bool show_next_bottom_overlay =
        has_next_preview && _next_story_overlay_opacity > 0.01;

    /// 原生广告素材先在后台加载，进入可视区域后再挂载平台视图。
    final Widget? native_ad_slot = _build_native_ad_slot();
    if (native_ad_slot != null) {
      _schedule_native_ad_visibility_update();
    }

    if (has_next_preview) {
      _schedule_next_story_overlay_update();
    }

    return Stack(
      children: <Widget>[
        /// 背景装饰（底层）。
        StarfieldDecoration(is_dark: is_dark),

        /// 顶部下拉查看上一篇提示（露出在当前页面背后）。
        _buildPreviousPullHeader(
          is_dark: is_dark,
          status_bar_height: status_bar_height,
        ),

        /// 正文内容（可滚动，点击切换导航栏显隐，翻页时滑动消失）。
        AnimatedBuilder(
          animation: _page_transition_controller,
          builder: (BuildContext context, Widget? child) {
            /// 翻页动画进度（0.0 = 原位，1.0 = 完全滑出屏幕）。
            final double progress = _page_transition_controller.value;

            /// 根据方向决定偏移量（向上或向下滑出屏幕）。
            final double transition_offset_y = _is_slide_up
                ? -progress * MediaQuery.sizeOf(context).height
                : progress * MediaQuery.sizeOf(context).height;
            // 注意：底部上拉时不能再把整个 SingleChildScrollView 视口整体上移。
            //
            // 旧写法是：transition_offset_y + _previous_pull_offset - _next_pull_offset。
            // 这会移动“已经被视口裁剪后的画面”，而不是移动滚动内容本身；
            // 结果就是下一篇正文预览看起来永远只露出最初那几行。
            //
            // 底部下一篇的露出改由 `_sync_next_preview_scroll_position()`
            // 在预览高度变化后把内部滚动位置同步到新的 maxScrollExtent，
            // 这样真正移动的是滚动内容，下一篇正文能按上拉距离持续露出。
            final double offset_y = transition_offset_y + _previous_pull_offset;

            return Transform.translate(
              offset: Offset(0, offset_y),
              child: child,
            );
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: _on_reader_pointer_move,
            onPointerUp: _on_reader_pointer_end,
            onPointerCancel: _on_reader_pointer_end,
            child: GestureDetector(
              onTap: _on_content_tap,
              behavior: HitTestBehavior.translucent,
              child: SingleChildScrollView(
                controller: _scroll_controller,
                physics: _reader_scroll_physics,
                padding: EdgeInsets.fromLTRB(
                  ShortStoryReadStyle.page_horizontal_padding,
                  status_bar_height + ShortStoryReadStyle.appbar_height + 16,
                  ShortStoryReadStyle.page_horizontal_padding,
                  scroll_bottom_padding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// 标题（有封面时左侧显示封面缩略图）。
                    if (_logic.story_data.value?.cover_url.isNotEmpty == true)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          NovelCover(
                            image_url: _logic.story_data.value!.cover_url,
                            width: 48,
                            height: 64,
                            border_radius: 6,
                            is_dark: is_dark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _logic.title,
                              style: TextStyle(
                                fontSize: title_font_size,
                                fontWeight: FontConfig.adjustedWeight(
                                  FontWeight.w500,
                                ),
                                color: title_color,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _logic.title,
                        style: TextStyle(
                          fontSize: title_font_size,
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w500,
                          ),
                          color: title_color,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 12),

                    /// 标签列表。
                    if (tags.isNotEmpty) ...[
                      TagList(
                        tags: tags,
                        is_dark: is_dark,
                        story_id: _logic.story_id,
                        is_cjk: is_cjk,
                      ),
                      const SizedBox(height: 24),
                    ],

                    /// 正文内容。
                    StoryUnlockGate(
                      content: _logic.content.value,
                      is_dark: is_dark,
                      is_loading: _logic.is_content_loading.value,
                      is_unlocked:
                          _logic.is_story_unlocked.value ||
                          !_is_video_ad_gate_required,
                      is_unlocking: _is_rewarded_ad_loading,
                      font_size: _logic.body_font_size.value,
                      on_unlock: _on_unlock_story_tap,
                      native_ad_widget: native_ad_slot,
                    ),

                    /// 当前篇正文结束位置，用于准确计算进度和恢复位置。
                    SizedBox(key: _current_story_end_key, height: 0),

                    /// 下一篇小说预览（固定显示在正文下方）。
                    if (has_next_preview)
                      NextStoryPreview(
                        next_story: _logic.next_story_item!,
                        body_font_size: _logic.body_font_size.value,
                        is_dark: is_dark,
                        is_cjk: is_cjk,
                        title_font_size: title_font_size,
                        title_color: title_color,
                        body_color: is_dark
                            ? ShortStoryReadStyle.body_dark_color
                            : ShortStoryReadStyle.body_light_color,
                        secondary_color: is_dark
                            ? ShortStoryReadStyle.secondary_dark_color
                            : ShortStoryReadStyle.secondary_light_color,
                        preview_body_height: next_preview_body_height,
                        preview_max_lines: next_preview_max_lines,
                        preview_line_height: next_preview_line_height,
                        preview_content: next_story_preview_content,
                        title_key: _next_story_title_key,
                        reader_text: _readerText,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// 底部下一篇渐变遮罩。
        ///
        /// 放在 Stack 层级里，而不是正文安全区域内部，保证渐变可以贯穿到屏幕底部；
        /// 文案和箭头固定在安全区域内的底部。
        if (show_next_bottom_overlay)
          _buildNextStoryBottomOverlay(
            is_dark: is_dark,
            bg_color: bg_color,
            bottom_padding: bottom_padding,
            overlay_opacity: _next_story_overlay_opacity,
            next_pull_hint_opacity: next_pull_hint_opacity,
            next_pull_ready: next_pull_ready,
          ),

        /// 覆盖层（导航栏+评论栏+浮动按钮+渐变遮罩）。
        ReaderOverlayLayer(
          is_dark: is_dark,
          status_bar_height: status_bar_height,
          bottom_padding: bottom_padding,
          bg_color: bg_color,
          is_appbar_visible: _logic.is_appbar_visible.value,
          bottom_bar_slide_animation: _bottom_bar_slide_animation,
          floating_button_fade_animation: _floating_button_fade_animation,
          show_floating_button: _has_floating_button,
          show_progress_bar: !_logic.is_loading.value && !_logic.is_error.value,
          catalog_loaded:
              !_logic.is_catalog_loading.value &&
              _logic.catalog_list.isNotEmpty,
          is_favorited: _logic.is_favorited,
          is_favorite_loading: _logic.is_favorite_loading.value,
          comment_count: _logic.comment_count,
          like_count: _logic.like_count,
          is_liked: _logic.is_liked,
          is_like_loading: _logic.is_like_loading.value,
          reading_progress: _logic.reading_progress.value,
          has_previous: _logic.has_previous_story,
          has_next: _logic.has_next_story,
          is_bottom_bar_visible: _logic.is_bottom_bar_visible.value,
          is_auto_reading: _logic.is_auto_reading.value,
          on_back: _on_back,
          on_favorite_tap: _on_favorite_tap,
          on_share: _on_share,
          on_catalog_tap: _on_catalog_tap,
          on_comment_tap: _on_comment_tap,
          on_like_tap: _on_like_tap,
          on_setting_tap: _on_setting_tap,
          on_previous_tap: _on_previous_tap,
          on_next_tap: _on_next_tap,
          on_progress_changed: _on_progress_changed,
          on_progress_change_end: _on_progress_change_end,
          on_scroll_to_bottom: _showNextStory,
          on_auto_read_settings_tap: _on_auto_read_settings_tap,
        ),
      ],
    );
  }

  /// 构建骨架屏（加载状态）。
  ///
  /// 包含背景装饰、骨架屏内容和完整导航栏。
  Widget _buildSkeleton({
    required bool is_dark,
    required double status_bar_height,
  }) {
    return Stack(
      children: <Widget>[
        /// 背景装饰。
        StarfieldDecoration(is_dark: is_dark),

        /// 骨架屏内容（位于导航栏下方）。
        Padding(
          padding: EdgeInsets.only(
            top: status_bar_height + ShortStoryReadStyle.appbar_height,
          ),
          child: SkeletonScreen(is_dark: is_dark),
        ),

        /// 顶部导航栏（加载中右侧显示骨架屏）。
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FullAppbar(
            is_dark: is_dark,
            on_back: _on_back,
            on_favorite_tap: _on_favorite_tap,
            on_share: _on_share,
            is_favorited: _logic.is_favorited,
            status_bar_height: status_bar_height,
            is_loading: true,
          ),
        ),
      ],
    );
  }

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

        /// 无网络状态（居中显示图标、标题和描述，点击触发重试）。
        NoInternet(
          is_dark: is_dark,
          title: easy.tr('no_internet.title'),
          description: easy.tr('no_internet.description'),
          on_reload: _retry_current_story,
        ),

        /// 顶部导航栏。
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FullAppbar(
            is_dark: is_dark,
            on_back: _on_back,
            on_favorite_tap: _on_favorite_tap,
            on_share: _on_share,
            is_favorited: _logic.is_favorited,
            status_bar_height: status_bar_height,
          ),
        ),
      ],
    );
  }
}
