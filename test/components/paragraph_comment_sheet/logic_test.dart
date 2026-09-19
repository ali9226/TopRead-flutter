// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/paragraph_comment_sheet/api.dart';
import 'package:app/components/paragraph_comment_sheet/logic.dart';
import 'package:flutter_test/flutter_test.dart';

/// 网关可延迟单个响应，用来覆盖分页、登录、点赞和关闭之间的真实竞争。
class _Repository extends ParagraphCommentRepository {
  Future<ParagraphCommentListResponse> Function(int? parent_id, int page)? read;
  Future<ParagraphCommentMutationResult> Function(
    String content, List<String> images, int? parent_id,
  )? send;
  Future<ParagraphCommentMutationResult> Function(int comment_id)? remove;
  Future<Map<String, dynamic>> Function(int comment_id, bool liked)? set_like;

  @override
  Future<ParagraphCommentListResponse> inquire({
    required int paragraph_id, int? parent_id, int page = 1,
  }) async => read?.call(parent_id, page) ?? _response();

  @override
  Future<ParagraphCommentMutationResult> submit({
    required int paragraph_id, required String content,
    int? parent_id, List<String> images = const [],
  }) async => send?.call(content, images, parent_id) ??
      const ParagraphCommentMutationResult(comment_count: 1);

  @override
  Future<ParagraphCommentMutationResult> delete(int comment_id) async =>
      remove?.call(comment_id) ??
      const ParagraphCommentMutationResult(comment_count: 0);

  @override
  Future<Map<String, dynamic>> like(int comment_id, bool liked) async =>
      set_like?.call(comment_id, liked) ?? {'liked': liked, 'like_count': 1};
}

ParagraphComment _comment(
  int id, {
  int reply_count = 0,
  List<ParagraphComment> replies = const [],
  List<String> images = const [],
  bool liked = false,
  int like_count = 0,
}) => ParagraphComment(
  id: id,
  user_id: 8,
  user_name: '读者',
  user_avatar: '',
  content: '评论 $id',
  create_time: '',
  replies: replies,
  reply_count: reply_count,
  images: images,
  quote: '引用正文',
  is_liked: liked,
  like_count: like_count,
);

ParagraphCommentListResponse _response({
  List<ParagraphComment> list = const [],
  int total = 0,
  int? count,
  bool more = false,
}) => ParagraphCommentListResponse(
  list: list,
  total: total,
  comment_count: count,
  page: 1,
  page_size: 20,
  has_more: more,
);

