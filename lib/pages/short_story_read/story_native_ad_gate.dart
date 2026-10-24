import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/pages/short_story_read/utils/resolve_story_native_ad_insert_index.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/native_ad_insert_index.dart';
import 'package:app/util/percentage_probability.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 短篇原生广告与激励门控的宿主能力。
abstract class StoryNativeAdHost {
  /// 当前小说 ID。
  int get story_id;

  /// 当前小说正文。
  String get content;

  /// 当前小说是否已解锁。
  bool get is_story_unlocked;

  /// 阅读树代数：切篇后失效，避免旧请求回写。
  int get reader_generation;

  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 是否已完成初始化。
  bool get is_initialization_complete;

  /// 用户是否已经开始阅读交互。
  bool get has_user_engaged;

  /// 当前语种是否为 CJK。
  bool get is_cjk_language;

  /// 界面刷新。
  void refresh_ui();

  /// 广告位状态变化，清空正文高度缓存。
  void invalidate_progress_extent();
}

/// 短篇阅读页的原生广告与视频解锁门控决策器。
///
/// 负责一次性概率判定、广告配置拉取与失效丢弃，
/// 把广告状态机从页面 State 中拆出，页面只消费结论与配置。
class StoryNativeAdGate {
  StoryNativeAdGate({required this.host});

  /// 页面能力宿主。
  final StoryNativeAdHost host;

  /// 当前小说的广告概率是否已经完成一次性判断。
  int? _ad_probability_generation;

  /// 短篇视频广告概率是否命中（需要展示解锁门控）。
  bool is_video_ad_gate_required = true;

  /// 激励视频加载中。
  bool is_rewarded_ad_loading = false;

  /// 是否插入原生广告。
  bool should_show_native_ad = false;

  /// 原生广告配置。
  AdConfig? native_ad_config;

  /// 正在拉取配置的代数集合，防止并发重复请求。
  final Set<int> _native_ad_config_loading_generations = <int>{};

  /// 广告位 key；配置替换后整体换新以释放旧素材。
  GlobalKey native_ad_slot_key = GlobalKey();

  /// 原生广告插入的正文段落下标。
  int? native_ad_insert_index;

  /// 切篇时把概率判定标记清空，等待新代数重新决策。
  void mark_generation_pending() {
    _ad_probability_generation = null;
  }

  /// 当前代数是否已完成概率判定。
  bool is_generation_resolved(int generation) =>
      _ad_probability_generation == generation;

  /// 广告位是否就绪可插入。
  bool get has_ready_slot => should_show_native_ad && native_ad_config != null;

  /// 读取原生广告配置；页面切换或策略关闭后丢弃结果。
  Future<void> load_native_ad_config({required int generation}) async {
    const String log_prefix = '[NativeAdConfig]';
    if (!AdDisplayPolicy.can_show_ads() ||
        !should_show_native_ad ||
        _ad_probability_generation != generation ||
        !_native_ad_config_loading_generations.add(generation)) {
      return;
    }
    try {
      logUtil(
        msg: '$log_prefix 开始读取本地广告配置, source_id=${host.story_id}',
      );

      final AdConfig? ad_config = Get.isRegistered<AdConfigStore>()
          ? Get.find<AdConfigStore>().select_google_config(
              AdPlacement.short_story_native,
            )
          : null;

      // 页面已切换或已销毁，丢弃结果。
      if (host.reader_generation != generation ||
          !host.host_mounted ||
          !AdDisplayPolicy.can_show_ads() ||
          !should_show_native_ad ||
          _ad_probability_generation != generation) {
        logUtil(msg: '$log_prefix 页面已切换或销毁，丢弃结果');
        return;
      }

      if (ad_config == null) {
        logUtil(msg: '$log_prefix 本地缓存没有可用配置，跳过', type: 'w');
        discard_for_generation(generation);
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
        discard_for_generation(generation);
        return;
      }

      logUtil(
        msg: '$log_prefix 创建NativeAdBanner, adUnitId=${ad_config.adsId}',
      );

      native_ad_config = ad_config;
      host.refresh_ui();
    } catch (e, stack_trace) {
      logUtil(msg: '$log_prefix 广告配置加载异常: $e\n$stack_trace', type: 'e');
      discard_for_generation(generation);
    } finally {
      _native_ad_config_loading_generations.remove(generation);
    }
  }

