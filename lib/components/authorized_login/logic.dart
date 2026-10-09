// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/components/authorized_login/apple_login.dart';
import 'package:app/components/authorized_login/telegram_login.dart';
import 'package:app/models/login.dart';
import 'package:app/models/rotation.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/services/post_login_sync_service.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/customer_service/open_rotation_jump.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'google_login.dart';

/// 授权登录组件逻辑处理。
class Logic {
  /// 当前上下文。
  final BuildContext context;

  Logic(
    this.context, {
    @visibleForTesting Future<GoogleLoginResult?> Function()? google_authorizer,
    @visibleForTesting Future<AppleLoginResult?> Function()? apple_authorizer,
    @visibleForTesting
    Future<ResultsType<Login>> Function(Map<String, dynamic>)? login_request,
    @visibleForTesting VoidCallback? on_login_completed,
  }) : _google_authorizer = google_authorizer ?? google_login,
       _apple_authorizer = apple_authorizer ?? apple_login,
       _login_request = login_request ?? _request_login,
       _on_login_completed = on_login_completed;

  final Future<GoogleLoginResult?> Function() _google_authorizer;
  final Future<AppleLoginResult?> Function() _apple_authorizer;
  final Future<ResultsType<Login>> Function(Map<String, dynamic>)
  _login_request;
  final VoidCallback? _on_login_completed;

  static Future<ResultsType<Login>> _request_login(
    Map<String, dynamic> parameter,
  ) => postRequest<Login>(
    path: 'user/firebase_login',
    parameter: parameter,
    fromJson: (json) => Login.fromJson(json),
  );

  /// 认证结果只有在发起页面和会话均有效时才允许提交凭证与跳转。
  bool _is_current(UserInformation user_controller, int revision) =>
      context.mounted && user_controller.is_auth_revision_current(revision);

  Future<void> _complete_login(
    Map<String, dynamic> parameter,
    UserInformation user_controller,
    int request_revision,
    String failure_message_key,
  ) async {
    final ResultsType<Login> results = await _login_request(parameter);
    if (!_is_current(user_controller, request_revision) ||
        !results.status ||
        results.content == null)
      return;

    final Login login_data = results.content!;
    if (login_data.token.isEmpty || login_data.userInfo.id <= 0) {
      showBottomTip(tr(failure_message_key));
      return;
    }
    if (!await user_controller.save_auth_credentials_if_current(
      token: login_data.token,
      info: login_data.userInfo,
      request_revision: request_revision,
      is_active: () => context.mounted,
    ))
      return;

    if (_on_login_completed != null) {
      _on_login_completed();
      return;
    }
    PostLoginSyncService.start();
    unawaited(NotificationPermissionRequest.request_after_login());
    routerUtil(path: '/', type: 'replace');
  }

  /// 处理授权登录项点击事件。
  Future<void> handle_authorized_login_tap(Rotation item) async {
    /// 获取全局授权登录状态管理。
    final AuthorizedLoginStore authorized_login_store =
        Get.find<AuthorizedLoginStore>();

    /// 如果有其他授权登录正在进行中，直接返回。
    if (authorized_login_store.loading.value) {
      return;
    }

    if (item.title.trim().toLowerCase() == 'google') {
      await _handle_google_login(authorized_login_store);
      return;
    }

    if (item.title.trim().toLowerCase() == 'telegram') {
      await _handle_telegram_login(authorized_login_store);
      return;
    }

    if (item.title.trim().toLowerCase() == 'apple') {
      await _handle_apple_login(authorized_login_store);
      return;
    }

    await open_rotation_jump(item);
  }

