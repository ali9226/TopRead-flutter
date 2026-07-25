// ignore_for_file: non_constant_identifier_names

/* TODO
 * app_config/inquire 接口返回的配置模型。
 *
 * 包含安卓和 iOS 的最低/最高版本号、下载链接、更新说明等信息。
 * 用于启动时判断是否需要强制升级或可选升级。
 */
class AppConfigInquire {
  /// 数据库主键 id。
  final int id;

  /// 安卓最低版本号（低于此版本必须强制升级）。
  final String min_android_version;

  /// 安卓最高版本号（低于此版本可选升级）。
  final String max_android_version;

  /// 安卓下载链接（点击升级按钮后跳转）。
  final String download_link;

  /// 下载页海报图地址。
  final String download_poster;

  /// 安卓应用市场更新地址。
  final String update_address;

  /// 更新内容说明文案。
  final String update_content;

  /// 更新时间。
  final String update_time;

  /// 更新操作人 id。
  final int update_user_id;

  /// 是否校验 ip。
  final int checkout_ip;

  /// iOS 应用市场更新地址（点击升级按钮后跳转）。
  final String ios_update_address;

  /// iOS 最低版本号（低于此版本必须强制升级）。
  final String min_ios_version;

  /// iOS 最高版本号（低于此版本可选升级）。
  final String max_ios_version;

  const AppConfigInquire({
    required this.id,
    required this.min_android_version,
    required this.max_android_version,
    required this.download_link,
    required this.download_poster,
    required this.update_address,
    required this.update_content,
    required this.update_time,
    required this.update_user_id,
    required this.checkout_ip,
    required this.ios_update_address,
    required this.min_ios_version,
    required this.max_ios_version,
  });

  /// 空配置兜底，接口失败时使用。
  factory AppConfigInquire.empty() {
    return const AppConfigInquire(
      id: 0,
      min_android_version: '',
      max_android_version: '',
      download_link: '',
      download_poster: '',
      update_address: '',
      update_content: '',
      update_time: '',
      update_user_id: 0,
      checkout_ip: 0,
      ios_update_address: '',
      min_ios_version: '',
      max_ios_version: '',
    );
  }

  /// 把接口返回的原始 json 转成强类型模型。
  ///
  /// 参数 [json]：
  /// `app_config/inquire` 的 `content` 数据体。
  factory AppConfigInquire.fromJson(Map<String, dynamic> json) {
    return AppConfigInquire(
      id: _parseInt(json['id']),
      min_android_version: json['min_android_version']?.toString() ?? '',
      max_android_version: json['max_android_version']?.toString() ?? '',
      download_link: json['download_link']?.toString() ?? '',
      download_poster: json['download_poster']?.toString() ?? '',
      update_address: json['update_address']?.toString() ?? '',
      update_content: json['update_content']?.toString() ?? '',
      update_time: json['update_time']?.toString() ?? '',
      update_user_id: _parseInt(json['update_user_id']),
      checkout_ip: _parseInt(json['checkout_ip']),
      ios_update_address: json['ios_update_address']?.toString() ?? '',
      min_ios_version: json['min_ios_version']?.toString() ?? '',
      max_ios_version: json['max_ios_version']?.toString() ?? '',
    );
  }

  /// 兼容 number/string 的整数解析。
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
