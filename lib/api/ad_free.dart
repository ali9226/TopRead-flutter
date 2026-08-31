// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/models/ad_verify_result.dart';
import 'package:app/websocket/websocket_service.dart';

/// 免广告状态数据模型。
class AdFreeStatus {
  /// 是否在免广告期内。
  final bool is_ad_free;

  /// 免广告到期时间（ISO格式字符串）。
  final String? expire_time;

  /// 剩余免广告秒数。
  final int remaining_seconds;

  const AdFreeStatus({
    required this.is_ad_free,
    this.expire_time,
    required this.remaining_seconds,
  });

  factory AdFreeStatus.fromJson(Map<String, dynamic> json) {
    return AdFreeStatus(
      is_ad_free: _parse_bool(json['is_ad_free']),
      expire_time: json['expire_time']?.toString(),
      remaining_seconds: _parse_int(json['remaining_seconds']),
    );
  }

  /// 兼容数据库驱动把布尔值返回为数字或字符串的情况。
  static bool _parse_bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == '1' || normalized == 'true';
  }

  /// 兼容数据库驱动把秒数返回为字符串的情况。
  static int _parse_int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// 解锁广告结果数据模型。
class UnlockAdFreeResult {
  /// 广告单元配置。
  final AdConfig? ad_config;

  /// 服务端当前已经确认的免广告状态，不包含本次尚未观看的奖励。
  final AdFreeStatus? ad_free_status;

  /// 本次完整观看广告后应获得的免广告分钟数。
  final int duration_minutes;

  const UnlockAdFreeResult({
    this.ad_config,
    this.ad_free_status,
    required this.duration_minutes,
  });

  factory UnlockAdFreeResult.fromJson(Map<String, dynamic> json) {
    return UnlockAdFreeResult(
      ad_config: json['ad_config'] is Map
          ? AdConfig.fromJson(
              Map<String, dynamic>.from(json['ad_config'] as Map),
            )
          : null,
      ad_free_status: json['ad_free_status'] is Map
          ? AdFreeStatus.fromJson(
              Map<String, dynamic>.from(json['ad_free_status'] as Map),
            )
          : null,
      duration_minutes: _parse_int(json['duration_minutes']),
    );
  }

  /// 兼容后端把数值返回为字符串的情况。
  static int _parse_int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// 获取设备标识（visitor_uuid）。
///
/// 复用 WebSocketService 的唯一设备标识生成逻辑，避免阅读页早于
/// 自动登录初始化时查不到已有免广告状态。
Future<String> _get_device_token() async {
  return WebSocketService().get_or_create_visitor_uuid();
}

/// 查询设备当前免广告状态。
///
/// 调用 `ads/read_check_ad_free_status` 接口，
/// 返回设备是否在免广告期内以及剩余时间。
Future<ResultsType<AdFreeStatus>> check_ad_free_status() async {
  final String device_token = await _get_device_token();
  if (device_token.isEmpty) {
    return ResultsType<AdFreeStatus>()
      ..status = false
      ..message = 'device_token not found';
  }

  return postRequest<AdFreeStatus>(
    path: 'ads/read_check_ad_free_status',
    parameter: <String, dynamic>{'device_token': device_token},
    showTips: false,
    fromJson: (json) => AdFreeStatus.fromJson(json),
  );
}

/// 准备长篇小说免广告激励视频。
///
/// 调用 `ads/read_unlock_ad_free_time` 接口，
/// 创建待Google SSV验证的广告记录，并返回广告配置及当前服务端状态。
/// 此接口不会提前发放本次免广告奖励。
///
/// [duration_minutes] 免广告分钟数，可选值：30（免30分钟）、60（免60分钟）、
/// 180（免3小时）、360（免6小时）。不同时长对应不同的视频广告单元。
/// [novel_id] 当前正在阅读的小说ID，用于广告播放数据归因。
Future<ResultsType<UnlockAdFreeResult>> unlock_ad_free_time({
  required int duration_minutes,
  required int novel_id,
}) async {
  final String device_token = await _get_device_token();
  if (device_token.isEmpty) {
    return ResultsType<UnlockAdFreeResult>()
      ..status = false
      ..message = 'device_token not found';
  }

  return postRequest<UnlockAdFreeResult>(
    path: 'ads/read_unlock_ad_free_time',
    parameter: <String, dynamic>{
      'device_token': device_token,
      'duration_minutes': duration_minutes,
      'novel_id': novel_id,
    },
    showTips: false,
    fromJson: (json) => UnlockAdFreeResult.fromJson(json),
  );
}

/// 静默查询指定激励视频UUID的Google SSV验证状态。
///
/// Flutter收到本地奖励回调后会先乐观增加免广告时长，再使用此接口等待
/// Google服务端回调。该查询不会显示网络错误提示，不会打断用户阅读。
Future<ResultsType<AdVerifyResult>> verify_ad_free_reward({
  required String uuid,
}) async {
  return postRequest<AdVerifyResult>(
    path: 'novel_ads/search_results',
    parameter: <String, dynamic>{'uuid': uuid},
    showTips: false,
    fromJson: (json) => AdVerifyResult.fromJson(json),
  );
}
