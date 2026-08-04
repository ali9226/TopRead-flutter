import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/comment_list/models/comment_data.dart';

void main() {
  test('评论列表使用后端 is_liked 字段恢复主评论和回复的点赞状态', () {
    final CommentData comment = CommentData.from_json(<String, dynamic>{
      'id': 1,
      'user_id': 10,
      'nickname': '主评论用户',
      'comment_content': '主评论内容',
      'like_count': 13,
      'is_liked': 1,
      'replies': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 2,
          'user_id': 20,
          'nickname': '回复用户',
          'comment_content': '回复内容',
          'like_count': 2,
          'is_liked': true,
        },
      ],
    });

    expect(comment.is_liked, isTrue);
    expect(comment.like_count, 13);
    expect(comment.replies.single.is_liked, isTrue);
    expect(comment.replies.single.like_count, 2);
  });

  test('评论列表兼容 like 字段和字符串状态', () {
    final CommentData compatible_comment = CommentData.from_json(
      <String, dynamic>{'id': 3, 'like': '1'},
    );
    final CommentData unliked_comment = CommentData.from_json(<String, dynamic>{
      'id': 4,
      'like': '0',
      'is_liked': true,
    });

    expect(compatible_comment.is_liked, isTrue);
    expect(unliked_comment.is_liked, isFalse);
  });
}
