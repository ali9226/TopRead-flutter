import 'package:easy_localization/easy_localization.dart' as easy;

/// 根据账单类型返回多语种文案键值。
///
/// 这里不能把 `type` 直接展示给用户，
/// 因为后端返回的是业务编码，不是可读文案。
/// 页面通过单独的映射函数，把“接口编码”和“前端展示语义”解耦，
/// 以后新增类型时只需要集中维护这里即可。
String getBillTypeText(int type) {
  switch (type) {
    case 3:
      return easy.tr('bill.type_3');
    case 103:
      return easy.tr('bill.type_103');
    case 104:
      return easy.tr('bill.type_104');
    case 105:
      return easy.tr('bill.type_105');
    case 106:
      return easy.tr('bill.type_106');
    case 108:
      return easy.tr('bill.type_108');
    case 109:
      return easy.tr('bill.type_109');
    case 110:
      return easy.tr('bill.type_110');
    default:
      return easy.tr('bill.type_default');
  }
}
