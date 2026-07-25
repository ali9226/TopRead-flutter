import 'package:flutter/material.dart';

/// TODO 将十六进制颜色字符串（如 "#888888"）转换为 Color 对象
Color hexToColor(String colorStr) {
  // TODO 去掉 #
  var hex = colorStr.replaceAll('#', '');
  // TODO 如果只有 6 位，前面加 FF 表示不透明
  if (hex.length == 6) hex = 'FF$hex';
  // TODO 转成 Color 对象
  return Color(int.parse(hex, radix: 16));
}
