import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/recommend_book_card/widgets/recommend_waterfall_skeleton.dart';
import 'package:app/models/story_item.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/index.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_section_skeleton.dart';

void main() {
  testWidgets('完整榜单加载态复用公共骨架并保持固定高度', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: RankingSectionStyle.section_fixed_height,
            child: RankingSection(
              sub_tab_list: <String>[],
              sub_tab_id_list: <int>[],
              all_ranking_data: <List<StoryItem>>[],
              is_dark: false,
              panel_bg: Colors.white,
              language_code: 'zh',
              is_loading: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder skeleton_finder = find.byType(RankingSectionSkeleton);
    expect(skeleton_finder, findsOneWidget);
    expect(
      tester.getSize(skeleton_finder).height,
      RankingSectionStyle.section_fixed_height,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('推荐瀑布流公共骨架同时适配日间和夜间主题', (WidgetTester tester) async {
    for (final bool is_dark in <bool>[false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 390,
                child: RecommendWaterfallSkeleton(is_dark: is_dark),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(RecommendWaterfallSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
