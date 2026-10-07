// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/components/inline_native_ad/style.dart';
import 'package:app/models/project_config.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/stores/device_info.dart';
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

/// 测试只需要主题状态，不启动真实网络监听。
class _ReaderDeviceInfo extends DeviceInfo {
  @override
  // ignore: must_call_super
  void onInit() {}
}

/// 使用 SDK 的真实广告对象，仅替换加载、释放和原生布局消息通道。
class _NativeAdPlatform {
  static const MethodChannel layout_channel = MethodChannel(
    'com.topread.novel/short_story_native_ad_layout',
  );

  final List<NativeAd> loads = [];
  final List<NativeAd> disposals = [];
  final List<int> created_platform_views = [];
  final Map<int, NativeAd> _ads = {};

  _NativeAdPlatform() {
    ads_sdk.instanceManager = ads_sdk.AdInstanceManager(
      'test.reader.native_ad',
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
  _ReaderMessagingChannel() : super(const MethodChannel('test.reader.ump'));

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

Future<void> _pump_banner(
  WidgetTester tester, {
  double width = 400,
  String uuid = 'current-config',
  String ad_unit_id = 'current-unit',
  ValueChanged<double>? on_layout_height_changed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          child: NativeAdBanner(
            key: const ValueKey('native_banner'),
            ad_unit_id: ad_unit_id,
            uuid: uuid,
            show_continue_hint: false,
            on_layout_height_changed: on_layout_height_changed,
          ),
        ),
      ),
    ),
  );
  await _flush_requests(tester);
}

