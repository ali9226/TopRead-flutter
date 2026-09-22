// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'selection_auto_scroll.dart';
import 'selection_toolbar.dart';
import 'style.dart';

/// 每段注册最新内容及局部选区；回调始终属于该段的真实数据库锚点。
class ParagraphSelectionEntry {
  const ParagraphSelectionEntry({
    required this.text,
    required this.start_offset,
    required this.selection,
    required this.on_comment,
    this.on_share,
  });
  final String text;
  final int start_offset;
  final TextSelection? selection;
  final ValueChanged<TextSelection> on_comment;
  final ValueChanged<TextSelection>? on_share;
}

/// 一份正文共享一个原生选区，跨段选择不创建编辑器或替换文字布局。
/// 长篇每章对应独立正文坐标系，短篇锁定预览仅包含可见的原文范围。
class ParagraphSelectionScope extends StatefulWidget {
  const ParagraphSelectionScope({
    super.key,
    required this.content,
    required this.is_dark,
    required this.child,
    this.content_offset = 0,
    this.on_tap_position,
  });
  final String content;
  final int content_offset;
  final bool is_dark;
  final Widget child;
  /// 段落间空白处的普通点击沿用阅读页动作。
  final ValueChanged<Offset>? on_tap_position;

  static ParagraphSelectionScopeState? maybe_of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ParagraphSelectionScope>()
      ?.state;

  @override
  State<ParagraphSelectionScope> createState() =>
      ParagraphSelectionScopeState();
}

class ParagraphSelectionScopeState extends State<ParagraphSelectionScope> {
  final _area_key = GlobalKey<SelectionAreaState>();
  final _focus_node = FocusNode(skipTraversal: true);
  final Map<Object, ParagraphSelectionEntry Function()> _entries = {};

  void register(Object owner, ParagraphSelectionEntry Function() entry) =>
      _entries[owner] = entry;
  void unregister(Object owner) => _entries.remove(owner);
  bool get has_selection =>
      _entries.values.toList().any((entry) => entry().selection != null);

  /// 清理工具栏与原生高亮，保持输入面板、章节跳转及普通阅读点击一致。
  void clear_selection() {
    final region = _area_key.currentState?.selectableRegion;
    region?.hideToolbar();
    region?.clearSelection();
    _focus_node.unfocus();
  }

  /// 长按选中当前作用域内的全部段落，替代默认的选词行为。
  void select_all() {
    _area_key.currentState?.selectableRegion
        .selectAll(SelectionChangedCause.longPress);
  }

  @override
  void didUpdateWidget(ParagraphSelectionScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.content_offset != widget.content_offset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) clear_selection();
      });
    }
  }

  /// 按原文次序归属末段，反向拖选同样成立；引用保留 CRLF 和空白行。
  void _open_action({required bool share}) {
    final entries =
        _entries.values
            .map((entry) => entry())
            .where((entry) => entry.selection != null)
            .toList()
          ..sort(
            (left, right) => left.start_offset.compareTo(right.start_offset),
          );
    if (entries.isEmpty) return;
    final first = entries.first;
    final last = entries.last;
    final start = first.start_offset + first.selection!.start;
    final end = last.start_offset + last.selection!.end;
    final local_start = start - widget.content_offset;
    final local_end = end - widget.content_offset;
    if (local_start < 0 ||
        local_end > widget.content.length ||
        local_start >= local_end) {
      return;
    }
    final quote = widget.content.substring(local_start, local_end);
    if (quote.trim().isEmpty) return;
    final selection = ParagraphTextSelection(
      baseOffset: last.selection!.start,
      extentOffset: last.selection!.end,
      selected_text: quote,
      content_start: start,
      content_end: end,
    );
    final callback = share ? last.on_share : last.on_comment;
    if (callback == null) return;
    clear_selection();
    callback(selection);
  }

  Widget _build_context_menu(
    BuildContext context,
    SelectableRegionState state,
  ) => TapRegion(
    groupId: SelectableRegion,
    child: ParagraphSelectionToolbar(
      anchors: state.contextMenuAnchors,
      is_dark: widget.is_dark,
      on_comment: () => _open_action(share: false),
      on_share: () => _open_action(share: true),
    ),
  );

  @override
  void dispose() {
    _entries.clear();
    _focus_node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ParagraphSelectionScope(
    state: this,
    child: CupertinoTheme(
      data: CupertinoTheme.of(
        context,
      ).copyWith(selectionHandleColor: ColorConstants.themeColor),
      child: TextSelectionTheme(
        data: TextSelectionTheme.of(context).copyWith(
          selectionColor: ColorConstants.themeColor.withValues(
            alpha: ParagraphSelectionStyle.selection_opacity,
          ),
          selectionHandleColor: ColorConstants.themeColor,
        ),
        child: TapRegion(
          groupId: SelectableRegion,
          onTapOutside: (_) => clear_selection(),
          child: SelectionArea(
            key: _area_key,
            focusNode: _focus_node,
            contextMenuBuilder: _build_context_menu,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                final was_selected = has_selection;
                clear_selection();
                if (!was_selected) widget.on_tap_position?.call(details.globalPosition);
              },
              child: ParagraphSelectionAutoScroll(child: widget.child),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ParagraphSelectionScope extends InheritedWidget {
  const _ParagraphSelectionScope({required this.state, required super.child});
  final ParagraphSelectionScopeState state;

  @override
  bool updateShouldNotify(_ParagraphSelectionScope oldWidget) =>
      state != oldWidget.state;
}
