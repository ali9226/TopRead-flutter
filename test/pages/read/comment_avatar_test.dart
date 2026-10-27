import 'package:app/components/comment_list/widgets/comment_avatar.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_item/reviewer_avatar.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_item/style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// 不访问外部网络，真实地址仍交给组件的图片加载管线。
class _PendingImages extends BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _preview = ValueKey('preview_avatar');
const _sheet = ValueKey('sheet_avatar');

Future<void> _mount(
  WidgetTester tester, {
  required int user_id,
  required bool dark,
  String url = '',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            ReadReviewerAvatar(
              key: _preview,
              user_id: user_id,
              avatar_url: url,
              is_dark: dark,
            ),
            CommentAvatar(
              key: _sheet,
              user_id: user_id,
              avatar_url: url,
              size: 38,
              is_dark: dark,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _fallback_name(WidgetTester tester, Finder avatar) => tester
    .widget<SvgIcon>(
      find.descendant(of: avatar, matching: find.byType(SvgIcon)),
    )
    .name;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    CachedNetworkImageProvider.defaultCacheManager = _PendingImages();
  });

  testWidgets('热门书评与弹窗按同用户展示相同默认头像，重建和主题变化不会重新随机', (tester) async {
    String? first;
    for (final dark in [false, true, false]) {
      await _mount(tester, user_id: 21, dark: dark);
      final preview = _fallback_name(tester, find.byKey(_preview));
      final sheet = _fallback_name(tester, find.byKey(_sheet));
      expect(preview, sheet);
      expect(preview, startsWith('avatar_'));
      first ??= preview;
      expect(preview, first);
      expect(
        tester.getSize(find.byKey(_preview)),
        const Size.square(CommentItemStyle.avatar_size),
      );
    }
    await _mount(tester, user_id: 22, dark: false);
    expect(_fallback_name(tester, find.byKey(_preview)), isNot(first));
    expect(tester.takeException(), isNull);
  });

  testWidgets('真实头像地址优先，加载失败与完整评论列表使用同一默认头像', (tester) async {
    const url = 'https://fixtures.invalid/reader-avatar.webp';
    await _mount(tester, user_id: 27, dark: true, url: ' $url ');
    final preview_image = tester.widget<CachedNetworkImage>(
      find.descendant(
        of: find.byKey(_preview),
        matching: find.byType(CachedNetworkImage),
      ),
    );
    final sheet_image = tester.widget<CachedNetworkImage>(
      find.descendant(
        of: find.byKey(_sheet),
        matching: find.byType(CachedNetworkImage),
      ),
    );
    expect(preview_image.imageUrl, url);
    expect(sheet_image.imageUrl, url);
    // 直接执行真实图片组件的失败回调，验证失败后的UI，而不依赖测试机网络时序。
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Row(
              children: [
                SizedBox(
                  key: _preview,
                  child: preview_image.errorWidget!(
                    context,
                    url,
                    StateError('offline'),
                  ),
                ),
                SizedBox(
                  key: _sheet,
                  child: sheet_image.errorWidget!(
                    context,
                    url,
                    StateError('offline'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _fallback_name(tester, find.byKey(_preview)),
      _fallback_name(tester, find.byKey(_sheet)),
    );
    expect(tester.takeException(), isNull);
  });
}
