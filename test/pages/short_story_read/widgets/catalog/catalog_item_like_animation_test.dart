import 'package:app/models/short_story_item.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('目录点赞图标点击后先缩小再放大并恢复', (WidgetTester tester) async {
    int like_tap_count = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CatalogItem(
            item: const ShortStoryItem(
              id: 1,
              title: '短篇小说',
              description: '简介',
              tags: <String>['测试'],
              like_count: 8,
            ),
            is_current: false,
            is_dark: false,
            on_tap: () {},
            on_like_tap: () => like_tap_count++,
          ),
        ),
      ),
    );

    final Finder like_icon = find.byType(SvgPicture).last;
    final Finder like_scale_transition = find.ancestor(
      of: like_icon,
      matching: find.byType(ScaleTransition),
    );

    expect(like_scale_transition, findsOneWidget);
    expect(
      tester.widget<ScaleTransition>(like_scale_transition).scale.value,
      1,
    );

    await tester.tap(like_icon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(like_tap_count, 1);
    expect(
      tester.widget<ScaleTransition>(like_scale_transition).scale.value,
      lessThan(1),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<ScaleTransition>(like_scale_transition).scale.value,
      greaterThan(1),
    );

    await tester.pumpAndSettle();
    expect(
      tester.widget<ScaleTransition>(like_scale_transition).scale.value,
      1,
    );
  });
}
