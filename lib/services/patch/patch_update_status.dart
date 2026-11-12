import 'package:flutter/foundation.dart';

/// TODO 热更任务的进程内快照；新页面可立即读取已完成或进行中的状态。
class PatchUpdateStatus {
  const PatchUpdateStatus({
    this.stage = 'idle',
    this.detail = '等待启动检查',
    this.received = 0,
    this.total = 0,
  });
  final String stage;
  final String detail;
  final int received;
  final int total;
  bool get running => const [
    'preparing',
    'checking',
    'downloading',
    'verifying',
    'installing',
  ].contains(stage);
  double? get progress => total > 0 ? (received / total).clamp(0.0, 1.0) : null;
}

/// TODO 只保存运行状态，不持久化诊断文本或用户凭据。
final patch_update_status = ValueNotifier<PatchUpdateStatus>(
  const PatchUpdateStatus(),
);
