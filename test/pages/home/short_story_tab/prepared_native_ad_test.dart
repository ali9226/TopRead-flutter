// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:app/models/ad_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/widgets/prepared_short_story_native_ad.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/widgets/short_story_native_ad_card.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/short_story_tab_ad_config_service.dart';
import 'package:app/services/short_story_tab_ad_pool.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as ads_sdk;
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';

/// 保留真实 SDK 广告对象及事件分发，只替换网络和 iOS 平台视图通道。
class _AdPlatform {
  static const layout_channel = MethodChannel(
    'com.topread.novel/short_story_native_ad_layout',
  );
  final List<NativeAd> loads = [];
  final List<NativeAd> disposals = [];
  final List<int> created_views = [];
  final Map<int, NativeAd> _ads = {};
  bool complete_immediately = false;

  _AdPlatform() {
    ads_sdk.instanceManager = ads_sdk.AdInstanceManager(
      'test.short_story_tab.ads',
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
        final id = call.arguments['adId'] as int;
        final ad = ads_sdk.instanceManager.adFor(id)! as NativeAd;
        _ads[id] = ad;
        loads.add(ad);
        if (complete_immediately) {
          await measure(ad, 250);
          await loaded(ad);
        }
      }
      if (call.method == 'disposeAd') {
        final ad = _ads[call.arguments['adId']];
        if (ad != null) disposals.add(ad);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create')
        created_views.add(call.arguments['id'] as int);
      return null;
    });
  }

  Future<void> loaded(NativeAd ad) async {
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
    ads_sdk.instanceManager.channel.setMethodCallHandler(null);
    messenger.setMockMethodCallHandler(ads_sdk.instanceManager.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
  }
}

class _ConsentInformation implements ConsentInformation {
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
    OnConsentInfoUpdateSuccessListener success,
    OnConsentInfoUpdateFailureListener failure,
  ) => scheduleMicrotask(success);
  @override
  Future<void> reset() async {}
}

class _MessagingChannel extends UserMessagingChannel {
  _MessagingChannel() : super(const MethodChannel('test.short_story_tab.ump'));
  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() async => null;
  @override
  Future<FormError?> showPrivacyOptionsForm() async => null;
}

