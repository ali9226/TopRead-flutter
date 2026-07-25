/* TODO
 * 充值 / 提现类型查询的通用模型。
 *
 * 提现后续也会复用 data_list 结构，
 * 只是提现场景可能没有 amount_list，所以这里把 amount_list 设计成可空缺的普通数组。
 */
class TransactionInquireTypeItem {
  final int id;
  final String label;
  final String languageVariables;

  TransactionInquireTypeItem({
    required this.id,
    required this.label,
    required this.languageVariables,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  factory TransactionInquireTypeItem.fromJson(Map<String, dynamic> json) {
    return TransactionInquireTypeItem(
      id: _parseInt(json['id']),
      label: json['label']?.toString() ?? '',
      languageVariables: json['language_variables']?.toString() ?? '',
    );
  }
}

class TransactionInquireTypeResponse {
  final List<TransactionInquireTypeItem> dataList;
  final List<double> amountList;
  final double minWithdrawal;

  TransactionInquireTypeResponse({
    required this.dataList,
    required this.amountList,
    this.minWithdrawal = 0,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory TransactionInquireTypeResponse.fromJson(Map<String, dynamic> json) {
    final rawDataList = json['data_list'];
    final rawAmountList = json['amount_list'];

    return TransactionInquireTypeResponse(
      dataList: rawDataList is List
          ? rawDataList
                .whereType<Map>()
                .map(
                  (item) => TransactionInquireTypeItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <TransactionInquireTypeItem>[],
      amountList: rawAmountList is List
          ? rawAmountList.map(_parseDouble).where((item) => item > 0).toList()
          : <double>[],
      minWithdrawal: _parseDouble(json['min_withdrawal']),
    );
  }
}
