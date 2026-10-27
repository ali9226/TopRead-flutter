// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:flutter/foundation.dart';

/// 服务器暂时返回旧画像时补取新首屏；仅在原页面上下文可见时有限重试。
class RecommendationPendingRefresh {
  RecommendationPendingRefresh({
    required this.is_visible,
    required this.context_key,
    required this.can_refresh,
    required this.on_refresh,
    Listenable? route_changes,
    Listenable? content_changes,
  }) : _route_changes = route_changes ?? AppRouter.routeChangeListenable(),
       _content_changes = content_changes {
    _route_changes.addListener(check);
    _content_changes?.addListener(check);
  }

  static const delay = Duration(milliseconds: 1200);
  static const max_attempts = 3;
  final bool Function() is_visible;
  final Object? Function() context_key;
  final bool Function() can_refresh;
  final Future<void> Function() on_refresh;
  final Listenable _route_changes;
  final Listenable? _content_changes;
  Timer? _timer;
  Object? _context;
  bool _pending = false;
  bool _running = false;
  bool _disposed = false;
  int _attempts = 0;
  int _generation = 0;

  void observe(bool pending) {
    if (_disposed) return;
    if (!pending) {
      reset();
      return;
    }
    final context = context_key();
    if (!_pending || context != _context) {
      reset();
      _context = context;
      _pending = true;
    }
    check();
  }

  /// 手动刷新或身份变化开始新一轮，已排队的旧请求不能再发起。
  void reset() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _pending = false;
    _context = null;
    _attempts = 0;
  }

  void check() {
    if (_disposed || !_pending) return;
    if (_context != context_key()) {
      reset();
      return;
    }
    if (!is_visible() || !can_refresh()) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_running || _timer != null || _attempts >= max_attempts) return;
    final generation = _generation;
    _timer = Timer(delay, () => unawaited(_refresh(generation)));
  }

  Future<void> _refresh(int generation) async {
    _timer = null;
    if (_disposed || generation != _generation || !_pending) return;
    if (_context != context_key()) {
      reset();
      return;
    }
    if (!is_visible() || !can_refresh()) return;
    _attempts++;
    _running = true;
    try {
      await on_refresh();
    } catch (_) {
      // 页面提供原位重试入口；异常同样受次数上限约束。
    } finally {
      _running = false;
      if (!_disposed) check();
    }
  }

  void dispose() {
    _disposed = true;
    reset();
    _route_changes.removeListener(check);
    _content_changes?.removeListener(check);
  }
}
