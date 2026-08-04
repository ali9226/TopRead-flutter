import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/platform.dart';
import '../widgets/debug_action_item.dart';
import 'logic.dart';

/// 激励视频广告调试按钮。
class RewardedAdDebugItem extends StatefulWidget {
  const RewardedAdDebugItem({required this.isDark, super.key});

  final bool isDark;

  @override
  State<RewardedAdDebugItem> createState() => _RewardedAdDebugItemState();
}

class _RewardedAdDebugItemState extends State<RewardedAdDebugItem> {
  static const String _logPrefix = '[Debug][RewardedAd]';

  final RewardedAdLogic _logic = RewardedAdLogic();
  bool _isLoading = false;

  Future<void> _handleTap() async {
    _log('用户点击“激励视频广告”按钮');
    if (!isAndroidOrIOS) {
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
      final RewardedAd? rewardedAd = await _logic.loadAd();
      if (rewardedAd == null) {
        _log('未获取到可展示的广告对象', type: 'e');
        showBottomTip('激励视频广告加载失败');
        return;
      }
      if (!mounted) {
        _log('页面已销毁，放弃展示并释放广告', type: 'w');
        await rewardedAd.dispose();
        _log('广告资源已释放');
        return;
      }

      bool hasEarnedReward = false;
      RewardItem? earnedReward;
      final String ssvAttemptId =
          'debug_${DateTime.now().microsecondsSinceEpoch}';

      _log('SSV 参数开始设置，userId=debug_user, customData=$ssvAttemptId');
      await rewardedAd.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: 'debug_user',
          customData: ssvAttemptId,
        ),
      );
      _log('SSV 参数设置完成');

      rewardedAd.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
        _log(
          '收入事件，valueMicros=$valueMicros, '
          'precision=${precision.name}, currencyCode=$currencyCode',
        );
      };

      rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _log('广告已进入全屏展示');
        },
        onAdImpression: (ad) {
          _log('广告曝光已记录');
        },
        onAdClicked: (ad) {
          _log('用户点击了广告');
        },
        onAdWillDismissFullScreenContent: (ad) {
          _log('广告即将关闭（iOS 回调）');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _log(
            '广告展示失败，code=${error.code}, '
            'domain=${error.domain}, message=${error.message}',
            type: 'e',
          );
          ad.dispose();
          _log('展示失败后已请求释放广告资源');
          if (mounted) {
            showBottomTip('激励视频广告展示失败');
          }
        },
        onAdDismissedFullScreenContent: (ad) {
          _log(
            '广告已关闭，奖励状态: '
            '${hasEarnedReward ? '已获得' : '未获得'}'
            '${earnedReward == null ? '' : '，数量=${earnedReward!.amount}, '
                      '类型=${earnedReward!.type}'}',
          );
          ad.dispose();
          _log('广告关闭后已请求释放广告资源');
          if (mounted) {
            showBottomTip(hasEarnedReward ? '激励视频已看完，获得奖励' : '激励视频未完成，未获得奖励');
          }
        },
      );

      _log('调用 RewardedAd.show()，请求展示广告');
      await rewardedAd.show(
        onUserEarnedReward: (ad, reward) {
          hasEarnedReward = true;
          earnedReward = reward;
          _log(
            '收到 onUserEarnedReward，用户获得奖励，'
            'amount=${reward.amount}, type=${reward.type}',
          );
        },
      );
      _log('RewardedAd.show() 调用已提交');
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
      title: '激励视频广告',
      isDark: widget.isDark,
      isLoading: _isLoading,
      onTap: _handleTap,
    );
  }
}
