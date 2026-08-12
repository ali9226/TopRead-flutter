import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/permission_request/app_tracking_transparency_permission_request.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';

/// 本次冷启动的 UMP/ATT 流程结果，供后续通知权限调度使用。
class AdMobStartupPrivacyResult {
  const AdMobStartupPrivacyResult({
    required this.can_request_ads,
    required this.did_update_consent_information,
    required this.did_present_privacy_prompt,
  });

  final bool can_request_ads;
  final bool did_update_consent_information;
  final bool did_present_privacy_prompt;

  /// UMP 状态已成功刷新，且本次没有法规、IDFA 或 ATT 界面时，
  /// 才适合继续检查通知权限。
  bool get can_continue_to_notification_permission =>
      !did_present_privacy_prompt;
}

/// Google User Messaging Platform（UMP）隐私同意请求器。
///
/// App 启动触发逻辑：
/// 1. Android 和 iOS 每次冷启动的第一帧完成后调用
///    [initialize_on_app_start]。
/// 2. 先刷新用户所在地区与同意状态，再展示必要的 UMP 表单。
/// 3. iOS 的 IDFA 铺垫消息和后续 ATT 系统弹窗交给 UMP 统一触发；
///    App 不再主动抢先请求 ATT。
///
/// 广告触发逻辑：
/// 1. 每个广告位在加载前调用 [request_before_ad]。
/// 2. 本次 App 进程内所有广告位共享同一个 Future，多个原生广告卡片
///    并发创建时也不会重复展示表单。
/// 3. 只有 UMP 返回允许请求广告时，才允许初始化 Google Mobile Ads SDK。
///
/// 隐私选项触发逻辑：
/// 1. “关于 TopRead”页面通过 [is_privacy_options_required] 判断是否需要入口。
/// 2. 用户点击入口后调用 [show_privacy_options_form] 修改或撤回选择。
class AdMobConsentPermissionRequest {
  const AdMobConsentPermissionRequest._();

  /// 启动根组件首帧已经完成，可以安全展示系统或 UMP 权限 UI。
  ///
  /// 首页瀑布流广告可能在首帧期间先调用 [request_before_ad]。这种情况下
  /// 可以先刷新 UMP 状态，但必要表单会等待 [initialize_on_app_start]
  /// 发出首帧就绪信号，避免在应用界面尚未稳定时抢先弹窗。
  static Completer<void> _privacy_ui_ready = Completer<void>();

  /// 本次进程是否已经成功刷新过 UMP 同意状态。
  static bool _has_updated_this_session = false;

  /// 当前正在执行的同意状态刷新，用于合并启动与广告入口的并发请求。
  static Future<bool>? _active_update;

  /// 本次 App 进程共享的广告请求许可结果。
  ///
  /// 启动流程、激励广告、正文原生广告和未来首页瀑布流广告都等待
  /// 这一个 Future，从而保证权限 UI 只有一个调度者。
  static Future<AdMobStartupPrivacyResult>? _session_privacy_result;

  /// 当前正在展示的隐私选项表单，防止列表项被重复点击。
  static Future<bool>? _active_privacy_options_request;

  /// 用户通过隐私选项表单更新选择的代次。
  ///
  /// 长期存活的原生广告位应监听该值，变化时释放已加载广告并按最新
  /// UMP 结果重新决定是否加载。
  static final ValueNotifier<int> _privacy_choice_revision = ValueNotifier<int>(
    0,
  );

  static ValueListenable<int> get privacy_choice_revision =>
      _privacy_choice_revision;

  /// App 每次冷启动第一帧完成后调用。
  ///
  /// 此方法会完成本次进程唯一的 UMP 流程。iOS 上如果 AdMob 后台已发布
  /// IDFA 铺垫消息，UMP 会在合适的地区和状态下自动衔接 ATT 系统弹窗。
  static Future<bool> initialize_on_app_start() {
    return initialize_on_app_start_with_result().then(
      (AdMobStartupPrivacyResult result) => result.can_request_ads,
    );
  }

