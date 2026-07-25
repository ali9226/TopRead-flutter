import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;

/// 空数据状态展示组件。
///
/// 简洁风格：
/// - empty.svg 纯色图标（日间/夜间不同配色）
/// - 干净的文字排版
/// - 点击可触发重新加载
class EmptyState extends StatelessWidget {
  /// 是否为深色主题。
  final bool is_dark;

  /// 空状态提示文字，不传时使用多语种默认文案。
  final String? message;

  /// 重新加载回调，点击插画或文字时触发。
  final VoidCallback? on_reload;

  /// 当前语种代码，用于判断 CJK。
  final String? language_code;

  const EmptyState({
    super.key,
    this.is_dark = true,
    this.message,
    this.on_reload,
    this.language_code,
  });

  @override
  Widget build(BuildContext context) {
    final String lang = language_code ??
        Localizations.localeOf(context).languageCode;
    final bool is_cjk = LanguageUtil.is_cjk_language(lang);
    final double font_size = is_cjk ? 13 : 12;

    final String display_message = message ?? easy.tr('common.empty_data');

    /// 图标颜色。
    final Color icon_color = is_dark
        ? const Color(0xFF4A4D60)
        : const Color(0xFFBBBBCC);

    /// 文字颜色。
    final Color text_color = is_dark
        ? const Color(0xFF6B6E82)
        : const Color(0xFFAAAAAA);

    return GestureDetector(
      onTap: on_reload,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgIcon(
              name: 'empty',
              width: 151,
              height: 151,
              color: icon_color,
            ),
            const SizedBox(height: 12),
            Text(
              display_message,
              style: TextStyle(
                fontSize: font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: text_color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
