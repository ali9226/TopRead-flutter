// TODO 项目发布工具新增标识符遵循 snake_case。
// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'progress.dart';

/// TODO 按实际完成的构建阶段显示总体进度；阶段内部仅显示耗时，不推算编译百分比。
class BuildProgress {
  BuildProgress(
    this.phases, {
    void Function(String)? write,
    this.terminal,
    this.automatic_heartbeat = true,
  }) : _write = write ?? stderr.write;

  final List<String> phases;
  final void Function(String) _write;
  final bool? terminal;
  final bool automatic_heartbeat;
  CliProgress? _active;
  int _index = -1;
  bool _closed = false;

  static const _labels = {
    'prepare': '准备工程与工具',
    'pub-get': '解析并校验依赖',
    'analysis': '分析应用代码',
    'interface': '生成补丁接口',
    'baseline-kernel': '编译热更基线',
    'ipa': '编译、签名并导出 IPA',
    'verify-ipa': '校验 IPA 与热更宿主',
    'apk': '编译 APK',
    'verify-apk': '校验 APK 与热更宿主',
    'aab': '编译 Android App Bundle',
    'verify-aab': '校验 Android App Bundle',
    'archive': '归档、上传并回读校验基线',
    'publish-output': '写入正式安装包与构建记录',
  };

  /// TODO 重复进入同一阶段不前进；总体条只统计此前确实完成的阶段。
  void enter(String phase) {
    if (_closed) return;
    final next = phases.indexOf(phase);
    if (next < 0 || next < _index) {
      throw ArgumentError.value(phase, 'phase', '未知或倒退的构建阶段');
    }
    if (next == _index) return;
    _active?.complete();
    _active = null;
    _index = next;
    final label = _labels[phase] ?? phase;
    _summary(next, '步骤 ${next + 1}/${phases.length}：$label');
    // TODO 上传阶段由各对象的真实字节进度更新，避免两个进度条同时刷新终端。
    if (phase != 'archive') {
      _active = CliProgress(
        label,
        show_bytes: false,
        write: _write,
        terminal: terminal,
        automatic_heartbeat: automatic_heartbeat,
      );
    }
  }

  void complete() {
    if (_closed) return;
    _closed = true;
    _active?.complete();
    _summary(phases.length, '构建、基线归档及正式产物写入完成');
  }

  void fail() {
    if (_closed) return;
    _closed = true;
    _active?.fail();
    _summary(_index < 0 ? 0 : _index, '当前阶段未完成，已保留构建日志');
  }

  void _summary(int completed, String message) {
    const width = 20;
    final filled = phases.isEmpty ? width : completed * width ~/ phases.length;
    final bar = '${'=' * filled}${' ' * (width - filled)}';
    _write('[进度] 总体 [$bar] $completed/${phases.length} · $message\n');
  }
}
