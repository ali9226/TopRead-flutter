class TopUpRecordItem {
  final int id;
  final int payStatus;
  final String createTime;
  final String payTime;
  final String serialNumber;
  final double amountPayable;
  final double payPayable;
  final String carrierOrderNumber;
  final String typeStr;
  final String payQrCode;

  const TopUpRecordItem({
    this.id = 0,
    this.payStatus = 0,
    this.createTime = '',
    this.payTime = '',
    this.serialNumber = '',
    this.amountPayable = 0,
    this.payPayable = 0,
    this.carrierOrderNumber = '',
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

  factory TopUpRecordItem.fromJson(Map<String, dynamic> json) {
    return TopUpRecordItem(
      id: _parseInt(json['id']),
      payStatus: _parseInt(json['pay_status'] ?? json['payStatus']),
      createTime: json['create_time']?.toString() ?? '',
      payTime: json['pay_time']?.toString() ?? '',
      serialNumber: json['serial_number']?.toString() ?? '',
      amountPayable: _parseDouble(
        json['amount_payable'] ?? json['amountPayable'],
      ),
      payPayable: _parseDouble(json['pay_payable'] ?? json['payPayable']),
      carrierOrderNumber: json['carrier_order_number']?.toString() ?? '',
      typeStr: json['type_str']?.toString() ?? '',
      payQrCode: json['pay_qr_code']?.toString() ?? '',
    );
  }
}

class TopUpRecordListResponse {
  final List<TopUpRecordItem> list;

  const TopUpRecordListResponse({required this.list});

  factory TopUpRecordListResponse.fromJsonList(List<dynamic> json) {
    return TopUpRecordListResponse(
      list: json
          .whereType<Map>()
          .map(
            (item) => TopUpRecordItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
