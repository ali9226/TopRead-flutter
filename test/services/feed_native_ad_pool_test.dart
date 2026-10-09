// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/ad_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/feed_native_ad_policy.dart';
import 'package:app/services/masonry_ad_config_service.dart';
import 'package:app/services/masonry_native_ad_pool.dart';
import 'package:app/services/short_story_tab_ad_config_service.dart';
import 'package:app/services/short_story_tab_ad_pool.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as ads_sdk;
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';

/// 测试仍使用真实 NativeAd 和 SDK 事件分发，只替换原生消息收发。
class _AdPlatform {
  final List<NativeAd> loads = [];
  final List<NativeAd> disposals = [];
  final Map<int, NativeAd> ads = {};
  Completer<void>? load_gate;
  bool throw_on_load = false;

  _AdPlatform() {
    ads_sdk.instanceManager = ads_sdk.AdInstanceManager('test.feed.ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ads_sdk.instanceManager.channel, (
          call,
        ) async {
          if (call.method == 'MobileAds#initialize') {
            return InitializationStatus(<String, AdapterStatus>{});
          }
          if (call.method == 'loadNativeAd') {
            final id = call.arguments['adId'] as int;
            final ad = ads_sdk.instanceManager.adFor(id)! as NativeAd;
            ads[id] = ad;
            loads.add(ad);
            if (throw_on_load) {
              throw PlatformException(code: 'load_failed');
            }
            await load_gate?.future;
          }
          if (call.method == 'disposeAd') {
            final ad = ads[call.arguments['adId']];
            if (ad != null) disposals.add(ad);
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.topread.novel/short_story_native_ad_layout'),
          (_) async => null,
        );
  }

  Future<void> event(NativeAd ad, String event_name) async {
    final channel = ads_sdk.instanceManager.channel;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            MethodCall('onAdEvent', {
              'adId': ads.entries
                  .singleWhere((e) => identical(e.value, ad))
                  .key,
              'eventName': event_name,
              if (event_name == 'onAdFailedToLoad')
                'loadAdError': LoadAdError(0, 'test', 'failed', null),
            }),
          ),
          null,
        );
  }

  Future<void> measure(
    NativeAd ad,
    double height, {
    required bool is_short,
  }) async {
    final channel = MethodChannel(
      is_short
          ? 'com.topread.novel/short_story_native_ad_layout'
          : 'com.topread.novel/masonry_native_ad_layout',
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
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
    for (final ad in ads.values) {
      await ad.dispose();
    }
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    ads_sdk.instanceManager.channel.setMethodCallHandler(null);
    messenger.setMockMethodCallHandler(ads_sdk.instanceManager.channel, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.topread.novel/short_story_native_ad_layout'),
      null,
    );
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
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) => scheduleMicrotask(successListener);
  @override
  Future<void> reset() async {}
}

class _MessagingChannel extends UserMessagingChannel {
  _MessagingChannel() : super(const MethodChannel('test.feed.ump'));
  Completer<void>? privacy_form_gate;
  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() async {
    await privacy_form_gate?.future;
    return null;
  }

  @override
  Future<FormError?> showPrivacyOptionsForm() async => null;
}

/// 两个实际 controller 共用行为用例；适配器只代理公开状态与动作。
class _Controller {
  final ChangeNotifier notifier;
  final NativeAd? Function() current_ad;
  final double Function() height;
  final bool Function() measured;
  final bool Function() failed;
  final bool Function() loading;
  final void Function({
    required double card_width,
    required bool is_dark,
    required String advertisement_label,
  })
  request;
  final bool Function(Object) claim;
  final void Function(Object) release;

  _Controller.masonry(MasonryNativeAdController controller)
    : notifier = controller,
      current_ad = (() => controller.native_ad),
      height = (() => controller.native_view_height),
      measured = (() => controller.layout_is_measured),
      failed = (() => controller.is_failed),
      loading = (() => controller.is_loading),
      request = controller.ensure_loaded,
      claim = controller.claim_attachment,
      release = controller.release_attachment;

  _Controller.short(ShortStoryTabAdController controller)
    : notifier = controller,
      current_ad = (() => controller.native_ad),
      height = (() => controller.native_view_height),
      measured = (() => controller.layout_is_measured),
      failed = (() => controller.is_failed),
      loading = (() => controller.is_loading),
      request = controller.ensure_loaded,
      claim = controller.claim_attachment,
      release = controller.release_attachment;

