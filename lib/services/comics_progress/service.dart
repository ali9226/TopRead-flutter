// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:app/api/comics.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/comics.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/services/comics_progress/record.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// TODO 保存队列属于服务而不是页面，页面退出后仍可靠落盘；账号和作品同时隔离。
class ComicsProgressService extends ChangeNotifier {
  static final ComicsProgressService instance = ComicsProgressService();
  final Future<String?> Function(String) read_storage;
  final Future<void> Function(String, String) write_storage;
  final Future<Map<String, dynamic>> Function(ComicProgressRecord, int)?
  send_remote;
  final int Function() account_id;
  final int Function() session_revision;
  final Future<String> Function() read_token;
  final Map<String, ComicProgressRecord> _memory =
      <String, ComicProgressRecord>{};
  final Map<String, Future<void>> _queues = <String, Future<void>>{};
  final Map<String, ComicProgressRecord> _pending =
      <String, ComicProgressRecord>{};
  final Map<String, ComicProgressRecord> _pending_local =
      <String, ComicProgressRecord>{};
  final Map<String, int> _record_revisions = <String, int>{};
  final Map<String, int> _epochs = <String, int>{};
  final Set<String> _cleared = <String>{};

  /// TODO 注入仅用于边界测试；生产实例始终复用统一存储、鉴权和书架刷新入口。
  ComicsProgressService({
    Future<String?> Function(String)? read_storage,
    Future<void> Function(String, String)? write_storage,
    this.send_remote,
    int Function()? account_id,
    int Function()? session_revision,
    Future<String> Function()? read_token,
  }) : read_storage = read_storage ?? StorageUtil.getData,
       write_storage =
           write_storage ??
           ((key, value) async {
             await StorageUtil.saveData(key, value);
           }),
       account_id = account_id ?? current_account_id,
       session_revision = session_revision ?? current_session_revision,
       read_token = read_token ?? current_token;

  static int current_session_revision() => Get.isRegistered<UserInformation>()
      ? Get.find<UserInformation>().auth_revision
      : 0;
  static Future<String> current_token() async => current_account_id() > 0
      ? await StorageUtil.getData(Constant.tokenKey) ?? ''
      : '';

  static int current_account_id() {
    if (!Get.isRegistered<UserInformation>()) return 0;
    final user = Get.find<UserInformation>();
    return user.isLoggedIn.value ? user.userInfo.value?.id ?? 0 : 0;
  }

  static String storage_key(int comic_id, int user_id) =>
      'comics_progress_${user_id}_$comic_id';

  static Future<Map<String, dynamic>> _send(
    ComicProgressRecord record,
    int user_id,
    int revision,
    String token,
  ) async {
    if (user_id <= 0 ||
        current_account_id() != user_id ||
        current_session_revision() != revision ||
        token.isEmpty) {
      throw StateError('阅读账号已切换');
    }
    final confirmed =
        await comics_session_request('save_progress', <String, dynamic>{
          'comic_id': record.comic_id,
          'chapter_id': record.chapter_id,
          'page_index': record.page_index,
        }, authorization_token: token);
    if (current_account_id() == user_id &&
        current_session_revision() == revision) {
      unawaited(BookshelfSyncService.history_changed(auth_revision: revision));
    }
    return confirmed;
  }

