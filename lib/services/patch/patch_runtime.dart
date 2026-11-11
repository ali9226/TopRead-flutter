import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_patcher/flutter_patcher.dart';

import 'package:app/models/patch_check_result.dart';

/// TODO 可注入的本地存储、原生 SDK 与网络边界，便于验证冷启动状态迁移。
abstract interface class PatchRuntimePlatform {
  Future<String?> read_state();
  Future<void> write_state(String value);
  Future<void> clear_legacy_state();
  Future<PatchTarget> read_target();
  Future<PatchBootDiagnostic?> read_diagnostic();
  Future<bool> wait_boot_verification();
  Future<String> read_device_id();
  Future<AppPatchCheckResult?> check_patch(
    PatchTarget target,
    String device_id,
  );
  Future<Uint8List?> download_patch(int patch_id);
  Future<PatchInspection> inspect_patch(Uint8List bytes);
  Future<PatchApplyResult> apply_patch(Uint8List bytes);
  Future<void> rollback();
  Future<String?> read_installed_version();
  Future<bool> send_report(PatchBootReport report);
  void log(String message);
}

/// TODO 已固定身份的不可变启动报告；网络重试不得改用后来安装的补丁身份。
class PatchBootReport {
  PatchBootReport.from_json(Map<String, dynamic> json)
    : patch_id = patch_int(json['patch_id']),
      device_id = json['device_id'] as String,
      is_healthy = json['is_healthy'] == true,
      boot_status = json['boot_status'] as String,
      diagnostic_id = json['diagnostic_id'] as String,
      patch_seq = patch_int(json['patch_seq']),
      target_version_code = json['target_version_code'] as String,
      recorded_at = patch_int(json['recorded_at']),
      fingerprint = json['fingerprint'] as String,
      abi = json['abi'] as String;

  final int patch_id;
  final String device_id;
  final bool is_healthy;
  final String boot_status;
  final String diagnostic_id;
  final int patch_seq;
  final String target_version_code;
  final int recorded_at;
  final String fingerprint;
  final String abi;

  Map<String, dynamic> to_json() => <String, dynamic>{
    'patch_id': patch_id,
    'device_id': device_id,
    'is_healthy': is_healthy,
    'boot_status': boot_status,
    'diagnostic_id': diagnostic_id,
    'patch_seq': patch_seq,
    'target_version_code': target_version_code,
    'recorded_at': recorded_at,
    'fingerprint': fingerprint,
    'abi': abi,
  };
}

/// TODO 实际加载版本只由本次原生诊断决定；磁盘安装版本仅作为下一次启动的候选。
class PatchRuntime {
  PatchRuntime(this._platform, {this.schedule_retry});

  final PatchRuntimePlatform _platform;
  final void Function(Future<void> Function() retry)? schedule_retry;
  Future<void> _state_tail = Future<void>.value();
  Future<void> _native_tail = Future<void>.value();
  Map<String, dynamic>? _state;
  Future<void>? _prepare_future;
  Future<void>? _observe_future;
  Future<void>? _check_future;
  Future<void>? _flush_future;
  bool _retry_scheduled = false;
  bool _boot_verification_failed = false;
  PatchTarget? _target;
  PatchBootDiagnostic? _boot_diagnostic;
  _PatchIdentity? _active;

  /// TODO 对账、健康观察先于安装；报告网络请求不阻塞安装或首帧。
  Future<void> start({Future<bool>? skip_patch_when}) async {
    await _observe_boot();
    unawaited(flush_reports());
    try {
      if (await (skip_patch_when ?? Future<bool>.value(false))) return;
      await check_and_apply_patch();
    } catch (error) {
      _platform.log('启动任务失败 error=$error');
    }
  }

  /// TODO 关于页只等待本地对账，不等待健康窗口或报告网络。
  Future<int> get_applied_hotfix_version() async {
    await _prepare();
    return _active?.hotfix_version ?? 0;
  }

  Future<void> _prepare() => _prepare_future ??= _prepare_boot();

  Future<void> _prepare_boot() async {
    try {
      _target = await _platform.read_target();
      _boot_diagnostic = await _platform.read_diagnostic();
      await _reconcile(_boot_diagnostic);
      // TODO 旧实现缺少 seq/目标身份，不能安全迁移为实际生效版本。
      await _platform.clear_legacy_state();
    } catch (error) {
      _active = null;
      _platform.log('宿主不支持热更或本地对账失败 error=$error');
    }
  }

  Future<void> _observe_boot() => _observe_future ??= _observe_boot_once();

