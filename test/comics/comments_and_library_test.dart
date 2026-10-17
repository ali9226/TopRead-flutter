// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/api/bookshelf.dart';
import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/services/comics_library_removal.dart';
import 'package:app/stores/bookshelf_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Map<String, dynamic> _comment(int id, {int? parent_id, int replies = 0}) =>
    <String, dynamic>{
      'id': '$id',
      'user_id': '7',
      'nickname': 'Reader',
      'comment_content': 'Comment $id',
      'reply_count': replies,
      'parent_id': parent_id,
      'is_liked': '0',
      'like_count': '0',
    };

UserInformation _login(int id) {
  final user = Get.isRegistered<UserInformation>()
      ? Get.find<UserInformation>()
      : Get.put(UserInformation(token_writer: (_, _) async => true));
  user.saveUserInfo(
    UserInfo.fromJson(<String, dynamic>{'id': id, 'name': 'Reader $id'}),
  );
  return user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
  });
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  test('漫画主评论独立范围分页，重复条目不重复渲染', () async {
    final requests = <Map<String, dynamic>>[];
    final logic = ComicCommentsLogic(
      comic_id: 15,
      chapter_id: 91,
      requester: (action, params, {authorization_token}) async {
        requests.add(params);
        final page = params['page'] as int;
        return <String, dynamic>{
          'total': 25,
          'list': page == 1
              ? List.generate(20, (index) => _comment(index + 1))
              : <Map<String, dynamic>>[
                  _comment(20),
                  ...List.generate(5, (index) => _comment(index + 21)),
                ],
        };
      },
    );
    addTearDown(logic.dispose);
    await logic.load();
    await logic.load(more: true);
    expect(logic.items, hasLength(25));
    expect(logic.has_more, isFalse);
    expect(requests.map((item) => item['page']), <int>[1, 2]);
    expect(
      requests.every(
        (item) =>
            item['comic_id'] == 15 &&
            item['chapter_id'] == 91 &&
            !item.containsKey('novel_id'),
      ),
      isTrue,
    );
  });

  test('根线程回复单独分页，嵌套回复提交真实父评论', () async {
    _login(7);
    final mutations = <Map<String, dynamic>>[];
    final logic = ComicCommentsLogic(
      comic_id: 15,
      chapter_id: 91,
      token_reader: () async => 'account-a',
      require_login: () => true,
      requester: (action, params, {authorization_token}) async {
        expect(authorization_token, 'account-a');
        if (action == 'add') {
          mutations.add(params);
          return <String, dynamic>{'id': 150};
        }
        if (params['parent_id'] != null) {
          expect(params['parent_id'], 1);
          return <String, dynamic>{
            'total': 25,
            'list': params['page'] == 1
                ? List.generate(
                    20,
                    (index) =>
                        _comment(101 + index, parent_id: index == 0 ? 1 : 101),
                  )
                : List.generate(
                    5,
                    (index) => _comment(121 + index, parent_id: 101),
                  ),
          };
        }
        return <String, dynamic>{
          'total': 1,
          'list': <Map<String, dynamic>>[_comment(1, replies: 26)],
        };
      },
    );
    addTearDown(logic.dispose);
    await logic.load();
    await logic.replies(1);
    await logic.replies(1, more: true);
    expect(logic.threads[1]!.items, hasLength(25));
    logic.reply_to(logic.threads[1]!.items[1], 1);
    expect(await logic.send('A reply to a reply'), isTrue);
    expect(mutations.single['parent_id'], 102);
    expect(mutations.single['comic_id'], 15);
    expect(mutations.single['chapter_id'], 91);
    expect(logic.threads[1]!.items.last.id, 150);
  });

  test('发送失败与超长内容保留回复目标，不产生假成功', () async {
    _login(7);
    final failures = <String>[];
    var writes = 0;
    final logic = ComicCommentsLogic(
      comic_id: 1,
      token_reader: () async => 'token',
      require_login: () => true,
      feedback: failures.add,
      requester: (action, params, {authorization_token}) async {
        writes++;
        throw StateError('network unavailable');
      },
    );
    addTearDown(logic.dispose);
    final target = CommentData.from_json(_comment(1));
    logic.reply_to(target, 1);
    expect(await logic.send('x' * 1001), isFalse);
    expect(writes, 0);
    expect(await logic.send('Please keep this draft'), isFalse);
    expect(logic.replying?.id, 1);
    expect(logic.sending, isFalse);
    expect(failures, hasLength(2));
  });

  test('匿名可读评论，但写入与点赞不会发出请求', () async {
    final actions = <String>[];
    final logic = ComicCommentsLogic(
      comic_id: 1,
      require_login: () => false,
      requester: (action, params, {authorization_token}) async {
        actions.add(action);
        expect(authorization_token, '');
        return <String, dynamic>{
          'list': <Map<String, dynamic>>[_comment(1)],
          'total': 1,
        };
      },
    );
    addTearDown(logic.dispose);
    await logic.load();
    expect(await logic.send('Anonymous message'), isFalse);
    await logic.like(logic.items.first);
    logic.reply_to(logic.items.first, 1);
    expect(actions, <String>['inquire']);
    expect(logic.replying, isNull);
  });

  test('点赞快速重复点击只请求一次，按服务端结果更新', () async {
    _login(7);
    final pending = Completer<Map<String, dynamic>>();
    var requests = 0;
    final logic = ComicCommentsLogic(
      comic_id: 1,
      token_reader: () async => 'token',
      require_login: () => true,
      requester: (action, params, {authorization_token}) {
        requests++;
        return pending.future;
      },
    );
    addTearDown(logic.dispose);
    final item = CommentData.from_json(_comment(1));
    logic.items.add(item);
    final first = logic.like(item);
    final duplicate = logic.like(item);
    await Future<void>.delayed(Duration.zero);
    expect(requests, 1);
    pending.complete(<String, dynamic>{'liked': true, 'like_count': '12'});
    await Future.wait(<Future<void>>[first, duplicate]);
    expect(logic.items.single.is_liked, isTrue);
    expect(logic.items.single.like_count, 12);
  });

  test('账号切换废弃旧请求、清理回复草稿和点赞状态', () async {
    final user = _login(7);
    final pending = Completer<Map<String, dynamic>>();
    final tokens = <String?>[];
    final logic = ComicCommentsLogic(
      comic_id: 1,
      token_reader: () async =>
          user.userInfo.value!.id == 7 ? 'account-a' : 'account-b',
      require_login: () => true,
      requester: (action, params, {authorization_token}) {
        tokens.add(authorization_token);
        return tokens.length == 1
            ? pending.future
            : Future.value(<String, dynamic>{
                'total': 1,
                'list': <Map<String, dynamic>>[_comment(99)],
              });
      },
    );
    addTearDown(logic.dispose);
    final old_request = logic.load();
    await Future<void>.delayed(Duration.zero);
    logic.reply_to(CommentData.from_json(_comment(1)), 1);
    _login(8);
    await Future<void>.delayed(Duration.zero);
    pending.complete(<String, dynamic>{
      'total': 1,
      'list': <Map<String, dynamic>>[_comment(1)],
    });
    await old_request;
    expect(tokens, <String>['account-a', 'account-b']);
    expect(logic.items.single.id, 99);
    expect(logic.replying, isNull);
    expect(logic.identity_epoch, 1);
  });

  test('漫画书架兼容comic DTO，ID不会与同号小说相撞，第一页显示续读', () async {
    final novel = ReadRecordItem.from_json(<String, dynamic>{
      'id': 5,
      'novel_id': 12,
      'novel_title': 'Novel',
    });
    final comic = ReadRecordItem.from_json(<String, dynamic>{
      'id': 5,
      'comic_id': 12,
      'content_type': 'comic',
      'comic_language_id': 3,
      'chapter_id': 90,
      'chapter_title': 'Chapter 7',
      'chapter_number': '7.0000',
      'page_index': 0,
      'page_count': 24,
      'title': 'Comic',
      'categories': <Map<String, dynamic>>[
        <String, dynamic>{'name': 'Adventure'},
      ],
    });
    expect(comic.novel_id, '12');
    expect(comic.novel_language_id, '3');
    expect(comic.page_index, 0);
    expect(comic.category_names, 'Adventure');
    final store = BookshelfStore(
      fetch_history_list: ({required page, required page_size}) async =>
          BookshelfListResult(
            list: <ReadRecordItem>[novel, comic, comic],
            total: 2,
            page: 1,
            page_size: 20,
          ),
    );
    addTearDown(store.onClose);
    await store.load_history_if_needed();
    expect(store.history_list, hasLength(2));
    final card = store.history_list.last;
    expect(card.id, 'comic:12');
    expect(card.identity, 'comic:12');
    expect(card.has_comic_progress, isTrue);
    expect(card.progress_key, 'bookshelf.progress.comic_reading');
    expect(card.chapter_title, 'Chapter 7');
    expect(card.page_count, 24);
  });

  test('登录标记先退出且资料仍在时，评论立即转为匿名并清理个人状态', () async {
    final user = _login(7);
    final tokens = <String?>[];
    final logic = ComicCommentsLogic(
      comic_id: 1,
      token_reader: () async => 'account-a',
      require_login: () => user.isLoggedIn.value,
      requester: (action, params, {authorization_token}) async {
        tokens.add(authorization_token);
        return <String, dynamic>{
          'list': <Map<String, dynamic>>[
            <String, dynamic>{
              ..._comment(1),
              'is_liked': authorization_token!.isNotEmpty,
            },
          ],
          'total': 1,
        };
      },
    );
    addTearDown(logic.dispose);
    await logic.load();
    logic.reply_to(logic.items.single, 1);
    user.isLoggedIn.value = false;
    await Future<void>.delayed(Duration.zero);
    expect(user.userInfo.value!.id, 7);
    expect(logic.user_id, 0);
    expect(logic.replying, isNull);
    expect(logic.items.single.is_liked, isFalse);
    expect(tokens, <String>['account-a', '']);
  });

  test('统一书架收到阅读/收藏通知立即刷新，同身份限制拒绝旧账号通知', () async {
    final user = _login(7);
    var history_requests = 0;
    var favorite_requests = 0;
    final store = Get.put(
      BookshelfStore(
        fetch_history_list: ({required page, required page_size}) async {
          history_requests++;
          return BookshelfListResult<ReadRecordItem>(
            list: const [],
            total: 0,
            page: 1,
            page_size: 20,
          );
        },
        fetch_favorite_list: ({required page, required page_size}) async {
          favorite_requests++;
          return BookshelfListResult<FavoriteItem>(
            list: const [],
            total: 0,
            page: 1,
            page_size: 20,
          );
        },
      ),
    );
    await store.load_history_if_needed();
    await store.load_favorite_if_needed();
    final revision = user.auth_revision;
    await BookshelfSyncService.history_changed(auth_revision: revision);
    await BookshelfSyncService.favorite_changed(auth_revision: revision);
    expect(history_requests, 2);
    expect(favorite_requests, 2);
    _login(8);
    await Future<void>.delayed(Duration.zero);
    final count = history_requests;
    await BookshelfSyncService.history_changed(auth_revision: revision);
    expect(history_requests, count);
  });

  test('删除漫画历史先排空旧保存，失败保留续读，成功后清本地', () async {
    _login(7);
    final phases = <String>[];
    var removed = false;
    Future<bool> remove() => remove_comic_history(
      comic_id: 12,
      token_reader: () async => 'account-a',
      prepare: (id, {user_id}) async {
        expect(id, 12);
        expect(user_id, 7);
        phases.add('prepare');
      },
      request: (action, params, {required authorization_token}) async {
        expect(action, 'remove_history');
        expect(authorization_token, 'account-a');
        phases.add('delete');
        if (!removed) throw StateError('network unavailable');
        return <String, dynamic>{'comic_id': 12};
      },
      clear: (id, {user_id}) async {
        phases.add('clear');
      },
    );
    await expectLater(remove(), throwsStateError);
    expect(phases, <String>['prepare', 'delete']);
    phases.clear();
    removed = true;
    expect(await remove(), isTrue);
    expect(phases, <String>['prepare', 'delete', 'clear']);
  });
}
