import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:app/api/ad_free.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/models/ad_verify_result.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/rewarded_ad_util.dart';
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
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/percentage_probability.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/share_sheet/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/pages/read/widgets/unlock_ad_free_popup/index.dart';
import 'package:app/pages/read/utils/calculate_ad_free_expire_time.dart';
import 'package:app/pages/read/utils/can_process_read_ads.dart';
import 'package:app/pages/read/widgets/rewarded_ad_loading_overlay/index.dart';

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

  /// 项目广告开关变更监听器。
  Worker? _ad_policy_worker;

  /// 页面首次数据与阅读进度初始化任务。
  late final Future<void> _initialization_future;

  /// 阅读进度展示通知器。
  ///
  /// 滚动过程中只刷新进度相关小组件，避免整页正文随每个像素重建。
  final ValueNotifier<double> _reading_progress_notifier =
      ValueNotifier<double>(0);

  /// 当前小说唯一的原生广告配置，所有命中概率的章节共同复用。
  AdConfig? _native_ad_config;

  /// 当前小说是否正在请求原生广告配置。
  bool _is_native_ad_config_loading = false;

  /// 当前小说是否已经请求过原生广告配置。
  ///
  /// 无论接口成功或失败，整个阅读页面生命周期内都只请求一次。
  bool _has_requested_native_ad_config = false;

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

  /// 已触发过解锁免广告弹窗判断的章节索引集合。
  ///
  /// 同一章节在重建、拼接和跳转时不会重复触发弹窗判断。
  final Set<int> _unlock_popup_evaluated_chapters = <int>{};

  /// 延迟展示的解锁免广告弹窗的目标时长（小时）。
  ///
  /// 当弹窗触发时如果"看视频免广告"提示文字正在屏幕内展示，
  /// 则延迟弹窗到用户停止滚动后再展示，避免弹窗与提示文字同时出现。
  int? _pending_unlock_duration_hours;

  /// 延迟弹窗的最小等待时间。
  ///
  /// 确保弹窗不在提示文字刚出现时就弹出，给用户足够阅读时间。
  Timer? _unlock_popup_defer_timer;

  /// 当前设备是否在免广告期内。
  ///
  /// 进入页面时通过接口查询，看视频广告后实时更新。
  /// 为 true 时跳过所有原生高级广告的展示。
  bool _is_ad_free = false;

  /// 首次设备免广告状态是否已经完成查询。
  ///
  /// 在返回前暂停原生广告和免时长弹窗逻辑，避免有效期内误展示。
  bool _is_ad_free_status_ready = false;

  /// 免广告到期时间。
  DateTime? _ad_free_expire_time;

  /// 免广告到期时间展示通知器。
  ///
  /// 每个章节底部的续时入口直接监听该值，不依赖整个章节列表重建。
  final ValueNotifier<DateTime?> _ad_free_expire_time_notifier =
      ValueNotifier<DateTime?>(null);

  /// 当前免广告时长的本地到期计时器。
  ///
  /// 用户长时间停留在阅读页时，到期后自动恢复广告展示，无需退出重进页面。
  Timer? _ad_free_expire_timer;

  /// 当前是否正在请求、加载或展示长篇阅读激励视频广告。
  bool _is_rewarded_ad_loading = false;

  /// 当前后台奖励校验任务的代次。
  ///
  /// 页面销毁或未来开始新的校验任务时递增，使旧任务不能覆盖新状态。
  int _ad_free_verification_generation = 0;

  /// Google SSV回调的静默校验间隔，总等待时间约90秒。
  ///
  /// 回调通常很快，但采用递增间隔可以兼容短暂网络延迟，同时避免频繁请求。
  static const List<Duration> _ad_free_verification_retry_delays = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
    Duration(seconds: 30),
  ];

  /// 常规校验窗口结束后的延迟复核时间。
  ///
  /// 本地奖励会先回退到服务端状态，但仍给Google异常延迟回调一次恢复机会。
  static const Duration _ad_free_late_verification_delay = Duration(minutes: 5);

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
    logic.on_chapter_loaded = _on_chapter_loaded;

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

    // 进入页面时先异步初始化设备免广告状态。
    unawaited(_initialize_ad_free_status());

    // 项目配置异步到达或更新时统一同步正文广告状态。
    _ad_policy_worker = ever(
      Get.find<ProjectConfigStore>().config_revision,
      (_) => _sync_ad_policy(),
    );
    _sync_ad_policy();

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

  /// 后台加载原生高级广告配置。
  ///
  /// 请求 ads/read_show_ads 接口获取长篇正文专用广告单元 ID。
  ///
  /// [source_id] 使用路由传入的长篇小说 ID。整个小说阅读页面生命周期内
  /// 只请求一次，命中概率的不同章节共同复用返回的广告配置。
  /// 加载失败不影响页面正常展示。
  Future<void> _load_native_ad_config() async {
    const String log_prefix = '[ReadNativeAdConfig]';
    if (!_can_process_read_ads) {
      logUtil(msg: '$log_prefix 免广告状态未就绪或仍在有效期，跳过加载');
      return;
    }
    if (!AdDisplayPolicy.can_show_ads()) {
      logUtil(msg: '$log_prefix can_show_ads=false，跳过加载广告配置', type: 'w');
      return;
    }
    if (_has_requested_native_ad_config) {
      logUtil(
        msg:
            '$log_prefix 已请求过广告配置, '
            'native_ad_config=${_native_ad_config != null}, '
            'adsId=${_native_ad_config?.adsId}',
      );
      return;
    }
    _has_requested_native_ad_config = true;
    _is_native_ad_config_loading = true;
    if (mounted) setState(() {});
    try {
      logUtil(msg: '$log_prefix 开始请求广告配置, source_id=${widget.story_id}');

      final ResultsType<AdConfig> result = await postRequest<AdConfig>(
        path: 'ads/read_show_ads',
        parameter: <String, dynamic>{'source_id': widget.story_id},
        showTips: false,
        fromJson: (json) => AdConfig.fromJson(json),
      );

      if (!mounted) return;

      logUtil(
        msg:
            '$log_prefix 接口响应: status=${result.status}, '
            'content=${result.content != null}',
      );

      if (!result.status || result.content == null) {
        logUtil(msg: '$log_prefix 接口返回失败或内容为空，跳过', type: 'w');
        return;
      }

      // 请求期间可能刚获得免广告时长，此时不再挂载原生广告。
      if (!_can_process_read_ads) {
        _has_requested_native_ad_config = false;
        logUtil(msg: '$log_prefix 请求返回时已在免广告期，丢弃本次配置');
        return;
      }

      final AdConfig ad_config = result.content!;

      logUtil(
        msg:
            '$log_prefix 广告配置详情: '
            'advertisers=${ad_config.advertisers}, '
            'adsId="${ad_config.adsId}", '
            'adsType=${ad_config.adsType}, '
            'uuid="${ad_config.uuid}", '
            'id=${ad_config.id}',
      );

      // advertisers=1 表示谷歌 AdMob，且 ads_id 必须有值。
      if (ad_config.advertisers != 1 || ad_config.adsId.isEmpty) {
        logUtil(
          msg:
              '$log_prefix 广告商不是谷歌或adsId为空，跳过: '
              'advertisers=${ad_config.advertisers} (期望1), '
              'adsId="${ad_config.adsId}" (期望非空)',
          type: 'w',
        );
        return;
      }

      logUtil(
        msg:
            '$log_prefix 广告配置加载成功, '
            'adsType=${ad_config.adsType}, '
            'adUnitId=${ad_config.adsId}',
      );

      _native_ad_config = ad_config;
    } catch (e, stack_trace) {
      logUtil(msg: '$log_prefix 广告配置加载异常: $e\n$stack_trace', type: 'e');
    } finally {
      _is_native_ad_config_loading = false;
      if (mounted) setState(() {});
    }
  }

  /// 在 AdMob 确认原生广告产生真实展示后记录一次长篇小说广告统计。
  Future<void> _record_native_ad_impression() async {
    const String log_prefix = '[ReadNativeAdRecord]';
    final AdConfig? ad_config = _native_ad_config;
    if (ad_config == null || ad_config.adsId.isEmpty) return;

    try {
      final ResultsType<void> result = await postRequest<void>(
        path: 'ads/read_record_count',
        parameter: <String, dynamic>{
          'ads_id': ad_config.adsId,
          'source_id': widget.story_id,
        },
        showTips: false,
      );
      if (!result.status) {
        logUtil(
          msg:
              '$log_prefix 展示统计失败, source_id=${widget.story_id}, '
              'adUnitId=${ad_config.adsId}, message=${result.message}',
          type: 'w',
        );
        return;
      }
      logUtil(
        msg:
            '$log_prefix 展示统计成功, source_id=${widget.story_id}, '
            'adUnitId=${ad_config.adsId}',
      );
    } catch (e, stack_trace) {
      logUtil(msg: '$log_prefix 展示统计异常: $e\n$stack_trace', type: 'e');
    }
  }

  /// 章节正文进入阅读窗口时完成该章唯一一次广告概率判断。
  ///
  /// 同时触发解锁免广告弹窗的概率判断（非第一章且非首次阅读章节）。
  /// 当设备处于免广告期内时，跳过所有广告相关逻辑。
  void _on_chapter_loaded(int chapter_index) {
    const String log_prefix = '[ReadNativeAd]';

    // 免广告状态未就绪或仍在有效期时，跳过所有广告和弹窗逻辑。
    if (!_can_process_read_ads) {
      logUtil(msg: '$log_prefix 当前禁止阅读广告，跳过章节 $chapter_index');
      return;
    }

    if (!AdDisplayPolicy.can_show_ads()) {
      final ProjectConfigStore? store = Get.isRegistered<ProjectConfigStore>()
          ? Get.find<ProjectConfigStore>()
          : null;
      logUtil(
        msg:
            '$log_prefix can_show_ads=false, '
            'config_loaded=${store?.is_config_loaded.value}, '
            'ads_switch=${store?.current.ads_switch}, '
            'is_ads_enabled=${store?.current.is_ads_enabled}',
        type: 'w',
      );
      return;
    }

    final ProjectConfigStore config_store = Get.find<ProjectConfigStore>();
    if (!config_store.is_config_loaded.value) {
      logUtil(msg: '$log_prefix config未加载完成，跳过章节 $chapter_index', type: 'w');
      return;
    }

    final bool should_show = logic.resolve_chapter_native_ad_decision(
      chapter_index: chapter_index,
      probability:
          config_store.current.ads_read_show_interstitial_ads_probability,
    );
    if (!should_show) {
      logUtil(
        msg:
            '$log_prefix 概率未命中, chapter=$chapter_index, '
            'probability=${config_store.current.ads_read_show_interstitial_ads_probability}',
      );
    } else {
      logUtil(
        msg:
            '$log_prefix 概率命中, chapter=$chapter_index, '
            'probability=${config_store.current.ads_read_show_interstitial_ads_probability}, '
            'native_ad_config=${_native_ad_config != null}, '
            'is_loading=$_is_native_ad_config_loading, '
            'has_requested=$_has_requested_native_ad_config',
      );
      if (mounted) setState(() {});
      unawaited(_load_native_ad_config());
    }

    // 触发解锁免广告弹窗概率判断。
    _maybe_show_unlock_popup(chapter_index, config_store);
  }

  /// 判断是否展示解锁免广告时长弹窗。
  ///
  /// 规则：
  /// - 第一章（index == 0）不触发，用户刚开始阅读时不做打扰。
  /// - 恢复进度自动跳转到的章节不触发，避免刚进入页面就弹窗。
  /// - 同一章节只触发一次判断，避免重复弹窗。
  /// - 按优先级依次判断：6小时 → 3小时 → 1小时，命中即展示，不继续判断。
  /// - 如果当前章节的"看视频免广告"提示文字可能在屏幕内，
  ///   则延迟弹窗到用户停止滚动后再展示，避免弹窗与提示文字同时出现。
  void _maybe_show_unlock_popup(
    int chapter_index,
    ProjectConfigStore config_store,
  ) {
    // 免广告状态未就绪或已在有效期时禁止弹窗。
    if (!_can_process_read_ads) return;

    // 第一章不触发，用户刚开始阅读时不做打扰。
    if (chapter_index <= 0) return;

    // 恢复进度跳转到的章节不触发，避免刚进入页面就弹窗。
    if (_is_restoring_progress) return;

    // 已有延迟弹窗待展示时跳过，避免多次触发。
    if (_pending_unlock_duration_hours != null) return;

    // 同一章节只判断一次，避免重复弹窗。
    if (!_unlock_popup_evaluated_chapters.add(chapter_index)) return;

    final int six_hour_probability =
        config_store.current.read_ads_unlock_six_hour;
    final int three_hour_probability =
        config_store.current.read_ads_unlock_three_hour;
    final int an_hour_probability =
        config_store.current.read_ads_unlock_an_hour;

    // 所有概率均为 0 时跳过，不做任何弹窗判断。
    if (six_hour_probability <= 0 &&
        three_hour_probability <= 0 &&
        an_hour_probability <= 0) {
      return;
    }

    // 按优先级依次判断：6小时 → 3小时 → 1小时，命中即停。
    int? hit_duration_hours;
    if (six_hour_probability > 0 &&
        PercentageProbability.is_hit(six_hour_probability)) {
      logUtil(
        msg:
            '[ReadUnlockPopup] 命中6小时免广告, chapter=$chapter_index, '
            'probability=$six_hour_probability',
      );
      hit_duration_hours = 6;
    } else if (three_hour_probability > 0 &&
        PercentageProbability.is_hit(three_hour_probability)) {
      logUtil(
        msg:
            '[ReadUnlockPopup] 命中3小时免广告, chapter=$chapter_index, '
            'probability=$three_hour_probability',
      );
      hit_duration_hours = 3;
    } else if (an_hour_probability > 0 &&
        PercentageProbability.is_hit(an_hour_probability)) {
      logUtil(
        msg:
            '[ReadUnlockPopup] 命中60分钟免广告, chapter=$chapter_index, '
            'probability=$an_hour_probability',
      );
      hit_duration_hours = 1;
    }

    if (hit_duration_hours == null) return;

    // 检查当前章节是否可能展示"看视频免广告"提示文字。
    // 如果提示文字可能在屏幕内，延迟弹窗到用户停止滚动后再展示，
    // 避免弹窗与提示文字同时出现影响阅读体验。
    final int video_ad_probability =
        config_store.current.ads_read_video_ad_probability;
    if (video_ad_probability > 0) {
      _pending_unlock_duration_hours = hit_duration_hours;
      _unlock_popup_defer_timer?.cancel();
      _unlock_popup_defer_timer = Timer(const Duration(seconds: 2), () {});
      logUtil(
        msg:
            '[ReadUnlockPopup] 延迟弹窗(提示文字可能可见), '
            'chapter=$chapter_index, hours=$hit_duration_hours',
      );
      return;
    }

    // 提示文字概率为 0（不展示提示文字），直接弹窗。
    _show_unlock_popup(hit_duration_hours);
  }

  /// 展示解锁免广告弹窗。
  ///
  /// [duration_hours] 免广告时长（小时），决定倒计时动画的终点数字。
  /// 弹窗内点击"立即解锁"按钮时，自动调用后端接口叠加对应时长。
  void _show_unlock_popup(int duration_hours) {
    if (!_can_process_read_ads) return;
    final bool is_dark = device_info.theme.value == ThemeMode.dark;
    final int duration_minutes = duration_hours * 60;
    UnlockAdFreePopup.show(
      context: context,
      is_dark: is_dark,
      duration_hours: duration_hours,
      on_tap: () => unawaited(_unlock_ad_free(duration_minutes)),
    );
  }

  /// 尝试展示延迟的解锁免广告弹窗。
  ///
  /// 在用户停止滚动时调用。如果延迟等待时间（2秒）已过，
  /// 说明用户已停止滚动，此时展示弹窗不会打断阅读。
  void _try_show_deferred_unlock_popup() {
    if (!_can_process_read_ads) {
      _clear_pending_unlock_popup();
      return;
    }
    final int? duration_hours = _pending_unlock_duration_hours;
    if (duration_hours == null) return;
    // 延迟定时器仍在计时中，说明用户刚触发延迟，暂不展示。
    if (_unlock_popup_defer_timer != null &&
        _unlock_popup_defer_timer!.isActive) {
      return;
    }
    // 定时器已到期，清除待展示状态并展示弹窗。
    _pending_unlock_duration_hours = null;
    _show_unlock_popup(duration_hours);
  }

  /// 清理尚未展示的免时长弹窗任务。
  ///
  /// 一旦确认设备已在免广告有效期内，延迟弹窗也必须同步撤销。
  void _clear_pending_unlock_popup() {
    _pending_unlock_duration_hours = null;
    _unlock_popup_defer_timer?.cancel();
    _unlock_popup_defer_timer = null;
  }

  /// 首次初始化设备免广告状态。
  ///
  /// 只有该任务结束后才放行原生广告和免时长弹窗；如果查询结果为
  /// 有效免广告，则继续保持屏蔽。
  Future<void> _initialize_ad_free_status() async {
    await _check_ad_free_status();
    if (!mounted) return;
    setState(() => _is_ad_free_status_ready = true);
    if (_is_ad_free) {
      _clear_pending_unlock_popup();
      return;
    }
    _sync_ad_policy();
  }

  /// 当前是否可以处理阅读页广告和免时长弹窗。
  bool get _can_process_read_ads => can_process_read_ads(
    is_ad_free_status_ready: _is_ad_free_status_ready,
    is_ad_free: _is_ad_free,
  );

  /// 异步检查设备免广告状态。
  ///
  /// 进入阅读页时调用一次，查询当前设备是否在免广告期内。
  /// 如果在免广告期内，设置 [_is_ad_free] 为 true，跳过所有原生广告展示。
  Future<void> _check_ad_free_status() async {
    final int verification_generation = _ad_free_verification_generation;
    try {
      final ResultsType<AdFreeStatus> result = await check_ad_free_status();
      if (!mounted ||
          verification_generation != _ad_free_verification_generation) {
        return;
      }
      if (result.status && result.content != null) {
        _apply_server_ad_free_status(result.content!);
        logUtil(
          msg:
              '[ReadAdFree] 免广告状态: is_ad_free=$_is_ad_free, '
              'remaining=${result.content!.remaining_seconds}s',
        );
      }
    } catch (e) {
      logUtil(msg: '[ReadAdFree] 查询免广告状态异常: $e', type: 'e');
    }
  }

  /// 使用服务端权威状态更新当前阅读页。
  ///
  /// Google SSV确认成功或校验超时后都会调用，确保客户端乐观增加的时长
  /// 最终与服务端一致。
  void _apply_server_ad_free_status(AdFreeStatus status) {
    final DateTime? expire_time = status.expire_time == null
        ? null
        : DateTime.tryParse(status.expire_time!);
    final bool is_active =
        status.is_ad_free &&
        expire_time != null &&
        expire_time.isAfter(DateTime.now());
    if (is_active) _clear_pending_unlock_popup();
    setState(() {
      _is_ad_free = is_active;
      _ad_free_expire_time = is_active ? expire_time : null;
    });
    _ad_free_expire_time_notifier.value = is_active ? expire_time : null;
    _schedule_ad_free_expiration(is_active ? expire_time : null);
  }

  /// 根据当前到期时间安排本地状态失效。
  ///
  /// 计时器触发后先恢复广告，再静默查询一次服务端，兼容设备时间误差或
  /// 其他终端在此期间新增了已确认免广告时长的情况。
  void _schedule_ad_free_expiration(DateTime? expire_time) {
    _ad_free_expire_timer?.cancel();
    _ad_free_expire_timer = null;
    if (expire_time == null) return;

    final Duration remaining = expire_time.difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    _ad_free_expire_timer = Timer(remaining, () {
      if (!mounted) return;
      setState(() {
        _is_ad_free = false;
        _ad_free_expire_time = null;
      });
      _ad_free_expire_time_notifier.value = null;
      unawaited(_check_ad_free_status());
    });
  }

  /// 点击"看视频免30分钟广告"提示时调用。
  ///
  /// 请求后端接口，播放视频广告后叠加30分钟免广告时长。
  /// 成功后更新本地免广告状态，后续章节不再展示原生广告。
  void _on_video_ad_hint_tap() {
    unawaited(_unlock_ad_free(30));
  }

  /// 请求广告配置、展示激励视频并乐观解锁免广告时长。
  ///
  /// [duration_minutes] 免广告分钟数，可选值：30/60/180/360。
  /// 后端准备接口不会提前发放奖励。只有Google Mobile Ads SDK返回
  /// [GoogleRewardedAdResult.rewarded] 后才在当前页面立即叠加时长，并在后台
  /// 静默等待Google SSV回调完成最终确认。
  Future<void> _unlock_ad_free(int duration_minutes) async {
    if (_is_rewarded_ad_loading) return;

    if (!AdDisplayPolicy.can_show_ads()) {
      if (!AdDisplayPolicy.should_bypass_ads()) {
        showBottomTip(easy.tr('read.ad_not_available'));
      }
      return;
    }

    setState(() => _is_rewarded_ad_loading = true);
    try {
      logUtil(msg: '[ReadAdFree] 准备激励视频: duration=${duration_minutes}min');
      final ResultsType<UnlockAdFreeResult> result = await unlock_ad_free_time(
        duration_minutes: duration_minutes,
        novel_id: widget.story_id,
      );
      if (!mounted) return;

      if (!result.status || result.content == null) {
        logUtil(msg: '[ReadAdFree] 获取广告配置失败: ${result.message}', type: 'w');
        showBottomTip(easy.tr('read.ad_not_available'));
        return;
      }

      // 后端请求期间广告开关可能被远程更新，调用SDK前再次校验。
      if (!AdDisplayPolicy.can_show_ads()) return;

      final UnlockAdFreeResult unlock_result = result.content!;
      final AdConfig? ad_config = unlock_result.ad_config;
      final int reward_duration_minutes = resolve_ad_free_reward_duration(
        requested_duration_minutes: duration_minutes,
        response_duration_minutes: unlock_result.duration_minutes,
      );
      if (unlock_result.duration_minutes <= 0) {
        logUtil(
          msg:
              '[ReadAdFree] 接口未返回duration_minutes，使用请求时长兼容: '
              '${duration_minutes}min',
          type: 'w',
        );
      }
      final bool is_valid_config =
          ad_config != null &&
          ad_config.advertisers == 1 &&
          ad_config.adsId.isNotEmpty &&
          ad_config.uuid.isNotEmpty &&
          reward_duration_minutes == duration_minutes;
      if (!is_valid_config) {
        logUtil(
          msg:
              '[ReadAdFree] 广告配置无效: '
              'advertisers=${ad_config?.advertisers}, '
              'adsId=${ad_config?.adsId}, uuid=${ad_config?.uuid}, '
              'responseDuration=${unlock_result.duration_minutes}, '
              'rewardDuration=$reward_duration_minutes',
          type: 'w',
        );
        showBottomTip(easy.tr('read.ad_not_available'));
        return;
      }
      final AdConfig rewarded_ad_config = ad_config;

      final GoogleRewardedAdResult ad_result = await GoogleRewardedAdUtil
          .instance
          .show_rewarded_ad(
            adUnitId: rewarded_ad_config.adsId,
            custom_data: rewarded_ad_config.uuid,
            can_show: () => mounted,
          );
      if (!mounted) return;

      switch (ad_result) {
        case GoogleRewardedAdResult.disabled:
          _sync_ad_policy();
          if (!AdDisplayPolicy.should_bypass_ads()) {
            showBottomTip(easy.tr('read.ad_not_available'));
          }
          break;
        case GoogleRewardedAdResult.rewarded:
          _apply_optimistic_ad_free_reward(
            duration_minutes: reward_duration_minutes,
            server_status: unlock_result.ad_free_status,
          );
          showBottomTip(easy.tr('read.ad_free_activated'));
          unawaited(
            _verify_ad_free_reward_in_background(rewarded_ad_config.uuid),
          );
          break;
        case GoogleRewardedAdResult.dismissed:
          showBottomTip(easy.tr('read.ad_not_completed'));
          break;
        case GoogleRewardedAdResult.load_failed:
          showBottomTip(easy.tr('read.ad_load_failed'));
          break;
        case GoogleRewardedAdResult.consent_unavailable:
          showBottomTip(easy.tr('read.ad_consent_unavailable'));
          break;
        case GoogleRewardedAdResult.show_failed:
          showBottomTip(easy.tr('read.ad_show_failed'));
          break;
        case GoogleRewardedAdResult.unsupported:
          showBottomTip(easy.tr('read.ad_unsupported'));
          break;
        case GoogleRewardedAdResult.busy:
          showBottomTip(easy.tr('read.ad_in_progress'));
          break;
        case GoogleRewardedAdResult.cancelled:
          break;
      }
    } catch (e, stack_trace) {
      logUtil(msg: '[ReadAdFree] 激励视频流程异常: $e\n$stack_trace', type: 'e');
      if (mounted) showBottomTip(easy.tr('read.ad_not_available'));
    } finally {
      if (mounted) {
        setState(() => _is_rewarded_ad_loading = false);
      }
    }
  }

  /// 在SDK确认用户获得奖励后立即在当前页面叠加免广告时长。
  ///
  /// 服务端已有有效时间、页面当前时间和当前设备时间取最大值作为叠加起点，
  /// 防止覆盖已经确认的剩余时长。
  void _apply_optimistic_ad_free_reward({
    required int duration_minutes,
    AdFreeStatus? server_status,
  }) {
    final String? server_expire_value = server_status?.expire_time;
    final DateTime? server_expire_time = server_expire_value == null
        ? null
        : DateTime.tryParse(server_expire_value);
    final DateTime expire_time = calculate_ad_free_expire_time(
      now: DateTime.now(),
      current_expire_time: _ad_free_expire_time,
      server_expire_time: server_expire_time,
      duration_minutes: duration_minutes,
    );
    _clear_pending_unlock_popup();
    setState(() {
      _is_ad_free = true;
      _ad_free_expire_time = expire_time;
    });
    _ad_free_expire_time_notifier.value = expire_time;
    _schedule_ad_free_expiration(expire_time);
    logUtil(
      msg:
          '[ReadAdFree] 本地乐观发放成功: '
          'duration=${duration_minutes}min, expire=$expire_time',
    );
  }

  /// 后台静默等待Google SSV确认，并用服务端状态校准本地乐观奖励。
  ///
  /// 验证成功后同步服务端最终到期时间；在完整重试窗口内始终未确认时，
  /// 同样同步服务端状态，从而只撤回本次未确认的乐观时长。网络完全不可用时
  /// 保留当前状态，避免把“暂时无法校验”误判为“没有看完广告”。
  Future<void> _verify_ad_free_reward_in_background(String uuid) async {
    final int verification_generation = ++_ad_free_verification_generation;
    bool received_pending_status = false;

    for (final Duration delay in _ad_free_verification_retry_delays) {
      await Future<void>.delayed(delay);
      if (!mounted ||
          verification_generation != _ad_free_verification_generation) {
        return;
      }

      final ResultsType<AdVerifyResult> result = await verify_ad_free_reward(
        uuid: uuid,
      );
      if (!mounted ||
          verification_generation != _ad_free_verification_generation) {
        return;
      }
      if (!result.status || result.content == null) continue;

      if (result.content!.status == AdVerifyResult.status_completed) {
        logUtil(msg: '[ReadAdFree] Google SSV验证完成: uuid=$uuid');
        await _synchronize_ad_free_status(
          verification_generation: verification_generation,
          reason: 'verified',
        );
        return;
      }
      if (result.content!.status == AdVerifyResult.status_not_completed) {
        received_pending_status = true;
      }
    }

    if (!received_pending_status ||
        !mounted ||
        verification_generation != _ad_free_verification_generation) {
      logUtil(msg: '[ReadAdFree] SSV校验期间网络不可用，暂不撤回本地奖励: uuid=$uuid', type: 'w');
      return;
    }

    logUtil(msg: '[ReadAdFree] SSV在重试窗口内未确认，回退到服务端状态: uuid=$uuid', type: 'w');
    await _synchronize_ad_free_status(
      verification_generation: verification_generation,
      reason: 'verification_timeout',
    );

    // Google回调可能因网络异常显著延迟；本地已完成回退后再低频复核一次。
    await Future<void>.delayed(_ad_free_late_verification_delay);
    if (!mounted ||
        verification_generation != _ad_free_verification_generation) {
      return;
    }
    final ResultsType<AdVerifyResult> late_result = await verify_ad_free_reward(
      uuid: uuid,
    );
    if (!mounted ||
        verification_generation != _ad_free_verification_generation ||
        !late_result.status ||
        late_result.content?.status != AdVerifyResult.status_completed) {
      return;
    }
    logUtil(msg: '[ReadAdFree] Google SSV延迟回调已确认: uuid=$uuid');
    await _synchronize_ad_free_status(
      verification_generation: verification_generation,
      reason: 'late_verified',
    );
  }

  /// 查询并应用服务端最终免广告状态。
  Future<void> _synchronize_ad_free_status({
    required int verification_generation,
    required String reason,
  }) async {
    final ResultsType<AdFreeStatus> result = await check_ad_free_status();
    if (!mounted ||
        verification_generation != _ad_free_verification_generation) {
      return;
    }
    if (!result.status || result.content == null) {
      logUtil(msg: '[ReadAdFree] 同步服务端状态失败，保留当前状态: reason=$reason', type: 'w');
      return;
    }
    _apply_server_ad_free_status(result.content!);
    logUtil(
      msg:
          '[ReadAdFree] 已同步服务端状态: reason=$reason, '
          'isAdFree=${result.content!.is_ad_free}, '
          'remaining=${result.content!.remaining_seconds}s',
    );
  }

  /// 为项目配置到达前已经加载的章节补齐一次性概率判断。
  Set<int> _resolve_loaded_chapter_native_ad_decisions() {
    if (!AdDisplayPolicy.can_show_ads()) return <int>{};

    final int probability = Get.find<ProjectConfigStore>()
        .current
        .ads_read_show_interstitial_ads_probability;
    final Set<int> native_ad_chapter_indexes = <int>{};
    for (final int chapter_index in logic.loaded_chapter_indexes) {
      final bool should_show = logic.resolve_chapter_native_ad_decision(
        chapter_index: chapter_index,
        probability: probability,
      );
      if (should_show) native_ad_chapter_indexes.add(chapter_index);
    }
    return native_ad_chapter_indexes;
  }

  /// 按公共平台策略同步长篇正文广告状态。
  void _sync_ad_policy() {
    const String log_prefix = '[ReadNativeAd]';
    if (!_can_process_read_ads) {
      logUtil(
        msg:
            '$log_prefix _sync_ad_policy: 跳过广告, '
            'status_ready=$_is_ad_free_status_ready, is_ad_free=$_is_ad_free',
      );
      if (mounted) setState(() {});
      return;
    }
    if (!AdDisplayPolicy.can_show_ads()) {
      logUtil(
        msg: '$log_prefix _sync_ad_policy: can_show_ads=false',
        type: 'w',
      );
      if (mounted) setState(() {});
      return;
    }
    final Set<int> native_ad_chapter_indexes =
        _resolve_loaded_chapter_native_ad_decisions();
    logUtil(
      msg:
          '$log_prefix _sync_ad_policy: 命中章节数=${native_ad_chapter_indexes.length}, '
          'indexes=$native_ad_chapter_indexes',
    );
    if (native_ad_chapter_indexes.isNotEmpty) {
      unawaited(_load_native_ad_config());
    }
    if (mounted) setState(() {});
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
    _unlock_popup_defer_timer?.cancel();
    _ad_free_expire_timer?.cancel();
    _ad_free_verification_generation++;
    // 退出页面时保存一次阅读进度。
    _save_current_progress_on_exit();
    _auto_read_ticker?.dispose();
    _comment_navigation_worker?.dispose();
    _error_worker?.dispose();
    _ad_policy_worker?.dispose();
    logic.wait_until_chapter_mutation_allowed = null;
    logic.preserve_chapter_anchor = null;
    logic.on_chapter_loaded = null;
    final Completer<void>? idle_completer = _scroll_idle_completer;
    if (idle_completer != null && !idle_completer.isCompleted) {
      idle_completer.complete();
    }
    _reading_progress_notifier.dispose();
    _has_started_reading_notifier.dispose();
    _ad_free_expire_time_notifier.dispose();
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

      // 滚动停止后尝试展示延迟的解锁免广告弹窗，避免滚动过程中弹窗打断阅读。
      _try_show_deferred_unlock_popup();
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
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
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
      // 免广告状态未就绪或仍在有效期时，所有阅读页广告保持屏蔽。
      final bool suppress_read_ads = !_can_process_read_ads;
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
                    native_ad_config: suppress_read_ads
                        ? null
                        : _native_ad_config,
                    is_native_ad_config_loading: suppress_read_ads
                        ? false
                        : _is_native_ad_config_loading,
                    on_native_ad_impression: () {
                      unawaited(_record_native_ad_impression());
                    },
                    ads_read_video_ad_probability: suppress_read_ads
                        ? 0
                        : Get.find<ProjectConfigStore>()
                              .current
                              .ads_read_video_ad_probability,
                    ad_free_expire_time_listenable:
                        _ad_free_expire_time_notifier,
                    on_video_ad_hint_tap: _on_video_ad_hint_tap,
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
              // 激励视频准备期间显示转圈并吸收点击，防止重复触发。
              if (_is_rewarded_ad_loading)
                Positioned.fill(
                  child: RewardedAdLoadingOverlay(is_dark: is_dark),
                ),
            ],
          ),
        ),
      );
    });
  }
}
