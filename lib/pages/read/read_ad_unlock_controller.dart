import 'dart:async';

import 'package:app/api/ad_free.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/pages/read/utils/calculate_ad_free_expire_time.dart';
import 'package:app/pages/read/utils/can_process_read_ads.dart';
import 'package:app/pages/read/widgets/unlock_ad_free_popup/index.dart';
import 'package:app/stores/read_ad_free_store.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/percentage_probability.dart';
import 'package:app/util/rewarded_ad_util.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 长篇阅读页免广告权益与激励解锁的宿主能力。
abstract class ReadAdUnlockHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 当前小说 ID。
  int get novel_id;

  /// 是否正在恢复阅读进度（恢复期间不弹窗）。
  bool get is_restoring_progress;

  /// 弹窗与提示所需的上下文。
  BuildContext get host_context;

  /// 界面刷新。
  void refresh_ui();

  /// 广告策略变化后同步正文广告位。
  void sync_ad_policy();
}

/// 长篇阅读页“看视频免广告”权益控制器。
///
/// 覆盖弹窗概率判定、延迟展示、激励视频播放与奖励时长发放，
/// 奖励结果统一经 [ReadAdFreeStore] 持久化，页面只消费权益状态。
class ReadAdUnlockController {
  ReadAdUnlockController({required this.host, required this.ad_free_store});

  /// 页面能力宿主。
  final ReadAdUnlockHost host;

  /// 免广告权益存储（本地持久化 + 服务器确认）。
  final ReadAdFreeStore ad_free_store;

  /// 已完成弹窗概率判定的章节（每章只判一次）。
  final Set<int> _evaluated_chapters = <int>{};

  /// 延迟弹窗定时器；为 true 表示提示文字可能可见，等待停止滚动。
  Timer? _defer_timer;

  /// 待展示的免广告时长（小时）。
  int? _pending_duration_hours;

  /// 当前是否在免广告有效期内。
  bool is_ad_free = false;

  /// 免广告状态是否已与服务器确认。
  bool is_status_ready = false;

  /// 免广告到期时间。
  final ValueNotifier<DateTime?> expire_time_notifier = ValueNotifier(null);

  /// 激励视频是否正在播放。
  bool is_rewarded_ad_loading = false;

  /// 免广告有效或状态未确认时，屏蔽所有长篇阅读广告。
  bool get can_process_ads_now => can_process_read_ads(
    is_ad_free_status_ready: is_status_ready,
    is_ad_free: is_ad_free,
  );

  /// 释放定时器与通知器。
  void dispose() {
    _defer_timer?.cancel();
    expire_time_notifier.dispose();
  }

  /// 章节切换时评估是否弹出免广告弹窗。
  ///
  /// [chapter_index] 当前章节下标；[six_hour]/[three_hour]/[an_hour] 为
  /// 对应时长的命中概率（千分比），[video_ad_probability] 大于 0 时
  /// 说明屏幕可能展示“看视频”提示，弹窗延迟到停止滚动后展示。
  void maybe_show_unlock_popup({
    required int chapter_index,
    required int six_hour,
    required int three_hour,
    required int an_hour,
    required int video_ad_probability,
  }) {
    // 免广告状态未就绪或已在有效期时禁止弹窗。
    if (!can_process_ads_now) return;

    // 第一章不触发，用户刚开始阅读时不做打扰。
    if (chapter_index <= 0) return;

    // 恢复进度跳转到的章节不触发，避免刚进入页面就弹窗。
    if (host.is_restoring_progress) return;

    // 已有延迟弹窗待展示时跳过，避免多次触发。
    if (_pending_duration_hours != null) return;

    // 同一章节只判断一次，避免重复弹窗。
    if (!_evaluated_chapters.add(chapter_index)) return;

    // 所有概率均为 0 时跳过，不做任何弹窗判断。
    if (six_hour <= 0 && three_hour <= 0 && an_hour <= 0) return;

    // 按优先级依次判断：6小时 → 3小时 → 1小时，命中即停。
    int? hit_duration_hours;
    if (six_hour > 0 && PercentageProbability.is_hit(six_hour)) {
      logUtil(
        msg:
            '[ReadUnlockPopup] 命中6小时免广告, chapter=$chapter_index, '
            'probability=$six_hour',
      );
      hit_duration_hours = 6;
    } else if (three_hour > 0 && PercentageProbability.is_hit(three_hour)) {
      logUtil(
        msg:
            '[ReadUnlockPopup] 命中3小时免广告, chapter=$chapter_index, '
            'probability=$three_hour',
      );
      hit_duration_hours = 3;
    } else if (an_hour > 0 && PercentageProbability.is_hit(an_hour)) {
      logUtil(
        msg:
            '[ReadUnlockPopup] 命中60分钟免广告, chapter=$chapter_index, '
            'probability=$an_hour',
      );
      hit_duration_hours = 1;
    }

    if (hit_duration_hours == null) return;

    // 提示文字可能在屏幕内时，延迟弹窗到用户停止滚动后再展示。
    if (video_ad_probability > 0) {
      _pending_duration_hours = hit_duration_hours;
      _defer_timer?.cancel();
      _defer_timer = Timer(const Duration(seconds: 2), () {});
      logUtil(
        msg:
            '[ReadUnlockPopup] 延迟弹窗(提示文字可能可见), '
            'chapter=$chapter_index, hours=$hit_duration_hours',
      );
      return;
    }

    show_unlock_popup(hit_duration_hours);
  }

