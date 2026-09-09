// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show FlutterView;

import 'package:app/pages/work_editor/style.dart';
import 'package:flutter/material.dart';

/// 编辑区独立接收键盘尺寸，避免每帧重建正文、章节列表和表单。
///
/// 键盘留白直接跟随系统尺寸；工具栏由焦点提前驱动，只做一次高度过渡。
/// 外层负责绘制背景，键盘圆角外露出的区域始终拥有相同的底色。
class EditorKeyboardLayout extends StatefulWidget {
  const EditorKeyboardLayout({
    super.key,
    required this.header,
    required this.content,
    required this.footer,
    this.collapse_header = true,
    this.collapse_when_editing = true,
  });

  final Widget header;
  final Widget content;
  final Widget footer;
  final bool collapse_header;
  final bool collapse_when_editing;

  /// 输入组件只订阅准入状态，不随键盘尺寸或动画进度重建。
  static bool input_enabled_of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_EditorKeyboardScope>()
          ?.input_enabled ??
      true;

  /// 重复点击已保留焦点的输入框时，也必须先收起工具栏。
  static void request_input(BuildContext context) => context
      .getInheritedWidgetOfExactType<_EditorKeyboardScope>()
      ?.request_input();

  @override
  State<EditorKeyboardLayout> createState() => _EditorKeyboardLayoutState();
}

class _EditorKeyboardLayoutState extends State<EditorKeyboardLayout>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _chrome_animation = AnimationController(
    vsync: this,
    duration: WorkEditorStyle.keyboard_chrome_duration,
    value: 1,
  );
  late final Animation<double> _chrome_size = _chrome_animation.drive(
    CurveTween(curve: WorkEditorStyle.keyboard_chrome_curve),
  );
  FlutterView? _view;
  double _keyboard_inset = 0;
  bool _has_focus = false;
  bool _keyboard_closing = false;
  bool _collapsed = false;
  late final ValueNotifier<bool> _input_enabled = ValueNotifier(
    !widget.collapse_when_editing,
  );
  bool _pending_input = false;
  bool _input_frame_scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chrome_animation.addStatusListener(_on_chrome_status);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.of(context);
    _keyboard_inset = _read_inset();
    _update_chrome();
  }

  @override
  void didUpdateWidget(EditorKeyboardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.collapse_when_editing && widget.collapse_when_editing) {
      // 从分类步骤进入正文时，重置上一页面允许立即输入的状态。
      _input_enabled.value = false;
      _pending_input = _has_focus;
    }
    _update_chrome();
  }

  double _read_inset() {
    final view = _view;
    return view == null ? 0 : view.viewInsets.bottom / view.devicePixelRatio;
  }

  @override
  void didChangeMetrics() {
    final inset = _read_inset();
    if (inset == _keyboard_inset) return;
    setState(() {
      // Android 返回键、系统下滑收起可能保留输入焦点：从首个下降帧恢复。
      if (inset < _keyboard_inset) {
        _keyboard_closing = true;
      } else if (_has_focus) {
        _keyboard_closing = false;
      }
      _keyboard_inset = inset;
      if (inset == 0 && _keyboard_closing) {
        _input_enabled.value = !widget.collapse_when_editing;
      }
      _update_chrome();
    });
  }

  void _on_focus_changed(bool has_focus) {
    setState(() {
      _has_focus = has_focus;
      _keyboard_closing = !has_focus;
      _pending_input = has_focus && !_input_enabled.value;
      if (!has_focus) {
        _input_enabled.value = !widget.collapse_when_editing;
      }
      _update_chrome();
    });
  }

  void _request_input() {
    if (!widget.collapse_when_editing) return;
    setState(() {
      _pending_input = !_input_enabled.value;
      _keyboard_closing = false;
      _update_chrome();
    });
  }

  void _on_chrome_status(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _schedule_input();
  }

  /// 必须等高度为零的画面提交后才允许 EditableText 打开输入连接。
  /// 不使用固定延时；失焦、退出页面或切换步骤均会取消尚未执行的请求。
  void _schedule_input() {
    if (_input_frame_scheduled || !_pending_input || !_has_focus) return;
    _input_frame_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _input_frame_scheduled = false;
      if (!mounted ||
          !_pending_input ||
          !_has_focus ||
          !_collapsed ||
          !_chrome_animation.isDismissed) {
        return;
      }
      _pending_input = false;
      _input_enabled.value = true;
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _update_chrome() {
    _collapsed =
        widget.collapse_when_editing &&
        !_keyboard_closing &&
        (_pending_input || _has_focus || _keyboard_inset > 0);
    if (!widget.collapse_when_editing) {
      _pending_input = false;
      _input_enabled.value = true;
    }
    final target = _collapsed ? 0.0 : 1.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _chrome_animation.value = target;
    } else if (target == 0) {
      _chrome_animation.reverse();
    } else {
      _chrome_animation.forward();
    }
    if (_chrome_animation.isDismissed) _schedule_input();
  }

  /// 仅重布局工具栏高度；不使用透明图层，也不在动画帧重建子组件。
  Widget _chrome(Widget child, {required double alignment}) {
    return ExcludeFocus(
      excluding: _collapsed,
      child: ExcludeSemantics(
        excluding: _collapsed,
        child: IgnorePointer(
          ignoring: _collapsed,
          child: SizeTransition(
            sizeFactor: _chrome_size,
            alignment: Alignment(0, alignment),
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content_widget = Expanded(
      child: Focus(
        canRequestFocus: false,
        onFocusChange: _on_focus_changed,
        child: widget.collapse_header
            ? widget.content
            : LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight,
                      ),
                      child: SingleChildScrollView(
                        primary: false,
                        child: widget.header,
                      ),
                    ),
                    Expanded(child: widget.content),
                  ],
                ),
              ),
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: _input_enabled,
      builder: (context, input_enabled, child) => _EditorKeyboardScope(
        input_enabled: input_enabled,
        request_input: _request_input,
        child: child!,
      ),
      child: widget.collapse_header
          ? Padding(
              // 普通表单已由外层 Scaffold 避让，只有正文需要自行处理键盘。
              padding: EdgeInsets.only(
                bottom: widget.collapse_when_editing ? _keyboard_inset : 0,
              ),
              child: Column(
                children: [
                  _chrome(widget.header, alignment: -1),
                  content_widget,
                  _chrome(widget.footer, alignment: 1),
                ],
              ),
            )
          : Column(
              children: [
                content_widget,
                _chrome(widget.footer, alignment: 1),
              ],
            ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chrome_animation.dispose();
    _input_enabled.dispose();
    super.dispose();
  }
}

class _EditorKeyboardScope extends InheritedWidget {
  const _EditorKeyboardScope({
    required this.input_enabled,
    required this.request_input,
    required super.child,
  });

  final bool input_enabled;
  final VoidCallback request_input;

  @override
  bool updateShouldNotify(_EditorKeyboardScope oldWidget) =>
      input_enabled != oldWidget.input_enabled;
}
