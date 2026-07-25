
import 'package:app/models/transaction_inquire_type.dart';

/* TODO
 * 应用启动时从 `redis/get` 拉取的全局配置模型。
 *
 * 这份数据会被多个页面复用：
 * 1. 充值页面使用 `payTypeList` 和 `payAmountList`。
 * 2. 提现页面使用 `payTypeList` 和 `businessConfig.minWithdrawal`。
 * 3. 充值记录页使用 `businessConfig.rechargeExpirationTime`。
 *
 * 统一放进一个模型里，能避免多个页面重复请求和重复解析。
 */
class AppGlobalConfig {
  final List<TransactionInquireTypeItem> payTypeList;
  final List<double> payAmountList;
  final BusinessConfig businessConfig;

  const AppGlobalConfig({
    required this.payTypeList,
    required this.payAmountList,
    required this.businessConfig,
  });

  /// TODO 空配置兜底。
  ///
  /// 当接口失败或应用尚未完成初始化时，页面仍然可以安全读取默认值。
  factory AppGlobalConfig.empty() {
    return const AppGlobalConfig(
      payTypeList: <TransactionInquireTypeItem>[],
      payAmountList: <double>[],
      businessConfig: BusinessConfig(),
    );
  }

  /// TODO 把接口返回的原始 json 转成强类型配置。
  ///
  /// 参数 [json]：
  /// `redis/get` 的 `content` 数据体。
  factory AppGlobalConfig.fromJson(Map<String, dynamic> json) {
    final dynamic rawPayTypeList = json['pay_type'];
    final dynamic rawPayAmountList = json['pay_amount'];
    final dynamic rawBusinessConfig = json['texas_holdem_config'];

    return AppGlobalConfig(
      payTypeList: rawPayTypeList is List
          ? rawPayTypeList
                .whereType<Map>()
                .map(
                  (dynamic item) => TransactionInquireTypeItem.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : <TransactionInquireTypeItem>[],
      payAmountList: _parse_double_list(rawPayAmountList),

      businessConfig: rawBusinessConfig is Map<String, dynamic>
          ? BusinessConfig.fromJson(rawBusinessConfig)
          : rawBusinessConfig is Map
          ? BusinessConfig.fromJson(
              Map<String, dynamic>.from(rawBusinessConfig),
            )
          : const BusinessConfig(),
    );
  }



  /// TODO 兼容接口返回中 number/string 混用的金额数组（pay_amount）。
  static List<double> _parse_double_list(dynamic raw_list) {
    if (raw_list is! List) return <double>[];
    return raw_list
        .map(_parseDouble)
        .where((double item) => item > 0)
        .toList();
  }

  /// TODO 兼容 number/string 的浮点值解析。
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

/* TODO
 * 业务配置。
 *
 * 这部分字段来自 `redis/get.content.texas_holdem_config`。
 */
class BusinessConfig {
  final int rechargeExpirationTime;
  final double minWithdrawal;

  const BusinessConfig({
    this.rechargeExpirationTime = 15,
    this.minWithdrawal = 0,
  });

  /// TODO 把配置节点解析成强类型。
  ///
  /// 参数 [json]：
  /// 后端返回的配置对象。
  factory BusinessConfig.fromJson(Map<String, dynamic> json) {
    return BusinessConfig(
      rechargeExpirationTime: _parseInt(json['recharge_expiration_time'], 15),
      minWithdrawal: _parseDouble(json['min_withdrawal']),
    );
  }

  static int _parseInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