  /// App 首帧后的完整启动隐私结果，供通知权限协调器判断是否继续弹窗。
  static Future<AdMobStartupPrivacyResult>
  initialize_on_app_start_with_result() {
    if (!isNativeMobileApp) {
      return Future<AdMobStartupPrivacyResult>.value(
        const AdMobStartupPrivacyResult(
          can_request_ads: false,
          did_update_consent_information: false,
          did_present_privacy_prompt: false,
        ),
      );
    }
    if (!_privacy_ui_ready.isCompleted) {
      _privacy_ui_ready.complete();
    }
    return _get_or_start_privacy_flow();
  }

  /// 向后兼容旧的启动调用名称。
  @Deprecated('Use initialize_on_app_start so required UMP forms are shown.')
  static Future<void> update_on_app_start() async {
    await request_before_ad();
  }

  /// 广告加载前调用，返回是否可以向 Google 请求广告。
  static Future<bool> request_before_ad() async {
    if (!isNativeMobileApp) {
      return false;
    }

    final AdMobStartupPrivacyResult result = await _get_or_start_privacy_flow();
    return result.can_request_ads;
  }

  /// 启动、激励广告和所有原生广告位共享同一条隐私流程。
  static Future<AdMobStartupPrivacyResult> _get_or_start_privacy_flow() {
    return _session_privacy_result ??= _request_before_ad_internal();
  }

  /// 判断法规是否要求在 App 内提供可随时访问的隐私选项入口。
  static Future<bool> is_privacy_options_required() async {
    if (!isNativeMobileApp) return false;

    await initialize_on_app_start();

    try {
      final PrivacyOptionsRequirementStatus status = await ConsentInformation
          .instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      logUtil(msg: 'UMP: 读取隐私选项入口状态失败: $error', type: 'e');
      return false;
    }
  }

  /// 展示 UMP 隐私选项表单，让用户修改或撤回之前的同意选择。
  static Future<bool> show_privacy_options_form() {
    if (!isNativeMobileApp) {
      return Future<bool>.value(false);
    }

    final Future<bool>? active_request = _active_privacy_options_request;
    if (active_request != null) {
      return active_request;
    }

    final Future<bool> request = _show_privacy_options_form_internal();
    _active_privacy_options_request = request;
    return request.whenComplete(() {
      if (identical(_active_privacy_options_request, request)) {
        _active_privacy_options_request = null;
      }
    });
  }

  /// 刷新同意状态、展示必要表单并读取最终广告请求权限。
  static Future<AdMobStartupPrivacyResult> _request_before_ad_internal() async {
    // 首页广告位可能先于根组件首帧进入 initState。等根组件开始启动权限
    // 协调后再联网刷新 UMP，便于统一观察网络、UMP、IDFA 和 ATT 弹窗。
    await _privacy_ui_ready.future;
    final bool did_update = await _update_consent_information();
    ConsentStatus consent_status_before = ConsentStatus.unknown;
    AppTrackingAuthorizationStatus att_status_before =
        AppTrackingAuthorizationStatus.unknown;

    try {
      if (did_update) {
        consent_status_before = await ConsentInformation.instance
            .getConsentStatus();
        if (isIOSApp) {
          att_status_before =
              await AppTrackingTransparencyPermissionRequest.get_authorization_status();
        }

        FormError? consent_form_error;
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          consent_form_error = error;
        });
        if (consent_form_error != null) {
          logUtil(
            msg:
                'UMP: 必要同意表单处理失败: '
                '${consent_form_error!.errorCode} '
                '${consent_form_error!.message}',
            type: 'e',
          );
        }
      } else {
        // 刷新失败时不尝试加载新表单，但仍按 Google 建议读取上一次
        // 会话持久化的 canRequestAds 状态。首次安装且状态未知时会返回 false。
        logUtil(msg: 'UMP: 同意状态刷新失败，尝试使用上一次会话状态', type: 'w');
      }

