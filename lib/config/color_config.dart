import 'package:flutter/material.dart';
import 'package:app/util/color_util.dart';

/// 颜色配置。
///
/// 集中管理所有颜色常量，包括主题色、日间/夜间文字色、背景色等。
/// 如无特殊情况：红色指 [dangerColor]，绿色指 [successColor]，主题色指 [themeColor]。
class ColorConstants {
  /// 主题色（金色）。
  static final Color themeColor = hexToColor("#F8D02D");

  /// 日间主题文字颜色。
  static final Color lightTextColor = hexToColor("#222222");

  /// 危险/错误红色。
  static final Color dangerColor = hexToColor("#F56C6C");

  /// 成功/确认绿色。
  static final Color successColor = hexToColor("#67C23A");

  /// 白色。
  static final Color whiteColor = hexToColor('#FFFFFF');

  /// 夜间主题背景色。
  static final Color backgroundColor = hexToColor("#121212");

  /// 文字提示颜色（灰色）。
  static final Color hintColor = hexToColor("#888888");

  /// 夜间主题高亮色。
  static final Color nightHighlightColor = hexToColor("#171926");

  /// 夜间主题文字颜色。
  static final Color nightTextColor = hexToColor("#68697e");

  /// 夜间主题背景色。
  static final Color nightBackgroundColor = hexToColor("#12121c");

  /// 日间主题背景色。
  static final Color lightBackgroundColor = hexToColor("#FAFAFA");

  /// 消息分类主色列表。
  ///
  /// 后续新增消息类型时，优先从这里扩展颜色，页面直接按索引读取。
  static final List<Color> messageTypeAccentColorList = <Color>[
    const Color(0xFFFFD45A), // 1 主题金（原消息中心色）
    const Color(0xFF8DB7FF), // 2 清透蓝（原消息中心色）
    const Color(0xFFFF9E80), // 3 暖珊瑚（原消息中心色）
    const Color(0xFFFFC76A), // 4 琥珀金（同系扩展）
    const Color(0xFF7EC2FF), // 5 天空蓝（同系扩展）
    const Color(0xFFFFB39A), // 6 蜜桃珊瑚（同系扩展）
    const Color(0xFFA7D8A8), // 7 薄荷绿（同系扩展）
    const Color(0xFFD6B0FF), // 8 淡紫（同系扩展）
  ];

  /// 小说标签颜色列表。
  static final List<Color> tagColorList = <Color>[
    const Color(0xFF5C9DFF), // 活力蓝
    const Color(0xFFFF7A59), // 珊瑚橙
    const Color(0xFFFFB020), // 琥珀黄
    const Color(0xFF4CBF8A), // 翡翠绿
    const Color(0xFFE85D75), // 玫瑰红
  ];

  /// 根据索引读取消息类型主色，越界时循环取值。
  static Color resolveMessageTypeAccentColor(int index) {
    if (messageTypeAccentColorList.isEmpty) {
      return themeColor;
    }
    final int safeIndex = index % messageTypeAccentColorList.length;
    return messageTypeAccentColorList[safeIndex];
  }

  /// 根据索引读取标签颜色，越界时循环取值。
  static Color resolveTagColor(int index) {
    if (tagColorList.isEmpty) {
      return themeColor;
    }
    final int safeIndex = index % tagColorList.length;
    return tagColorList[safeIndex];
  }

  /// 判断消息强调色是否属于主题金系。
  ///
  /// 目前将主主题金和琥珀金都归入该类别。
  static bool isMessageGoldAccent(Color color) {
    return color.value == const Color(0xFFFFD45A).value ||
        color.value == const Color(0xFFFFC76A).value;
  }
}
