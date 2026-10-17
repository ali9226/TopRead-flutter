// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/resume_record.dart';
import 'package:app/services/comics_progress/record.dart';
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
  is_collected: false,
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
