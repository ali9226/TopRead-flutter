// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:app/fcm/register_token.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';

/// 语种变化处理器。
///
/// 监听用户语种变化，统一处理所有需要在语种变化时触发的逻辑。
/// 当用户切换语种时，自动执行以下操作：
/// 1. 更新 FCM Token 中的语言代码
/// 2. 触发其他需要响应语种变化的业务逻辑
///
/// 使用方式：
///   // 在语种变化时调用
///   LanguageChangeHandler.onLanguageChanged('zh');
class LanguageChangeHandler {
  /// 上一次记录的语种代码。
  static String? _last_language_code;

  /// 初始化语种变化监听器。
  ///
  /// 应在应用启动时调用，读取本地缓存的语种作为初始值。
  static Future<void> init() async {
    try {
      _last_language_code = await StorageUtil.getData('language');
      logUtil(msg: 'LanguageChangeHandler: 初始化完成，当前语种: $_last_language_code');
    } catch (e) {
      logUtil(msg: 'LanguageChangeHandler: 初始化失败: $e', type: 'e');
    }
  }

  /// 语种变化时的处理逻辑。
  ///
  /// 当用户切换语种时调用此方法。
  /// 会自动判断语种是否真的发生了变化，避免重复触发。
  ///
  /// [new_language_code] 新的语种代码（如 'zh', 'en', 'ja'）。
  static Future<void> onLanguageChanged(String new_language_code) async {
    // 规范化语种代码（如 'zh-CN' -> 'zh'）。
    final String normalized_code = _normalizeLanguageCode(new_language_code);

    // 判断语种是否真的发生了变化。
    if (_last_language_code == normalized_code) {
      logUtil(msg: 'LanguageChangeHandler: 语种未变化，跳过处理');
      return;
    }

    logUtil(msg: 'LanguageChangeHandler: 语种从 $_last_language_code 变化为 $normalized_code');

    // 更新记录。
    _last_language_code = normalized_code;

    // 1. 更新 FCM Token 中的语言代码。
    await _updateFcmLanguage(normalized_code);

    // 2. 在这里添加其他需要响应语种变化的逻辑。
    // 例如：
    // - 清除缓存
    // - 重新请求数据
    // - 更新主题样式
  }

  /// 更新 FCM Token 中的语言代码。
  ///
  /// 当用户切换语种时，重新注册 FCM Token 以更新语言字段。
  static Future<void> _updateFcmLanguage(String language_code) async {
    try {
      logUtil(msg: 'LanguageChangeHandler: 更新 FCM 语言代码为 $language_code');
      await FcmRegisterToken.execute();
      logUtil(msg: 'LanguageChangeHandler: FCM 语言代码更新完成');
    } catch (e) {
      logUtil(msg: 'LanguageChangeHandler: 更新 FCM 语言代码失败: $e', type: 'e');
    }
  }

  /// 规范化语种代码。
  ///
  /// 将 'zh-CN'、'zh_CN' 等格式统一为 'zh'。
  static String _normalizeLanguageCode(String language_code) {
    final String normalized = language_code.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'en';
    }
    return normalized.split(RegExp(r'[-_]')).first;
  }

  /// 获取当前记录的语种代码。
  static String? get currentLanguageCode => _last_language_code;

  /// 手动触发语种变化处理。
  ///
  /// 在某些场景下需要手动触发语种变化处理时调用。
  /// 例如：应用启动时、从后台恢复时。
  static Future<void> triggerUpdate() async {
    final String? current_code = await StorageUtil.getData('language');
    if (current_code != null) {
      await onLanguageChanged(current_code);
    }
  }
}
