// ignore_for_file: non_constant_identifier_names

import 'package:app/stores/user_information.dart';
import 'package:get/get.dart';

/// 所有语种入口共用的用户权限规则，不以设备语种或缓存列表授予权限。
class LanguagePermission {
  const LanguagePermission._();

  /// 只有当前有效登录用户的后端资料 debug=2 才能使用中文。
  /// 注册用户仓库之前按访客处理，避免启动阶段短暂显示中文。
  static bool get can_use_chinese {
    if (!Get.isRegistered<UserInformation>()) return false;
    final UserInformation user_information = Get.find<UserInformation>();
    final user_info = user_information.userInfo.value;
    return user_information.isLoggedIn.value &&
        user_info != null &&
        user_info.id > 0 &&
        user_info.debug == 2;
  }

  /// 将区域语种代码归一化，如 zh-CN、zh_Hant 都归为 zh。
  static String normalize_language_code(String language_code) {
    return language_code.trim().toLowerCase().split(RegExp(r'[-_]')).first;
  }

  /// 判断接口或历史偏好是否指向中文，包括常见的旧代码别名。
  static bool is_chinese(String language_code) {
    final String code = normalize_language_code(language_code);
    return code == 'zh' || code == 'cn' || code == 'chinese';
  }

  /// 判断语种是否允许参与菜单展示、默认语种或请求参数解析。
  static bool is_language_allowed(String language_code) {
    return !is_chinese(language_code) || can_use_chinese;
  }

  /// 拒绝中文时明确回退英语，不依赖后端默认语种的排序。
  static String resolve_language_code(String language_code) {
    final String code = normalize_language_code(language_code);
    if (code.isEmpty || !is_language_allowed(code)) return 'en';
    return is_chinese(code) ? 'zh' : code;
  }
}
