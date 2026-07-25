import 'display_bill_number.dart';

/// 格式化账单金额正负号。
///
/// 账单列表里最重要的信息之一就是“这笔流水到底是增加还是减少”，
/// 所以这里显式补上 `+` / `-`，避免用户只看颜色时产生误读。
String formatBillAmount(double amount) {
  final String fixed = displayBillNumber(amount.abs());

  if (amount > 0) {
    return '+$fixed';
  }

  if (amount < 0) {
    return '-$fixed';
  }

  return fixed;
}
