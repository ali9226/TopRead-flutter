import 'package:flutter/material.dart';
import 'package:app/util/color_util.dart';

/*
  TODO 颜色相关的配置
 */
class ColorConstants {
  // TODO 主题色
  static final Color themeColor = hexToColor("#F8D02D");

  // TODO 日间主题文字的颜色
  static final Color lightTextColor = hexToColor("#222222");

  // TODO 红色
  static final Color dangerColor = hexToColor("#F56C6C");

  // TODO 绿色
  static final Color successColor = hexToColor("#67C23A");

  // TODO 白色
  static final Color whiteColor = hexToColor('#FFFFFF');

  // TODO 背景色
  static final Color backgroundColor = hexToColor("#121212");

  // TODO 文字提示颜色
  static final Color hintColor = hexToColor("#888888");

  // TODO 夜间主题高亮色
  static final Color nightHighlightColor = hexToColor("#171926");

  // TODO 夜间主题的文字的颜色
  static final Color nightTextColor = hexToColor("#68697e");

  // TODO 夜间主题背景色
  static final Color nightBackgroundColor = hexToColor("#12121c");

  // TODO 日间主题背景色
  static final Color lightBackgroundColor = hexToColor("#FAFAFA");

  // TODO 卡牌背面的颜色
  static final Color cardColor = hexToColor("#F56C6C");

  // TODO 夜间主题牌局页面文字颜色
  static final Color nightGameTextColor = hexToColor("#999999");

  // TODO 消息分类主色列表。
  // 后续新增消息类型时，优先从这里扩展颜色，页面直接按索引读取。
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


  // TODO 在小说标签里面用到的颜色列表
  static final List<Color> tagColorList = <Color>[
    const Color(0xFF5C9DFF), // 活力蓝
    const Color(0xFFFF7A59), // 珊瑚橙
    const Color(0xFFFFB020), // 琥珀黄
    const Color(0xFF4CBF8A), // 翡翠绿
    const Color(0xFFE85D75), // 玫瑰红
  ];



  // TODO 根据索引读取消息类型主色，越界时循环取值。
  static Color resolveMessageTypeAccentColor(int index) {
    if (messageTypeAccentColorList.isEmpty) {
      return themeColor;
    }
    final int safeIndex = index % messageTypeAccentColorList.length;
    return messageTypeAccentColorList[safeIndex];
  }

  // TODO 根据索引读取标签颜色，越界时循环取值。
  static Color resolveTagColor(int index) {
    if (tagColorList.isEmpty) {
      return themeColor;
    }
    final int safeIndex = index % tagColorList.length;
    return tagColorList[safeIndex];
  }

  // TODO 判断消息强调色是否属于主题金系。
  // 目前将主主题金和琥珀金都归入该类别。
  static bool isMessageGoldAccent(Color color) {
    return color.value == const Color(0xFFFFD45A).value ||
        color.value == const Color(0xFFFFC76A).value;
  }
}

