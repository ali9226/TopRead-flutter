class WithdrawRecordItem {
  final int id;
  final int payStatus;
  final String createTime;
  final String payTime;
  final String serialNumber;
  final double amountPayable;
  final String typeStr;
  final String payQrCode;

  const WithdrawRecordItem({
    this.id = 0,
    this.payStatus = 0,
    this.createTime = '',
    this.payTime = '',
    this.serialNumber = '',
    this.amountPayable = 0,
    this.typeStr = '',
    this.payQrCode = '',
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory WithdrawRecordItem.fromJson(Map<String, dynamic> json) {
    return WithdrawRecordItem(
      id: _parseInt(json['id']),
      payStatus: _parseInt(json['pay_status'] ?? json['payStatus']),
      createTime: json['create_time']?.toString() ?? '',
      payTime: json['pay_time']?.toString() ?? '',
      serialNumber: json['serial_number']?.toString() ?? '',
      amountPayable: _parseDouble(
        json['amount_payable'] ?? json['amountPayable'],
      ),
      typeStr: json['type_str']?.toString() ?? '',
      payQrCode: json['pay_qr_code']?.toString() ?? '',
    );
  }
}

class WithdrawRecordListResponse {
  final List<WithdrawRecordItem> list;

  const WithdrawRecordListResponse({required this.list});

  factory WithdrawRecordListResponse.fromJsonList(List<dynamic> json) {
    return WithdrawRecordListResponse(
      list: json
          .whereType<Map>()
          .map(
            (item) =>
                WithdrawRecordItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
