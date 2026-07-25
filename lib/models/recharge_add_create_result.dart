/* TODO
 * 充值下单接口第一阶段返回模型。
 *
 * 当前后端在 `recharge/add` 里只返回一个订单 id，
 * Flutter 拿到这个 id 后会跳到二维码详情页，
 * 再通过 `recharge/get_info` 拉取完整充值信息。
 */
class RechargeAddCreateResult {
  final int id;

  const RechargeAddCreateResult({this.id = 0});

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  factory RechargeAddCreateResult.fromJson(Map<String, dynamic> json) {
    return RechargeAddCreateResult(id: _parseInt(json['id']));
  }
}