      final bool can_request_ads = await ConsentInformation.instance
          .canRequestAds();
      final ConsentStatus consent_status_after = did_update
          ? await ConsentInformation.instance.getConsentStatus()
          : ConsentStatus.unknown;
      final AppTrackingAuthorizationStatus att_status_after =
          did_update && isIOSApp
          ? await AppTrackingTransparencyPermissionRequest.get_authorization_status()
          : AppTrackingAuthorizationStatus.unknown;
      // google_mobile_ads 目前不会返回“表单是否实际出现”的布尔值。
      // 因此用调用前后的 UMP/ATT 状态变化判断用户本次是否完成了权限界面；
      // iOS 网络等系统弹窗则由根组件的 App 生命周期监听补充判断。
      final bool did_present_privacy_prompt =
          (consent_status_before == ConsentStatus.required &&
              consent_status_after != ConsentStatus.required) ||
          (att_status_before == AppTrackingAuthorizationStatus.not_determined &&
              att_status_after !=
                  AppTrackingAuthorizationStatus.not_determined &&
              att_status_after != AppTrackingAuthorizationStatus.unknown);
      logUtil(msg: 'UMP: 广告请求许可状态: $can_request_ads');
      logUtil(msg: 'UMP: 本次是否展示隐私/ATT界面: $did_present_privacy_prompt');
      return AdMobStartupPrivacyResult(
        can_request_ads: can_request_ads,
        did_update_consent_information: did_update,
        did_present_privacy_prompt: did_present_privacy_prompt,
      );
    } catch (error) {
      // UMP 状态未知时禁止初始化广告 SDK，避免未经同意发送广告请求。
      logUtil(msg: 'UMP: 广告前同意流程失败: $error', type: 'e');
      return const AdMobStartupPrivacyResult(
        can_request_ads: false,
        did_update_consent_information: false,
        did_present_privacy_prompt: false,
      );
    }
  }

  /// 请求 UMP 更新当前用户所在地区和隐私同意状态。
  static Future<bool> _update_consent_information() {
    if (_has_updated_this_session) {
      return Future<bool>.value(true);
    }

    final Future<bool>? active_update = _active_update;
    if (active_update != null) {
      return active_update;
    }

    final Completer<bool> completer = Completer<bool>();
    _active_update = completer.future;
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          _has_updated_this_session = true;
          logUtil(msg: 'UMP: 隐私同意状态更新完成');
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        (FormError error) {
          logUtil(
            msg:
                'UMP: 隐私同意状态更新失败: '
                '${error.errorCode} ${error.message}',
            type: 'e',
          );
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );
    } catch (error) {
      logUtil(msg: 'UMP: 发起隐私同意状态更新失败: $error', type: 'e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future.whenComplete(() {
      if (identical(_active_update, completer.future)) {
        _active_update = null;
      }
    });
  }

  /// 调用 UMP 原生隐私选项表单并返回是否成功展示、关闭。
  static Future<bool> _show_privacy_options_form_internal() async {
    try {
      // 避免隐私选项表单与启动阶段的法规/IDFA 表单并发展示。
      await request_before_ad();

      FormError? privacy_options_error;
      await ConsentForm.showPrivacyOptionsForm((FormError? error) {
        privacy_options_error = error;
      });
      if (privacy_options_error != null) {
        logUtil(
          msg:
              'UMP: 隐私选项表单展示失败: '
              '${privacy_options_error!.errorCode} '
              '${privacy_options_error!.message}',
          type: 'e',
        );
        return false;
      }

      logUtil(msg: 'UMP: 隐私选项表单已关闭');
      final bool can_request_ads = await ConsentInformation.instance
          .canRequestAds();
      // 用户修改选择后，让后续新建的广告位立即使用最新结果。
      _session_privacy_result = Future<AdMobStartupPrivacyResult>.value(
        AdMobStartupPrivacyResult(
          can_request_ads: can_request_ads,
          did_update_consent_information: true,
          // 这是用户主动打开的隐私选项，不参与启动通知弹窗判断。
          did_present_privacy_prompt: false,
        ),
      );
      _privacy_choice_revision.value += 1;
      logUtil(msg: 'UMP: 隐私选项更新后广告请求许可: $can_request_ads');
      return true;
    } catch (error) {
      logUtil(msg: 'UMP: 隐私选项表单异常: $error', type: 'e');
      return false;
    }
  }

  /// 清理进程内缓存，仅供单元测试隔离用例。
  @visibleForTesting
  static void reset_for_test() {
    _has_updated_this_session = false;
    _active_update = null;
    _session_privacy_result = null;
    _active_privacy_options_request = null;
    _privacy_ui_ready = Completer<void>();
    _privacy_choice_revision.value = 0;
  }
}
