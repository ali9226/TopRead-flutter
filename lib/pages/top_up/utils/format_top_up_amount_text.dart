import 'package:app/util/number_util.dart';

/// 把充值金额格式化成页面展示文本。
///
/// 统一复用项目内的数字格式化逻辑，
/// 是为了保证充值页、账单页、记录页的金额显示风格完全一致，
/// 避免同一个金额在不同页面出现位数和千分位不一致的问题。
String formatTopUpAmountText(double amount) {
  return '\$${formatDisplayNumber(amount)}';
}
