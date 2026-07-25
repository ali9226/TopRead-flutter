import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:app/config/theme.dart';

/* TODO
 * 持久化当前主题模式。
 *
 * [mode] 需要保存的主题模式。
 */
Future<void> saveThemeMode(ThemeMode mode) async {
  final storage = GetStorage();
  await storage.write(
    ThemeConstants.themeKey,
    mode == ThemeMode.dark ? 'dark' : 'light',
  );
}