  /// 展示解锁免广告弹窗；点击“立即解锁”后按 [duration_hours] 发放时长。
  void show_unlock_popup(int duration_hours) {
    if (!can_process_ads_now) return;
    final bool is_dark = Get.find<DeviceInfo>().theme.value == ThemeMode.dark;
    final int duration_minutes = duration_hours * 60;
    UnlockAdFreePopup.show(
      context: host.host_context,
      is_dark: is_dark,
      duration_hours: duration_hours,
      on_tap: () => unawaited(unlock_ad_free(duration_minutes)),
    );
  }

  /// 用户停止滚动后尝试展示此前延迟的弹窗。
  void try_show_deferred_unlock_popup() {
    if (!can_process_ads_now) {
      clear_pending_unlock_popup();
      return;
    }
    final int? duration_hours = _pending_duration_hours;
    if (duration_hours == null) return;
    // 延迟定时器仍在计时中，说明用户刚触发延迟，暂不展示。
    if (_defer_timer != null && _defer_timer!.isActive) return;
    // 定时器已到期，清除待展示状态并展示弹窗。
    _pending_duration_hours = null;
    show_unlock_popup(duration_hours);
  }

  /// 清理尚未展示的免时长弹窗任务。
  void clear_pending_unlock_popup() {
    _pending_duration_hours = null;
    _defer_timer?.cancel();
    _defer_timer = null;
  }

  /// 同步共享权益到当前页面。
  void apply_shared_ad_free_state() {
    if (!host.host_mounted) return;
    final bool is_active = ad_free_store.is_ad_free;
    final DateTime? expire_time = is_active ? ad_free_store.expire_time : null;
    if (is_active) clear_pending_unlock_popup();
    is_ad_free = is_active;
    is_status_ready = ad_free_store.is_status_ready;
    expire_time_notifier.value = expire_time;
    host.refresh_ui();
    host.sync_ad_policy();
  }

  /// 点击“看视频免30分钟广告”提示。
  void on_video_ad_hint_tap() {
    unawaited(unlock_ad_free(30));
  }

  /// 请求广告配置、展示激励视频并乐观解锁免广告时长。
  ///
  /// [duration_minutes] 免广告分钟数，可选值：30/60/180/360。
  /// 后端准备接口不会提前发放奖励。只有 Google Mobile Ads SDK 返回
  /// rewarded 后才在当前页面立即叠加时长，并在后台静默等待 SSV 回调确认。
  Future<void> unlock_ad_free(int duration_minutes) async {
    if (is_rewarded_ad_loading) return;

    if (!AdDisplayPolicy.can_show_ads()) {
      if (!AdDisplayPolicy.should_bypass_ads()) {
        showBottomTip(easy.tr('read.ad_not_available'));
      }
      return;
    }

    is_rewarded_ad_loading = true;
    host.refresh_ui();
    try {
      logUtil(msg: '[ReadAdFree] 准备激励视频: duration=${duration_minutes}min');
      final AdFreeRequestIdentity? identity = await ad_free_store
          .capture_reward_identity();
      if (!host.host_mounted || identity == null) return;
      final ResultsType<UnlockAdFreeResult> result = await unlock_ad_free_time(
        duration_minutes: duration_minutes,
        novel_id: host.novel_id,
        identity: identity,
      );
      if (!host.host_mounted || !ad_free_store.is_identity_current(identity)) {
        return;
      }

      if (!result.status || result.content == null) {
        logUtil(msg: '[ReadAdFree] 获取广告配置失败: ${result.message}', type: 'w');
        showBottomTip(easy.tr('read.ad_not_available'));
        return;
      }

      // 后端请求期间广告开关可能被远程更新，调用SDK前再次校验。
      if (!AdDisplayPolicy.can_show_ads()) return;

      final UnlockAdFreeResult unlock_result = result.content!;
      final DateTime reward_status_received_at = DateTime.now();
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
          ad_config.advertisers == AdTypeConfig.google_advertiser &&
          ad_config.adsId.isNotEmpty &&
          ad_config.uuid.isNotEmpty &&
          unlock_result.ad_free_status?.user_id == identity.user_id &&
          unlock_result.ad_free_status?.device_token == identity.device_token &&
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
            can_show: () =>
                host.host_mounted &&
                ad_free_store.is_identity_current(identity),
          );
      // 广告已经完整观看时先持久化奖励；退出小说页面不应丢失该次观看。
      final bool reward_recorded = ad_result == GoogleRewardedAdResult.rewarded
          ? await ad_free_store.record_reward(
              identity: identity,
              uuid: rewarded_ad_config.uuid,
              duration_minutes: reward_duration_minutes,
              server_status: unlock_result.ad_free_status,
              server_status_received_at: reward_status_received_at,
            )
          : false;
      if (!host.host_mounted || !ad_free_store.is_identity_current(identity)) {
        return;
      }

      switch (ad_result) {
        case GoogleRewardedAdResult.disabled:
          host.sync_ad_policy();
          if (!AdDisplayPolicy.should_bypass_ads()) {
            showBottomTip(easy.tr('read.ad_not_available'));
          }
          break;
        case GoogleRewardedAdResult.rewarded:
          if (reward_recorded) {
            showBottomTip(easy.tr('read.ad_free_activated'));
          }
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
      if (host.host_mounted) showBottomTip(easy.tr('read.ad_not_available'));
    } finally {
      is_rewarded_ad_loading = false;
      if (host.host_mounted) host.refresh_ui();
    }
  }
}