  Future<void> _observe_boot_once() async {
    await _prepare();
    if (_target == null) return;
    try {
      if (_boot_diagnostic?.status == PatchBootStatus.patched) {
        // TODO SDK 的 patched 只确认首帧；前台窗口结束后重读，避免把随后熔断报成健康。
        _boot_verification_failed = !await _platform.wait_boot_verification();
        _boot_diagnostic = await _platform.read_diagnostic();
        _boot_verification_failed =
            _boot_verification_failed ||
            _boot_diagnostic?.status != PatchBootStatus.patched;
        await _reconcile(_boot_diagnostic);
        if (_boot_verification_failed &&
            _boot_diagnostic?.status == PatchBootStatus.patched) {
          _active = null;
          _platform.log('观察窗口捕获错误，等待原生失败诊断，暂不报告健康');
          return;
        }
      }
      final diagnostic = _boot_diagnostic;
      if (diagnostic == null || diagnostic.status == PatchBootStatus.noPatch) {
        return;
      }
      if (diagnostic.status == PatchBootStatus.patched && _active == null) {
        return;
      }
      final String device_id = await _platform.read_device_id();
      await _with_state((state) {
        final identity = _find_identity(state, diagnostic);
        if (identity == null) return;
        final int recorded_at = diagnostic.recordedAt.millisecondsSinceEpoch;
        final String diagnostic_id = sha256
            .convert(
              utf8.encode(
                jsonEncode([
                  device_id,
                  identity.patch_id,
                  identity.seq,
                  diagnostic.status.name,
                  recorded_at,
                ]),
              ),
            )
            .toString();
        // TODO SDK 会跨启动保留失败诊断，同一原生记录只能入队一次。
        if (state['last_diagnostic_id'] == diagnostic_id) return;
        final report = PatchBootReport.from_json(<String, dynamic>{
          'patch_id': identity.patch_id,
          'device_id': device_id,
          'is_healthy': diagnostic.status == PatchBootStatus.patched,
          'boot_status': diagnostic.status.name,
          'diagnostic_id': diagnostic_id,
          'patch_seq': identity.seq,
          'target_version_code': identity.version_code,
          'recorded_at': recorded_at,
          'fingerprint': identity.fingerprint,
          'abi': identity.abi,
        });
        (state['reports'] as List<dynamic>).add(report.to_json());
        state['last_diagnostic_id'] = diagnostic_id;
      });
    } catch (error) {
      _platform.log('准备启动报告失败 error=$error');
    }
  }

  Future<void> _reconcile(PatchBootDiagnostic? diagnostic) async {
    await _with_state((state) {
      final identity = diagnostic == null
          ? null
          : _find_identity(state, diagnostic);
      final target = _target;
      _active =
          diagnostic?.status == PatchBootStatus.patched &&
              identity != null &&
              target != null &&
              identity.matches(target)
          ? identity
          : null;
      // TODO 本次冷启动已决定实际加载结果；候选不能越过 native 诊断继续当作已生效。
      state['pending'] = null;
    });
  }

  _PatchIdentity? _find_identity(
    Map<String, dynamic> state,
    PatchBootDiagnostic diagnostic,
  ) {
    final int? seq = int.tryParse(diagnostic.patchVersion ?? '');
    if (seq == null) return null;
    final candidates = <_PatchIdentity>[];
    for (final raw in state['known'] as List<dynamic>) {
      final identity = _PatchIdentity.from_json(
        Map<String, dynamic>.from(raw as Map),
      );
      if (identity.seq == seq &&
          (diagnostic.patchTargetVersionCode == null ||
              '${diagnostic.patchTargetVersionCode}' ==
                  identity.version_code)) {
        // TODO 健康诊断必须属于当前完整宿主，不能被其他 ABI/指纹的同序号历史记录遮住。
        if (diagnostic.status == PatchBootStatus.patched &&
            (_target == null || !identity.matches(_target!))) {
          continue;
        }
        candidates.add(identity);
      }
    }
    // TODO 失败记录可能来自升级前的旧宿主；原生未提供指纹，歧义时拒绝猜测归属。
    return candidates.length == 1 ? candidates.single : null;
  }

  /// TODO 文件安装与手动回滚互斥；重复调用复用当前任务。
  Future<void> check_and_apply_patch() => _check_future ??= _with_native(
    _check_once,
  ).whenComplete(() => _check_future = null);

  Future<void> _check_once() async {
    await _observe_boot();
    try {
      if (_target == null || _boot_verification_failed) return;
      final target = await _platform.read_target();
      final check = await _platform.check_patch(
        target,
        await _platform.read_device_id(),
      );
      if (check == null ||
          !check.has_update ||
          check.seq <= target.acceptedSeq ||
          check.file_name != target.fileName) {
        return;
      }
      final bytes = await _platform.download_patch(check.patch_id);
      if (bytes == null) return;
      final inspection = await _platform.inspect_patch(bytes);
      if (!inspection.fresh ||
          inspection.seq != check.seq ||
          inspection.action !=
              (check.action == 'withdraw' ? 'withdraw' : 'publish')) {
        _platform.log('补丁文件头与下发记录不一致 patch_id=${check.patch_id}');
        return;
      }
      final identity = _PatchIdentity.from_check(check, target);
      // TODO 在原生原子安装之前持久化身份，进程即使在安装后立刻退出也能在下次对账。
      await _with_state((state) {
        state['pending'] = identity.to_json();
        final known = state['known'] as List<dynamic>;
        known.removeWhere(
          (raw) => (raw as Map)['patch_id'] == identity.patch_id,
        );
        known.add(identity.to_json());
      });
      final result = await _platform.apply_patch(bytes);
      if (!result.ok) {
        await _with_state((state) {
          if ((state['pending'] as Map?)?['patch_id'] == identity.patch_id) {
            state['pending'] = null;
          }
        });
        _platform.log(
          '安装失败 patch_id=${check.patch_id} error=${result.error?.name}',
        );
      }
    } catch (error) {
      _platform.log('检查或安装失败 error=$error');
    }
  }

