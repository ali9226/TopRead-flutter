// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/components/recommend_book_card/animated_waterfall.dart';
import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/components/recommend_book_card/widgets/masonry_native_ad_card.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/masonry_ad_config_service.dart';
import 'package:app/services/masonry_native_ad_pool.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/recommend_waterfall_store.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as ads_sdk;
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';

/// 会话集成测试不读取首页本地缓存或启动后台工作。
class _WaterfallHomeStore extends HomeBannerStore {
  @override
  // ignore: must_call_super
  void onInit() {}
}

/// 保留封面真实 Widget 与尺寸，只把图片缓存流替换成不联网的空流。
class _WaterfallCoverCache extends BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WaterfallAssetLoader extends AssetLoader {
  const _WaterfallAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'bookshelf': {
      'load_more': {'no_more': 'No more books'},
    },
    'recommend_card': {'advertisement': 'Ad', 'dislike': 'Dislike'},
  };
}

/// 预填会话，不触发推荐接口；封面尺寸明确且 URL 为空，不请求图片。
RecommendWaterfallSession _create_waterfall_session() {
  Get.put<HomeBannerStore>(_WaterfallHomeStore());
  final session = Get.put(RecommendWaterfallStore()).obtain('widget-waterfall');
  session
    ..has_initialized = true
    ..is_initial_loading = false
    ..has_more = false
    ..language_revision = LanguageChangeHandler.current_revision;
  for (int index = 0; index < 24; index++) {
    if (index == 12) {
      session.items.add(BookListItem.ad_slot(id: 'widget-test-slot'));
      session.item_heights['widget-test-slot'] = 0;
    }
    final id = 'waterfall-book-$index';
    session.items.add(
      BookListItem(
        id: id,
        story_id: index + 1,
        type: BookListItemType.book,
        title: 'Book $index',
        description: '',
        cover_url: '',
        cover_width: 156,
        cover_height: 120,
        cover_badge: '',
        cover_meta_text: '',
        tag_list: const [],
        ad_image_url_list: const [],
      ),
    );
    session.item_heights[id] = RecommendBookCardStyle.default_card_height;
  }
  return session;
}

Future<void> _pump_waterfall(
  WidgetTester tester, {
  required ScrollController controller,
  double width = 320,
  bool flush = true,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      startLocale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      path: 'assets/i18n',
      assetLoader: const _WaterfallAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 500,
              child: SingleChildScrollView(
                controller: controller,
                child: AnimatedRecommendWaterfall(
                  waterfall_id: 'widget-waterfall',
                  is_dark: false,
                  scroll_controller: controller,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (flush) {
    await _flush_requests(tester);
    await tester.pump(
      const Duration(
        milliseconds: RecommendBookCardStyle.reorder_animation_duration_ms,
      ),
    );
    await _flush_requests(tester);
  }
}

/// 使用 SDK 的真实广告对象，仅替换加载、释放和原生布局消息通道。
class _NativeAdPlatform {
  static const MethodChannel layout_channel = MethodChannel(
    'com.topread.novel/masonry_native_ad_layout',
  );

  final List<NativeAd> loads = [];
  final List<NativeAd> disposals = [];
  final List<int> created_platform_views = [];
  final Map<int, NativeAd> _ads = {};

  _NativeAdPlatform() {
    ads_sdk.instanceManager = ads_sdk.AdInstanceManager(
      'test.masonry.native_ad',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ads_sdk.instanceManager.channel, (
      call,
    ) async {
      if (call.method == 'MobileAds#initialize') {
        return InitializationStatus(<String, AdapterStatus>{});
      }
      if (call.method == 'loadNativeAd') {
        final int ad_id = call.arguments['adId'] as int;
        final NativeAd ad = ads_sdk.instanceManager.adFor(ad_id)! as NativeAd;
        _ads[ad_id] = ad;
        loads.add(ad);
      }
      if (call.method == 'disposeAd') {
        final NativeAd? ad = _ads[call.arguments['adId']];
        if (ad != null) disposals.add(ad);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(layout_channel, (_) async => false);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        created_platform_views.add(call.arguments['id'] as int);
      }
      return null;
    });
  }

  /// 从 SDK 事件入口完成指定素材，保留真实的代次和对象身份判断。
  Future<void> load_success(NativeAd ad) async {
    final channel = ads_sdk.instanceManager.channel;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            MethodCall('onAdEvent', {
              'adId': _ads.entries
                  .singleWhere((entry) => identical(entry.value, ad))
                  .key,
              'eventName': 'onAdLoaded',
            }),
          ),
          null,
        );
  }

  /// 原生工厂可以在 AdWidget 挂载前回报尺寸。
  Future<void> measure(NativeAd ad, double height) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          layout_channel.name,
          layout_channel.codec.encodeMethodCall(
            MethodCall('onNativeAdLayout', {
              'slotId': ad.customOptions!['slotId'],
              'layoutToken': ad.customOptions!['layoutToken'],
              'viewHeight': height,
            }),
          ),
          null,
        );
  }

  Future<void> dispose() async {
    for (final ad in _ads.values) {
      await ad.dispose();
    }
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final channel = ads_sdk.instanceManager.channel;
    channel.setMethodCallHandler(null);
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(layout_channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
  }
}

