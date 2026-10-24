import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/title_with_story_id/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';

const _two_lines = 'The Silver Moon\nBeyond the Stars';
const _three_lines = 'The Silver Moon\nBeyond the Stars\nAnother Promise';
const _five_lines =
    'The Silver Moon\nBeyond the Stars\nAnother Promise\nAcross the Sea\nA New Dawn';
const _title_key = ValueKey('bottom_title');
const _author_key = ValueKey('bottom_author');
const _actions_key = ValueKey('bottom_actions');
const _stats_key = ValueKey('bottom_stats');
const _cover_key = ValueKey('work_introduction_cover');
const _metadata_key = ValueKey('work_introduction_metadata');

class _StateProbe extends StatefulWidget {
  const _StateProbe({super.key, required this.label, this.compact = false});
  final String label;
  final bool compact;

  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  bool selected = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => selected = !selected),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: SizedBox(
        width: double.infinity,
        child: Text('${widget.label}${selected ? ' selected' : ''}'),
      ),
    ),
  );
}

Future<void> _load_fonts() async {
  final font = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '.fvm/flutter_sdk'}'
    '/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  expect(font.existsSync(), isTrue);
  final bytes = ByteData.sublistView(font.readAsBytesSync());
  for (final family in ['Roboto', 'Georgia']) {
    await (FontLoader(family)..addFont(Future.value(bytes))).load();
  }
}

