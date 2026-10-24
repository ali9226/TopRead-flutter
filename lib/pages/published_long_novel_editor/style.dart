import 'package:app/config/layout_config.dart';

// ignore_for_file: constant_identifier_names

/// 与偏好配置表对应的稳定标识，以及编辑页使用的限制。
class PublishedEditorStyle {
  const PublishedEditorStyle._();
  static const double tab_outer_padding = LayoutConfig.space_16;
  static const double tab_spacing_cjk = LayoutConfig.space_18;
  static const double tab_spacing_alphabetic = 16;
  static const double directory_header_gap = LayoutConfig.space_4;
  static const double directory_top_padding = LayoutConfig.space_20;
  static const int status_group = 4;
  static const int completed_item = 114;
  static const int serializing_item = 115;
  static const int max_categories = 5;
  static const double toolbar_icon_size = LayoutConfig.icon_compact;
  static const double directory_number_width = 44;
  static const double cover_max_width = 1600;
  static const int cover_quality = 90;
}