  Future<Map<String, dynamic>> read_record(int comic_id, {int? user_id}) async {
    final key = storage_key(comic_id, user_id ?? account_id());
    if (_cleared.contains(key)) return <String, dynamic>{};
    final existing = _memory[key];
    if (existing != null) return existing.to_json();
    try {
      final encoded = await read_storage(key);
      if (_cleared.contains(key)) return <String, dynamic>{};
      // TODO 慢读取不能覆盖正在阅读产生的新记录。
      if (_memory[key] != null) return _memory[key]!.to_json();
      if (encoded == null) return <String, dynamic>{};
      final record = ComicProgressRecord.from_json(
        comics_map(jsonDecode(encoded)),
      );
      if (record.comic_id != comic_id || record.chapter_id <= 0) {
        return <String, dynamic>{};
      }
      _memory[key] = record;
      return record.to_json();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// TODO 立即通知续读按钮，再串行写本地与服务器；后发记录永远不会被早发请求覆盖。
  Future<void> save(
    ComicProgressRecord record, {
    int? user_id,
    int? auth_revision,
    String? authorization_token,
  }) {
    final owner = user_id ?? account_id();
    final revision = auth_revision ?? session_revision();
    final key = storage_key(record.comic_id, owner);
    final epoch = _epochs[key] ?? 0;
    // TODO 同账号退出再登录后，旧页面不能覆盖新会话已经产生的本地记录。
    if ((_record_revisions[key] ?? revision) > revision) {
      return Future<void>.value();
    }
    _record_revisions[key] = revision;
    _cleared.remove(key);
    final token = authorization_token != null
        ? Future<String>.value(authorization_token)
        : owner == account_id() && revision == session_revision()
        ? read_token()
        : Future<String>.value('');
    final snapshot = ComicProgressRecord.from_json(<String, dynamic>{
      ...record.to_json(),
      'pending_sync': owner > 0,
    });
    _memory[key] = snapshot;
    _pending_local[key] = snapshot;
    if (owner > 0) _pending[key] = snapshot;
    notifyListeners();
    final previous = _queues[key] ?? Future<void>.value();
    final next = previous.then((_) async {
      if ((_epochs[key] ?? 0) != epoch) return;
      try {
        await write_storage(key, jsonEncode(snapshot.to_json()));
        if ((_epochs[key] ?? 0) != epoch) return;
        if (identical(_pending_local[key], snapshot)) {
          _pending_local.remove(key);
        }
      } catch (_) {
        // TODO 内存保留最新记录，下次flush继续重试，不让存储插件错误中断整个队列。
        return;
      }
      if (owner <= 0 ||
          account_id() != owner ||
          session_revision() != revision ||
          !identical(_pending[key], snapshot)) {
        return;
      }
      try {
        final credential = await token;
        if (account_id() != owner ||
            session_revision() != revision ||
            (_epochs[key] ?? 0) != epoch) {
          return;
        }
        final confirmation = send_remote != null
            ? await send_remote!(snapshot, owner)
            : await _send(snapshot, owner, revision, credential);
        if ((_epochs[key] ?? 0) != epoch ||
            account_id() != owner ||
            session_revision() != revision ||
            (confirmation['user_id'] != null &&
                comics_int(confirmation['user_id']) != owner)) {
          return;
        }
        if (!identical(_pending[key], snapshot) ||
            !identical(_memory[key], snapshot)) {
          return;
        }
        final server_time = ComicProgressRecord.utc_time(
          confirmation['update_time'] ?? confirmation['updated_at'],
        );
        if (server_time == null) return;
        final confirmed = ComicProgressRecord.from_json(<String, dynamic>{
          ...snapshot.to_json(),
          ...confirmation,
          'updated_at': server_time.toIso8601String(),
          'pending_sync': false,
          'server_confirmed': true,
        });
        _pending.remove(key);
        _memory[key] = confirmed;
        _pending_local[key] = confirmed;
        await write_storage(key, jsonEncode(confirmed.to_json()));
        if (identical(_pending_local[key], confirmed)) {
          _pending_local.remove(key);
        }
        notifyListeners();
      } catch (_) {
        /* TODO 失败保留dirty记录，退出/后台/下一次保存时重试。 */
      }
    });
    _queues[key] = next;
    return next;
  }

  Future<void> flush({int? user_id, int? comic_id}) async {
    final owner = user_id ?? account_id();
    final keys = comic_id == null
        ? _queues.keys
              .where((key) => key.startsWith('comics_progress_${owner}_'))
              .toList()
        : <String>[storage_key(comic_id, owner)];
    for (final key in keys) {
      await (_queues[key] ?? Future<void>.value());
      final pending = _pending_local[key] ?? _pending[key];
      if (pending != null &&
          account_id() == owner &&
          (_record_revisions[key] ?? session_revision()) ==
              session_revision()) {
        await save(
          pending,
          user_id: owner,
          auth_revision: _record_revisions[key],
        );
      }
    }
  }

  /// TODO 删除历史立刻作废该作品全部旧保存任务；旧网络确认不能让详情出现幽灵续读。
  Future<void> clear_record(int comic_id, {int? user_id}) {
    final key = storage_key(comic_id, user_id ?? account_id());
    final epoch = (_epochs[key] ?? 0) + 1;
    _epochs[key] = epoch;
    _cleared.add(key);
    _memory.remove(key);
    _pending.remove(key);
    _pending_local.remove(key);
    _record_revisions.remove(key);
    notifyListeners();
    final previous = _queues[key] ?? Future<void>.value();
    final clearing = previous.then((_) async {
      // TODO 排在旧落盘之后清空；删除后真正产生的新阅读保存会排在此操作之后。
      if ((_epochs[key] ?? 0) == epoch) await write_storage(key, '{}');
    });
    _queues[key] = clearing;
    return clearing;
  }

  /// TODO 删除请求前取消旧排队保存并等待在途写入完成；删除失败时保留用户原来的续读位置。
  Future<void> prepare_history_removal(int comic_id, {int? user_id}) async {
    final key = storage_key(comic_id, user_id ?? account_id());
    _epochs[key] = (_epochs[key] ?? 0) + 1;
    _pending.remove(key);
    _pending_local.remove(key);
    await (_queues[key] ?? Future<void>.value());
  }
}