/// 已取得 UMP 许可，生命周期测试无需展示真实表单。
class _ReaderConsentInformation implements ConsentInformation {
  @override
  Future<bool> canRequestAds() async => true;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) => scheduleMicrotask(successListener);

  @override
  Future<void> reset() async {}
}

class _ReaderMessagingChannel extends UserMessagingChannel {
  _ReaderMessagingChannel() : super(const MethodChannel('test.masonry.ump'));

  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() async => null;

  @override
  Future<FormError?> showPrivacyOptionsForm() async => null;
}

/// 推进布局和 UMP 的真实异步 Future，避免跨测试共享 fake async Future。
Future<void> _flush_requests(WidgetTester tester) async {
  for (int round = 0; round < 3; round++) {
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pump();
}

/// 零高度锚点始终位于第 900 像素，便于精确验证插位与可见性。
Future<void> _pump_card(
  WidgetTester tester, {
  required ScrollController controller,
  bool is_dark = false,
  double? initial_reserved_extent,
  VoidCallback? on_skipped,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 320,
          height: 500,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 900),
                MasonryNativeAdCard(
                  key: const ValueKey('masonry_card'),
                  slot_id: 'widget-test-slot',
                  is_dark: is_dark,
                  scroll_controller: controller,
                  initial_reserved_extent: initial_reserved_extent,
                  on_skipped: on_skipped,
                ),
                const SizedBox(key: ValueKey('after_ad_content'), height: 1400),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await _flush_requests(tester);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final original_ad_manager = ads_sdk.instanceManager;
  final original_consent = ConsentInformation.instance;
  final original_ump = UserMessagingChannel.instance;
  late _NativeAdPlatform platform;
  final slot = find.byType(PreparedNativeAdSlot);

  setUpAll(() async {
    CachedNetworkImageProvider.defaultCacheManager = _WaterfallCoverCache();
    const preferences_channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences_channel, (call) async {
          return call.method == 'getAll' ? <String, Object>{} : true;
        });
    await EasyLocalization.ensureInitialized();
  });

  Future<void> set_up() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Get.testMode = true;
    platform = _NativeAdPlatform();
    Get.put(
      ProjectConfigStore(),
    ).save_config(ProjectConfig.from_json({'ads_switch': SwitchValue.on}));
    MasonryAdConfigService.set_fetcher_for_test(
      () async => AdConfig(
        id: 'masonry-config',
        adsId: 'masonry-ad-unit',
        showNumber: 0,
        notificationNumber: 0,
        adsType: 15,
        advertisers: 1,
        weight: 100,
        adsTypeStr: '',
        advertisersStr: '',
        uuid: 'masonry-config-uuid',
      ),
    );
    ConsentInformation.instance = _ReaderConsentInformation();
    UserMessagingChannel.instance = _ReaderMessagingChannel();
    AdMobConsentPermissionRequest.reset_for_test();
    await AdMobConsentPermissionRequest.initialize_on_app_start();
    await GoogleMobileAdsUtil.instance.ensure_initialized();
  }

  void test_card(String description, WidgetTesterCallback callback) {
    testWidgets(description, (tester) async {
      await tester.runAsync(set_up);
      try {
        await callback(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush_requests(tester);
        MasonryNativeAdPool.remove_all(['widget-test-slot']);
        await _flush_requests(tester);
        await tester.runAsync(() async {
          Get.reset();
          MasonryAdConfigService.reset_for_test();
          await platform.dispose();
          ads_sdk.instanceManager = original_ad_manager;
          ConsentInformation.instance = original_consent;
          UserMessagingChannel.instance = original_ump;
          AdMobConsentPermissionRequest.reset_for_test();
        });
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  for (final bool measure_first in [false, true]) {
    test_card('瀑布流${measure_first ? '尺寸' : '素材'}先就绪仍零高度，二者完成后仅在可见处挂载', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pump_card(tester, controller: controller);
      final ad = platform.loads.single;
      expect(ad.factoryId, 'masonryNativeAdCard');
      expect(tester.getSize(slot).height, 0);
      expect(find.byType(AdWidget), findsNothing);

      if (measure_first) {
        await platform.measure(ad, 250);
      } else {
        await platform.load_success(ad);
      }
      await _flush_requests(tester);
      expect(tester.getSize(slot).height, 0);
      expect(platform.created_platform_views, isEmpty);

      if (measure_first) {
        await platform.load_success(ad);
      } else {
        await platform.measure(ad, 250);
      }
      await _flush_requests(tester);
      expect(tester.getSize(slot).height, 250);
      expect(find.byType(AdWidget), findsNothing);
      expect(platform.created_platform_views, isEmpty);

      controller.jumpTo(410);
      await _flush_requests(tester);
      expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(ad));
      expect(platform.created_platform_views, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }

  test_card('瀑布流边界滑过后放弃迟到素材，正文位置与高度保持不变', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    int skipped_count = 0;
    await _pump_card(
      tester,
      controller: controller,
      on_skipped: () => skipped_count += 1,
    );
    final ad = platform.loads.single;
    controller.jumpTo(700);
    await _flush_requests(tester);
    final content = find.byKey(const ValueKey('after_ad_content'));
    final before_position = tester.getTopLeft(content);
    final before_extent = controller.position.maxScrollExtent;
    expect(skipped_count, 1);
    await platform.measure(ad, 250);
    await platform.load_success(ad);
    await _flush_requests(tester);
    expect(tester.getSize(slot).height, 0);
    expect(tester.getTopLeft(content), before_position);
    expect(controller.position.maxScrollExtent, before_extent);
    expect(controller.offset, 700);
    expect(find.byType(AdWidget), findsNothing);
    expect(platform.created_platform_views, isEmpty);
    expect(platform.disposals, contains(ad));
    expect(skipped_count, 1);
    expect(tester.takeException(), isNull);
  });

  test_card('缓存广告与已提交高度在视口中恢复，不折叠或重复请求素材', (tester) async {
    final first_controller = ScrollController();
    addTearDown(first_controller.dispose);
    await _pump_card(tester, controller: first_controller);
    final ad = platform.loads.single;
    await platform.measure(ad, 250);
    await platform.load_success(ad);
    await _flush_requests(tester);
    first_controller.jumpTo(410);
    await _flush_requests(tester);
    expect(find.byType(AdWidget), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _flush_requests(tester);
    final restored_controller = ScrollController(initialScrollOffset: 500);
    addTearDown(restored_controller.dispose);
    await _pump_card(
      tester,
      controller: restored_controller,
      initial_reserved_extent: 250,
    );
    expect(tester.getSize(slot).height, 250);
    expect(restored_controller.offset, 500);
    expect(tester.getTopLeft(slot).dy, 400);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(ad));
    expect(platform.loads, hasLength(1));
    expect(platform.disposals, isEmpty);
    expect(platform.created_platform_views, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  for (final bool change_privacy in [false, true]) {
    test_card('瀑布流${change_privacy ? '隐私' : '主题'}快速重载时，屏外新素材不复用旧挂载批准', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pump_card(tester, controller: controller);
      final old_ad = platform.loads.single;
      await platform.measure(old_ad, 250);
      await platform.load_success(old_ad);
      await _flush_requests(tester);
      controller.jumpTo(410);
      await _flush_requests(tester);
      expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(old_ad));

      // 旧实例已经展示过，快速移回屏外后，重新加载仍必须经过新门禁。
      controller.jumpTo(0);
      if (change_privacy) {
        await tester.runAsync(
          AdMobConsentPermissionRequest.show_privacy_options_form,
        );
      }
      // 故意不给布局帧：新代次在组件首次重建前已经完成加载，无法依赖
      // 中间 loading 帧清理旧批准，必须根据新的代次再次关闭首次挂载门禁。
      await tester.runAsync(() async {
        MasonryNativeAdPool.obtain('widget-test-slot').ensure_loaded(
          card_width: 320,
          is_dark: !change_privacy,
          advertisement_label: 'recommend_card.advertisement',
        );
        for (int round = 0; round < 3; round++) {
          await Future<void>.delayed(Duration.zero);
        }
      });
      expect(platform.loads, hasLength(2));
      final next_ad = platform.loads.last;
      await platform.measure(old_ad, 999);
      // 同一帧前完成两个回调，验证极快加载也不沿用旧实例的批准。
      await platform.measure(next_ad, 250);
      await platform.load_success(next_ad);
      await _pump_card(
        tester,
        controller: controller,
        is_dark: !change_privacy,
      );
      expect(tester.getSize(slot).height, 250);
      expect(find.byType(AdWidget), findsNothing);
      expect(platform.created_platform_views, hasLength(1));
      expect(platform.disposals, contains(old_ad));

      controller.jumpTo(410);
      await _flush_requests(tester);
      expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(next_ad));
      expect(platform.created_platform_views, hasLength(2));
      expect(tester.takeException(), isNull);
    });
  }

  test_card('真实瀑布流下方广告就绪更新会话高度，插入与关闭均保留当前可见书籍位置', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final session = _create_waterfall_session();
    await _pump_waterfall(tester, controller: controller);
    final ad = platform.loads.single;
    final first_book = find.byKey(const ValueKey('waterfall-book-0'));
    final before_position = tester.getTopLeft(first_book);
    expect(session.item_heights['widget-test-slot'], 0);
    expect(tester.getSize(slot).height, 0);

    await platform.measure(ad, 250);
    await platform.load_success(ad);
    await _flush_requests(tester);
    await tester.pump(
      const Duration(
        milliseconds: RecommendBookCardStyle.reorder_animation_duration_ms,
      ),
    );
    await _flush_requests(tester);
    expect(session.item_heights['widget-test-slot'], 250);
    expect(tester.getSize(slot).height, 250);
    expect(tester.getTopLeft(first_book), before_position);
    expect(controller.offset, 0);
    expect(find.byType(AdWidget), findsNothing);

    final ad_top = tester.getTopLeft(slot).dy;
    controller.jumpTo(ad_top - 100);
    await _flush_requests(tester);
    expect(find.byType(AdWidget), findsOneWidget);
    controller.jumpTo(ad_top + 270);
    await _flush_requests(tester);
    final current_book = find.byKey(const ValueKey('waterfall-book-15'));
    final before_disable = tester.getTopLeft(current_book);
    expect(before_disable.dy, inInclusiveRange(0, 500));
    final before_offset = controller.offset;
    Get.find<ProjectConfigStore>().save_config(
      ProjectConfig.from_json({'ads_switch': SwitchValue.off}),
    );
    await _flush_requests(tester);
    await tester.pump(
      const Duration(
        milliseconds: RecommendBookCardStyle.reorder_animation_duration_ms,
      ),
    );
    await _flush_requests(tester);
    expect(session.item_heights['widget-test-slot'], 250);
    expect(tester.getTopLeft(current_book), before_disable);
    expect(controller.offset, before_offset);
    expect(find.byType(AdWidget), findsNothing);
    expect(platform.disposals, contains(ad));
    expect(tester.takeException(), isNull);
  });

  test_card('真实瀑布流宽度变化撤销尚未落地的插位，构建期缓存回调安全延后', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final session = _create_waterfall_session();
    await _pump_waterfall(tester, controller: controller);
    final ad = platform.loads.single;
    await platform.measure(ad, 250);
    await platform.load_success(ad);

    // 仅推进到帧末的插位批准，下一帧尚未把 250 写入实际渲染布局。
    for (int frame = 0; frame < 8; frame++) {
      if (session.item_heights['widget-test-slot'] == 250) break;
      await tester.pump();
    }
    expect(session.item_heights['widget-test-slot'], 250);
    expect(tester.getSize(slot).height, 0);

    // LayoutBuilder 改列宽会在 didUpdateWidget 中撤销刚才的批准。
    await _pump_waterfall(
      tester,
      controller: controller,
      width: 300,
      flush: false,
    );
    expect(tester.takeException(), isNull);
    await _flush_requests(tester);
    expect(find.byType(AdWidget), findsNothing);
    // 父级按 AnimatedPositioned 平滑调整列宽，完成后素材才因真实宽度重载。
    await tester.pump(
      const Duration(
        milliseconds: RecommendBookCardStyle.reorder_animation_duration_ms,
      ),
    );
    await _flush_requests(tester);
    expect(platform.loads, hasLength(2));
    expect(platform.disposals, contains(ad));

    final next_ad = platform.loads.last;
    await platform.measure(next_ad, 280);
    await platform.load_success(next_ad);
    await _flush_requests(tester);
    expect(session.item_heights['widget-test-slot'], 280);
    expect(tester.getSize(slot).height, 280);
    expect(controller.offset, 0);
    expect(tester.takeException(), isNull);
  });
}
