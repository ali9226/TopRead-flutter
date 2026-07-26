import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/config/font_config.dart';

/// 阅读设置弹窗组件。
///
/// 从屏幕底部滑出的半屏弹窗，展示阅读设置选项：
/// - 字号调节（增加/减少）
/// - 主题切换（日间/夜间，带遮罩层图标过渡效果）
class ReadSettingsSheet extends StatefulWidget {
  /// 当前字号。
  final RxDouble body_font_size;

  /// 字号最小值。
  final double font_size_min;

  /// 字号最大值。
  final double font_size_max;

  /// 增加字号回调。
  final VoidCallback on_increase_font_size;

  /// 减少字号回调。
  final VoidCallback on_decrease_font_size;

  /// 关闭弹窗回调。
  final VoidCallback on_close;

  /// 自动阅读回调（关闭弹窗并开始自动滚动）。
  final VoidCallback on_auto_read;

  const ReadSettingsSheet({
    super.key,
    required this.body_font_size,
    required this.font_size_min,
    required this.font_size_max,
    required this.on_increase_font_size,
    required this.on_decrease_font_size,
    required this.on_close,
    required this.on_auto_read,
  });

  @override
  State<ReadSettingsSheet> createState() => _ReadSettingsSheetState();
}

class _ReadSettingsSheetState extends State<ReadSettingsSheet>
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

  /// 显示主题切换遮罩层。
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
      // 弹窗关闭时动画会取消，由 finally 统一清理 Overlay。
    } finally {
      _theme_overlay_controller.removeListener(animation_listener);
      _overlay_entry?.remove();
      _overlay_entry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    final double screen_height = MediaQuery.of(context).size.height;
    final double max_height = screen_height * 0.9;

    return Obx(() {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      final Color bg_color = is_dark ? const Color(0xFF161B22) : Colors.white;

      return Container(
        constraints: BoxConstraints(maxHeight: max_height),
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(is_dark: is_dark),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildFontSizeRow(is_dark: is_dark),
                    const SizedBox(height: 20),
                    _buildThemeRow(is_dark: is_dark),
                    const SizedBox(height: 24),
                    _buildOtherSection(is_dark: is_dark),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建顶部标题栏。
  Widget _buildHeader({required bool is_dark}) {
    final Color title_color = is_dark ? Colors.white : const Color(0xFF1F1A12);

    final Color icon_color = is_dark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF7A6A56);

    final Color divider_color = is_dark
        ? const Color(0xFF21262D)
        : const Color(0xFFEEEEEE);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BottomSheetDragHandle(is_dark: is_dark),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: <Widget>[
              Text(
                tr('short_story_read.reading_settings'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: title_color,
                ),
              ),
              const Spacer(),
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
        Divider(height: 0.5, color: divider_color),
      ],
    );
  }

  /// 计算标题列宽。
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
    final Color title_color = is_dark ? Colors.white : const Color(0xFF1F1A12);

    final double current_size = widget.body_font_size.value;
    final bool can_increase = current_size < widget.font_size_max;
    final bool can_decrease = current_size > widget.font_size_min;
    final double label_width = _calculate_label_width(context);

    return Row(
      children: <Widget>[
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
        Expanded(
          child: _buildCapsuleButton(
            is_dark: is_dark,
            icon: 'font_size_reduce',
            is_enabled: can_decrease,
            onTap: widget.on_decrease_font_size,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildAnimatedFontSize(
            current_size: current_size,
            title_color: title_color,
          ),
        ),
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
    final Color title_color = is_dark ? Colors.white : const Color(0xFF1F1A12);

    final double label_width = _calculate_label_width(context);

    return Row(
      children: <Widget>[
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

  /// 构建胶囊按钮。
  Widget _buildCapsuleButton({
    required bool is_dark,
    required String icon,
    required bool is_enabled,
    required VoidCallback onTap,
  }) {
    final Color bg_color = is_dark
        ? (is_enabled
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.08))
        : (is_enabled
              ? const Color(0xFF7A6A56).withValues(alpha: 0.10)
              : const Color(0xFF7A6A56).withValues(alpha: 0.05));

    final Color icon_color = is_dark
        ? (is_enabled ? Colors.white : Colors.white.withValues(alpha: 0.3))
        : (is_enabled
              ? const Color(0xFF1F1A12)
              : const Color(0xFF7A6A56).withValues(alpha: 0.3));

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

  /// 构建其它区域（"其它"标题 + 自动阅读按钮）。
  Widget _buildOtherSection({required bool is_dark}) {
    final Color title_color = is_dark ? Colors.white : const Color(0xFF1F1A12);

    final double label_width = _calculate_label_width(context);

    return Row(
      children: <Widget>[
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
        Expanded(
          child: GestureDetector(
            onTap: widget.on_auto_read,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: is_dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFF7A6A56).withValues(alpha: 0.10),
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
}
