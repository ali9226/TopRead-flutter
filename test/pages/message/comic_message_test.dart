// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/models/message_data.dart';
import 'package:app/stores/message_store.dart';
import 'package:flutter_test/flutter_test.dart';

MessageData _comic({
  int type = MessageType.comment_reply,
  int? chapter_id,
  bool self = false,
  String scene = 'comic_comment',
}) => MessageData.from_json({
  'id': 19,
  'user_id': 2,
  'send_user': self ? 0 : 3,
  'notify_status': self ? 2 : 1,
  'type': type,
  'comic_cover': 'https://fixture.test/comic.webp',
  'novel_cover': 'https://fixture.test/unrelated-novel.webp',
  'content': jsonEncode({
    'content_type': 'comic',
    'comic_id': '81',
    'comic_title': '漫画标题',
    'chapter_id': chapter_id,
    'comment_id': '51',
    'notification_scene': scene,
  }),
});

void main() {
  test('漫画有独立封面及标题，已读复制不会丢失作品类型', () {
    final message = _comic();
    expect(message.is_comic, isTrue);
    expect(message.comic_id, 81);
    expect(message.novel_id, 0);
    expect(message.work_title, '漫画标题');
    expect(message.work_cover, 'https://fixture.test/comic.webp');
    final read = message.copy_with(notify_status: NotifyStatus.read);
    expect(read.is_unread, isFalse);
    expect(read.is_comic, isTrue);
    expect(read.work_cover, message.work_cover);
  });

  for (final type in [MessageType.comment_reply, MessageType.comment_like]) {
    test('漫画互动类型 $type 使用正确作品/章节评论路由', () {
      for (final chapter in [null, 0, 123]) {
        final destination = Uri.parse(
          _comic(type: type, chapter_id: chapter).destination_path!,
        );
        expect(destination.path, '/comics/comments');
        expect(destination.queryParameters['comic_id'], '81');
        expect(
          destination.queryParameters['chapter_id'],
          chapter == 123 ? '123' : isNull,
        );
        expect(destination.queryParameters.containsKey('novel_id'), isFalse);
      }
    });
  }

  test('漫画收藏进入漫画详情，缺少有效 ID 不会误跳小说', () {
    expect(
      _comic(type: MessageType.novel_favorite).destination_path,
      '/comics/detail?id=81',
    );
    final invalid = MessageData.from_json({
      'type': 5,
      'content': '{"content_type":"comic","novel_id":81}',
    });
    expect(invalid.destination_path, isNull);
    expect(invalid.work_cover, isEmpty);
  });

  test('长篇短篇消息保持原路由与评论参数，字符串特殊字符正确编码', () {
    for (final status in [1, 4]) {
      final novel = MessageData.from_json({
        'type': 2,
        'novel_cover': 'novel.webp',
        'comic_cover': 'unrelated.webp',
        'content': jsonEncode({
          'novel_id': 81,
          'novel_title': '书名 & spaces',
          'novel_publish_status': status,
          'comment_id': 18,
        }),
      });
      final destination = Uri.parse(novel.destination_path!);
      expect(novel.is_comic, isFalse);
      expect(novel.work_cover, 'novel.webp');
      expect(destination.path, status == 4 ? '/short_story_read' : '/read');
      expect(destination.queryParameters['id'], '81');
      expect(destination.queryParameters['comment_id'], '18');
      if (status != 4) {
        expect(destination.queryParameters['title'], '书名 & spaces');
      }
    }
  });

  test('漫画实时消息复用评论/点赞/收藏统计，重连重复事件不重复插入或加未读', () {
    final store = MessageStore();
    addTearDown(store.onClose);
    for (final type in [2, 3, 5]) {
      final event = <String, dynamic>{
        'type': 'new_message',
        'data': {
          'message': {
            'id': type + 100,
            'type': type,
            'notify_status': 1,
            'send_user': 3,
            'comic_cover': 'https://fixture.test/comic.webp',
            'content': _comic(type: type).content,
          },
        },
      };
      store.handle_websocket_event(event);
      store.handle_websocket_event(event);
    }
    expect(store.message_list.length, 3);
    expect(store.message_list.every((message) => message.is_comic), isTrue);
    expect(store.comment_unread.value, 1);
    expect(store.like_unread.value, 1);
    expect(store.favorite_unread.value, 1);
    expect(store.unread_total.value, 3);
  });

  test('四种界面语言都有漫画消息标题及本人/他人文案', () {
    for (final locale in ['zh', 'en', 'fr', 'sw']) {
      final data =
          jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
              as Map;
      final message = data['message'] as Map;
      for (final scene in [
        'comic_comment',
        'comic_reply',
        'comic_like',
        'comic_collect',
      ]) {
        expect(message['card_title'][scene], isNotEmpty);
        for (final suffix in ['self', 'other']) {
          expect(message['card_subtitle']['${scene}_$suffix'], contains('{0}'));
        }
      }
    }
  });
}
