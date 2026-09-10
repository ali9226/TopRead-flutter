// ignore_for_file: non_constant_identifier_names

import 'style.dart';

/// 单次弹窗的临时选择。只有确认后才交回表单，取消不会改动原草稿。
class ScheduleTimeSelection {
  ScheduleTimeSelection({required DateTime now, DateTime? initial_time})
      : opened_at = now.toLocal() {
    minimum_time = DateTime(
      opened_at.year, opened_at.month, opened_at.day,
      opened_at.hour, opened_at.minute + 1,
    );
    final horizon = opened_at.add(const Duration(days: ScheduleTimeStyle.horizon_days));
    maximum_time = DateTime(horizon.year, horizon.month, horizon.day, 23, 59);
    final initial = initial_time?.toLocal();
    selected_time = clamp_time(
      initial != null && initial.isAfter(opened_at) ? initial : tomorrow_morning,
    );
  }

  final DateTime opened_at;
  late final DateTime minimum_time;
  late final DateTime maximum_time;
  late DateTime selected_time;

  DateTime get next_hour => minimum_time.add(const Duration(hours: 1));
  DateTime get tomorrow_morning => DateTime(
    opened_at.year, opened_at.month, opened_at.day + 1, 9,
  );
  DateTime get following_morning => DateTime(
    opened_at.year, opened_at.month, opened_at.day + 2, 9,
  );

  /// 日期轮以分钟为单位；同时兼容旧草稿中的秒值、UTC 和超出范围的日期。
  DateTime clamp_time(DateTime time) {
    final local = time.toLocal();
    final minute = DateTime(local.year, local.month, local.day, local.hour, local.minute);
    if (minute.isBefore(minimum_time)) return minimum_time;
    if (minute.isAfter(maximum_time)) return maximum_time;
    return minute;
  }

  void select(DateTime time) => selected_time = clamp_time(time);

  /// 确认时重新读取时钟，防止面板长时间停留后提交已经过去的时间。
  bool is_valid_at(DateTime now) =>
      selected_time.isAfter(now) && !selected_time.isAfter(maximum_time);
}
