import 'package:app/services/patch/patch_update_status.dart';

/// TODO 把真实下载进度转换为显示文本，未提供文件长度时不推算百分比。
String patch_progress_text(PatchUpdateStatus status, bool cjk) {
  if (status.stage == 'pending_restart') {
    return cjk ? '下载完成 · 100%' : 'Downloaded · 100%';
  }
  if (status.stage != 'downloading') return '';
  final received = (status.received / 1024 / 1024).toStringAsFixed(2);
  if (status.progress == null) {
    return cjk
        ? '已下载 $received MB · 总大小未知'
        : '$received MB received · Total unknown';
  }
  final total = (status.total / 1024 / 1024).toStringAsFixed(2);
  return '${(status.progress! * 100).floor()}% · $received / $total MB';
}

String patch_stage_text(String stage, bool cjk) {
  const labels = {
    'idle': ['等待检查', 'Waiting'],
    'preparing': ['准备热更新', 'Preparing'],
    'checking': ['检查补丁', 'Checking'],
    'downloading': ['下载补丁', 'Downloading'],
    'verifying': ['校验补丁', 'Verifying'],
    'installing': ['安装补丁', 'Installing'],
    'pending_restart': ['等待下次冷启动生效', 'Ready for next cold launch'],
    'up_to_date': ['没有可用的新补丁', 'No new patch'],
    'failed': ['热更新失败', 'Update failed'],
    'unavailable': ['热更新不可用', 'Unavailable'],
    'skipped': ['本次已跳过', 'Skipped'],
  };
  return labels[stage]?[cjk ? 0 : 1] ?? stage;
}
