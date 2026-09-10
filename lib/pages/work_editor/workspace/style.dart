// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:flutter/material.dart';

/// 已发布作品沿用新建编辑器的留白、圆角、按钮与主题色。
class WorkspaceStyle {
  const WorkspaceStyle._();

  static const double gap = 12;
  static const double small_gap = 6;
  static const double radius = 14;
  static const double cover_width = 88;
  static const double cover_height = 112;
  static const double icon_size = 22;
  static const double title_size_cjk = 23;
  static const double title_size_alphabetic = 21;
  static const double body_size_cjk = 15;
  static const double body_size_alphabetic = 14;
  static const double caption_size_cjk = 12;
  static const double caption_size_alphabetic = 11;
  static const double body_height = 1.65;
  static const double writing_height = 1.9;
  static const double writing_size_cjk = 16;
  static const double writing_size_alphabetic = 15;
  static const double writing_letter_spacing = .3;
  static const int content_min_lines = 16;
  static const int chapter_title_limit = 255;
  static const EdgeInsets padding = EdgeInsets.all(
    WorkEditorStyle.page_padding,
  );

  static TextStyle title(bool dark, bool cjk) => TextStyle(
    color: AuthorStyle.primary_text(dark),
    fontSize: cjk ? title_size_cjk : title_size_alphabetic,
    fontWeight: AuthorStyle.title_weight,
    height: 1.4,
  );

  static TextStyle body(bool dark, bool cjk) => TextStyle(
    color: AuthorStyle.primary_text(dark),
    fontSize: cjk ? body_size_cjk : body_size_alphabetic,
    fontWeight: AuthorStyle.body_weight,
    height: body_height,
  );

  static TextStyle caption(bool dark, bool cjk) => TextStyle(
    color: AuthorStyle.secondary_text(dark),
    fontSize: cjk ? caption_size_cjk : caption_size_alphabetic,
    fontWeight: AuthorStyle.body_weight,
    height: 1.5,
  );
}
