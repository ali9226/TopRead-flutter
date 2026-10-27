// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

/// TODO 只广播服务端确认的收藏关系；域、作品和账号会话共同隔离，收藏与点赞从不混用。
enum WorkFavoriteDomain { novel, comic }

class WorkFavoriteChange {
  const WorkFavoriteChange({
    required this.domain,
    required this.work_id,
    required this.favorited,
    required this.account_identity,
  });

  final WorkFavoriteDomain domain;
  final int work_id;
  final bool favorited;
  final String account_identity;
}

/// TODO 详情和阅读页通常各有控制器，成功收藏后同步按钮，避免返回详情仍显示旧星形。
/// 不持久化用户信息，不保存token；新页仍以真实详情响应初始化状态。
class WorkFavoriteSignals extends ChangeNotifier {
  static final instance = WorkFavoriteSignals();
  WorkFavoriteChange? latest;

  void confirm(WorkFavoriteChange change) {
    latest = change;
    notifyListeners();
  }
}
