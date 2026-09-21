// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/config/color_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'comment_badge.dart';
import 'selection_toolbar.dart';
import 'selection_reveal_guard.dart';
import 'style.dart';

/// 长短篇共用正文段落：首次长按整段全选，后续沿用平台原生手柄调整选区。
///
/// [on_comment] 返回原始 [text] 内的 UTF-16 偏移；段评气泡没有参与文字排版。
class ParagraphSelection extends StatefulWidget {
  const ParagraphSelection({
    super.key,
    required this.text,
    required this.text_style,
    required this.is_dark,
    required this.on_comment,
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
  final int comment_count;
  final String? paragraph_id;
  final ValueChanged<TextSelection> on_comment;
  final ValueChanged<TextSelection>? on_share;
  final ValueChanged<bool>? on_selection_changed;
  final VoidCallback? on_tap;

  /// 手势确认是单击后才交给阅读页翻页，长按和拖动不会提前触发。
  final ValueChanged<Offset>? on_tap_position;
  final VoidCallback? on_comment_count_tap;

  /// 点击评论数量气泡时返回段落文本、评论数量和段落 ID 的回调。
  final void Function(
    String paragraph_text,
    int comment_count,
    String? paragraph_id,
  )?
  on_comment_count_tap_with_data;

  @override
  State<ParagraphSelection> createState() => _ParagraphSelectionState();
}

class _ParagraphSelectionState extends State<ParagraphSelection>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late final TextEditingController _controller;
  late final _ParagraphGestureBuilder _gesture_builder;
  final FocusNode _focus_node = FocusNode(skipTraversal: true);
  bool _has_selection = false;
  bool _suppress_initial_reveal = false;
  TextSelection _previous_selection = const TextSelection.collapsed(offset: -1);
  TextPosition? _active_selection_position;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _gesture_builder = _ParagraphGestureBuilder(state: this);
    _focus_node.addListener(_handle_focus_changed);
  }

