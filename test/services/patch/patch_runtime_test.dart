import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/models/patch_check_result.dart';
import 'package:app/services/patch/patch_runtime.dart';
import 'package:app/services/patch/patch_update_status.dart';
import 'package:flutter_patcher/flutter_patcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('进度来自下载字节回调，安装完成只显示待重启而非已生效', () async {
    final states = <PatchUpdateStatus>[];
    final platform = _ProgressPlatform();
    final runtime = PatchRuntime(platform, on_status: states.add);
    await runtime.check_and_apply_patch();
    expect(
      states.map((s) => s.stage),
      containsAllInOrder([
        'preparing',
        'checking',
        'downloading',
        'verifying',
        'installing',
        'pending_restart',
      ]),
    );
    expect(
      states.where((s) => s.stage == 'downloading').map((s) => s.progress),
      contains(0.5),
    );
    expect(states.last.running, isFalse);
    expect(states.last.detail, contains('下次完全退出'));
    expect(await runtime.get_applied_hotfix_version(), 0);
  });
  test('校验拒绝时诊断显示失败，不进入安装和待生效阶段', () async {
    final states = <PatchUpdateStatus>[];
    final platform = _ProgressPlatform()..inspection_seq = 999;
    await PatchRuntime(platform, on_status: states.add).check_and_apply_patch();
    expect(states.last.stage, 'failed');
    expect(states.any((s) => s.stage == 'pending_restart'), isFalse);
    expect(platform.apply_count, 0);
  });

  test('安装成功只登记候选，下一次冷启动才展示实际加载版本', () async {
    final platform = _Platform();
    final initial = PatchRuntime(platform);
    await initial.check_and_apply_patch();
    expect(platform.apply_count, 1);
    expect(await initial.get_applied_hotfix_version(), 0);
    expect(platform.state['pending']['seq'], 101);

    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    final restarted = PatchRuntime(platform);
    expect(await restarted.get_applied_hotfix_version(), 1);
    expect(platform.state['pending'], isNull);
  });

  test('SDK首帧不等于健康，观察窗口内熔断不得发送健康结果或下载补丁', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    final window = Completer<void>();
    platform.verify = () => window.future;
    final runtime = PatchRuntime(platform);
    final startup = runtime.start();
    await runtime.get_applied_hotfix_version();
    await Future<void>.delayed(Duration.zero);
    expect(platform.reports, isEmpty);
    expect(platform.check_count, 1);

    platform.diagnostic = _diagnostic(
      PatchBootStatus.droppedCircuitBreaker,
      at: 200,
    );
    platform.decision = null;
    window.complete();
    await startup;
    await runtime.flush_reports();
    expect(await runtime.get_applied_hotfix_version(), 0);
    expect(platform.reports.single.is_healthy, isFalse);
    expect(platform.reports.single.boot_status, 'droppedCircuitBreaker');
    expect(platform.reports.single.patch_seq, 101);
  });

  test('整包升级清实际版本，但移除诊断仍绑定旧补丁宿主身份', () async {
    final platform = await _installed();
    platform.target = _target(version: '26', fingerprint: 'new-host');
    platform.diagnostic = _diagnostic(
      PatchBootStatus.droppedVersionCodeMismatch,
    );
    final runtime = PatchRuntime(platform);
    await runtime.report_boot_diagnostic();
    expect(await runtime.get_applied_hotfix_version(), 0);
    final report = platform.reports.single;
    expect(report.target_version_code, '25');
    expect(report.fingerprint, 'old-host');
    expect(report.patch_id, 1);
  });

  test('健康诊断按完整宿主过滤同序号历史，其他ABI和指纹不能遮住实际补丁', () async {
    final platform = await _installed();
    _add_conflicting_identity(platform);
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    final runtime = PatchRuntime(platform);
    expect(await runtime.get_applied_hotfix_version(), 1);
    await runtime.report_boot_diagnostic();
    expect(platform.reports.single.patch_id, 1);
    expect(platform.reports.single.fingerprint, 'old-host');
    expect(platform.reports.single.abi, 'arm64-v8a');
  });

  test('失败诊断同序号和版本仍对应多个宿主时不猜测归属', () async {
    for (final status in <PatchBootStatus>[
      PatchBootStatus.droppedCircuitBreaker,
      PatchBootStatus.droppedVersionCodeMismatch,
    ]) {
      final platform = await _installed();
      _add_conflicting_identity(platform);
      platform.diagnostic = _diagnostic(status);
      final runtime = PatchRuntime(platform);
      await runtime.report_boot_diagnostic();
      expect(platform.reports, isEmpty);
      expect(platform.state['reports'], isEmpty);
      expect(await runtime.get_applied_hotfix_version(), 0);
    }
  });

  test('Dart错误已捕获但native仍返回patched时绝不误报健康', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    platform.verification_healthy = false;
    final runtime = PatchRuntime(platform);
    await runtime.start();
    await runtime.flush_reports();
    expect(platform.reports, isEmpty);
    expect(platform.check_count, 1);
    expect(await runtime.get_applied_hotfix_version(), 0);
  });

  test('SDK跨启动保留的同一失败诊断只上报一次', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.droppedCircuitBreaker);
    await PatchRuntime(platform).report_boot_diagnostic();
    await PatchRuntime(platform).report_boot_diagnostic();
    expect(platform.reports, hasLength(1));
    expect(platform.state['reports'], isEmpty);
  });

  test('失败报告持久化，下次启动以同一幂等id重试', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    platform.report_success = false;
    final retries = <Future<void> Function()>[];
    final first = PatchRuntime(platform, schedule_retry: retries.add);
    await first.report_boot_diagnostic();
    expect(platform.state['reports'], hasLength(1));
    expect(retries, hasLength(1));
    final original_id = platform.reports.single.diagnostic_id;

    platform.report_success = true;
    await PatchRuntime(platform).report_boot_diagnostic();
    expect(platform.reports, hasLength(2));
    expect(platform.reports.last.diagnostic_id, original_id);
    expect(platform.state['reports'], isEmpty);
  });

  test('同进程定时重试确认成功后才移除报告', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    platform.report_success = false;
    final retries = <Future<void> Function()>[];
    final runtime = PatchRuntime(platform, schedule_retry: retries.add);
    await runtime.report_boot_diagnostic();
    platform.report_success = true;
    await retries.single();
    expect(platform.reports, hasLength(2));
    expect(platform.state['reports'], isEmpty);
  });

  test('旧报告慢回包不覆盖新候选，也不把本次A诊断归给B', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    platform.decision = _decision(id: 2, seq: 102, hotfix: 2);
    final response = Completer<bool>();
    final report_started = Completer<void>();
    platform.report = (_) {
      report_started.complete();
      return response.future;
    };
    final runtime = PatchRuntime(platform);
    final report_task = runtime.report_boot_diagnostic();
    await report_started.future;
    await runtime.check_and_apply_patch();
    expect(platform.state['pending']['patch_id'], 2);
    expect(await runtime.get_applied_hotfix_version(), 1);
    expect(platform.reports.single.patch_id, 1);
    response.complete(true);
    await report_task;
    expect(platform.state['pending']['patch_id'], 2);
    expect(platform.state['reports'], isEmpty);
  });

  test('安装前身份已落盘，安装后进程退出也可在下一启动识别补丁', () async {
    final platform = _Platform();
    final applying = Completer<void>();
    final installed = Completer<PatchApplyResult>();
    platform.apply = () {
      applying.complete();
      return installed.future;
    };
    final task = PatchRuntime(platform).check_and_apply_patch();
    await applying.future;
    expect(platform.state['pending']['seq'], 101);
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    expect(await PatchRuntime(platform).get_applied_hotfix_version(), 1);
    installed.complete(PatchApplyResult.success());
    await task;
  });

  test('本地身份写失败或文件头与下发记录不匹配时不执行原生安装', () async {
    final platform = _Platform();
    platform.inspection_seq = 999;
    await PatchRuntime(platform).check_and_apply_patch();
    expect(platform.apply_count, 0);

    platform.inspection_seq = null;
    platform.fail_candidate_write = true;
    await PatchRuntime(platform).check_and_apply_patch();
    expect(platform.apply_count, 0);
  });

  test('验签安装失败不改变运行版本，也不会下次启动误报已生效', () async {
    final platform = _Platform();
    platform.apply = () async =>
        PatchApplyResult.failure(PatchApplyError.signatureInvalid);
    final runtime = PatchRuntime(platform);
    await runtime.check_and_apply_patch();
    expect(platform.state['pending'], isNull);
    expect(await runtime.get_applied_hotfix_version(), 0);
    await PatchRuntime(platform).report_boot_diagnostic();
    expect(platform.reports, isEmpty);
  });

  test('强制整包升级仍报告启动，但跳过补丁查询下载', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    final checks_before = platform.check_count;
    final runtime = PatchRuntime(platform);
    await runtime.start(skip_patch_when: Future<bool>.value(true));
    await runtime.flush_reports();
    expect(platform.check_count, checks_before);
    expect(platform.reports.single.is_healthy, isTrue);
  });

  test('手动回滚不提前隐藏本进程版本，下一冷启动无补丁才清除', () async {
    final platform = await _installed();
    platform.diagnostic = _diagnostic(PatchBootStatus.patched);
    final runtime = PatchRuntime(platform);
    await runtime.rollback_patch();
    expect(await runtime.get_applied_hotfix_version(), 1);
    platform.diagnostic = _diagnostic(PatchBootStatus.noPatch, seq: null);
    expect(await PatchRuntime(platform).get_applied_hotfix_version(), 0);
  });

  test('安装与手动回滚串行，重复检查只执行一次', () async {
    final platform = _Platform();
    final applying = Completer<void>();
    final installed = Completer<PatchApplyResult>();
    platform.apply = () {
      applying.complete();
      return installed.future;
    };
    final runtime = PatchRuntime(platform);
    final first = runtime.check_and_apply_patch();
    final second = runtime.check_and_apply_patch();
    await applying.future;
    final rollback = runtime.rollback_patch();
    await Future<void>.delayed(Duration.zero);
    expect(platform.rollback_count, 0);
    installed.complete(PatchApplyResult.success());
    await Future.wait([first, second, rollback]);
    expect(platform.apply_count, 1);
    expect(platform.rollback_count, 1);
    expect(platform.state['pending'], isNull);
  });
}

