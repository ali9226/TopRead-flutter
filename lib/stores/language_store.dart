// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:get/get.dart';
import 'package:app/models/language_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/language_permission.dart';
import 'package:app/util/storage_util/index.dart';

/* TODO
 * 全局语种状态仓库。
 */
class LanguageStore extends GetxController {
  static const String language_key = 'language';
  static const String language_list_key = 'language_list';

  /// 本地存在翻译文件的语种代码列表（如 ['en', 'zh', 'sw', 'fr']）。
  final List<String> asset_language_code_list;

  /// 当前用户有权使用的语种列表，所有对外入口都经过权限过滤。
  final RxList<LanguageInfo> language_list = <LanguageInfo>[].obs;

  /// 私有的接口原始数据，登录权限变化时可重新计算，不暴露给菜单。
  List<LanguageInfo> _source_language_list = <LanguageInfo>[];

  /// 用户资料及登录状态订阅，控制器关闭时释放。
  Worker? _user_permission_worker;

  /// 过滤后应用支持的语种列表。
  final RxList<LanguageInfo> supported_language_list = <LanguageInfo>[].obs;

  /// UI 界面可见的语种列表（菜单展示用）。
  final RxList<LanguageInfo> visible_language_list = <LanguageInfo>[].obs;

  /// 默认语种信息。
  final Rxn<LanguageInfo> default_language_info = Rxn<LanguageInfo>();

  final RxBool loaded = false.obs;

  LanguageStore({required List<String> asset_language_code_list})
    : asset_language_code_list = asset_language_code_list
          .map((String item) => item.trim().toLowerCase())
          .toList();

  @override
  void onInit() {
    super.onInit();
    _load_language_list_from_storage();
    if (Get.isRegistered<UserInformation>()) {
      final UserInformation user_information = Get.find<UserInformation>();
      _user_permission_worker = everAll([
        user_information.userInfo,
        user_information.isLoggedIn,
      ], (_) => _refresh_available_language_list());
    }
  }

  @override
  void onClose() {
    _user_permission_worker?.dispose();
    super.onClose();
  }

  /// TODO 从本地存储恢复语种列表。
  void _load_language_list_from_storage() {
    final List<dynamic>? cached_list = StorageUtil.getList(language_list_key);
    if (cached_list != null && cached_list.isNotEmpty) {
      final List<LanguageInfo> data = cached_list
          .whereType<Map>()
          .map(
            (dynamic item) =>
                LanguageInfo.from_json(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (data.isNotEmpty) {
        save_language_list(data, persist: false);
      }
    }
  }

  /// TODO 保存语种列表并计算派生状态
  ///
  /// 核心逻辑：将接口返回的列表与本地 i18n 资源进行交叉匹配。
  void save_language_list(List<LanguageInfo> data, {bool persist = true}) {
    _source_language_list = List<LanguageInfo>.from(data);
    _refresh_available_language_list();
    loaded.value = true;

    // 原始列表仅用于私有缓存；恢复时仍会重新检查当前用户权限。
    if (persist) {
      StorageUtil.saveList(
        language_list_key,
        _source_language_list
            .map((LanguageInfo item) => item.to_json())
            .toList(),
      );
    }
  }

  /// 资料刷新、登录、退出均重新派生列表，接口返回中文也不能绕过权限。
  void _refresh_available_language_list() {
    final List<LanguageInfo> next_language_list = _source_language_list
        .where(
          (item) => LanguagePermission.is_language_allowed(item.language_code),
        )
        .toList();

    // 2. 过滤出本地有翻译资源的语种
    final List<LanguageInfo> next_supported_language_list = next_language_list
        .where((item) => _is_supported_language(item))
        .toList();

    // 3. 过滤出状态为“展示”的语种（用于菜单渲染）
    final List<LanguageInfo> next_visible_language_list =
        next_supported_language_list
            .where((LanguageInfo item) => item.show_status == 1) // 1 为展示
            .toList();

    // 4. 更新响应式变量
    language_list.assignAll(next_language_list);
    supported_language_list.assignAll(next_supported_language_list);
    visible_language_list.assignAll(next_visible_language_list);

    // 5. 确定默认语种
    default_language_info.value = _resolve_default_language_info(
      next_supported_language_list,
    );
  }

  /// 判断语种是否受本地资源支持
  bool _is_supported_language(LanguageInfo item) {
    // 规范化接口代码（如 en-US -> en）
    final String code = item.language_code;
    if (code.isEmpty || item.is_removed) {
      return false;
    }
    // 只要本地 asset 列表中包含这个前缀，就认为支持
    return asset_language_code_list.contains(code);
  }

  /// 确定默认语种：优先找 default_language == 2 的，找不到取第一个
  LanguageInfo? _resolve_default_language_info(List<LanguageInfo> data) {
    for (final LanguageInfo item in data) {
      if (item.is_default_language) {
        return item;
      }
    }
    for (final LanguageInfo item in data) {
      if (item.language_code == 'en') return item;
    }
    if (data.isNotEmpty) {
      return data.first;
    }
    return null;
  }

  /// 根据代码查找匹配的语种对象
  LanguageInfo? find_supported_language_by_code(String language_code) {
    final String normalized = _normalize_language_code(language_code);
    for (final LanguageInfo item in supported_language_list) {
      if (item.language_code == normalized) {
        return item;
      }
    }
    return null;
  }

  /// 获取默认语种代码
  String get default_language_code {
    if (default_language_info.value != null) {
      return default_language_info.value!.language_code;
    }
    if (asset_language_code_list.contains('en')) return 'en';
    return asset_language_code_list.firstWhere(
      LanguagePermission.is_language_allowed,
      orElse: () => 'en',
    );
  }

  String _normalize_language_code(String code) {
    final String normalized = code.trim().toLowerCase();
    return normalized.split(RegExp(r'[-_]')).first;
  }
}