  @override
  void didUpdateWidget(ParagraphSelection old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.text != widget.text) {
      _controller.value = TextEditingValue(text: widget.text);
      editableTextKey.currentState?.hideToolbar();
      if (_has_selection) {
        _has_selection = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.on_selection_changed?.call(false);
        });
      }
    }
  }

  @override
  void dispose() {
    // 章节窗口移除已选择的段落时同步清理阅读页状态，避免永久阻止翻页。
    if (_has_selection) widget.on_selection_changed?.call(false);
    _focus_node.removeListener(_handle_focus_changed);
    _focus_node.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 焦点进入输入面板或其他段落时，移除旧段落的选区与操作浮层。
  void _handle_focus_changed() {
    if (!_focus_node.hasFocus) _clear_selection();
  }

  void _clear_selection() {
    _active_selection_position = null;
    _previous_selection = const TextSelection.collapsed(offset: -1);
    editableTextKey.currentState?.hideToolbar();
    _controller.selection = const TextSelection.collapsed(offset: -1);
    _update_selection_state(false);
  }

  void _update_selection_state(bool has_selection) {
    if (_has_selection == has_selection || !mounted) return;
    setState(() => _has_selection = has_selection);
    widget.on_selection_changed?.call(has_selection);
  }

  void _handle_selection_changed(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    _active_selection_position = cause == SelectionChangedCause.drag
        ? (selection.extentOffset == _previous_selection.extentOffset &&
                  selection.baseOffset != _previous_selection.baseOffset
              ? selection.base
              : selection.extent)
        : null;
    _previous_selection = selection;
    _update_selection_state(selection.isValid && !selection.isCollapsed);
  }

  /// 先拷贝选择范围，再关闭原生选区，防止输入弹窗获取焦点后丢失引用。
  void _open_comment() {
    final TextSelection selection = _controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    _clear_selection();
    _focus_node.unfocus();
    widget.on_comment(selection);
  }

  /// 拷贝选择范围并关闭选区后，将选区传递给分享回调。
  void _open_share() {
    final TextSelection selection = _controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    _clear_selection();
    _focus_node.unfocus();
    widget.on_share?.call(selection);
  }

  /// 普通单击沿用阅读页动作；已存在选区时，第一次单击只退出选择。
  void _handle_tap(Offset global_position) {
    final bool was_selected = _has_selection;
    _clear_selection();
    _focus_node.unfocus();
    if (!was_selected) {
      widget.on_tap?.call();
      widget.on_tap_position?.call(global_position);
    }
  }

  /// 使用稳定的方法引用，避免重建正文时 Flutter 销毁并遗漏原生手柄浮层。
  Widget _build_context_menu(BuildContext context, EditableTextState state) =>
      ParagraphSelectionToolbar(
        anchors: state.contextMenuAnchors,
        is_dark: widget.is_dark,
        on_comment: _open_comment,
        on_share: widget.on_share != null ? _open_share : null,
      );

  @override
  Widget build(BuildContext context) {
    final TextStyle effective_style = DefaultTextStyle.of(
      context,
    ).style.merge(widget.text_style);
    final TargetPlatform platform = Theme.of(context).platform;
    final bool is_apple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final TextSelectionControls selection_controls = switch (platform) {
      TargetPlatform.iOS => cupertinoTextSelectionHandleControls,
      TargetPlatform.macOS => cupertinoDesktopTextSelectionHandleControls,
      TargetPlatform.linux ||
      TargetPlatform.windows => desktopTextSelectionHandleControls,
      _ => materialTextSelectionHandleControls,
    };
    final Widget editable = RepaintBoundary(
      child: EditableText(
        key: editableTextKey,
        controller: _controller,
        focusNode: _focus_node,
        readOnly: true,
        showCursor: false,
        maxLines: null,
        forceLine: false,
        style: effective_style,
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
        textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
        strutStyle: const StrutStyle(),
        cursorColor: ColorConstants.themeColor,
        backgroundCursorColor: ColorConstants.hintColor,
        selectionColor: ColorConstants.themeColor.withValues(
          alpha: ParagraphSelectionStyle.selection_opacity,
        ),
        showSelectionHandles: _has_selection,
        selectionControls: selection_controls,
        rendererIgnoresPointer: true,
        paintCursorAboveText: is_apple,
        enableInteractiveSelection: true,
        selectAllOnFocus: false,
        enableSuggestions: false,
        stylusHandwritingEnabled: false,
        autofillHints: null,
        scrollPhysics: const NeverScrollableScrollPhysics(),
        magnifierConfiguration: TextMagnifier.adaptiveMagnifierConfiguration,
        onSelectionChanged: _handle_selection_changed,
        onTapOutside: (_) {
          _clear_selection();
          _focus_node.unfocus();
        },
        contextMenuBuilder: _build_context_menu,
      ),
    );

    return CupertinoTheme(
      data: CupertinoTheme.of(
        context,
      ).copyWith(selectionHandleColor: ColorConstants.themeColor),
      child: TextSelectionTheme(
        data: TextSelectionTheme.of(
          context,
        ).copyWith(selectionHandleColor: ColorConstants.themeColor),
        child: _gesture_builder.buildGestureDetector(
          behavior: HitTestBehavior.translucent,
          child: ParagraphSelectionRevealGuard(
            should_suppress: () => _suppress_initial_reveal,
            active_selection_position: () => _active_selection_position,
            child: widget.comment_count > 0
                ? _build_badge_layout(context, effective_style, editable)
                : editable,
          ),
        ),
      ),
    );
  }

  /// 按正文最后一行的实际宽度定位气泡；行尾空间不足时自然移到下一行。
  ///
  /// 原生 EditableText 保持原文不变，因此 emoji、空格及拖拽选区偏移均准确。
  Widget _build_badge_layout(
    BuildContext context,
    TextStyle effective_style,
    Widget editable,
  ) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final TextDirection direction = Directionality.of(context);
      final TextScaler scaler = MediaQuery.textScalerOf(context);
      final bool is_cjk = LanguageUtil.is_cjk_language(
        Localizations.localeOf(context).languageCode,
      );
      final TextPainter painter = TextPainter(
        text: TextSpan(text: widget.text, style: effective_style),
        textDirection: direction,
        textScaler: scaler,
        textHeightBehavior: DefaultTextStyle.of(context).textHeightBehavior,
        strutStyle: const StrutStyle(),
      )..layout(maxWidth: constraints.maxWidth);
      final List<ui.LineMetrics> lines = painter.computeLineMetrics();
      final Size badge_size = ParagraphCommentBadge.measure(
        comment_count: widget.comment_count,
        style: ParagraphSelectionStyle.badge_text_style(
          is_dark: widget.is_dark,
          is_cjk: is_cjk,
        ),
        text_scaler: scaler,
        text_direction: direction,
      );
      final double width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : painter.width +
                badge_size.width +
                ParagraphSelectionStyle.badge_gap;
      final ui.LineMetrics? last_line = lines.isEmpty ? null : lines.last;
      final bool is_rtl = direction == TextDirection.rtl;
      final double inline_x = is_rtl
          ? (last_line?.left ?? width) -
                ParagraphSelectionStyle.badge_gap -
                badge_size.width
          : (last_line?.left ?? 0) +
                (last_line?.width ?? 0) +
                ParagraphSelectionStyle.badge_gap;
      final bool fits_inline =
          inline_x >= 0 && inline_x + badge_size.width <= width;
      final double badge_x = fits_inline
          ? inline_x
          : (is_rtl ? math.max(0, width - badge_size.width) : 0);
      final double badge_y = fits_inline && last_line != null
          ? math.max(
              0,
              last_line.baseline -
                  last_line.ascent +
                  (last_line.height - badge_size.height) / 2,
            )
          : painter.height;
      final double total_height = math.max(
        painter.height,
        badge_y + badge_size.height,
      );
      painter.dispose();
      return SizedBox(
        width: width,
        height: total_height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(top: 0, left: 0, right: 0, child: editable),
            Positioned(
              left: badge_x,
              top: badge_y,
              width: badge_size.width,
              height: badge_size.height,
              child: ParagraphCommentBadge(
                comment_count: widget.comment_count,
                is_dark: widget.is_dark,
                is_cjk: is_cjk,
                on_tap:
                    widget.on_comment_count_tap ??
                    () => widget.on_comment_count_tap_with_data?.call(
                      widget.text,
                      widget.comment_count,
                      widget.paragraph_id,
                    ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 只覆盖首次长按与阅读点击，保留 Flutter 的拖拽、手柄和滚动协调逻辑。
class _ParagraphGestureBuilder extends TextSelectionGestureDetectorBuilder {
  _ParagraphGestureBuilder({required _ParagraphSelectionState state})
    : _state = state,
      super(delegate: state);

  final _ParagraphSelectionState _state;

  @override
  void onSingleLongTapStart(LongPressStartDetails details) {
    _state._suppress_initial_reveal = true;
    super.onSingleLongTapStart(details);
    editableText.selectAll(SelectionChangedCause.longPress);
  }

  @override
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    _state._suppress_initial_reveal = false;
    super.onSingleLongTapMoveUpdate(details);
  }

  @override
  void onSingleLongTapEnd(LongPressEndDetails details) {
    super.onSingleLongTapEnd(details);
    _finish_initial_selection();
  }

  @override
  void onSingleLongTapCancel() {
    super.onSingleLongTapCancel();
    _finish_initial_selection();
  }

  /// 等待 EditableText 当前帧已排队的显示选区请求处理完成。
  void _finish_initial_selection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state._suppress_initial_reveal = false;
    });
  }

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    _state._handle_tap(details.globalPosition);
  }
}
