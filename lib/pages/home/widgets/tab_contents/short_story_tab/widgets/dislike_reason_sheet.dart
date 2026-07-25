import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:get/get.dart';
import 'package:app/config/font_config.dart';

import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/models/home_classification.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';

/// 不喜欢理由底部弹窗组件。
///
/// 长按卡片后从底部弹出，展示不喜欢的理由选项，
/// 支持手势下拉关闭和点击遮罩层关闭。
///
/// 参数说明：
/// [is_dark] - 当前是否为夜间模式。
/// [on_option_tap] - 用户点击某个选项后的回调，参数为选中的理由文本。
/// [on_close] - 弹窗关闭时的回调。
class DislikeReasonSheet extends StatefulWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 用户点击某个选项后的回调，参数为选中的理由文本。
  final ValueChanged<String>? on_option_tap;

  /// 弹窗关闭时的回调。
  final VoidCallback? on_close;

  /// 点击提示文字后跳转到兴趣偏好页面的回调。
  final VoidCallback? on_navigate_to_interest;

  const DislikeReasonSheet({
    super.key,
    required this.is_dark,
    this.on_option_tap,
    this.on_close,
    this.on_navigate_to_interest,
  });

  @override
  State<DislikeReasonSheet> createState() => _DislikeReasonSheetState();
}

