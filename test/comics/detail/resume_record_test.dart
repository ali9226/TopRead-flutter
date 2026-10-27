// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/resume_record.dart';
import 'package:app/services/comics_progress/record.dart';
import 'package:app/services/work_favorite_signals.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/models/user_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const comic = ComicItem(
  id: 42,
  title: 'A comic',
  cover_url: '',
  author_id: 1,
  author_name: 'Creator',
  categories: <Map<String, dynamic>>[],
  chapter_count: 3,
  language_count: 2,
  status: 'published',
);
const language_en = ComicLanguage(
  id: 7,
  language: 'en',
  title: 'A comic',
  description: '',
  cover_url: '',
);
const language_ja = ComicLanguage(
  id: 8,
  language: 'ja',
  title: '漫画',
  description: '',
  cover_url: '',
);
const chapters = <ComicChapter>[
  ComicChapter(
    id: 1,
    title: 'Chapter 1',
    page_count: 8,
    sort_order: 1,
    status: 'published',
    images: <ComicImageData>[],
  ),
  ComicChapter(
    id: 2,
    title: 'Chapter 2',
    page_count: 6,
    sort_order: 2,
    status: 'published',
    images: <ComicImageData>[],
  ),
  ComicChapter(
    id: 3,
    title: 'Hidden',
    page_count: 4,
    sort_order: 3,
    status: 'hidden',
    images: <ComicImageData>[],
  ),
];
ComicDetail fixture({
  Map<String, dynamic> server = const <String, dynamic>{},
  int language_id = 7,
  bool is_collected = false,
}) => ComicDetail(
  comic: comic,
  languages: const <ComicLanguage>[language_en, language_ja],
  selected_language_id: language_id,
  chapters: language_id == 7
      ? chapters
      : const <ComicChapter>[
          ComicChapter(
            id: 10,
            title: '第一話',
            page_count: 4,
            sort_order: 1,
            status: 'published',
            images: <ComicImageData>[],
          ),
        ],
  is_collected: is_collected,
  read_record: server,
);
Map<String, dynamic> record({
  int chapter_id = 2,
  int page = 3,
  String time = '2026-10-15 00:00:00',
  bool pending = false,
}) => <String, dynamic>{
  'comic_id': 42,
  'chapter_id': chapter_id,
  'page_index': page,
  'language': 'en',
  'comic_language_id': 7,
  'update_time': time,
  'pending_sync': pending,
  'server_confirmed': true,
};

