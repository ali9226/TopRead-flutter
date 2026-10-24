import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/components/work_introduction_hero/title_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/config/color_config.dart';

const _regular_title = 'Dandelion\nA Mageknight';
const _flowing_title = 'Beyond the Silver Moon and the Last Forgotten Star';
const _extended_title =
    'A promise forgotten\nAcross the winter sea\nBeneath a falling moon\n'
    'Beyond the hidden gate\nWhere every star returns';
const _author_key = ValueKey('title_tier_author');
const _action_key = ValueKey('title_tier_action');
const _title_key = ValueKey('title_tier_title');
const _stats_key = ValueKey('title_tier_stats');

/// 用本地交互State检查动作跨父节点迁移，而不是只核对按钮文案。
class _InteractionProbe extends StatefulWidget {
  const _InteractionProbe({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  State<_InteractionProbe> createState() => _InteractionProbeState();
}

class _InteractionProbeState extends State<_InteractionProbe> {
  int count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => count++),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: SizedBox(
        width: double.infinity,
        child: Text('${widget.label} $count'),
      ),
    ),
  );
}

/// 测试使用Flutter随附的真实Roboto，标题的Georgia族也绑定同一份真实字形，
/// 使两行/四行边界跨平台可复现，并避免Ahem等宽方块改变分档结果。
Future<void> _load_real_fonts() async {
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
  String title = _regular_title,
  Size size = const Size(390, 900),
  double scale = 1,
  bool cutout = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
                  key: const ValueKey('title_tier_hero'),
                  is_dark: false,
                  title: title,
                  cover: const ColoredBox(color: Colors.blue),
                  backdrop: const ColoredBox(color: ColorConstants.whiteColor),
                  title_builder: (_, style, _) =>
                      Text(title, key: _title_key, style: style),
                  metadata_builder: (_, _) => const _InteractionProbe(
                    key: _author_key,
                    label: 'Follow',
                  ),
                  actions_builder: (_, _, compact) => _InteractionProbe(
                    key: _action_key,
                    label: 'Read',
                    compact: compact,
                  ),
                  overflow_builder: (_, _) => const SizedBox(
                    key: _stats_key,
                    height: 64,
                    width: double.infinity,
                    child: Text('123 Readers'),
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

/// 读取最终实际Text使用的字体、字号、宽度和系统缩放，独立验证真实行数。
int _actual_lines(WidgetTester tester, {double? font_size}) {
  final finder = find.byKey(_title_key);
  final rich = tester.widget<RichText>(
    find.descendant(of: finder, matching: find.byType(RichText)),
  );
  final span = rich.text as TextSpan;
  final painter = TextPainter(
    text: TextSpan(
      text: span.toPlainText(),
      style: span.style!.copyWith(fontSize: font_size),
    ),
    textDirection:
        rich.textDirection ?? Directionality.of(tester.element(finder)),
    textScaler: rich.textScaler,
    locale: rich.locale,
    textHeightBehavior: rich.textHeightBehavior,
  )..layout(maxWidth: tester.getSize(finder).width);
  final lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines;
}

void _expect_tier(WidgetTester tester, WorkHeroTitleTier tier) {
  final title = tester.widget<Text>(find.byKey(_title_key));
  final regular = tier == WorkHeroTitleTier.regular;
  expect(title.style!.fontFamily, 'Georgia');
  expect(
    title.style!.fontSize,
    regular
        ? WorkIntroductionHeroStyle.title_size_alphabetic
        : WorkIntroductionHeroStyle.reduced_title_size_alphabetic,
  );
  expect(title.maxLines, isNull);
  expect(title.overflow, isNot(TextOverflow.ellipsis));
  final lines = _actual_lines(tester);
  if (regular) {
    expect(lines, lessThanOrEqualTo(2));
  } else {
    expect(
      _actual_lines(
        tester,
        font_size: WorkIntroductionHeroStyle.title_size_alphabetic,
      ),
      greaterThan(2),
    );
    expect(
      lines,
      tier == WorkHeroTitleTier.reduced ? lessThanOrEqualTo(4) : greaterThan(4),
    );
  }
  final cover = _rect(tester, const ValueKey('work_introduction_cover'));
  final title_bounds = _rect(tester, _title_key);
  final author = _rect(tester, _author_key);
  final action = _rect(tester, _action_key);
  final stats = _rect(tester, _stats_key);
  final compact = tier != WorkHeroTitleTier.extended;
  expect(title_bounds.left, greaterThanOrEqualTo(cover.right));
  expect(
    _rect(tester, const ValueKey('work_introduction_metadata')).bottom,
    closeTo(cover.bottom, 0.01),
  );
  expect(author.top, greaterThanOrEqualTo(title_bounds.bottom));
  expect(
    tester.widget<_InteractionProbe>(find.byKey(_action_key)).compact,
    compact,
  );
  if (compact) {
    expect(action.top, greaterThanOrEqualTo(author.bottom));
    expect(action.bottom, lessThan(stats.top));
    expect(action.width, lessThan(stats.width));
  } else {
    expect(action.top, greaterThan(stats.bottom));
    expect(action.left, closeTo(stats.left, 0.01));
    expect(action.width, closeTo(stats.width, 0.01));
  }
  expect(find.byKey(const ValueKey('work_introduction_panel')), findsNothing);
  expect(tester.takeException(), isNull);
}

/// 生成只因Duo局部避让而从原字号两行进入小字号的真实字体边界书名。
String _duo_boundary_title(TextStyle regular_style) {
  int lines(String title, double width) {
    final painter = TextPainter(
      text: TextSpan(text: title, style: regular_style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final count = painter.computeLineMetrics().length;
    painter.dispose();
    return count;
  }

  const inner_width = 466 - WorkIntroductionHeroStyle.horizontal_padding * 2;
  final cover_width = math.min(
    WorkIntroductionHeroStyle.cover_max_width,
    inner_width * WorkIntroductionHeroStyle.cover_width_ratio,
  );
  final full_width =
      inner_width - cover_width - WorkIntroductionHeroStyle.content_gap;
  final avoided_width =
      full_width - (84 - WorkIntroductionHeroStyle.horizontal_padding);
  for (var count = 1; count <= 40; count++) {
    final title = List.filled(count, 'Voyage').join(' ');
    if (lines(title, full_width) == 2 && lines(title, avoided_width) > 2) {
      return title;
    }
  }
  fail('真实字体中未找到Duo两行边界书名');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_load_real_fonts);

  testWidgets('三档第一档：两行保留原字号，操作在作者下方', (tester) async {
    await _mount(tester);
    expect(_actual_lines(tester), 2);
    _expect_tier(tester, WorkHeroTitleTier.regular);
  });

  testWidgets('三档第二档：原字号超过两行，小字号四行内操作仍在作者下方', (tester) async {
    await _mount(tester, title: _flowing_title);
    _expect_tier(tester, WorkHeroTitleTier.reduced);
  });

  testWidgets('三档第三档：小字号超过四行完整换行，操作在全宽统计下方', (tester) async {
    await _mount(tester, title: _extended_title);
    _expect_tier(tester, WorkHeroTitleTier.extended);
    final title = _rect(tester, _title_key);
    final poster = _rect(tester, const ValueKey('work_introduction_poster'));
    expect(title.bottom, lessThan(poster.bottom));
    expect(tester.widget<Text>(find.byKey(_title_key)).data, _extended_title);
  });

  testWidgets('2倍字体和折叠往返即时更新三档，关注与动作State跨位置迁移保持', (tester) async {
    await _mount(tester, title: _flowing_title);
    _expect_tier(tester, WorkHeroTitleTier.reduced);
    final author_state = tester.state<_InteractionProbeState>(
      find.byKey(_author_key),
    );
    final action_state = tester.state<_InteractionProbeState>(
      find.byKey(_action_key),
    );
    await tester.tap(find.text('Follow 0'));
    await tester.tap(find.text('Read 0'));
    await tester.pumpAndSettle();
    for (final scenario in [
      (const Size(390, 900), 2.0, WorkHeroTitleTier.extended),
      (const Size(951, 900), 2.0, WorkHeroTitleTier.reduced),
      (const Size(951, 900), 1.0, WorkHeroTitleTier.regular),
      (const Size(390, 900), 1.0, WorkHeroTitleTier.reduced),
    ]) {
      await _mount(
        tester,
        title: _flowing_title,
        size: scenario.$1,
        scale: scenario.$2,
      );
      _expect_tier(tester, scenario.$3);
      expect(
        tester.state<_InteractionProbeState>(find.byKey(_author_key)),
        same(author_state),
      );
      expect(
        tester.state<_InteractionProbeState>(find.byKey(_action_key)),
        same(action_state),
      );
      expect(find.text('Follow 1'), findsOneWidget);
      expect(find.text('Read 1'), findsOneWidget);
    }
  });

  testWidgets('Duo按避让后真实行宽选档，移除局部系统区后恢复原字号和动作', (tester) async {
    const size = Size(466, 678);
    await _mount(tester, size: size);
    final rich_title = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(_title_key),
        matching: find.byType(RichText),
      ),
    );
    final title = _duo_boundary_title(rich_title.text.style!);
    await _mount(tester, title: title, size: size);
    _expect_tier(tester, WorkHeroTitleTier.regular);
    await _mount(tester, title: title, size: size, cutout: true);
    _expect_tier(tester, WorkHeroTitleTier.reduced);
    const obstruction = Rect.fromLTWH(382, 0, 84, 124);
    expect(_rect(tester, _title_key).overlaps(obstruction), isFalse);
    expect(
      tester.getRect(find.byIcon(Icons.share_outlined)).overlaps(obstruction),
      isFalse,
    );
    expect(
      _rect(tester, const ValueKey('work_introduction_poster')).width,
      size.width,
    );
    await _mount(tester, title: title, size: size);
    _expect_tier(tester, WorkHeroTitleTier.regular);
  });
}
