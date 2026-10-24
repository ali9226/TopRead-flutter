import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 将十六进制颜色字符串（如 "#888888"）转换为 [Color] 对象。
///
/// [colorStr] 十六进制颜色字符串，支持带或不带 `#` 前缀。
Color hexToColor(String colorStr) {
  return ColorConstants.parse_hex(colorStr);
}
