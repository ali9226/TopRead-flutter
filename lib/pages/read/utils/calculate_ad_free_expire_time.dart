/// 计算客户端乐观发放奖励后的免广告到期时间。
///
/// [now] 是当前设备时间。
/// [current_expire_time] 是阅读页内已经生效的到期时间。
/// [server_expire_time] 是准备广告接口返回的服务端已确认到期时间。
/// [duration_minutes] 是本次完整观看广告获得的分钟数。
///
/// 取三个时间中的最大值作为叠加起点，确保已有有效时长不会被覆盖；如果
/// 原有时长已经到期，则从当前时间重新计算。
DateTime calculate_ad_free_expire_time({
  required DateTime now,
  DateTime? current_expire_time,
  DateTime? server_expire_time,
  required int duration_minutes,
}) {
  DateTime base_time = now;
  if (current_expire_time != null && current_expire_time.isAfter(base_time)) {
    base_time = current_expire_time;
  }
  if (server_expire_time != null && server_expire_time.isAfter(base_time)) {
    base_time = server_expire_time;
  }
  return base_time.add(Duration(minutes: duration_minutes));
}

/// 解析本次激励视频最终使用的免广告分钟数。
///
/// 新版后端会回传 [response_duration_minutes]；兼容尚未重启或尚未升级的旧版
/// 后端，当该字段缺失并被解析为0时，使用客户端本次明确请求的时长。
/// 如果后端返回了非零时长，则保留原值供调用方校验是否与请求一致。
int resolve_ad_free_reward_duration({
  required int requested_duration_minutes,
  required int response_duration_minutes,
}) {
  if (response_duration_minutes > 0) return response_duration_minutes;
  return requested_duration_minutes;
}
