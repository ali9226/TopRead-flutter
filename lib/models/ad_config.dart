// ignore_for_file: non_constant_identifier_names

/// 广告配置。
///
/// 短篇阅读和今日推荐瀑布流的广告配置接口共用该结构。
class AdConfig {
  /// 广告配置记录 ID。
  final String id;

  /// 广告单元 ID。
  final String adsId;

  /// 已展示次数。
  final int showNumber;

  /// 已通知次数。
  final int notificationNumber;

  /// 广告类型。
  final int adsType;

  /// 广告商：1=谷歌广告。
  final int advertisers;

  /// 权重，用于多广告时的优先级排序。
  final int weight;

  /// 广告类型的可读描述。
  final String adsTypeStr;

  /// 广告商的可读描述。
  final String advertisersStr;

  /// 激励视频准备接口返回的唯一标识，用于广告服务器端验证。
  /// `redis/get.ads_ids` 中的非激励广告配置为空字符串。
  final String uuid;

  AdConfig({
    required this.id,
    required this.adsId,
    required this.showNumber,
    required this.notificationNumber,
    required this.adsType,
    required this.advertisers,
    required this.weight,
    required this.adsTypeStr,
    required this.advertisersStr,
    required this.uuid,
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    return AdConfig(
      id: json['id']?.toString() ?? '',
      adsId: json['ads_id']?.toString() ?? '',
      showNumber: _parseInt(json['show_number']),
      notificationNumber: _parseInt(json['notification_number']),
      adsType: _parseInt(json['ads_type']),
      advertisers: _parseInt(json['advertisers']),
      weight: _parseInt(json['weight']),
      adsTypeStr: json['ads_type_str']?.toString() ?? '',
      advertisersStr: json['advertisers_str']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
