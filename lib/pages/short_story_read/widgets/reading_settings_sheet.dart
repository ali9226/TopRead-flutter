import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/config/font_config.dart';

/// 阅读设置弹窗组件。
///
/// 从屏幕底部滑出的半屏弹窗，展示阅读设置选项：
/// - 字号调节（增加/减少，范围 16 ~ 36）
/// - 主题切换（日间/夜间，带遮罩层图标过渡效果）
class ReadingSettingsSheet extends StatefulWidget {
  /// 页面逻辑层（管理字号状态）。
  final ShortStoryReadLogic logic;

  /// 关闭弹窗回调。
  final VoidCallback on_close;

  /// 自动阅读回调（关闭弹窗并开始自动滚动）。
  final VoidCallback on_auto_read;

  /// 减小字号回调，用于让阅读页在重新排版后保持原阅读进度。
  final VoidCallback on_decrease_font_size;

  /// 增大字号回调，用于让阅读页在重新排版后保持原阅读进度。
  final VoidCallback on_increase_font_size;

  const ReadingSettingsSheet({
    super.key,
    required this.logic,
    required this.on_close,
    required this.on_auto_read,
    required this.on_decrease_font_size,
    required this.on_increase_font_size,
  });

  @override
  State<ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<ReadingSettingsSheet>
    with SingleTickerProviderStateMixin {
  /// 主题切换动画控制器（1.2 秒：0→1 淡入，1→0 淡出）。
  late AnimationController _theme_overlay_controller;

  /// 主题切换遮罩透明度动画。
  late Animation<double> _theme_overlay_opacity;

  /// 遮罩层 OverlayEntry。
  OverlayEntry? _overlay_entry;

  @override
  void initState() {
    super.initState();
    _theme_overlay_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _theme_overlay_opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_theme_overlay_controller);
  }

  @override
  void dispose() {
    _theme_overlay_controller.dispose();
    _overlay_entry?.remove();
    _overlay_entry = null;
    super.dispose();
  }