class _DislikeReasonSheetState extends State<DislikeReasonSheet>
    with TickerProviderStateMixin {
  /// 弹窗面板动画控制器，控制滑入/滑出。
  late AnimationController _sheet_animation_controller;

  /// 弹窗面板滑入动画。
  late Animation<Offset> _sheet_slide_animation;

  /// 遮罩层淡入动画。
  late Animation<double> _overlay_fade_animation;

  /// 当前拖拽偏移量（正值=向下拖拽）。
  double _drag_offset = 0.0;

  /// 是否正在回弹动画中（回弹期间忽略手势拖拽）。
  bool _is_bouncing = false;

  @override
  void initState() {
    super.initState();
    _sheet_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sheet_slide_animation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sheet_animation_controller,
      curve: Curves.easeOutCubic,
    ));

    _overlay_fade_animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sheet_animation_controller,
      curve: Curves.easeOut,
    ));

    _sheet_animation_controller.forward();
  }

  @override
  void dispose() {
    _sheet_animation_controller.dispose();
    super.dispose();
  }

  /// 关闭弹窗动画，完成后执行 [on_after_dismiss] 回调。
  void _dismiss({VoidCallback? on_after_dismiss}) {
    _sheet_animation_controller.reverse().then((_) {
      widget.on_close?.call();
      on_after_dismiss?.call();
    });
  }

  /// 手势拖拽更新：仅允许向下拖拽，向上拖拽锁定在0。
  void _on_drag_update(DragUpdateDetails details) {
    if (_is_bouncing) return;
    final double new_offset = _drag_offset + details.delta.dy;
    if (new_offset >= 0) {
      setState(() {
        _drag_offset = new_offset;
      });
    }
  }

  /// 手势拖拽结束时的处理。
  void _on_drag_end(DragEndDetails details) {
    if (_is_bouncing) return;
    final double velocity = details.velocity.pixelsPerSecond.dy;
    final double screen_height = MediaQuery.of(context).size.height;

    if (velocity > 300 || _drag_offset > screen_height / 4) {
      _dismiss();
    } else {
      _bounce_back();
    }
  }

  /// 平滑回弹到初始位置。
  void _bounce_back() {
    if (_drag_offset <= 0) return;
    _is_bouncing = true;
    final double start_offset = _drag_offset;
    final int duration_ms = 250;

    late Animation<double> curve;
    final AnimationController ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration_ms),
    );
    curve = CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic);

    ctrl.addListener(() {
      if (mounted) {
        setState(() {
          _drag_offset = start_offset * (1.0 - curve.value);
        });
      }
    });

    ctrl.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        ctrl.dispose();
        if (mounted) {
          setState(() {
            _drag_offset = 0.0;
            _is_bouncing = false;
          });
        }
      }
    });

    ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    /// 从全局仓库获取不喜欢理由列表。
    final List<HomeClassification> dislike_list =
        Get.find<HomeBannerStore>().dislike_list;

    final Color bg_color = widget.is_dark
        ? ShortStoryTabStyle.dislike_popup_dark_bg
        : ShortStoryTabStyle.dislike_popup_light_bg;

    final Color option_bg = widget.is_dark
        ? ShortStoryTabStyle.dislike_option_dark_bg
        : ShortStoryTabStyle.dislike_option_light_bg;

    final Color option_text = widget.is_dark
        ? ShortStoryTabStyle.dislike_option_dark_text
        : ShortStoryTabStyle.dislike_option_light_text;

    final Color drag_handle_color = widget.is_dark
        ? ShortStoryTabStyle.dislike_drag_handle_dark_color
        : ShortStoryTabStyle.dislike_drag_handle_light_color;

    final Color hint_text = widget.is_dark
        ? ShortStoryTabStyle.dislike_hint_dark_text
        : ShortStoryTabStyle.dislike_hint_light_text;

    return AnimatedBuilder(
      animation: _sheet_animation_controller,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          children: <Widget>[
            /// 遮罩层：点击关闭弹窗。
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  color: ShortStoryTabStyle.dislike_overlay_color
                      .withValues(alpha: _overlay_fade_animation.value * 0.4),
                ),
              ),
            ),

            /// 底部弹窗面板：仅支持向下拖拽关闭。
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _sheet_slide_animation,
                child: GestureDetector(
                  onVerticalDragUpdate: _on_drag_update,
                  onVerticalDragEnd: _on_drag_end,
                  child: Transform.translate(
                    offset: Offset(0, _drag_offset),
                    child: Material(
                      color: bg_color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: ShortStoryTabStyle.dislike_popup_top_padding,
                              bottom: 8,
                            ),
                            child: Container(
                              width: ShortStoryTabStyle.dislike_popup_drag_handle_width,
                              height: ShortStoryTabStyle.dislike_popup_drag_handle_height,
                              decoration: BoxDecoration(
                                color: drag_handle_color,
                                borderRadius: BorderRadius.circular(
                                  ShortStoryTabStyle.dislike_popup_drag_handle_height / 2,
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              easy.tr('dislike_sheet.title'),
                              style: TextStyle(
                                fontSize: ShortStoryTabStyle.dislike_popup_title_font_size,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                color: option_text,
                              ),
                            ),
                          ),

                          Padding(
                            padding: ShortStoryTabStyle.dislike_popup_content_padding,
                            child: Wrap(
                              spacing: ShortStoryTabStyle.dislike_popup_option_column_spacing,
                              runSpacing: ShortStoryTabStyle.dislike_popup_option_row_spacing,
                              children: List<Widget>.generate(
                                dislike_list.length,
                                (int index) {
                                  return _build_option_item(
                                    text: dislike_list[index].title,
                                    bg_color: option_bg,
                                    text_color: option_text,
                                  );
                                },
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(
                              top: ShortStoryTabStyle.dislike_popup_hint_top_spacing,
                              bottom: ShortStoryTabStyle.dislike_popup_bottom_safe,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                _dismiss(
                                  on_after_dismiss: () {
                                    widget.on_navigate_to_interest?.call();
                                  },
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    easy.tr('dislike_sheet.hint'),
                                    style: TextStyle(
                                      fontSize: ShortStoryTabStyle.dislike_popup_hint_font_size,
                                      color: hint_text,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: hint_text,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建单个选项按钮。
  Widget _build_option_item({
    required String text,
    required Color bg_color,
    required Color text_color,
  }) {
    final double screen_width = MediaQuery.of(context).size.width;
    final double option_width =
        (screen_width - 40 - ShortStoryTabStyle.dislike_popup_option_column_spacing) / 2;

    return GestureDetector(
      onTap: () {
        widget.on_option_tap?.call(text);
        _dismiss();
      },
      child: Container(
        width: option_width,
        height: SelectionChipStyle.chipHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: BorderRadius.circular(SelectionChipStyle.borderRadius),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: ShortStoryTabStyle.dislike_popup_option_font_size,
            color: text_color,
          ),
        ),
      ),
    );
  }
}
