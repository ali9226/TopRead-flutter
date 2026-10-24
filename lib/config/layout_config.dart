// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';

/// 页面级通用布局配置。
class LayoutConfig {
  /// 全局页面左右基础边距。
  static const double page_horizontal_padding = space_12;

  /// 普通内容页的可读宽度；展开窗口增加内容列数，文字和触控目标保持原尺寸。
  static const double page_max_width = 900;

  /// 小说正文的最大行宽，避免展开后每行过长、收起后文字被整体缩小。
  static const double reader_max_width = 760;

  /// 登录和注册表单的最大宽度。
  static const double form_max_width = 560;

  /// 共用间距阶梯，单位为逻辑像素。
  ///
  /// 只供 padding、margin、控件之间的留白使用，不兼作字号、圆角或业务尺寸。
  /// 数字后缀表示阶梯的基准值，页面专用样式通过语义常量引用本表。
  /// 发丝级间距。
  static const double space_1 = 1;

  /// 最细间距。
  static const double space_2 = 2;

  /// 紧凑文字内部间距。
  static const double space_3 = 3;

  /// 微小间距。
  static const double space_4 = 4;

  /// 图标微调间距。
  static const double space_5 = 5;

  /// 小标签内部间距。
  static const double space_6 = 6;

  /// 紧凑元数据间距。
  static const double space_7 = 7;

  /// 紧凑内容间距。
  static const double space_8 = 8;

  /// 元数据行间距。
  static const double space_9 = 9;

  /// 小控件内部间距。
  static const double space_10 = 10;

  /// 常规内容间距。
  static const double space_12 = 12;

  /// 舒适控件间距。
  static const double space_14 = 14;

  /// 标准分组内部间距。
  static const double space_16 = 16;

  /// 宽松控件间距。
  static const double space_18 = 18;

  /// 宽松内容间距。
  static const double space_20 = 20;

  /// 标题区域间距。
  static const double space_22 = 22;

  /// 区块内部间距。
  static const double space_24 = 24;

  /// 大卡片内部间距。
  static const double space_26 = 26;

  /// 区块之间间距。
  static const double space_28 = 28;

  /// 表单段落间距。
  static const double space_30 = 30;

  /// 大区块之间间距。
  static const double space_32 = 32;

  /// 空状态内部间距。
  static const double space_36 = 36;

  /// 页面段落间距。
  static const double space_40 = 40;

  /// 大段落间距。
  static const double space_44 = 44;

  /// 展开区域间距。
  static const double space_48 = 48;

  /// 大面积分隔间距。
  static const double space_56 = 56;

  /// 空状态上下间距。
  static const double space_60 = 60;

  /// 页面顶部间距。
  static const double space_64 = 64;

  /// 大空状态间距。
  static const double space_72 = 72;

  /// 页面底部间距。
  static const double space_80 = 80;

  /// 紧凑行内控件间距。
  static const double space_11 = 11;

  /// 紧凑区块间距。
  static const double space_15 = 15;

  /// 装饰纹理间距。
  static const double space_34 = 34;

  /// 大型空状态间距。
  static const double space_96 = 96;

  /// 共用圆角阶梯，单位为逻辑像素；阴影 blurRadius 不使用本表。
  /// 精细描边圆角。
  static const double radius_1 = 1;

  /// 进度条圆角。
  static const double radius_2 = 2;

  /// 微型标记圆角。
  static const double radius_3 = 3;

  /// 微型标签圆角。
  static const double radius_4 = 4;

  /// 紧凑封面圆角。
  static const double radius_5 = 5;

  /// 小标签圆角。
  static const double radius_6 = 6;

  /// 小型封面与控件圆角。
  static const double radius_8 = 8;

  /// 紧凑控件圆角。
  static const double radius_10 = 10;

  /// 常规控件圆角。
  static const double radius_12 = 12;

  /// 输入与筛选控件圆角。
  static const double radius_14 = 14;

  /// 大控件圆角。
  static const double radius_16 = 16;

  /// 内容卡片圆角。
  static const double radius_18 = 18;

  /// 面板圆角。
  static const double radius_20 = 20;

  /// 表单卡片圆角。
  static const double radius_22 = 22;

  /// 弹窗与抽屉圆角。
  static const double radius_24 = 24;

  /// 大型卡片圆角。
  static const double radius_26 = 26;

  /// 主操作区域圆角。
  static const double radius_28 = 28;

  /// 装饰面板圆角。
  static const double radius_30 = 30;

  /// 大尺寸面板圆角。
  static const double radius_32 = 32;

  /// 大型装饰卡片圆角。
  static const double radius_36 = 36;

  /// 大幅背景圆角。
  static const double radius_40 = 40;

  /// 小型井槽圆角。
  static const double radius_9 = 9;

  /// 紧凑圆形控件圆角。
  static const double radius_11 = 11;

  /// 紧凑操作按钮圆角。
  static const double radius_15 = 15;

  /// 托盘与操作栏圆角。
  static const double radius_19 = 19;

  /// 紧凑主按钮圆角。
  static const double radius_23 = 23;

  /// 圆形操作卡片圆角。
  static const double radius_25 = 25;

  /// 大尺寸主按钮圆角。
  static const double radius_27 = 27;

  /// 胶囊圆角；实际裁切仍由控件短边决定，避免各处散落 99/100/999。
  static const double radius_pill = 999;

  /// 内容卡片的默认圆角。
  static const double card_radius = radius_18;

  /// 分组区域默认圆角，与内容卡片保持一致。
  static const double section_radius = card_radius;

  /// 微型标签的默认圆角。
  static const double tag_radius = radius_4;

  /// 通用圆形操作与图标按钮的触控边长。
  static const double touch_target_size = 48;

  /// 密集导航、列表内操作的最小触控边长。
  static const double compact_control_height = 44;

  /// 常规主要操作按钮高度。
  static const double button_height = touch_target_size;

  /// 高强调主操作按钮高度。
  static const double prominent_button_height = 56;

  /// 通用导航栏高度；内容区域额外叠加系统安全区。
  static const double navigation_bar_height = 52;

  /// 小型辅助图标尺寸。
  static const double icon_small = 16;

  /// 紧凑操作图标尺寸。
  static const double icon_medium = 20;

  /// 浮动操作图标尺寸。
  static const double icon_compact = 22;

  /// 常规导航与工具图标尺寸。
  static const double icon_regular = 24;

  /// 根据当前页面上下边距构建统一的页面 padding。
  static EdgeInsets page_padding({
    required double top,
    required double bottom,
  }) {
    return const EdgeInsets.symmetric(
      horizontal: page_horizontal_padding,
    ).copyWith(top: top, bottom: bottom);
  }
}
