import 'package:app/components/reader_theme_options/index.dart';
import 'dart:async';
import 'package:app/components/reader_theme_transition/index.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/config/color_config.dart';
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
  /// TODO 与小说、漫画共用主题转场，关闭弹窗时同步清理动画与遮罩。
  late final ReaderThemeTransition _theme_transition;

  @override
  void initState() {
    super.initState();
    _theme_transition = ReaderThemeTransition(vsync: this);
  }

  @override
  void dispose() {
    _theme_transition.dispose();
    super.dispose();
  }

  Future<void> _show_theme_overlay(bool to_dark) =>
      _theme_transition.change(context, to_dark: to_dark);

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    final double screen_height = MediaQuery.of(context).size.height;
    final double max_height = screen_height * 0.9;

    return Obx(() {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      final Color bg_color = ColorConstants.sheetBackground(is_dark);

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

  /// 与漫画阅读器共用日夜胶囊，沿用各阅读器原本的主题转场。
  Widget _buildThemeRow({required bool is_dark}) => ReaderThemeOptions(
    is_dark: is_dark,
    label_width: _calculate_label_width(context),
    on_change: (to_dark) => unawaited(_show_theme_overlay(to_dark)),
  );

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
