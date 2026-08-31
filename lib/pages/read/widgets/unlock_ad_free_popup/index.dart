import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 解锁免广告时长弹窗入口。
///
/// 使用 [showModalBottomSheet] 展示，原生支持：
/// - 点击遮罩层关闭
/// - 向下拖拽关闭
/// - 系统返回键关闭
///
/// 弹窗核心视觉元素是一个从 24 倒数到目标时长的数字动画，
/// 配合"免广告阅读"副标题和"立即解锁"按钮，形成清晰的行动引导。
class UnlockAdFreePopup {
  UnlockAdFreePopup._();

  /// 展示解锁免广告弹窗。
  ///
  /// [context] 当前页面上下文，用于展示 BottomSheet。
  /// [is_dark] 当前是否为夜间模式，控制弹窗配色。
  /// [duration_hours] 目标免广告时长（小时），如 6、3、1，决定倒计时终点。
  /// [on_tap] 点击"立即解锁"按钮的回调（暂不处理，后续接入广告逻辑）。
  static Future<void> show({
    required BuildContext context,
    required bool is_dark,
    required int duration_hours,
    VoidCallback? on_tap,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: UnlockAdFreePopupStyle.barrier_color,
      builder: (BuildContext sheet_context) {
        return _UnlockAdFreePopupSheet(
          is_dark: is_dark,
          duration_hours: duration_hours,
          on_tap: on_tap,
        );
      },
    );
  }
}

/// 解锁免广告弹窗内容组件。
///
/// 使用 [SingleTickerProviderStateMixin] 驱动倒计时动画。
/// 数字从 24 开始，以 easeOutCubic 曲线减速滚动到 [duration_hours]，
/// 视觉上像老虎机数字滚动，最终停在目标值。
class _UnlockAdFreePopupSheet extends StatefulWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 目标免广告时长（小时）。
  final int duration_hours;

  /// 点击"立即解锁"按钮的回调。
  final VoidCallback? on_tap;

  const _UnlockAdFreePopupSheet({
    required this.is_dark,
    required this.duration_hours,
    this.on_tap,
  });

  @override
  State<_UnlockAdFreePopupSheet> createState() =>
      _UnlockAdFreePopupSheetState();
}

