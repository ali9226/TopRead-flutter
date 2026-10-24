// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/network_cover_image/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/message/style.dart';
import 'package:app/pages/message/widgets/message_item_card.dart';
import 'package:app/stores/device_info.dart';
import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _preview_dir = String.fromEnvironment('MESSAGE_CARD_PREVIEW_DIR');
const _cover_url = 'https://fixture.test/cover.png';
const _failed_cover_url = 'https://fixture.test/failed.png';
const _card_key = ValueKey('message_card_fixture');
const _preview_key = ValueKey('message_card_preview');

class _TestDeviceInfo extends DeviceInfo {
  @override
  // ignore: must_call_super
  void onInit() {}
}

/// 真实封面组件从确定图片缓存读取；失败路径也完全离线。
class _Images extends BaseCacheManager {
  _Images(this.image);
  final FileInfo image;

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => url == _failed_cover_url
      ? Stream<FileResponse>.error(StateError('offline fixture failure'))
      : Stream<FileResponse>.value(image);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Only fixture images may be read.');
}

Future<void> _mount(
  WidgetTester tester, {
  String? cover,
  bool dark = false,
  Size size = const Size(390, 844),
  double scale = 1,
  bool duo = false,
  int unread_count = 7,
  String badge = 'Comment',
  String icon = 'message',
  int message_type = 2,
  VoidCallback? on_tap,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Get.find<DeviceInfo>().theme.value = dark ? ThemeMode.dark : ThemeMode.light;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        fontFamily: _preview_dir.isEmpty ? null : 'MessagePreview',
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
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
            body: RepaintBoundary(
              key: _preview_key,
              child: ColoredBox(
                color: dark
                    ? ColorConstants.nightBackgroundColor
                    : ColorConstants
                          .components_category_filter_category_filter_bar_tone_fff6f7fb,
                child: WindowContentLayout(
                  child: SingleChildScrollView(
                    padding: MessageStyle.page_padding.copyWith(top: 64),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: on_tap,
                      child: MessageItemCard(
                        key: _card_key,
                        icon_name: icon,
                        title: 'A reader responded to your story',
                        subtitle:
                            'A thoughtful response to the chapter you published yesterday.',
                        time_text: '8m ago',
                        badge_text: badge,
                        accent_color: Colors.orange,
                        message_type: message_type,
                        novel_cover: cover,
                        is_unread: true,
                        unread_count: unread_count,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // 图片解码需要真实异步队列，不能等一个仍在播放的加载占位动画结束。
  await tester.runAsync(() async {
    await precacheImage(
      CachedNetworkImageProvider(_cover_url),
      tester.element(find.byKey(_card_key)),
    );
  });
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_preview_dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_preview_key),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_preview_dir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final image = MemoryFileSystem().file('/cover.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGPIbJgJAALYAYO6bf8KAAAAAElFTkSuQmCC',
        ),
      );
    CachedNetworkImageProvider.defaultCacheManager = _Images(
      FileInfo(image, FileSource.Cache, DateTime.utc(2100), _cover_url),
    );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    if (_preview_dir.isNotEmpty) {
      final font = File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf');
      if (font.existsSync()) {
        await (FontLoader('MessagePreview')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  setUp(() {
    Get.testMode = true;
    Get.put<DeviceInfo>(_TestDeviceInfo());
  });
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    Get.reset();
  });

  for (final dark in [false, true]) {
    testWidgets('消息有封面时右侧只显示类型图标，保留封面角标与外层点击 dark=$dark', (tester) async {
      var taps = 0;
      await _mount(
        tester,
        cover: '  $_cover_url  ',
        dark: dark,
        on_tap: () => taps++,
      );
      final cover = find.byType(NetworkCoverImage);
      expect(cover, findsOneWidget);
      expect(tester.widget<NetworkCoverImage>(cover).image_url, _cover_url);
      expect(tester.getSize(cover), const Size(45, 55));
      expect(find.text('Comment'), findsNothing);
      final icon = find.byType(SvgPicture);
      expect(icon, findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('message_type_icon'))),
        const Size(44, 44),
      );
      expect(find.byTooltip('Comment'), findsOneWidget);
      expect(
        tester.getCenter(icon).dx,
        greaterThan(tester.getRect(cover).right),
      );
      expect(
        tester.getSize(icon),
        const Size(MessageStyle.icon_size, MessageStyle.icon_size),
      );
      expect(find.text('7'), findsOneWidget);
      for (final target in [
        cover,
        icon,
        find.text('A reader responded to your story'),
      ]) {
        await tester.tap(target);
      }
      expect(taps, 3);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'message_cover_${dark ? 'dark' : 'light'}');
    });

    testWidgets('无封面或空白URL保留左图标右文字与未读角标 dark=$dark', (tester) async {
      for (final cover in <String?>[null, '   ']) {
        var taps = 0;
        await _mount(
          tester,
          cover: cover,
          dark: dark,
          badge: 'Like',
          icon: 'love_02',
          message_type: 4,
          unread_count: 128,
          on_tap: () => taps++,
        );
        expect(find.byType(NetworkCoverImage), findsNothing);
        final icon = find.byType(SvgPicture);
        final label = find.text('Like');
        expect(icon, findsOneWidget);
        expect(label, findsOneWidget);
        expect(tester.getCenter(icon).dx, lessThan(tester.getCenter(label).dx));
        expect(find.text('99+'), findsOneWidget);
        await tester.tap(icon);
        await tester.tap(label);
        expect(taps, 2);
        expect(tester.takeException(), isNull);
      }
      await _capture(tester, 'message_no_cover_${dark ? 'dark' : 'light'}');
    });
  }

  testWidgets('封面失败显示书籍占位，右侧类型图标不重复且仍可打开消息', (tester) async {
    var taps = 0;
    await _mount(tester, cover: _failed_cover_url, on_tap: () => taps++);
    expect(find.byType(NetworkCoverImage), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Comment'), findsNothing);
    expect(find.text('7'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  for (final config in [
    (size: const Size(280, 740), scale: 2.0, duo: false),
    (size: const Size(466, 678), scale: 1.6, duo: true),
  ]) {
    testWidgets('消息卡片在窄屏大字与Duo不溢出 ${config.size}', (tester) async {
      for (final dark in [false, true]) {
        for (final cover in <String?>[null, _cover_url]) {
          await _mount(
            tester,
            cover: cover,
            dark: dark,
            size: config.size,
            scale: config.scale,
            duo: config.duo,
          );
          expect(tester.takeException(), isNull);
          final card = tester.getRect(find.byKey(_card_key));
          final icon = tester.getRect(find.byType(SvgPicture));
          expect(icon.left, greaterThanOrEqualTo(card.left));
          expect(icon.right, lessThanOrEqualTo(card.right));
          expect(find.text('7').hitTestable(), findsOneWidget);
          expect(
            find.text('Comment'),
            cover == null ? findsOneWidget : findsNothing,
          );
        }
      }
    });
  }

  if (_preview_dir.isNotEmpty) {
    testWidgets('导出消息卡片窄屏大字与Duo预览', (tester) async {
      final previous_shadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        for (final config in [
          (size: const Size(280, 740), scale: 2.0, duo: false),
          (size: const Size(466, 678), scale: 1.6, duo: true),
        ]) {
          for (final dark in [false, true]) {
            await _mount(
              tester,
              cover: _cover_url,
              dark: dark,
              size: config.size,
              scale: config.scale,
              duo: config.duo,
            );
            await _capture(
              tester,
              'message_${config.size.width.toInt()}_${dark ? 'dark' : 'light'}',
            );
          }
        }
      } finally {
        debugDisableShadows = previous_shadows;
      }
    });
  }
}
