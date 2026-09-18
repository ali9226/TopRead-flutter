// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'logic.dart';
import 'style.dart';
import 'widgets/composer_body.dart';
import 'widgets/input_panel.dart';

export 'show_composer.dart';

/// 独立段评弹窗，只组装编辑区和输入面板，业务及键盘状态分别由逻辑层管理。
class ParagraphCommentComposer extends StatefulWidget {
  final String quote;
  final bool is_dark;
  final Future<bool> Function(String content, List<String> images) on_send;

  const ParagraphCommentComposer({
    super.key,
    required this.quote,
    required this.is_dark,
    required this.on_send,
  });

  @override
  State<ParagraphCommentComposer> createState() =>
      _ParagraphCommentComposerState();
}

class _ParagraphCommentComposerState extends State<ParagraphCommentComposer>
    with WidgetsBindingObserver {
  late final ParagraphCommentComposerLogic _logic;
  ui.FlutterView? _view;
  bool _is_closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logic = ParagraphCommentComposerLogic(
      on_send: widget.on_send,
      on_close: () {
        if (!mounted || _is_closing) return;
        _is_closing = true;
        Navigator.of(context).pop();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_is_closing && _logic.is_active) {
        _logic.focus_node.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.of(context);
    // 此处本身会重建 UI，不在构建过程中额外发送状态通知。
    _read_view_metrics(notify: false);
  }

  @override
  void didChangeMetrics() => _read_view_metrics();

  /// 直接读取窗口指标，不等待 MediaQuery 的下一帧，切换表情时已有完整键盘高度。
  void _read_view_metrics({bool notify = true}) {
    final ui.FlutterView? view = _view;
    if (view == null || !_logic.is_active) return;
    _logic.input_panel.update_metrics(
      keyboard_height: view.viewInsets.bottom / view.devicePixelRatio,
      view_width: view.physicalSize.width / view.devicePixelRatio,
      view_height: view.physicalSize.height / view.devicePixelRatio,
      notify: notify,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    onPopInvokedWithResult: (bool did_pop, _) {
      if (did_pop) {
        _is_closing = true;
        _logic.deactivate();
      }
    },
    child: ListenableBuilder(
      listenable: _logic,
      builder: (BuildContext context, _) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double safe_bottom = MediaQuery.viewPaddingOf(context).bottom;
          final double panel_height = math.min(
            constraints.maxHeight,
            math.max(_logic.input_panel.height, safe_bottom),
          );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _logic.close,
            child: Material(
              key: const ValueKey<String>('paragraph_comment_composer'),
              color: ParagraphCommentComposerStyle.surface(widget.is_dark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(ParagraphCommentComposerStyle.radius),
              ),
              clipBehavior: Clip.antiAlias,
              child: TextFieldTapRegion(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      // 只对编辑区限宽并避让侧边安全区，底部键盘背景保持全宽。
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: ParagraphCommentComposerStyle.max_width,
                          ),
                          child: ParagraphCommentComposerBody(
                            logic: _logic,
                            quote: widget.quote,
                            is_dark: widget.is_dark,
                          ),
                        ),
                      ),
                    ),
                    ParagraphCommentInputPanel(
                      logic: _logic,
                      is_dark: widget.is_dark,
                      height: panel_height,
                      safe_bottom: safe_bottom,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
