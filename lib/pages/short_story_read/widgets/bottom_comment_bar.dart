import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/font_config.dart';

import 'package:app/config/color_config.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/number_format_util.dart';
import 'package:app/util/language_util/index.dart';

/// 底部操作栏组件。
///
/// 固定在页面底部，包含：
/// - 上一篇/下一篇导航和进度条（可选，通过 [show_progress_bar] 控制）
/// - 四个等分居中的操作项：目录、设置、评论、喜欢
///
/// 支持安全区域适配，点赞时显示加载指示器。
class BottomCommentBar extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 评论数。
  final int comment_count;

  /// 点赞数。
  final int like_count;

  /// 是否已点赞。
  final bool is_liked;

  /// 是否正在点赞请求中（为 true 时显示加载指示器并禁用点击）。
  final bool is_like_loading;

  /// 目录按钮点击回调。
  final VoidCallback on_catalog_tap;

  /// 评论按钮点击回调。
  final VoidCallback on_comment_tap;

  /// 点赞按钮点击回调。
  final VoidCallback on_like_tap;

  /// 设置按钮点击回调。
  final VoidCallback on_setting_tap;

  /// 是否显示进度条区域（正文加载完成即可显示）。
  final bool show_progress_bar;

  /// 目录是否已加载完成（控制上一篇/下一篇文字显示）。
  final bool catalog_loaded;

  /// 当前阅读进度（0.0 ~ 1.0）。
  final double progress;

  /// 是否有上一篇小说。
  final bool has_previous;

  /// 是否有下一篇小说。
  final bool has_next;

  /// 上一篇按钮点击回调。
  final VoidCallback? on_previous_tap;

  /// 下一篇按钮点击回调。
  final VoidCallback? on_next_tap;

  /// 进度变化回调（拖动进度条时触发）。
  final ValueChanged<double>? on_progress_changed;

  /// 进度变化完成回调（松开进度条时触发）。
  /// 参数：[progress] 目标进度值，[on_complete] 滚动动画完成后的回调。
  final void Function(double progress, VoidCallback on_complete)?
  on_progress_change_end;

  const BottomCommentBar({
    super.key,
    required this.is_dark,
    required this.comment_count,
    required this.like_count,
    required this.is_liked,
    required this.is_like_loading,
    required this.on_catalog_tap,
    required this.on_comment_tap,
    required this.on_like_tap,
    required this.on_setting_tap,
    this.show_progress_bar = false,
    this.catalog_loaded = false,
    this.progress = 0.0,
    this.has_previous = false,
    this.has_next = false,
    this.on_previous_tap,
    this.on_next_tap,
    this.on_progress_changed,
    this.on_progress_change_end,
  });

  @override
  State<BottomCommentBar> createState() => _BottomCommentBarState();
}

class _BottomCommentBarState extends State<BottomCommentBar> {
  /// 是否正在拖动进度条。
  bool _is_dragging = false;

  /// 拖动过程中的临时进度值。
  double _drag_progress = 0.0;

  /// 进度条区域的全局键（用于计算弹窗位置）。
  final GlobalKey _progress_key = GlobalKey();

  /// 整个进度区域的全局键（用于把全局坐标换算为 Stack 局部坐标）。
  final GlobalKey _progress_section_key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    /// 底部安全区域高度。
    final double bottom_padding = MediaQuery.viewPaddingOf(context).bottom;

    /// 背景色。
    final Color bg_color = widget.is_dark
        ? ShortStoryReadStyle.bottom_bar_dark_bg
        : ShortStoryReadStyle.bottom_bar_light_bg;

    /// 图标/文字颜色。
    final Color icon_color = widget.is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 分割线颜色。
    final Color divider_color = widget.is_dark
        ? ShortStoryReadStyle.bottom_bar_dark_divider
        : ShortStoryReadStyle.bottom_bar_light_divider;

