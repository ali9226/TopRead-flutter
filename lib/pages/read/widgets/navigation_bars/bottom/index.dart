import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/stores/project_config_store.dart';

/// 阅读页底部导航栏组件。
///
/// 匹配短篇阅读页 BottomCommentBar 的视觉风格：
/// - 进度条区域：上一章 + 可拖动进度条 + 下一章
/// - 四个操作项：目录、设置、评论、喜欢
class ReadBottomBar extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 是否显示导航栏。
  final bool show;

  /// 当前阅读进度（0.0 ~ 1.0）。
  final double progress;

  /// 章节列表（用于拖动时显示章节信息）。
  final List<NovelChapterInfo> chapter_list;

  /// 进度变化完成回调（松开进度条时触发）。
  final ValueChanged<double> on_progress_changed_end;

  /// 将全书进度比例换算为目录索引。
  final int Function(double progress_ratio) chapter_index_for_progress;

  /// 上一章按钮回调。
  final VoidCallback on_prev_chapter;

  /// 下一章按钮回调。
  final VoidCallback on_next_chapter;

  /// 是否为第一章（禁用上一章按钮）。
  final bool is_first_chapter;

  /// 是否为最后一章（禁用下一章按钮）。
  final bool is_last_chapter;

  /// 目录按钮回调。
  final VoidCallback on_catalog_tap;

  /// 设置按钮回调。
  final VoidCallback on_setting_tap;

  /// 评论按钮回调。
  final VoidCallback on_comment_tap;

  /// 评论数。
  final int comment_count;

  /// 是否已点赞。
  final bool is_liked;

  /// 点赞数。
  final int like_count;

  /// 是否正在点赞中。
  final bool is_like_loading;

  /// 点赞按钮回调。
  final VoidCallback on_like_tap;

  const ReadBottomBar({
    super.key,
    required this.is_dark,
    required this.show,
    required this.progress,
    required this.chapter_list,
    required this.on_progress_changed_end,
    required this.chapter_index_for_progress,
    required this.on_prev_chapter,
    required this.on_next_chapter,
    required this.is_first_chapter,
    required this.is_last_chapter,
    required this.on_catalog_tap,
    required this.on_setting_tap,
    required this.on_comment_tap,
    required this.comment_count,
    required this.is_liked,
    required this.like_count,
    required this.is_like_loading,
    required this.on_like_tap,
  });

  @override
  State<ReadBottomBar> createState() => _ReadBottomBarState();
}

class _ReadBottomBarState extends State<ReadBottomBar> {
  /// 是否正在拖动进度条。
  bool _is_dragging = false;

  /// 拖动过程中的临时进度值。
  double _drag_progress = 0.0;

  /// 进度条区域的全局键（用于计算弹窗位置）。
  final GlobalKey _progress_key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    /// 评论开关。
    final bool isCommentEnabled =
        Get.find<ProjectConfigStore>().current.is_comment_enabled;

    /// 底部安全区域高度。
    final double bottom_padding = MediaQuery.viewPaddingOf(context).bottom;

    /// 背景色。
    final Color bg_color = widget.is_dark
        ? const Color(0xFF161B22)
        : Colors.white;