/// 用真实预加载槽位验证多个未完成请求之间不会沿用旧素材测量。
Future<void> _pump_prepared_banner(
  WidgetTester tester, {
  required ScrollController controller,
  required List<NativeAdLoadStatus> statuses,
  double width = 400,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          height: 500,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 900),
                PreparedNativeAdSlot(
                  key: const ValueKey('prepared_native_banner'),
                  scroll_controller: controller,
                  builder:
                      (
                        context, {
                        required attach_ad,
                        required reserve_space,
                        required on_load_status_changed,
                        required on_layout_height_changed,
                        required on_ad_attached,
                      }) => NativeAdBanner(
                        ad_unit_id: 'current-unit',
                        uuid: 'current-config',
                        attach_ad: attach_ad,
                        reserve_space: reserve_space,
                        show_placeholder: false,
                        show_continue_hint: false,
                        on_load_status_changed: (status) {
                          statuses.add(status);
                          on_load_status_changed(status);
                        },
                        on_layout_height_changed: on_layout_height_changed,
                        on_ad_attached: on_ad_attached,
                      ),
                ),
                const SizedBox(height: 1400),
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
  late DeviceInfo device;

  Future<void> set_up() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    Get.testMode = true;
    platform = _NativeAdPlatform();
    device = Get.put<DeviceInfo>(_ReaderDeviceInfo());
    Get.put(
      ProjectConfigStore(),
    ).save_config(ProjectConfig.from_json({'ads_switch': SwitchValue.on}));
    ConsentInformation.instance = _ReaderConsentInformation();
    UserMessagingChannel.instance = _ReaderMessagingChannel();
    AdMobConsentPermissionRequest.reset_for_test();
    await AdMobConsentPermissionRequest.initialize_on_app_start();
    await GoogleMobileAdsUtil.instance.ensure_initialized();
  }

  void test_native_ad(String description, WidgetTesterCallback callback) {
    testWidgets(description, (tester) async {
      await tester.runAsync(set_up);
      try {
        await callback(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush_requests(tester);
        await tester.runAsync(() async {
          Get.reset();
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

  test_native_ad('已展示广告切换日夜主题保留素材和平台视图，仅更新外层颜色', (tester) async {
    await _pump_banner(tester);
    final ad = platform.loads.single;
    await platform.measure(ad, 250);
    await platform.load_success(ad);
    await _flush_requests(tester);
    final ad_widget = tester.widget<AdWidget>(find.byType(AdWidget));
    expect(ad_widget.ad, same(ad));
    expect(platform.created_platform_views, hasLength(1));
    final Color light_color = tester
        .widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(NativeAdBanner),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;

    device.dark.value = true;
    await _flush_requests(tester);
    final Color dark_color = tester
        .widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(NativeAdBanner),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;
    expect(dark_color, isNot(light_color));
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(ad));
    expect(platform.loads, hasLength(1));
    expect(platform.disposals, isEmpty);
    expect(platform.created_platform_views, hasLength(1));

    device.dark.value = false;
    await _flush_requests(tester);
    expect(platform.loads, hasLength(1));
    expect(platform.disposals, isEmpty);
    expect(platform.created_platform_views, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  test_native_ad('预加载期间切换主题不会丢弃正在请求的素材', (tester) async {
    await _pump_banner(tester);
    final ad = platform.loads.single;
    device.dark.value = true;
    await _flush_requests(tester);
    expect(platform.loads, hasLength(1));
    expect(platform.disposals, isEmpty);
    await platform.measure(ad, 250);
    await platform.load_success(ad);
    await _flush_requests(tester);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(ad));
    expect(tester.takeException(), isNull);
  });

  test_native_ad('真实宽度变化仍重载，测量抖动不会重复请求', (tester) async {
    await _pump_banner(tester);
    final first_ad = platform.loads.single;
    await platform.measure(first_ad, 250);
    await platform.load_success(first_ad);
    await _flush_requests(tester);
    await _pump_banner(tester, width: 400.2);
    expect(platform.loads, hasLength(1));

    await _pump_banner(tester, width: 360);
    expect(platform.loads, hasLength(2));
    expect(platform.disposals, contains(first_ad));
    final next_ad = platform.loads.last;
    expect(next_ad.customOptions!['cardWidth'], 360);
    await platform.measure(next_ad, 280);
    await platform.load_success(next_ad);
    await _flush_requests(tester);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(next_ad));
    expect(tester.takeException(), isNull);
  });

  test_native_ad('配置身份或广告单元变化仍释放旧素材并重新请求', (tester) async {
    await _pump_banner(tester);
    final first_ad = platform.loads.single;
    await _pump_banner(tester, uuid: 'next-config');
    expect(platform.loads, hasLength(2));
    expect(platform.disposals, contains(first_ad));
    final second_ad = platform.loads.last;
    await _pump_banner(tester, uuid: 'next-config', ad_unit_id: 'next-unit');
    expect(platform.loads, hasLength(3));
    expect(platform.disposals, contains(second_ad));
    expect(platform.loads.last.adUnitId, 'next-unit');
    expect(tester.takeException(), isNull);
  });

  test_native_ad('隐私选择更新仍重载，并拒绝旧素材迟到的尺寸回调', (tester) async {
    final heights = <double>[];
    await _pump_banner(tester, on_layout_height_changed: heights.add);
    final first_ad = platform.loads.single;
    await platform.measure(first_ad, 250);
    await platform.load_success(first_ad);
    await _flush_requests(tester);

    final bool? did_update = await tester.runAsync(
      AdMobConsentPermissionRequest.show_privacy_options_form,
    );
    expect(did_update, isTrue);
    await _flush_requests(tester);
    expect(platform.loads, hasLength(2));
    expect(platform.disposals, contains(first_ad));
    final next_ad = platform.loads.last;
    await platform.measure(first_ad, 999);
    await platform.measure(next_ad, 300);
    await platform.load_success(next_ad);
    await _flush_requests(tester);
    expect(heights, [250, 300]);
    expect(tester.widget<AdWidget>(find.byType(AdWidget)).ad, same(next_ad));
    expect(tester.takeException(), isNull);
  });

  test_native_ad('未完成请求连续重载会再次通知 loading，新素材必须等待自己的测量', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final statuses = <NativeAdLoadStatus>[];
    final slot = find.byKey(const ValueKey('prepared_native_banner'));
    await _pump_prepared_banner(
      tester,
      controller: controller,
      statuses: statuses,
    );
    final first_ad = platform.loads.single;

    // 第一次工厂已测量，但 SDK loaded 事件尚未到达，此时仍不提交高度。
    await platform.measure(first_ad, 350);
    await _flush_requests(tester);
    expect(statuses, [NativeAdLoadStatus.loading]);
    expect(tester.getSize(slot).height, 0);

    // 宽度变化发起第二次请求，即使状态仍为 loading，也必须清除旧尺寸。
    await _pump_prepared_banner(
      tester,
      controller: controller,
      statuses: statuses,
      width: 360,
    );
    expect(platform.loads, hasLength(2));
    expect(statuses, [NativeAdLoadStatus.loading, NativeAdLoadStatus.loading]);
    final next_ad = platform.loads.last;
    await platform.load_success(next_ad);
    await _flush_requests(tester);
    expect(tester.getSize(slot).height, 0);
    expect(find.byType(AdWidget), findsNothing);

    // loaded 本身不能复用第一次测量；新代次的真实高度到达后才提交广告位。
    await platform.measure(first_ad, 999);
    await _flush_requests(tester);
    expect(tester.getSize(slot).height, 0);
    await platform.measure(next_ad, 250);
    await _flush_requests(tester);
    expect(
      tester.getSize(slot).height,
      InlineNativeAdStyle.spacing_top +
          250 +
          InlineNativeAdStyle.spacing_bottom,
    );
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
