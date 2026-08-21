import 'package:app/api/post_request.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/rewarded_ad_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/debug_action_item.dart';

/// 激励视频广告调试按钮。
class RewardedAdDebugItem extends StatefulWidget {
  const RewardedAdDebugItem({required this.isDark, super.key});

  final bool isDark;

  @override
  State<RewardedAdDebugItem> createState() => _RewardedAdDebugItemState();
}

class _RewardedAdDebugItemState extends State<RewardedAdDebugItem> {
  static const String _logPrefix = '[Debug][RewardedAd]';

  bool _isLoading = false;

  Future<void> _handleTap() async {
    _log('用户点击"播放谷歌激励视频广告"按钮');
    if (!AdDisplayPolicy.can_show_ads()) {
      _log('当前平台广告开关未开启', type: 'w');
      showBottomTip('当前平台未开启广告');
      return;
    }
    if (!GoogleRewardedAdUtil.instance.is_supported) {
      _log('当前平台不支持激励视频广告', type: 'w');
      showBottomTip('当前设备不是安卓或苹果设备');
      return;
    }
    if (_isLoading) {
      _log('广告正在加载，忽略重复点击', type: 'w');
      return;
    }

    setState(() => _isLoading = true);
    _log('进入广告加载状态');

    try {
      // 请求广告配置接口。
      final results = await postRequest<AdConfig>(
        path: 'ads/short_story_read',
        showTips: false,
        fromJson: (json) => AdConfig.fromJson(json),
      );

      if (!results.status || results.content == null) {
        _log('获取广告配置失败: ${results.message}', type: 'w');
        showBottomTip('获取广告配置失败');
        return;
      }

      final AdConfig adConfig = results.content!;
      _log(
        '广告配置: advertisers=${adConfig.advertisers}, adsId=${adConfig.adsId}',
      );

      // advertisers=1 表示谷歌广告，且 ads_id 必须有值。
      if (adConfig.advertisers != 1 || adConfig.adsId.isEmpty) {
        _log(
          '广告配置异常: advertisers=${adConfig.advertisers}, adsId=${adConfig.adsId}',
          type: 'w',
        );
        showBottomTip(tr('short_story_read.ad_not_available'));
        return;
      }

      final String adUnitId = adConfig.adsId;
      _log('使用广告单元 ID: $adUnitId, uuid=${adConfig.uuid}');

      final GoogleRewardedAdResult result = await GoogleRewardedAdUtil.instance
          .show_rewarded_ad(
            adUnitId: adUnitId,
            custom_data: adConfig.uuid,
            can_show: () => mounted,
          );
      if (!mounted) return;

      switch (result) {
        case GoogleRewardedAdResult.disabled:
          showBottomTip('当前平台未开启广告');
          break;
        case GoogleRewardedAdResult.rewarded:
          showBottomTip('激励视频已看完，获得奖励');
          break;
        case GoogleRewardedAdResult.dismissed:
          showBottomTip('激励视频未完成，未获得奖励');
          break;
        case GoogleRewardedAdResult.load_failed:
          showBottomTip('激励视频广告加载失败');
          break;
        case GoogleRewardedAdResult.consent_unavailable:
          showBottomTip('UMP 隐私同意未完成，未请求广告');
          break;
        case GoogleRewardedAdResult.show_failed:
          showBottomTip('激励视频广告展示失败');
          break;
        case GoogleRewardedAdResult.unsupported:
          showBottomTip('当前设备不是安卓或苹果设备');
          break;
        case GoogleRewardedAdResult.busy:
          showBottomTip('激励视频广告正在播放');
          break;
        case GoogleRewardedAdResult.cancelled:
          break;
      }
      _log('激励视频广告流程结束，result=${result.name}');
    } catch (e, stackTrace) {
      _log('广告流程异常: $e\n$stackTrace', type: 'e');
      showBottomTip('激励视频广告展示失败');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _log('退出广告加载状态');
    }
  }

  void _log(String message, {String? type}) {
    logUtil(msg: '$_logPrefix $message', type: type);
  }

  @override
  Widget build(BuildContext context) {
    return DebugActionItem(
      title: '播放谷歌激励视频广告',
      isDark: widget.isDark,
      isLoading: _isLoading,
      onTap: _handleTap,
    );
  }
}
