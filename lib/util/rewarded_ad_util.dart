// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/full_screen_ad_guard.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 谷歌激励视频广告的最终展示结果。
enum GoogleRewardedAdResult {
  /// 当前平台的项目广告开关未开启。
  disabled,

  /// 用户完整观看并获得了奖励。
  rewarded,

  /// 用户在获得奖励前关闭了广告。
  dismissed,

  /// 广告加载失败。
  load_failed,

  /// UMP 尚未允许请求广告，或必要的隐私同意流程未能完成。
  consent_unavailable,

  /// 广告已加载，但全屏展示失败。
  show_failed,

  /// 当前运行平台不支持谷歌移动广告。
  unsupported,

  /// 已经有一个全屏广告流程在执行。
  busy,

  /// 广告加载完成前，发起展示的页面已经失效。
  cancelled,
}

/// 统一处理谷歌激励视频广告的初始化、加载、展示和释放。
///
/// 整个应用共享同一个实例，避免重复初始化 SDK，也防止多个页面
/// 同时发起全屏广告。
class GoogleRewardedAdUtil {
  GoogleRewardedAdUtil._();

  /// 应用内共享的激励广告工具实例。
  static final GoogleRewardedAdUtil instance = GoogleRewardedAdUtil._();

  /// 日志前缀。
  static const String _log_prefix = '[GoogleRewardedAd]';

  /// 必要隐私表单完成后，SDK 初始化、加载与 SSV 准备的最长等待时间。
  /// 超时后立即归还全屏资格，迟到广告只能释放，不能继续弹出。
  static const Duration preparation_timeout = Duration(seconds: 30);

  /// 当前是否已有广告在加载或展示。
  bool _is_running = false;

  /// 激励广告是否正在准备或展示，供开屏广告避免抢占全屏流程。
  bool get is_running => _is_running;

  /// 当前平台是否支持 Google Mobile Ads。
  ///
  bool get is_supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 加载并展示一次谷歌激励视频广告。
  ///
  /// [adUnitId] 广告单元 ID，由后端接口返回。
  /// [user_id] 是服务器端验证使用的用户标识。
  /// [custom_data] 是服务器端验证使用的本次广告业务标识。
  /// [can_show] 在隐私、加载与 SSV 准备后重新执行，防止旧页面继续弹出广告。
  Future<GoogleRewardedAdResult> show_rewarded_ad({
    required String adUnitId,
    String? user_id,
    String? custom_data,
    bool Function()? can_show,
  }) async {
    if (!AdDisplayPolicy.can_show_ads()) {
      _log('当前平台广告开关未开启，跳过激励广告', type: 'w');
      return GoogleRewardedAdResult.disabled;
    }
    if (!is_supported) {
      _log('当前平台不支持激励视频广告', type: 'w');
      return GoogleRewardedAdResult.unsupported;
    }
    if (_is_running || !FullScreenAdGuard.try_acquire(this)) {
      _log('已有全屏广告流程在执行', type: 'w');
      return GoogleRewardedAdResult.busy;
    }

    _is_running = true;
    final _RewardedAdPreparation preparation = _RewardedAdPreparation(can_show);
    RewardedAd? rewarded_ad;

    Future<GoogleRewardedAdResult> prepare_and_show() async {
      // 先完成 UMP 必要表单；未获得广告请求许可时不得初始化广告 SDK。
      final bool can_request_ads =
          await AdMobConsentPermissionRequest.request_before_ad();
      final GoogleRewardedAdResult? privacy_invalid_result = preparation
          .invalid_result();
      if (privacy_invalid_result != null) return privacy_invalid_result;
      if (!can_request_ads) {
        _log('UMP 未允许请求广告，本次不初始化广告 SDK', type: 'w');
        return GoogleRewardedAdResult.consent_unavailable;
      }
      preparation.start_timeout();
      final RewardedAd? loaded_ad = await _load_rewarded_ad(
        adUnitId,
        preparation,
        on_loaded: (RewardedAd ad) => rewarded_ad = ad,
      );
      final GoogleRewardedAdResult? load_invalid_result = preparation
          .invalid_result();
      if (load_invalid_result != null) return load_invalid_result;
      if (loaded_ad == null) {
        return GoogleRewardedAdResult.load_failed;
      }

      return await _show_loaded_ad(
        loaded_ad,
        preparation: preparation,
        user_id: user_id,
        custom_data: custom_data,
      );
    }

    try {
      return await Future.any<GoogleRewardedAdResult>(
        <Future<GoogleRewardedAdResult>>[
          prepare_and_show(),
          preparation.cancelled,
        ],
      );
    } catch (error, stack_trace) {
      _log('激励视频广告流程异常: $error\n$stack_trace', type: 'e');
      return GoogleRewardedAdResult.show_failed;
    } finally {
      preparation.dispose();
      try {
        await rewarded_ad?.dispose();
      } catch (error) {
        _log('激励广告资源释放失败: $error', type: 'w');
      } finally {
        _is_running = false;
        FullScreenAdGuard.release(this);
      }
    }
  }

