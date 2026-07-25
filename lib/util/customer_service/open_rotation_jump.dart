// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/models/rotation.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

/// 客服支持的平台类型。
enum CustomerServicePlatform {
  unknown,
  telegram,
  whatsapp,
  instagram,
  twitter_x,
  tiktok,
  facebook,
  youtube,
  sharechat,
  snapchat,
}

/// 通过客服配置打开对应跳转目标。
Future<void> open_rotation_jump(Rotation rotation) async {
  final CustomerServicePlatform platform = _resolve_customer_service_platform(
    rotation,
  );

  switch (platform) {
    case CustomerServicePlatform.telegram:
      await _open_telegram_chat(rotation.jump);
      return;
    case CustomerServicePlatform.whatsapp:
      await _open_whatsapp_chat(rotation.jump);
      return;
    case CustomerServicePlatform.instagram:
      await _open_instagram_target(rotation.jump);
      return;
    case CustomerServicePlatform.twitter_x:
      await _open_twitter_x_target(rotation.jump);
      return;
    case CustomerServicePlatform.tiktok:
      await _open_tiktok_target(rotation.jump);
      return;
    case CustomerServicePlatform.facebook:
      await _open_facebook_target(rotation.jump);
      return;
    case CustomerServicePlatform.youtube:
      await _open_youtube_target(rotation.jump);
      return;
    case CustomerServicePlatform.sharechat:
      await _open_sharechat_target(rotation.jump);
      return;
    case CustomerServicePlatform.snapchat:
      await _open_snapchat_target(rotation.jump);
      return;
    case CustomerServicePlatform.unknown:
      await _open_default_target(rotation);
      return;
  }
}

/// 未识别到具体平台时，按旧规则兜底。
Future<void> _open_default_target(Rotation rotation) async {
  switch (rotation.format) {
    case 1:
    case 2:
    case 3:
      await _open_external_url(rotation.jump);
      return;
    default:
      await _open_external_url(rotation.jump);
  }
}

/// 统一识别当前客服项对应的平台。
CustomerServicePlatform _resolve_customer_service_platform(Rotation rotation) {
  switch (rotation.format) {
    case 4:
      return CustomerServicePlatform.telegram;
    case 5:
      return CustomerServicePlatform.whatsapp;
    case 6:
      return CustomerServicePlatform.instagram;
    case 7:
      return CustomerServicePlatform.twitter_x;
    case 8:
      return CustomerServicePlatform.tiktok;
    case 9:
      return CustomerServicePlatform.facebook;
    case 10:
      return CustomerServicePlatform.youtube;
    case 11:
      return CustomerServicePlatform.sharechat;
    case 12:
      return CustomerServicePlatform.snapchat;
  }

  final String title = rotation.title.trim().toLowerCase();
  final String represent = rotation.represent.trim().toLowerCase();
  final String note = rotation.note.trim().toLowerCase();
  final String jump = rotation.jump.trim().toLowerCase();
  final Uri? uri = Uri.tryParse(rotation.jump.trim());
  final String host = uri?.host.toLowerCase() ?? '';
  final String scheme = uri?.scheme.toLowerCase() ?? '';

  final List<String> matched_values = <String>[
    title,
    represent,
    note,
    jump,
    host,
    scheme,
  ];

  if (_contains_exact_platform_name(
    values: <String>[title, represent, note, scheme],
    alias_list: <String>['tg'],
  )) {
    return CustomerServicePlatform.telegram;
  }
  if (_contains_exact_platform_name(
    values: <String>[title, represent, note, scheme],
    alias_list: <String>['x'],
  )) {
    return CustomerServicePlatform.twitter_x;
  }
  if (_contains_exact_platform_name(
    values: <String>[title, represent, note, scheme],
    alias_list: <String>['fb'],
  )) {
    return CustomerServicePlatform.facebook;
  }

  if (_contains_any_alias(matched_values, _telegram_alias_list)) {
    return CustomerServicePlatform.telegram;
  }
  if (_contains_any_alias(matched_values, _whatsapp_alias_list)) {
    return CustomerServicePlatform.whatsapp;
  }
  if (_contains_any_alias(matched_values, _instagram_alias_list)) {
    return CustomerServicePlatform.instagram;
  }
  if (_contains_any_alias(matched_values, _twitter_x_alias_list)) {
    return CustomerServicePlatform.twitter_x;
  }
  if (_contains_any_alias(matched_values, _tiktok_alias_list)) {
    return CustomerServicePlatform.tiktok;
  }
  if (_contains_any_alias(matched_values, _facebook_alias_list)) {
    return CustomerServicePlatform.facebook;
  }
  if (_contains_any_alias(matched_values, _youtube_alias_list)) {
    return CustomerServicePlatform.youtube;
  }
  if (_contains_any_alias(matched_values, _sharechat_alias_list)) {
    return CustomerServicePlatform.sharechat;
  }
  if (_contains_any_alias(matched_values, _snapchat_alias_list)) {
    return CustomerServicePlatform.snapchat;
  }

  return CustomerServicePlatform.unknown;
}

