// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/components/authorized_login/apple_login.dart';
import 'package:app/components/authorized_login/telegram_login.dart';
import 'package:app/config/constant.dart';
import 'package:app/fcm/fcm_auth.dart';
import 'package:app/models/login.dart';
import 'package:app/models/rotation.dart';
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
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'google_login.dart';

/// 授权登录组件逻辑处理。
class Logic {
  /// 当前上下文。
  final BuildContext context;

  Logic(this.context);

  /// 处理授权登录项点击事件。
  Future<void> handle_authorized_login_tap(Rotation item) async {
    if (item.title.trim().toLowerCase() == 'google') {
      await google_login();
      return;
    }

    if (item.title.trim().toLowerCase() == 'telegram') {
      await telegram_login(context);
      return;
    }

    if (item.title.trim().toLowerCase() == 'apple') {
      await _handle_apple_login();
      return;
    }

    await open_rotation_jump(item);
  }

  /// 处理 Apple 登录完整流程。
  ///
  /// 先获取授权信息，成功后请求后端接口完成登录。
  Future<void> _handle_apple_login() async {
    /// 获取全局授权登录状态管理。
    final AuthorizedLoginStore authorized_login_store =
        Get.find<AuthorizedLoginStore>();

    /// 获取 Apple 授权信息。
    final AuthorizationCredentialAppleID? credential = await apple_login();

    /// 授权失败或用户取消，直接返回。
    if (credential == null) {
      return;
    }

    /// 设置加载状态，标记当前平台为 apple，显示转圈效果。
    authorized_login_store.loading.value = true;
    authorized_login_store.loading_platform.value = 'apple';

    try {
      /// 构建请求参数。
      final Map<String, dynamic> parameter = {
        'identity_token': credential.identityToken,
        'authorization_code': credential.authorizationCode,
        'user_identifier': credential.userIdentifier,
        'given_name': credential.givenName ?? '',
        'family_name': credential.familyName ?? '',
        'email': credential.email ?? '',
      };

      /// 打印请求参数，方便调试后端逻辑。
      logUtil(msg: "===== Apple 登录请求参数 =====");
      logUtil(msg: "请求路径: user/apple_login");
      parameter.forEach((key, value) {
        logUtil(msg: "$key: $value");
      });
      logUtil(msg: "===== Apple 登录请求参数结束 =====");

      /// 请求后端 Apple 登录接口。
      final ResultsType<Login> results = await postRequest<Login>(
        path: 'user/apple_login',
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

      /// 跳转首页。
      routerUtil(path: '/', type: 'replace');
    } catch (error) {
      logUtil(msg: "Apple 登录后端请求失败: $error", type: 'e');
      showBottomTip(tr('AuthorizedLogin.apple_auth_failed'));
    } finally {
      /// 重置加载状态。
      authorized_login_store.loading.value = false;
      authorized_login_store.loading_platform.value = '';
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
