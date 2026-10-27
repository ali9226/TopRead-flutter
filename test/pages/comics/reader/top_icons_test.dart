// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/action_button.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/models/project_config.dart';
import 'package:app/pages/comics/reader/widgets/top_scrim.dart';
import 'package:app/pages/short_story_read/widgets/full_appbar.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(
      ProjectConfigStore(),
    ).save_config(ProjectConfig.from_json({'share_switch': SwitchValue.on}));
  });
  tearDown(Get.reset);

  for (final dark in [false, true]) {
    for (final collected in [false, true]) {
      testWidgets('漫画顶部与短篇使用相同图形、尺寸及SVG描边配色 dark=$dark saved=$collected', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: Column(
                children: [
                  FullAppbar(
                    is_dark: dark,
                    on_back: () {},
                    on_favorite_tap: () {},
                    on_share: () {},
                    is_favorited: collected,
                    status_bar_height: 0,
                  ),
                  ComicReaderTopScrim(
                    title: 'Chapter 4',
                    on_back: () {},
                    on_share: () {},
                    on_collect: () {},
                    collected: collected,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final asset in [
          collected ? 'user_selected' : 'not_favorited',
          'share',
        ]) {
          Finder icon_in(Type parent) => find.descendant(
            of: find.byType(parent),
            matching: find.byWidgetPredicate(
              (widget) => widget is SvgIcon && widget.name == asset,
            ),
          );
          final novel = tester.widget<SvgIcon>(icon_in(FullAppbar));
          final comic = tester.widget<SvgIcon>(icon_in(ComicReaderTopScrim));
          expect(comic.width, novel.width);
          expect(comic.height, novel.height);
          expect(comic.color, novel.color);
          SvgPicture rendered(Finder parent) => tester.widget<SvgPicture>(
            find.descendant(of: parent, matching: find.byType(SvgPicture)),
          );
          // 同一SVG渲染源包含全部原始填色与外部补色，不能被单色滤镜抹去。
          final novel_svg = rendered(icon_in(FullAppbar));
          final comic_svg = rendered(icon_in(ComicReaderTopScrim));
          expect(comic_svg.colorFilter, novel_svg.colorFilter);
          expect(comic_svg.bytesLoader, isA<SvgStringLoader>());
          expect(comic_svg.bytesLoader, novel_svg.bytesLoader);
        }
        for (final action
            in find
                .descendant(
                  of: find.byType(ComicReaderTopScrim),
                  matching: find.byType(ReaderTopBarAction),
                )
                .evaluate()) {
          final target = tester.getSize(find.byWidget(action.widget));
          expect(target.width, greaterThanOrEqualTo(48));
          expect(target.height, greaterThanOrEqualTo(48));
        }
        expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
        expect(find.byIcon(Icons.favorite_rounded), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('漫画收藏即时显示乐观星形、无波纹并阻止重复点击，远端分享开关实时生效', (tester) async {
    var collecting = false;
    var collected = false;
    var collections = 0;
    var shares = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, state) {
              update = state;
              return ComicReaderTopScrim(
                title: 'Chapter 4',
                on_back: () {},
                on_share: () => shares++,
                on_collect: () => collections++,
                collected: collected,
                collecting: collecting,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    List<ReaderTopBarAction> actions() => tester
        .widgetList<ReaderTopBarAction>(find.byType(ReaderTopBarAction))
        .toList();
    await tester.tap(find.byWidget(actions()[1]));
    expect(collections, 1);
    update(() {
      collecting = true;
      collected = true;
    });
    await tester.pump();
    final spinner = find.byType(CircularProgressIndicator);
    expect(spinner, findsNothing);
    expect((actions()[1].icon_widget! as SvgIcon).name, 'user_selected');
    expect(actions()[1].ripple, isFalse);
    expect(actions().first.ripple, isTrue);
    expect(actions().last.ripple, isTrue);
    await tester.tap(find.byWidget(actions()[1]));
    expect(collections, 1);
    update(() {
      collecting = false;
      collected = true;
    });
    await tester.pumpAndSettle();
    expect(spinner, findsNothing);
    expect((actions()[1].icon_widget! as SvgIcon).name, 'user_selected');
    await tester.tap(find.byWidget(actions()[2]));
    expect(shares, 1);
    Get.find<ProjectConfigStore>().save_config(
      ProjectConfig.from_json({'share_switch': SwitchValue.off}),
    );
    await tester.pumpAndSettle();
    expect(actions(), hasLength(2));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SvgIcon && widget.name == 'share',
      ),
      findsNothing,
    );
    Get.find<ProjectConfigStore>().save_config(
      ProjectConfig.from_json({'share_switch': SwitchValue.on}),
    );
    await tester.pumpAndSettle();
    expect(actions(), hasLength(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
