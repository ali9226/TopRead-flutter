// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/components/authorized_login/apple_login.dart';
import 'package:app/components/authorized_login/telegram_login.dart';
import 'package:app/config/constant.dart';
import 'package:app/fcm/fcm_auth.dart';
import 'package:app/models/login.dart';
import 'package:app/models/rotation.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/customer_service/open_rotation_jump.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'google_login.dart';

/// 授权登录组件逻辑处理。
class Logic {
  /// 当前上下文。
  final BuildContext context;

  Logic(this.context);

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
    /// 占用全局认证锁，防止重复点击或并发启动其他认证流程。
    if (!authorized_login_store.try_start_authentication('google')) {
      return;
    }

    try {
      /// 通过 Firebase 获取 Google 授权信息。
      final GoogleLoginResult? result = await google_login();

      /// 授权失败或用户取消，直接返回。
      if (result == null) {
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

      /// 打印请求参数，方便调试后端逻辑。
      logUtil(msg: "===== Google 登录请求参数 =====");
      logUtil(msg: "请求路径: user/firebase_login");
      parameter.forEach((key, value) {
        logUtil(msg: "$key: $value");
      });
      logUtil(msg: "===== Google 登录请求参数结束 =====");

      /// 请求后端 Firebase 登录接口。
      final ResultsType<Login> results = await postRequest<Login>(
        path: 'user/firebase_login',
        parameter: parameter,
        fromJson: (Map<String, dynamic> json) => Login.fromJson(json),
      );

      if (!results.status || results.content == null) {
        return;
      }

      /// 获取 token。
      final String token = results.content?.token.toString() ?? '';
      if (token.isEmpty) {
        showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
        return;
      }

      /// 保存 token。
      await StorageUtil.saveData(Constant.tokenKey, token);

      /// 保存用户信息。
      final UserInformation user_controller = Get.put(UserInformation());
      user_controller.saveUserInfo(results.content!.userInfo);

      /// 绑定 FCM Token 到用户。
      FcmAuth.onLoginSuccess();

      /// 用户主动完成 Google 登录后申请系统通知权限。
      unawaited(NotificationPermissionRequest.request_after_login());

      /// 跳转首页。
      routerUtil(path: '/', type: 'replace');
    } catch (error) {
      logUtil(msg: "Google 登录后端请求失败: $error", type: 'e');
      showBottomTip(tr('AuthorizedLogin.google_auth_failed'));
    } finally {
      /// 重置加载状态。
      authorized_login_store.finish_authentication('google');
    }
  }

  /// 处理 Telegram 登录完整流程。
  Future<void> _handle_telegram_login(
    AuthorizedLoginStore authorized_login_store,
  ) async {
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
    /// 占用全局认证锁，防止重复点击或并发启动其他认证流程。
    if (!authorized_login_store.try_start_authentication('apple')) {
      return;
    }

    try {
      /// 通过 Firebase 获取 Apple 授权信息。
      final AppleLoginResult? result = await apple_login();

      /// 授权失败或用户取消，直接返回。
      if (result == null) {
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

      /// 请求后端 Apple 登录接口。
      final ResultsType<Login> results = await postRequest<Login>(
        path: 'user/firebase_login',
        parameter: parameter,
        fromJson: (Map<String, dynamic> json) => Login.fromJson(json),
      );

      if (!results.status || results.content == null) {
        return;
      }

      /// 获取 token。
      final String token = results.content?.token.toString() ?? '';
      if (token.isEmpty) {
        showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
        return;
      }

      /// 保存 token。
      await StorageUtil.saveData(Constant.tokenKey, token);

      /// 保存用户信息。
      final UserInformation user_controller = Get.put(UserInformation());
      user_controller.saveUserInfo(results.content!.userInfo);

      /// 绑定 FCM Token 到用户。
      FcmAuth.onLoginSuccess();

      /// 用户主动完成 Apple 登录后申请系统通知权限。
      unawaited(NotificationPermissionRequest.request_after_login());

      /// 跳转首页。
      routerUtil(path: '/', type: 'replace');
    } catch (error) {
      logUtil(msg: "Apple 登录后端请求失败: $error", type: 'e');
      showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
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
