import 'dart:async';
import 'package:app/api/creator_workspace.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

// TODO 每次业务操作生成标识；网络重试必须复用同一标识与同一份参数。
String creatorRequestKey() =>
    'draft_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';

/* TODO 单章自动保存控制器：串行请求、输入期间保存不丢字、失败保留本机副本、冲突停止覆盖。 */
class ChapterDraftController extends ChangeNotifier {
  ChapterDraftController({
    required this.revisionId,
    required this.lockVersion,
    required Map<String, dynamic> initial,
    required this.send,
    required this.writeRecovery,
    required this.clearRecovery,
    this.debounce = const Duration(seconds: 3),
    this.auto_save = true,
  }) : values = Map.of(initial),
       saved = Map.of(initial);
  final int revisionId;
  int lockVersion;
  Map<String, dynamic> values;
  Map<String, dynamic> saved;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) send;
  final Future<void> Function(Map<String, dynamic>) writeRecovery;
  final Future<void> Function() clearRecovery;
  final Duration debounce;

  /// 已发布原章只保存本机恢复副本，点击发布才更新公开内容。
  final bool auto_save;
  Timer? _timer;
  Future<void>? _saving;
  Future<void> _storage = Future.value();
  Map<String, dynamic>? _request;
  bool _disposed = false;
  bool conflict = false;
  bool localBackupReady = false;
  String? error;
  bool get dirty => !mapEquals(values, saved);
  bool get saving => _saving != null;

  void update(String title, String content) {
    values = {'title': title, 'content': content};
    _backup();
    _timer?.cancel();
    if (auto_save) {
      _timer = Timer(debounce, () {
        if (!conflict) save();
      });
    }
    _notify();
  }

  void _backup() {
    final snapshot = {...values, 'lock_version': lockVersion};
    _storage = _storage
        .then((_) async {
          await writeRecovery(snapshot);
          localBackupReady = true;
        })
        .catchError((Object e) {
          localBackupReady = false;
          error = '本机备份失败，请保持页面打开并复制内容';
          _notify();
        });
  }

  Future<void> save() async {
    _timer?.cancel();
    if (!auto_save) return;
    if (_saving != null) {
      await _saving;
      return;
    }
    if ((!dirty && _request == null) || conflict || _disposed) return;
    final done = Completer<void>();
    _saving = done.future;
    _notify();
    try {
      // TODO 上一次可能已提交但响应丢失；先用原请求确认结果，再处理后来输入。
      _request ??= {
        ...values,
        'revision_id': revisionId,
        'lock_version': lockVersion,
        'request_key': creatorRequestKey(),
      };
      final result = await send(Map.of(_request!));
      lockVersion = int.parse('${result['lock_version']}');
      saved = {'title': _request!['title'], 'content': _request!['content']};
      _request = null;
      error = null;
      if (dirty) {
        _backup();
      } else {
        _storage = _storage.then((_) => clearRecovery());
        await _storage;
      }
    } catch (e) {
      if (e is CreatorWorkspaceException && e.serverRejected) _request = null;
      error = '$e';
      conflict = error!.contains('版本冲突');
      _backup();
    } finally {
      _saving = null;
      done.complete();
      _notify();
      if (dirty && error == null && !_disposed) _timer = Timer(debounce, save);
    }
  }

  // TODO 用户明确看过云端和本机差异后才能采用新的基线；不自动忽略版本冲突。
  void acceptServerVersion(int version, Map<String, dynamic> server) {
    lockVersion = version;
    saved = Map.of(server);
    _request = null;
    conflict = false;
    error = null;
    _backup();
    _notify();
  }

  Future<void> flushLocal() async {
    _backup();
    await _storage;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
