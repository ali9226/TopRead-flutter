/* TODO
 * 充值详情接口返回模型。
 *
 * amountPayable:
 * 用户最初选择的充值金额。
 *
 * payPayable:
 * 服务端为了避开金额冲突后，最终要求用户实际转入的金额。
 *
 * typeStr:
 * 当前地址所属的充值网络名称，例如 USDT-TRC20。
 *
 * payQrCode:
 * 服务端随机分配出来的收款地址。
 *
 * serialNumber:
 * 当前充值订单对应的流水号，后续排查订单时会用到。
 */
class RechargeAddResult {
  final double amountPayable;
  final double payPayable;
  final String typeStr;
  final String payQrCode;
  final String serialNumber;

  const RechargeAddResult({
    this.amountPayable = 0,
    this.payPayable = 0,
    this.typeStr = '',
    this.payQrCode = '',
    this.serialNumber = '',
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory RechargeAddResult.fromJson(Map<String, dynamic> json) {
    return RechargeAddResult(
      amountPayable: _parseDouble(
        json['amount_payable'] ?? json['amountPayable'],
      ),
      payPayable: _parseDouble(json['pay_payable'] ?? json['payPayable']),
      typeStr: json['type_str']?.toString() ?? '',
      payQrCode: json['pay_qr_code']?.toString() ?? '',
      serialNumber: json['serial_number']?.toString() ?? '',
    );
  }
}