Future<_Platform> _installed() async {
  final platform = _Platform();
  await PatchRuntime(platform).check_and_apply_patch();
  return platform;
}

/// TODO 模拟恢复或同 build 重装后保留的另一宿主记录，序号相同但完整身份不同。
void _add_conflicting_identity(_Platform platform) {
  final state = platform.state;
  final known = state['known'] as List<dynamic>;
  known.add(<String, dynamic>{
    ...Map<String, dynamic>.from(known.first as Map),
    'patch_id': 99,
    'hotfix_version': 99,
    'fingerprint': 'another-host',
    'abi': 'ios-arm64',
  });
  platform.persisted = jsonEncode(state);
}

PatchTarget _target({String version = '25', String fingerprint = 'old-host'}) =>
    PatchTarget.fromNative(<String, dynamic>{
      'scope': <String, String>{
        'application_id': 'com.topread.novel',
        'version_code': version,
        'flavor': 'default',
        'channel': 'production',
        'abi': 'arm64-v8a',
        'strategy': 'bytecode',
        'fingerprint': fingerprint,
      },
      'signed': true,
      'acceptedSeq': 0,
    });

AppPatchCheckResult _decision({int id = 1, int seq = 101, int hotfix = 1}) =>
    AppPatchCheckResult(
      action: 'patch',
      patch_id: id,
      file_name: '25-arm64-v8a.fptc',
      seq: seq,
      hotfix_version: hotfix,
    );

