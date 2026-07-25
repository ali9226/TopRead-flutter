// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/fcm/register_token.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 语种切换刷新阶段。
///
/// 配置数据必须先于页面内容刷新，后台任务不阻塞页面恢复展示。
enum LanguageRefreshPhase { configuration, content, background }

/// 单次语种切换上下文。
class LanguageRefreshContext {
  /// 切换后的语种代码。
  final String language_code;

  /// 本次切换版本号。
  final int revision;

  const LanguageRefreshContext({
    required this.language_code,
    required this.revision,
  });

  /// 当前任务是否仍属于最新一次语种切换。
  bool get is_current =>
      LanguageChangeHandler.is_current_revision(revision, language_code);
}

typedef LanguageRefreshCallback =
    Future<void> Function(LanguageRefreshContext context);
typedef LanguageRefreshPrepareCallback =
    void Function(LanguageRefreshContext context);

/// 语种刷新任务订阅。
class LanguageRefreshSubscription {
  final int _task_id;
  bool _disposed = false;

  LanguageRefreshSubscription._(this._task_id);

  /// 注销刷新任务。
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    LanguageChangeHandler._remove_refresh_task(_task_id);
  }
}

class _LanguageRefreshTask {
  final int id;
  final LanguageRefreshPhase phase;
  final LanguageRefreshPrepareCallback? on_prepare;
  final LanguageRefreshCallback on_refresh;

  const _LanguageRefreshTask({
    required this.id,
    required this.phase,
    required this.on_prepare,
    required this.on_refresh,
  });
}

/// 全局语种切换协调器。
///
/// 所有依赖语种的数据通过 [register_refresh_task] 注册，切换时统一执行：
/// 1. 同步进入刷新态并清理旧语种展示数据。
/// 2. 切换 Flutter Locale。
/// 3. 先刷新基础配置，再并行刷新页面内容。
/// 4. 最后执行 FCM 等不阻塞页面的后台任务。
class LanguageChangeHandler {
  static String? _last_language_code;
  static int _revision = 0;
  static int _next_task_id = 0;
  static LanguageRefreshContext? _active_context;

  static final Map<int, _LanguageRefreshTask> _refresh_tasks =
      <int, _LanguageRefreshTask>{};

  /// 当前是否正在执行语种切换刷新。
  static final RxBool is_refreshing = false.obs;

  /// 初始化当前语种。
  static Future<void> init() async {
    try {
      final String? saved_language_code = await StorageUtil.getData(
        LanguageStore.language_key,
      );
      _last_language_code = saved_language_code == null
          ? null
          : _normalize_language_code(saved_language_code);
      logUtil(msg: 'LanguageChangeHandler: 初始化完成，当前语种: $_last_language_code');
    } catch (error) {
      logUtil(msg: 'LanguageChangeHandler: 初始化失败: $error', type: 'e');
    }
  }

  /// 同步启动阶段最终解析出的语种。
  ///
  /// 必须在语言相关 Store 初始化前调用，确保读取和写入正确的分语种缓存。
  static void sync_initial_language(String language_code) {
    _last_language_code = _normalize_language_code(language_code);
  }

  /// 注册需要在语种切换时执行的刷新任务。
  static LanguageRefreshSubscription register_refresh_task({
    required LanguageRefreshPhase phase,
    LanguageRefreshPrepareCallback? on_prepare,
    required LanguageRefreshCallback on_refresh,
  }) {
    final int task_id = ++_next_task_id;
    final _LanguageRefreshTask task = _LanguageRefreshTask(
      id: task_id,
      phase: phase,
      on_prepare: on_prepare,
      on_refresh: on_refresh,
    );
    _refresh_tasks[task_id] = task;

    /// 页面如果恰好在切换过程中挂载，立即加入当前刷新，不遗漏本次事件。
    final LanguageRefreshContext? active_context = _active_context;
    if (is_refreshing.value &&
        active_context != null &&
        active_context.is_current) {
      _prepare_task(task, active_context);
    }

    return LanguageRefreshSubscription._(task_id);
  }

  /// 统一切换语种并启动刷新流程。
  ///
  /// 返回时 Locale 已切换完成，网络刷新继续在后台执行。
  static Future<bool> change_language(
    BuildContext context,
    String new_language_code,
  ) async {
    final String normalized_code = _normalize_language_code(new_language_code);
    if (_last_language_code == normalized_code &&
        context.locale.languageCode == normalized_code) {
      return false;
    }

    final String? previous_code = _last_language_code;
    final LanguageRefreshContext refresh_context = LanguageRefreshContext(
      language_code: normalized_code,
      revision: ++_revision,
    );

    _last_language_code = normalized_code;
    _active_context = refresh_context;
    is_refreshing.value = true;
    logUtil(
      msg:
          'LanguageChangeHandler: 语种从 $previous_code 变化为 $normalized_code，'
          'revision=${refresh_context.revision}',
    );

    /// 内容组件先保存当前选择，配置任务随后统一清空旧语种数据。
    _prepare_phase(LanguageRefreshPhase.content, refresh_context);
    _prepare_phase(LanguageRefreshPhase.configuration, refresh_context);
    _prepare_phase(LanguageRefreshPhase.background, refresh_context);

    await StorageUtil.saveData(LanguageStore.language_key, normalized_code);
    if (!context.mounted || !refresh_context.is_current) {
      return false;
    }

    await context.setLocale(Locale(normalized_code));
    if (!refresh_context.is_current) {
      return false;
    }

    unawaited(_run_refresh_pipeline(refresh_context));
    return true;
  }

