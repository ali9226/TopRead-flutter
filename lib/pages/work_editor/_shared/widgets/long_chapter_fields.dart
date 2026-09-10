// ignore_for_file: non_constant_identifier_names
import 'package:app/config/font_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'editor_keyboard_input.dart';

/// 新建长篇和已发布单章共用的正文排版，避免两套界面产生差异。
class LongChapterFields extends StatelessWidget {
  const LongChapterFields({
    super.key,
    required this.title_controller,
    required this.content_controller,
    required this.is_dark,
    this.locked = false,
    this.title_key = const ValueKey('chapter_title_input'),
    this.content_key = const ValueKey('chapter_content_input'),
  });
  final TextEditingController title_controller;
  final TextEditingController content_controller;
  final bool is_dark;
  final bool locked;
  final Key title_key;
  final Key content_key;
  @override
  Widget build(BuildContext context) {
    final primary = AuthorStyle.primary_text(is_dark);
    final secondary = AuthorStyle.secondary_text(is_dark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorKeyboardInput(
          builder: (read_only, on_tap) => TextField(
            readOnly: locked || read_only,
            onTap: locked ? null : on_tap,
            onTapAlwaysCalled: true,
            key: title_key,
            controller: title_controller,
            maxLines: null,
            style: TextStyle(
              color: primary,
              fontSize: 23,
              height: 1.4,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
            decoration: InputDecoration(
              hintText: easy.tr('creator_center.chapter_title_hint'),
              hintStyle: TextStyle(
                color: secondary.withValues(alpha: .7),
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 14),
        EditorKeyboardInput(
          builder: (read_only, on_tap) => TextField(
            readOnly: locked || read_only,
            onTap: locked ? null : on_tap,
            onTapAlwaysCalled: true,
            key: content_key,
            controller: content_controller,
            minLines: 16,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(
              color: primary,
              fontSize: 16,
              height: 1.9,
              letterSpacing: .3,
            ),
            decoration: InputDecoration(
              hintText: easy.tr('creator_center.chapter_content_hint'),
              hintStyle: TextStyle(color: secondary.withValues(alpha: .65)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
