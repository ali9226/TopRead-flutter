// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

/// 构建正文时，将每个段落的点击和选择状态接入同一个手势门控。
typedef ReaderTapRegionBuilder =
    Widget Function(
      ValueChanged<Offset> on_tap_position,
      void Function(String paragraph_key, bool active) on_selection_changed,
    );

/// 阅读区域的单击协调器：有选区时，本次点击只退出选择。
///
/// 原生选区可能在 pointer down 阶段失焦并清空旧选区；
/// 这里必须提前记住按下时的选择状态，不能到 tap up 时才查询选区。
class ReaderTapRegion extends StatefulWidget {
  const ReaderTapRegion({
    super.key,
    required this.on_tap_position,
    required this.builder,
  });

  /// 单击手势确认且无需退出选区后，通知页面翻页或切换导航。
  final ValueChanged<Offset> on_tap_position;

  /// 构建区域正文，段落内部点击和区域空白点击使用相同回调。
  final ReaderTapRegionBuilder builder;

  @override
  State<ReaderTapRegion> createState() => _ReaderTapRegionState();
}

class _ReaderTapRegionState extends State<ReaderTapRegion> {
  /// 跨章节、跨正文版本的选中段落分别记录，失焦互不覆盖。
  final Set<String> _selected_paragraphs = <String>{};

  /// 当前指针序列开始时存在选区；直到下一次按下前都阻止阅读单击。
  bool _tap_started_with_selection = false;

  /// Listener 提前记录本次点击是否用于取消已存在的选区。
  void _handle_pointer_down(PointerDownEvent event) {
    _tap_started_with_selection = _selected_paragraphs.isNotEmpty;
  }

  /// 仅记录交互状态，不需要重建正文或打断原生选区手柄。
  void _handle_selection_changed(String paragraph_key, bool active) {
    if (active) {
      _selected_paragraphs.add(paragraph_key);
    } else {
      _selected_paragraphs.remove(paragraph_key);
    }
  }

  /// 长按、拖动不会走到这里；同次单击中的提前失焦不会触发翻页。
  void _handle_confirmed_tap(Offset position) {
    if (_tap_started_with_selection) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    widget.on_tap_position(position);
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _handle_pointer_down,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handle_confirmed_tap(details.globalPosition),
      child: widget.builder(_handle_confirmed_tap, _handle_selection_changed),
    ),
  );
}