void main() {
  late _Repository repository;
  late ParagraphCommentSheetLogic logic;
  late List<int> counts;
  late List<Object> errors;

  setUp(() {
    repository = _Repository();
    counts = [];
    errors = [];
    logic = ParagraphCommentSheetLogic(
      paragraph_id: 7,
      initial_comment_count: 12,
      ensure_authenticated: () async => true,
      repository: repository,
      on_comment_count_changed: counts.add,
      on_error: errors.add,
    );
  });
  tearDown(() => logic.dispose());

  test('列表层级 total 不覆盖段落总数，刷新淘汰迟到的旧请求', () async {
    final old = Completer<ParagraphCommentListResponse>();
    repository.read = (_, _) => old.future;
    final pending = logic.load_comments();
    repository.read = (_, _) async => _response(
      list: [_comment(2)], total: 1, count: 5,
    );
    await logic.load_comments();
    old.complete(_response(list: [_comment(1)], total: 99, count: 99));
    await pending;
    expect(logic.comments.single.id, 2);
    expect(logic.comment_count, 5);
    expect(counts, [5]);
  });

  test('分页失败不推进页码，重复触发分页只发出一个请求', () async {
    repository.read = (_, _) async => _response(list: [_comment(1)], more: true);
    await logic.load_comments();
    final pages = <int>[];
    final delayed = Completer<ParagraphCommentListResponse>();
    repository.read = (_, page) {
      pages.add(page);
      return delayed.future;
    };
    final pending = logic.load_comments(load_more: true);
    await logic.load_comments(load_more: true);
    delayed.completeError(StateError('网络中断'));
    await pending;
    repository.read = (_, page) async {
      pages.add(page);
      return _response(list: [_comment(1), _comment(2)]);
    };
    await logic.load_comments(load_more: true);
    expect(pages, [2, 2]);
    expect(logic.comments.map((item) => item.id), [1, 2]);
    expect(logic.is_loading_more, isFalse);
    expect(errors, hasLength(1));
  });

  test('回复预览从第一页展开，重叠分页去重并保留段落总数', () async {
    final parent = _comment(1, reply_count: 4, replies: [_comment(2)]);
    repository.read = (_, _) async => _response(list: [parent], count: 9);
    await logic.load_comments();
    final pages = <int>[];
    repository.read = (parent_id, page) async {
      expect(parent_id, 1);
      pages.add(page);
      return page == 1
          ? _response(list: [_comment(5), _comment(4)], total: 4, more: true)
          : _response(list: [_comment(4), _comment(3), _comment(2)], total: 4);
    };
    await logic.load_replies(logic.comments.single);
    await logic.load_replies(logic.comments.single);
    expect(pages, [1, 2]);
    expect(logic.comments.single.replies.map((item) => item.id), [5, 4, 3, 2]);
    expect(logic.can_load_replies(logic.comments.single), isFalse);
    expect(logic.comment_count, 9);
  });

  test('回复请求期间点赞完成，迟到的回复页不能撤销点赞或图片引用', () async {
    const images = ['https://example.com/photo.png'];
    final reply = _comment(2, images: images);
    final parent = _comment(1, reply_count: 2, replies: [reply]);
    repository.read = (_, _) async => _response(list: [parent]);
    await logic.load_comments();
    final delayed = Completer<ParagraphCommentListResponse>();
    repository.read = (_, _) => delayed.future;
    final pending = logic.load_replies(parent);
    await logic.toggle_like(reply);
    delayed.complete(_response(list: [reply, _comment(3)], total: 2));
    await pending;
    final updated = logic.comments.single.replies.first;
    expect(updated.is_liked, isTrue);
    expect(updated.like_count, 1);
    expect(updated.images, images);
    expect(updated.quote, '引用正文');
  });

  test('连续点赞有请求锁，下一次点击基于当前状态取消点赞', () async {
    final comment = _comment(1);
    repository.read = (_, _) async => _response(list: [comment]);
    await logic.load_comments();
    final delayed = Completer<Map<String, dynamic>>();
    final requested_states = <bool>[];
    repository.set_like = (_, liked) {
      requested_states.add(liked);
      return delayed.future;
    };
    final pending = logic.toggle_like(comment);
    await logic.toggle_like(comment);
    await Future<void>.delayed(Duration.zero);
    delayed.complete({'liked': '1', 'like_count': '1'});
    await pending;
    repository.set_like = (_, liked) async {
      requested_states.add(liked);
      return {'liked': liked, 'like_count': 0};
    };
    await logic.toggle_like(comment);
    expect(requested_states, [true, false]);
    expect(logic.comments.single.is_liked, isFalse);
    expect(logic.liking_ids, isEmpty);
  });

  test('纯图片回复成功后刷新失败仍返回成功，避免重复发送已发布草稿', () async {
    repository.send = (content, images, parent_id) async {
      expect(content, isEmpty);
      expect(images, ['https://example.com/image.png']);
      expect(parent_id, 2);
      return const ParagraphCommentMutationResult(comment_count: 13);
    };
    repository.read = (_, _) async => throw StateError('刷新失败');
    final success = await logic.submit(
      content: ' ', images: ['https://example.com/image.png'], parent_id: 2,
    );
    expect(success, isTrue);
    expect(counts, [13]);
    expect(errors, hasLength(1));
    expect(logic.is_submitting, isFalse);
  });

  test('删除采用后端总数，不把带回复的父评当成单条增减', () async {
    repository.remove = (id) async {
      expect(id, 1);
      return const ParagraphCommentMutationResult(comment_count: 8);
    };
    repository.read = (_, _) async => _response(total: 2, count: 8);
    await logic.delete_comment(1);
    expect(logic.comment_count, 8);
    expect(counts, [8]);
  });

  test('关闭弹窗后不再发送登录后的请求或触发迟到回调', () async {
    logic.dispose();
    final authentication = Completer<bool>();
    int submits = 0;
    logic = ParagraphCommentSheetLogic(
      paragraph_id: 7,
      initial_comment_count: 12,
      ensure_authenticated: () => authentication.future,
      repository: repository,
      on_comment_count_changed: counts.add,
      on_error: errors.add,
    );
    repository.send = (_, _, _) async {
      submits++;
      return const ParagraphCommentMutationResult(comment_count: 13);
    };
    final pending = logic.submit(content: '异步草稿');
    logic.deactivate();
    authentication.complete(true);
    expect(await pending, isFalse);
    expect(submits, 0);
    expect(counts, isEmpty);
    expect(errors, isEmpty);
  });

  test('关闭后忽略迟到列表的总数、错误和监听回调', () async {
    final delayed = Completer<ParagraphCommentListResponse>();
    repository.read = (_, _) => delayed.future;
    final pending = logic.load_comments();
    int notifications = 0;
    logic.addListener(() => notifications++);
    logic.deactivate();
    delayed.complete(_response(count: 99));
    await pending;
    expect(notifications, 0);
    expect(counts, isEmpty);
    expect(logic.comment_count, 12);
  });
}
