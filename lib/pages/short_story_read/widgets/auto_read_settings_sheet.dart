import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config/font_config.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/util/device/save_body_font_size.dart';

/// 自动阅读设置弹窗组件。
///
/// 从底部弹出，包含：
/// - 速度调节滑块（慢 ↔ 快，拖动时显示百分比吐司）
/// - 退出自动阅读按钮
class AutoReadSettingsSheet extends StatefulWidget {
  /// 页面逻辑层。
  final ShortStoryReadLogic logic;

  /// 关闭弹窗回调。
  final VoidCallback on_close;

  /// 退出自动阅读回调。
  final VoidCallback on_exit;

  const AutoReadSettingsSheet({
    super.key,
    required this.logic,
    required this.on_close,
    required this.on_exit,
  });

  @override
  State<AutoReadSettingsSheet> createState() => _AutoReadSettingsSheetState();
}

class _AutoReadSettingsSheetState extends State<AutoReadSettingsSheet> {
  /// 是否正在拖动滑块。
  bool _is_dragging = false;

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    final bool is_dark = device_info.theme.value == ThemeMode.dark;

    /// 弹窗背景色。
    final Color bg_color = is_dark
        ? ShortStoryReadStyle.catalog_sheet_dark_bg
        : ShortStoryReadStyle.catalog_sheet_light_bg;

    /// 屏幕高度。
    final double screen_height = MediaQuery.of(context).size.height;
    final double max_height = screen_height * 0.9;

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

          /// 速度调节区域（带吐司弹窗）。
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildSpeedSection(is_dark: is_dark),
          ),

          /// 退出自动阅读按钮。
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: _buildExitButton(is_dark: is_dark),
          ),
        ],
      ),
    );
  }

  /// 构建顶部标题栏。
  Widget _buildHeader({required bool is_dark}) {
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    final Color icon_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

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
              Text(
                tr('short_story_read.auto_read_settings'),
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
                  child: SvgIcon(
                    name: 'close',
                    width: 16,
                    height: 16,
                    color: icon_color,
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

  /// 构建速度调节区域（慢 + 滑块 + 快 + 吐司弹窗）。
  Widget _buildSpeedSection({required bool is_dark}) {
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    final Color track_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color.withValues(alpha: 0.15)
        : ShortStoryReadStyle.secondary_light_color.withValues(alpha: 0.15);

    final Color thumb_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.bottom_bar_light_bg;

    final Color thumb_shadow_color = is_dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.15);

    return Obx(() {
      /// 当前速度百分比。
      final int percentage = (widget.logic.auto_read_speed.value * 100).round();

      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          /// 慢 + 滑块 + 快。
          Row(
            children: <Widget>[
              Text(
                tr('short_story_read.speed_slow'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  color: title_color,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: ShortStoryReadStyle.progress_track_height,
                    activeTrackColor: track_color,
                    inactiveTrackColor: track_color,
                    thumbColor: thumb_color,
                    thumbShape: _CircleThumbShape(
                      thumbSize: ShortStoryReadStyle.progress_thumb_size,
                      shadowColor: thumb_shadow_color,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: widget.logic.auto_read_speed.value,
                    onChangeStart: (_) {
                      setState(() {
                        _is_dragging = true;
                      });
                    },
                    onChanged: (double value) {
                      widget.logic.auto_read_speed.value = value;
                    },
                    onChangeEnd: (double value) {
                      save_auto_read_speed(value);
                      setState(() {
                        _is_dragging = false;
                      });
                    },
                  ),
                ),
              ),
              Text(
                tr('short_story_read.speed_fast'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  color: title_color,
                ),
              ),
            ],
          ),

          /// 拖动时显示的百分比吐司（绝对定位，不影响布局）。
          if (_is_dragging)
            Positioned(
              top: -32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  /// 构建退出自动阅读按钮。
  Widget _buildExitButton({required bool is_dark}) {
    return GestureDetector(
      onTap: widget.on_exit,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: is_dark
              ? ShortStoryReadStyle.secondary_dark_color.withValues(alpha: 0.10)
              : ShortStoryReadStyle.secondary_light_color.withValues(
                  alpha: 0.08,
                ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SvgIcon(
              name: 'quit',
              width: 18,
              height: 18,
              color: Color(0xFFE54D4D),
            ),
            const SizedBox(width: 8),
            Text(
              tr('short_story_read.exit_auto_read'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: Color(0xFFE54D4D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自定义圆形滑块形状（带投影）。
class _CircleThumbShape extends SliderComponentShape {
  final double thumbSize;
  final Color shadowColor;

  const _CircleThumbShape({required this.thumbSize, required this.shadowColor});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbSize, thumbSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint shadow_paint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 1), thumbSize / 2, shadow_paint);

    final Paint thumb_paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.white;
    canvas.drawCircle(center, thumbSize / 2, thumb_paint);
  }
}
