// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

import '../style.dart';

/// 单个底部导航按钮组件。
///
/// 这个子组件只负责：
/// 1. 提供统一点击热区；
/// 2. 把不同尺寸的图标放进固定槽位里垂直居中；
/// 3. 处理图标缩放和透明度反馈；
/// 4. 右上角显示未读数角标（可选）。
class NavigationItem extends StatelessWidget {
  /// 当前按钮对应的路由路径。
  final String tab_path;

  /// 当前按钮展示的图标资源名。
  final String icon_name;

  /// 当前按钮是否选中。
  final bool is_active;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 按下手势回调。
  final GestureTapDownCallback on_tap_down;

  /// 点击回调。
  final VoidCallback on_tap;

  /// 角标数量（0 或 null 不显示）。
  final int badge_count;

  const NavigationItem({
    super.key,
    required this.tab_path,
    required this.icon_name,
    required this.is_active,
    required this.is_dark,
    required this.on_tap_down,
    required this.on_tap,
    this.badge_count = 0,
  });

  /// 当前图标的实际显示尺寸。
  double get _icon_size {
    return Style.icon_size(tab_path: tab_path, is_active: is_active);
  }

  /// 当前图标的缩放倍率。
  double get _icon_scale {
    return Style.icon_scale(tab_path: tab_path, is_active: is_active);
  }

  /// 当前图标的纵向偏移。
  double get _icon_offset_y {
    return Style.icon_offset_y(tab_path: tab_path, is_active: is_active);
  }

  /// 当前图标的夜间模式着色。
  Color? get _icon_color {
    if (!is_dark) {
      return null;
    }
    return is_active
        ? Style.night_active_icon_color()
        : Style.night_inactive_icon_color();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTapDown: on_tap_down,
        onTap: on_tap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        radius: Style.navigation_item_radius,
        containedInkWell: false,
        child: SizedBox(
          height: Style.navigation_item_height,
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: Style.icon_scale_duration,
              curve: Curves.elasticOut,
              tween: Tween<double>(
                begin: is_active ? 0.58 : 1.08,
                end: _icon_scale,
              ),
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedOpacity(
                duration: Style.icon_opacity_duration,
                curve: Curves.easeOutCubic,
                opacity: is_active ? 1 : 0.9,
                child: SizedBox(
                  width: Style.icon_slot_width,
                  height: Style.icon_slot_height,
                  child: Center(
                    child: AnimatedSlide(
                      duration: Style.icon_anim_duration,
                      curve: Curves.elasticOut,
                      offset: is_active
                          ? Offset(0, _icon_offset_y / _icon_size)
                          : Offset(0, 0.20 + _icon_offset_y / _icon_size),
                      child: AnimatedContainer(
                        duration: Style.icon_anim_duration,
                        curve: Curves.easeOutBack,
                        width: _icon_size,
                        height: _icon_size,
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SvgIcon(
                              name: icon_name,
                              color: _icon_color,
                              width: _icon_size,
                              height: _icon_size,
                            ),
                            // TODO 未读数角标
                            if (badge_count > 0)
                              Positioned(
                                top: -4,
                                right: -8,
                                child: _Badge(count: badge_count),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 未读数角标组件。
///
/// 红色圆形背景 + 白色数字，最多显示 99。
class _Badge extends StatelessWidget {
  /// 未读数量。
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    // TODO 超过99显示 99+
    final String text = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: ColorConstants.dangerColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.dangerColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
          height: 1.0,
        ),
        textAlign: TextAlign.center,
        strutStyle: StrutStyle(
          fontSize: 10,
          height: 1.0,
          forceStrutHeight: true,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
        ),
      ),
    );
  }
}