Future<void> _flush(WidgetTester tester) async {
  for (int frame = 0; frame < 4; frame++) {
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pump();
}

/// 使用真实 ListView cacheExtent，页面保存尺寸与跳过决策，item 可正常回收。
Future<void> _pump_list(
  WidgetTester tester,
  ScrollController controller, {
  VoidCallback? on_skipped,
}) async {
  double reserved_extent = 0;
  bool skipped = false;
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: 500,
          child: ListView.builder(
            controller: controller,
            cacheExtent: 1000,
            itemCount: 10,
            itemBuilder: (context, index) {
              if (index == 3) {
                if (skipped)
                  return const SizedBox.shrink(key: ValueKey('ad-slot'));
                return PreparedShortStoryNativeAd(
                  key: const ValueKey('ad-slot'),
                  slot_id: 'test-slot',
                  is_dark: false,
                  scroll_controller: controller,
                  initial_reserved_extent: reserved_extent,
                  on_extent_changed: (extent) => reserved_extent = extent,
                  on_skipped: () {
                    skipped = true;
                    on_skipped?.call();
                  },
                );
              }
              return SizedBox(key: ValueKey(index), height: 300);
            },
          ),
        ),
      ),
    ),
  );
  await _flush(tester);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final original_manager = ads_sdk.instanceManager;
  final original_consent = ConsentInformation.instance;
  final original_ump = UserMessagingChannel.instance;
  late _AdPlatform platform;
  late ProjectConfigStore config;

  Future<void> set_up() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Get.testMode = true;
    platform = _AdPlatform();
    config = Get.put(ProjectConfigStore());
    config.save_config(ProjectConfig.from_json({'ads_switch': SwitchValue.on}));
    ShortStoryTabAdConfigService.set_fetcher_for_test(
      () async => AdConfig(
        id: 'short-story-config',
        adsId: 'test-unit',
        showNumber: 0,
        notificationNumber: 0,
        adsType: 18,
        advertisers: 1,
        weight: 100,
        adsTypeStr: '',
        advertisersStr: '',
        uuid: 'test-config',
      ),
    );
    ConsentInformation.instance = _ConsentInformation();
    UserMessagingChannel.instance = _MessagingChannel();
    AdMobConsentPermissionRequest.reset_for_test();
    await AdMobConsentPermissionRequest.initialize_on_app_start();
    await GoogleMobileAdsUtil.instance.ensure_initialized();
  }

  void test_ad(String description, WidgetTesterCallback callback) {
    testWidgets(description, (tester) async {
      await tester.runAsync(set_up);
      try {
        await callback(tester);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        ShortStoryTabAdPool.remove_all(['test-slot']);
        await _flush(tester);
        await tester.runAsync(() async {
          Get.reset();
          ShortStoryTabAdConfigService.reset_for_test();
          await platform.dispose();
          ads_sdk.instanceManager = original_manager;
          ConsentInformation.instance = original_consent;
          UserMessagingChannel.instance = original_ump;
          AdMobConsentPermissionRequest.reset_for_test();
        });
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  test_ad('素材与等高原生测量都到达才插位，cacheExtent 不提前挂载平台视图', (tester) async {
    final scroll = ScrollController();
    await _pump_list(tester, scroll);
    final ad = platform.loads.single;
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ad-slot'), skipOffstage: false))
          .height,
      0,
    );
    await platform.loaded(ad);
    await _flush(tester);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ad-slot'), skipOffstage: false))
          .height,
      0,
    );
    expect(platform.created_views, isEmpty);
    await platform.measure(ad, short_story_tab_ad_fallback_height);
    await _flush(tester);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ad-slot'), skipOffstage: false))
          .height,
      260,
    );
    expect(find.byType(AdWidget), findsNothing);
    scroll.jumpTo(450);
    await _flush(tester);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(ad));
    expect(platform.created_views, hasLength(1));
  });

  test_ad('读者先经过边界时永久跳过，晚到素材和反向滚动均不挤动内容', (tester) async {
    final scroll = ScrollController();
    int skipped = 0;
    await _pump_list(tester, scroll, on_skipped: () => skipped++);
    final ad = platform.loads.single;
    scroll.jumpTo(850);
    await _flush(tester);
    expect(skipped, 1);
    await platform.measure(ad, 250);
    await platform.loaded(ad);
    await _flush(tester);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ad-slot'), skipOffstage: false))
          .height,
      0,
    );
    scroll.jumpTo(2200);
    await _flush(tester);
    scroll.jumpTo(0);
    await _flush(tester);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ad-slot'), skipOffstage: false))
          .height,
      0,
    );
    expect(platform.created_views, isEmpty);
    expect(platform.loads, hasLength(1));
    expect(skipped, 1);
  });

  test_ad('加载失败不留下广告骨架和卡片间距', (tester) async {
    final scroll = ScrollController();
    await _pump_list(tester, scroll);
    final initial_extent = scroll.position.maxScrollExtent;
    final ad = platform.loads.single;
    ad.listener.onAdFailedToLoad!(ad, LoadAdError(3, 'test', 'no fill', null));
    await _flush(tester);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ad-slot'), skipOffstage: false))
          .height,
      0,
    );
    expect(scroll.position.maxScrollExtent, initial_extent);
    expect(platform.created_views, isEmpty);
  });

  test_ad('已提交广告经 lazy 列表回收后复用同一素材并恢复已提交布局', (tester) async {
    final scroll = ScrollController();
    await _pump_list(tester, scroll);
    final ad = platform.loads.single;
    await platform.measure(ad, 250);
    await platform.loaded(ad);
    await _flush(tester);
    scroll.jumpTo(450);
    await _flush(tester);
    scroll.jumpTo(2200);
    await _flush(tester);
    scroll.jumpTo(450);
    await _flush(tester);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(ad));
    expect(platform.loads, hasLength(1));
    expect(platform.created_views, hasLength(2));
  });

  test_ad('隐私更新后的新素材不得沿用上一代次的测量和挂载许可', (tester) async {
    final scroll = ScrollController();
    await _pump_list(tester, scroll);
    final first_ad = platform.loads.single;
    await platform.measure(first_ad, 250);
    await platform.loaded(first_ad);
    await _flush(tester);
    scroll.jumpTo(450);
    await _flush(tester);
    await tester.runAsync(
      AdMobConsentPermissionRequest.show_privacy_options_form,
    );
    await _flush(tester);
    expect(platform.loads, hasLength(2));
    final next_ad = platform.loads.last;
    await platform.loaded(next_ad);
    await _flush(tester);
    expect(find.byType(AdWidget), findsNothing);
    await platform.measure(first_ad, 250);
    await _flush(tester);
    expect(find.byType(AdWidget), findsNothing);
    await platform.measure(next_ad, 250);
    await _flush(tester);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(next_ad));
  });

  test_ad('同一槽位只允许一个 AdWidget，卸载后下一张卡片可以接管', (tester) async {
    Widget card(String key) => ShortStoryNativeAdCard(
      key: ValueKey(key),
      slot_id: 'test-slot',
      is_dark: false,
      attach_ad: true,
      reserve_space: true,
      on_load_status_changed: (_) {},
      on_layout_height_changed: (_) {},
      on_ad_attached: () {},
    );
    Widget frame(bool include_first) => MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: Column(
            children: [if (include_first) card('first'), card('second')],
          ),
        ),
      ),
    );
    await tester.pumpWidget(frame(true));
    await _flush(tester);
    final ad = platform.loads.single;
    await platform.measure(ad, 250);
    await platform.loaded(ad);
    await _flush(tester);
    expect(find.byType(AdWidget), findsOneWidget);
    await tester.pumpWidget(frame(false));
    await _flush(tester);
    expect(find.byType(AdWidget), findsOneWidget);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(ad));
    expect(platform.loads, hasLength(1));
  });

  test_ad('屏外隐私重载即使 loaded 和测量同帧到达，也不能复用旧挂载许可', (tester) async {
    final scroll = ScrollController();
    await _pump_list(tester, scroll);
    final first_ad = platform.loads.single;
    await platform.measure(first_ad, 250);
    await platform.loaded(first_ad);
    await _flush(tester);
    scroll.jumpTo(450);
    await _flush(tester);
    expect(platform.created_views, hasLength(1));
    scroll.jumpTo(1500);
    await _flush(tester);
    platform.complete_immediately = true;
    await tester.runAsync(
      AdMobConsentPermissionRequest.show_privacy_options_form,
    );
    await _flush(tester);
    expect(platform.loads, hasLength(2));
    expect(platform.created_views, hasLength(1));
    expect(find.byType(AdWidget, skipOffstage: false), findsNothing);
    scroll.jumpTo(450);
    await _flush(tester);
    expect(
      tester.widget<AdWidget>(find.byType(AdWidget)).ad,
      same(platform.loads.last),
    );
    expect(platform.created_views, hasLength(2));
  });

  test_ad('广告开关关闭立即卸载平台视图，在屏外安全收回已提交高度', (tester) async {
    final scroll = ScrollController();
    await _pump_list(tester, scroll);
    final ad = platform.loads.single;
    await platform.measure(ad, 250);
    await platform.loaded(ad);
    await _flush(tester);
    scroll.jumpTo(450);
    await _flush(tester);
    final double extent = scroll.position.maxScrollExtent;
    config.save_config(
      ProjectConfig.from_json({'ads_switch': SwitchValue.off}),
    );
    await _flush(tester);
    expect(find.byType(AdWidget, skipOffstage: false), findsNothing);
    expect(scroll.position.maxScrollExtent, extent);
    scroll.jumpTo(1500);
    await _flush(tester);
    // ListView 的 maxScrollExtent 会按已构建项估算，验证实际广告位与补偿位置。
    expect(
      tester
          .getSize(find.byKey(const ValueKey('ad-slot'), skipOffstage: false))
          .height,
      0,
    );
    expect(scroll.offset, 1240);
    expect(platform.disposals, contains(ad));
  });
}
