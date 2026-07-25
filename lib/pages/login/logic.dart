import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/fcm/fcm_auth.dart';
import 'package:app/message/message_service.dart';
import 'package:app/models/login.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/aes_encryption.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/string/to_string.dart';
import 'package:app/websocket/websocket_auth.dart';
import 'package:get/get.dart';

const String accountKey = 'account';
const String passwordKey = 'password';

/// 登录页逻辑控制器。
class Logic {
  Logic();

  /// 用户输入的账号。
  String account = '';

  /// 用户输入的密码。
  String password = '';

  /// 用户输入的邀请码。
  String invitationCode = '';

  /// 是否记住密码。
  bool remember = true;

  /// 账号是否已注册：null 表示未验证，true 已注册，false 未注册。
  bool? isAccountRegistered;

  /// 外部页面注入的账号输入框控制器。
  TextEditingController? accountController;

  /// 外部页面注入的密码输入框控制器。
  TextEditingController? passwordController;

  /// 初始化登录表单的缓存数据。
  Future<void> init() async {
    final String? storageAccountEncryption = await StorageUtil.getData(
      accountKey,
    );

    if (storageAccountEncryption == null || storageAccountEncryption.isEmpty) {
      return;
    }

    final String storageAccount = aesDecryption(storageAccountEncryption);

    if (storageAccount.isEmpty) {
      await StorageUtil.removeData(accountKey);
      return;
    }

    account = storageAccount;
    accountController?.text = account;

    final String? storagePasswordEncryption = await StorageUtil.getData(
      passwordKey,
    );
    if (storagePasswordEncryption == null ||
        storagePasswordEncryption.isEmpty) {
      return;
    }

    final String storagePassword = aesDecryption(storagePasswordEncryption);
    if (storagePassword.isEmpty) {
      await StorageUtil.removeData(passwordKey);
      return;
    }

    password = storagePassword;
    passwordController?.text = password;
  }

  /// 验证账号是否已注册。
  ///
  /// 调用 user/register_verify 接口，返回 true 表示已注册，false 表示未注册。
  Future<bool> verifyAccount() async {
    if (account.isEmpty) {
      isAccountRegistered = null;
      return false;
    }

    try {
      final results = await postRequest<Map<String, dynamic>>(
        path: 'user/register_verify',
        parameter: {'account': removeSpaces(account)},
        showTips: false,
        fromJson: (json) => json,
      );

      /// 接口返回 {status: true} 表示已注册。
      if (results.status && results.content != null) {
        isAccountRegistered = results.content!['status'] == true;
      } else {
        isAccountRegistered = false;
      }
      return isAccountRegistered!;
    } catch (e) {
      isAccountRegistered = null;
      return false;
    }
  }

  /// 执行登录请求。
  Future<bool> login() async {
    if (account.isEmpty) {
      showBottomTip(easy.tr('login.account_tips'));
      return false;
    }

    if (password.isEmpty) {
      showBottomTip(easy.tr('login.password_tips'));
      return false;
    }

    final Map<String, dynamic> parameter = {
      'account': removeSpaces(account),
      'password': passwordEncryption(removeSpaces(password)),
    };

    final String accountEncrypted = aesEncryption(account);
    await StorageUtil.saveData(accountKey, accountEncrypted);

    if (remember) {
      final String passwordEncrypted = aesEncryption(password);
      await StorageUtil.saveData(passwordKey, passwordEncrypted);
    }

    final results = await postRequest<Login>(
      path: 'user/login',
      parameter: parameter,
      fromJson: (json) => Login.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;

    await StorageUtil.saveData(Constant.tokenKey, token);

    final userController = Get.put(UserInformation());
    if (results.content?.userInfo != null) {
      userController.saveUserInfo(results.content!.userInfo);
    }

    if (!remember) {
      await StorageUtil.removeData(passwordKey);
    }

    // 登录成功，切换 WebSocket 连接（断开访客连接，用 token 重新连接）。
    await WebSocketAuth.onLoginSuccess();
    // 清空访客数据，获取已登录用户的未读消息。
    await MessageService.fetchUnreadAfterLogin();
    // 绑定 FCM Token 到用户。
    await FcmAuth.onLoginSuccess();

    showBottomTip(easy.tr('login.success_01'));
    return true;
  }

  /// 执行注册请求（当账号未注册时使用）。
  Future<bool> register() async {
    if (account.isEmpty) {
      showBottomTip(easy.tr('login.account_tips'));
      return false;
    }

    if (password.isEmpty) {
      showBottomTip(easy.tr('login.password_tips'));
      return false;
    }

    final Map<String, dynamic> parameter = {
      'account': removeSpaces(account),
      'password': passwordEncryption(removeSpaces(password)),
      'invitation_code': invitationCode,
    };

    final results = await postRequest<Login>(
      path: 'user/register',
      parameter: parameter,
      fromJson: (json) => Login.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;

    await StorageUtil.saveData(Constant.tokenKey, token);

    final userController = Get.put(UserInformation());
    if (results.content?.userInfo != null) {
      userController.saveUserInfo(results.content!.userInfo);
    }

    // 注册成功，切换 WebSocket 连接（断开访客连接，用 token 重新连接）。
    await WebSocketAuth.onLoginSuccess();
    // 清空访客数据，获取已登录用户的未读消息。
    await MessageService.fetchUnreadAfterLogin();
    // 绑定 FCM Token 到用户。
    await FcmAuth.onLoginSuccess();

    showBottomTip(easy.tr('register.success_01'));
    return true;
  }
}
