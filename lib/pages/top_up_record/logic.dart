import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/top_up_record.dart';
import 'package:app/stores/app_global_config.dart';
import 'package:app/util/number_util.dart';
import 'dart:async';

import 'style.dart';

/// 充值记录页面的逻辑控制器。
///
/// 这个类专门承接所有“非纯 UI”的工作：
/// 1. 调用 `recharge/inquire` 请求充值记录。
/// 2. 管理首次加载、下拉刷新、自动加载更多三种数据流。
/// 3. 维护分页状态、loading 状态和返回顶部按钮状态。
/// 4. 提供金额、空文案、状态文案等展示所需的格式化能力。
///
/// 这样做的核心目的是把业务状态从 `index.dart` 里移出去，
/// 避免页面文件一边写布局、一边写分页和滚动判断，后续维护会更清晰。
class TopUpRecordLogic extends ChangeNotifier {
  final AppGlobalConfigStore appGlobalConfigStore =
      Get.find<AppGlobalConfigStore>();

  /// 列表滚动控制器。
  ///
  /// 用途：
  /// 1. 监听滚动位置，决定是否自动加载更多。
  /// 2. 根据滚动深度控制“返回顶部”按钮的显隐。
  /// 3. 在点击悬浮按钮时执行平滑滚动到顶部。
  final ScrollController scrollController = ScrollController();

  /// 当前已经拿到的充值记录列表。
  ///
  /// 每次加载更多时，会把后端返回的新结果 append 到这个数组尾部。
  final List<TopUpRecordItem> records = [];

  /// 页面级 loading。
  ///
  /// 主要用于“首次进入页面”或需要全屏遮罩的刷新场景。
  bool loading = false;

  /// 底部加载更多状态。
  ///
  /// 和 `loading` 分离的原因是：
  /// 首次加载更适合全屏遮罩，而分页追加更适合轻量底部提示。
  bool loadingMore = false;

  /// 当前是否还有下一页数据。
  ///
  /// 判断规则：
  /// 如果某次返回条数小于 `pageSize`，就说明后面已经没有更多了。
  bool hasMore = true;

  /// 是否展示“返回顶部”按钮。
  bool showBackToTop = false;

  /// 充值地址的有效期，单位分钟。
  ///
  /// 默认先给一个后端当前约定的兜底值，等配置接口返回后再覆盖。
  int rechargeExpirationMinutes = 15;

  /// 统一的秒级倒计时定时器。
  ///
  /// 页面里每条记录的倒计时都基于同一个 ticker 刷新，
  /// 避免每张卡片各自起一个 Timer 带来额外开销。
  Timer? _countdownTimer;

  /// 上一秒是否还存在可见倒计时。
  ///
  /// 用于“最后一个倒计时结束时”补发一次刷新，
  /// 这样可以把倒计时条和充值地址块及时从界面移除。
  bool _hadActiveCountdown = false;

  /// 统一的“当前时间”快照。
  ///
  /// 倒计时全部基于这个时间点计算，
  /// 避免同一帧里多次调用 `DateTime.now()` 导致边界秒抖动。
  DateTime _now = DateTime.now();

  void init() {
    // 初始化时先注册滚动监听，再发首次请求。
    scrollController.addListener(_handleScroll);
    _startCountdownTicker();
    _syncRechargeExpirationTimeFromStore();
    unawaited(fetchRecords(isRefresh: true, showOverlay: true));
  }

  @override
  void dispose() {
    // 逻辑销毁前释放滚动监听与控制器，避免内存泄漏。
    _countdownTimer?.cancel();
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    super.dispose();
  }

  /// 对外暴露的下拉刷新入口。
  ///
  /// 返回值：接口成功拿到数据（含空列表）时为 true；并发冲突或请求失败时为 false。
  Future<bool> refresh() async {
    return fetchRecords(isRefresh: true);
  }

