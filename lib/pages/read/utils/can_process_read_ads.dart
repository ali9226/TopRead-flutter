// ignore_for_file: non_constant_identifier_names

/// 判断长篇阅读页当前是否可以处理广告和免时长弹窗。
///
/// 首次免广告状态尚未返回时先屏蔽广告，避免有效期内的用户
/// 因为接口时序短暂看到原生广告或解锁弹窗。
bool can_process_read_ads({
  required bool is_ad_free_status_ready,
  required bool is_ad_free,
}) {
  return is_ad_free_status_ready && !is_ad_free;
}
