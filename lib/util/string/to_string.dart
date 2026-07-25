import 'package:intl/intl.dart';

/* TODO 把任意值安全转换为字符串。 */
String toStringSafe(dynamic value) {
  if (value == null) return '';

  try {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is DateTime) return value.toIso8601String();
    if (value is Iterable || value is Map) return value.toString();
    return value.toString();
  } catch (_) {
    return '';
  }
}

/* TODO 删除字符串里的所有空白字符。
 *
 * [input] 原始字符串。
 */
String removeSpaces(String input) {
  return input.replaceAll(RegExp(r'\s+'), '');
}

/* TODO 把金额格式化为千分位字符串。
 *
 * [value] 需要格式化的金额。
 */
String formatMoney(double value) {
  if (value % 1 == 0) {
    return NumberFormat('#,###').format(value);
  }
  return NumberFormat('#,###.##').format(value);
}

/* TODO 格式化数字并移除无意义尾零。
 *
 * [value] 原始数字。
 */
String formatNumber(num value) {
  String result = value.toStringAsFixed(2);
  result = result.replaceAll(RegExp(r'([.]*0+)$'), '');
  return result;
}
