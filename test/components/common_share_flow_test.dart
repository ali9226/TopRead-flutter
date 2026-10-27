import 'package:app/components/share_sheet/index.dart';
import 'package:app/components/share_sheet/poster_export.dart';
import 'package:app/components/share_sheet/share_channel_uri.dart';
import 'package:app/components/share_sheet/share_work_url.dart';
import 'package:app/components/share_sheet/style.dart';
import 'package:app/components/share_sheet/widgets/card_preview_sheet.dart';
import 'package:app/components/share_sheet/widgets/share_poster_card.dart';
import 'package:app/config/share_channels.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'share_sheet': {
      'title': 'Share',
      'generate_image': 'Create Image',
      'copy_link': 'Copy Link',
      'copy_success': 'Link copied',
      'copy_failed': 'Copy failed',
      'card_preview_title': 'Card Preview',
      'save_to_album': 'Save to Gallery',
      'save_success': 'Saved',
      'save_failed': 'Save failed',
      'photo_permission_denied': 'Permission needed',
      'default_reader': 'Reader',
      'excerpt_by': '{name} · Excerpt',
      'read_together': 'Open {app} · Read with me',
      'qr_semantics': 'Sharing QR',
      'share_text': 'Read {title} on {app}',
    },
  };
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      startLocale: const Locale('en'),
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(bottom: 24),
              ),
              child: Align(alignment: Alignment.bottomCenter, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
  });

  test('三种分享链接与真实路由一致，公开地址不使用API调试配置或令牌', () {
    for (final entry in {
      WorkShareKind.novel: '/read',
      WorkShareKind.short_story: '/short_story_read',
      WorkShareKind.comic: '/comics/detail',
    }.entries) {
      final url = share_work_url(
        work_id: 42,
        work_kind: entry.key,
        language: 'zh',
      );
      expect(url.scheme, 'https');
      expect(url.path, entry.value);
      expect(url.queryParameters, {'id': '42', 'language': 'zh'});
      expect(url.userInfo, isEmpty);
      expect(url.fragment, isEmpty);
    }
    for (final base in [
      'http://public.example',
      'https://localhost',
      'https://127.0.0.1',
      'https://0.0.0.0',
      'https://192.168.1.5',
      'https://10.0.0.2',
      'https://172.16.0.1',
      'https://[::1]',
      'https://user:pass@public.example',
    ]) {
      expect(() => public_share_origin(base), throwsStateError);
    }
    expect(() => share_work_url(work_id: 0), throwsArgumentError);
  });

  test('一处渠道配置决定所有入口，平台图标默认显示且URL安全编码', () {
    expect(enabled_share_channels().map((row) => row.id), [
      'generate_image',
      'whatsapp',
      'x',
      'telegram',
      'copy_link',
    ]);
    expect(
      enabled_share_channels(
        include_generate_image: false,
      ).map((row) => row.id),
      ['whatsapp', 'x', 'telegram', 'copy_link'],
    );
    final uri = share_work_url(
      work_id: 7,
      work_kind: WorkShareKind.comic,
      language: 'en',
    );
    for (final action in [
      ShareChannelAction.whatsapp,
      ShareChannelAction.x,
      ShareChannelAction.telegram,
    ]) {
      final intent = share_channel_uri(
        action: action,
        work_url: uri,
        title: 'A & 中文 ?',
      );
      expect(intent?.scheme, 'https');
      if (action == ShareChannelAction.whatsapp) {
        expect(intent?.queryParameters['text'], 'A & 中文 ?\n$uri');
      } else {
        expect(intent?.queryParameters['text'], 'A & 中文 ?');
        expect(intent?.queryParameters['url'], uri.toString());
      }
    }
  });

  test('所有可一处启用的渠道图标都来自实际打包资源', () async {
    for (final channel in share_channel_configuration) {
      final bytes = await rootBundle.load(
        'assets/svg/${channel.icon_name}.svg',
      );
      expect(bytes.lengthInBytes, greaterThan(0));
    }
  });

  test('拒绝权限或页面失效时不截图、不写相册，成功时等待真正写入完成', () async {
    var captured = 0, written = 0;
    final bytes = Uint8List.fromList([1, 2, 3]);
    final denied = PosterExportService(
      has_access: () async => false,
      request_access: () async => false,
      capture: (_) async {
        captured++;
        return bytes;
      },
      write_image: (_, _) async {
        written++;
      },
    );
    expect(
      await denied.save(boundary_key: GlobalKey(), image_name: 'test'),
      PosterSaveResult.access_denied,
    );
    expect(captured, 0);
    expect(written, 0);
    final approved = PosterExportService(
      has_access: () async => true,
      request_access: () async => throw StateError('Must not request twice'),
      capture: (_) async {
        captured++;
        return bytes;
      },
      write_image: (actual, name) async {
        expect(actual, same(bytes));
        expect(name, 'test');
        written++;
      },
    );
    expect(
      await approved.save(
        boundary_key: GlobalKey(),
        image_name: 'test',
        is_current: () => false,
      ),
      PosterSaveResult.unavailable,
    );
    expect(written, 0);
    expect(
      await approved.save(boundary_key: GlobalKey(), image_name: 'test'),
      PosterSaveResult.saved,
    );
    expect(captured, 1);
    expect(written, 1);
  });

  test('截图缺失和相册写入失败不伪装成功', () async {
    final missing = PosterExportService(
      has_access: () async => true,
      request_access: () async => true,
      capture: (_) async => null,
      write_image: (_, _) async => throw StateError('Must not write'),
    );
    expect(
      await missing.save(boundary_key: GlobalKey(), image_name: 'test'),
      PosterSaveResult.failed,
    );
    final failure = PosterExportService(
      has_access: () async => true,
      request_access: () async => true,
      capture: (_) async => Uint8List(1),
      write_image: (_, _) async => throw StateError('disk full'),
    );
    expect(
      await failure.save(boundary_key: GlobalKey(), image_name: 'test'),
      PosterSaveResult.failed,
    );
  });

  testWidgets('无ShareStore也能打开三类公共入口，复制对应真实链接', (tester) async {
    String? copied;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    for (final kind in WorkShareKind.values) {
      await _mount(
        tester,
        ShareSheet(
          novel_id: 42,
          novel_title: 'Title',
          novel_cover_url: '',
          novel_intro: 'Intro',
          work_kind: kind,
          is_dark: false,
          on_close: () {},
        ),
      );
      expect(
        find.byKey(const ValueKey('share_channel_generate_image')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('share_channel_copy_link')),
        findsOneWidget,
      );
      for (final platform in ['whatsapp', 'x', 'telegram']) {
        expect(find.byKey(ValueKey('share_channel_$platform')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('share_channel_copy_link')));
      await tester.pump();
      expect(copied, share_work_url(work_id: 42, work_kind: kind).toString());
      expect(find.text('Link copied'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('海报导出真实PNG且二维码正确指向漫画，截图仅含固定海报区域', (tester) async {
    final key = GlobalKey();
    await _mount(
      tester,
      Center(
        child: RepaintBoundary(
          key: key,
          child: SharePosterCard(
            novel_id: 42,
            novel_title: 'Title',
            novel_author: 'Author',
            novel_cover_url: '',
            novel_intro: 'Intro',
            work_kind: WorkShareKind.comic,
            language: 'en',
            user_avatar_url: '',
            user_nickname: 'Reader',
            date_text: '2026.10.26',
            fallback_avatar_index: 2,
            canvas_colors: ShareSheetStyle.card_gradient_colors.first,
            accent_color: ShareSheetStyle.card_accent_colors.first,
            footer_color: ShareSheetStyle.card_footer_colors.first,
          ),
        ),
      ),
    );
    expect(
      tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel,
      contains(
        share_work_url(
          work_id: 42,
          work_kind: WorkShareKind.comic,
          language: 'en',
        ).toString(),
      ),
    );
    final future = capture_share_poster(key);
    await tester.pump();
    final bytes = await tester.runAsync(() => future);
    expect(bytes, isNotNull);
    expect(bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final header = ByteData.sublistView(bytes);
    expect(header.getUint32(16), 1026);
    expect(header.getUint32(20), 1314);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击保存按钮完成PNG截图并交给图库插件，测试只使用mock相册', (tester) async {
    var writes = 0;
    Uint8List? written;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('gal'), (call) async {
          if (call.method == 'hasAccess' || call.method == 'requestAccess') {
            return true;
          }
          if (call.method == 'putImageBytes') {
            writes++;
            written = (call.arguments as Map)['bytes'] as Uint8List;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('gal'), null),
    );
    await _mount(
      tester,
      const CardPreviewSheet(
        novel_id: 42,
        novel_title: 'Title',
        novel_cover_url: '',
        novel_intro: 'Intro',
        is_dark: false,
      ),
    );
    final save = find.text('Save to Gallery');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 40 && writes == 0; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pump();
    expect(writes, 1);
    expect(written!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(find.text('Saved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(466, 678),
  ]) {
    testWidgets('公共入口和海报预览在 $size 大字夜间可滚动且不溢出', (tester) async {
      await _mount(
        tester,
        ShareSheet(
          novel_id: 42,
          novel_title: 'Title',
          novel_cover_url: '',
          novel_intro: 'Intro',
          is_dark: true,
          on_close: () {},
        ),
        size: size,
        scale: 2,
        dark: true,
      );
      expect(tester.takeException(), isNull);
      await _mount(
        tester,
        const CardPreviewSheet(
          novel_id: 42,
          novel_title: 'A long title to validate resizing',
          novel_cover_url: '',
          novel_intro: 'Intro',
          is_dark: true,
        ),
        size: size,
        scale: 2,
        dark: true,
      );
      expect(find.byType(SharePosterCard), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('普通海报按内容收拢高度，底部仅保留一次安全区', (tester) async {
    await _mount(
      tester,
      const CardPreviewSheet(
        novel_id: 42,
        novel_title: 'Title',
        novel_cover_url: '',
        novel_intro: 'Intro',
        is_dark: false,
      ),
      size: const Size(390, 1200),
    );
    final sheet = find.byType(CardPreviewSheet);
    expect(tester.getSize(sheet).height, lessThan(1200 * 0.9));
    expect(
      tester.getBottomLeft(sheet).dy -
          tester.getBottomLeft(find.text('Save to Gallery')).dy,
      lessThan(70),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
