// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// TODO 作品编辑流程统一样式与常量。
class WorkEditorStyle {
  const WorkEditorStyle._();

  // ==================== 偏好分组 ID 常量 ========================

  /// TODO 内容偏好（分类）分组 ID。
  static const int preference_category_id = 2;

  /// TODO 长篇选项 ID。
  static const int long_work_id = 117;

  /// TODO 短篇选项 ID（篇幅偏好中）。
  static const int short_work_id = 119;

  /// TODO 性别偏好「无所谓」选项 ID。
  static const int gender_any_id = 113;

  // ==================== 布局常量 ========================

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
  static const double cover_height = 124;

  /// TODO 底部操作栏最小高度。
  static const double bottom_bar_min_height = 78;

  /// TODO CJK 步骤标题字号。
  static const double step_label_size_cjk = 12;

  /// TODO 非 CJK 步骤标题字号。
  static const double step_label_size_alphabetic = 10;

  /// TODO 步骤指示器圆圈固定高度（最大圆直径）。
  static const double step_indicator_height = 30;

  /// TODO 步骤指示器最大圆直径。
  static const double step_circle_size_large = 30;

  /// TODO 步骤指示器普通圆直径。
  static const double step_circle_size_small = 24;

  // ==================== 字重常量 ========================

  /// TODO 表单标题字重。
  static final FontWeight section_title_weight = FontConfig.adjustedWeight(
    FontWeight.w600,
  );

  /// TODO 字段标题字重。
  static final FontWeight field_label_weight = FontConfig.adjustedWeight(
    FontWeight.w500,
  );
}
