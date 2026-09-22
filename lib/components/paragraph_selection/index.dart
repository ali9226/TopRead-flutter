// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectionStatus;

import 'inline_comment_badge.dart';
import 'scope.dart';

export 'scope.dart';

/// 正文和高亮共用 RenderParagraph，段评气泡由同一行内排版自动避让。
/// 所有同正文段落由上层 [ParagraphSelectionScope] 共享原生选区与手柄。
class ParagraphSelection extends StatelessWidget {
  const ParagraphSelection({
    super.key,
    required this.text,
    required this.text_style,
    required this.is_dark,
    required this.on_comment,
    this.start_offset = 0,
    this.on_share,
    this.comment_count = 0,
    this.paragraph_id,
    this.on_selection_changed,
    this.on_tap,
    this.on_tap_position,
    this.on_comment_count_tap,
    this.on_comment_count_tap_with_data,
  });

  final String text;
  final TextStyle text_style;
  final bool is_dark;

  /// 原始正文中的 UTF-16 偏移，不能使用过滤空行后的段落序号。
  final int start_offset;
  final int comment_count;
  final String? paragraph_id;
  final ValueChanged<TextSelection> on_comment;
  final ValueChanged<TextSelection>? on_share;
  final ValueChanged<bool>? on_selection_changed;
  final VoidCallback? on_tap;
  final ValueChanged<Offset>? on_tap_position;
  final VoidCallback? on_comment_count_tap;
  final void Function(String, int, String?)? on_comment_count_tap_with_data;

  @override
  Widget build(BuildContext context) {
    final paragraph = _SelectableParagraph(paragraph: this);
    // 独立预览仍可选择；阅读页始终使用覆盖多段正文的外层作用域。
    if (ParagraphSelectionScope.maybe_of(context) != null) return paragraph;
    return ParagraphSelectionScope(
      content: text,
      content_offset: start_offset,
      is_dark: is_dark,
      child: paragraph,
    );
  }
}

class _SelectableParagraph extends StatefulWidget {
  const _SelectableParagraph({required this.paragraph});
  final ParagraphSelection paragraph;

  @override
  State<_SelectableParagraph> createState() => _SelectableParagraphState();
}

class _SelectableParagraphState extends State<_SelectableParagraph> {
  final SelectionListenerNotifier _notifier = SelectionListenerNotifier();

  /// 气泡的内容独立刷新，避免替换 WidgetSpan 导致正文可选片段重新注册。
  late final ValueNotifier<ParagraphSelection> _badge_paragraph;
  late final WidgetSpan _badge_span;
  ParagraphSelectionScopeState? _scope;
  bool _has_selection = false;

  /// 长按检测：pointer down 时标记，若无移动且选区激活则扩展为整段。
  bool _long_press_pending = false;
  bool _pointer_moved = false;
  ParagraphSelection get paragraph => widget.paragraph;

  @override
  void initState() {
    super.initState();
    _badge_paragraph = ValueNotifier(paragraph);
    _badge_span = WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: SelectionContainer.disabled(
        child: ValueListenableBuilder<ParagraphSelection>(
          valueListenable: _badge_paragraph,
          builder: (context, value, child) => InlineParagraphCommentBadge(
            comment_count: value.comment_count,
            is_dark: value.is_dark,
            on_tap: _open_comment_count,
          ),
        ),
      ),
    );
    _notifier.addListener(_selection_changed);
  }

  @override
  void didUpdateWidget(_SelectableParagraph old_widget) {
    super.didUpdateWidget(old_widget);
    _badge_paragraph.value = paragraph;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ParagraphSelectionScope.maybe_of(context);
    if (scope == _scope) return;
    _scope?.unregister(this);
    _scope = scope;
    scope?.register(
      this,
      () => ParagraphSelectionEntry(
        text: paragraph.text,
        start_offset: paragraph.start_offset,
        selection: _selection,
        on_comment: paragraph.on_comment,
        on_share: paragraph.on_share,
      ),
    );
  }

  /// WidgetSpan 不可选，且所有范围限定为原文字数，气泡不会进入引用。
  TextSelection? get _selection {
    if (!_notifier.registered ||
        _notifier.selection.status != SelectionStatus.uncollapsed) {
      return null;
    }
    final range = _notifier.selection.range;
    if (range == null) return null;
    final start = math
        .min(range.startOffset, range.endOffset)
        .clamp(0, paragraph.text.length);
    final end = math
        .max(range.startOffset, range.endOffset)
        .clamp(0, paragraph.text.length);
    return start < end
        ? TextSelection(baseOffset: start, extentOffset: end)
        : null;
  }

  void _selection_changed() {
    // Flutter 会逐个更新选区端点；通知阶段仅检查状态，不能读取尚未完整的 range。
    final active =
        _notifier.registered &&
        _notifier.selection.status == SelectionStatus.uncollapsed;
    if (_has_selection == active) return;
    _has_selection = active;
    paragraph.on_selection_changed?.call(active);
    // 长按选词后自动扩展为整段选择；Pointer 已移动则为拖选，不干预。
    if (active && _long_press_pending && !_pointer_moved) {
      _long_press_pending = false;
      _scope?.select_all();
    }
  }

  /// 气泡点击使用当前段落的数据和回调，不缓存旧计数或旧锚点。
  void _open_comment_count() {
    _scope?.clear_selection();
    if (paragraph.on_comment_count_tap != null) {
      paragraph.on_comment_count_tap!();
    } else {
      paragraph.on_comment_count_tap_with_data?.call(
        paragraph.text,
        paragraph.comment_count,
        paragraph.paragraph_id,
      );
    }
  }

  @override
  void dispose() {
    _scope?.unregister(this);
    if (_has_selection) paragraph.on_selection_changed?.call(false);
    _notifier.removeListener(_selection_changed);
    _notifier.dispose();
    _badge_paragraph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _long_press_pending = true;
        _pointer_moved = false;
      },
      onPointerMove: (_) => _pointer_moved = true,
      onPointerUp: (_) {
        _long_press_pending = false;
        _pointer_moved = false;
      },
      onPointerCancel: (_) {
        _long_press_pending = false;
        _pointer_moved = false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          _long_press_pending = false;
          _pointer_moved = false;
          final was_selected = _scope?.has_selection ?? false;
          _scope?.clear_selection();
          FocusManager.instance.primaryFocus?.unfocus();
          if (!was_selected) {
            paragraph.on_tap?.call();
            paragraph.on_tap_position?.call(details.globalPosition);
          }
        },
        child: SelectionListener(
          selectionNotifier: _notifier,
          child: Text.rich(
            TextSpan(text: paragraph.text, children: [_badge_span]),
            style: paragraph.text_style,
            textWidthBasis: TextWidthBasis.parent,
          ),
        ),
      ),
    );
  }
}
