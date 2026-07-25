import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart'; // TODO kIsWeb
import 'package:app/stores/device_info.dart';
import 'package:app/config/theme.dart';
import 'save_theme_mode.dart';

/* TODO
 * 读取并应用主题模式。
 *
 * [context] 仅在 Web 端需要借助上下文读取平台亮度时使用。
 */
Future<ThemeMode> getThemeMode({BuildContext? context}) async {
  final storage = GetStorage();

  // TODO 本地获取主题
  final savedTheme = storage.read(ThemeConstants.themeKey);

  ThemeMode themeMode;

  if (savedTheme == 'light') {
    themeMode = ThemeMode.light;
  } else if (savedTheme == 'dark') {
    themeMode = ThemeMode.dark;
  } else {
    // TODO 本地没有缓存主题，自动获取系统主题
    Brightness brightness;

    if (kIsWeb && context != null) {
      brightness = MediaQuery.of(context).platformBrightness;
    } else {
      brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
    themeMode = brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  // TODO 触发 DeviceInfo 控制器的 changeTheme
  if (Get.isRegistered<DeviceInfo>()) {
    final deviceInfo = Get.find<DeviceInfo>();
    deviceInfo.changeTheme(themeMode);
  }

  // TODO 主题保存本地
  await saveThemeMode(themeMode);

  return themeMode;
}
