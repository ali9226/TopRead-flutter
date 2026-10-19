// ignore_for_file: non_constant_identifier_names

import 'dart:ui' as ui;
import 'package:app/pages/tile_quest/game/engine.dart';
import 'package:app/pages/tile_quest/game/generator.dart';
import 'package:app/pages/tile_quest/game/models.dart';
import 'package:app/pages/tile_quest/index.dart';
import 'package:app/pages/tile_quest/logic.dart';
import 'package:app/pages/tile_quest/services/feedback_service.dart';
import 'package:app/pages/tile_quest/services/save_service.dart';
import 'package:app/pages/tile_quest/services/work_service.dart';
import 'package:app/pages/tile_quest/widgets/quest_result.dart';
import 'package:app/pages/tile_quest/widgets/session_pause.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements TileQuestSaveStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async => value = next;
}

class _Feedback implements TileQuestFeedbackService {
  @override
  Future<void> play(TileQuestFeedbackEvent event) async {}
}

class _Work implements TileQuestWorkService {
  @override
  Future<TileQuestState> generate({
    required int level,
    required int seed,
    required int unlocked_level,
    String? challenge_id,
  }) async => TileQuestGenerator.generate(
    level: level,
    seed: seed,
    unlocked_level: unlocked_level,
    challenge_id: challenge_id,
  );

  @override
  Future<TileQuestPreparedShuffle> shuffle(
    Map<String, dynamic> engine_json, {
    required int seed,
  }) async {
    final engine = TileQuestEngine.restore(engine_json);
    return TileQuestPreparedShuffle(
      engine: engine,
      result: engine.shuffle(seed: seed),
    );
  }
}

const _hinge = DisplayFeature(
  bounds: Rect.fromLTWH(455.5, 0, 40, 669),
  type: DisplayFeatureType.hinge,
  state: DisplayFeatureState.postureHalfOpened,
);

MediaQueryData _media(Size size, {bool folded = false}) => MediaQueryData(
  size: size,
  padding: const EdgeInsets.only(right: 84, bottom: 34),
  viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
  displayFeatures: [
    if (folded) _hinge,
    DisplayFeature(
      bounds: Rect.fromLTWH(
        size.width - 84,
        0,
        84,
        size.width == 466 ? 174 : 124,
      ),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    ),
  ],
);

Future<ui.Image> _capture(WidgetTester tester, GlobalKey key) async =>
    (await tester.runAsync(
      () => (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
          .toImage(pixelRatio: 1),
    ))!;

Future<List<Color>> _pixels(
  WidgetTester tester,
  ui.Image image,
  List<Offset> points,
) async {
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return [
    for (final point in points)
      Color.fromARGB(
        bytes.getUint8(
          (point.dy.toInt() * image.width + point.dx.toInt()) * 4 + 3,
        ),
        bytes.getUint8((point.dy.toInt() * image.width + point.dx.toInt()) * 4),
        bytes.getUint8(
          (point.dy.toInt() * image.width + point.dx.toInt()) * 4 + 1,
        ),
        bytes.getUint8(
          (point.dy.toInt() * image.width + point.dx.toInt()) * 4 + 2,
        ),
      ),
  ];
}

void _expect_blend(List<Color> before, List<Color> after, Color mask) {
  for (var index = 0; index < before.length; index++) {
    final expected = Color.alphaBlend(mask, before[index]);
    for (final channel in [
      (after[index].r, expected.r),
      (after[index].g, expected.g),
      (after[index].b, expected.b),
    ]) {
      expect(channel.$1, closeTo(channel.$2, 3 / 255));
    }
  }
}

void main() {
  for (final dark in [false, true]) {
    for (final pose in ['closed', 'open', 'half_open']) {
      testWidgets('real tutorial result covers all window edges: $pose/$dark', (
        tester,
      ) async {
        final size = pose == 'closed'
            ? const Size(466, 678)
            : const Size(951, 669);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final media = _media(size, folded: pose == 'half_open');
        final saves = TileQuestSaveService(
          store: _Store(),
          encode_snapshot: encode_tile_quest_snapshot,
        );
        final logic = TileQuestLogic(
          save_service: saves,
          work_service: _Work(),
          feedback_service: _Feedback(),
          next_seed: () => 730,
          now_ms: () => 0,
          enable_timer: false,
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: MediaQuery(
              data: media,
              child: RepaintBoundary(
                key: boundary,
                child: TileQuestPage(logic: logic),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // 探针位于棋盘安全区以外：右侧状态栏、底部手势区以及右下角。
        final probes = [
          Offset(size.width - 2, size.height / 2),
          Offset(2, size.height - 2),
          Offset(size.width - 2, size.height - 2),
        ];
        final before_image = await _capture(tester, boundary);
        final before = await _pixels(tester, before_image, probes);
        before_image.dispose();
        for (final id in logic.state!.certified_solution.toList()) {
          expect((await logic.tap_tile(id))!.accepted, isTrue);
        }
        await tester.pumpAndSettle();
        expect(logic.state!.status, TileQuestStatus.won);
        expect(tester.getRect(find.byType(QuestResult)), Offset.zero & size);
        final after_image = await _capture(tester, boundary);
        final after = await _pixels(tester, after_image, probes);
        after_image.dispose();
        _expect_blend(
          before,
          after,
          const Color(0xFF061126).withValues(alpha: .72),
        );
        final button = tester.getRect(
          find.byKey(const ValueKey('tile_quest_result_primary')),
        );
        expect(button.right, lessThanOrEqualTo(size.width - 84));
        expect(button.bottom, lessThanOrEqualTo(size.height - 34));
        if (pose == 'half_open')
          expect(button.overlaps(_hinge.bounds), isFalse);
        await tester.tap(
          find.byKey(const ValueKey('tile_quest_result_primary')),
        );
        await tester.pumpAndSettle();
        expect(logic.state!.level, 2);
        expect(find.byType(QuestResult), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await saves.flush();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('session pause mask stays full window while folding', (
    tester,
  ) async {
    const size = Size(951, 669);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final media = ValueNotifier(_media(size));
    addTearDown(media.dispose);
    final saves = TileQuestSaveService(
      store: _Store(),
      encode_snapshot: encode_tile_quest_snapshot,
    );
    final logic = TileQuestLogic(
      save_service: saves,
      work_service: _Work(),
      feedback_service: _Feedback(),
      next_seed: () => 730,
      now_ms: () => 0,
      enable_timer: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<MediaQueryData>(
          valueListenable: media,
          child: TileQuestPage(logic: logic),
          builder: (_, value, child) => MediaQuery(data: value, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final other_owner = saves.acquire_session(on_revoke: () {});
    await tester.pumpAndSettle();
    expect(logic.session_suspended, isTrue);
    expect(tester.getRect(find.byType(QuestSessionPause)), Offset.zero & size);
    final pause_element = tester.element(find.byType(QuestSessionPause));
    media.value = _media(size, folded: true);
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(QuestSessionPause)), same(pause_element));
    expect(tester.getRect(find.byType(QuestSessionPause)), Offset.zero & size);
    final button = tester.getRect(
      find.byKey(const ValueKey('tile_quest_resume_session')),
    );
    expect(button.overlaps(_hinge.bounds), isFalse);
    expect(button.bottom, lessThanOrEqualTo(size.height - 34));
    saves.release_session(other_owner);
    await tester.tap(find.byKey(const ValueKey('tile_quest_resume_session')));
    await tester.pumpAndSettle();
    expect(logic.session_suspended, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await saves.flush();
    expect(tester.takeException(), isNull);
  });
}