class _UnlockAdFreePopupSheetState extends State<_UnlockAdFreePopupSheet>
    with SingleTickerProviderStateMixin {
  /// 倒计时动画控制器，管理动画的播放和生命周期。
  late final AnimationController _countdown_controller;

  /// 倒计时动画，值从 24.0 渐变到目标时长。
  late final Animation<double> _countdown_animation;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器，时长由样式常量控制。
    _countdown_controller = AnimationController(
      vsync: this,
      duration: UnlockAdFreePopupStyle.countdown_duration,
    );
    // 数值插值：从 24 滚动到目标时长（如 6、3、1）。
    _countdown_animation = Tween<double>(
      begin: 24.0,
      end: widget.duration_hours.toDouble(),
    ).animate(CurvedAnimation(
      parent: _countdown_controller,
      // easeOutCubic 让数字先快后慢，有"刹停"的视觉效果。
      curve: Curves.easeOutCubic,
    ));
    // 弹窗出现后立即播放倒计时动画。
    _countdown_controller.forward();
  }

  @override
  void dispose() {
    _countdown_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根据当前主题模式解析各区域颜色。
    final Color background_color = widget.is_dark
        ? UnlockAdFreePopupStyle.background_color_dark
        : UnlockAdFreePopupStyle.background_color_light;
    final Color subtitle_color = widget.is_dark
        ? UnlockAdFreePopupStyle.subtitle_color_dark
        : UnlockAdFreePopupStyle.subtitle_color_light;
    final Color desc_color = widget.is_dark
        ? UnlockAdFreePopupStyle.desc_color_dark
        : UnlockAdFreePopupStyle.desc_color_light;
    final Color drag_handle_color = widget.is_dark
        ? UnlockAdFreePopupStyle.drag_handle_color_dark
        : UnlockAdFreePopupStyle.drag_handle_color_light;

    // 底部安全区域高度，适配刘海屏和 Home Indicator。
    final double bottom_safe = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: background_color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(UnlockAdFreePopupStyle.border_radius),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          UnlockAdFreePopupStyle.content_horizontal_padding,
          UnlockAdFreePopupStyle.top_padding,
          UnlockAdFreePopupStyle.content_horizontal_padding,
          UnlockAdFreePopupStyle.bottom_padding + bottom_safe,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 拖拽指示条，提示用户可以向下拖拽关闭。
            _build_drag_handle(drag_handle_color),
            const SizedBox(height: 24),
            // 核心视觉：倒计时数字，主题色大字号突出显示。
            _build_animated_number(),
            const SizedBox(
              height: UnlockAdFreePopupStyle.number_subtitle_spacing,
            ),
            // 副标题：说明数字含义（"免广告阅读"）。
            _build_subtitle(subtitle_color),
            const SizedBox(
              height: UnlockAdFreePopupStyle.subtitle_desc_spacing,
            ),
            // 描述：引导用户操作（"观看短视频即可解锁"）。
            _build_description(desc_color),
            const SizedBox(
              height: UnlockAdFreePopupStyle.desc_button_spacing,
            ),
            // 行动按钮：主题色胶囊按钮。
            _build_button(context),
          ],
        ),
      ),
    );
  }

  /// 构建顶部拖拽指示条。
  ///
  /// 居中放置的灰色小横条，视觉上提示用户此弹窗可向下拖拽关闭。
  Widget _build_drag_handle(Color color) {
    return Center(
      child: Container(
        width: UnlockAdFreePopupStyle.drag_handle_width,
        height: UnlockAdFreePopupStyle.drag_handle_height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(
            UnlockAdFreePopupStyle.drag_handle_radius,
          ),
        ),
      ),
    );
  }

  /// 构建倒计时数字动画。
  ///
  /// 数字从 24 开始，以 easeOutCubic 曲线减速滚动到目标时长。
  /// 使用 [AnimatedBuilder] 每帧重建文本，实现数字滚动效果。
  /// 字号 72、字重 w700、主题色，是弹窗中最醒目的视觉元素。
  Widget _build_animated_number() {
    return AnimatedBuilder(
      animation: _countdown_animation,
      builder: (BuildContext context, Widget? child) {
        final double value = _countdown_animation.value;
        final int display_value = value.round();
        return Text(
          '$display_value',
          style: TextStyle(
            fontSize: UnlockAdFreePopupStyle.number_font_size,
            fontWeight: UnlockAdFreePopupStyle.number_font_weight,
            color: UnlockAdFreePopupStyle.number_color,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  /// 构建副标题（数字下方的说明文字）。
  ///
  /// 用较小字号说明数字含义，如"免广告阅读"，
  /// 与大数字形成"数字 + 文字"的信息组合。
  Widget _build_subtitle(Color color) {
    return Text(
      easy.tr('read.unlock_ad_free_subtitle'),
      style: TextStyle(
        fontSize: UnlockAdFreePopupStyle.subtitle_font_size,
        fontWeight: UnlockAdFreePopupStyle.subtitle_font_weight,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 构建描述文字（引导用户操作）。
  ///
  /// 浅灰色小字，告诉用户如何获得免广告时长，如"观看短视频即可解锁"。
  /// 视觉层级最低，仅作为辅助信息。
  Widget _build_description(Color color) {
    return Text(
      easy.tr('read.unlock_ad_free_desc'),
      style: TextStyle(
        fontSize: UnlockAdFreePopupStyle.desc_font_size,
        fontWeight: UnlockAdFreePopupStyle.desc_font_weight,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 构建"立即解锁"按钮。
  ///
  /// 主题色背景 + 深色文字的胶囊按钮，占据弹窗全宽。
  /// 点击后关闭弹窗并触发 [on_tap] 回调。
  Widget _build_button(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: UnlockAdFreePopupStyle.button_height,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.on_tap?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: UnlockAdFreePopupStyle.button_color,
          foregroundColor: UnlockAdFreePopupStyle.button_text_color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              UnlockAdFreePopupStyle.button_radius,
            ),
          ),
          elevation: 0,
        ),
        child: Text(
          easy.tr('read.unlock_ad_free_button'),
          style: TextStyle(
            fontSize: UnlockAdFreePopupStyle.button_font_size,
            fontWeight: UnlockAdFreePopupStyle.button_font_weight,
          ),
        ),
      ),
    );
  }
}
