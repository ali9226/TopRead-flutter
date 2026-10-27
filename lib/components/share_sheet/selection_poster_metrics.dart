// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/models/share_excerpt.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'selection_poster_style.dart';
import 'style.dart';

TextStyle selection_excerpt_text_style(BuildContext context) {
  final cjk = LanguageUtil.is_cjk_language(
    Localizations.localeOf(context).languageCode,
  );
  return TextStyle(
    fontSize: cjk
        ? ShareSheetStyle.poster_excerpt_font_size_cjk
        : ShareSheetStyle.poster_excerpt_font_size_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    height: cjk
        ? SelectionPosterStyle.context_line_height_cjk
        : SelectionPosterStyle.context_line_height_alphabetic,
    letterSpacing: cjk ? 0.2 : 0,
  );
}

/// 底栏随文字缩放增高，封面/二维码尺寸保持稳定。
double selection_poster_footer_height(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context);
  final text_height =
      scale.scale(ShareSheetStyle.poster_title_font_size) * 1.24 * 2 +
      LayoutConfig.space_4 +
      scale.scale(ShareSheetStyle.poster_author_font_size) * 1.2 +
      LayoutConfig.space_7 +
      scale.scale(ShareSheetStyle.poster_cta_font_size) * 1.2;
  return math.max(
    ShareSheetStyle.poster_footer_height,
    ShareSheetStyle.poster_footer_padding.vertical +
        math.max(ShareSheetStyle.poster_cover_height, text_height),
  );
}

/// 长选文扩为长图，优先完整保存选择；超过安全高度时由排版器明确省略。
Size selection_poster_design_size(BuildContext context, ShareExcerpt excerpt) {
  final text = excerpt.selected_text.characters
      .take(SelectionPosterStyle.selection_working_limit + 1)
      .toString();
  if (text.characters.length > SelectionPosterStyle.selection_working_limit) {
    return const Size(
      ShareSheetStyle.poster_design_width,
      SelectionPosterStyle.maximum_height,
    );
  }
  final painter =
      TextPainter(
        text: TextSpan(
          text: text,
          style: SelectionPosterStyle.selected_style(
            selection_excerpt_text_style(context),
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.localeOf(context),
      )..layout(
        maxWidth:
            ShareSheetStyle.poster_design_width -
            ShareSheetStyle.poster_frame_width * 2 -
            ShareSheetStyle.poster_excerpt_padding.horizontal,
      );
  final scale = MediaQuery.textScalerOf(context);
  final user_height = math.max(
    ShareSheetStyle.poster_avatar_size,
    scale.scale(ShareSheetStyle.poster_nickname_font_size) * 1.2 +
        LayoutConfig.space_3 +
        scale.scale(ShareSheetStyle.poster_date_font_size) * 1.2,
  );
  final overhead =
      ShareSheetStyle.poster_frame_width * 2 +
      selection_poster_footer_height(context) +
      ShareSheetStyle.poster_excerpt_padding.vertical +
      ShareSheetStyle.poster_quote_mark_height +
      ShareSheetStyle.poster_excerpt_user_spacing +
      user_height +
      LayoutConfig.space_4;
  final height = (painter.height + overhead).ceilToDouble().clamp(
    ShareSheetStyle.poster_design_height,
    SelectionPosterStyle.maximum_height,
  );
  painter.dispose();
  return Size(ShareSheetStyle.poster_design_width, height);
}
