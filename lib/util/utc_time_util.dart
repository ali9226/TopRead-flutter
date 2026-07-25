// ignore_for_file: non_constant_identifier_names

/// TODO 将后端 UTC 时间解析为用户设备本地时间。
///
/// 后端可能返回 `yyyy-MM-dd HH:mm:ss`、ISO 8601 `Z` 或带时区
/// 偏移的字符串。没有时区后缀时始终按 UTC 解析，避免 Dart
/// 将其误当成本地时间。
DateTime? parse_utc_time_to_local(String value) {
  final DateTime? utc_time = _parse_utc_time(value);
  return utc_time?.toLocal();
}

/// TODO 将后端 UTC 时间统一为带 `Z` 的 ISO 8601 字符串。
String normalize_utc_time(String value) {
  final DateTime? utc_time = _parse_utc_time(value);
  return utc_time?.toUtc().toIso8601String() ?? value.trim();
}

/// TODO 将 UTC 消息时间格式化为适合气泡内展示的本地时间。
///
/// 今天只显示时分，当年其他日期显示月日和时分，跨年时补充年份。
String format_message_local_time(String value, {DateTime? now}) {
  final DateTime? local_time = parse_utc_time_to_local(value);
  if (local_time == null) return '';

  final DateTime local_now = (now ?? DateTime.now()).toLocal();
  final String hour = local_time.hour.toString().padLeft(2, '0');
  final String minute = local_time.minute.toString().padLeft(2, '0');
  final bool is_today =
      local_time.year == local_now.year &&
      local_time.month == local_now.month &&
      local_time.day == local_now.day;
  if (is_today) return '$hour:$minute';

  final String month = local_time.month.toString().padLeft(2, '0');
  final String day = local_time.day.toString().padLeft(2, '0');
  if (local_time.year == local_now.year) {
    return '$month-$day $hour:$minute';
  }

  final String year = local_time.year.toString().padLeft(4, '0');
  return '$year-$month-$day $hour:$minute';
}

/// TODO 将任意支持的后端时间文本统一解析为 UTC。
DateTime? _parse_utc_time(String value) {
  final String raw_value = value.trim();
  if (raw_value.isEmpty ||
      raw_value == '0' ||
      raw_value == '0000-00-00 00:00:00') {
    return null;
  }

  final String normalized_value = raw_value.contains('T')
      ? raw_value
      : raw_value.replaceFirst(' ', 'T');
  final bool has_timezone = RegExp(
    r'(Z|[+-]\d{2}:?\d{2})$',
    caseSensitive: false,
  ).hasMatch(normalized_value);
  final String utc_value = has_timezone
      ? normalized_value
      : '${normalized_value}Z';
  return DateTime.tryParse(utc_value)?.toUtc();
}
