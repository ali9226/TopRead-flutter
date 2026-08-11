import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';

/// Google User Messaging Platform（UMP）隐私同意请求器。
///
/// App 启动触发逻辑：
/// 1. Android 和 iOS 每次冷启动的第一帧完成后调用 [update_on_app_start]。
/// 2. 启动阶段只联网刷新用户所在地区与同意状态，不主动展示 UMP 表单，
///    避免破坏网络、通知和 ATT 已有的系统弹窗顺序。
///
/// 广告触发逻辑：
/// 1. 每次真正加载广告前调用 [request_before_ad]。
/// 2. 若本次启动尚未成功刷新状态，则先重试刷新。
/// 3. 展示当前地区法规要求的 UMP 表单，并等待用户完成选择。
/// 4. 只有 UMP 返回允许请求广告时，才允许初始化 Google Mobile Ads SDK。
///
/// 隐私选项触发逻辑：
/// 1. “关于 TopRead”页面通过 [is_privacy_options_required] 判断是否需要入口。
/// 2. 用户点击入口后调用 [show_privacy_options_form] 修改或撤回选择。
class AdMobConsentPermissionRequest {
  const AdMobConsentPermissionRequest._();

  /// 本次进程是否已经成功刷新过 UMP 同意状态。
  static bool _has_updated_this_session = false;

  /// 当前正在执行的同意状态刷新，用于合并启动与广告入口的并发请求。
  static Future<bool>? _active_update;

  /// 当前正在执行的广告前同意流程，防止用户快速点击造成多个表单。
  static Future<bool>? _active_ad_request;

  /// 当前正在展示的隐私选项表单，防止列表项被重复点击。
  static Future<bool>? _active_privacy_options_request;

  /// App 每次冷启动第一帧完成后调用，只更新状态，不展示表单。
  static Future<void> update_on_app_start() async {
    if (!isNativeMobileApp) return;
    await _update_consent_information();
  }

  /// 广告加载前调用，返回是否可以向 Google 请求广告。
  static Future<bool> request_before_ad() {
    if (!isNativeMobileApp) {
      return Future<bool>.value(false);
    }

    final Future<bool>? active_request = _active_ad_request;
    if (active_request != null) {
      return active_request;
    }

    final Future<bool> request = _request_before_ad_internal();
    _active_ad_request = request;
    return request.whenComplete(() {
      if (identical(_active_ad_request, request)) {
        _active_ad_request = null;
      }
    });
  }

  /// 判断法规是否要求在 App 内提供可随时访问的隐私选项入口。
  static Future<bool> is_privacy_options_required() async {
    if (!isNativeMobileApp) return false;

    if (!_has_updated_this_session) {
      await _update_consent_information();
    }

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
  static Future<bool> _request_before_ad_internal() async {
    if (!_has_updated_this_session) {
      await _update_consent_information();
    }

    try {
      FormError? consent_form_error;
      await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
        consent_form_error = error;
      });
      if (consent_form_error != null) {
        logUtil(
          msg:
              'UMP: 必要同意表单处理失败: '
              '${consent_form_error!.errorCode} ${consent_form_error!.message}',
          type: 'e',
        );
      }

      final bool can_request_ads = await ConsentInformation.instance
          .canRequestAds();
      logUtil(msg: 'UMP: 广告请求许可状态: $can_request_ads');
      return can_request_ads;
    } catch (error) {
      // UMP 状态未知时禁止初始化广告 SDK，避免未经同意发送广告请求。
      logUtil(msg: 'UMP: 广告前同意流程失败: $error', type: 'e');
      return false;
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
      return true;
    } catch (error) {
      logUtil(msg: 'UMP: 隐私选项表单异常: $error', type: 'e');
      return false;
    }
  }
}