  /// 拉取充值记录。
  ///
  /// 返回值：本次请求成功且解析到列表时为 true（列表可为空）；否则为 false。
  Future<bool> fetchRecords({
    bool isRefresh = false,
    bool showOverlay = false,
  }) async {
    // 正在请求时直接返回，避免用户反复触发并发请求。
    if (loading || loadingMore) return false;

    // 非刷新场景下，如果已经确认没有更多数据，就不再继续请求。
    if (!isRefresh && !hasMore) return false;

    // 刷新时 no_ids 传空，表示重新取最新结果。
    // 分页时把当前已拿到的 id 全量传给后端，用于排除重复数据。
    final noIds = isRefresh ? <int>[] : records.map((item) => item.id).toList();

    // 根据当前请求类型切换对应的 loading 状态。
    if (showOverlay) {
      loading = true;
    } else if (!isRefresh) {
      loadingMore = true;
    }
    notifyListeners();

    var requestSucceeded = false;
    try {
      // 统一通过内部请求方法调用后端接口。
      final newRecords = await _getRecordList(
        noIds: noIds,
        pageSize: TopUpRecordStyle.pageSize,
      );

      // 接口失败时保持旧列表状态不动。
      if (newRecords == null) {
        requestSucceeded = false;
      } else {
        requestSucceeded = true;
        if (isRefresh) {
          // 刷新是覆盖式更新，不是追加。
          records
            ..clear()
            ..addAll(newRecords);
        } else {
          // 加载更多则把新结果接到尾部。
          records.addAll(newRecords);
        }

        // 返回条数不足一页，说明后面没有更多数据了。
        _now = DateTime.now();
        hasMore = newRecords.length >= TopUpRecordStyle.pageSize;
        _hadActiveCountdown = _hasAnyActiveCountdown();
        notifyListeners();
      }
    } finally {
      // finally 保证任何情况下都能恢复 loading 状态。
      loading = false;
      loadingMore = false;
      notifyListeners();
    }

    return requestSucceeded;
  }

  Future<void> scrollToTop() async {
    // 没有挂载滚动对象时，不执行动画。
    if (!scrollController.hasClients) return;

    // 使用平滑滚动而不是 jumpTo，用户感知更自然。
    await scrollController.animateTo(
      0,
      duration: const Duration(
        milliseconds: TopUpRecordStyle.scrollToTopDurationMs,
      ),
      curve: Curves.easeInOutCubic,
    );
  }

  String displayAmount(double value) {
    // 统一把金额格式化成带千分位且去尾零的美元字符串。
    return '\$${formatDisplayNumber(value)}';
  }

  String displayText(String? value) {
    // 空字符串或 null 统一回退成 '--'，避免 UI 上出现空白占位。
    final current = (value ?? '').trim();
    return current.isEmpty ? '--' : current;
  }

  String statusText(TopUpRecordItem item) {
    // 当前按后端 pay_status 做最基本的前端映射。
    // 如果后面状态种类扩展，优先继续在这里集中处理，不要分散到 UI 组件里。
    switch (item.payStatus) {
      case 1:
        if (remainingSeconds(item) <= 0) {
          return easy.tr('top_up_record_page.status_expired');
        }
        return easy.tr('top_up_record_page.status_unpaid');
      case 2:
        return easy.tr('top_up_record_page.status_success');
      case 3:
        return easy.tr('top_up_record_page.status_failed');
      default:
        return '${easy.tr('top_up_record_page.status_unknown')} #${item.payStatus}';
    }
  }

  Color statusColor(bool isDark, TopUpRecordItem item) {
    // 状态颜色和状态文案一样，集中由 logic 层统一给出，
    // 这样 UI 组件只消费颜色值，不关心业务枚举。
    switch (item.payStatus) {
      case 2:
        return ColorConstants.successColor;
      case 1:
        if (remainingSeconds(item) <= 0) {
          return TopUpRecordStyle.failedStatusColor;
        }
        return isDark
            ? TopUpRecordStyle.pendingStatusDarkColor
            : TopUpRecordStyle.pendingStatusLightColor;
      case 3:
        return TopUpRecordStyle.failedStatusColor;
      default:
        return isDark
            ? ColorConstants.whiteColor.withValues(
                alpha: TopUpRecordStyle.defaultStatusDarkOpacity,
              )
            : ColorConstants.hintColor;
    }
  }

  /// 未充值且仍在有效期内的记录才展示倒计时。
  bool shouldShowCountdown(TopUpRecordItem item) {
    return item.payStatus == 1 && remainingSeconds(item) > 0;
  }

  /// 倒计时结束后，未充值记录不再展示充值地址，避免用户继续误充旧地址。
  ///
  /// 成功和失败记录都不展示地址，只在未支付且仍有效时展示。
  bool shouldShowPayQrCode(TopUpRecordItem item) {
    if (item.payStatus == 2 ||
        item.payStatus == 3 ||
        item.payQrCode.trim().isEmpty) {
      return false;
    }
    if (item.payStatus == 1) {
      return remainingSeconds(item) > 0;
    }
    return true;
  }

