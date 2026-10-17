// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:app/util/storage_util/index.dart';
import 'package:get_storage/get_storage.dart';

import '../game/engine.dart';

/// 可注入的本地存储边界；游戏不依赖用户登录或远端服务。
abstract interface class TileQuestSaveStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// 沿用项目现有 StorageUtil，不创建独立数据库或第三方存储。
class TileQuestLocalStore implements TileQuestSaveStore {
  static const String storage_key = 'tile_quest_save_v1';

  @override
  Future<String?> read() async {
    try {
      return await StorageUtil.getData(storage_key);
    } on TypeError {
      // 旧值被其他版本写成非字符串时，交给上层作为坏档安全恢复。
      return '';
    }
  }

  @override
  Future<void> write(String value) {
    final Completer<void> completion = Completer<void>();
    // GetStorage 2.1.1 的 write() 只等待微任务安排，未等待物理写入；
    // 队列栅栏确保该次 flush 完成后才报告成功。局部 Zone 捕获其
    // 内部未向 write() 传播的磁盘错误，转换成可重试的保存失败。
    runZonedGuarded(
      () {
        unawaited(() async {
          await StorageUtil.saveData(storage_key, value);
          await GetStorage().queue.add<void>(() {});
          // 让内部 flush Future 的未处理错误先到达此 Zone。
          await Future<void>.delayed(Duration.zero);
          if (!completion.isCompleted) completion.complete();
        }());
      },
      (Object error, StackTrace stack) {
        if (!completion.isCompleted) completion.completeError(error, stack);
      },
    );
    return completion.future;
  }
}

/// 读取结果将坏档恢复与正常首次启动区分开，供界面轻量提示。
class TileQuestLoadedSave {
  const TileQuestLoadedSave({this.engine, this.recovered = false});

  final TileQuestEngine? engine;
  final bool recovered;
}

/// 版本化存档及有序写队列。
///
/// [save] 在调用时立即序列化快照；排队任务不会读取之后改变的引擎。
/// 默认单例跨页面复用，因此旧页面退出与新页面读取也遵循同一顺序。
class TileQuestSaveService {
  TileQuestSaveService({required TileQuestSaveStore store}) : _store = store;

  static final TileQuestSaveService shared = TileQuestSaveService(
    store: TileQuestLocalStore(),
  );

  static const int save_version = 1;
  static const int max_save_bytes = 8 * 1024 * 1024;

  final TileQuestSaveStore _store;
  Future<void> _tail = Future<void>.value();
  bool has_write_error = false;
  Object? _session_owner;
  void Function()? _revoke_session;

  /// 页面会话单写者租约。接管前同步通知旧页提交最终快照并停止计时，
  /// 因而新页随后的 load 会等待旧快照，旧页迟到的 dispose 不会写回。
  Object acquire_session({required void Function() on_revoke}) {
    _revoke_session?.call();
    final Object owner = Object();
    _session_owner = owner;
    _revoke_session = on_revoke;
    return owner;
  }

  bool owns_session(Object? owner) =>
      owner != null && identical(_session_owner, owner);

  /// 只释放匹配的租约，旧页面销毁不能释放后来页面的所有权。
  void release_session(Object? owner) {
    if (!owns_session(owner)) return;
    _session_owner = null;
    _revoke_session = null;
  }

  /// 等待先前页面所有写入，再读取最新已提交的存档。
  Future<TileQuestLoadedSave> load() async {
    await _tail;
    final String? raw = await _store.read();
    if (raw == null) return const TileQuestLoadedSave();
    try {
      if (raw.length > max_save_bytes) {
        throw const FormatException('Save exceeds the size limit.');
      }
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['version'] is! int ||
          decoded['version'] != save_version) {
        throw const FormatException('Unsupported Tile Quest save version.');
      }
      final dynamic engine_json = decoded['engine'];
      if (engine_json is! Map) {
        throw const FormatException('Missing game state.');
      }
      return TileQuestLoadedSave(
        engine: TileQuestEngine.restore(Map<String, dynamic>.from(engine_json)),
      );
    } on Object {
      // 不信任本地 JSON；错误类型或被截断的数据都进入可玩新局。
      return const TileQuestLoadedSave(recovered: true);
    }
  }

  /// 每次保存独立捕获；失败仅影响该请求，不会毒化后续队列。
  Future<void> save(TileQuestEngine engine) {
    final String captured = jsonEncode(<String, dynamic>{
      'version': save_version,
      'engine': engine.export_json(),
    });
    final Future<void> operation = _tail.then((_) => _store.write(captured));
    _tail = operation.then<void>(
      (_) {
        has_write_error = false;
      },
      onError: (Object _, StackTrace _) {
        has_write_error = true;
      },
    );
    return operation;
  }

  /// 让返回页面等场景能够等待当前队列落盘。
  Future<void> flush() => _tail;
}
