import 'package:app/util/number_util.dart';

/// 把数字转成统一展示文本（千分位 + 去尾零）。
String displayBillNumber(double value) {
  return formatDisplayNumber(value);
}
