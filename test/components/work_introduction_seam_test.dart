import 'dart:ui' as ui;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(466, 678)]) {
    for (final short_story in [false, true]) {
      for (final dark in [false, true]) {
        testWidgets('封面与正文在分数滚动位置无细线 $size short=$short_story dark=$dark', (
          tester,
        ) async {
          const dpr = 2.625;
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = size * dpr;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          final boundary_key = GlobalKey();
          final hero_key = GlobalKey();
          final body_key = GlobalKey();
          final paper = dark
              ? short_story
                    ? ShortStoryReadStyle.bg_dark_color
                    : ColorConstants.nightBackgroundColor
              : ColorConstants.whiteColor;
          final duo = size.width == 466;
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  devicePixelRatio: dpr,
                  padding: duo
                      ? const EdgeInsets.only(top: 44, right: 84, bottom: 34)
                      : const EdgeInsets.only(top: 44, bottom: 34),
                  viewPadding: duo
                      ? const EdgeInsets.only(top: 44, right: 84, bottom: 34)
                      : const EdgeInsets.only(top: 44, bottom: 34),
                  displayFeatures: duo
                      ? [
                          ui.DisplayFeature(
                            bounds: Rect.fromLTWH(size.width - 84, 0, 84, 48),
                            type: ui.DisplayFeatureType.cutout,
                            state: ui.DisplayFeatureState.unknown,
                          ),
                        ]
                      : const [],
                ),
                child: WindowLayoutScope(
                  child: Scaffold(
                    backgroundColor: paper,
                    body: RepaintBoundary(
                      key: boundary_key,
                      child: WindowContentLayout(
                        child: SingleChildScrollView(
                          controller: scroll,
                          child: Column(
                            children: [
                              WorkIntroductionHero(
                                key: hero_key,
                                is_dark: dark,
                                surface_color: short_story ? paper : null,
                                title: 'Dawn',
                                cover: const ColoredBox(color: Colors.grey),
                                // 高对比头图暴露被两个抗锯齿边缘漏出的底色。
                                backdrop: const ColoredBox(color: Colors.blue),
                                metadata_builder: (_, _) =>
                                    const SizedBox(height: 13.7),
                              ),
                              ColoredBox(
                                color: paper,
                                child: SizedBox(
                                  key: body_key,
                                  width: double.infinity,
                                  height: 1200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final height = tester.getSize(find.byKey(hero_key)).height;
          expect(tester.getTopLeft(find.byKey(body_key)).dy, height);

          for (final fraction in [0.0, 0.1, 0.25, 0.5, 0.75]) {
            scroll.jumpTo(height - 200 - fraction);
            await tester.pumpAndSettle();
            final seam = tester.getBottomLeft(find.byKey(hero_key)).dy;
            // 绘制覆盖不能改变正文位置或海报布局高度。
            expect(tester.getSize(find.byKey(hero_key)).height, height);
            expect(tester.getTopLeft(find.byKey(body_key)).dy, seam);
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(boundary_key),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: dpr);
              try {
                final bytes = (await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                ))!.buffer.asUint8List();
                for (final ratio in [0.15, 0.5, 0.85]) {
                  final x = (size.width * ratio * dpr).floor();
                  for (
                    var y = (seam * dpr).floor() - 3;
                    y <= (seam * dpr).ceil() + 3;
                    y++
                  ) {
                    final offset = (y * image.width + x) * 4;
                    expect(
                      bytes.sublist(offset, offset + 4),
                      [
                        (paper.r * 255).round(),
                        (paper.g * 255).round(),
                        (paper.b * 255).round(),
                        255,
                      ],
                      reason: 'fraction=$fraction, x=$x, y=$y, seam=$seam',
                    );
                  }
                }
              } finally {
                image.dispose();
              }
            });
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
