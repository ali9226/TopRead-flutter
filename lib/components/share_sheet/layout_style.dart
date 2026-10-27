import 'package:app/config/layout_config.dart';

/// 分享容器的响应式约束；海报自身仍使用固定导出设计尺寸。
class ShareLayoutStyle {
  ShareLayoutStyle._();

  static const double max_width = 600;
  static const double sheet_height_ratio = 0.9;
  static const double min_channel_width = 90;
  static const int max_channel_columns = 6;
  static const double min_tap_extent = 48;
  static const double row_spacing = LayoutConfig.space_20;
  static const double min_preview_height = 180;
  static const double preview_controls_reserved_height = 220;
  static const double export_pixel_ratio = 3;
  static const double feedback_font_size = 14;
  static const Duration feedback_duration = Duration(seconds: 2);
}
