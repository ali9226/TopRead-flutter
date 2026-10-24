import 'dart:async';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/share_sheet/index.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/models/ad_verify_result.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_sheet.dart';
import 'package:app/pages/short_story_read/widgets/reading_settings_sheet.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/rewarded_ad_util.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 短篇阅读页工具栏动作的宿主能力。
abstract class StoryToolbarHost {
  /// 弹窗与分享所需的上下文。
  BuildContext get host_context;

  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 当前页面逻辑层。
  ShortStoryReadLogic get logic;

  /// 当前阅读树代数。
  int get reader_generation;

  /// 指定逻辑与代数是否仍是当前篇。
  bool is_current_logic(ShortStoryReadLogic logic, int generation);

  /// 激励视频是否正在加载。
  bool get is_rewarded_ad_loading;

  /// 更新激励视频加载状态。
  set is_rewarded_ad_loading(bool value);

  /// 停止自动阅读。
  void stop_auto_read();

  /// 开启自动阅读。
  void start_auto_read();

  /// 修改字号并按比例恢复位置。
  void change_body_font_size(VoidCallback mutation);

  /// 切换到指定小说（目录点击入口）。
  void open_story(int story_id);

  /// 界面刷新。
  void refresh_ui();

  /// 广告位状态变化，清空正文高度缓存。
  void invalidate_progress_extent();

  /// 标记用户已交互。
  void mark_user_engaged();

  /// 清零底部下一篇遮罩透明度。
  void reset_next_story_overlay();

  /// 重新计算当前篇的正文滚动范围（解锁后内容变高必须刷新）。
  double calculate_story_extent();

  /// 写回正文滚动范围缓存。
  void cache_story_extent(double extent);

  /// 正文滚动控制器。
  ScrollController get scroll_controller;
}

/// 短篇阅读页工具栏与目录/设置/解锁动作处理器。
///
/// 集中承载返回、分享、评论、收藏、点赞、目录、设置与激励解锁等
/// 入口逻辑；解锁发放链路与页面广告门控协同，但不直接持有页面 State。
class StoryToolbarActions {
  StoryToolbarActions({required this.host});

  /// 页面能力宿主。
  final StoryToolbarHost host;

  /// 返回上一页。
  void on_back() {
    AppRouter.pop();
  }

  /// 弹出分享弹窗，传递当前小说的基本信息。
  void on_share() {
    final ShortStoryReadLogic logic = host.logic;
    showShareSheet(
      context: host.host_context,
      novel_id: logic.story_id,
      novel_title: logic.title,
      novel_cover_url: logic.story_data.value?.cover_url ?? '',
      novel_intro: logic.story_data.value?.introduction ?? '',
      is_dark: Get.find<DeviceInfo>().dark.value,
    );
  }

  /// 弹出评论弹窗；关闭后若有新增评论，同步底部评论栏数量。
  Future<void> on_comment_tap({int scroll_to_comment_id = 0}) async {
    host.stop_auto_read();
    final ShortStoryReadLogic comment_logic = host.logic;
    final int? new_count = await showCommentSheet(
      context: host.host_context,
      novel_id: comment_logic.story_id,
      on_close: () => Navigator.pop(host.host_context),
      scroll_to_comment_id: scroll_to_comment_id,
    );
    if (new_count != null && host.host_mounted) {
      comment_logic.update_comment_count(new_count);
    }
  }

