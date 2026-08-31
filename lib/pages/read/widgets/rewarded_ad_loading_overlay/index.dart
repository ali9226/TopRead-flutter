import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 长篇阅读激励视频准备中的全页等待层。
///
/// 视频广告配置请求和SDK加载期间吸收所有点击，既给用户明确反馈，
/// 也从UI层阻止重复触发同一次激励视频流程。
class RewardedAdLoadingOverlay extends StatelessWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  const RewardedAdLoadingOverlay({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    final Color surface_color = is_dark
        ? RewardedAdLoadingOverlayStyle.surface_color_dark
        : RewardedAdLoadingOverlayStyle.surface_color_light;

    return AbsorbPointer(
      absorbing: true,
      child: ColoredBox(
        color: RewardedAdLoadingOverlayStyle.barrier_color,
        child: Center(
          child: Semantics(
            label: easy.tr('read.ad_loading'),
            liveRegion: true,
            child: Container(
              width: RewardedAdLoadingOverlayStyle.surface_size,
              height: RewardedAdLoadingOverlayStyle.surface_size,
              decoration: BoxDecoration(
                color: surface_color,
                borderRadius: BorderRadius.circular(
                  RewardedAdLoadingOverlayStyle.surface_radius,
                ),
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: RewardedAdLoadingOverlayStyle.indicator_size,
                height: RewardedAdLoadingOverlayStyle.indicator_size,
                child: CircularProgressIndicator(
                  strokeWidth:
                      RewardedAdLoadingOverlayStyle.indicator_stroke_width,
                  color: RewardedAdLoadingOverlayStyle.indicator_color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