  /// 初始化 SDK 并加载当前平台的激励广告。
  Future<RewardedAd?> _load_rewarded_ad(
    String adUnitId,
    _RewardedAdPreparation preparation, {
    required void Function(RewardedAd ad) on_loaded,
  }) async {
    try {
      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!is_initialized || preparation.invalid_result() != null) {
        return null;
      }

      final Completer<RewardedAd?> completer = Completer<RewardedAd?>();
      _log('开始加载激励广告，adUnitId=$adUnitId');
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (!preparation.is_active) {
              unawaited(ad.dispose());
              if (!completer.isCompleted) completer.complete(null);
              return;
            }
            final ResponseInfo? response_info = ad.responseInfo;
            _log(
              '广告加载成功，responseId=${response_info?.responseId}, '
              'adapter=${response_info?.mediationAdapterClassName}',
            );
            if (!completer.isCompleted) {
              // 在完成 Future 之前登记所有权，取消竞争不能遗漏已返回的广告。
              on_loaded(ad);
              completer.complete(ad);
            } else {
              unawaited(ad.dispose());
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _log(
              '广告加载失败，code=${error.code}, domain=${error.domain}, '
              'message=${error.message}, responseInfo=${error.responseInfo}',
              type: 'e',
            );
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
        ),
      );

      return completer.future;
    } catch (error, stack_trace) {
      _log('SDK 初始化或广告加载异常: $error\n$stack_trace', type: 'e');
      return null;
    }
  }

  /// 展示已经加载的广告，并等待全屏页关闭后返回最终结果。
  Future<GoogleRewardedAdResult> _show_loaded_ad(
    RewardedAd rewarded_ad, {
    required _RewardedAdPreparation preparation,
    String? user_id,
    String? custom_data,
  }) async {
    final Completer<GoogleRewardedAdResult> result_completer =
        Completer<GoogleRewardedAdResult>();
    bool has_earned_reward = false;
    RewardItem? earned_reward;

    void complete_result(GoogleRewardedAdResult result) {
      if (!result_completer.isCompleted) {
        result_completer.complete(result);
      }
    }

    final bool has_server_side_options =
        (user_id?.trim().isNotEmpty ?? false) ||
        (custom_data?.trim().isNotEmpty ?? false);
    if (has_server_side_options) {
      await rewarded_ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: user_id?.trim(),
          customData: custom_data?.trim(),
        ),
      );
      _log('SSV 参数设置完成，userId=$user_id, customData=$custom_data');
    }

    // SSV 参数写入也是异步边界，必须重新检查页面、开关与隐私选择。
    final GoogleRewardedAdResult? invalid_result = preparation.invalid_result();
    if (invalid_result != null) return invalid_result;

    rewarded_ad.onPaidEvent =
        (
          Ad ad,
          double value_micros,
          PrecisionType precision,
          String currency_code,
        ) {
          _log(
            '收入事件，valueMicros=$value_micros, '
            'precision=${precision.name}, currencyCode=$currency_code',
          );
        };

    rewarded_ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        _log('广告已进入全屏展示');
      },
      onAdImpression: (Ad ad) {
        _log('广告曝光已记录');
      },
      onAdClicked: (Ad ad) {
        _log('用户点击了广告');
      },
      onAdWillDismissFullScreenContent: (Ad ad) {
        _log('广告即将关闭');
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        _log(
          '广告展示失败，code=${error.code}, domain=${error.domain}, '
          'message=${error.message}',
          type: 'e',
        );
        complete_result(GoogleRewardedAdResult.show_failed);
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        _log(
          '广告已关闭，奖励状态: ${has_earned_reward ? '已获得' : '未获得'}'
          '${earned_reward == null ? '' : '，数量=${earned_reward!.amount}, '
                    '类型=${earned_reward!.type}'}',
        );
        complete_result(
          has_earned_reward
              ? GoogleRewardedAdResult.rewarded
              : GoogleRewardedAdResult.dismissed,
        );
      },
    );

    try {
      // 在调用 SDK 前结束准备阶段，广告自身引起的后台事件不能取消奖励。
      preparation.mark_presented();
      await rewarded_ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (result_completer.isCompleted) return;
          has_earned_reward = true;
          earned_reward = reward;
          _log('用户获得奖励，amount=${reward.amount}, type=${reward.type}');
        },
      );
      return await result_completer.future;
    } catch (error, stack_trace) {
      _log('调用广告展示异常: $error\n$stack_trace', type: 'e');
      complete_result(GoogleRewardedAdResult.show_failed);
      return result_completer.future;
    }
  }

  /// 输出广告流程日志。
  void _log(String message, {String? type}) {
    logUtil(msg: '$_log_prefix $message', type: type);
  }
}

