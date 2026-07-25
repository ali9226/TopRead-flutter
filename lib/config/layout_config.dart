import 'package:flutter/material.dart';

/// 页面级通用布局配置。
class LayoutConfig {
  /// 全局页面左右基础边距。
  static const double page_horizontal_padding = 12;


  /*
    内容卡片圆角，用到的位置：
      首页今日推荐卡片
      首页短篇榜卡片
      message 未登录按钮
   */
  static const double card_radius = 18.0;

  /*
    分组/区域圆角，用到的位置：
      user_info 统计卡片（关注/粉丝/点赞）
      user_info 操作按钮（充值/提现）
      user_info 操作列表分组外层卡片
      user_info 操作列表分组内层列表
      user_info 头像操作卡片（夜间模式）
      user_info 底部弹窗卡片
      user_info 底部弹窗按钮
      message 概览统计卡
      message 消息卡片
   */
  static const double section_radius = 18.0;

  /*
    标签/封面圆角，用到的位置：
      首页短篇榜卡片内分类标签
      首页榜单书籍封面
      首页骨架屏榜单封面
   */
  static const double tag_radius = 4.0;

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