  /// 为当前小说一次性判断原生广告和激励视频广告概率。
  void resolve_probability_decisions({required int generation}) {
    if (_ad_probability_generation == generation) return;

    // 配置尚未解析时保持待定，等 config_revision 通知后再判断；
    // 明确关闭广告时才把当前小说固定为免广告。
    if (!AdDisplayPolicy.can_show_ads() &&
        !AdDisplayPolicy.is_config_resolved()) {
      return;
    }

    _ad_probability_generation = generation;
    reset_native_state();

    if (!AdDisplayPolicy.can_show_ads()) {
      is_video_ad_gate_required = false;
      return;
    }

    final current_config = Get.find<ProjectConfigStore>().current;
    is_video_ad_gate_required = PercentageProbability.is_hit(
      current_config.ads_short_story_video_ad_probability,
    );

    final bool content_supports_native_ad = can_insert_native_ad(
      host.content,
    );
    final bool reader_has_not_started =
        !host.is_initialization_complete || !host.has_user_engaged;
    should_show_native_ad =
        content_supports_native_ad &&
        reader_has_not_started &&
        PercentageProbability.is_hit(
          current_config.ads_short_story_show_interstitial_ads_probability,
        );
    if (should_show_native_ad) {
      native_ad_insert_index = resolve_story_native_ad_insert_index(
        content: host.content,
        is_unlocked: host.is_story_unlocked || !is_video_ad_gate_required,
        is_cjk: host.is_cjk_language,
      );
    }
    logUtil(
      msg:
          '[NativeAdConfig] 概率判断完成: '
          'generation=$generation, '
          'nativeProbability='
          '${current_config.ads_short_story_show_interstitial_ads_probability}, '
          'showNative=$should_show_native_ad, '
          'videoProbability=${current_config.ads_short_story_video_ad_probability}, '
          'requireVideo=$is_video_ad_gate_required',
    );
    host.refresh_ui();
  }

  /// 清空当前原生广告配置，广告组件随正文重建自行释放素材与监听。
  void reset_native_state() {
    should_show_native_ad = false;
    native_ad_config = null;
    native_ad_slot_key = GlobalKey();
    native_ad_insert_index = null;
    host.invalidate_progress_extent();
  }

  /// 当前广告配置不可用时移除广告位。
  void discard_for_generation(int generation) {
    if (!host.host_mounted || host.reader_generation != generation) return;
    reset_native_state();
    host.refresh_ui();
  }

  /// 将远端广告平台开关同步到当前短篇的正文与广告位。
  void on_policy_changed({
    required void Function() sync_ad_access_policy,
  }) {
    sync_ad_access_policy();
    if (!AdDisplayPolicy.can_show_ads()) {
      is_rewarded_ad_loading = false;
      is_video_ad_gate_required = false;
      _ad_probability_generation = host.reader_generation;
      if (host.host_mounted) {
        host.invalidate_progress_extent();
        host.refresh_ui();
      }
      return;
    }

    if (host.content.isNotEmpty) {
      resolve_probability_decisions(generation: host.reader_generation);
    }
    if (should_show_native_ad && native_ad_config == null) {
      load_native_ad_config(generation: host.reader_generation);
    }
    host.refresh_ui();
  }

  /// 切篇初始化时的门控决策入口。
  void on_story_initialized({required int generation}) {
    resolve_probability_decisions(generation: generation);
    if (should_show_native_ad) {
      load_native_ad_config(generation: generation);
    }
  }

  /// 释放资源。
  void dispose() {
    _native_ad_config_loading_generations.clear();
  }
}
