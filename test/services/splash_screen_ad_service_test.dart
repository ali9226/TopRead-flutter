// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/splash_screen/style.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/services/splash_screen_ad_service.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/rewarded_ad_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as ads_sdk;
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  final ads_sdk.AdInstanceManager original_ad_manager = ads_sdk.instanceManager;
  final ConsentInformation original_consent = ConsentInformation.instance;
  final UserMessagingChannel original_ump = UserMessagingChannel.instance;

  late _FakeAdPlatform platform;
  late AdConfigStore ad_store;
  late ProjectConfigStore project_store;

  Future<void> set_up() async {
    Get.testMode = true;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    platform = _FakeAdPlatform();
    ad_store = Get.put(AdConfigStore());
    project_store = Get.put(ProjectConfigStore())
      ..save_config(_project_config());
    ConsentInformation.instance = _FakeConsentInformation();
    UserMessagingChannel.instance = _FakeUserMessagingChannel();
    AdMobConsentPermissionRequest.reset_for_test();
    await AdMobConsentPermissionRequest.initialize_on_app_start();
    await GoogleMobileAdsUtil.instance.ensure_initialized();
  }

  Future<void> tear_down() async {
    await Get.delete<SplashScreenAdService>(force: true);
    Get.reset();
    await platform.dispose();
    ads_sdk.instanceManager = original_ad_manager;
    ConsentInformation.instance = original_consent;
    UserMessagingChannel.instance = original_ump;
    AdMobConsentPermissionRequest.reset_for_test();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  /// SDK 缓存跨测试共享的初始化 Future，因此统一在真实异步区域初始化，
  /// 避免缓存已销毁的 fake async 区域；退出测试前注销观察器和定时器。
  void test_ad_widgets(String description, WidgetTesterCallback callback) {
    testWidgets(description, (tester) async {
      await tester.runAsync(set_up);
      try {
        await callback(tester);
      } finally {
        await tester.runAsync(tear_down);
      }
    });
  }

  /// 模拟实际切至后台再返回；hidden 与 paused 属于同一次后台经历。
  void return_from_background() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  /// 首次启动没有缓存广告，之后允许测试单独设置热启动使用的最新配置。
  SplashScreenAdService create_started_service() {
    final SplashScreenAdService service = Get.put(SplashScreenAdService());
    service.set_splash_completed(true);
    ad_store.save_configs(<AdConfig>[_ad_config('current-unit')]);
    return service;
  }

  test_ad_widgets('冷启动结束会取消尚未执行的首帧广告请求', (tester) async {
    ad_store.save_configs(<AdConfig>[_ad_config('cached-unit')]);
    final SplashScreenAdService service = Get.put(SplashScreenAdService());
    service.set_splash_completed(true);

    await _flush_ad_tasks(tester);

    expect(platform.app_open_loads, isEmpty);
    expect(service.is_loading, isFalse);
  });

  test_ad_widgets('冷启动由图片组件展示广告，图片完成不会提前释放正在展示的广告', (tester) async {
    ad_store.save_configs(<AdConfig>[_ad_config('cached-unit')]);
    final SplashScreenAdService service = Get.put(SplashScreenAdService());
    await _flush_ad_tasks(tester);
    final AppOpenAd ad = platform.app_open_loads.single;
    await platform.emit_event(ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(platform.shown_ads, isEmpty);

    await service.show_ad();
    service.set_splash_completed(true);
    expect(platform.shown_ads, <Ad>[ad]);
    expect(service.app_open_ad, same(ad));
    expect(platform.disposed_ads, isEmpty);

    await platform.emit_event(ad, 'onAdDismissedFullScreenContent');
    await _flush_ad_tasks(tester);
    expect(service.app_open_ad, isNull);
    expect(platform.disposed_ads, <Ad>[ad]);
  });

  test_ad_widgets('首次 resumed 和 inactive 返回不会触发热启动广告', (tester) async {
    create_started_service();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush_ad_tasks(tester);

    expect(platform.app_open_loads, isEmpty);
  });

  test_ad_widgets('真正返回前台后读取最新 ID 并自动展示，每次后台经历仅请求一次', (tester) async {
    final SplashScreenAdService service = create_started_service();
    ad_store.save_configs(<AdConfig>[_ad_config('updated-unit')]);
    return_from_background();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush_ad_tasks(tester);

    expect(platform.app_open_loads, hasLength(1));
    expect(platform.app_open_loads.single.adUnitId, 'updated-unit');
    expect(platform.shown_ads, isEmpty);
    await platform.emit_event(platform.app_open_loads.single, 'onAdLoaded');
    await _flush_ad_tasks(tester);

    expect(platform.shown_ads, <Ad>[platform.app_open_loads.single]);
    expect(service.is_ad_loaded, isTrue);
  });

  test_ad_widgets('广告开关、零概率和没有 ID 都跳过，恢复百分百概率后可以展示', (tester) async {
    create_started_service();
    project_store.save_config(_project_config(ads_switch: SwitchValue.off));
    return_from_background();
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, isEmpty);

    project_store.save_config(_project_config(probability: 0));
    return_from_background();
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, isEmpty);

    project_store.save_config(_project_config());
    ad_store.save_configs(<AdConfig>[]);
    return_from_background();
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, isEmpty);

    ad_store.save_configs(<AdConfig>[_ad_config('enabled-unit')]);
    return_from_background();
    await _flush_ad_tasks(tester);
    await platform.emit_event(platform.app_open_loads.single, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(platform.shown_ads, hasLength(1));
  });

  test_ad_widgets('已结束的冷启动请求迟到时不会覆盖新的热启动请求', (tester) async {
    ad_store.save_configs(<AdConfig>[_ad_config('cold-unit')]);
    final SplashScreenAdService service = Get.put(SplashScreenAdService());
    await _flush_ad_tasks(tester);
    final AppOpenAd cold_ad = platform.app_open_loads.single;
    service.set_splash_completed(true);
    expect(service.is_loading, isFalse);

    ad_store.save_configs(<AdConfig>[_ad_config('warm-unit')]);
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd warm_ad = platform.app_open_loads.last;
    expect(platform.app_open_loads, hasLength(2));

    await platform.emit_event(cold_ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(service.is_loading, isTrue);
    expect(service.app_open_ad, isNull);
    expect(platform.disposed_ads, contains(cold_ad));
    expect(platform.shown_ads, isEmpty);

    await platform.emit_event(warm_ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(service.app_open_ad, same(warm_ad));
    expect(platform.shown_ads, <Ad>[warm_ad]);
  });

  test_ad_widgets('热启动加载期间再次退到后台会失效，旧失败回调不能结束新请求', (tester) async {
    final SplashScreenAdService service = create_started_service();
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd stale_ad = platform.app_open_loads.single;

    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd current_ad = platform.app_open_loads.last;
    expect(platform.app_open_loads, hasLength(2));
    await platform.emit_event(
      stale_ad,
      'onAdFailedToLoad',
      error: LoadAdError(1, 'test', 'stale request', null),
    );
    await _flush_ad_tasks(tester);
    expect(service.is_loading, isTrue);

    await platform.emit_event(current_ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(service.app_open_ad, same(current_ad));
    expect(platform.shown_ads, <Ad>[current_ad]);
  });

  for (final bool remove_id in <bool>[false, true]) {
    test_ad_widgets('展示前静音等待期间${remove_id ? '移除 ID' : '关闭广告'}会取消广告', (
      tester,
    ) async {
      final SplashScreenAdService service = create_started_service();
      return_from_background();
      await _flush_ad_tasks(tester);
      final AppOpenAd ad = platform.app_open_loads.single;
      final Completer<void> mute_gate = Completer<void>();
      platform.mute_gate = mute_gate;
      await platform.emit_event(ad, 'onAdLoaded');
      await _flush_ad_tasks(tester);

      if (remove_id) {
        ad_store.save_configs(<AdConfig>[_ad_config('replacement-unit')]);
      } else {
        project_store.save_config(_project_config(ads_switch: SwitchValue.off));
      }
      mute_gate.complete();
      await _flush_ad_tasks(tester);

      expect(platform.shown_ads, isEmpty);
      expect(platform.disposed_ads, contains(ad));
      expect(service.app_open_ad, isNull);
    });
  }

  test_ad_widgets('热启动加载超时后丢弃迟到广告，下次返回仍可重新请求', (tester) async {
    final SplashScreenAdService service = create_started_service();
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd stale_ad = platform.app_open_loads.single;
    await tester.pump(
      Duration(milliseconds: SplashScreenStyle.display_duration_ms),
    );
    expect(service.is_loading, isFalse);
    await platform.emit_event(stale_ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(platform.shown_ads, isEmpty);
    expect(platform.disposed_ads, contains(stale_ad));

    return_from_background();
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, hasLength(2));
    await platform.emit_event(platform.app_open_loads.last, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(platform.shown_ads, <Ad>[platform.app_open_loads.last]);
  });

  test_ad_widgets('热启动已加载但静音等待超时，也不能延后弹出广告', (tester) async {
    create_started_service();
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd ad = platform.app_open_loads.single;
    final Completer<void> mute_gate = Completer<void>();
    platform.mute_gate = mute_gate;
    await platform.emit_event(ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    await tester.pump(
      Duration(milliseconds: SplashScreenStyle.display_duration_ms),
    );
    mute_gate.complete();
    await _flush_ad_tasks(tester);

    expect(platform.shown_ads, isEmpty);
    expect(platform.disposed_ads, contains(ad));
  });

  test_ad_widgets('开屏广告引发后台后先关闭再 resumed，不会立即重复弹广告', (tester) async {
    create_started_service();
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd ad = platform.app_open_loads.single;
    await platform.emit_event(ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await platform.emit_event(ad, 'onAdDismissedFullScreenContent');
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, hasLength(1));

    return_from_background();
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, hasLength(2));
    await platform.emit_event(platform.app_open_loads.last, 'onAdLoaded');
    await _flush_ad_tasks(tester);
  });

  test_ad_widgets('激励广告执行期间的后台经历不能触发开屏广告', (tester) async {
    create_started_service();
    final Future<GoogleRewardedAdResult> rewarded_result = GoogleRewardedAdUtil
        .instance
        .show_rewarded_ad(adUnitId: 'reward-unit');
    await _flush_ad_tasks(tester);
    expect(GoogleRewardedAdUtil.instance.is_running, isTrue);
    expect(platform.rewarded_loads, hasLength(1));

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await platform.emit_event(
      platform.rewarded_loads.single,
      'onAdFailedToLoad',
      error: LoadAdError(1, 'test', 'reward request complete', null),
    );
    await _flush_ad_tasks(tester);
    expect(await rewarded_result, GoogleRewardedAdResult.load_failed);
    expect(GoogleRewardedAdUtil.instance.is_running, isFalse);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, isEmpty);

    return_from_background();
    await _flush_ad_tasks(tester);
    expect(platform.app_open_loads, hasLength(1));
    await platform.emit_event(platform.app_open_loads.single, 'onAdLoaded');
    await _flush_ad_tasks(tester);
  });

  for (final bool dismiss_in_background in <bool>[false, true]) {
    test_ad_widgets(
      '激励视频全屏播放后切后台，${dismiss_in_background ? '后台关闭后返回' : '仍在播放时返回'}不会展示开屏',
      (tester) async {
        create_started_service();
        final Future<GoogleRewardedAdResult> rewarded_result =
            GoogleRewardedAdUtil.instance.show_rewarded_ad(
              adUnitId: 'reward-unit',
            );
        await _flush_ad_tasks(tester);
        final RewardedAd rewarded_ad = platform.rewarded_loads.single;
        await platform.emit_event(rewarded_ad, 'onAdLoaded');
        await _flush_ad_tasks(tester);
        await platform.emit_event(rewarded_ad, 'onAdShowedFullScreenContent');
        expect(platform.shown_ads, <Ad>[rewarded_ad]);

        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        if (dismiss_in_background) {
          await platform.emit_event(
            rewarded_ad,
            'onAdDismissedFullScreenContent',
          );
          await _flush_ad_tasks(tester);
          expect(await rewarded_result, GoogleRewardedAdResult.dismissed);
          expect(GoogleRewardedAdUtil.instance.is_running, isFalse);
        }

        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await _flush_ad_tasks(tester);
        expect(platform.app_open_loads, isEmpty);
        expect(platform.shown_ads, <Ad>[rewarded_ad]);

        if (!dismiss_in_background) {
          expect(GoogleRewardedAdUtil.instance.is_running, isTrue);
          await platform.emit_event(
            rewarded_ad,
            'onAdDismissedFullScreenContent',
          );
          await _flush_ad_tasks(tester);
          expect(await rewarded_result, GoogleRewardedAdResult.dismissed);
          expect(GoogleRewardedAdUtil.instance.is_running, isFalse);
        }
        expect(platform.app_open_loads, isEmpty);

        // 互斥只跳过此次广告期间的恢复，不影响下一次普通前后台切换。
        return_from_background();
        await _flush_ad_tasks(tester);
        final AppOpenAd splash_ad = platform.app_open_loads.single;
        await platform.emit_event(splash_ad, 'onAdLoaded');
        await _flush_ad_tasks(tester);
        expect(platform.shown_ads, <Ad>[rewarded_ad, splash_ad]);
      },
    );
  }

  test_ad_widgets('开屏加载期间开始激励视频，迟到开屏被丢弃且不能释放激励锁', (tester) async {
    final SplashScreenAdService service = create_started_service();
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd splash_ad = platform.app_open_loads.single;

    final Future<GoogleRewardedAdResult> rewarded_result = GoogleRewardedAdUtil
        .instance
        .show_rewarded_ad(adUnitId: 'reward-unit');
    await _flush_ad_tasks(tester);
    final RewardedAd rewarded_ad = platform.rewarded_loads.single;
    await platform.emit_event(rewarded_ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    await platform.emit_event(splash_ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);

    expect(service.is_loading, isFalse);
    expect(service.app_open_ad, isNull);
    expect(platform.disposed_ads, contains(splash_ad));
    expect(platform.shown_ads, <Ad>[rewarded_ad]);
    expect(
      await GoogleRewardedAdUtil.instance.show_rewarded_ad(
        adUnitId: 'second-reward-unit',
      ),
      GoogleRewardedAdResult.busy,
    );
    expect(platform.rewarded_loads, hasLength(1));

    await platform.emit_event(rewarded_ad, 'onAdDismissedFullScreenContent');
    await _flush_ad_tasks(tester);
    expect(await rewarded_result, GoogleRewardedAdResult.dismissed);
    return_from_background();
    await _flush_ad_tasks(tester);
    await platform.emit_event(platform.app_open_loads.last, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(platform.shown_ads, <Ad>[rewarded_ad, platform.app_open_loads.last]);
  });

  test_ad_widgets('开屏广告正在展示时激励广告返回忙碌且不加载', (tester) async {
    create_started_service();
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd ad = platform.app_open_loads.single;
    await platform.emit_event(ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);
    expect(platform.shown_ads, <Ad>[ad]);

    final GoogleRewardedAdResult result = await GoogleRewardedAdUtil.instance
        .show_rewarded_ad(adUnitId: 'reward-unit');

    expect(result, GoogleRewardedAdResult.busy);
    expect(platform.rewarded_loads, isEmpty);
    expect(GoogleRewardedAdUtil.instance.is_running, isFalse);
  });

  test_ad_widgets('注销服务后不响应生命周期，未完成广告回调只释放资源', (tester) async {
    final SplashScreenAdService service = create_started_service();
    return_from_background();
    await _flush_ad_tasks(tester);
    final AppOpenAd ad = platform.app_open_loads.single;
    await Get.delete<SplashScreenAdService>();

    return_from_background();
    await platform.emit_event(ad, 'onAdLoaded');
    await _flush_ad_tasks(tester);

    expect(platform.app_open_loads, hasLength(1));
    expect(platform.shown_ads, isEmpty);
    expect(platform.disposed_ads, contains(ad));
    expect(service.app_open_ad, isNull);
    expect(service.is_loading, isFalse);
  });
}

/// 推进首帧与原生插件异步任务，同时保持展示超时由 tester 的虚拟时钟控制。
Future<void> _flush_ad_tasks(WidgetTester tester) async {
  // 服务使用首帧回调启动冷启动请求；测试未挂载根组件，需要显式调度帧。
  tester.binding.scheduleFrame();
  // UMP 许可和 SDK 初始化分别复用真实异步区域的 Future，逐轮排空两种
  // 区域的任务；不推进虚拟时间，也不自动完成测试刻意阻塞的静音 Future。
  for (int round = 0; round < 3; round++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pump();
}

/// 使用 Google SDK 真实广告对象，只模拟原生消息通道，避免伪造服务内部状态。
class _FakeAdPlatform {
  _FakeAdPlatform() {
    ads_sdk.instanceManager = ads_sdk.AdInstanceManager('test.splash_ad.sdk');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ads_sdk.instanceManager.channel, _on_method);
  }

  /// SDK 已发起加载的真实开屏广告，保留顺序以验证过期回调。
  final List<AppOpenAd> app_open_loads = <AppOpenAd>[];

  /// SDK 已发起加载的激励广告，用于检验全屏流程之间的互斥。
  final List<RewardedAd> rewarded_loads = <RewardedAd>[];

  /// 原生已接受展示的广告。
  final List<Ad> shown_ads = <Ad>[];

  /// 原生已释放的广告。
  final List<Ad> disposed_ads = <Ad>[];

  /// 广告 ID 到真实对象的快照；SDK dispose 时会先移除自身映射。
  final Map<int, Ad> _ads = <int, Ad>{};

  /// 可选静音阻塞点，用来验证 show 前跨 await 的配置变化与超时。
  Completer<void>? mute_gate;

  /// 拦截原生调用并保存 SDK 分配的对象；初始化和无返回值方法即时成功。
  Future<Object?> _on_method(MethodCall call) async {
    if (call.method == 'MobileAds#initialize') {
      return InitializationStatus(<String, AdapterStatus>{});
    }
    if (call.method == 'MobileAds#setAppMuted') {
      await mute_gate?.future;
    }
    if (call.method == 'loadAppOpenAd' || call.method == 'loadRewardedAd') {
      final int ad_id = call.arguments['adId'] as int;
      final Ad ad = ads_sdk.instanceManager.adFor(ad_id)!;
      _ads[ad_id] = ad;
      if (ad is AppOpenAd) app_open_loads.add(ad);
      if (ad is RewardedAd) rewarded_loads.add(ad);
    }
    if (call.method == 'showAdWithoutView') {
      shown_ads.add(_ads[call.arguments['adId']]!);
    }
    if (call.method == 'disposeAd') {
      disposed_ads.add(_ads[call.arguments['adId']]!);
    }
    return null;
  }

  /// 通过 SDK 的原生事件入口触发真实回调，而非直接改写服务字段。
  Future<void> emit_event(
    Ad ad,
    String event_name, {
    LoadAdError? error,
  }) async {
    final int ad_id = _ads.entries
        .singleWhere((entry) => identical(entry.value, ad))
        .key;
    final MethodChannel channel = ads_sdk.instanceManager.channel;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            MethodCall('onAdEvent', <String, Object?>{
              'adId': ad_id,
              'eventName': event_name,
              'loadAdError': ?error,
            }),
          ),
          null,
        );
  }

  /// 清理仍由 SDK 持有的对象，避免测试之间残留广告和消息监听。
  Future<void> dispose() async {
    for (final Ad ad in _ads.values) {
      await ad.dispose();
    }
    final MethodChannel channel = ads_sdk.instanceManager.channel;
    channel.setMethodCallHandler(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}

/// 构造当前 Android 平台的开屏广告配置。
AdConfig _ad_config(String ads_id) {
  return AdConfig(
    id: ads_id,
    adsId: ads_id,
    showNumber: 0,
    notificationNumber: 0,
    adsType: 19,
    advertisers: 1,
    weight: 100,
    adsTypeStr: '',
    advertisersStr: '',
    uuid: '',
  );
}

/// 构造已经解析完成的广告开关和确定性概率配置。
ProjectConfig _project_config({
  int ads_switch = SwitchValue.on,
  int probability = 100,
}) {
  return ProjectConfig.from_json(<String, dynamic>{
    'ads_switch': ads_switch,
    'splash_screen_ads': probability,
  });
}

/// UMP 状态始终允许广告，测试专注于开屏广告生命周期。
class _FakeConsentInformation implements ConsentInformation {
  @override
  Future<bool> canRequestAds() async => true;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    return PrivacyOptionsRequirementStatus.notRequired;
  }

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    scheduleMicrotask(successListener);
  }

  @override
  Future<void> reset() async {}
}

/// 不展示 UMP UI，仅结束必要表单流程。
class _FakeUserMessagingChannel extends UserMessagingChannel {
  _FakeUserMessagingChannel()
    : super(const MethodChannel('test.splash_ad.ump'));

  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() async => null;
}