void main() {
  tearDown(() => Get.reset());
  test('漫画简介与独立阅读控制器只同步已确认收藏，并保留其他作品及点赞域隔离', () async {
    final signals = WorkFavoriteSignals(), changes = ChangeNotifier();
    final response = Completer<Map<String, dynamic>>();
    var requests = 0;
    ComicDetailLogic create(int id, {bool delayed = false}) => ComicDetailLogic(
      id,
      require_login: () => true,
      progress_changes: changes,
      favorite_signals: signals,
      request: (_, parameters) {
        requests++;
        return delayed
            ? response.future
            : Future.value({'collected': parameters['collected']});
      },
      favorite_changed: () async {},
    );
    final description = create(42),
        reader = create(42, delayed: true),
        other = create(43);
    addTearDown(() {
      description.dispose();
      reader.dispose();
      other.dispose();
      changes.dispose();
      signals.dispose();
    });
    final saving = reader.collect();
    expect(reader.collected, isTrue, reason: '当前页先显示乐观星形');
    expect(reader.collecting, isTrue);
    await reader.collect();
    expect(requests, 1, reason: '在途收藏禁止连点');
    expect(description.collected, isFalse, reason: '请求完成前不广播假成功');
    response.complete({'collected': true});
    await saving;
    expect(reader.collected, isTrue);
    expect(description.collected, isTrue);
    expect(other.collected, isFalse);
    signals.confirm(
      const WorkFavoriteChange(
        domain: WorkFavoriteDomain.novel,
        work_id: 42,
        favorited: false,
        account_identity: '0:0',
      ),
    );
    expect(description.collected, isTrue, reason: '小说同ID不影响漫画收藏');
    signals.confirm(
      const WorkFavoriteChange(
        domain: WorkFavoriteDomain.comic,
        work_id: 42,
        favorited: false,
        account_identity: 'other-account',
      ),
    );
    expect(description.collected, isTrue, reason: '旧账号信号不能影响当前账号');
    await description.collect();
    expect(description.collected, isFalse);
    expect(reader.collected, isFalse, reason: '取消收藏也同步回阅读页');
  });

  for (final initial in [false, true]) {
    test('漫画收藏与取消收藏失败恢复原星形，保留错误提示 initial=$initial', () async {
      final signals = WorkFavoriteSignals(), changes = ChangeNotifier();
      final response = Completer<Map<String, dynamic>>();
      final errors = <String>[];
      var requests = 0, refreshes = 0;
      final logic = ComicDetailLogic(
        42,
        progress_changes: changes,
        favorite_signals: signals,
        require_login: () => true,
        request: (_, _) {
          requests++;
          return response.future;
        },
        favorite_changed: () async {
          refreshes++;
        },
        on_collection_error: errors.add,
      )..collected = initial;
      addTearDown(() {
        logic.dispose();
        changes.dispose();
        signals.dispose();
      });
      final saving = logic.collect();
      expect(logic.collected, !initial);
      expect(logic.collecting, isTrue);
      await logic.collect();
      expect(requests, 1);
      response.completeError(StateError('offline'));
      await saving;
      expect(logic.collected, initial);
      expect(logic.collecting, isFalse);
      expect(errors.single, contains('offline'));
      expect(refreshes, 0);
      expect(signals.latest, isNull);
    });
  }

  for (final detail_first in [false, true]) {
    test('收藏期间发起的旧详情无论先后返回都不覆盖乐观或已确认星形 detail_first=$detail_first', () async {
      final signals = WorkFavoriteSignals(), changes = ChangeNotifier();
      final response = Completer<Map<String, dynamic>>();
      final old_detail = Completer<ComicDetail>();
      final errors = <String>[];
      final logic = ComicDetailLogic(
        42,
        progress_changes: changes,
        favorite_signals: signals,
        require_login: () => true,
        request: (_, _) => response.future,
        fetch_detail: (_, {language}) => old_detail.future,
        read_progress: (_, {user_id}) async => {},
        favorite_changed: () async {},
        on_collection_error: errors.add,
      );
      addTearDown(() {
        logic.dispose();
        changes.dispose();
        signals.dispose();
      });
      final saving = logic.collect();
      final refreshing = logic.load();
      if (detail_first) {
        old_detail.complete(fixture());
        await refreshing;
        expect(logic.collected, isTrue);
        expect(logic.collecting, isTrue);
      }
      response.complete({'collected': true});
      await saving;
      if (!detail_first) {
        old_detail.complete(fixture());
        await refreshing;
      }
      expect(logic.collected, isTrue);
      expect(errors, isEmpty, reason: '成功收藏不触发提示');
    });
  }

  test('本地请求失败不能撤销另一页已确认的相同星形', () async {
    final signals = WorkFavoriteSignals(), changes = ChangeNotifier();
    final response = Completer<Map<String, dynamic>>();
    final errors = <String>[];
    final logic = ComicDetailLogic(
      42,
      progress_changes: changes,
      favorite_signals: signals,
      require_login: () => true,
      request: (_, _) => response.future,
      on_collection_error: errors.add,
    );
    addTearDown(() {
      logic.dispose();
      changes.dispose();
      signals.dispose();
    });
    final saving = logic.collect();
    signals.confirm(
      const WorkFavoriteChange(
        domain: WorkFavoriteDomain.comic,
        work_id: 42,
        favorited: true,
        account_identity: '0:0',
      ),
    );
    response.completeError(StateError('offline'));
    await saving;
    expect(logic.collected, isTrue);
    expect(errors.single, contains('offline'));
  });

  test('跨页面收藏成功后迟到的旧详情不能撤销已同步的星形状态', () async {
    final signals = WorkFavoriteSignals(), changes = ChangeNotifier();
    final old = Completer<ComicDetail>();
    final description = ComicDetailLogic(
      42,
      progress_changes: changes,
      favorite_signals: signals,
      fetch_detail: (_, {language}) => old.future,
      read_progress: (_, {user_id}) async => {},
    );
    final reader = ComicDetailLogic(
      42,
      progress_changes: changes,
      favorite_signals: signals,
      require_login: () => true,
      request: (_, _) async => {'collected': true},
      favorite_changed: () async {},
    );
    addTearDown(() {
      description.dispose();
      reader.dispose();
      changes.dispose();
      signals.dispose();
    });
    final loading = description.load();
    await reader.collect();
    expect(description.collected, isTrue);
    old.complete(fixture());
    await loading;
    expect(description.collected, isTrue);
  });

  test('收藏星形采用服务端确认结果，不能只按用户点击推断成功状态', () async {
    final signals = WorkFavoriteSignals(), changes = ChangeNotifier();
    final logic = ComicDetailLogic(
      42,
      progress_changes: changes,
      favorite_signals: signals,
      require_login: () => true,
      request: (_, _) async => {'collected': false},
      favorite_changed: () async {},
    );
    addTearDown(() {
      logic.dispose();
      changes.dispose();
      signals.dispose();
    });
    await logic.collect();
    expect(logic.collected, isFalse);
    expect(signals.latest!.favorited, isFalse);
  });
  test('UTC服务器记录比已同步本地记录新时使用服务器，页数按现存目录收敛', () {
    final value = resolve_comic_resume(
      fixture(server: record(page: 40, time: '2026-10-15 03:00:00')),
      local_record: record(page: 1, time: '2026-10-15T01:00:00Z'),
    )!;
    expect(value.chapter.id, 2);
    expect(value.page_index, 5);
    expect(
      ComicProgressRecord.utc_time(value.record['update_time']),
      DateTime.utc(2026, 10, 15, 3),
    );
  });
  test('尚未同步的本地阅读优先，不依赖设备时钟快慢', () {
    final value = resolve_comic_resume(
      fixture(server: record(page: 1, time: '2026-10-15T12:00:00Z')),
      local_record: record(
        page: 4,
        time: '2026-10-14T09:00:00Z',
        pending: true,
      ),
    )!;
    expect(value.page_index, 4);
  });
  test('带偏移的日期和数据库DATETIME统一按UTC比较', () {
    final value = resolve_comic_resume(
      fixture(server: record(page: 1, time: '2026-10-15 00:00:00')),
      local_record: record(page: 4, time: '2026-10-15T09:00:00+08:00'),
    )!;
    expect(value.page_index, 4);
  });
  test('旧版缓存设备时钟异常不能覆盖可信服务器进度', () {
    final value = resolve_comic_resume(
      fixture(server: record(page: 2)),
      local_record: <String, dynamic>{
        ...record(page: 4, time: '2099-01-01 00:00:00'),
        'server_confirmed': false,
      },
    )!;
    expect(value.page_index, 2);
  });
  test('无效旧本地记录不掩盖有效服务器记录，隐藏章不进入可读目录', () {
    final value = resolve_comic_resume(
      fixture(server: record(chapter_id: 1, page: 2)),
      local_record: record(chapter_id: 3, pending: true),
    )!;
    expect(value.chapter.id, 1);
    expect(
      comic_readable_chapters(fixture()).map((chapter) => chapter.id),
      <int>[1, 2],
    );
  });
  test('切换语种、账号或作品后不会沿用另一条阅读记录', () {
    expect(
      resolve_comic_resume(fixture(language_id: 8), local_record: record()),
      isNull,
    );
    expect(
      resolve_comic_resume(
        fixture(),
        local_record: <String, dynamic>{...record(), 'user_id': 9},
        user_id: 11,
      ),
      isNull,
    );
    expect(
      resolve_comic_resume(
        fixture(),
        local_record: <String, dynamic>{...record(), 'comic_id': 99},
      ),
      isNull,
    );
    expect(
      resolve_comic_resume(
        fixture(),
        local_record: <String, dynamic>{...record(), 'language': 'ja'},
      ),
      isNull,
    );
  });
  test('旧记录没有语种字段时，只有唯一章节属于当前目录才可恢复', () {
    expect(
      resolve_comic_resume(
        fixture(),
        local_record: <String, dynamic>{'chapter_id': 2, 'page_index': 4},
      )?.page_index,
      4,
    );
    expect(
      resolve_comic_resume(
        fixture(language_id: 8),
        local_record: <String, dynamic>{'chapter_id': 2, 'page_index': 4},
      ),
      isNull,
    );
  });
  test('历史章隐藏时开始第一可读章并明确传零页', () async {
    String? location;
    final changes = ChangeNotifier();
    final logic = ComicDetailLogic(
      42,
      fetch_detail: (_, {language}) async =>
          fixture(server: record(chapter_id: 3, page: 3)),
      read_progress: (_, {user_id}) async =>
          record(chapter_id: 3, pending: true),
      progress_changes: changes,
      navigate: (path) => location = path,
    );
    await logic.load();
    expect(logic.can_continue, false);
    expect(logic.start_chapter_id, 1);
    logic.open_chapter(logic.start_chapter_id, resume: true);
    expect(Uri.parse(location!).queryParameters['page'], '0');
    expect(Uri.parse(location!).queryParameters['resume'], '0');
    logic.dispose();
    changes.dispose();
  });
  test('阅读服务通知后详情立即续读最新章节，关闭详情后注销监听', () async {
    var local = <String, dynamic>{};
    int reads = 0;
    final changes = ChangeNotifier();
    final logic = ComicDetailLogic(
      42,
      fetch_detail: (_, {language}) async => fixture(),
      read_progress: (_, {user_id}) async {
        reads++;
        return local;
      },
      progress_changes: changes,
    );
    await logic.load();
    expect(logic.can_continue, false);
    local = record();
    changes.notifyListeners();
    await Future<void>.delayed(Duration.zero);
    expect(logic.resume_chapter_title, 'Chapter 2');
    expect(logic.read_record['page_index'], 3);
    logic.dispose();
    final previous_reads = reads;
    changes.notifyListeners();
    await Future<void>.delayed(Duration.zero);
    expect(reads, previous_reads);
    changes.dispose();
  });
  test('较晚完成的旧语种请求不会覆盖新的语种目录', () async {
    final english = Completer<ComicDetail>();
    final japanese = Completer<ComicDetail>();
    final changes = ChangeNotifier();
    final logic = ComicDetailLogic(
      42,
      fetch_detail: (_, {language}) =>
          language == 'ja' ? japanese.future : english.future,
      read_progress: (_, {user_id}) async => <String, dynamic>{},
      progress_changes: changes,
    );
    final first = logic.load(language: 'en');
    final second = logic.load(language: 'ja');
    japanese.complete(fixture(language_id: 8));
    await second;
    english.complete(fixture());
    await first;
    expect(logic.detail!.selected_language_id, 8);
    logic.dispose();
    changes.dispose();
  });
  test('收藏写成功后一次刷新统一书架，服务端幂等目标由按钮状态确定', () async {
    int refreshed = 0;
    Map<String, dynamic>? sent;
    final changes = ChangeNotifier();
    final logic = ComicDetailLogic(
      42,
      require_login: () => true,
      progress_changes: changes,
      request: (action, parameter) async {
        sent = parameter;
        return <String, dynamic>{};
      },
      favorite_changed: () async {
        refreshed++;
      },
    );
    await logic.collect();
    expect(logic.collected, true);
    expect(sent, <String, dynamic>{'comic_id': 42, 'collected': true});
    expect(refreshed, 1);
    logic.dispose();
    changes.dispose();
  });
  test('详情背景刷新旧快照不会撤销刚成功的收藏状态', () async {
    final response = Completer<ComicDetail>();
    final changes = ChangeNotifier();
    final logic = ComicDetailLogic(
      42,
      require_login: () => true,
      progress_changes: changes,
      fetch_detail: (_, {language}) => response.future,
      read_progress: (_, {user_id}) async => <String, dynamic>{},
      request: (_, parameter) async => <String, dynamic>{},
      favorite_changed: () async {},
    );
    final loading = logic.load();
    await logic.collect();
    expect(logic.collected, true);
    response.complete(fixture());
    await loading;
    expect(logic.collected, true);
    logic.dispose();
    changes.dispose();
  });
  test('旧账号收藏完成不会更新新账号按钮或触发新账号书架刷新', () async {
    final user = Get.put(UserInformation());
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': 1}));
    final pending = Completer<Map<String, dynamic>>();
    final changes = ChangeNotifier();
    int refreshes = 0;
    final logic = ComicDetailLogic(
      42,
      require_login: () => true,
      progress_changes: changes,
      fetch_detail: (_, {language}) async => fixture(),
      read_progress: (_, {user_id}) async => <String, dynamic>{},
      request: (_, parameter) => pending.future,
      favorite_changed: () async {
        refreshes++;
      },
    );
    await logic.load();
    final collect = logic.collect();
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': 2}));
    pending.complete(<String, dynamic>{});
    await collect;
    expect(logic.collected, false);
    expect(refreshes, 0);
    logic.dispose();
    changes.dispose();
  });
  test('旧账号收藏在途时，新账号详情仍能显示自己的真实收藏状态', () async {
    final user = Get.put(UserInformation());
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': 1}));
    final pending = Completer<Map<String, dynamic>>();
    final changes = ChangeNotifier();
    final logic = ComicDetailLogic(
      42,
      require_login: () => true,
      progress_changes: changes,
      fetch_detail: (_, {language}) async =>
          fixture(is_collected: user.userInfo.value?.id == 2),
      read_progress: (_, {user_id}) async => {},
      request: (_, _) => pending.future,
    );
    addTearDown(() {
      logic.dispose();
      changes.dispose();
    });
    await logic.load();
    final saving = logic.collect();
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': 2}));
    await Future<void>.delayed(Duration.zero);
    expect(logic.collecting, isTrue);
    expect(logic.collected, isTrue, reason: '不能把旧账号的在途状态当作新账号刷新屏障');
    pending.complete({'collected': false});
    await saving;
    expect(logic.collected, isTrue);
  });

  test('在途响应不读取或展示后来登录账号的本地进度', () async {
    final user = Get.put(UserInformation());
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': 1}));
    final response = Completer<ComicDetail>();
    final changes = ChangeNotifier();
    final requested_owners = <int?>[];
    final logic = ComicDetailLogic(
      42,
      progress_changes: changes,
      fetch_detail: (_, {language}) => response.future,
      read_progress: (_, {user_id}) async {
        requested_owners.add(user_id);
        return record();
      },
    );
    final load = logic.load();
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': 2}));
    response.complete(fixture());
    await load;
    await Future<void>.delayed(Duration.zero);
    expect(requested_owners.where((id) => id == 1), isEmpty);
    logic.dispose();
    changes.dispose();
  });
}