PatchBootDiagnostic _diagnostic(
  PatchBootStatus status, {
  int? seq = 101,
  int at = 100,
}) => PatchBootDiagnostic(
  status: status,
  patchVersion: seq?.toString(),
  patchTargetVersionCode: seq == null ? null : 25,
  appVersionCode: 25,
  recordedAt: DateTime.fromMillisecondsSinceEpoch(at),
);

/// TODO 以同一存储模拟多个冷启动，原生与网络结果可分别控制。
class _Platform implements PatchRuntimePlatform {
  String? persisted;
  Map<String, dynamic> get state =>
      jsonDecode(persisted!) as Map<String, dynamic>;
  PatchTarget target = _target();
  PatchBootDiagnostic? diagnostic = _diagnostic(
    PatchBootStatus.noPatch,
    seq: null,
  );
  AppPatchCheckResult? decision = _decision();
  int? inspection_seq;
  bool report_success = true;
  bool verification_healthy = true;
  bool fail_candidate_write = false;
  int apply_count = 0;
  int check_count = 0;
  int rollback_count = 0;
  String? installed_version;
  Future<void> Function()? verify;
  Future<PatchApplyResult> Function()? apply;
  Future<bool> Function(PatchBootReport)? report;
  final List<PatchBootReport> reports = [];

  @override
  Future<String?> read_state() async => persisted;
  @override
  Future<void> write_state(String value) async {
    if (fail_candidate_write && (jsonDecode(value) as Map)['pending'] != null) {
      throw StateError('disk full');
    }
    persisted = value;
  }

  @override
  Future<void> clear_legacy_state() async {}
  @override
  Future<PatchTarget> read_target() async => target;
  @override
  Future<PatchBootDiagnostic?> read_diagnostic() async => diagnostic;
  @override
  Future<bool> wait_boot_verification() async {
    await verify?.call();
    return verification_healthy;
  }

  @override
  Future<String> read_device_id() async => 'device-one';
  @override
  Future<AppPatchCheckResult?> check_patch(
    PatchTarget target,
    String device_id,
  ) async {
    check_count++;
    return decision;
  }

  @override
  Future<Uint8List?> download_patch(int patch_id) async => Uint8List(146);
  @override
  Future<PatchInspection> inspect_patch(Uint8List bytes) async =>
      PatchInspection.fromNative(<String, dynamic>{
        'fresh': true,
        'action': 'publish',
        'seq': inspection_seq ?? decision!.seq,
        'reason': null,
      });
  @override
  Future<PatchApplyResult> apply_patch(Uint8List bytes) async {
    apply_count++;
    final result =
        await (apply?.call() ?? Future.value(PatchApplyResult.success()));
    if (result.ok) installed_version = '${decision!.seq}';
    return result;
  }

  @override
  Future<void> rollback() async {
    rollback_count++;
    installed_version = null;
  }

  @override
  Future<String?> read_installed_version() async => installed_version;
  @override
  Future<bool> send_report(PatchBootReport value) async {
    reports.add(value);
    return report == null ? report_success : report!(value);
  }

  @override
  void log(String message) {}
}

/// TODO 假下载发出确定字节回调，不访问网络。
class _ProgressPlatform extends _Platform implements PatchProgressPlatform {
  @override
  Future<Uint8List?> download_with_progress(
    int patch_id,
    void Function(int, int) on_progress,
  ) async {
    on_progress(73, 146);
    on_progress(146, 146);
    return download_patch(patch_id);
  }
}
