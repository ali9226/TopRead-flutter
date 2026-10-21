// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// TODO 会话内修改屏幕亮度；串行写入避免拖动的旧响应覆盖新值，退出恢复进入时的窗口覆盖值。
class ComicReaderBrightnessSession extends ChangeNotifier {
  static const MethodChannel channel = MethodChannel(
    'com.topread.novel/reader_brightness',
  );
  double value = 1;
  bool available = false;
  bool initialized = false;
  double? _original_override;
  bool _closed = false;
  bool _notifier_disposed = false;
  Future<void>? _initializing;
  Future<void>? _restoring;
  Future<void> _writes = Future<void>.value();
  double? _requested;

  Future<void> initialize() => _initializing ??= _initialize();

  /// 每次打开面板都读取当前屏幕，不能复用进入阅读页时的旧亮度。
  /// 原始覆盖值仍只在首次初始化记录，退出恢复不会被刷新操作篡改。
  Future<void> refresh() async {
    await initialize();
    await _writes;
    if (_closed) return;
    try {
      final result = await channel.invokeMapMethod<String, dynamic>(
        'getBrightness',
      );
      final current = result?['brightness'];
      if (current is num && current.isFinite) {
        value = current.toDouble().clamp(0.01, 1);
        available = true;
      }
    } on PlatformException {
      available = false;
    } on MissingPluginException {
      available = false;
    }
    _notify();
  }

  Future<void> _initialize() async {
    try {
      final result = await channel.invokeMapMethod<String, dynamic>(
        'getBrightness',
        // 新Dart会话清除模拟器上一次热重启遗留的预览；真机仍读取当前屏幕。
        {'reset_preview': true},
      );
      final brightness = result?['brightness'];
      final override = result?['override'];
      if (brightness is num &&
          override is num &&
          brightness.isFinite &&
          override.isFinite) {
        _original_override = override.toDouble();
        value = brightness.toDouble().clamp(0.01, 1);
        available = true;
      }
    } on PlatformException {
      available = false;
    } on MissingPluginException {
      available = false;
    } finally {
      initialized = true;
      _notify();
    }
  }

  /// TODO 滑块立即响应本地值；同一轮异步期间只写入最新目标，避免堆积原生亮度请求。
  void set_value(double next) {
    if (_closed || !available || !next.isFinite) return;
    value = next.clamp(0.01, 1);
    _requested = value;
    _notify();
    _writes = _writes.then((_) async {
      final target = _requested;
      _requested = null;
      if (_closed || target == null) return;
      try {
        await channel.invokeMethod<void>('setBrightness', {'value': target});
      } on PlatformException {
        available = false;
        _notify();
      } on MissingPluginException {
        available = false;
        _notify();
      }
    });
  }

  void _notify() {
    if (!_closed && !_notifier_disposed) notifyListeners();
  }

  /// TODO 幂等恢复：即使初始化尚未完成或拖动还在排队，也在最后一次原生写入后恢复原值。
  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    _closed = true;
    _requested = null;
    await initialize();
    await _writes;
    final original = _original_override;
    if (original == null) return;
    try {
      await channel.invokeMethod<void>('restoreBrightness', {
        'value': original,
      });
    } on PlatformException {
      // TODO 页面已退出，原生通道不可用时不向新页面投递错误提示。
    } on MissingPluginException {
      // TODO 非移动端没有屏幕亮度通道，保留正常退出流程。
    }
  }

  @override
  void dispose() {
    unawaited(restore());
    _notifier_disposed = true;
    super.dispose();
  }
}
