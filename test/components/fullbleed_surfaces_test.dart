// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/auth_page/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/language_info.dart';
import 'package:app/pages/home/widgets/full_screen_skeleton/index.dart';
import 'package:app/pages/user_info/widgets/user_info_top.dart';
import 'package:app/pages/user_info/widgets/login_register_button.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Device extends DeviceInfo {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Home extends HomeBannerStore {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Language extends LanguageStore {
  _Language() : super(asset_language_code_list: ['en']) {
    supported_language_list.assignAll(const [
      LanguageInfo(code: 'en', title: 'English'),
    ]);
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/en.json').readAsStringSync()) as Map,
      );
}

Future<ui.Image> _capture(WidgetTester tester, GlobalKey key) async {
  await tester.pump(const Duration(milliseconds: 16));
  return (await tester.runAsync(
    () => (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
        .toImage(pixelRatio: 1),
  ))!;
}

Future<Color> _pixel(WidgetTester tester, ui.Image image, int x, int y) async {
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    await LanguageUtil.load_asset_language_code_list();
  });
  setUp(() {
    Get.testMode = true;
    Get.put<DeviceInfo>(_Device());
    Get.put<HomeBannerStore>(_Home());
    Get.put<LanguageStore>(_Language());
    Get.put(UserInformation());
  });
  tearDown(Get.reset);

  Future<void> mount(
    WidgetTester tester,
    Widget page,
    GlobalKey boundary, {
    required bool dark,
  }) async {
    Get.find<DeviceInfo>().dark.value = dark;
    Get.find<DeviceInfo>().theme.value = dark
        ? ThemeMode.dark
        : ThemeMode.light;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        assetLoader: const _Assets(),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(right: 84, bottom: 34),
                viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
              ),
              child: WindowLayoutScope(
                child: RepaintBoundary(key: boundary, child: page),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final dark in [false, true]) {
    testWidgets('真实用户中心hero $dark 背景铺满右84状态区且不重复放大图片', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(466, 678);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final boundary = GlobalKey();
      final profile_key = GlobalKey();
      await mount(
        tester,
        Scaffold(
          body: SingleChildScrollView(child: UserInfoTop(key: profile_key)),
        ),
        boundary,
        dark: dark,
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/img/user_info_background_image.webp'),
          tester.element(find.byType(UserInfoTop)),
        ),
      );
      final profile_state = profile_key.currentState;
      for (final width in [466.0, 669.0]) {
        tester.view.physicalSize = Size(width, width == 466 ? 678 : 951);
        await tester.pump(const Duration(milliseconds: 300));
        final hero_image = find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).image?.image ==
                  const AssetImage(
                    'assets/img/user_info_background_image.webp',
                  ),
        );
        expect(tester.getRect(hero_image).left, 0);
        expect(tester.getSize(hero_image).width, width);
        expect(profile_key.currentState, same(profile_state));
        final login = tester.getRect(find.byType(LoginRegisterButton));
        expect(login.right, lessThanOrEqualTo(width - 84));
        final image = await _capture(tester, boundary);
        final right_pixel = await _pixel(tester, image, width.toInt() - 8, 40);
        expect(right_pixel, isNot(Colors.white));
        expect(right_pixel.a, 1);
        expect(right_pixel.r, greaterThan(.35));
        expect(right_pixel.g, greaterThan(.25));
        image.dispose();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('真实首页骨架 $dark 装饰和底色铺满右84，内容保持安全宽度', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(466, 678);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final boundary = GlobalKey();
      await mount(
        tester,
        FullScreenSkeleton(
          is_dark: dark,
          on_search_tap: () {},
          on_language_tap: () {},
        ),
        boundary,
        dark: dark,
      );
      final foreground = find.descendant(
        of: find.byType(FullScreenSkeleton),
        matching: find.byType(WindowContentLayout),
      );
      expect(tester.getRect(foreground).width, 466);
      final image = await _capture(tester, boundary);
      final right_pixel = await _pixel(tester, image, 450, 120);
      expect(
        right_pixel,
        dark ? const Color(0xFF0D1117) : const Color(0xFFF6F7FB),
      );
      image.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('真实认证共享壳 $dark 渐变不被前景容器涂白且字段避让右84', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(466, 678);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final boundary = GlobalKey();
      const field_key = ValueKey('fullbleed_auth_field');
      await mount(
        tester,
        const AuthPageScaffold(
          backgroundBubbles: [],
          children: [
            TextField(key: field_key),
            SizedBox(height: 300),
          ],
        ),
        boundary,
        dark: dark,
      );
      expect(tester.getRect(find.byKey(field_key)).right, 382);
      final image = await _capture(tester, boundary);
      final right = await _pixel(tester, image, 450, 120);
      final center = await _pixel(tester, image, 210, 120);
      expect(right, isNot(Colors.white));
      expect(center, right);
      image.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
