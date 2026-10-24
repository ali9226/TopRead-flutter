// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ui' as ui;
import 'package:app/components/category_filter/filter_popup.dart';
import 'package:app/components/category_filter/style.dart';
import 'package:app/models/preference.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/widgets/dislike_reason_sheet.dart';
import 'package:app/models/home_classification.dart';
import 'package:app/stores/home_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';

/// iPhone Duo closed：右侧状态区 84、底部手势区 34（逻辑像素）。
const _duo_size = Size(466, 678);
const _duo_padding = EdgeInsets.only(right: 84, bottom: 34);

/// 右侧状态区上沿探针（时间/运营商所在右上角）。
Offset get _top_right => Offset(_duo_size.width - 2, 2);

/// 右侧状态区中线（面板未覆盖到的中上部）。
Offset get _right_mid => Offset(_duo_size.width - 2, 100);

const _bg = ColorConstants.components_app_modal_full_window_test_tone_ff3a7bbe;

MediaQueryData _duo_media() => MediaQueryData(
  size: _duo_size,
  padding: _duo_padding,
  viewPadding: _duo_padding,
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

void _expect_masked(List<Color> pixels, Color mask, Color background) {
  final expected = Color.alphaBlend(mask, background);
  for (final pixel in pixels) {
    expect(
      pixel.r,
      closeTo(expected.r, 3 / 255),
      reason: 'pixel=$pixel expected=$expected',
    );
    expect(
      pixel.g,
      closeTo(expected.g, 3 / 255),
      reason: 'pixel=$pixel expected=$expected',
    );
    expect(
      pixel.b,
      closeTo(expected.b, 3 / 255),
      reason: 'pixel=$pixel expected=$expected',
    );
  }
}

Future<void> _pump_duo_host(WidgetTester tester, GlobalKey boundary) async {
  await tester.binding.setSurfaceSize(_duo_size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: _duo_media(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _bg),
            RepaintBoundary(key: boundary, child: const SizedBox.expand()),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 不触碰 GetStorage 的最小替身，只为让 DislikeReasonSheet 拿到 dislike_list。
class _FakeBannerStore extends GetxController implements HomeBannerStore {
  @override
  final RxList<HomeClassification> dislike_list = <HomeClassification>[].obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('showGeneralDialog 的 ModalBarrier 铺满 Duo 全窗口', (tester) async {
    await tester.binding.setSurfaceSize(_duo_size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: _duo_media(),
          child: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showGeneralDialog<void>(
                  context: context,
                  barrierLabel: 'dialog',
                  barrierColor: ColorConstants.util_dialog_pop_up_input_tone,
                  pageBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // 路由遮罩必须是整个 Navigator 矩形，不能被 SafeArea 压进安全区。
    expect(
      tester.getRect(find.byType(ModalBarrier).last),
      Offset.zero & _duo_size,
    );
    Navigator.of(tester.element(find.byType(ModalBarrier).last)).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('showModalBottomSheet 的 ModalBarrier 铺满 Duo 全窗口', (tester) async {
    await tester.binding.setSurfaceSize(_duo_size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: _duo_media(),
          child: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const SizedBox(height: 200),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(ModalBarrier).last),
      Offset.zero & _duo_size,
    );
    Navigator.of(tester.element(find.byType(ModalBarrier).last)).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('CategoryFilterPopup 自绘遮罩覆盖右侧状态区', (tester) async {
    final boundary = GlobalKey();
    await _pump_duo_host(tester, boundary);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: _duo_media(),
          child: RepaintBoundary(
            key: boundary,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: _bg),
                CategoryFilterPopup(
                  temp_selected_id: Rxn<int>(),
                  category_list: const [
                    PreferenceItem(id: 1, type: 2, title: 'Fantasy'),
                    PreferenceItem(id: 2, type: 2, title: 'Romance'),
                  ],
                  is_dark: false,
                  language_code: 'en',
                  on_toggle_category: (_) {},
                  on_clear: () {},
                  on_confirm: () {},
                  on_close: () {},
                  scroll_controller: ScrollController(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = await _capture(tester, boundary);
    final pixels = await _pixels(tester, image, [_top_right, _right_mid]);
    image.dispose();
    _expect_masked(
      pixels,
      CategoryFilterStyle.overlay_color.withValues(alpha: 0.66),
      _bg,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('DislikeReasonSheet 自绘遮罩覆盖右侧状态区', (tester) async {
    Get.put<HomeBannerStore>(_FakeBannerStore());
    addTearDown(Get.reset);
    final boundary = GlobalKey();
    await _pump_duo_host(tester, boundary);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: _duo_media(),
          child: RepaintBoundary(
            key: boundary,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: _bg),
                DislikeReasonSheet(
                  is_dark: false,
                  on_option_tap: (_) {},
                  on_close: () {},
                  on_navigate_to_interest: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = await _capture(tester, boundary);
    final pixels = await _pixels(tester, image, [_top_right, _right_mid]);
    image.dispose();
    _expect_masked(
      pixels,
      ShortStoryTabStyle.dislike_overlay_color.withValues(alpha: 0.4),
      _bg,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
