import 'package:flutter/material.dart';

/// 将十六进制颜色字符串（如 "#888888"）转换为 [Color] 对象。
///
/// [colorStr] 十六进制颜色字符串，支持带或不带 `#` 前缀。
Color hexToColor(String colorStr) {
  // 去掉 # 前缀。
  var hex = colorStr.replaceAll('#', '');
  // 如果只有 6 位，前面加 FF 表示不透明。
  if (hex.length == 6) hex = 'FF$hex';
  // 转成 Color 对象。
  return Color(int.parse(hex, radix: 16));
}
