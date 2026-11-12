import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_patcher/flutter_patcher.dart';

import 'package:app/api/patch.dart';
import 'package:app/models/patch_check_result.dart';
import 'package:app/services/patch/patch_boot_window.dart';
import 'package:app/services/patch/patch_runtime.dart';
import 'patch_update_status.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/websocket/websocket_service.dart';

/// TODO 补丁入口；先对账本次启动身份，再允许下载下一份补丁。
class PatchService {
  static const Duration boot_verify_duration = Duration(seconds: 5);
  static PatchRuntime? _runtime;
  static Future<bool>? _boot_window;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// TODO 尽早安装 SDK 崩溃保护；健康报告等待同一首帧后的前台观察窗口。
  static Future<void> init_patcher() async {
    if (!_supported) return;
    try {
      await FlutterPatcher.init(verifyAfter: boot_verify_duration);
      _boot_window ??= PatchBootWindow.wait(boot_verify_duration);
    } catch (error) {
      logUtil(msg: 'patch: 初始化失败 error=$error', type: 'w');
    }
  }

  static PatchRuntime get _instance => _runtime ??= PatchRuntime(
    _PatchPlatform(),
    on_status: (status) => patch_update_status.value = status,
    schedule_retry: (retry) {
      Timer(const Duration(seconds: 30), () => unawaited(retry()));
    },
  );

  /// TODO 强制整包升级时仍报告启动结果，但跳过补丁下载安装。
  static Future<void> start({Future<bool>? skip_patch_when}) async {
    if (!_supported) return;
    await _instance.start(skip_patch_when: skip_patch_when);
  }

  /// TODO 返回本次冷启动实际加载的热更版本，不读取待生效版本。
  static Future<int> get_applied_hotfix_version() async {
    if (!_supported) return 0;
    return _instance.get_applied_hotfix_version();
  }

  /// TODO 失败报告保留到本次进程或下次启动重试。
  static Future<void> report_boot_diagnostic() async {
    if (!_supported) return;
    await _instance.report_boot_diagnostic();
  }

  /// TODO 本地对账及启动观察结束后安装补丁，只对下次冷启动生效。
  static Future<void> check_and_apply_patch() async {
    if (!_supported) return;
    await _instance.check_and_apply_patch();
  }

  /// TODO 移除磁盘上的补丁，本进程实际运行版本保持到冷启动。
  static Future<void> rollback_patch() async {
    if (!_supported) return;
    await _instance.rollback_patch();
  }
}

/// TODO 生产适配层；业务请求继续使用统一加密 API。
class _PatchPlatform implements PatchRuntimePlatform, PatchProgressPlatform {
  static const String _state_key = 'patch_runtime_state_v2';

  @override
  Future<String?> read_state() => StorageUtil.getData(_state_key);

  @override
  Future<void> write_state(String value) async {
    await StorageUtil.saveData(_state_key, value);
  }

  @override
  Future<void> clear_legacy_state() async {
    await StorageUtil.removeData('patch_applied_id');
    await StorageUtil.removeData('patch_applied_hotfix_version');
  }

  @override
  Future<PatchTarget> read_target() => FlutterPatcher.patchTarget;

  @override
  Future<PatchBootDiagnostic?> read_diagnostic() =>
      FlutterPatcher.lastBootDiagnostic;

  @override
  Future<bool> wait_boot_verification() => PatchService._boot_window ??=
      PatchBootWindow.wait(PatchService.boot_verify_duration);

  @override
  Future<String> read_device_id() =>
      WebSocketService().get_or_create_visitor_uuid();

  @override
  Future<AppPatchCheckResult?> check_patch(
    PatchTarget target,
    String device_id,
  ) => check_app_patch(
    file_name: target.fileName,
    fingerprint: target.fingerprint,
    accepted_seq: target.acceptedSeq,
    version_code: target.versionCode,
    flavor: target.flavor,
    channel: target.channel,
    abi: target.abi,
    strategy: target.strategy,
    signed: target.signed,
    device_id: device_id,
  );

  @override
  Future<Uint8List?> download_patch(int patch_id) =>
      download_app_patch(patch_id: patch_id);

  @override
  Future<Uint8List?> download_with_progress(
    int patch_id,
    void Function(int, int) on_progress,
  ) => download_app_patch(patch_id: patch_id, on_progress: on_progress);

  @override
  Future<PatchInspection> inspect_patch(Uint8List bytes) =>
      FlutterPatcher.inspectPatch(bytes);

  @override
  Future<PatchApplyResult> apply_patch(Uint8List bytes) =>
      FlutterPatcher.applyPatchBytes(bytes);

  @override
  Future<void> rollback() => FlutterPatcher.rollback();

  @override
  Future<String?> read_installed_version() => FlutterPatcher.currentVersion;

  @override
  Future<bool> send_report(PatchBootReport report) => report_app_patch(
    patch_id: report.patch_id,
    device_id: report.device_id,
    is_healthy: report.is_healthy,
    boot_status: report.boot_status,
    diagnostic_id: report.diagnostic_id,
    patch_seq: '${report.patch_seq}',
    target_version_code: report.target_version_code,
    recorded_at: report.recorded_at,
    fingerprint: report.fingerprint,
    abi: report.abi,
  );

  @override
  void log(String message) => logUtil(msg: 'patch: $message', type: 'w');
}
