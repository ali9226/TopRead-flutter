import 'package:flutter/widgets.dart';

/// 一次布局帧中，同一阅读列表上方广告的尺寸变化。
class _PendingScrollCompensation {
  _PendingScrollCompensation(this.initial_offset);

  /// 尺寸变化前的正文位置，避免与框架自动范围修正重复相加。
  final double initial_offset;

  /// 各广告的变化量和生命周期检查，已销毁的广告不再补偿。
  final List<({double delta, bool Function() is_valid})> changes = [];
}

final Map<ScrollPosition, _PendingScrollCompensation> _pending_compensations =
    {};

/// 正在同步修正的列表；滚动监听可据此区分正文补偿和读者手动操作。
final Set<ScrollPosition> _compensating_positions = {};

/// 仅在广告高度补偿触发的同步滚动回调期间返回 true。
bool is_native_ad_scroll_compensating(ScrollPosition position) {
  return _compensating_positions.contains(position);
}

/// 合并同一帧的广告尺寸变化，在新范围就绪后一次性恢复正文位置。
///
/// [position] 是当前阅读列表的位置；[extent_delta] 为广告高度差；
/// [is_valid] 确认广告和列表仍然属于原页面，防止退出后旧回调回写。
void queue_native_ad_scroll_compensation({
  required ScrollPosition position,
  required double extent_delta,
  required bool Function() is_valid,
}) {
  final _PendingScrollCompensation? pending = _pending_compensations[position];
  if (pending != null) {
    pending.changes.add((delta: extent_delta, is_valid: is_valid));
    return;
  }

  final compensation = _PendingScrollCompensation(position.pixels);
  compensation.changes.add((delta: extent_delta, is_valid: is_valid));
  _pending_compensations[position] = compensation;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _pending_compensations.remove(position);
    final valid_changes = compensation.changes.where(
      (entry) => entry.is_valid(),
    );
    if (valid_changes.isEmpty || position.isScrollingNotifier.value) return;

    final double clamped_initial_offset = compensation.initial_offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    // 框架可能已因内容缩短修正到底部；用户或跳章改变的位置不被覆盖。
    if (position.pixels != compensation.initial_offset &&
        position.pixels != clamped_initial_offset) {
      return;
    }
    final double total_delta = valid_changes.fold(
      0,
      (double total, entry) => total + entry.delta,
    );
    final double target_offset = (compensation.initial_offset + total_delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (position.pixels == target_offset) return;
    _compensating_positions.add(position);
    try {
      position.jumpTo(target_offset);
    } finally {
      _compensating_positions.remove(position);
    }
  });
}
