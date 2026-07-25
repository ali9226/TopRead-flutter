import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

/// 样式配置（类似 CSS）
class Style {
  // TODO 高度
  static const double containerHeight = 58;

  // TODO 国旗图标大小
  static const double nationSize = 24;

  // TODO 关闭图标的尺寸
  static const double closeSize = 18;

  // logo的尺寸
  static const double logoSize = 32;

  // TODO 默认文字样式
  static final TextStyle textStyle = TextStyle(
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
    fontSize: 15,
    color: Colors.black,
  );

  static final TextStyle titleStyle = TextStyle(
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
    fontSize: 18,
    color: Colors.black,
    letterSpacing: 0.2,
  );
}
