// ignore_for_file: non_constant_identifier_names

/* TODO
 * app_patch/check 接口返回的补丁决策模型。
 *
 * [action] 服务端决策：none=无补丁、patch=补丁、withdraw=回滚文件。
 * [patch_id] 命中时的补丁记录 id，下载与上报使用。
 * [file_name] 补丁文件名（如 24-arm64-v8a.fptc）。
 * [seq] 补丁序号，设备只接受大于已装序号的文件。
 * [hotfix_version] 热更版本（同一目标包的第 N 个补丁，1 起递增；回滚/无补丁为 0）。
 */
/// TODO 服务端 BIGINT（patch_id）经 bigNumberStrings 序列化成字符串数字，
/// 统一归一化，防止补丁决策解析失败。
int patch_int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

class AppPatchCheckResult {
  /// 服务端决策：none / patch / withdraw。
  final String action;

  /// 补丁记录 id。
  final int patch_id;

  /// 补丁文件名。
  final String file_name;

  /// 补丁序号。
  final int seq;

  /// 热更版本（同目标包第 N 个补丁，回滚/无补丁为 0）。
  final int hotfix_version;

  const AppPatchCheckResult({
    required this.action,
    required this.patch_id,
    required this.file_name,
    required this.seq,
    this.hotfix_version = 0,
  });

  /// 是否需要下载安装补丁（补丁或回滚文件都走下载安装流程）。
  bool get has_update =>
      (action == 'patch' || action == 'withdraw') && patch_id > 0 && seq > 0;

  factory AppPatchCheckResult.from_json(Map<String, dynamic> json) {
    return AppPatchCheckResult(
      action: (json['action'] ?? 'none') as String,
      patch_id: patch_int(json['patch_id']),
      file_name: (json['file_name'] ?? '') as String,
      seq: patch_int(json['seq']),
      hotfix_version: patch_int(json['hotfix_version']),
    );
  }
}
