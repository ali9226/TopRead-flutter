// ignore_for_file: non_constant_identifier_names

/// 全应用共享的全屏广告占用保护，防止开屏与激励广告同时展示。
class FullScreenAdGuard {
  const FullScreenAdGuard._();

  /// 当前持有全屏广告展示资格的实例；null 表示空闲。
  static Object? _owner;

  /// 为 [owner] 申请独占资格；已有占用时返回 false，同一实例也不可重入。
  static bool try_acquire(Object owner) {
    if (_owner != null) return false;
    _owner = owner;
    return true;
  }

  /// 仅当 [owner] 就是当前持有者时释放资格，防止其他流程误释放。
  static void release(Object owner) {
    if (identical(_owner, owner)) _owner = null;
  }
}
