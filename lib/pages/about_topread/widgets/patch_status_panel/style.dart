import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// TODO 热更诊断面板的布局、字号与主题透明度。
class PatchPanelStyle {
  static const padding = 16.0;
  static const gap = 12.0;
  static const radius = 12.0;
  static const title_cjk = 15.0;
  static const title_alphabetic = 14.0;
  static const detail_cjk = 12.0;
  static const detail_alphabetic = 12.0;
  static const line_height = 1.6;
  static const progress_height = 5.0;
  static const surface_alpha = 0.06;
  static const muted_alpha = 0.7;
  static final weight = FontConfig.adjustedWeight(FontWeight.w500);
}
