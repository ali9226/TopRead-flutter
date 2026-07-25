import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/models/transaction_inquire_type.dart';

/// 获取充值类型展示文案。
///
/// 为什么优先走 `languageVariables`：
/// 1. 接口返回的 `label` 更像兜底文本；
/// 2. 只要后端提供了多语种键值，前端就应该优先用翻译系统输出，
///    这样页面语言切换时才能保持一致。
String getTopUpTypeDisplayText(TransactionInquireTypeItem item) {
  if (item.languageVariables.isNotEmpty) {
    return easy.tr(item.languageVariables);
  }

  return item.label;
}
