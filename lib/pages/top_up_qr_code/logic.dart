import 'package:flutter/material.dart';
import 'package:app/models/recharge_add_result.dart';
import 'package:app/pages/top_up/logic.dart' as top_up_logic;

/* TODO
 * 充值二维码页逻辑层。
 *
 * 这里不直接重复写 postRequest，而是复用 TopUp 页已经接好的
 * recharge/get_info 请求封装，避免同一个接口在两个页面里出现两套解析逻辑。
 */
class Logic {
  final BuildContext context;
  late final top_up_logic.Logic _topUpLogic;

  Logic(this.context) {
    _topUpLogic = top_up_logic.Logic(context);
  }

  Future<RechargeAddResult?> getRechargeInfo({required int id}) async {
    return _topUpLogic.getRechargeInfo(id: id);
  }
}