  /// 显示主题切换遮罩层（与 user_info 页面效果一致）。
  Future<void> _show_theme_overlay(bool to_dark) async {
    if (_overlay_entry != null || _theme_overlay_controller.isAnimating) {
      return;
    }

    bool theme_changed = false;
    final OverlayState overlay_state = Overlay.of(context, rootOverlay: true);

    _overlay_entry = OverlayEntry(
      builder: (BuildContext context) {
        return AnimatedBuilder(
          animation: _theme_overlay_opacity,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: <Widget>[
                const ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
                Opacity(
                  opacity: _theme_overlay_opacity.value,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: Center(
                      child: Transform.scale(
                        scale: 0.5 + 0.5 * _theme_overlay_opacity.value,
                        child: SvgIcon(
                          name: to_dark ? 'moon' : 'sun',
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay_state.insert(_overlay_entry!);

    void animation_listener() {
      if (_theme_overlay_controller.value >= 0.5 && !theme_changed) {
        theme_changed = true;
        final DeviceInfo device_info = Get.find<DeviceInfo>();
        device_info.changeTheme(to_dark ? ThemeMode.dark : ThemeMode.light);
      }
    }

    _theme_overlay_controller.addListener(animation_listener);
    try {
      await _theme_overlay_controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      // 页面关闭时动画会被取消，由 finally 统一释放 Overlay。
    } finally {
      _theme_overlay_controller.removeListener(animation_listener);
      _overlay_entry?.remove();
      _overlay_entry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 设备信息仓库（获取当前主题模式）。
    final DeviceInfo device_info = Get.find<DeviceInfo>();

    /// 屏幕高度（用于限制弹窗最大高度）。
    final double screen_height = MediaQuery.of(context).size.height;

    /// 弹窗最大高度（屏幕高度的 90%）。
    final double max_height = screen_height * 0.9;

    return Obx(() {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      /// 弹窗背景色。
      final Color bg_color = is_dark
          ? ShortStoryReadStyle.catalog_sheet_dark_bg
          : ShortStoryReadStyle.catalog_sheet_light_bg;

      return Container(
        constraints: BoxConstraints(maxHeight: max_height),
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /// 顶部标题栏。
            _buildHeader(is_dark: is_dark),

            /// 设置内容区域。
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      /// 第一行：字号调节。
                      _buildFontSizeRow(is_dark: is_dark),

                      const SizedBox(height: 20),

                      /// 第二行：主题切换。
                      _buildThemeRow(is_dark: is_dark),

                      const SizedBox(height: 24),

                      /// 第三行：其它标题。
                      _buildOtherSection(is_dark: is_dark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建顶部标题栏（标题 + 关闭按钮）。
  Widget _buildHeader({required bool is_dark}) {
    /// 标题文字颜色。
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    /// 关闭图标颜色。
    final Color icon_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 分割线颜色。
    final Color divider_color = is_dark
        ? ShortStoryReadStyle.bottom_bar_dark_divider
        : ShortStoryReadStyle.bottom_bar_light_divider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BottomSheetDragHandle(is_dark: is_dark),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: <Widget>[
              /// 标题文字（粗细 500）。
              Text(
                tr('short_story_read.reading_settings'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: title_color,
                ),
              ),

              const Spacer(),

              /// 关闭按钮。
              GestureDetector(
                onTap: widget.on_close,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/svg/close.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(icon_color, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 底部分割线。
        Divider(height: 0.5, color: divider_color),
      ],
    );
  }

  /// 计算两行标题中较长的那个宽度，用于统一标题列宽。
  /// 加 1px 余量防止亚像素舍入导致换行。
  double _calculate_label_width(BuildContext context) {
    final TextStyle label_style = TextStyle(
      fontSize: 15,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );

    final TextPainter size_painter = TextPainter(
      text: TextSpan(
        text: tr('short_story_read.font_size'),
        style: label_style,
      ),
      textDirection: Directionality.of(context),
    )..layout();

    final TextPainter theme_painter = TextPainter(
      text: TextSpan(text: tr('short_story_read.theme'), style: label_style),
      textDirection: Directionality.of(context),
    )..layout();

    final double max_width = size_painter.width > theme_painter.width
        ? size_painter.width
        : theme_painter.width;

    return max_width.ceilToDouble() + 1;
  }

  /// 构建字号调节行。
  Widget _buildFontSizeRow({required bool is_dark}) {
    /// 标题文字颜色。
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    /// 当前字号。
    final double current_size = widget.logic.body_font_size.value;

    /// 是否可以增加。
    final bool can_increase = current_size < ShortStoryReadLogic.font_size_max;

    /// 是否可以减少。
    final bool can_decrease = current_size > ShortStoryReadLogic.font_size_min;

    /// 标题列统一宽度。
    final double label_width = _calculate_label_width(context);

    return Row(
      children: <Widget>[
        /// 标题（固定宽度，与主题行对齐）。
        SizedBox(
          width: label_width,
          child: Text(
            tr('short_story_read.font_size'),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: title_color,
            ),
          ),
        ),

        const SizedBox(width: 16),

        /// 减少按钮（Expanded 等分）。
        Expanded(
          child: _buildCapsuleButton(
            is_dark: is_dark,
            icon: 'font_size_reduce',
            is_enabled: can_decrease,
            onTap: widget.on_decrease_font_size,
          ),
        ),

        /// 当前字号数字（带滚动动画）。
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildAnimatedFontSize(
            current_size: current_size,
            title_color: title_color,
          ),
        ),

        /// 增加按钮（Expanded 等分）。
        Expanded(
          child: _buildCapsuleButton(
            is_dark: is_dark,
            icon: 'font_size_add',
            is_enabled: can_increase,
            onTap: widget.on_increase_font_size,
          ),
        ),
      ],
    );
  }

  /// 构建带滚动动画的字号数字。
  Widget _buildAnimatedFontSize({
    required double current_size,
    required Color title_color,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ClipRect(
          child: SizeTransition(
            sizeFactor: animation,
            alignment: AlignmentDirectional.topStart,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        current_size.round().toString(),
        key: ValueKey<int>(current_size.round()),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          color: title_color,
        ),
      ),
    );
  }

  /// 构建主题切换行。
  Widget _buildThemeRow({required bool is_dark}) {
    /// 标题文字颜色。
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    /// 标题列统一宽度。
    final double label_width = _calculate_label_width(context);

    return Row(
      children: <Widget>[
        /// 标题（固定宽度，与字号行对齐）。
        SizedBox(
          width: label_width,
          child: Text(
            tr('short_story_read.theme'),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: title_color,
            ),
          ),
        ),

        const SizedBox(width: 16),

        /// 日间按钮（日间模式下红色边框）。
        Expanded(
          child: _buildThemeCapsule(
            is_dark: is_dark,
            label: tr('short_story_read.theme_day'),
            is_selected: !is_dark,
            background_color: Colors.white,
            text_color: const Color(0xFF333333),
            border_color: !is_dark ? ColorConstants.dangerColor : null,
            onTap: () {
              if (is_dark) {
                unawaited(_show_theme_overlay(false));
              }
            },
          ),
        ),

        const SizedBox(width: 10),

        /// 夜间按钮（夜间模式下红色边框）。
        Expanded(
          child: _buildThemeCapsule(
            is_dark: is_dark,
            label: tr('short_story_read.theme_night'),
            is_selected: is_dark,
            background_color: const Color(0xFF1A1A1A),
            text_color: Colors.white,
            border_color: is_dark ? ColorConstants.dangerColor : null,
            onTap: () {
              if (!is_dark) {
                unawaited(_show_theme_overlay(true));
              }
            },
          ),
        ),
      ],
    );
  }

  /// 构建其它区域（"其它"标题 + 自动阅读按钮在同一行）。
  Widget _buildOtherSection({required bool is_dark}) {
    /// 标题文字颜色。
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    /// 标题列统一宽度。
    final double label_width = _calculate_label_width(context);

    return Row(
      children: <Widget>[
        /// 标题"其它"（与字号/主题对齐）。
        SizedBox(
          width: label_width,
          child: Text(
            tr('short_story_read.other'),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: title_color,
            ),
          ),
        ),

        const SizedBox(width: 16),

        /// 自动阅读按钮（Expanded 占满剩余宽度）。
        Expanded(
          child: GestureDetector(
            onTap: widget.on_auto_read,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: is_dark
                    ? ShortStoryReadStyle.secondary_dark_color.withValues(
                        alpha: 0.15,
                      )
                    : ShortStoryReadStyle.secondary_light_color.withValues(
                        alpha: 0.10,
                      ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  tr('short_story_read.auto_read'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    color: title_color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建胶囊按钮（字号增加/减少）。
  Widget _buildCapsuleButton({
    required bool is_dark,
    required String icon,
    required bool is_enabled,
    required VoidCallback onTap,
  }) {
    /// 胶囊背景色。
    final Color bg_color = is_dark
        ? (is_enabled
              ? ShortStoryReadStyle.secondary_dark_color.withValues(alpha: 0.15)
              : ShortStoryReadStyle.secondary_dark_color.withValues(
                  alpha: 0.08,
                ))
        : (is_enabled
              ? ShortStoryReadStyle.secondary_light_color.withValues(
                  alpha: 0.10,
                )
              : ShortStoryReadStyle.secondary_light_color.withValues(
                  alpha: 0.05,
                ));

    /// 图标颜色。
    final Color icon_color = is_dark
        ? (is_enabled
              ? ShortStoryReadStyle.title_dark_color
              : ShortStoryReadStyle.secondary_dark_color.withValues(alpha: 0.3))
        : (is_enabled
              ? ShortStoryReadStyle.title_light_color
              : ShortStoryReadStyle.secondary_light_color.withValues(
                  alpha: 0.3,
                ));

    return GestureDetector(
      onTap: is_enabled ? onTap : null,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/svg/$icon.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(icon_color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  /// 构建主题胶囊按钮。
  ///
  /// [border_color] 为 null 时不显示边框。
  Widget _buildThemeCapsule({
    required bool is_dark,
    required String label,
    required bool is_selected,
    required Color background_color,
    required Color text_color,
    Color? border_color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: background_color,
          borderRadius: BorderRadius.circular(18),
          border: border_color != null
              ? Border.all(color: border_color, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: text_color,
            ),
          ),
        ),
      ),
    );
  }
}
