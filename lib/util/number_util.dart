import 'package:intl/intl.dart';

final NumberFormat _numberFormatter = NumberFormat('#,##0.##');

/// 统一金额显示：千分位 + 去除小数末尾无意义 0。
///
/// TODO 先按“分”级别做一次归一化，消除 double 二进制浮点噪音，
/// TODO 再做千分位格式化，避免出现 1766.3800000000000001091 这种展示。
///
/// 示例：
/// - 12.30 -> 12.3
/// - 12.00 -> 12
/// - 1766.38 -> 1,766.38
String formatMoneyDisplay(num value) {
  final double normalized = (value * 100).roundToDouble() / 100;
  return _numberFormatter.format(normalized);
}

/// 统一数字显示：当前默认与金额显示规则保持一致。
String formatDisplayNumber(num value) {
  return formatMoneyDisplay(value);
}

/// 兼容旧调用方。
String formatAmountWithThousands(double value) {
  return formatDisplayNumber(value);
}

/// 兼容旧调用方。
String thousandsSeparator(double value) {
  return formatDisplayNumber(value);
}

/// 仅返回不带千分位的规整数字字符串（去掉末尾 0）。
String formatNumberValue(double value) {
  final String result = value.toStringAsFixed(16).replaceFirst(RegExp(r'\.?0+$'), '');
  return result.isEmpty ? '0' : result;
}