  /// TODO 手动回滚只修改下次启动的磁盘状态；SDK 会吞掉原生错误，需回读确认。
  Future<void> rollback_patch() async {
    await _observe_boot();
    await _with_native(_rollback_once);
  }

  Future<void> _rollback_once() async {
    try {
      await _platform.rollback();
      if (await _platform.read_installed_version() != null) {
        _platform.log('回滚未完成，保留候选身份');
        return;
      }
      await _with_state((state) => state['pending'] = null);
    } catch (error) {
      _platform.log('回滚失败 error=$error');
    }
  }

  /// TODO 原生安装和手动移除共用串行队列，防止同时修改磁盘候选。
  Future<void> _with_native(Future<void> Function() action) {
    final operation = _native_tail.then((_) => action());
    _native_tail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> report_boot_diagnostic() async {
    await _observe_boot();
    await flush_reports();
  }

  /// TODO 仅成功响应后删除对应报告；慢响应不得覆盖后来安装产生的本地状态。
  Future<void> flush_reports() =>
      _flush_future ??= _flush_once().whenComplete(() => _flush_future = null);

  Future<void> _flush_once() async {
    bool failed = false;
    try {
      final reports = await _with_state(
        (state) => (state['reports'] as List<dynamic>)
            .map(
              (raw) => PatchBootReport.from_json(
                Map<String, dynamic>.from(raw as Map),
              ),
            )
            .toList(),
      );
      for (final report in reports) {
        bool sent = false;
        try {
          sent = await _platform.send_report(report);
        } catch (_) {
          /* TODO 保留失败报告。 */
        }
        if (!sent) {
          failed = true;
          continue;
        }
        await _with_state((state) {
          (state['reports'] as List<dynamic>).removeWhere(
            (raw) => (raw as Map)['diagnostic_id'] == report.diagnostic_id,
          );
        });
      }
    } catch (error) {
      failed = true;
      _platform.log('发送报告失败 error=$error');
    }
    if (failed && !_retry_scheduled && schedule_retry != null) {
      _retry_scheduled = true;
      schedule_retry!(() async {
        _retry_scheduled = false;
        await flush_reports();
      });
    }
  }

  /// TODO 单个 JSON 快照和串行事务避免报告回包删除新候选，写失败不提交内存状态。
  Future<T> _with_state<T>(FutureOr<T> Function(Map<String, dynamic>) action) {
    final operation = _state_tail.then((_) async {
      Map<String, dynamic> state;
      if (_state != null) {
        state = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(_state)) as Map,
        );
      } else {
        final raw = await _platform.read_state();
        state = raw == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
      state.putIfAbsent('known', () => <dynamic>[]);
      state.putIfAbsent('reports', () => <dynamic>[]);
      final result = await action(state);
      await _platform.write_state(jsonEncode(state));
      _state = state;
      return result;
    });
    _state_tail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}

/// TODO 保存签名文件所对应的业务记录和完整宿主身份，整包升级后仍可报告旧补丁被移除。
class _PatchIdentity {
  _PatchIdentity.from_json(Map<String, dynamic> json)
    : patch_id = patch_int(json['patch_id']),
      seq = patch_int(json['seq']),
      hotfix_version = patch_int(json['hotfix_version']),
      version_code = json['version_code'] as String,
      fingerprint = json['fingerprint'] as String,
      abi = json['abi'] as String,
      action = json['action'] as String;

  factory _PatchIdentity.from_check(
    AppPatchCheckResult check,
    PatchTarget target,
  ) => _PatchIdentity.from_json(<String, dynamic>{
    'patch_id': check.patch_id,
    'seq': check.seq,
    'hotfix_version': check.action == 'withdraw' ? 0 : check.hotfix_version,
    'version_code': target.versionCode,
    'fingerprint': target.fingerprint,
    'abi': target.abi,
    'action': check.action,
  });

  final int patch_id;
  final int seq;
  final int hotfix_version;
  final String version_code;
  final String fingerprint;
  final String abi;
  final String action;

  bool matches(PatchTarget target) =>
      action == 'patch' &&
      version_code == target.versionCode &&
      fingerprint == target.fingerprint &&
      abi == target.abi;

  Map<String, dynamic> to_json() => <String, dynamic>{
    'patch_id': patch_id,
    'seq': seq,
    'hotfix_version': hotfix_version,
    'version_code': version_code,
    'fingerprint': fingerprint,
    'abi': abi,
    'action': action,
  };
}