  /// 返回某条记录剩余有效秒数。
  ///
  /// 后端时间是 0 时区，这里统一转成本地时间对应的绝对时间点再计算。
  int remainingSeconds(TopUpRecordItem item) {
    if (item.payStatus != 1) return 0;
    final createTime = _parseUtcDateTime(item.createTime);
    if (createTime == null) return 0;

    final expireAt = createTime.add(
      Duration(minutes: rechargeExpirationMinutes),
    );
    final diff = expireAt.difference(_now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// 把剩余秒数格式化成 `MM:SS` 或 `HH:MM:SS`。
  String countdownText(TopUpRecordItem item) {
    final seconds = remainingSeconds(item);
    if (seconds <= 0) return '--:--';

    final hour = seconds ~/ 3600;
    final minute = (seconds % 3600) ~/ 60;
    final second = seconds % 60;

    if (hour > 0) {
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}:'
          '${second.toString().padLeft(2, '0')}';
    }

    return '${minute.toString().padLeft(2, '0')}:'
        '${second.toString().padLeft(2, '0')}';
  }

  /// 后端返回的 create_time / pay_time 都是 0 时区时间。
  ///
  /// 这里统一按 UTC 解析后转成本地时间，再格式化为常规展示字符串。
  String displayUtcTime(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty ||
        raw == '0' ||
        raw == '0000-00-00 00:00:00' ||
        raw == '--') {
      return '--';
    }

    try {
      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      final utcTime = DateTime.parse('${normalized}Z');
      final localTime = utcTime.toLocal();
      final year = localTime.year.toString().padLeft(4, '0');
      final month = localTime.month.toString().padLeft(2, '0');
      final day = localTime.day.toString().padLeft(2, '0');
      final hour = localTime.hour.toString().padLeft(2, '0');
      final minute = localTime.minute.toString().padLeft(2, '0');
      final second = localTime.second.toString().padLeft(2, '0');
      return '$year-$month-$day $hour:$minute:$second';
    } catch (_) {
      return raw;
    }
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      final hasActiveCountdown = _hasAnyActiveCountdown();

      // 只在真正有倒计时，或刚好从“有倒计时”切到“无倒计时”时刷新，
      // 减少无意义的整页重建。
      if (hasActiveCountdown || _hadActiveCountdown != hasActiveCountdown) {
        _hadActiveCountdown = hasActiveCountdown;
        notifyListeners();
      }
    });
  }

  Future<void> _syncRechargeExpirationTimeFromStore() async {
    if (!appGlobalConfigStore.configLoaded.value) {
      await appGlobalConfigStore.loadConfig();
    }

    final int minutes =
        appGlobalConfigStore.businessConfig.rechargeExpirationTime;
    if (minutes <= 0 || minutes == rechargeExpirationMinutes) return;

    rechargeExpirationMinutes = minutes;
    _now = DateTime.now();
    _hadActiveCountdown = _hasAnyActiveCountdown();
    notifyListeners();
  }

  bool _hasAnyActiveCountdown() {
    return records.any(shouldShowCountdown);
  }

  DateTime? _parseUtcDateTime(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty ||
        raw == '0' ||
        raw == '0000-00-00 00:00:00' ||
        raw == '--') {
      return null;
    }

    try {
      final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
      return DateTime.parse('${normalized}Z').toLocal();
    } catch (_) {
      return null;
    }
  }

  void _handleScroll() {
    // 还没有挂载滚动对象时，不做任何计算。
    if (!scrollController.hasClients) return;

    // 计算离底部还有多远。
    final distanceToBottom =
        scrollController.position.maxScrollExtent - scrollController.offset;

    // 接近底部 300px 时提前触发下一页请求，避免真的滑到底才开始等加载。
    if (hasMore &&
        !loading &&
        !loadingMore &&
        records.isNotEmpty &&
        distanceToBottom <= TopUpRecordStyle.autoLoadMoreTriggerDistance) {
      fetchRecords();
    }

    final position =
        scrollController.position.viewportDimension *
        TopUpRecordStyle.backToTopThresholdRatio;
    final shouldShow = scrollController.offset > position;

    // 显示状态没变化时不通知，减少无效刷新。
    if (shouldShow == showBackToTop) return;

    showBackToTop = shouldShow;
    notifyListeners();
  }

  Future<List<TopUpRecordItem>?> _getRecordList({
    List<int> noIds = const [],
    int pageSize = 20,
  }) async {
    // 真实接口请求集中收口在这里：
    // - 路径固定为 `recharge/inquire`
    // - `data_only` 固定为 true
    // - `no_ids` 用于排除已拿到的数据
    // - `page_size` 控制每次分页条数
    final results = await postRequest<TopUpRecordListResponse>(
      path: 'recharge/inquire',
      showTips: false,
      parameter: {'no_ids': noIds, 'data_only': true, 'page_size': pageSize},
      fromJsonList: (json) => TopUpRecordListResponse.fromJsonList(json),
    );

    // 请求失败或数据体为空时，返回 null 给上层自行兜底。
    if (!results.status || results.content == null) {
      return null;
    }

    return results.content!.list;
  }
}