/// 只观察展示前的准备阶段，取消后不会因返回前台而恢复旧请求。
class _RewardedAdPreparation with WidgetsBindingObserver {
  _RewardedAdPreparation(this._can_show)
    : _privacy_revision =
          AdMobConsentPermissionRequest.privacy_choice_revision.value {
    WidgetsBinding.instance.addObserver(this);
    AdMobConsentPermissionRequest.privacy_choice_revision.addListener(
      _on_privacy_changed,
    );
    if (Get.isRegistered<ProjectConfigStore>()) {
      _policy_worker = ever<int>(
        Get.find<ProjectConfigStore>().config_revision,
        (_) {
          if (!AdDisplayPolicy.can_show_ads()) {
            _cancel(GoogleRewardedAdResult.disabled);
          }
        },
      );
    }
  }

  final bool Function()? _can_show;
  final int _privacy_revision;
  final Completer<GoogleRewardedAdResult> _cancelled =
      Completer<GoogleRewardedAdResult>();
  Worker? _policy_worker;
  Timer? _timeout;
  bool _is_disposed = false;
  bool _has_presented = false;
  GoogleRewardedAdResult? _cancelled_result;

  Future<GoogleRewardedAdResult> get cancelled => _cancelled.future;
  bool get is_active => !_is_disposed && _cancelled_result == null;

  /// 当前准备工作是否仍然属于可展示的用户操作。
  GoogleRewardedAdResult? invalid_result() {
    if (_cancelled_result != null) return _cancelled_result;
    if (_is_disposed) return GoogleRewardedAdResult.cancelled;
    if (!AdDisplayPolicy.can_show_ads()) return GoogleRewardedAdResult.disabled;
    if (_privacy_revision !=
        AdMobConsentPermissionRequest.privacy_choice_revision.value) {
      return GoogleRewardedAdResult.cancelled;
    }
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) {
      return GoogleRewardedAdResult.cancelled;
    }
    if (_can_show != null && !_can_show()) {
      return GoogleRewardedAdResult.cancelled;
    }
    return null;
  }

  void start_timeout() {
    if (!is_active) return;
    _timeout = Timer(GoogleRewardedAdUtil.preparation_timeout, () {
      _cancel(GoogleRewardedAdResult.load_failed);
    });
  }

  void _on_privacy_changed() => _cancel(GoogleRewardedAdResult.cancelled);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cancel(GoogleRewardedAdResult.cancelled);
    }
  }

  void _cancel(GoogleRewardedAdResult result) {
    if (!is_active || _has_presented) return;
    _cancelled_result = result;
    _cancelled.complete(result);
    _timeout?.cancel();
  }

  void mark_presented() {
    _has_presented = true;
    _timeout?.cancel();
  }

  void dispose() {
    _is_disposed = true;
    _timeout?.cancel();
    _policy_worker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    AdMobConsentPermissionRequest.privacy_choice_revision.removeListener(
      _on_privacy_changed,
    );
  }
}
