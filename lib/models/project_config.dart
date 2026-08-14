// ignore_for_file: non_constant_identifier_names

import 'dart:io';

/// 平台开关值枚举。
///
/// 对应后端 `project_config` 中 `_switch` 字段的 int 值。
class SwitchValue {
  /// 都不开启。
  static const int off = 1;

  /// 都开启。
  static const int on = 2;

  /// 仅安卓开启。
  static const int android_only = 3;

  /// 仅 iOS 开启。
  static const int ios_only = 4;

  /// 仅网页开启。
  static const int web_only = 5;
}

/// 项目配置模型。
///
/// 对应 `redis/get` 接口返回的 `project_config` 字段。
class ProjectConfig {
  /// 配置 ID。
  final int id;

  /// 广告开关。
  final int ads_switch;

  /// 授权登录开关。
  final int authorized_login_switch;

  /// 评论开关。
  final int comment_switch;

  /// 在线客服开关。
  final int online_customer_service_switch;

  /// 评分开关。
  final int rating_switch;

  /// 创作者入口开关。
  final int creator_switch;

  /// 分享开关。
  final int share_switch;

  /// 联系客服开关。
  final int contact_customer_service_switch;

  /// 名言内容。
  final String famous_quote;

  /// 苹果审核状态。1 = 审核中，2 = 审核通过。
  final int app_review_status;

  const ProjectConfig({
    required this.id,
    required this.ads_switch,
    required this.authorized_login_switch,
    required this.comment_switch,
    required this.online_customer_service_switch,
    required this.rating_switch,
    required this.creator_switch,
    required this.share_switch,
    required this.contact_customer_service_switch,
    required this.famous_quote,
    required this.app_review_status,
  });

  /// 空配置兜底。
  const ProjectConfig.empty()
      : id = 0,
        ads_switch = SwitchValue.on,
        authorized_login_switch = SwitchValue.on,
        comment_switch = SwitchValue.on,
        online_customer_service_switch = SwitchValue.on,
        rating_switch = SwitchValue.on,
        creator_switch = SwitchValue.on,
        share_switch = SwitchValue.on,
        contact_customer_service_switch = SwitchValue.on,
        famous_quote = '',
        app_review_status = 2;

  /// 从 JSON 解析。
  factory ProjectConfig.from_json(Map<String, dynamic> json) {
    return ProjectConfig(
      id: _parse_int(json['id']),
      ads_switch: _parse_int(json['ads_switch']),
      authorized_login_switch: _parse_int(json['authorized_login_switch']),
      comment_switch: _parse_int(json['comment_switch']),
      online_customer_service_switch:
          _parse_int(json['online_customer_service_switch']),
      rating_switch: _parse_int(json['rating_switch']),
      creator_switch: _parse_int(json['creator_switch']),
      share_switch: _parse_int(json['share_switch']),
      contact_customer_service_switch:
          _parse_int(json['contact_customer_service_switch']),
      famous_quote: _parse_string(json['famous_quote']),
      app_review_status: _parse_int(json['app_review_status']),
    );
  }

  /// 安全解析 int 类型。
  static int _parse_int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// 安全解析字符串类型。
  static String _parse_string(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// 判断指定开关是否在当前平台启用。
  ///
  /// [switch_value] 为开关的 int 值。
  /// 返回 true 表示当前平台应该启用该功能。
  static bool is_enabled(int switch_value) {
    switch (switch_value) {
      case SwitchValue.off:
        return false;
      case SwitchValue.on:
        return true;
      case SwitchValue.android_only:
        return Platform.isAndroid;
      case SwitchValue.ios_only:
        return Platform.isIOS;
      case SwitchValue.web_only:
        return false; // Flutter 应用非网页环境
      default:
        return true;
    }
  }

  /// 判断创作者入口是否显示。
  ///
  /// 特殊逻辑：
  /// - 1: 都不显示
  /// - 2: 都显示
  /// - 3: iOS 和网页不显示（仅安卓显示）
  /// - 4: 安卓和网页不显示（仅 iOS 显示）
  /// - 5: 安卓和 iOS 不显示（仅网页显示）
  bool get is_creator_enabled {
    switch (creator_switch) {
      case SwitchValue.off:
        return false;
      case SwitchValue.on:
        return true;
      case SwitchValue.android_only:
        return Platform.isAndroid;
      case SwitchValue.ios_only:
        return Platform.isIOS;
      case SwitchValue.web_only:
        return false; // Flutter 应用非网页环境
      default:
        return true;
    }
  }

  /// 判断广告是否启用。
  bool get is_ads_enabled => is_enabled(ads_switch);

  /// 判断授权登录是否启用。
  bool get is_authorized_login_enabled =>
      is_enabled(authorized_login_switch);

  /// 判断评论是否启用。
  bool get is_comment_enabled => is_enabled(comment_switch);

  /// 判断在线客服是否启用。
  bool get is_online_customer_service_enabled =>
      is_enabled(online_customer_service_switch);

  /// 判断评分是否启用。
  bool get is_rating_enabled => is_enabled(rating_switch);

  /// 判断分享是否启用。
  bool get is_share_enabled => is_enabled(share_switch);

  /// 判断联系客服是否启用。
  bool get is_contact_customer_service_enabled =>
      is_enabled(contact_customer_service_switch);

  /// 判断是否处于苹果审核模式。
  ///
  /// 苹果设备且 app_review_status = 1（审核中）时返回 true，
  /// 此时快捷登录需要使用符合 Apple HIG 规范的按钮样式。
  bool get is_apple_review_mode =>
      Platform.isIOS && app_review_status == 1;
}
