/// 把后端返回的 UTC 时间字符串转成本地时区显示文本。
///
/// 为什么这里要手动补 `T` 和 `Z`：
/// 1. 现有接口返回格式并不完全稳定，可能是 `yyyy-MM-dd HH:mm:ss`，
///    也可能已经是 ISO 字符串。
/// 2. `DateTime.parse` 在处理非标准 UTC 文本时容易按本地时间解释，
///    账单时间一旦错时区，用户会直接怀疑账目准确性。
/// 3. 因此这里先统一补成标准 UTC 输入，再转本地时间输出。
String formatBillUpdateTime(String value) {
  if (value.isEmpty) {
    return '';
  }

  try {
    final String normalized = value.contains('T')
        ? value
        : value.replaceFirst(' ', 'T');
    final String utcSource = normalized.endsWith('Z')
        ? normalized
        : '${normalized}Z';
    final DateTime utcTime = DateTime.parse(utcSource);
    final DateTime localTime = utcTime.toLocal();
    final String year = localTime.year.toString().padLeft(4, '0');
    final String month = localTime.month.toString().padLeft(2, '0');
    final String day = localTime.day.toString().padLeft(2, '0');
    final String hour = localTime.hour.toString().padLeft(2, '0');
    final String minute = localTime.minute.toString().padLeft(2, '0');
    final String second = localTime.second.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute:$second';
  } catch (_) {
    return value;
  }
}
