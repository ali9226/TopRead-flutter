// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:flutter/foundation.dart';

export 'pending.dart';

/// 已经被服务器确认的兴趣变化。只通知失效，不在写入时直接请求推荐。
class RecommendationRefreshSignals extends ChangeNotifier {
  static final instance = RecommendationRefreshSignals();
  int revision = 0;

  static const _interest_writes = {
    'user_preference/choose',
    'novel_like/click',
    'novel_favorite/click',
    'novel_favorite/remove',
    'novel_focus_on/click',
    'novel_focus_on/remove',
    'novel_read_record/save_progress',
    'novel_read_record/remove',
    'novel_comment/add',
    'novel_comment/like',
    'novel_comment/delete',
    'paragraph_comment/create',
    'paragraph_comment/reply',
    'paragraph_comment/like',
    'paragraph_comment/delete',
    'comics/collect',
    'comics/save_progress',
    'comics_comment/create',
    'comics_comment/add',
    'comics_comment/reply',
    'comics_comment/like',
    'comics_comment/delete',
  };

  /// 调用方必须先确认业务成功，且响应仍属于发起请求的认证会话。
  void record_success(String path, {Map<String, dynamic>? parameters}) {
    if (!_interest_writes.contains(path)) return;
    // 计时首帧只是建立服务器时钟，不代表已经产生有效阅读。
    if (path == 'novel_read_record/save_progress' &&
        parameters?['reading_only'] == true &&
        (num.tryParse('${parameters?['reading_seconds']}') ?? 0) <= 0) {
      return;
    }
    revision++;
    notifyListeners();
  }
}

/// 多次阅读心跳合并为一次失效，返回可见推荐页后才请求最新首屏。
/// 隐藏页面不发请求；请求过程中产生的新行为会在结束后补充一次刷新。
class RecommendationRefreshSubscription {
  RecommendationRefreshSubscription({
    required this.is_visible,
    required this.on_refresh,
    RecommendationRefreshSignals? signals,
    Listenable? route_changes,
  }) : _signals = signals ?? RecommendationRefreshSignals.instance,
       _route_changes = route_changes ?? AppRouter.routeChangeListenable() {
    _seen_revision = _signals.revision;
    _signals.addListener(check);
    _route_changes.addListener(check);
  }

  static const debounce = Duration(milliseconds: 300);
  final bool Function() is_visible;
  final Future<void> Function() on_refresh;
  final RecommendationRefreshSignals _signals;
  final Listenable _route_changes;
  late int _seen_revision;
  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  bool _invalidated = false;

  int get revision => _signals.revision;

  /// 身份在隐藏页面改变时，返回后也必须重新读取，不能复用旧账号列表。
  void invalidate() {
    _invalidated = true;
    check();
  }

  /// 首次加载、手动刷新和身份切换也已经读取了当时最新的兴趣。
  void acknowledge(int revision) {
    if (revision > _seen_revision) _seen_revision = revision;
    _invalidated = false;
    if (_seen_revision >= _signals.revision) _timer?.cancel();
    check();
  }

  /// 路由返回、首页 Tab 激活和行为写入共同使用这一去重入口。
  void check() {
    if (_disposed ||
        _running ||
        (!_invalidated && _seen_revision >= _signals.revision) ||
        !is_visible()) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (_disposed ||
        _running ||
        (!_invalidated && _seen_revision >= _signals.revision) ||
        !is_visible()) {
      return;
    }
    final revision = _signals.revision;
    _invalidated = false;
    _running = true;
    try {
      await on_refresh();
    } finally {
      // 失败由页面保留重试入口；避免网络故障时自发无限重试。
      if (revision > _seen_revision) _seen_revision = revision;
      _running = false;
      check();
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _signals.removeListener(check);
    _route_changes.removeListener(check);
  }
}
