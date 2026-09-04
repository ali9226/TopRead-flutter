// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/util/log_util.dart';

/// 广告真实曝光静默上报器。
///
/// 仅在 Google Mobile Ads SDK 触发曝光回调后调用。上报失败只写日志，
/// 不显示提示、不阻塞广告或页面交互。
class AdImpressionReporter {
  const AdImpressionReporter._();

  /// 将一次真实广告曝光发送到后端。
  ///
  /// [ad_config] 是本次实际加载的缓存广告配置。
  /// [placement] 是广告所在的固定业务场景。
  /// [source_id] 是小说 ID；只有正文广告需要传入。
  static Future<void> report({
    required AdConfig ad_config,
    required AdPlacement placement,
    int source_id = 0,
  }) async {
    if (ad_config.adsId.trim().isEmpty) return;

    try {
      final ResultsType<void> result = await postRequest<void>(
        path: 'ads/record_impression',
        parameter: <String, dynamic>{
          'ads_id': ad_config.adsId,
          'placement': placement.name,
          if (source_id > 0) 'source_id': source_id,
        },
        showTips: false,
      );
      if (!result.status) {
        logUtil(
          msg:
              '[AdImpressionReporter] 曝光上报失败: '
              'placement=${placement.name}, adsId=${ad_config.adsId}, '
              'message=${result.message}',
          type: 'w',
        );
      }
    } catch (error, stack_trace) {
      logUtil(
        msg:
            '[AdImpressionReporter] 曝光上报异常: '
            'placement=${placement.name}, error=$error\n$stack_trace',
        type: 'w',
      );
    }
  }
}
