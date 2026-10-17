// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'package:app/services/comics_progress/record.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:flutter_test/flutter_test.dart';

ComicProgressRecord record(int chapter, int page) => ComicProgressRecord(
  comic_id: 7,
  chapter_id: chapter,
  chapter_title: 'Chapter $chapter',
  page_index: page,
  language: 'en',
  comic_language_id: 8,
  updated_at: DateTime.utc(2099),
  page_fraction: .4,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('数据库无时区时间是UTC，设备时区不改变排序', () {
    expect(
      ComicProgressRecord.utc_time('2026-10-15 02:00:00.123'),
      DateTime.utc(2026, 10, 15, 2, 0, 0, 123),
    );
    expect(
      ComicProgressRecord.utc_time('2026-10-15T10:00:00.123+08:00'),
      DateTime.utc(2026, 10, 15, 2, 0, 0, 123),
    );
    expect(ComicProgressRecord.utc_time('bad'), isNull);
  });
  test('服务器失败保留dirty，flush重试并采用服务器时钟', () async {
    final storage = <String, String>{};
    var calls = 0;
    final service = ComicsProgressService(
      account_id: () => 1,
      read_storage: (key) async => storage[key],
      write_storage: (key, value) async {
        storage[key] = value;
      },
      send_remote: (value, owner) async {
        if (++calls == 1) throw StateError('offline');
        return <String, dynamic>{'update_time': '2026-10-15T02:00:00.123Z'};
      },
    );
    await service.save(record(10, 0));
    expect((await service.read_record(7))['pending_sync'], true);
    await service.flush(comic_id: 7);
    final confirmed = ComicProgressRecord.from_json(
      await service.read_record(7),
    );
    expect(confirmed.pending_sync, false);
    expect(confirmed.updated_at, DateTime.utc(2026, 10, 15, 2, 0, 0, 123));
    expect(confirmed.chapter_title, 'Chapter 10');
    expect(calls, 2);
    service.dispose();
  });
  test('旧章慢请求不会覆盖新章或新页，服务器按队列写入', () async {
    final storage = <String, String>{};
    final first = Completer<Map<String, dynamic>>();
    final entered = Completer<void>();
    final sent = <int>[];
    final service = ComicsProgressService(
      account_id: () => 1,
      read_storage: (key) async => storage[key],
      write_storage: (key, value) async {
        storage[key] = value;
      },
      send_remote: (value, owner) async {
        sent.add(value.chapter_id);
        if (sent.length == 1) {
          entered.complete();
          return first.future;
        }
        return <String, dynamic>{'update_time': '2026-10-15T02:00:02Z'};
      },
    );
    final old = service.save(record(10, 9));
    await entered.future;
    final next = service.save(record(20, 0));
    first.complete(<String, dynamic>{'update_time': '2026-10-15T02:00:01Z'});
    await Future.wait(<Future<void>>[old, next]);
    final latest = await service.read_record(7);
    expect(sent, <int>[10, 20]);
    expect(latest['chapter_id'], 20);
    expect(latest['page_index'], 0);
    expect(latest['pending_sync'], false);
    expect(
      jsonDecode(
        storage[ComicsProgressService.storage_key(7, 1)]!,
      )['chapter_id'],
      20,
    );
    service.dispose();
  });
  test('账号切换不把旧阅读写进新账号，访客存储也独立', () async {
    final storage = <String, String>{};
    var owner = 1;
    final block = Completer<void>();
    final sent = <int>[];
    final service = ComicsProgressService(
      account_id: () => owner,
      read_storage: (key) async => storage[key],
      write_storage: (key, value) async {
        if (key.endsWith('1_7')) await block.future;
        storage[key] = value;
      },
      send_remote: (value, user) async {
        sent.add(user);
        return <String, dynamic>{'update_time': '2026-10-15T02:00:00Z'};
      },
    );
    final old = service.save(record(10, 5));
    owner = 2;
    await service.save(record(20, 0));
    block.complete();
    await old;
    expect((await service.read_record(7, user_id: 1))['chapter_id'], 10);
    expect((await service.read_record(7))['chapter_id'], 20);
    expect(sent, <int>[2]);
    owner = 0;
    await service.save(record(30, 0));
    expect((await service.read_record(7))['chapter_id'], 30);
    expect(sent, <int>[2]);
    service.dispose();
  });
  test('访客本地写失败退出flush仍重试', () async {
    var writes = 0;
    final storage = <String, String>{};
    final service = ComicsProgressService(
      account_id: () => 0,
      read_storage: (key) async => storage[key],
      write_storage: (key, value) async {
        if (++writes == 1) throw StateError('disk busy');
        storage[key] = value;
      },
      send_remote: (_, _) async => throw StateError('guest cannot send'),
    );
    await service.save(record(10, 0));
    await service.flush(comic_id: 7);
    expect(writes, 2);
    expect(storage.length, 1);
    service.dispose();
  });
  test('删除历史作废旧网络确认和排队保存，不会出现幽灵续读', () async {
    final storage = <String, String>{};
    final old = Completer<Map<String, dynamic>>();
    final entered = Completer<void>();
    var requests = 0;
    final service = ComicsProgressService(
      account_id: () => 1,
      read_storage: (key) async => storage[key],
      write_storage: (key, value) async {
        storage[key] = value;
      },
      send_remote: (_, _) async {
        requests++;
        if (requests == 1) {
          entered.complete();
          return old.future;
        }
        return <String, dynamic>{'update_time': '2026-10-15T02:00:02Z'};
      },
    );
    final saving = service.save(record(10, 9));
    await entered.future;
    final queued = service.save(record(20, 0));
    final clearing = service.clear_record(7, user_id: 1);
    expect(await service.read_record(7), isEmpty);
    old.complete(<String, dynamic>{'update_time': '2026-10-15T02:00:01Z'});
    await Future.wait(<Future<void>>[saving, queued, clearing]);
    await service.flush(comic_id: 7);
    expect(requests, 1);
    expect(await service.read_record(7), isEmpty);
    expect(storage[ComicsProgressService.storage_key(7, 1)], '{}');
    await service.save(record(30, 0));
    expect((await service.read_record(7))['chapter_id'], 30);
    expect(requests, 2);
    service.dispose();
  });
  test('删除前排空旧保存但保留位置，服务器删除失败仍能续读', () async {
    final storage = <String, String>{};
    final old = Completer<Map<String, dynamic>>();
    final entered = Completer<void>();
    final service = ComicsProgressService(
      account_id: () => 1,
      read_storage: (key) async => storage[key],
      write_storage: (key, value) async {
        storage[key] = value;
      },
      send_remote: (_, _) async {
        entered.complete();
        return old.future;
      },
    );
    final saving = service.save(record(10, 9));
    await entered.future;
    final preparing = service.prepare_history_removal(7, user_id: 1);
    old.complete(<String, dynamic>{'update_time': '2026-10-15T02:00:01Z'});
    await saving;
    await preparing;
    expect((await service.read_record(7))['chapter_id'], 10);
    expect((await service.read_record(7))['page_index'], 9);
    expect(
      jsonDecode(
        storage[ComicsProgressService.storage_key(7, 1)]!,
      )['chapter_id'],
      10,
    );
    service.dispose();
  });
  test('A到B再到A的旧会话不能同步或覆盖新会话记录', () async {
    var revision = 1;
    final block = Completer<void>();
    var requests = 0;
    final service = ComicsProgressService(
      account_id: () => 1,
      session_revision: () => revision,
      read_storage: (_) async => null,
      write_storage: (_, _) async {
        if (revision == 1) await block.future;
      },
      send_remote: (_, _) async {
        requests++;
        return <String, dynamic>{'update_time': '2026-10-15T02:00:00Z'};
      },
    );
    final old = service.save(record(10, 0), auth_revision: 1);
    await Future<void>.delayed(Duration.zero);
    revision = 3;
    final current = service.save(record(20, 0), auth_revision: 3);
    block.complete();
    await old;
    await current;
    await service.save(record(10, 0), auth_revision: 1);
    expect(requests, 1);
    expect((await service.read_record(7))['chapter_id'], 20);
    service.dispose();
  });
}
