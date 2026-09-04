// ignore_for_file: non_constant_identifier_names

import 'package:app/util/device/app_environment.dart';

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

  /// 长篇小说每一章展示插屏广告的概率（0~100）。
  final int ads_read_show_interstitial_ads_probability;

  /// 短篇小说展示插屏广告的概率（0~100）。
  final int ads_short_story_show_interstitial_ads_probability;

  /// 长篇小说解锁30分钟免广告概率（0~100）。
  final int ads_read_video_ad_probability;

  /// 短篇小说视频广告展示概率（0~100）。
  final int ads_short_story_video_ad_probability;

  /// 长篇小说解锁1个小时免广告概率（0~100）。
  final int read_ads_unlock_an_hour;

  /// 长篇小说解锁3个小时免广告概率（0~100）。
  final int read_ads_unlock_three_hour;

  /// 解锁6小时免长篇小说广告时长概率（0~100）。
  final int read_ads_unlock_six_hour;

  /// 瀑布流列表展示广告的概率（0~100）。
  final int waterfall_ad;

  /// 短篇小说列表展示广告的概率（0~100）。
  final int short_story_tab_ad;

  /// 开屏广告展示的概率（0~100）。
  final int splash_screen_ads;

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
    required this.ads_read_show_interstitial_ads_probability,
    required this.ads_short_story_show_interstitial_ads_probability,
    required this.ads_read_video_ad_probability,
    required this.ads_short_story_video_ad_probability,
    required this.read_ads_unlock_an_hour,
    required this.read_ads_unlock_three_hour,
    required this.read_ads_unlock_six_hour,
    required this.waterfall_ad,
    required this.short_story_tab_ad,
    required this.splash_screen_ads,
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
      app_review_status = 2,
      ads_read_show_interstitial_ads_probability = 100,
      ads_short_story_show_interstitial_ads_probability = 100,
      ads_read_video_ad_probability = 100,
      ads_short_story_video_ad_probability = 100,
      read_ads_unlock_an_hour = 0,
      read_ads_unlock_three_hour = 0,
      read_ads_unlock_six_hour = 0,
      waterfall_ad = 0,
      short_story_tab_ad = 0,
      splash_screen_ads = 0;

  /// 从 JSON 解析。
  factory ProjectConfig.from_json(Map<String, dynamic> json) {
    return ProjectConfig(
      id: _parse_int(json['id']),
      ads_switch: _parse_int(json['ads_switch']),
      authorized_login_switch: _parse_int(json['authorized_login_switch']),
      comment_switch: _parse_int(json['comment_switch']),
      online_customer_service_switch: _parse_int(
        json['online_customer_service_switch'],
      ),
      rating_switch: _parse_int(json['rating_switch']),
      creator_switch: _parse_int(json['creator_switch']),
      share_switch: _parse_int(json['share_switch']),
      contact_customer_service_switch: _parse_int(
        json['contact_customer_service_switch'],
      ),
      famous_quote: _parse_string(json['famous_quote']),
      app_review_status: _parse_int(json['app_review_status']),
      ads_read_show_interstitial_ads_probability: _parse_probability(
        json['ads_read_show_interstitial_ads_probability'],
      ),
      ads_short_story_show_interstitial_ads_probability: _parse_probability(
        json['ads_short_story_show_interstitial_ads_probability'],
      ),
      ads_read_video_ad_probability: _parse_probability(
        json['ads_read_video_ad_probability'],
      ),
      ads_short_story_video_ad_probability: _parse_probability(
        json['ads_short_story_video_ad_probability'],
      ),
      read_ads_unlock_an_hour: _parse_probability(
        json['read_ads_unlock_an_hour'],
      ),
      read_ads_unlock_three_hour: _parse_probability(
        json['read_ads_unlock_three_hour'],
      ),
      read_ads_unlock_six_hour: _parse_probability(
        json['read_ads_unlock_six_hour'],
      ),
      waterfall_ad: _parse_probability(
        json['waterfall_ad'],
      ),
      short_story_tab_ad: _parse_probability(
        json['short_story_tab_ad'],
      ),
      splash_screen_ads: _parse_probability(
        json['splash_screen_ads'],
      ),
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

  /// 安全解析概率值（0~100）。
  ///
  /// 超出范围时自动钳制到 0 或 100。
  static int _parse_probability(dynamic value) {
    final int parsed = _parse_int(value);
    return parsed.clamp(0, 100);
  }

  /// 判断指定开关是否在当前平台启用。
  ///
  /// [switch_value] 为开关的 int 值。
  /// 返回 true 表示当前平台应该启用该功能。
  static bool is_enabled(int switch_value) {
    return is_enabled_for_environment(switch_value, currentEnvironment);
  }

  /// 判断指定开关是否在目标运行环境启用。
  ///
  /// [switch_value] 为后端开关值。
  /// [environment] 为需要判断的运行环境。
  /// 浏览器环境不区分桌面、Android 浏览器和 iOS 浏览器，统一按网页处理。
  static bool is_enabled_for_environment(
    int switch_value,
    AppEnvironment environment,
  ) {
    final bool is_android = environment == AppEnvironment.android;
    final bool is_ios = environment == AppEnvironment.ios;
    final bool is_web =
        environment == AppEnvironment.desktopBrowser ||
        environment == AppEnvironment.androidBrowser ||
        environment == AppEnvironment.iosBrowser;

    switch (switch_value) {
      case SwitchValue.off:
        return false;
      case SwitchValue.on:
        return true;
      case SwitchValue.android_only:
        return is_android;
      case SwitchValue.ios_only:
        return is_ios;
      case SwitchValue.web_only:
        return is_web;
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
  bool get is_creator_enabled => is_enabled(creator_switch);

  /// 判断广告是否启用。
  bool get is_ads_enabled => is_enabled(ads_switch);

  /// 判断授权登录是否启用。
  bool get is_authorized_login_enabled => is_enabled(authorized_login_switch);

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
  bool get is_apple_review_mode => isIOSApp && app_review_status == 1;
}
