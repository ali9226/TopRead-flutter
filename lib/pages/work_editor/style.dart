// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// TODO 作品编辑流程统一样式。
class WorkEditorStyle {
  const WorkEditorStyle._();

  /// TODO 内容最大宽度。
  static const double content_max_width = 720;

  /// TODO 页面水平留白。
  static const double page_padding = 16;

  /// TODO 表单卡片圆角。
  static const double section_radius = 20;

  /// TODO 表单卡片内边距。
  static const double section_padding = 18;

  /// TODO 表单区块间距。
  static const double section_spacing = 16;

  /// TODO 字段间距。
  static const double field_spacing = 20;

  /// TODO 封面宽度。
  static const double cover_width = 116;

  /// TODO 封面高度。
  static const double cover_height = 154;

  /// TODO 底部操作栏最小高度。
  static const double bottom_bar_min_height = 78;

  /// TODO CJK 步骤标题字号。
  static const double step_label_size_cjk = 12;

  /// TODO 非 CJK 步骤标题字号。
  static const double step_label_size_alphabetic = 10;

  /// TODO 表单标题字重。
  static final FontWeight section_title_weight = FontConfig.adjustedWeight(
    FontWeight.w600,
  );

  /// TODO 字段标题字重。
  static final FontWeight field_label_weight = FontConfig.adjustedWeight(
    FontWeight.w500,
  );
}
