// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:app/util/storage_util/index.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import '../game/engine.dart';
import '../game/config.dart';

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
  const TileQuestLoadedSave({
    this.engine,
    this.recovered = false,
    this.previous_seed,
    this.unlocked_level = 1,
    this.sound_enabled = true,
  });

  final TileQuestEngine? engine;
  final bool recovered;

  /// 旧图案表的棋盘不能合并为十五类；安全保留进度、声音与防重复种子。
  final int? previous_seed;
  final int unlocked_level;
  final bool sound_enabled;
}

/// 版本化存档及有序写队列。
///
/// [save] 立即捕获不可变快照；全量 JSON 转换与编码在工作 isolate 执行。
/// 尚未开始的写入合并为最新快照，避免快速点击制造无界磁盘/编码积压。
/// 默认单例跨页面复用，因此旧页面退出与新页面读取也遵循同一顺序。
class TileQuestSaveService {
  TileQuestSaveService({
    required TileQuestSaveStore store,
    FutureOr<String> Function(TileQuestEngineSnapshot snapshot)?
    encode_snapshot,
  }) : _store = store,
       _encode_snapshot = encode_snapshot ?? _encode_background;

  static final TileQuestSaveService shared = TileQuestSaveService(
    store: TileQuestLocalStore(),
  );

  static const int save_version = 1;
  static const int max_save_bytes = 8 * 1024 * 1024;

  final TileQuestSaveStore _store;
  final FutureOr<String> Function(TileQuestEngineSnapshot snapshot)
  _encode_snapshot;
  Future<void> _tail = Future<void>.value();
  _PendingSave? _pending;
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
      try {
        final engine = TileQuestEngine.restore(
          Map<String, dynamic>.from(engine_json),
        );
        return TileQuestLoadedSave(
          engine: engine,
          previous_seed: engine.state.seed,
          unlocked_level: engine.state.unlocked_level,
          sound_enabled: engine.state.sound_enabled,
        );
      } on FormatException {
        // 棋盘仍必须通过完整校验；仅独立读取有严格类型/范围的无害偏好。
        // 素材升级或坏档不能把未知牌型静默映射成可三消的相同图案。
        final state_json = engine_json['state'];
        if (state_json is! Map ||
            (engine_json['version'] != 1 &&
                engine_json['version'] != TileQuestConfig.save_version)) {
          rethrow;
        }
        final seed = state_json['seed'];
        final unlocked = state_json['unlocked_level'];
        final sound = state_json['sound_enabled'];
        return TileQuestLoadedSave(
          recovered: true,
          previous_seed:
              seed is int && seed >= 0 && seed <= TileQuestConfig.max_seed
              ? seed
              : null,
          unlocked_level: unlocked is int && unlocked >= 1 && unlocked <= 2
              ? unlocked
              : 1,
          sound_enabled: sound is bool ? sound : true,
        );
      }
    } on Object {
      // 不信任本地 JSON；错误类型或被截断的数据都进入可玩新局。
      return const TileQuestLoadedSave(recovered: true);
    }
  }

  /// 捕获状态引用是常量工作量；后续点击不会改变已捕获的状态。
  /// 同一等待批次的请求均在最新快照落盘后完成，错误也一并传播。
  Future<void> save(TileQuestEngine engine) {
    final snapshot = engine.capture_snapshot();
    final completion = Completer<void>();
    final waiting = _pending;
    if (waiting != null) {
      waiting.snapshot = snapshot;
      waiting.completions.add(completion);
      return completion.future;
    }
    final pending = _PendingSave(snapshot, completion);
    _pending = pending;
    final operation = _tail.then((_) async {
      // 开始编码后不再替换该快照；后续请求进入下一个有序批次。
      _pending = null;
      final captured = await _encode_snapshot(pending.snapshot);
      await _store.write(captured);
    });
    _tail = operation.then<void>(
      (_) {
        has_write_error = false;
        for (final completion in pending.completions) {
          completion.complete();
        }
      },
      onError: (Object error, StackTrace stack) {
        has_write_error = true;
        for (final completion in pending.completions) {
          completion.completeError(error, stack);
        }
      },
    );
    return completion.future;
  }

  /// 让返回页面等场景能够等待当前队列落盘。
  Future<void> flush() => _tail;
}

/// 编码入口只接收不可变规则数据，不捕获磁盘适配器、控制器或平台对象。
String encode_tile_quest_snapshot(TileQuestEngineSnapshot snapshot) =>
    jsonEncode(<String, dynamic>{
      'version': TileQuestSaveService.save_version,
      'engine': snapshot.export_json(),
    });

/// 移动端的默认编码边界；组件测试可注入同步纯编码，使用虚拟时钟。
Future<String> _encode_background(TileQuestEngineSnapshot snapshot) =>
    compute(encode_tile_quest_snapshot, snapshot);

class _PendingSave {
  _PendingSave(this.snapshot, Completer<void> completion)
    : completions = [completion];

  TileQuestEngineSnapshot snapshot;
  final List<Completer<void>> completions;
}
