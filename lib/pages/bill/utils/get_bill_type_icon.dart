/// 根据账单类型和金额方向推导图标名称。
///
/// 为什么不能只靠金额正负判断：
/// 1. 有些账单类型本身就带有明确业务语义，例如提现、充值。
/// 2. 后端后续如果出现“金额为 0 但仍需显示业务图标”的场景，
///    页面也需要优先遵守业务类型，而不是只看金额。
String getBillTypeIcon({required int type, required double amount}) {
  switch (type) {
    case 105:
      return 'withdraw_02';
    case 106:
      return 'recharge';
    default:
      return amount >= 0 ? 'recharge' : 'withdraw_02';
  }
}