  /// 处理 Google 登录完整流程。
  ///
  /// 通过 Firebase 进行 Google 授权，成功后请求后端接口完成登录。
  Future<void> _handle_google_login(
    AuthorizedLoginStore authorized_login_store,
  ) async {
    if (!context.mounted) return;

    /// 占用全局认证锁，防止重复点击或并发启动其他认证流程。
    if (!authorized_login_store.try_start_authentication('google')) {
      return;
    }
    final UserInformation user_controller = Get.find<UserInformation>();
    final int request_revision = user_controller.auth_revision;

    try {
      /// 通过 Firebase 获取 Google 授权信息。
      final GoogleLoginResult? result = await _google_authorizer();

      /// 授权失败或用户取消，直接返回。
      if (result == null || !_is_current(user_controller, request_revision)) {
        return;
      }

      /// 构建请求参数。
      final Map<String, dynamic> parameter = {
        'firebase_uid': result.user.uid,
        'identity_token': result.firebaseIdToken,
        'email': result.user.email ?? '',
        'given_name': result.user.displayName ?? '',
        'uuid_type': 4,
        'note': 'firebase Google授权登录',
      };

      await _complete_login(
        parameter,
        user_controller,
        request_revision,
        'AuthorizedLogin.google_auth_failed',
      );
    } catch (error) {
      logUtil(msg: "Google 登录后端请求失败: $error", type: 'e');
      if (_is_current(user_controller, request_revision)) {
        showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
      }
    } finally {
      /// 重置加载状态。
      authorized_login_store.finish_authentication('google');
    }
  }

  /// 处理 Telegram 登录完整流程。
  Future<void> _handle_telegram_login(
    AuthorizedLoginStore authorized_login_store,
  ) async {
    if (!context.mounted) return;

    /// 占用全局认证锁，防止重复点击或并发启动其他认证流程。
    if (!authorized_login_store.try_start_authentication('telegram')) {
      return;
    }

    try {
      await telegram_login(context);
    } finally {
      /// 重置加载状态。
      authorized_login_store.finish_authentication('telegram');
    }
  }

  /// 处理 Apple 登录完整流程。
  ///
  /// 通过 Firebase 进行 Apple 授权，成功后请求后端接口完成登录。
  Future<void> _handle_apple_login(
    AuthorizedLoginStore authorized_login_store,
  ) async {
    if (!context.mounted) return;

    /// 占用全局认证锁，防止重复点击或并发启动其他认证流程。
    if (!authorized_login_store.try_start_authentication('apple')) {
      return;
    }
    final UserInformation user_controller = Get.find<UserInformation>();
    final int request_revision = user_controller.auth_revision;

    try {
      /// 通过 Firebase 获取 Apple 授权信息。
      final AppleLoginResult? result = await _apple_authorizer();

      /// 授权失败或用户取消，直接返回。
      if (result == null || !_is_current(user_controller, request_revision)) {
        return;
      }

      /// 构建请求参数。
      final Map<String, dynamic> parameter = {
        'firebase_uid': result.user.uid,
        'identity_token': result.firebaseIdToken,
        'authorization_code': result.authorizationCode,
        'email': result.user.email ?? '',
        'given_name': result.givenName ?? '',
        'family_name': result.familyName ?? '',
        'uuid_type': 3,
        'note': 'firebase Apple授权登录',
      };

      await _complete_login(
        parameter,
        user_controller,
        request_revision,
        'AuthorizedLogin.apple_auth_failed',
      );
    } catch (error) {
      logUtil(msg: "Apple 登录后端请求失败: $error", type: 'e');
      if (_is_current(user_controller, request_revision)) {
        showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
      }
    } finally {
      /// 重置加载状态。
      authorized_login_store.finish_authentication('apple');
    }
  }

  /// 获取授权登录展示标题。
  String get_authorized_login_title(Rotation item) {
    if (item.title.trim().isNotEmpty) {
      return item.title.trim();
    }
    if (item.represent.trim().isNotEmpty) {
      return item.represent.trim();
    }
    return item.note.trim();
  }

  /// 获取授权登录 svg 图标名称。
  String get_authorized_login_svg_name(Rotation item) {
    if (item.note.trim().isNotEmpty) {
      return item.note.trim();
    }
    if (item.represent.trim().isNotEmpty) {
      return item.represent.trim();
    }
    return 'public';
  }
}
