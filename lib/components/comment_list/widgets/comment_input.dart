import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/comment_list/widgets/comment_composer_surface.dart';
import 'package:app/components/comment_list/widgets/emoji_panel.dart';

/// 微信视频号式评论输入组件。
///
/// 组件由两层组成：
/// - 固定层：始终位于评论面板底部，只读取不会随键盘变化的 viewPadding。
/// - 编辑层：首帧预挂载在根 Overlay 中，仅该层读取 viewInsets 并贴住键盘。
///
/// 键盘开始收起时编辑层在第一个尺寸变化帧立即消失，固定层从未移动，因此不会
/// 出现真假输入框重叠、下滑或安全区回弹。
class CommentInput extends StatefulWidget {
  final bool is_dark;
  final Future<bool> Function(String content) on_send;
  final CommentData? reply_target;
  final VoidCallback? on_cancel_reply;
  final FocusNode? focus_node;

  const CommentInput({
    super.key,
    required this.is_dark,
    required this.on_send,
    this.reply_target,
    this.on_cancel_reply,
    this.focus_node,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _internal_focus_node;
  late final OverlayEntry _overlay_entry;

  bool _has_text = false;
  bool _is_editor_visible = false;
  bool _is_overlay_inserted = false;
  bool _is_overlay_rebuild_scheduled = false;
  bool _keyboard_opened_in_current_session = false;
  bool _show_emoji_panel = false;
  bool _is_sending = false;
  double _last_keyboard_height = 0;

  FocusNode get _focus_node => widget.focus_node ?? _internal_focus_node;

  @override
  void initState() {
    super.initState();
    _internal_focus_node = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    _focus_node.addListener(_on_focus_changed);
    _controller.addListener(_on_text_changed);

    // 编辑器首帧就进入 Overlay 并完成布局。隐藏状态只跳过绘制与手势，
    // 用户第一次点击时无需再创建 TextField、装饰或 OverlayEntry。
    _overlay_entry = OverlayEntry(
      builder: (BuildContext overlay_context) {
        return _CommentEditorOverlay(
          is_dark: widget.is_dark,
          is_visible: _is_editor_visible,
          has_text: _has_text && !_is_sending,
          show_emoji_panel: _show_emoji_panel,
          controller: _controller,
          focus_node: _focus_node,
          reply_target: widget.reply_target,
          on_activate: _show_editor,
          on_send: _handle_send,
          on_toggle_emoji: _toggle_emoji,
          on_emoji_selected: _on_emoji_selected,
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _last_keyboard_height = _read_keyboard_height();
      final OverlayState? overlay_state = Overlay.maybeOf(
        context,
        rootOverlay: true,
      );
      if (overlay_state == null) return;
      overlay_state.insert(_overlay_entry);
      _is_overlay_inserted = true;
    });
  }

  @override
  void didUpdateWidget(covariant CommentInput old_widget) {
    super.didUpdateWidget(old_widget);

    if (old_widget.focus_node != widget.focus_node) {
      final FocusNode old_focus_node =
          old_widget.focus_node ?? _internal_focus_node;
      old_focus_node.removeListener(_on_focus_changed);
      old_focus_node.unfocus();
      _focus_node.addListener(_on_focus_changed);
      _set_editor_visibility(_focus_node.hasFocus);
    }

    // 父组件更新发生在构建阶段，安全刷新函数会把独立 Overlay 的刷新合并到帧尾。
    _mark_overlay_needs_build();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_on_text_changed);
    _focus_node.removeListener(_on_focus_changed);
    _focus_node.unfocus();
    if (_is_overlay_inserted) {
      _overlay_entry.remove();
      _is_overlay_inserted = false;
    }
    _controller.dispose();
    _internal_focus_node.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final double keyboard_height = _read_keyboard_height();
    final double previous_keyboard_height = _last_keyboard_height;
    _last_keyboard_height = keyboard_height;

    if (!_is_editor_visible) return;

    // 一次编辑会话必须先观察到键盘从 0 开始上升，或高度继续上升，之后才允许
    // 将高度下降判定为关闭。这样上一轮残留的 metrics 不会关闭刚获得焦点的新会话。
    if (!_keyboard_opened_in_current_session) {
      final bool started_from_closed =
          previous_keyboard_height <=
          CommentListStyle.keyboard_close_hide_threshold;
      final bool is_opening =
          keyboard_height > CommentListStyle.keyboard_close_hide_threshold &&
          (started_from_closed || keyboard_height >= previous_keyboard_height);
      if (is_opening) {
        _keyboard_opened_in_current_session = true;
      }
      return;
    }

    final bool is_keyboard_closing =
        previous_keyboard_height >
            CommentListStyle.keyboard_close_hide_threshold &&
        keyboard_height <
            previous_keyboard_height -
                CommentListStyle.keyboard_close_hide_threshold;

    // 表情面板打开时，键盘收起不隐藏编辑层
    if (is_keyboard_closing && !_show_emoji_panel) {
      _hide_editor();
    }
  }

  /// 固定输入栏只读取 viewPadding，它在键盘显示和隐藏期间保持恒定。
  ///
  /// 编辑层可见时固定层透明度为 0，其余时间为 1。
  ///
  /// 这里不能只根据焦点判断：表情面板打开时 TextField 会主动失焦，
  /// 但编辑层仍需保持显示。使用 [_is_editor_visible] 可避免两套输入栏重叠。
  @override
  Widget build(BuildContext context) {
    final double stable_bottom_padding = MediaQuery.viewPaddingOf(
      context,
    ).bottom;

    return RepaintBoundary(
      child: IgnorePointer(
        key: const ValueKey<String>('comment_fixed_composer_gate'),
        ignoring: _is_editor_visible,
        child: ExcludeSemantics(
          excluding: _is_editor_visible,
          child: AnimatedOpacity(
            duration: const Duration(
              milliseconds: CommentListStyle.input_state_animation_duration_ms,
            ),
            curve: Curves.easeOutCubic,
            opacity: _is_editor_visible ? 0.0 : 1.0,
            child: CommentComposerSurface(
              is_dark: widget.is_dark,
              is_editor: false,
              has_text: _has_text && !_is_sending,
              show_emoji_panel: _show_emoji_panel,
              bottom_padding: stable_bottom_padding,
              controller: _controller,
              focus_node: _focus_node,
              reply_target: widget.reply_target,
              on_activate: _show_editor,
              on_send: _handle_send,
              on_toggle_emoji: _toggle_emoji,
            ),
          ),
        ),
      ),
    );
  }

  double _read_keyboard_height() {
    final view = View.maybeOf(context);
    if (view == null || view.devicePixelRatio == 0) return 0;
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  void _on_focus_changed() {
    // 触发重建以更新固定层透明度。
    setState(() {});

    if (_focus_node.hasFocus) {
      if (!_is_editor_visible) {
        _begin_editor_session();
      }
      // 键盘弹出时隐藏表情面板
      if (_show_emoji_panel) {
        _show_emoji_panel = false;
        _mark_overlay_needs_build();
      }
      return;
    }

    // 表情面板打开时，保持编辑层可见，不隐藏
    if (_show_emoji_panel) {
      _keyboard_opened_in_current_session = false;
      return;
    }

    final bool was_editor_visible = _is_editor_visible;
    _keyboard_opened_in_current_session = false;
    _set_editor_visibility(false);
    if (was_editor_visible) {
      _cancel_reply();
    }
  }

  void _on_text_changed() {
    final bool has_text = _controller.text.trim().isNotEmpty;
    if (_has_text == has_text || !mounted) return;

    // 只在“空/非空”状态改变时更新发送按钮；草稿文字由局部监听器独立刷新。
    setState(() {
      _has_text = has_text;
    });
    _mark_overlay_needs_build();
  }

  Future<void> _handle_send() async {
    final String content = _controller.text.trim();
    if (content.isEmpty || _is_sending) return;

    setState(() => _is_sending = true);
    _mark_overlay_needs_build();
    final bool success = await widget.on_send(content);
    if (!mounted) return;

    setState(() => _is_sending = false);
    _mark_overlay_needs_build();
    if (!success) return;

    _controller.clear();
    _hide_editor();
  }

  void _toggle_emoji() {
    if (!_show_emoji_panel) {
      // 先记录表情模式，再释放焦点。焦点回调因此不会把编辑层
      // 误判为已关闭；键盘下降期间表情网格延迟绘制，减少重布局。
      setState(() => _show_emoji_panel = true);
      if (!_is_editor_visible) {
        _set_editor_visibility(true);
      }
      if (_focus_node.hasFocus) {
        _focus_node.unfocus();
      }
    } else {
      // 键盘图标的语义是“切回键盘”，因此收起表情网格后继续保留
      // 编辑层并请求焦点，不让输入框瞬间回落到假输入栏。
      setState(() => _show_emoji_panel = false);
      if (!_is_editor_visible) {
        _set_editor_visibility(true);
      }
      _focus_node.requestFocus();
    }
    _mark_overlay_needs_build();
  }

  void _on_emoji_selected(String emoji) {
    final TextEditingValue value = _controller.value;
    final String old_text = value.text;
    final int raw_start = value.selection.start;
    final int raw_end = value.selection.end;
    final int start = raw_start < 0
        ? old_text.length
        : raw_start.clamp(0, old_text.length);
    final int end = raw_end < 0 ? start : raw_end.clamp(start, old_text.length);
    final String new_text =
        old_text.substring(0, start) + emoji + old_text.substring(end);
    _controller.value = TextEditingValue(
      text: new_text,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _show_editor() {
    if (!_is_editor_visible) {
      _begin_editor_session();
    }
    _focus_node.requestFocus();
  }

  /// 开始一次全新的编辑会话，切断上一轮键盘动画留下的高度状态。
  void _begin_editor_session() {
    _last_keyboard_height = _read_keyboard_height();
    _keyboard_opened_in_current_session = false;
    _set_editor_visibility(true);
  }

  void _hide_editor() {
    // 先撤掉编辑层，再释放焦点，避免主动关闭时编辑层参与键盘下降动画。
    final bool was_editor_visible = _is_editor_visible;
    _keyboard_opened_in_current_session = false;
    _show_emoji_panel = false;
    if (_is_editor_visible) {
      _set_editor_visibility(false);
    }
    if (_focus_node.hasFocus) {
      _focus_node.unfocus();
    }
    if (was_editor_visible) {
      _cancel_reply();
    }
  }

  /// 编辑器关闭时同步退出回复模式；普通评论状态下不触发父级重建。
  void _cancel_reply() {
    if (widget.reply_target == null) return;
    widget.on_cancel_reply?.call();
  }

  void _set_editor_visibility(bool is_visible) {
    if (_is_editor_visible == is_visible) return;
    _is_editor_visible = is_visible;
    _mark_overlay_needs_build();
  }

  /// 在构建阶段延迟刷新，其余交互阶段立即刷新，兼顾安全与响应速度。
  void _mark_overlay_needs_build() {
    if (!_is_overlay_inserted) return;

    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      _overlay_entry.markNeedsBuild();
      return;
    }

    if (_is_overlay_rebuild_scheduled) return;
    _is_overlay_rebuild_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _is_overlay_rebuild_scheduled = false;
      if (!mounted || !_is_overlay_inserted) return;
      _overlay_entry.markNeedsBuild();
    });
  }
}

/// 独立于评论面板布局的真实编辑层。
class _CommentEditorOverlay extends StatelessWidget {
  final bool is_dark;
  final bool is_visible;
  final bool has_text;
  final bool show_emoji_panel;
  final TextEditingController controller;
  final FocusNode focus_node;
  final CommentData? reply_target;
  final VoidCallback on_activate;
  final VoidCallback on_send;
  final VoidCallback on_toggle_emoji;
  final void Function(String emoji) on_emoji_selected;

  const _CommentEditorOverlay({
    required this.is_dark,
    required this.is_visible,
    required this.has_text,
    required this.show_emoji_panel,
    required this.controller,
    required this.focus_node,
    required this.reply_target,
    required this.on_activate,
    required this.on_send,
    required this.on_toggle_emoji,
    required this.on_emoji_selected,
  });

  @override
  Widget build(BuildContext context) {
    final double keyboard_height = MediaQuery.viewInsetsOf(context).bottom;
    final double stable_bottom_padding = MediaQuery.viewPaddingOf(
      context,
    ).bottom;
    final bool can_paint_emoji_panel =
        show_emoji_panel &&
        keyboard_height <= CommentListStyle.keyboard_close_hide_threshold;

    return IgnorePointer(
      ignoring: !is_visible,
      child: ExcludeSemantics(
        excluding: !is_visible,
        child: Opacity(
          opacity: is_visible ? 1 : 0,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: keyboard_height,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    /// 表情面板区域（AnimatedSize 实现展开/收起过渡）。
                    AnimatedSize(
                      duration: const Duration(
                        milliseconds:
                            CommentListStyle.emoji_panel_animation_duration_ms,
                      ),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomCenter,
                      child: can_paint_emoji_panel
                          ? CommentEmojiPanel(
                              is_dark: is_dark,
                              on_emoji_selected: on_emoji_selected,
                            )
                          : const SizedBox.shrink(),
                    ),

                    /// 输入栏区域。
                    RepaintBoundary(
                      child: CommentComposerSurface(
                        is_dark: is_dark,
                        is_editor: true,
                        has_text: has_text,
                        show_emoji_panel: show_emoji_panel,
                        bottom_padding: keyboard_height > 0
                            ? 0
                            : stable_bottom_padding,
                        controller: controller,
                        focus_node: focus_node,
                        reply_target: reply_target,
                        on_activate: on_activate,
                        on_send: on_send,
                        on_toggle_emoji: on_toggle_emoji,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
