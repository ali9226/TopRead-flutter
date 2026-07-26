import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/widgets/comment_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferences_channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences_channel, (_) async {
          return <String, Object>{};
        });
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('整条主评论和子回复可触发回复，点赞区域保持独立', (WidgetTester tester) async {
    int? replied_comment_id;
    int? liked_comment_id;
    const CommentData reply = CommentData(
      id: 2,
      user_id: 2,
      avatar: '',
      nickname: '回复用户',
      content: '子回复内容',
      time: '',
    );
    const CommentData comment = CommentData(
      id: 1,
      user_id: 1,
      avatar: '',
      nickname: '评论用户',
      content: '主评论内容',
      time: '',
      replies: <CommentData>[reply],
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _CommentItemTestAssetLoader(),
        startLocale: const Locale('zh'),
        fallbackLocale: const Locale('zh'),
        child: MaterialApp(
          home: Material(
            child: SizedBox(
              width: 400,
              child: CommentItem(
                comment: comment,
                is_dark: false,
                on_reply: (CommentData target, BuildContext target_context) {
                  replied_comment_id = target.id;
                },
                on_like: (CommentData target) {
                  liked_comment_id = target.id;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder main_comment = find.byKey(
      const ValueKey<String>('comment_item_tap_1'),
    );
    await tester.tapAt(tester.getTopLeft(main_comment) + const Offset(8, 8));
    await tester.pump();
    expect(replied_comment_id, 1);

    replied_comment_id = null;
    await tester.tap(find.byKey(const ValueKey<String>('comment_like_1')));
    await tester.pump();
    expect(liked_comment_id, 1);
    expect(replied_comment_id, isNull);

    final Finder nested_reply = find.byKey(
      const ValueKey<String>('comment_reply_tap_2'),
    );
    await tester.tapAt(tester.getTopLeft(nested_reply) + const Offset(8, 8));
    await tester.pump();
    expect(replied_comment_id, 2);

    replied_comment_id = null;
    liked_comment_id = null;
    await tester.tap(find.byKey(const ValueKey<String>('comment_like_2')));
    await tester.pump();
    expect(liked_comment_id, 2);
    expect(replied_comment_id, isNull);
    expect(tester.takeException(), isNull);
  });
}

class _CommentItemTestAssetLoader extends AssetLoader {
  const _CommentItemTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'comment': <String, dynamic>{'reply': '回复', 'like': '赞'},
    };
  }
}
