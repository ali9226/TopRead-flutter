// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:ui' as ui;

import 'package:app/components/window_display_features/index.dart';
import 'package:app/components/window_display_features/regions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _region({
  String kind = 'division',
  bool active = true,
  double x = 440,
  double y = 0,
  double width = 20,
  double height = 600,
}) => {
  'kind': kind,
  'active': active,
  'x': x,
  'y': y,
  'width': width,
  'height': height,
};

Map<String, Object?> _packet(
  List<Object?> regions, {
  Size size = const Size(900, 600),
}) => {
  'view_width': size.width,
  'view_height': size.height,
  'regions': regions,
};

void main() {
  test(
    'active system regions preserve point coordinates and classify hardware',
    () {
      final snapshot = WindowReservedRegions.from_platform(
        _packet([
          _region(),
          _region(kind: 'occlusion', x: 840, y: 18, width: 40, height: 40),
          _region(active: false, x: 450, width: 0),
          _region(kind: 'unknown'),
        ]),
      )!;
      expect(snapshot.view_size, const Size(900, 600));
      expect(snapshot.features, hasLength(2));
      final division = snapshot.features.first;
      expect(division.bounds, const Rect.fromLTWH(440, 0, 20, 600));
      expect(division.type, ui.DisplayFeatureType.hinge);
      expect(division.state, ui.DisplayFeatureState.postureHalfOpened);
      final camera = snapshot.features.last;
      expect(camera.bounds, const Rect.fromLTWH(840, 18, 40, 40));
      expect(camera.type, ui.DisplayFeatureType.cutout);
      expect(camera.state, ui.DisplayFeatureState.unknown);
    },
  );

  test(
    'malformed and out of view regions cannot produce invalid layout geometry',
    () {
      for (final value in <Object?>[
        null,
        false,
        {'view_width': double.infinity, 'view_height': 600, 'regions': []},
        {'view_width': 900, 'view_height': -1, 'regions': []},
        {'view_width': 900, 'view_height': 600, 'regions': null},
      ]) {
        expect(WindowReservedRegions.from_platform(value), isNull);
      }
      final snapshot = WindowReservedRegions.from_platform(
        _packet([
          null,
          'region',
          _region(x: double.nan),
          _region(width: -20),
          _region(x: 1000),
          _region(kind: 'occlusion', width: 0),
          _region(x: -8, y: -10, width: 20, height: 630),
          _region(x: 450, width: 0),
        ]),
      )!;
      expect(snapshot.features, hasLength(2));
      expect(
        snapshot.features.first.bounds,
        const Rect.fromLTWH(0, 0, 12, 600),
      );
      expect(
        snapshot.features.last.bounds,
        const Rect.fromLTWH(450, 0, 0, 600),
      );
      expect(
        snapshot.features.last.state,
        ui.DisplayFeatureState.postureHalfOpened,
      );
    },
  );

  test(
    'merge preserves engine features, rejects stale size, and avoids duplicates',
    () {
      final snapshot = WindowReservedRegions.from_platform(
        _packet([_region()]),
      )!;
      final existing_division = snapshot.features.single;
      const camera = ui.DisplayFeature(
        bounds: Rect.fromLTWH(880, 4, 16, 20),
        type: ui.DisplayFeatureType.cutout,
        state: ui.DisplayFeatureState.unknown,
      );
      final media = MediaQueryData(
        size: const Size(900, 600),
        displayFeatures: [existing_division, camera],
      );
      expect(snapshot.merge_with(media), [existing_division, camera]);
      final stale = media.copyWith(size: const Size(600, 900));
      expect(snapshot.merge_with(stale), same(stale.displayFeatures));
      expect(
        snapshot.has_same_geometry(
          WindowReservedRegions.from_platform(_packet([_region()])),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'changing posture updates MediaQuery without displacing a continuous page or losing state',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final stream = StreamController<Object?>.broadcast();
      addTearDown(stream.close);
      final text = TextEditingController(text: '保留编辑内容');
      addTearDown(text.dispose);
      MediaQueryData? observed;
      const surface_key = ValueKey('continuous_surface');
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => WindowDisplayFeatures(
            feature_stream: stream.stream,
            refresh_features: () async => null,
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                observed = MediaQuery.of(context);
                return SizedBox.expand(
                  key: surface_key,
                  child: TextField(controller: text),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original_rect = tester.getRect(find.byKey(surface_key));
      final original_state = tester.state(find.byType(TextField));
      for (final packet in [
        _packet([_region()]),
        _packet([_region(active: false, width: 0)]),
        _packet([_region(x: 0, y: 290, width: 900, height: 20)]),
      ]) {
        stream.add(packet);
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(surface_key)), original_rect);
        expect(tester.state(find.byType(TextField)), same(original_state));
        expect(text.text, '保留编辑内容');
        expect(observed!.size, const Size(900, 600));
        expect(tester.takeException(), isNull);
      }
      expect(observed!.displayFeatures.single.bounds.top, 290);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(stream.hasListener, isFalse);
    },
  );

  testWidgets(
    'a dialog moves into its anchor pane when an active fold appears',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final stream = StreamController<Object?>.broadcast();
      addTearDown(stream.close);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => WindowDisplayFeatures(
            feature_stream: stream.stream,
            refresh_features: () async => null,
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  anchorPoint: const Offset(880, 10),
                  builder: (_) => const AlertDialog(
                    title: Text('可见的操作'),
                    content: Text('折叠变化期间仍能完整阅读与操作。'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final before = tester.getRect(find.byType(AlertDialog));
      expect(before.left, lessThan(440));
      expect(before.right, greaterThan(460));

      stream.add(_packet([_region()]));
      await tester.pumpAndSettle();
      final after = tester.getRect(find.byType(AlertDialog));
      expect(after.left, greaterThanOrEqualTo(460));
      expect(after.right, lessThanOrEqualTo(900));
      expect(find.text('可见的操作'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a delayed refresh and an unavailable plugin cannot replace newer posture',
    (tester) async {
      final stream = StreamController<Object?>.broadcast();
      addTearDown(stream.close);
      final refresh = Completer<Object?>();
      MediaQueryData? observed;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(900, 600)),
          child: WindowDisplayFeatures(
            feature_stream: stream.stream,
            refresh_features: () => refresh.future,
            child: Builder(
              builder: (context) {
                observed = MediaQuery.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      stream.add(_packet([_region()]));
      await tester.pumpAndSettle();
      expect(observed!.displayFeatures, hasLength(1));
      refresh.complete(_packet([]));
      await tester.pumpAndSettle();
      expect(observed!.displayFeatures, hasLength(1));
      stream.addError(MissingPluginException('Unsupported host'));
      await tester.pumpAndSettle();
      expect(observed!.displayFeatures, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
