// ignore_for_file: non_constant_identifier_names
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/widgets.dart';
import 'package:app/util/language_util/index.dart';

/// 无本地化宿主的组件测试也能展示英文；正式页面始终使用项目翻译资源。
String quest_text(
  BuildContext context,
  String key,
  String fallback, {
  Map<String, String> args = const {},
}) {
  if (easy.EasyLocalization.of(context) != null) {
    final value = easy.tr('tile_quest.$key', context: context, namedArgs: args);
    if (value != 'tile_quest.$key') return value;
  }
  var value = fallback;
  for (final entry in args.entries) {
    value = value.replaceAll('{${entry.key}}', entry.value);
  }
  return value;
}

/// CJK 判断使用项目统一工具，字体与行高由游戏样式表提供。
bool quest_is_cjk(BuildContext context) => LanguageUtil.is_cjk_language(
  easy.EasyLocalization.of(context)?.locale.languageCode ??
      Localizations.localeOf(context).languageCode,
);
