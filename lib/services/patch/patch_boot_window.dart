import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';

/// TODO 从首帧开始累计前台时间，后台停留不计入 SDK 健康观察窗口。
class PatchBootWindow with WidgetsBindingObserver {
  PatchBootWindow._(this._duration);

  final Duration _duration;
  final Completer<bool> _ready = Completer<bool>();
  final Stopwatch _foreground = Stopwatch();
  Timer? _timer;
  bool _had_error = false;
  void Function(FlutterErrorDetails)? _prior_flutter_handler;
  bool Function(Object, StackTrace)? _prior_platform_handler;
  late final void Function(FlutterErrorDetails) _flutter_handler;
  late final bool Function(Object, StackTrace) _platform_handler;

  /// TODO 不阻塞首帧；窗口结束后解除监听并完成 Future。
  static Future<bool> wait(Duration duration) {
    final window = PatchBootWindow._(duration);
    window._watch_errors();
    WidgetsBinding.instance.addPostFrameCallback((_) => window._begin());
    return window._ready.future;
  }

  /// TODO 保留 SDK 错误链；本地同步标记避免原生失败诊断异步落盘前误报健康。
  void _watch_errors() {
    _prior_flutter_handler = FlutterError.onError;
    _prior_platform_handler = PlatformDispatcher.instance.onError;
    _flutter_handler = (details) {
      if (!_ready.isCompleted) _had_error = true;
      (_prior_flutter_handler ?? FlutterError.presentError)(details);
    };
    _platform_handler = (error, stack) {
      if (!_ready.isCompleted) _had_error = true;
      return _prior_platform_handler?.call(error, stack) ?? false;
    };
    FlutterError.onError = _flutter_handler;
    PlatformDispatcher.instance.onError = _platform_handler;
  }

  void _begin() {
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) _resume();
  }

  void _resume() {
    _foreground.start();
    final remaining = _duration - _foreground.elapsed;
    _timer?.cancel();
    _timer = Timer(remaining.isNegative ? Duration.zero : remaining, _finish);
  }

  void _finish() {
    _foreground.stop();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // TODO 不覆盖窗口期间其他组件安装的新处理器。
    if (identical(FlutterError.onError, _flutter_handler)) {
      FlutterError.onError = _prior_flutter_handler;
    }
    if (identical(PlatformDispatcher.instance.onError, _platform_handler)) {
      PlatformDispatcher.instance.onError = _prior_platform_handler;
    }
    if (!_ready.isCompleted) _ready.complete(!_had_error);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else {
      _foreground.stop();
      _timer?.cancel();
    }
  }
}
