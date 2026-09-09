// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'editor_keyboard_layout.dart';

/// 保留 TextField 原生光标、选择及焦点行为，仅延后输入连接的建立。
///
/// builder 必须把 read_only、on_tap 分别交给 TextField.readOnly、onTap，
/// 并启用 onTapAlwaysCalled，保证系统收起键盘后再次点击也遵循相同时序。
class EditorKeyboardInput extends StatelessWidget {
  const EditorKeyboardInput({super.key, required this.builder});

  final Widget Function(bool read_only, VoidCallback on_tap) builder;

  @override
  Widget build(BuildContext context) => builder(
    !EditorKeyboardLayout.input_enabled_of(context),
    () => EditorKeyboardLayout.request_input(context),
  );
}
