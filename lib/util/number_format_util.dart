/// 数字格式化工具类。
///
/// 提供数字的格式化显示功能。
class NumberFormatUtil {
  /// 格式化数字显示。
  ///
  /// - 小于 10000：直接显示原数字。
  /// - 大于等于 10000 且小于 100000000：显示为 x.xw 格式。
  /// - 大于等于 100000000：显示为 x.x 亿格式。
  ///
  /// [count] 要格式化的数字。
  static String format_count(int count) {
    if (count < 10000) {
      return count.toString();
    } else if (count < 100000000) {
      final double wan = count / 10000;
      return '${wan.toStringAsFixed(1)}w';
    } else {
      final double yi = count / 100000000;
      return '${yi.toStringAsFixed(1)} 亿';
    }
  }
}