  /// 兼容已先行切换 Locale 的旧调用入口。
  static Future<void> onLanguageChanged(String new_language_code) async {
    final String normalized_code = _normalize_language_code(new_language_code);
    if (_last_language_code == normalized_code) return;

    final LanguageRefreshContext refresh_context = LanguageRefreshContext(
      language_code: normalized_code,
      revision: ++_revision,
    );
    _last_language_code = normalized_code;
    _active_context = refresh_context;
    is_refreshing.value = true;

    _prepare_phase(LanguageRefreshPhase.content, refresh_context);
    _prepare_phase(LanguageRefreshPhase.configuration, refresh_context);
    _prepare_phase(LanguageRefreshPhase.background, refresh_context);
    await StorageUtil.saveData(LanguageStore.language_key, normalized_code);
    unawaited(_run_refresh_pipeline(refresh_context));
  }

  /// 执行分阶段刷新。
  static Future<void> _run_refresh_pipeline(
    LanguageRefreshContext refresh_context,
  ) async {
    await _run_phase(LanguageRefreshPhase.configuration, refresh_context);
    if (!refresh_context.is_current) return;

    await _run_phase(LanguageRefreshPhase.content, refresh_context);
    if (!refresh_context.is_current) return;

    is_refreshing.value = false;
    _active_context = null;

    await _run_phase(LanguageRefreshPhase.background, refresh_context);
    if (!refresh_context.is_current) return;
    await _update_fcm_language(refresh_context.language_code);
  }

  /// 执行一个刷新阶段内的全部任务。
  static Future<void> _run_phase(
    LanguageRefreshPhase phase,
    LanguageRefreshContext refresh_context,
  ) async {
    if (!refresh_context.is_current) return;
    final List<_LanguageRefreshTask> tasks = _refresh_tasks.values
        .where((_LanguageRefreshTask task) => task.phase == phase)
        .toList(growable: false);

    await Future.wait<void>(
      tasks.map((_LanguageRefreshTask task) async {
        if (!refresh_context.is_current ||
            !identical(_refresh_tasks[task.id], task)) {
          return;
        }
        try {
          await task.on_refresh(refresh_context);
        } catch (error) {
          logUtil(
            msg: 'LanguageChangeHandler: ${task.phase.name} 刷新任务失败: $error',
            type: 'e',
          );
        }
      }),
    );
  }

  /// 执行指定阶段的同步准备任务。
  static void _prepare_phase(
    LanguageRefreshPhase phase,
    LanguageRefreshContext refresh_context,
  ) {
    final List<_LanguageRefreshTask> tasks = _refresh_tasks.values
        .where((_LanguageRefreshTask task) => task.phase == phase)
        .toList(growable: false);
    for (final _LanguageRefreshTask task in tasks) {
      _prepare_task(task, refresh_context);
    }
  }

  static void _prepare_task(
    _LanguageRefreshTask task,
    LanguageRefreshContext refresh_context,
  ) {
    try {
      task.on_prepare?.call(refresh_context);
    } catch (error) {
      logUtil(
        msg: 'LanguageChangeHandler: ${task.phase.name} 准备任务失败: $error',
        type: 'e',
      );
    }
  }

  static void _remove_refresh_task(int task_id) {
    _refresh_tasks.remove(task_id);
  }

  /// 更新 FCM Token 的语言代码。
  static Future<void> _update_fcm_language(String language_code) async {
    try {
      logUtil(msg: 'LanguageChangeHandler: 更新 FCM 语言代码为 $language_code');
      await FcmRegisterToken.execute();
    } catch (error) {
      logUtil(msg: 'LanguageChangeHandler: 更新 FCM 语言代码失败: $error', type: 'e');
    }
  }

  static String _normalize_language_code(String language_code) {
    final String normalized = language_code.trim().toLowerCase();
    if (normalized.isEmpty) return 'en';
    return normalized.split(RegExp(r'[-_]')).first;
  }

  /// 当前语种代码。
  static String get current_language_code => _last_language_code ?? 'en';

  /// 当前语种请求版本。
  static int get current_revision => _revision;

  /// 兼容旧命名的当前语种代码。
  static String? get currentLanguageCode => _last_language_code;

  /// 判断异步响应是否属于最新语种。
  static bool is_current_revision(int revision, [String? language_code]) {
    if (_revision != revision) return false;
    if (language_code == null) return true;
    return _last_language_code == _normalize_language_code(language_code);
  }

  /// 应用恢复时同步 FCM 语种。
  static Future<void> triggerUpdate() async {
    final String? current_code = await StorageUtil.getData(
      LanguageStore.language_key,
    );
    if (current_code == null) return;
    _last_language_code = _normalize_language_code(current_code);
    await _update_fcm_language(_last_language_code!);
  }
}