    return Container(
      padding: EdgeInsets.only(bottom: bottom_padding),
      decoration: BoxDecoration(
        color: bg_color,
        border: Border(top: BorderSide(color: divider_color, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// 进度条区域（可选显示）。
          if (widget.show_progress_bar) _buildProgressBarSection(),

          /// 四个操作图标。
          SizedBox(
            height: ShortStoryReadStyle.bottom_bar_height,
            child: Row(
              children: <Widget>[
                /// 1. 目录。
                Expanded(
                  child: _buildActionItem(
                    icon: 'menu',
                    label: tr('short_story_read.catalog'),
                    icon_color: icon_color,
                    onTap: widget.on_catalog_tap,
                  ),
                ),

                /// 2. 设置。
                Expanded(
                  child: _buildActionItem(
                    icon: 'se_up',
                    label: tr('short_story_read.setting'),
                    icon_color: icon_color,
                    onTap: widget.on_setting_tap,
                  ),
                ),

                /// 3. 评论，随远端项目配置实时显示或隐藏。
                Obx(() {
                  final bool is_comment_enabled =
                      Get.find<ProjectConfigStore>().current.is_comment_enabled;
                  if (!is_comment_enabled) return const SizedBox.shrink();

                  return Expanded(
                    child: _buildActionItem(
                      icon: 'message',
                      label: NumberFormatUtil.format_count(
                        widget.comment_count,
                      ),
                      icon_color: icon_color,
                      onTap: widget.on_comment_tap,
                    ),
                  );
                }),

                /// 4. 喜欢（图标 + 数字，上下排列，已点赞使用红色）。
                Expanded(child: _buildLikeItem(icon_color: icon_color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建进度条区域（上一篇 + 进度条 + 下一篇）。
  Widget _buildProgressBarSection() {
    /// 当前语种是否为 CJK。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );

    /// 文字颜色。
    final Color text_color = widget.is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 禁用状态文字颜色。
    final Color disabled_text_color = widget.is_dark
        ? ShortStoryReadStyle.secondary_dark_color.withValues(alpha: 0.4)
        : ShortStoryReadStyle.secondary_light_color.withValues(alpha: 0.4);

    /// 进度条轨道颜色（浅灰色背景）。
    final Color track_color = widget.is_dark
        ? ShortStoryReadStyle.secondary_dark_color.withValues(alpha: 0.15)
        : ShortStoryReadStyle.secondary_light_color.withValues(alpha: 0.15);

    /// 滑块颜色（夜间模式与上一篇/下一篇文字颜色一致，日间模式与底部导航背景色一致）。
    final Color thumb_color = widget.is_dark
        ? text_color
        : ShortStoryReadStyle.bottom_bar_light_bg;

    /// 滑块阴影颜色。
    final Color thumb_shadow_color = widget.is_dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.15);

    /// 文字字号。
    final double font_size = is_cjk
        ? ShortStoryReadStyle.nav_text_font_size_cjk
        : ShortStoryReadStyle.nav_text_font_size_alphabetic;

    return Stack(
      key: _progress_section_key,
      clipBehavior: Clip.none,
      children: <Widget>[
        /// 主要内容行。
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ShortStoryReadStyle.progress_area_horizontal_padding,
          ),
          child: SizedBox(
            height: ShortStoryReadStyle.progress_bar_height,
            child: Row(
              children: <Widget>[
                /// 上一篇文字（目录未加载时灰色不可点击）。
                _buildNavigationText(
                  text: tr('short_story_read.previous'),
                  is_enabled: widget.catalog_loaded && widget.has_previous,
                  text_color: text_color,
                  disabled_color: disabled_text_color,
                  font_size: font_size,
                  onTap: widget.on_previous_tap,
                ),

                /// 进度条（Expanded 占据中间空间）。
                Expanded(
                  child: _buildProgressTrack(
                    track_color: track_color,
                    thumb_color: thumb_color,
                    thumb_shadow_color: thumb_shadow_color,
                  ),
                ),

                /// 下一篇文字（目录未加载时灰色不可点击）。
                _buildNavigationText(
                  text: tr('short_story_read.next'),
                  is_enabled: widget.catalog_loaded && widget.has_next,
                  text_color: text_color,
                  disabled_color: disabled_text_color,
                  font_size: font_size,
                  onTap: widget.on_next_tap,
                ),
              ],
            ),
          ),
        ),

        /// 拖动时显示的百分比弹窗。
        if (_is_dragging) _buildProgressPopup(),
      ],
    );
  }

  /// 构建导航文字（上一篇/下一篇）。
  Widget _buildNavigationText({
    required String text,
    required bool is_enabled,
    required Color text_color,
    required Color disabled_color,
    required double font_size,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: is_enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ShortStoryReadStyle.nav_text_padding,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: font_size,
            color: is_enabled ? text_color : disabled_color,
          ),
        ),
      ),
    );
  }

  /// 构建进度条轨道（带滑块）。
  ///
  /// 拖动时使用 [AbsorbPointer] 阻断底层 ScrollView 接收事件，
  /// 同时通过 [Listener] 直接处理指针位置来控制滑块。
  Widget _buildProgressTrack({
    required Color track_color,
    required Color thumb_color,
    required Color thumb_shadow_color,
  }) {
    /// 当前显示的进度值。
    final double current_progress = _is_dragging
        ? _drag_progress
        : widget.progress;

    return Listener(
      key: _progress_key,
      onPointerDown: _on_pointer_down,
      onPointerMove: _on_pointer_move,
      onPointerUp: _on_pointer_up,
      onPointerCancel: _on_pointer_cancel,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(
        absorbing: _is_dragging,
        child: GestureDetector(
          onVerticalDragStart: (_) {},
          onVerticalDragUpdate: (_) {},
          onVerticalDragEnd: (_) {},
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: ShortStoryReadStyle.progress_bar_height,
            color: Colors.transparent,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                /// 滑块半径。
                final double thumb_radius =
                    ShortStoryReadStyle.progress_thumb_size / 2;

                /// 轨道可用宽度（减去滑块直径，确保滑块在边缘不被裁剪）。
                final double track_width = math.max(
                  0,
                  constraints.maxWidth -
                      ShortStoryReadStyle.progress_thumb_size,
                );

                /// 滑块中心 X 坐标（从滑块半径位置开始）。
                final double thumb_center_x =
                    thumb_radius + current_progress * track_width;

                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    /// 浅灰色背景轨道（左右留出滑块半径空间）。
                    Positioned(
                      left: thumb_radius,
                      right: thumb_radius,
                      top:
                          (ShortStoryReadStyle.progress_bar_height -
                              ShortStoryReadStyle.progress_track_height) /
                          2,
                      child: Container(
                        height: ShortStoryReadStyle.progress_track_height,
                        decoration: BoxDecoration(
                          color: track_color,
                          borderRadius: BorderRadius.circular(
                            ShortStoryReadStyle.progress_track_radius,
                          ),
                        ),
                      ),
                    ),

                    /// 带投影的滑块圆圈。
                    Positioned(
                      left: thumb_center_x - thumb_radius,
                      top:
                          (ShortStoryReadStyle.progress_bar_height -
                              ShortStoryReadStyle.progress_thumb_size) /
                          2,
                      child: Container(
                        width: ShortStoryReadStyle.progress_thumb_size,
                        height: ShortStoryReadStyle.progress_thumb_size,
                        decoration: BoxDecoration(
                          color: thumb_color,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: thumb_shadow_color,
                              blurRadius: ShortStoryReadStyle
                                  .progress_thumb_shadow_blur,
                              offset: const Offset(
                                0,
                                ShortStoryReadStyle
                                    .progress_thumb_shadow_offset_y,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 指针按下时开始拖动，记录初始进度。
  void _on_pointer_down(PointerDownEvent event) {
    final RenderBox? render_box =
        _progress_key.currentContext?.findRenderObject() as RenderBox?;
    if (render_box == null) return;

    final double thumb_radius = ShortStoryReadStyle.progress_thumb_size / 2;
    final double track_width = math.max(
      0,
      render_box.size.width - ShortStoryReadStyle.progress_thumb_size,
    );
    if (track_width <= 0) return;
    final double new_progress =
        ((event.localPosition.dx - thumb_radius) / track_width).clamp(0.0, 1.0);

    setState(() {
      _is_dragging = true;
      _drag_progress = new_progress;
    });
    widget.on_progress_changed?.call(new_progress);
  }

  /// 指针移动时更新拖动进度。
  void _on_pointer_move(PointerMoveEvent event) {
    if (!_is_dragging) return;

    final RenderBox? render_box =
        _progress_key.currentContext?.findRenderObject() as RenderBox?;
    if (render_box == null) return;

    final double thumb_radius = ShortStoryReadStyle.progress_thumb_size / 2;
    final double track_width = math.max(
      0,
      render_box.size.width - ShortStoryReadStyle.progress_thumb_size,
    );
    if (track_width <= 0) return;
    final double new_progress =
        ((event.localPosition.dx - thumb_radius) / track_width).clamp(0.0, 1.0);

    setState(() {
      _drag_progress = new_progress;
    });
    widget.on_progress_changed?.call(new_progress);
  }

  /// 指针抬起时结束拖动，触发滚动。
  void _on_pointer_up(PointerUpEvent event) {
    if (!_is_dragging) return;
    final progress_callback = widget.on_progress_change_end;
    if (progress_callback == null) {
      _on_scroll_complete();
      return;
    }
    progress_callback(_drag_progress, _on_scroll_complete);
  }

  void _on_pointer_cancel(PointerCancelEvent event) {
    _on_scroll_complete();
  }

  /// 构建进度百分比弹窗（显示在滑块上方）。
  Widget _buildProgressPopup() {
    /// 进度条区域的渲染对象。
    final RenderBox? render_box =
        _progress_key.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? section_box =
        _progress_section_key.currentContext?.findRenderObject() as RenderBox?;
    if (render_box == null || section_box == null) {
      return const SizedBox.shrink();
    }

    /// 进度条区域在屏幕上的位置。
    final Offset position = render_box.localToGlobal(Offset.zero);
    final Offset section_position = section_box.localToGlobal(Offset.zero);

    /// 滑块半径。
    final double thumb_radius = ShortStoryReadStyle.progress_thumb_size / 2;

    /// 轨道实际宽度（减去滑块直径）。
    final double track_width = math.max(
      0,
      render_box.size.width - ShortStoryReadStyle.progress_thumb_size,
    );

    /// 弹窗水平位置（基于拖动进度计算，居中于滑块）。
    final double popup_left =
        (position.dx -
                section_position.dx +
                thumb_radius +
                track_width * _drag_progress -
                20)
            .clamp(0.0, math.max(0.0, section_box.size.width - 40));

    /// 百分比文字。
    final String percentage_text = '${(_drag_progress * 100).round()}%';

    return Positioned(
      left: popup_left,
      bottom: ShortStoryReadStyle.progress_bar_height + 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// 弹窗主体（半透明黑色，类似吐司）。
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ShortStoryReadStyle.progress_popup_padding,
              vertical: ShortStoryReadStyle.progress_popup_padding / 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(
                ShortStoryReadStyle.progress_popup_radius,
              ),
            ),
            child: Text(
              percentage_text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              ),
            ),
          ),

          /// 箭头。
          CustomPaint(
            size: Size(
              ShortStoryReadStyle.progress_popup_arrow_size * 2,
              ShortStoryReadStyle.progress_popup_arrow_size,
            ),
            painter: _ArrowPainter(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// 滚动动画完成回调，重置拖动状态。
  void _on_scroll_complete() {
    if (!mounted) return;
    setState(() {
      _is_dragging = false;
    });
  }

  /// 构建单个操作项（图标在上，文字在下，居中排列）。
  ///
  /// 参数：
  /// - [icon] SVG 图标名称（不含路径和后缀）。
  /// - [label] 图标下方的文字。
  /// - [icon_color] 图标和文字的颜色。
  /// - [onTap] 点击回调。
  Widget _buildActionItem({
    required String icon,
    required String label,
    required Color icon_color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgIcon(name: icon, width: 22, height: 22, color: icon_color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: icon_color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建点赞操作项（支持已点赞红色高亮和缩放回弹动画）。
  ///
  /// 参数：
  /// - [icon_color] 默认图标和文字颜色。
  Widget _buildLikeItem({required Color icon_color}) {
    /// 点赞激活时的颜色。
    final Color active_color = ColorConstants.dangerColor;

    /// 当前显示的颜色（已点赞时使用红色）。
    final Color current_color = widget.is_liked ? active_color : icon_color;

    return GestureDetector(
      onTap: widget.is_like_loading ? null : widget.on_like_tap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 560),
            curve: Curves.elasticOut,
            tween: Tween<double>(begin: 0.6, end: widget.is_liked ? 1.0 : 1.0),
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            key: ValueKey(widget.is_liked),
            child: SvgIcon(
              name: widget.is_liked ? 'love_02' : 'love',
              width: 22,
              height: 22,
              color: current_color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormatUtil.format_count(widget.like_count),
            style: TextStyle(fontSize: 11, color: current_color),
          ),
        ],
      ),
    );
  }
}

/// 箭头绘制器。
///
/// 绘制弹窗下方的三角形箭头。
class _ArrowPainter extends CustomPainter {
  /// 箭头颜色。
  final Color color;

  _ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old_delegate) {
    return false;
  }
}