    /// 图标/文字颜色。
    final Color icon_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF7A6A56);

    /// 分割线颜色。
    final Color divider_color = widget.is_dark
        ? const Color(0xFF21262D)
        : const Color(0xFFEEEEEE);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: widget.show ? 0 : -(200 + bottom_padding),
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(bottom: bottom_padding),
        decoration: BoxDecoration(
          color: bg_color,
          border: Border(top: BorderSide(color: divider_color, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /// 进度条区域（上一章 + 进度条 + 下一章）。
            _buildProgressBarSection(icon_color, bg_color),

            /// 四个操作图标。
            SizedBox(
              height: 60,
              child: Row(
                children: <Widget>[
                  /// 1. 目录。
                  Expanded(
                    child: _buildActionItem(
                      icon: 'menu',
                      label: tr('read.catalog'),
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

                  /// 3. 评论。
                  if (isCommentEnabled)
                    Expanded(
                      child: _buildActionItem(
                        icon: 'message',
                        label: '${widget.comment_count}',
                        icon_color: icon_color,
                        onTap: widget.on_comment_tap,
                      ),
                    ),

                  /// 4. 喜欢。
                  Expanded(child: _buildLikeItem(icon_color: icon_color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建进度条区域（上一章 + 进度条 + 下一章）。
  Widget _buildProgressBarSection(Color text_color, Color thumb_color) {
    /// 禁用状态文字颜色。
    final Color disabled_text_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFF7A6A56).withValues(alpha: 0.4);

    /// 进度条轨道颜色。
    final Color track_color = widget.is_dark
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFF7A6A56).withValues(alpha: 0.15);

    /// 滑块阴影颜色。
    final Color thumb_shadow_color = widget.is_dark
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.15);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        /// 主要内容行。
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 40,
            child: Row(
              children: <Widget>[
                /// 上一章文字。
                _buildNavigationText(
                  text: tr('read.prev_chapter'),
                  is_enabled: !widget.is_first_chapter,
                  text_color: text_color,
                  disabled_color: disabled_text_color,
                  onTap: widget.on_prev_chapter,
                ),

                /// 进度条。
                Expanded(
                  child: _buildProgressTrack(
                    track_color: track_color,
                    thumb_color: thumb_color,
                    thumb_shadow_color: thumb_shadow_color,
                  ),
                ),

                /// 下一章文字。
                _buildNavigationText(
                  text: tr('read.next_chapter'),
                  is_enabled: !widget.is_last_chapter,
                  text_color: text_color,
                  disabled_color: disabled_text_color,
                  onTap: widget.on_next_chapter,
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

  /// 构建导航文字（上一章/下一章）。
  Widget _buildNavigationText({
    required String text,
    required bool is_enabled,
    required Color text_color,
    required Color disabled_color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: is_enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: is_enabled ? text_color : disabled_color,
          ),
        ),
      ),
    );
  }

  /// 构建进度条轨道（带滑块）。
  Widget _buildProgressTrack({
    required Color track_color,
    required Color thumb_color,
    required Color thumb_shadow_color,
  }) {
    /// 当前显示的进度值。
    final double current_progress = _is_dragging
        ? _drag_progress
        : widget.progress;

    /// 滑块半径。
    const double thumb_radius = 9.0;

    /// 滑块尺寸。
    const double thumb_size = 18.0;

    /// 轨道高度。
    const double track_height = 8.0;

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
            height: 40,
            color: Colors.transparent,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                /// 轨道可用宽度。
                final double track_width = constraints.maxWidth - thumb_size;

                /// 滑块中心 X 坐标。
                final double thumb_center_x =
                    thumb_radius + current_progress * track_width;

                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    /// 背景轨道。
                    Positioned(
                      left: thumb_radius,
                      right: thumb_radius,
                      top: (40 - track_height) / 2,
                      child: Container(
                        height: track_height,
                        decoration: BoxDecoration(
                          color: track_color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    /// 滑块圆圈。
                    Positioned(
                      left: thumb_center_x - thumb_radius,
                      top: (40 - thumb_size) / 2,
                      child: Container(
                        width: thumb_size,
                        height: thumb_size,
                        decoration: BoxDecoration(
                          color: thumb_color,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: thumb_shadow_color,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
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

  /// 指针按下时开始拖动。
  void _on_pointer_down(PointerDownEvent event) {
    final RenderBox? render_box =
        _progress_key.currentContext?.findRenderObject() as RenderBox?;
    if (render_box == null) return;

    const double thumb_size = 18.0;
    const double thumb_radius = 9.0;
    final double track_width = render_box.size.width - thumb_size;
    if (track_width <= 0) return;
    final double new_progress =
        ((event.localPosition.dx - thumb_radius) / track_width).clamp(0.0, 1.0);

    setState(() {
      _is_dragging = true;
      _drag_progress = new_progress;
    });
  }

  /// 指针移动时更新拖动进度。
  void _on_pointer_move(PointerMoveEvent event) {
    if (!_is_dragging) return;

    final RenderBox? render_box =
        _progress_key.currentContext?.findRenderObject() as RenderBox?;
    if (render_box == null) return;

    const double thumb_size = 18.0;
    const double thumb_radius = 9.0;
    final double track_width = render_box.size.width - thumb_size;
    if (track_width <= 0) return;
    final double new_progress =
        ((event.localPosition.dx - thumb_radius) / track_width).clamp(0.0, 1.0);

    setState(() {
      _drag_progress = new_progress;
    });
  }

  /// 指针抬起时结束拖动。
  void _on_pointer_up(PointerUpEvent event) {
    if (!_is_dragging) return;
    widget.on_progress_changed_end(_drag_progress);
    setState(() {
      _is_dragging = false;
    });
  }

  /// 系统手势或父级滚动抢占指针时恢复滑块状态。
  void _on_pointer_cancel(PointerCancelEvent event) {
    if (!_is_dragging || !mounted) return;
    setState(() {
      _is_dragging = false;
      _drag_progress = widget.progress;
    });
  }

  /// 构建进度百分比弹窗。
  Widget _buildProgressPopup() {
    final RenderBox? render_box =
        _progress_key.currentContext?.findRenderObject() as RenderBox?;

    if (render_box == null) return const SizedBox.shrink();

    final Offset position = render_box.localToGlobal(Offset.zero);

    const double thumb_size = 18.0;
    const double thumb_radius = 9.0;
    final double track_width = render_box.size.width - thumb_size;
    final double popup_left =
        position.dx + thumb_radius + (track_width * _drag_progress) - 20;

    final String percentage_text = '${(_drag_progress * 100).round()}%';

    /// 显示当前章节信息。
    String chapter_text = '';
    if (widget.chapter_list.isNotEmpty) {
      final int index = widget
          .chapter_index_for_progress(_drag_progress)
          .clamp(0, widget.chapter_list.length - 1);
      final NovelChapterInfo chapter = widget.chapter_list[index];
      chapter_text = tr(
        'read.chapter_label',
        args: <String>[chapter.chapter_no.toString()],
      );
    }

    return Positioned(
      left: popup_left,
      bottom: 44,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  percentage_text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  ),
                ),
                if (chapter_text.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    chapter_text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          CustomPaint(
            size: const Size(12, 6),
            painter: _ArrowPainter(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// 构建单个操作项（图标在上，文字在下，居中排列）。
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

  /// 构建点赞操作项（支持加载状态和已点赞红色高亮）。
  Widget _buildLikeItem({required Color icon_color}) {
    final Color active_color = ColorConstants.dangerColor;
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
            '${widget.like_count}',
            style: TextStyle(fontSize: 11, color: current_color),
          ),
        ],
      ),
    );
  }
}

/// 箭头绘制器。
class _ArrowPainter extends CustomPainter {
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
