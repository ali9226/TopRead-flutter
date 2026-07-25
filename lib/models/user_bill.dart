class UserBillItem {
  final int id;
  final String updateTime;
  final double amount;
  final double balance;
  final int type;
  final String serialNumber;

  UserBillItem({
    required this.id,
    required this.updateTime,
    required this.amount,
    required this.balance,
    required this.type,
    required this.serialNumber,
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

  factory UserBillItem.fromJson(Map<String, dynamic> json) {
    return UserBillItem(
      id: _parseInt(json['id']),
      updateTime: json['update_time']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      balance: _parseDouble(json['balance']),
      type: _parseInt(json['type']),
      serialNumber: json['serial_number']?.toString() ?? '',
    );
  }
}

class UserBillListResponse {
  final List<UserBillItem> list;

  UserBillListResponse({required this.list});

  factory UserBillListResponse.fromJsonList(List<dynamic> json) {
    return UserBillListResponse(
      list: json
          .whereType<Map>()
          .map((item) => UserBillItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
