import 'dart:async';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/services/ad_impression_reporter.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/log_util.dart';
import 'package:get/get.dart';

/// 长篇原生广告门控的宿主能力。
abstract class ReadingNativeAdHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 当前小说 ID。
  int get novel_id;

  /// 页面逻辑层。
  Logic get logic;

  /// 免广告有效或状态未确认时屏蔽广告。
  bool get can_process_ads_now;

  /// 界面刷新。
  void refresh_ui();

  /// 章节加载后触发解锁弹窗概率判断。
  void maybe_show_unlock_popup(int chapter_index);
}

/// 长篇阅读页原生广告门控。
///
/// 负责配置拉取（每篇一次）、章节级概率决策与平台策略同步；
/// 页面只消费 [native_ad_config] 并在其变化后重建广告位。
class ReadingNativeAdGate {
  ReadingNativeAdGate({required this.host});

  /// 页面能力宿主。
  final ReadingNativeAdHost host;

  /// 已就绪的原生广告配置。
  AdConfig? native_ad_config;

  /// 是否已发起过配置请求（每篇一次）。
  bool _has_requested_config = false;

  /// 配置是否加载中。
  bool is_config_loading = false;

  /// 读取原生广告配置；免广告期或已请求过时跳过。
  Future<void> load_native_ad_config() async {
    const String log_prefix = '[ReadNativeAdConfig]';
    if (!host.can_process_ads_now) {
      logUtil(msg: '$log_prefix 免广告状态未就绪或仍在有效期，跳过加载');
      return;
    }
    if (!AdDisplayPolicy.can_show_ads()) {
      logUtil(msg: '$log_prefix can_show_ads=false，跳过加载广告配置', type: 'w');
      return;
    }
    if (_has_requested_config) {
      logUtil(
        msg:
            '$log_prefix 已请求过广告配置, '
            'native_ad_config=${native_ad_config != null}, '
            'adsId=${native_ad_config?.adsId}',
      );
      return;
    }
    _has_requested_config = true;
    is_config_loading = true;
    host.refresh_ui();
    try {
      logUtil(
        msg: '$log_prefix 开始读取本地广告配置, source_id=${host.novel_id}',
      );

      final AdConfig? ad_config = Get.isRegistered<AdConfigStore>()
          ? Get.find<AdConfigStore>().select_google_config(
              AdPlacement.long_story_native,
            )
          : null;

      if (!host.host_mounted) return;

      if (ad_config == null) {
        logUtil(msg: '$log_prefix 本地缓存没有可用配置，跳过', type: 'w');
        return;
      }

      // 请求期间可能刚获得免广告时长，此时不再挂载原生广告。
      if (!host.can_process_ads_now) {
        _has_requested_config = false;
        logUtil(msg: '$log_prefix 请求返回时已在免广告期，丢弃本次配置');
        return;
      }

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
      if (ad_config.advertisers != AdTypeConfig.google_advertiser ||
          ad_config.adsId.isEmpty) {
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

      native_ad_config = ad_config;
    } catch (e, stack_trace) {
      logUtil(msg: '$log_prefix 广告配置加载异常: $e\n$stack_trace', type: 'e');
    } finally {
      is_config_loading = false;
      if (host.host_mounted) host.refresh_ui();
    }
  }

  /// 在 AdMob 确认原生广告产生真实展示后记录一次长篇小说广告统计。
  Future<void> record_native_ad_impression() async {
    final AdConfig? ad_config = native_ad_config;
    if (ad_config == null || ad_config.adsId.isEmpty) return;
    await AdImpressionReporter.report(
      ad_config: ad_config,
      placement: AdPlacement.long_story_native,
      source_id: host.novel_id,
    );
  }

  /// 章节正文进入阅读窗口时完成该章唯一一次广告概率判断。
  ///
  /// 同时触发解锁免广告弹窗的概率判断。
  void on_chapter_loaded(int chapter_index) {
    const String log_prefix = '[ReadNativeAd]';

    // 免广告状态未就绪或仍在有效期时，跳过所有广告和弹窗逻辑。
    if (!host.can_process_ads_now) {
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
      logUtil(
        msg: '$log_prefix config未加载完成，跳过章节 $chapter_index',
        type: 'w',
      );
      return;
    }

    final bool should_show = host.logic.resolve_chapter_native_ad_decision(
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
            'native_ad_config=${native_ad_config != null}, '
            'is_loading=$is_config_loading, '
            'has_requested=$_has_requested_config',
      );
      host.refresh_ui();
      unawaited(load_native_ad_config());
    }

    // 触发解锁免广告弹窗概率判断。
    host.maybe_show_unlock_popup(chapter_index);
  }

  /// 为项目配置到达前已经加载的章节补齐一次性概率判断。
  Set<int> resolve_loaded_chapter_decisions() {
    if (!AdDisplayPolicy.can_show_ads()) return <int>{};

    final int probability = Get.find<ProjectConfigStore>()
        .current
        .ads_read_show_interstitial_ads_probability;
    final Set<int> native_ad_chapter_indexes = <int>{};
    for (final int chapter_index in host.logic.loaded_chapter_indexes) {
      final bool should_show = host.logic.resolve_chapter_native_ad_decision(
        chapter_index: chapter_index,
        probability: probability,
      );
      if (should_show) native_ad_chapter_indexes.add(chapter_index);
    }
    return native_ad_chapter_indexes;
  }

  /// 按公共平台策略同步长篇正文广告状态。
  void sync_ad_policy() {
    const String log_prefix = '[ReadNativeAd]';
    if (!host.can_process_ads_now) {
      logUtil(msg: '$log_prefix sync_ad_policy: 当前禁止阅读广告，跳过');
      host.refresh_ui();
      return;
    }
    if (!AdDisplayPolicy.can_show_ads()) {
      logUtil(msg: '$log_prefix sync_ad_policy: can_show_ads=false', type: 'w');
      host.refresh_ui();
      return;
    }
    final Set<int> native_ad_chapter_indexes = resolve_loaded_chapter_decisions();
    logUtil(
      msg:
          '$log_prefix sync_ad_policy: 命中章节数=${native_ad_chapter_indexes.length}, '
          'indexes=$native_ad_chapter_indexes',
    );
    if (native_ad_chapter_indexes.isNotEmpty) {
      unawaited(load_native_ad_config());
    }
    host.refresh_ui();
  }
}
