// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

/// 作品编辑器各步骤共用的工具方法。
class StepUtils {
  const StepUtils._();

  /// 构建字段标题。
  static Widget build_field_label(
    String title,
    bool is_dark, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AuthorStyle.primary_text(is_dark),
          fontSize: 13,
          fontWeight: WorkEditorStyle.field_label_weight,
        ),
        children: <InlineSpan>[
          TextSpan(text: title),
          if (required)
            TextSpan(
              text: '  *',
              style: TextStyle(color: ColorConstants.dangerColor),
            ),
        ],
      ),
    );
  }

  /// 输入框文字样式。
  /// 输入框文字样式。
  static TextStyle input_text_style(bool is_dark) {
    return TextStyle(
      color: AuthorStyle.primary_text(is_dark),
      fontSize: 15,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );
  }

  /// 输入框统一装饰。
  static InputDecoration field_decoration(bool is_dark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AuthorStyle.secondary_text(is_dark),
        fontSize: 14,
        fontWeight: AuthorStyle.body_weight,
      ),
      filled: true,
      fillColor: AuthorStyle.secondary_surface(is_dark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AuthorStyle.border(is_dark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthorStyle.gold, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  /// 构建步骤内统一的滚动容器。
  ///
  /// 点击空白区域自动取消焦点，收起输入法。
  static Widget build_step_scroll_view({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final bottom_safe = MediaQuery.paddingOf(context).bottom;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          WorkEditorStyle.page_padding,
          WorkEditorStyle.section_spacing,
          WorkEditorStyle.page_padding,
          // 键盘高度由页面布局统一处理，滚动内容只保留正常间距与安全区。
          WorkEditorStyle.section_spacing + bottom_safe,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WorkEditorStyle.content_max_width,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .expand(
                  (Widget child) => <Widget>[
                    child,
                    const SizedBox(height: WorkEditorStyle.section_spacing),
                  ],
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  /// 判断当前语种是否为 CJK。
  static bool is_cjk(BuildContext context) {
    return LanguageUtil.is_cjk_language(context.locale.languageCode);
  }
}
