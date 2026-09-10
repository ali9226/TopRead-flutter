// ignore_for_file: non_constant_identifier_names
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/widgets/long_chapter_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 直接使用新建长篇的输入组件；章节标识在上、字数在底部，正文独立滚动。
class ChapterWritingSurface extends StatelessWidget {
  const ChapterWritingSurface({
    super.key,
    required this.title_controller,
    required this.content_controller,
    required this.is_dark,
    required this.is_cjk,
    required this.read_only,
    this.chapter_label,
  });
  final TextEditingController title_controller;
  final TextEditingController content_controller;
  final bool is_dark, is_cjk, read_only;
  final String? chapter_label;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        children: [
          if (chapter_label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: SizedBox(
                height: kMinInteractiveDimension,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    chapter_label!,
                    style: TextStyle(
                      color: is_dark
                          ? ColorConstants.themeColor
                          : ColorConstants.lightTextColor,
                      fontSize: 15,
                      fontWeight: AuthorStyle.emphasis_weight,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
              child: LongChapterFields(
                title_controller: title_controller,
                content_controller: content_controller,
                is_dark: is_dark,
                locked: read_only,
                title_key: const ValueKey('single_chapter_title'),
                content_key: const ValueKey('single_chapter_content'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: content_controller,
              builder: (context, value, _) => Text(
                tr(
                  'creator_center.chapter_word_count',
                  namedArgs: {
                    'count':
                        '${value.text.replaceAll(RegExp(r'\s+'), '').length}',
                  },
                ),
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