Future<void> _mount(
  WidgetTester tester, {
  String title = _two_lines,
  Size size = const Size(390, 900),
  double scale = 1,
  bool cutout = false,
  bool actual_debug_title = false,
  RxBool? inline_badge,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
          padding: cutout ? const EdgeInsets.only(right: 84) : EdgeInsets.zero,
          viewPadding: cutout
              ? const EdgeInsets.only(right: 84)
              : EdgeInsets.zero,
          displayFeatures: cutout
              ? [
                  ui.DisplayFeature(
                    bounds: Rect.fromLTWH(size.width - 84, 0, 84, 124),
                    type: ui.DisplayFeatureType.cutout,
                    state: ui.DisplayFeatureState.unknown,
                  ),
                ]
              : const [],
        ),
        child: WindowLayoutScope(
          child: Scaffold(
            body: WindowContentLayout(
              max_width: double.infinity,
              child: SingleChildScrollView(
                child: WorkIntroductionHero(
                  key: const ValueKey('bottom_alignment_hero'),
                  is_dark: false,
                  title: title,
                  cover: const ColoredBox(color: Colors.blue),
                  backdrop: const ColoredBox(color: ColorConstants.whiteColor),
                  status_label: 'Completed',
                  status_key: const ValueKey('bottom_status'),
                  title_builder: (_, style, _) => KeyedSubtree(
                    key: _title_key,
                    child: actual_debug_title
                        ? TitleWithStoryId(
                            title: title,
                            story_id: 42,
                            title_style: style,
                          )
                        : inline_badge == null
                        ? Text(title, style: style)
                        : Obx(
                            () => Text.rich(
                              TextSpan(
                                text: title,
                                style: style,
                                children: inline_badge.value
                                    ? const [
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: SizedBox(
                                            key: ValueKey('bottom_inline_id'),
                                            width: 110,
                                            height: 20,
                                          ),
                                        ),
                                      ]
                                    : const [],
                              ),
                            ),
                          ),
                  ),
                  metadata_builder: (_, _) =>
                      const _StateProbe(key: _author_key, label: 'Follow'),
                  actions_builder: (_, _, compact) => _StateProbe(
                    key: _actions_key,
                    label: 'Read',
                    compact: compact,
                  ),
                  overflow_builder: (_, _) => const SizedBox(
                    key: _stats_key,
                    width: double.infinity,
                    height: 64,
                  ),
                  on_back: () {},
                  on_share: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

RenderParagraph _paragraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byKey(_title_key),
            matching: find.byType(RichText),
          )
          .first,
    );

double _font_size(InlineSpan span, [double inherited = 14]) {
  final current = span.style?.fontSize ?? inherited;
  if (span is TextSpan && span.text?.isNotEmpty == true) return current;
  double? result;
  span.visitDirectChildren((child) {
    result ??= _font_size(child, current);
    return result == null;
  });
  return result ?? current;
}

void _expect_bottom_alignment(WidgetTester tester) {
  final cover = _rect(tester, _cover_key);
  final metadata = _rect(tester, _metadata_key);
  expect(cover.bottom, closeTo(metadata.bottom, 0.01));
  expect(_rect(tester, _title_key).left, greaterThanOrEqualTo(cover.right));
  final status = _rect(tester, const ValueKey('bottom_status'));
  expect(
    status.top,
    closeTo(cover.top + WorkIntroductionHeroStyle.status_margin, 0.01),
  );
  expect(
    status.right,
    closeTo(cover.right - WorkIntroductionHeroStyle.status_margin, 0.01),
  );
  final compact = tester.widget<_StateProbe>(find.byKey(_actions_key)).compact;
  final actions = _rect(tester, _actions_key);
  final stats = _rect(tester, _stats_key);
  if (compact) {
    expect(actions.bottom, closeTo(metadata.bottom, 0.01));
    expect(actions.bottom, lessThan(stats.top));
  } else {
    expect(actions.top, greaterThan(stats.bottom));
  }
  expect(find.byKey(const ValueKey('work_introduction_panel')), findsNothing);
  expect(_paragraph(tester).maxLines, isNull);
  expect(_paragraph(tester).didExceedMaxLines, isFalse);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_load_fonts);
  setUp(() {
    Get.testMode = true;
    Get.put(UserInformation());
  });
  tearDown(Get.reset);

  testWidgets('三档标题与作者操作整体始终和封面底对齐，Completed在右上', (tester) async {
    for (final title in ['Dawn', _two_lines, _three_lines, _five_lines]) {
      await _mount(tester, title: title);
      _expect_bottom_alignment(tester);
      expect(
        tester.widget<_StateProbe>(find.byKey(_actions_key)).compact,
        title != _five_lines,
      );
    }
  });

  testWidgets('实际WidgetSpan增加一行时缩字，Obx内联内容出现隐藏会重新分档', (tester) async {
    final badge = false.obs;
    await _mount(tester, inline_badge: badge);
    expect(
      _font_size(_paragraph(tester).text),
      WorkIntroductionHeroStyle.title_size_alphabetic,
    );
    badge.value = true;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bottom_inline_id')), findsOneWidget);
    expect(_paragraph(tester).childCount, 1);
    expect(
      _font_size(_paragraph(tester).text),
      WorkIntroductionHeroStyle.reduced_title_size_alphabetic,
    );
    _expect_bottom_alignment(tester);
    final settled = _rect(tester, _metadata_key);
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(_rect(tester, _metadata_key), settled);
      expect(
        _font_size(_paragraph(tester).text),
        WorkIntroductionHeroStyle.reduced_title_size_alphabetic,
      );
    }
    badge.value = false;
    await tester.pumpAndSettle();
    expect(_paragraph(tester).childCount, 0);
    expect(
      _font_size(_paragraph(tester).text),
      WorkIntroductionHeroStyle.title_size_alphabetic,
    );
    _expect_bottom_alignment(tester);
  });

  testWidgets('真实TitleWithStoryId的运营徽标参与字号判断，账号切换后恢复', (tester) async {
    final user = Get.find<UserInformation>();
    user.userInfo.value = UserInfo.fromJson({'id': 1, 'debug': 1});
    await _mount(tester, actual_debug_title: true);
    expect(
      _font_size(_paragraph(tester).text),
      WorkIntroductionHeroStyle.title_size_alphabetic,
    );
    user.userInfo.value = UserInfo.fromJson({'id': 1, 'debug': 2});
    await tester.pumpAndSettle();
    expect(_paragraph(tester).childCount, 1);
    expect(
      _font_size(_paragraph(tester).text),
      WorkIntroductionHeroStyle.reduced_title_size_alphabetic,
    );
    _expect_bottom_alignment(tester);
    user.userInfo.value = UserInfo.fromJson({'id': 1, 'debug': 1});
    await tester.pumpAndSettle();
    expect(_paragraph(tester).childCount, 0);
    expect(
      _font_size(_paragraph(tester).text),
      WorkIntroductionHeroStyle.title_size_alphabetic,
    );
  });

  testWidgets('Duo底对齐和两倍字体窗口往返保持档位稳定及关注动作State', (tester) async {
    final badge = true.obs;
    await _mount(
      tester,
      inline_badge: badge,
      size: const Size(466, 900),
      cutout: true,
    );
    final author_state = tester.state<_StateProbeState>(
      find.byKey(_author_key),
    );
    final action_state = tester.state<_StateProbeState>(
      find.byKey(_actions_key),
    );
    await tester.tap(find.text('Follow'));
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();
    final initial_compact = tester
        .widget<_StateProbe>(find.byKey(_actions_key))
        .compact;
    for (final scenario in [
      (const Size(390, 900), 2.0, false),
      (const Size(951, 900), 1.0, false),
      (const Size(466, 900), 1.0, true),
    ]) {
      await _mount(
        tester,
        inline_badge: badge,
        size: scenario.$1,
        scale: scenario.$2,
        cutout: scenario.$3,
      );
      _expect_bottom_alignment(tester);
      expect(
        tester.state<_StateProbeState>(find.byKey(_author_key)),
        same(author_state),
      );
      expect(
        tester.state<_StateProbeState>(find.byKey(_actions_key)),
        same(action_state),
      );
      expect(find.text('Follow selected'), findsOneWidget);
      expect(find.text('Read selected'), findsOneWidget);
      final metadata = _rect(tester, _metadata_key);
      final font_size = _font_size(_paragraph(tester).text);
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(_rect(tester, _metadata_key), metadata);
        expect(_font_size(_paragraph(tester).text), font_size);
      }
      if (scenario.$3) {
        expect(
          _rect(
            tester,
            _metadata_key,
          ).overlaps(const Rect.fromLTWH(382, 0, 84, 124)),
          isFalse,
        );
        expect(
          tester.widget<_StateProbe>(find.byKey(_actions_key)).compact,
          initial_compact,
        );
      }
    }
  });
}
