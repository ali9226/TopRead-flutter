// ignore_for_file: non_constant_identifier_names

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app/models/language_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/storage_util/index.dart';

/* TODO
 * 语言工具。
 *
 * 负责决定应用启动时应使用的语种，并优先尊重用户本地缓存。
 */
class LanguageUtil {
  const LanguageUtil._();

  /// TODO 本地翻译资源中的语种代码列表。
  static List<String> _asset_language_code_list = <String>[];

  /// TODO 初始化本地翻译资源语种列表。
  static Future<void> load_asset_language_code_list() async {
    final AssetManifest asset_manifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> next_asset_language_code_list =
        asset_manifest
            .listAssets()
            .where((String item) => item.startsWith('assets/i18n/'))
            .where((String item) => item.endsWith('.json'))
            .map((String item) => item.split('/').last.replaceAll('.json', ''))
            .map((String item) => item.trim().toLowerCase())
            .where((String item) => item.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    _asset_language_code_list = next_asset_language_code_list;
  }

  /// TODO 获取本地翻译资源语种列表。
  static List<String> get asset_language_code_list =>
      List<String>.from(_asset_language_code_list);

  /// TODO 生成 `EasyLocalization` 需要的 locale 列表。
  static List<Locale> get supported_locales {
    return _asset_language_code_list
        .map((String item) => Locale(item))
        .toList();
  }

  /* TODO 获取当前应该使用的语言代码。 */
  static Future<String> get_language() async {
    final String? cache_language = await StorageUtil.getData(
      LanguageStore.language_key,
    );
    final LanguageInfo? cache_language_info = _find_supported_language(
      cache_language,
    );
    if (cache_language_info != null) {
      return cache_language_info.language_code;
    }

    final List<Locale> locales = PlatformDispatcher.instance.locales.isNotEmpty
        ? PlatformDispatcher.instance.locales
        : <Locale>[PlatformDispatcher.instance.locale];

    for (final Locale locale in locales) {
      final LanguageInfo? current_language_info = _find_supported_language(
        locale.languageCode,
      );
      if (current_language_info != null) {
        return current_language_info.language_code;
      }
    }

    return get_fallback_language_code();
  }

  /* TODO
   * 把语种代码映射为后端约定的 language 数字 ID。
   */
  static Future<int> get_language_id() async {
    final String language_code = (await get_language()).toLowerCase();
    final LanguageInfo? current_language_info = _find_supported_language(
      language_code,
    );
    if (current_language_info != null && current_language_info.id > 0) {
      return current_language_info.id;
    }

    final LanguageStore? language_store = _get_language_store();
    final LanguageInfo? default_language_info =
        language_store?.default_language_info.value;
    if (default_language_info != null && default_language_info.id > 0) {
      return default_language_info.id;
    }

    return 1;
  }

  /// TODO 获取默认回退语种代码。
  static String get_fallback_language_code() {
    final LanguageStore? language_store = _get_language_store();
    if (language_store != null) {
      return language_store.default_language_code;
    }

    if (_asset_language_code_list.isNotEmpty) {
      return _asset_language_code_list.first;
    }

    return 'en';
  }

  /// TODO 根据语种代码获取请求头 locale。
  static String resolve_locale_code_by_language(String language_code) {
    final LanguageInfo? current_language_info = _find_supported_language(
      language_code,
    );
    if (current_language_info != null &&
        current_language_info.code.isNotEmpty) {
      return current_language_info.code;
    }
    return get_fallback_language_code();
  }

  /// TODO 获取当前语种的展示名称。
  static String get_language_name(String language_code) {
    final LanguageInfo? current_language_info = _find_supported_language(
      language_code,
    );
    if (current_language_info != null &&
        current_language_info.title.isNotEmpty) {
      return current_language_info.title;
    }
    return _normalize_language_code(language_code).toUpperCase();
  }

  /// TODO 获取当前语种的 app 标题。
  static String get_language_title(String language_code) {
    final LanguageInfo? current_language_info = _find_supported_language(
      language_code,
    );
    if (current_language_info != null &&
        current_language_info.title.isNotEmpty) {
      return current_language_info.title;
    }
    return get_language_name(get_fallback_language_code());
  }

  /// TODO 获取当前语种图标资源路径。
  static String get_language_asset_image(String language_code) {
    final String normalized_language_code = _normalize_language_code(
      language_code,
    );
    if (_asset_language_code_list.contains(normalized_language_code)) {
      return 'assets/img/$normalized_language_code.png';
    }
    return 'assets/img/${get_fallback_language_code()}.png';
  }

  /// TODO 判断当前语种是否有可用的本地图标资源。
  static bool has_language_asset_image(String language_code) {
    final String normalized_language_code = _normalize_language_code(
      language_code,
    );
    return _asset_language_code_list.contains(normalized_language_code);
  }

  /// TODO 获取当前语种对应的接口图标地址。
  static String get_language_icon_url(String language_code) {
    final LanguageInfo? current_language_info = _find_supported_language(
      language_code,
    );
    if (current_language_info != null && current_language_info.icon.isNotEmpty) {
      return current_language_info.icon;
    }
    return '';
  }

  /// TODO 判断当前语种是否为 CJK（中日韩）语系。
  ///
  /// CJK 语系字符宽度均匀、视觉密度高，布局上可以使用更紧凑的间距和更大的字号。
  /// 非 CJK 语系（如英语、斯瓦希里语等拉丁字母语种）单词宽度更大，
  /// 需要更小的字号和更紧凑的间距以避免溢出。
  static bool is_cjk_language(String language_code) {
    final String normalized = _normalize_language_code(language_code);
    return normalized.startsWith('zh') ||
        normalized.startsWith('ja') ||
        normalized.startsWith('ko');
  }

  /// TODO 判断语种代码是否属于应用允许的展示范围。
  static bool is_supported_language_code(String language_code) {
    final String normalized_language_code = _normalize_language_code(
      language_code,
    );
    if (normalized_language_code.isEmpty) {
      return false;
    }
    return _asset_language_code_list.contains(normalized_language_code);
  }

  /// TODO 断网且接口缓存不可用时使用的离线兜底语种代码。
  static List<String> get offline_fallback_language_code_list {
    final List<String> fallback_list = <String>['en', 'sw']
        .where((String item) => _asset_language_code_list.contains(item))
        .toList();
    if (fallback_list.isNotEmpty) {
      return fallback_list;
    }
    return _asset_language_code_list.isNotEmpty
        ? List<String>.from(_asset_language_code_list.take(2))
        : <String>['en'];
  }

  /// TODO 断网且接口缓存不可用时使用的离线兜底图标路径。
  static String get_offline_fallback_language_asset_image(
    String language_code,
  ) {
    final String normalized_language_code = _normalize_language_code(
      language_code,
    );
    if (offline_fallback_language_code_list.contains(normalized_language_code)) {
      return 'assets/img/$normalized_language_code.png';
    }
    return get_language_asset_image(get_fallback_language_code());
  }

  static LanguageInfo? _find_supported_language(String? language_code) {
    final String normalized_language_code = _normalize_language_code(
      language_code ?? '',
    );
    if (normalized_language_code.isEmpty) {
      return null;
    }

    final LanguageStore? language_store = _get_language_store();
    if (language_store != null) {
      final LanguageInfo? current_language_info = language_store
          .find_supported_language_by_code(normalized_language_code);
      if (current_language_info != null) {
        return current_language_info;
      }
    }

    if (_asset_language_code_list.contains(normalized_language_code)) {
      // TODO 如果尚未加载远程语种列表，提供常见语种的初始 ID 映射，避免首次请求携带 language_id=1。
      int initial_id = 0;
      if (normalized_language_code == 'en') {
        initial_id = 1;
      } else if (normalized_language_code == 'zh') {
        initial_id = 2;
      }

      return LanguageInfo(
        id: initial_id,
        title: normalized_language_code.toUpperCase(),
        code: normalized_language_code,
      );
    }

    return null;
  }

  static LanguageStore? _get_language_store() {
    if (!Get.isRegistered<LanguageStore>()) {
      return null;
    }
    return Get.find<LanguageStore>();
  }

  static String _normalize_language_code(String language_code) {
    final String normalized_language_code = language_code.trim().toLowerCase();
    if (normalized_language_code.isEmpty) {
      return '';
    }
    return normalized_language_code.split(RegExp(r'[-_]')).first;
  }
}
