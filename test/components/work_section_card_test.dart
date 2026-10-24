import 'dart:ui' as ui;

import 'package:app/components/work_section_card/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('作品卡片上下均有柔和投影且保留昼夜纸面层级 dark=$dark', (tester) async {
      final original_shadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = original_shadows);

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: const ValueKey('card_capture'),
              child: ColoredBox(
                color: WorkSectionCardStyle.background(dark),
                child: SizedBox(
                  width: 240,
                  height: 220,
                  child: Center(
                    child: SizedBox(
                      width: 168,
                      height: 100,
                      child: WorkSectionCard(
                        is_dark: dark,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 直接采样实际像素，防止阴影配置存在但卡片顶部没有可见分层。
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('card_capture')),
      );
      final pixels = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes!;
      });
      // 测试框架在 tearDown 之前校验绘图全局状态，采样后立即复原。
      debugDisableShadows = original_shadows;
      int intensity(int x, int y) {
        final offset = (y * 240 + x) * 4;
        return pixels!.getUint8(offset) +
            pixels.getUint8(offset + 1) +
            pixels.getUint8(offset + 2);
      }

      final background = intensity(120, 16);
      final above_card = intensity(120, 54);
      final below_card = intensity(120, 166);
      expect(above_card, lessThan(background));
      expect(below_card, lessThan(background));
      expect(
        intensity(120, 110),
        dark ? greaterThan(background) : equals(background),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