/// 判断文本是否与平台短别名完全相等。
bool _contains_exact_platform_name({
  required List<String> values,
  required List<String> alias_list,
}) {
  for (final String value in values) {
    if (value.isEmpty) {
      continue;
    }

    if (alias_list.contains(value)) {
      return true;
    }
  }

  return false;
}

/// 判断文本列表中是否包含任一平台别名。
bool _contains_any_alias(List<String> values, List<String> alias_list) {
  for (final String value in values) {
    if (value.isEmpty) {
      continue;
    }

    for (final String alias in alias_list) {
      if (value.contains(alias)) {
        return true;
      }
    }
  }

  return false;
}

/// 外部浏览器打开普通链接。
Future<void> _open_external_url(String url) async {
  final String normalized_url = url.trim();
  if (normalized_url.isEmpty) {
    showBottomTip('Link is empty');
    return;
  }

  final Uri? uri = Uri.tryParse(normalized_url);
  if (uri == null) {
    showBottomTip('Invalid link');
    return;
  }

  final bool launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    showBottomTip('Failed to open link');
  }
}

/// 优先打开 Telegram App，未安装时回退浏览器。
Future<void> _open_telegram_chat(String telegram_value) async {
  final String telegram_account = _extract_telegram_account(telegram_value);
  if (telegram_account.isEmpty) {
    showBottomTip('Telegram account is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse('tg://resolve?domain=$telegram_account'),
    browser_uri: Uri.parse('https://t.me/$telegram_account'),
    error_message: 'Failed to open Telegram',
  );
}

/// 优先打开 WhatsApp App，未安装时回退浏览器。
Future<void> _open_whatsapp_chat(String whatsapp_value) async {
  final String whatsapp_phone = _extract_whatsapp_phone(whatsapp_value);
  final String whatsapp_text = _extract_query_parameter(
    whatsapp_value,
    key: 'text',
  );

  if (whatsapp_phone.isEmpty) {
    showBottomTip('WhatsApp phone is empty');
    return;
  }

  final String encoded_text = Uri.encodeComponent(whatsapp_text);
  final String app_uri_string = whatsapp_text.isEmpty
      ? 'whatsapp://send?phone=$whatsapp_phone'
      : 'whatsapp://send?phone=$whatsapp_phone&text=$encoded_text';
  final String browser_uri_string = whatsapp_text.isEmpty
      ? 'https://wa.me/$whatsapp_phone'
      : 'https://wa.me/$whatsapp_phone?text=$encoded_text';

  await _open_app_or_browser(
    app_uri: Uri.parse(app_uri_string),
    browser_uri: Uri.parse(browser_uri_string),
    error_message: 'Failed to open WhatsApp',
  );
}

/// 优先打开 Instagram App，未安装时回退浏览器。
Future<void> _open_instagram_target(String instagram_value) async {
  final String instagram_username = _extract_instagram_username(
    instagram_value,
  );
  if (instagram_username.isEmpty) {
    showBottomTip('Instagram username is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse('instagram://user?username=$instagram_username'),
    browser_uri: Uri.parse('https://www.instagram.com/$instagram_username/'),
    error_message: 'Failed to open Instagram',
  );
}

/// 优先打开 X / Twitter App，未安装时回退浏览器。
Future<void> _open_twitter_x_target(String twitter_value) async {
  final String twitter_username = _extract_social_username(
    twitter_value,
    host_keywords: _twitter_x_alias_list,
  );
  if (twitter_username.isEmpty) {
    showBottomTip('X account is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse('twitter://user?screen_name=$twitter_username'),
    browser_uri: Uri.parse('https://x.com/$twitter_username'),
    error_message: 'Failed to open X',
  );
}

/// 优先打开 TikTok App，未安装时回退浏览器。
Future<void> _open_tiktok_target(String tiktok_value) async {
  final String tiktok_username = _extract_tiktok_username(tiktok_value);
  if (tiktok_username.isEmpty) {
    showBottomTip('TikTok account is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse('snssdk1233://user/profile/$tiktok_username'),
    browser_uri: Uri.parse('https://www.tiktok.com/@$tiktok_username'),
    error_message: 'Failed to open TikTok',
  );
}

/// 优先打开 Facebook App，未安装时回退浏览器。
Future<void> _open_facebook_target(String facebook_value) async {
  final String facebook_target = _extract_social_username(
    facebook_value,
    host_keywords: _facebook_alias_list,
  );
  if (facebook_target.isEmpty) {
    showBottomTip('Facebook target is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse(
      'fb://facewebmodal/f?href=https://www.facebook.com/$facebook_target',
    ),
    browser_uri: Uri.parse('https://www.facebook.com/$facebook_target'),
    error_message: 'Failed to open Facebook',
  );
}

/// 优先打开 YouTube App，未安装时回退浏览器。
Future<void> _open_youtube_target(String youtube_value) async {
  final String youtube_id = _extract_youtube_video_id(youtube_value);
  if (youtube_id.isNotEmpty) {
    await _open_app_or_browser(
      app_uri: Uri.parse('vnd.youtube://$youtube_id'),
      browser_uri: Uri.parse('https://www.youtube.com/watch?v=$youtube_id'),
      error_message: 'Failed to open YouTube',
    );
    return;
  }

  final String youtube_target = _extract_youtube_target(youtube_value);
  if (youtube_target.isEmpty) {
    showBottomTip('YouTube target is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse('youtube://www.youtube.com/$youtube_target'),
    browser_uri: Uri.parse('https://www.youtube.com/$youtube_target'),
    error_message: 'Failed to open YouTube',
  );
}

/// 优先打开 ShareChat App，未安装时回退浏览器。
Future<void> _open_sharechat_target(String sharechat_value) async {
  final Uri? sharechat_browser_uri = _build_browser_uri_from_value(
    value: sharechat_value,
    prefix: 'https://sharechat.com/',
  );
  if (sharechat_browser_uri == null) {
    showBottomTip('ShareChat link is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse('sharechat://open'),
    browser_uri: sharechat_browser_uri,
    error_message: 'Failed to open ShareChat',
  );
}

/// 优先打开 Snapchat App，未安装时回退浏览器。
Future<void> _open_snapchat_target(String snapchat_value) async {
  final String snapchat_username = _extract_social_username(
    snapchat_value,
    host_keywords: _snapchat_alias_list,
  );
  if (snapchat_username.isEmpty) {
    showBottomTip('Snapchat username is empty');
    return;
  }

  await _open_app_or_browser(
    app_uri: Uri.parse('snapchat://add/$snapchat_username'),
    browser_uri: Uri.parse('https://www.snapchat.com/add/$snapchat_username'),
    error_message: 'Failed to open Snapchat',
  );
}

/// 统一封装“先打开 App，失败后回退浏览器”的流程。
Future<void> _open_app_or_browser({
  required Uri app_uri,
  required Uri browser_uri,
  required String error_message,
}) async {
  if (!kIsWeb && await canLaunchUrl(app_uri)) {
    final bool launched = await launchUrl(
      app_uri,
      mode: LaunchMode.externalApplication,
    );
    if (launched) {
      return;
    }
  }

  final bool browser_launched = await launchUrl(
    browser_uri,
    mode: LaunchMode.externalApplication,
  );
  if (!browser_launched) {
    showBottomTip(error_message);
  }
}

/// 兼容账号、@账号、完整 t.me 链接三种输入。
String _extract_telegram_account(String telegram_value) {
  final String normalized_value = telegram_value.trim();
  if (normalized_value.isEmpty) {
    return '';
  }

  final Uri? uri = Uri.tryParse(normalized_value);
  if (uri != null && uri.host.contains('t.me')) {
    final List<String> path_segments = uri.pathSegments
        .where((String item) => item.trim().isNotEmpty)
        .toList();
    if (path_segments.isNotEmpty) {
      return path_segments.first.trim();
    }
  }

  if (normalized_value.startsWith('@')) {
    return normalized_value.substring(1).trim();
  }

  return normalized_value;
}

/// 解析 WhatsApp 使用的手机号。
String _extract_whatsapp_phone(String whatsapp_value) {
  final String normalized_value = whatsapp_value.trim();
  if (normalized_value.isEmpty) {
    return '';
  }

  final Uri? uri = Uri.tryParse(normalized_value);
  if (uri != null) {
    if (uri.host.contains('wa.me')) {
      final List<String> path_segments = uri.pathSegments
          .where((String item) => item.trim().isNotEmpty)
          .toList();
      if (path_segments.isNotEmpty) {
        return _normalize_whatsapp_phone(path_segments.first);
      }
    }

    final String phone = uri.queryParameters['phone'] ?? '';
    if (phone.isNotEmpty) {
      return _normalize_whatsapp_phone(phone);
    }
  }

  return _normalize_whatsapp_phone(normalized_value);
}

/// 统一把 WhatsApp 手机号清洗为国际数字格式。
String _normalize_whatsapp_phone(String phone) {
  return phone.replaceAll(RegExp(r'[^0-9]'), '');
}

/// 解析 Instagram 用户名。
String _extract_instagram_username(String instagram_value) {
  return _extract_social_username(
    instagram_value,
    host_keywords: _instagram_alias_list,
  );
}

/// 解析 TikTok 用户名。
String _extract_tiktok_username(String tiktok_value) {
  final String username = _extract_social_username(
    tiktok_value,
    host_keywords: _tiktok_alias_list,
  );
  if (username.startsWith('@')) {
    return username.substring(1);
  }
  return username;
}

/// 提取常见社交平台使用的用户名。
String _extract_social_username(
  String value, {
  required List<String> host_keywords,
}) {
  final String normalized_value = value.trim();
  if (normalized_value.isEmpty) {
    return '';
  }

  final Uri? uri = Uri.tryParse(normalized_value);
  if (uri != null &&
      uri.host.isNotEmpty &&
      host_keywords.any(
        (String keyword) => uri.host.toLowerCase().contains(keyword),
      )) {
    final List<String> path_segments = uri.pathSegments
        .where((String item) => item.trim().isNotEmpty)
        .toList();
    if (path_segments.isNotEmpty) {
      return path_segments.last.trim();
    }
  }

  if (normalized_value.startsWith('@')) {
    return normalized_value.substring(1).trim();
  }

  return normalized_value;
}

/// 提取指定链接中的查询参数。
String _extract_query_parameter(String url, {required String key}) {
  final Uri? uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return '';
  }
  return uri.queryParameters[key]?.trim() ?? '';
}

/// 提取 YouTube 视频 id。
String _extract_youtube_video_id(String youtube_value) {
  final String normalized_value = youtube_value.trim();
  if (normalized_value.isEmpty) {
    return '';
  }

  final Uri? uri = Uri.tryParse(normalized_value);
  if (uri == null) {
    return '';
  }

  if (uri.host.contains('youtu.be')) {
    final List<String> path_segments = uri.pathSegments
        .where((String item) => item.trim().isNotEmpty)
        .toList();
    if (path_segments.isNotEmpty) {
      return path_segments.first.trim();
    }
  }

  if (uri.host.contains('youtube.com')) {
    final String video_id = uri.queryParameters['v']?.trim() ?? '';
    if (video_id.isNotEmpty) {
      return video_id;
    }
  }

  return '';
}

/// 提取 YouTube 页面路径。
String _extract_youtube_target(String youtube_value) {
  final String normalized_value = youtube_value.trim();
  if (normalized_value.isEmpty) {
    return '';
  }

  final Uri? uri = Uri.tryParse(normalized_value);
  if (uri != null && uri.host.contains('youtube.com')) {
    final String path = uri.path.startsWith('/')
        ? uri.path.substring(1)
        : uri.path;
    return path;
  }

  if (normalized_value.startsWith('@')) {
    return normalized_value;
  }

  return normalized_value;
}

/// 根据原始值生成外部浏览器链接。
Uri? _build_browser_uri_from_value({
  required String value,
  required String prefix,
}) {
  final String normalized_value = value.trim();
  if (normalized_value.isEmpty) {
    return null;
  }

  final Uri? uri = Uri.tryParse(normalized_value);
  if (uri != null && uri.hasScheme) {
    return uri;
  }

  return Uri.tryParse('$prefix$normalized_value');
}

const List<String> _telegram_alias_list = <String>['telegram', 'tg', 't.me'];

const List<String> _whatsapp_alias_list = <String>['whatsapp', 'wa.me'];

const List<String> _instagram_alias_list = <String>['instagram'];

const List<String> _twitter_x_alias_list = <String>[
  'twitter',
  'x.com',
  'mobile.twitter.com',
];

const List<String> _tiktok_alias_list = <String>['tiktok', 'snssdk1233'];

const List<String> _facebook_alias_list = <String>['facebook', 'fb'];

const List<String> _youtube_alias_list = <String>[
  'youtube',
  'youtu.be',
  'vnd.youtube',
];

const List<String> _sharechat_alias_list = <String>['sharechat'];

const List<String> _snapchat_alias_list = <String>['snapchat'];