  /// 收藏按钮（带登录检查）。
  Future<void> on_favorite_tap() async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;
    final ShortStoryReadLogic action_logic = host.logic;
    final bool? is_favorited = await action_logic.toggle_favorite();
    if (!host.host_mounted || is_favorited == null) return;
    showBottomTip(
      easy.tr(
        is_favorited ? 'favorite.add_success' : 'favorite.remove_success',
      ),
    );
  }

  /// 底部栏点赞按钮（带登录检查）。
  Future<void> on_like_tap() async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;
    await host.logic.toggle_like();
  }

  /// 目录弹窗中的卡片点赞（乐观更新，失败静默回退）。
  Future<void> on_catalog_like_tap(int story_id) async {
    final bool is_logged_in = await showLoginRequiredDialog(
      title: easy.tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;

    final ShortStoryReadLogic action_logic = host.logic;
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

  /// 从底部弹出目录弹窗（数据来自预加载的目录列表）。
  void on_catalog_tap() {
    host.stop_auto_read();
    final ShortStoryReadLogic sheet_logic = host.logic;
    showModalBottomSheet(
      context: host.host_context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: ColorConstants.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(host.host_context).size.width,
      ),
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
            host.open_story(story_id);
          },
          on_like_tap: on_catalog_like_tap,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_reload: sheet_logic.reload_catalog,
        );
      },
    );
  }

  /// 从底部弹出阅读设置弹窗。
  Future<void> on_setting_tap() async {
    bool should_start_auto_read = false;
    await showModalBottomSheet<void>(
      context: host.host_context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: ColorConstants.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(host.host_context).size.width,
      ),
      builder: (BuildContext sheet_context) {
        return ReadingSettingsSheet(
          logic: host.logic,
          on_close: () => Navigator.of(sheet_context).pop(),
          on_decrease_font_size: () {
            host.change_body_font_size(host.logic.decrease_font_size);
          },
          on_increase_font_size: () {
            host.change_body_font_size(host.logic.increase_font_size);
          },
          on_auto_read: () {
            should_start_auto_read = true;
            Navigator.of(sheet_context).pop();
          },
        );
      },
    );
    if (!host.host_mounted || !should_start_auto_read) return;
    host.start_auto_read();
  }

  /// 观看激励视频广告并解锁当前短篇的全部正文。
  Future<void> on_unlock_story_tap() async {
    if (host.is_rewarded_ad_loading || host.logic.is_story_unlocked.value) {
      return;
    }

    if (!AdDisplayPolicy.can_show_ads()) {
      host.logic.sync_ad_access_policy();
      host.invalidate_progress_extent();
      host.refresh_ui();
      if (!AdDisplayPolicy.should_bypass_ads()) {
        showBottomTip(easy.tr('short_story_read.ad_not_available'));
      }
      return;
    }

    host.stop_auto_read();
    final ShortStoryReadLogic action_logic = host.logic;
    final int action_generation = host.reader_generation;

    host.is_rewarded_ad_loading = true;
    host.refresh_ui();
    try {
      // 从后端获取广告配置。
      final adConfigResult = await postRequest<AdConfig>(
        path: 'ads/short_story_read',
        parameter: <String, dynamic>{'source_id': host.logic.story_id},
        showTips: false,
        fromJson: (json) => AdConfig.fromJson(json),
      );
      if (!host.is_current_logic(action_logic, action_generation)) return;

      // 后端广告配置请求期间开关可能被远程更新，调用 SDK 前再次校验。
      if (!AdDisplayPolicy.can_show_ads()) {
        action_logic.sync_ad_access_policy();
        host.invalidate_progress_extent();
        host.refresh_ui();
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
            can_show: () =>
                host.is_current_logic(action_logic, action_generation),
          );
      if (!host.is_current_logic(action_logic, action_generation)) return;

      switch (result) {
        case GoogleRewardedAdResult.disabled:
          action_logic.sync_ad_access_policy();
          host.invalidate_progress_extent();
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
          host.mark_user_engaged();
          host.invalidate_progress_extent();
          host.reset_next_story_overlay();
          host.refresh_ui();
          await WidgetsBinding.instance.endOfFrame;
          await WidgetsBinding.instance.endOfFrame;
          if (!host.is_current_logic(action_logic, action_generation) ||
              !host.scroll_controller.hasClients) {
            return;
          }
          final double full_extent = host.calculate_story_extent();
          host.cache_story_extent(full_extent);
          action_logic.update_reading_progress(
            host.scroll_controller.offset,
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
      // 旧篇请求结束时不能清除新篇激励广告的加载状态。
      if (host.is_current_logic(action_logic, action_generation)) {
        host.is_rewarded_ad_loading = false;
        host.refresh_ui();
      }
    }
  }
}
