// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// TODO 创作者中心统一样式。
///
/// 与 LayoutConfig 对齐：page_padding、section_radius、card_radius 均取全局值，
/// 保证创作者中心与其他页面左右边距、圆角风格一致。
class AuthorStyle {
  const AuthorStyle._();

  /// TODO 页面内容最大宽度，兼容平板和桌面端。
  static const double content_max_width = 760;

  /// TODO 页面水平留白，与全局 LayoutConfig 保持一致。
  static const double page_padding = LayoutConfig.page_horizontal_padding;

  /// TODO 区块圆角，与全局 LayoutConfig 保持一致。
  static const double section_radius = LayoutConfig.section_radius;

  /// TODO 小型卡片圆角，与全局 LayoutConfig 保持一致。
  static const double card_radius = LayoutConfig.card_radius;

  /// TODO 胶囊圆角。
  static const double pill_radius = 999;

  /// TODO 区块纵向间距。
  static const double section_spacing = 22;

  /// TODO CJK 主标题字号。
  static const double hero_title_size_cjk = 25;

  /// TODO 非 CJK 主标题字号。
  static const double hero_title_size_alphabetic = 22;

  /// TODO CJK 按钮字号。
  static const double button_font_size_cjk = 14;

  /// TODO 非 CJK 按钮字号。
  static const double button_font_size_alphabetic = 12.5;

  /// TODO CJK 状态标签字号。
  static const double status_font_size_cjk = 12;

  /// TODO 非 CJK 状态标签字号。
  static const double status_font_size_alphabetic = 10.5;

  /// TODO 标题字重。
  static final FontWeight title_weight = FontConfig.adjustedWeight(
    FontWeight.w600,
  );

  /// TODO 强调字重。
  static final FontWeight emphasis_weight = FontConfig.adjustedWeight(
    FontWeight.w500,
  );

  /// TODO 正文字重。
  static final FontWeight body_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );

  /// TODO 日间页面背景色。
  static const Color light_background = Color(0xFFF7F7F4);

  /// TODO 夜间页面背景色。
  static const Color dark_background = Color(0xFF0D0E14);

  /// TODO 夜间卡片颜色。
  static const Color dark_surface = Color(0xFF181A24);

  /// TODO 夜间次级卡片颜色。
  static const Color dark_surface_secondary = Color(0xFF202330);

  /// TODO 日间主文字颜色。
  static const Color light_primary_text = Color(0xFF17191F);

  /// TODO 日间次级文字颜色。
  static const Color light_secondary_text = Color(0xFF777A84);

  /// TODO 夜间次级文字颜色。
  static const Color dark_secondary_text = Color(0xFFA6A9B4);

  /// TODO 创作者中心暖金强调色，与 ColorConstants.themeColor 一致。
  static const Color gold = Color(0xFFF8D02D);

  /// TODO 深金色，保证日间背景上的文字对比度。
  static const Color deep_gold = Color(0xFF9A7300);

  /// TODO 蓝色强调色。
  static const Color blue = Color(0xFF6596FF);

  /// TODO 珊瑚强调色。
  static const Color coral = Color(0xFFFF8A72);

  /// TODO 绿色成功色。
  static const Color green = Color(0xFF55B98A);

  /// TODO 紫色定时状态色。
  static const Color purple = Color(0xFF9A86FF);

  /// TODO 根据主题返回页面背景色。
  static Color background(bool is_dark) {
    return is_dark ? dark_background : light_background;
  }

  /// TODO 根据主题返回卡片颜色。
  static Color surface(bool is_dark) {
    return is_dark ? dark_surface : Colors.white;
  }

  /// TODO 根据主题返回次级卡片颜色。
  static Color secondary_surface(bool is_dark) {
    return is_dark ? dark_surface_secondary : const Color(0xFFF1F2F5);
  }

  /// TODO 根据主题返回主文字颜色。
  static Color primary_text(bool is_dark) {
    return is_dark ? Colors.white : light_primary_text;
  }

  /// TODO 根据主题返回次级文字颜色。
  static Color secondary_text(bool is_dark) {
    return is_dark ? dark_secondary_text : light_secondary_text;
  }

  /// TODO 根据主题返回描边颜色。
  static Color border(bool is_dark) {
    return is_dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE7E7E2);
  }

  /// TODO 创作者头图渐变，与 user_info 统计卡片风格对齐。
  static LinearGradient hero_gradient(bool is_dark) {
    if (is_dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF262113), Color(0xFF17140E)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFFFF4D3), Color(0xFFFFFCF0)],
    );
  }
}