  void ensure({double width = 400, bool is_dark = false}) =>
      request(card_width: width, is_dark: is_dark, advertisement_label: 'Ad');
}

AdConfig _config({String uuid = 'one', String unit = 'unit'}) =>
    AdConfig.fromJson({
      'id': 'configuration',
      'ads_id': unit,
      'uuid': uuid,
      'advertisers': 1,
      'weight': 1,
      'ads_type': 9,
    });

Future<void> _flush(WidgetTester tester) async {
  for (int round = 0; round < 3; round++) {
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pump();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final original_ad_manager = ads_sdk.instanceManager;
  final original_consent = ConsentInformation.instance;
  final original_messaging = UserMessagingChannel.instance;
  late _AdPlatform platform;
  late _Controller controller;
  int slot_sequence = 0;

  void case_for(
    bool is_short,
    String name,
    Future<void> Function(WidgetTester) callback,
  ) {
    testWidgets('${is_short ? '短篇列表' : '瀑布流'}：$name', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(() async {
        Get.testMode = true;
        platform = _AdPlatform();
        Get.put(
          ProjectConfigStore(),
        ).save_config(ProjectConfig.from_json({'ads_switch': SwitchValue.on}));
        ConsentInformation.instance = _ConsentInformation();
        UserMessagingChannel.instance = _MessagingChannel();
        AdMobConsentPermissionRequest.reset_for_test();
        await AdMobConsentPermissionRequest.initialize_on_app_start();
        await GoogleMobileAdsUtil.instance.ensure_initialized();
      });
      MasonryAdConfigService.set_fetcher_for_test(() async => _config());
      ShortStoryTabAdConfigService.set_fetcher_for_test(() async => _config());
      final slot_id = 'feed_test_${slot_sequence++}';
      controller = is_short
          ? _Controller.short(ShortStoryTabAdController(slot_id: slot_id))
          : _Controller.masonry(MasonryNativeAdController(slot_id: slot_id));
      try {
        await callback(tester);
      } finally {
        controller.notifier.dispose();
        await _flush(tester);
        await tester.runAsync(() async {
          Get.reset();
          await platform.dispose();
          ads_sdk.instanceManager = original_ad_manager;
          ConsentInformation.instance = original_consent;
          UserMessagingChannel.instance = original_messaging;
          AdMobConsentPermissionRequest.reset_for_test();
          MasonryAdConfigService.reset_for_test();
          ShortStoryTabAdConfigService.reset_for_test();
        });
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  for (final is_short in [false, true]) {
    case_for(is_short, 'SDK无回调会超时释放，冷却重试后旧事件不能恢复素材', (tester) async {
      controller.ensure();
      await _flush(tester);
      final first = platform.loads.single;
      await tester.pump(FeedNativeAdPolicy.preparation_timeout);
      await _flush(tester);
      expect(controller.loading(), isFalse);
      expect(controller.failed(), isTrue);
      expect(controller.current_ad(), isNull);
      expect(platform.disposals, contains(first));
      for (int round = 0; round < 10; round++) {
        controller.ensure();
      }
      await _flush(tester);
      expect(platform.loads, hasLength(1));

      await tester.pump(FeedNativeAdPolicy.retry_delay);
      controller.ensure();
      await _flush(tester);
      final next = platform.loads.last;
      expect(platform.loads, hasLength(2));
      await platform.event(first, 'onAdLoaded');
      await platform.event(first, 'onAdFailedToLoad');
      await platform.measure(first, 999, is_short: is_short);
      expect(controller.loading(), isTrue);
      expect(controller.failed(), isFalse);
      expect(controller.measured(), isFalse);
      await platform.measure(next, 280, is_short: is_short);
      await platform.event(next, 'onAdLoaded');
      expect(controller.current_ad(), same(next));
      expect(controller.height(), 280);
    });

    case_for(is_short, 'SDK加载调用自身挂起也会超时，迟到完成不修改失败状态', (tester) async {
      await tester.runAsync(() async => platform.load_gate = Completer<void>());
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await tester.pump(FeedNativeAdPolicy.preparation_timeout);
      await _flush(tester);
      expect(controller.loading(), isFalse);
      expect(controller.failed(), isTrue);
      expect(platform.disposals, contains(ad));
      await tester.runAsync(() async => platform.load_gate!.complete());
      await _flush(tester);
      expect(controller.failed(), isTrue);
      expect(controller.current_ad(), isNull);
    });

    case_for(is_short, 'loaded缺少原生尺寸仍在准备期限内超时，不能占用一小时缓存', (tester) async {
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await platform.event(ad, 'onAdLoaded');
      expect(controller.current_ad(), same(ad));
      expect(controller.measured(), isFalse);
      expect(controller.claim(Object()), isFalse);
      await tester.pump(FeedNativeAdPolicy.preparation_timeout);
      await _flush(tester);
      expect(controller.failed(), isTrue);
      expect(controller.current_ad(), isNull);
      expect(platform.disposals, contains(ad));
      await platform.measure(ad, 999, is_short: is_short);
      expect(controller.measured(), isFalse);
    });

    case_for(is_short, '仅收到尺寸也不能结束准备期限', (tester) async {
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await platform.measure(ad, 280, is_short: is_short);
      expect(controller.measured(), isTrue);
      expect(controller.loading(), isTrue);
      await tester.pump(FeedNativeAdPolicy.preparation_timeout);
      await _flush(tester);
      expect(controller.failed(), isTrue);
      expect(controller.measured(), isFalse);
      expect(platform.disposals, contains(ad));
    });

    for (final measure_first in [false, true]) {
      case_for(is_short, '${measure_first ? '尺寸先到' : 'loaded先到'}完整就绪后取消准备超时', (
        tester,
      ) async {
        controller.ensure();
        await _flush(tester);
        final ad = platform.loads.single;
        if (measure_first) {
          await platform.measure(ad, 280, is_short: is_short);
          await platform.event(ad, 'onAdLoaded');
        } else {
          await platform.event(ad, 'onAdLoaded');
          await platform.measure(ad, 280, is_short: is_short);
        }
        await tester.pump(FeedNativeAdPolicy.preparation_timeout * 2);
        await _flush(tester);
        expect(controller.current_ad(), same(ad));
        expect(controller.failed(), isFalse);
        expect(controller.measured(), isTrue);
        expect(platform.disposals, isEmpty);
      });
    }

    case_for(is_short, '新宽度取消旧代次期限，旧截止时间不会废弃新素材', (tester) async {
      controller.ensure();
      await _flush(tester);
      final half_deadline = FeedNativeAdPolicy.preparation_timeout ~/ 2;
      await tester.pump(half_deadline);
      controller.ensure(width: 360);
      await _flush(tester);
      final next = platform.loads.last;
      await tester.pump(half_deadline);
      expect(controller.failed(), isFalse);
      expect(controller.loading(), isTrue);
      await platform.event(next, 'onAdLoaded');
      await platform.measure(next, 280, is_short: is_short);
      await tester.pump(FeedNativeAdPolicy.preparation_timeout);
      expect(controller.current_ad(), same(next));
      expect(controller.failed(), isFalse);
    });

    case_for(is_short, 'UMP表单等待时间不计入SDK准备超时', (tester) async {
      late Completer<void> privacy_gate;
      late Future<bool> privacy_flow;
      await tester.runAsync(() async {
        AdMobConsentPermissionRequest.reset_for_test();
        privacy_gate = Completer<void>();
        UserMessagingChannel.instance = _MessagingChannel()
          ..privacy_form_gate = privacy_gate;
        privacy_flow = AdMobConsentPermissionRequest.initialize_on_app_start();
        await Future<void>.delayed(Duration.zero);
      });
      controller.ensure();
      await _flush(tester);
      await tester.pump(FeedNativeAdPolicy.preparation_timeout * 2);
      expect(controller.loading(), isTrue);
      expect(controller.failed(), isFalse);
      expect(platform.loads, isEmpty);
      await tester.runAsync(() async {
        privacy_gate.complete();
        expect(await privacy_flow, isTrue);
      });
      await _flush(tester);
      expect(platform.loads, hasLength(1));
      await tester.pump(FeedNativeAdPolicy.preparation_timeout);
      expect(controller.loading(), isFalse);
      expect(controller.failed(), isTrue);
    });

    case_for(is_short, 'SDK调用抛异常立即冷却，旧准备计时不会干扰下一次重试', (tester) async {
      platform.throw_on_load = true;
      controller.ensure();
      await _flush(tester);
      expect(controller.loading(), isFalse);
      expect(controller.failed(), isTrue);
      expect(platform.disposals, contains(platform.loads.single));
      platform.throw_on_load = false;
      await tester.pump(FeedNativeAdPolicy.retry_delay);
      controller.ensure();
      await _flush(tester);
      final next = platform.loads.last;
      await platform.measure(next, 280, is_short: is_short);
      await platform.event(next, 'onAdLoaded');
      await tester.pump(FeedNativeAdPolicy.preparation_timeout);
      expect(platform.loads, hasLength(2));
      expect(controller.current_ad(), same(next));
      expect(controller.failed(), isFalse);
    });

    case_for(is_short, '配置暂时缺失后可重试，冷却期间不会请求风暴', (tester) async {
      int requests = 0;
      Future<AdConfig?> fetch() async => ++requests == 1 ? null : _config();
      MasonryAdConfigService.set_fetcher_for_test(fetch);
      ShortStoryTabAdConfigService.set_fetcher_for_test(fetch);
      controller.ensure();
      await _flush(tester);
      expect(controller.failed(), isTrue);
      expect(platform.loads, isEmpty);
      for (int round = 0; round < 10; round++) {
        controller.ensure();
      }
      await _flush(tester);
      expect(requests, 1);
      await tester.pump(FeedNativeAdPolicy.retry_delay);
      controller.ensure();
      await _flush(tester);
      expect(platform.loads, hasLength(1));
      expect(controller.loading(), isTrue);
      expect(requests, 2);
    });

    case_for(is_short, 'SDK失败可重试，不保留无限骨架 loading 状态', (tester) async {
      controller.ensure();
      await _flush(tester);
      await platform.event(platform.loads.single, 'onAdFailedToLoad');
      await _flush(tester);
      expect(controller.failed(), isTrue);
      expect(controller.loading(), isFalse);
      expect(controller.current_ad(), isNull);
      await tester.pump(FeedNativeAdPolicy.retry_delay);
      controller.ensure();
      await _flush(tester);
      expect(platform.loads, hasLength(2));
    });

    case_for(is_short, '等fallback的测量也是ready，loaded不能代替测量', (tester) async {
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      int changes = 0;
      controller.notifier.addListener(() => changes++);
      await platform.event(ad, 'onAdLoaded');
      expect(controller.current_ad(), same(ad));
      expect(controller.measured(), isFalse);
      final owner = Object();
      expect(controller.claim(owner), isFalse);
      final previous_changes = changes;
      await platform.measure(ad, controller.height(), is_short: is_short);
      expect(changes, previous_changes + 1);
      expect(controller.measured(), isTrue);
      expect(controller.claim(owner), isTrue);
      controller.release(owner);
    });

    case_for(is_short, '新宽度拒绝旧素材的迟到尺寸并等待自己的测量', (tester) async {
      controller.ensure();
      await _flush(tester);
      final first = platform.loads.single;
      await platform.measure(first, 350, is_short: is_short);
      controller.ensure(width: 400.2);
      await _flush(tester);
      expect(platform.loads, hasLength(1));
      controller.ensure(width: 360);
      await _flush(tester);
      final next = platform.loads.last;
      expect(platform.loads, hasLength(2));
      expect(controller.measured(), isFalse);
      await platform.measure(first, 999, is_short: is_short);
      expect(controller.measured(), isFalse);
      await platform.event(next, 'onAdLoaded');
      expect(controller.measured(), isFalse);
      await platform.measure(next, 280, is_short: is_short);
      expect(controller.measured(), isTrue);
      expect(controller.height(), 280);
      expect(controller.current_ad(), same(next));
    });

    case_for(is_short, '主题按真实原生外观决定是否重载', (tester) async {
      controller.ensure();
      await _flush(tester);
      controller.ensure(is_dark: true);
      await _flush(tester);
      expect(platform.loads, hasLength(is_short ? 1 : 2));
    });

    case_for(is_short, '配置UUID更新使旧请求失效，旧宽度测量不能污染新广告', (tester) async {
      final config_store = Get.put(AdConfigStore());
      config_store.save_configs([_config()]);
      controller.ensure();
      await _flush(tester);
      final first = platform.loads.single;
      await platform.measure(first, 250, is_short: is_short);
      await platform.event(first, 'onAdLoaded');
      expect(controller.current_ad(), same(first));
      config_store.save_configs([_config(uuid: 'two')]);
      expect(controller.current_ad(), isNull);
      expect(controller.measured(), isFalse);
      MasonryAdConfigService.set_fetcher_for_test(
        () async => _config(uuid: 'two'),
      );
      ShortStoryTabAdConfigService.set_fetcher_for_test(
        () async => _config(uuid: 'two'),
      );
      controller.ensure();
      await _flush(tester);
      expect(platform.loads, hasLength(2));
      await platform.measure(first, 999, is_short: is_short);
      expect(controller.measured(), isFalse);
      final next = platform.loads.last;
      await platform.measure(next, 280, is_short: is_short);
      await platform.event(next, 'onAdLoaded');
      expect(controller.current_ad(), same(next));
    });

    case_for(is_short, '仅改权重复用有效素材，权重归零即时撤销', (tester) async {
      final config_store = Get.put(AdConfigStore());
      config_store.save_configs([_config()]);
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await platform.measure(ad, 250, is_short: is_short);
      await platform.event(ad, 'onAdLoaded');
      config_store.save_configs([
        AdConfig.fromJson({
          'id': 'configuration',
          'ads_id': 'unit',
          'uuid': 'one',
          'advertisers': 1,
          'weight': 3,
          'ads_type': 9,
        }),
      ]);
      expect(controller.current_ad(), same(ad));
      expect(platform.loads, hasLength(1));
      config_store.save_configs([
        AdConfig.fromJson({
          'id': 'configuration',
          'ads_id': 'unit',
          'uuid': 'one',
          'advertisers': 1,
          'weight': 0,
          'ads_type': 9,
        }),
      ]);
      expect(controller.current_ad(), isNull);
      expect(controller.measured(), isFalse);
      await _flush(tester);
      expect(platform.disposals, contains(ad));
    });

    case_for(is_short, '配置仓库尚未恢复时不会重复请求或丢弃有效素材', (tester) async {
      Get.put(AdConfigStore());
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      controller.ensure();
      await platform.event(ad, 'onAdLoaded');
      controller.ensure();
      await _flush(tester);
      expect(platform.loads, hasLength(1));
      expect(controller.current_ad(), same(ad));
    });

    case_for(is_short, '关闭广告立即释放素材，旧在途事件不恢复广告', (tester) async {
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await platform.measure(ad, 250, is_short: is_short);
      await platform.event(ad, 'onAdLoaded');
      Get.find<ProjectConfigStore>().save_config(
        ProjectConfig.from_json({'ads_switch': SwitchValue.off}),
      );
      expect(controller.current_ad(), isNull);
      expect(controller.measured(), isFalse);
      await _flush(tester);
      expect(platform.disposals, contains(ad));
      Get.find<ProjectConfigStore>().save_config(
        ProjectConfig.from_json({'ads_switch': SwitchValue.on}),
      );
      controller.ensure();
      await _flush(tester);
      expect(platform.loads, hasLength(2));
    });

    case_for(is_short, '同槽位只允许一个平台视图，卸载后下一帧可接管', (tester) async {
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await platform.measure(ad, 250, is_short: is_short);
      await platform.event(ad, 'onAdLoaded');
      final owner = Object();
      final other = Object();
      expect(controller.claim(owner), isTrue);
      expect(controller.claim(other), isFalse);
      controller.release(other);
      expect(controller.claim(other), isFalse);
      controller.release(owner);
      expect(controller.claim(other), isFalse);
      await _flush(tester);
      expect(controller.claim(other), isTrue);
      controller.release(other);
    });

    case_for(is_short, '同ID控制器重建后旧素材测量不能命中新token', (tester) async {
      controller.ensure();
      await _flush(tester);
      final first = platform.loads.single;
      final slot_id = first.customOptions!['slotId'] as String;
      controller.notifier.dispose();
      controller = is_short
          ? _Controller.short(ShortStoryTabAdController(slot_id: slot_id))
          : _Controller.masonry(MasonryNativeAdController(slot_id: slot_id));
      controller.ensure();
      await _flush(tester);
      final next = platform.loads.last;
      expect(
        next.customOptions!['layoutToken'],
        isNot(first.customOptions!['layoutToken']),
      );
      await platform.measure(first, 999, is_short: is_short);
      expect(controller.measured(), isFalse);
      await platform.measure(next, 260, is_short: is_short);
      await platform.event(next, 'onAdLoaded');
      expect(controller.height(), 260);
      expect(controller.current_ad(), same(next));
    });

    case_for(is_short, '未展示缓存一小时后释放，返回时请求新素材', (tester) async {
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await platform.measure(ad, 250, is_short: is_short);
      await platform.event(ad, 'onAdLoaded');
      await tester.pump(FeedNativeAdPolicy.maximum_cache_age);
      await _flush(tester);
      expect(controller.current_ad(), isNull);
      expect(platform.disposals, contains(ad));
      controller.ensure();
      await _flush(tester);
      expect(platform.loads, hasLength(2));
    });

    case_for(is_short, '已显示素材到期不突然消失，卸载后释放', (tester) async {
      controller.ensure();
      await _flush(tester);
      final ad = platform.loads.single;
      await platform.measure(ad, 250, is_short: is_short);
      await platform.event(ad, 'onAdLoaded');
      final owner = Object();
      expect(controller.claim(owner), isTrue);
      await tester.pump(FeedNativeAdPolicy.maximum_cache_age);
      controller.ensure();
      expect(controller.current_ad(), same(ad));
      expect(platform.loads, hasLength(1));
      controller.release(owner);
      await _flush(tester);
      expect(controller.current_ad(), isNull);
      expect(platform.disposals, contains(ad));
    });

    case_for(is_short, '隐私选择使测量失效，新素材仍通过共享桥接收到真实高度', (tester) async {
      controller.ensure();
      await _flush(tester);
      final first = platform.loads.single;
      await platform.measure(first, 250, is_short: is_short);
      await platform.event(first, 'onAdLoaded');
      final changed = await tester.runAsync(
        AdMobConsentPermissionRequest.show_privacy_options_form,
      );
      expect(changed, isTrue);
      expect(controller.current_ad(), isNull);
      expect(controller.measured(), isFalse);
      controller.ensure();
      await _flush(tester);
      expect(platform.loads, hasLength(2));
      final next = platform.loads.last;
      await platform.measure(first, 999, is_short: is_short);
      expect(controller.measured(), isFalse);
      await platform.measure(next, 300, is_short: is_short);
      await platform.event(next, 'onAdLoaded');
      expect(controller.height(), 300);
      expect(controller.current_ad(), same(next));
    });
  }

  testWidgets('跳过广告只在子组件卸载后释放，其他页面listener继续持有素材', (tester) async {
    final masonry = MasonryNativeAdPool.obtain('retained_masonry');
    final short = ShortStoryTabAdPool.obtain('retained_short');
    void listener() {}
    masonry.addListener(listener);
    short.addListener(listener);
    MasonryNativeAdPool.remove_if_unattached('retained_masonry');
    ShortStoryTabAdPool.remove_if_unattached('retained_short');
    await _flush(tester);
    expect(MasonryNativeAdPool.obtain('retained_masonry'), same(masonry));
    expect(ShortStoryTabAdPool.obtain('retained_short'), same(short));
    MasonryNativeAdPool.remove_if_unattached('retained_masonry');
    ShortStoryTabAdPool.remove_if_unattached('retained_short');
    masonry.removeListener(listener);
    short.removeListener(listener);
    await _flush(tester);
    expect(MasonryNativeAdPool.controller_count, 0);
    expect(ShortStoryTabAdPool.controller_count, 0);
  });

  testWidgets('广告池限制未使用控制器总数，仍被页面使用的槽位不淘汰', (tester) async {
    final masonry_ids = <String>[];
    final short_ids = <String>[];
    final active_masonry = MasonryNativeAdPool.obtain('active_masonry');
    final active_short = ShortStoryTabAdPool.obtain('active_short');
    void listener() {}
    active_masonry.addListener(listener);
    active_short.addListener(listener);
    for (
      int i = 0;
      i < FeedNativeAdPolicy.maximum_retained_controllers + 10;
      i++
    ) {
      masonry_ids.add('cache_masonry_$i');
      short_ids.add('cache_short_$i');
      MasonryNativeAdPool.obtain(masonry_ids.last);
      ShortStoryTabAdPool.obtain(short_ids.last);
    }
    expect(
      MasonryNativeAdPool.controller_count,
      FeedNativeAdPolicy.maximum_retained_controllers,
    );
    expect(
      ShortStoryTabAdPool.controller_count,
      FeedNativeAdPolicy.maximum_retained_controllers,
    );
    expect(MasonryNativeAdPool.obtain('active_masonry'), same(active_masonry));
    expect(ShortStoryTabAdPool.obtain('active_short'), same(active_short));
    active_masonry.removeListener(listener);
    active_short.removeListener(listener);
    MasonryNativeAdPool.remove_all([...masonry_ids, 'active_masonry']);
    ShortStoryTabAdPool.remove_all([...short_ids, 'active_short']);
    await _flush(tester);
  });
}
