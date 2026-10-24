import 'package:app/components/work_section_card/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

export 'style.dart';

/// 分类、简介、目录和评论共用的轻浮起卡片；阴影不占布局空间。
class WorkSectionCard extends StatelessWidget {
  const WorkSectionCard({
    super.key,
    required this.child,
    required this.is_dark,
    this.padding = const EdgeInsets.all(WorkSectionCardStyle.padding),
  });

  final Widget child;
  final bool is_dark;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: WorkSectionCardStyle.card_background(is_dark),
      borderRadius: BorderRadius.circular(WorkSectionCardStyle.radius),
      border: WorkSectionCardStyle.border(is_dark),
      boxShadow: WorkSectionCardStyle.shadows(is_dark),
    ),
    child: Material(
      color: ColorConstants.transparent,
      borderRadius: BorderRadius.circular(WorkSectionCardStyle.radius),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// 章节等入口和正文卡片使用同一标题层级，长文案自然换行。
class WorkSectionHeading extends StatelessWidget {
  const WorkSectionHeading({
    super.key,
    required this.title,
    required this.is_dark,
    this.trailing,
  });

  final String title;
  final bool is_dark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return Row(
      children: [
        Container(
          width: WorkSectionCardStyle.accent_width,
          height: WorkSectionCardStyle.accent_height,
          decoration: BoxDecoration(
            color: ColorConstants.themeColor,
            borderRadius: BorderRadius.circular(
              WorkSectionCardStyle.accent_radius,
            ),
          ),
        ),
        const SizedBox(width: WorkSectionCardStyle.accent_gap),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: WorkSectionCardStyle.foreground(is_dark),
              fontSize: cjk
                  ? WorkSectionCardStyle.title_size_cjk
                  : WorkSectionCardStyle.title_size_alphabetic,
              height: cjk
                  ? WorkSectionCardStyle.title_height_cjk
                  : WorkSectionCardStyle.title_height_alphabetic,
              fontWeight: WorkSectionCardStyle.title_weight,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
