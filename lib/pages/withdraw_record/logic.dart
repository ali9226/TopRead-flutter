import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/api/post_request.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/withdraw_record.dart';
import 'package:app/pages/withdraw_record/style.dart';
import 'package:app/util/number_util.dart';

/// 提现记录页逻辑层。
///
/// 这里沿用充值记录页的分页和滚动交互，只保留提现需要的字段和状态映射。
class WithdrawRecordLogic extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final List<WithdrawRecordItem> records = [];

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  bool showBackToTop = false;

  void init() {
    scrollController.addListener(_handleScroll);
    unawaited(fetchRecords(isRefresh: true, showOverlay: true));
  }

  @override
  void dispose() {
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    super.dispose();
  }

  /// 下拉刷新；成功拿到数据（含空列表）时返回 true。
  Future<bool> refresh() async {
    return fetchRecords(isRefresh: true);
  }

  /// 拉取提现记录；成功时返回 true。
  Future<bool> fetchRecords({
    bool isRefresh = false,
    bool showOverlay = false,
  }) async {
    if (loading || loadingMore) return false;
    if (!isRefresh && !hasMore) return false;

    final noIds = isRefresh ? <int>[] : records.map((item) => item.id).toList();

    if (showOverlay) {
      loading = true;
    } else if (!isRefresh) {
      loadingMore = true;
    }
    notifyListeners();

    var requestSucceeded = false;
    try {
      final newRecords = await _getRecordList(
        noIds: noIds,
        pageSize: TopUpRecordStyle.pageSize,
      );
      if (newRecords == null) {
        requestSucceeded = false;
      } else {
        requestSucceeded = true;
        if (isRefresh) {
          records
            ..clear()
            ..addAll(newRecords);
        } else {
          records.addAll(newRecords);
        }

        hasMore = newRecords.length >= TopUpRecordStyle.pageSize;
        notifyListeners();
      }
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }

    return requestSucceeded;
  }

  Future<void> scrollToTop() async {
    if (!scrollController.hasClients) return;

    await scrollController.animateTo(
      0,
      duration: const Duration(
        milliseconds: TopUpRecordStyle.scrollToTopDurationMs,
      ),
      curve: Curves.easeInOutCubic,
    );
  }

  String displayAmount(double value) {
    return formatDisplayNumber(value);
  }

  String displayText(String? value) {
    final current = (value ?? '').trim();
    return current.isEmpty ? '--' : current;
  }

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

  bool shouldShowPayTime(WithdrawRecordItem item) {
    return displayUtcTime(item.payTime) != '--';
  }

  String statusText(BuildContext context, WithdrawRecordItem item) {
    switch (item.payStatus) {
      case 1:
        return context.tr('withdraw_record_page.status_processing');
      case 2:
        return context.tr('withdraw_record_page.status_success');
      case 3:
        return context.tr('withdraw_record_page.status_void');
      case 4:
        return context.tr('withdraw_record_page.status_returned');
      default:
        return '${context.tr('withdraw_record_page.status_unknown')} #${item.payStatus}';
    }
  }

  Color statusColor(bool isDark, WithdrawRecordItem item) {
    switch (item.payStatus) {
      case 2:
      case 4:
        return ColorConstants.successColor;
      case 3:
        return ColorConstants.dangerColor;
      case 1:
        return isDark
            ? TopUpRecordStyle.pendingStatusDarkColor
            : TopUpRecordStyle.pendingStatusLightColor;
      default:
        return isDark
            ? ColorConstants.whiteColor.withValues(
                alpha: TopUpRecordStyle.defaultStatusDarkOpacity,
              )
            : ColorConstants.hintColor;
    }
  }

  void _handleScroll() {
    if (!scrollController.hasClients) return;

    final distanceToBottom =
        scrollController.position.maxScrollExtent - scrollController.offset;
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
    if (shouldShow == showBackToTop) return;

    showBackToTop = shouldShow;
    notifyListeners();
  }

  Future<List<WithdrawRecordItem>?> _getRecordList({
    List<int> noIds = const [],
    int pageSize = 20,
  }) async {
    final results = await postRequest<WithdrawRecordListResponse>(
      path: 'withdraw/inquire',
      showTips: false,
      parameter: {'no_ids': noIds, 'data_only': true, 'page_size': pageSize},
      fromJsonList: (json) => WithdrawRecordListResponse.fromJsonList(json),
    );

    if (!results.status || results.content == null) {
      return null;
    }

    return results.content!.list;
  }
}
