// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/login.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/services/post_login_sync_service.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/auth/account_registration_verifier.dart';
import 'package:app/util/dialog/aes_encryption.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/string/to_string.dart';
import 'package:get/get.dart';

const String accountKey = 'account';
const String passwordKey = 'password';

/// 登录页逻辑控制器。
class Logic extends AccountRegistrationVerifier {
  final Future<ResultsType<Login>> Function({
    required String path,
    required Map<String, dynamic> parameter,
  })
  _authentication_request;

  Logic({
    super.verify_account_request,
    Future<ResultsType<Login>> Function({
      required String path,
      required Map<String, dynamic> parameter,
    })?
    authentication_request,
  }) : _authentication_request =
           authentication_request ?? _request_authentication;

  /// 生产环境仍走统一请求；测试可控制响应顺序和页面销毁时点。
  static Future<ResultsType<Login>> _request_authentication({
    required String path,
    required Map<String, dynamic> parameter,
  }) => postRequest<Login>(
    path: path,
    parameter: parameter,
    fromJson: (json) => Login.fromJson(json),
  );

  /// 用户输入的密码。
  String password = '';

  /// 用户输入的邀请码。
  String invitationCode = '';

  /// 是否记住密码。
  bool remember = true;

  /// 外部页面注入的账号输入框控制器。
  TextEditingController? accountController;

  /// 外部页面注入的密码输入框控制器。
  TextEditingController? passwordController;

  /// 初始化登录表单的缓存数据。
  Future<void> init() async {
    final int initial_revision = account_revision;
    final String? storageAccountEncryption = await StorageUtil.getData(
      accountKey,
    );

    // 缓存读取期间页面可能已关闭，或用户已经开始输入。
    if (!is_active || account_revision != initial_revision) return;

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

    final int restored_revision = account_revision;

    final String? storagePasswordEncryption = await StorageUtil.getData(
      passwordKey,
    );
    if (!is_active ||
        account_revision != restored_revision ||
        password.isNotEmpty) {
      return;
    }
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

  /// 执行登录请求。
  Future<bool> login() async {
    if (!is_active) return false;
    final userController = Get.find<UserInformation>();
    final int request_revision = userController.auth_revision;
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
    final String submitted_account = account;
    final String submitted_password = password;
    final bool should_remember = remember;

    final results = await _authentication_request(
      path: 'user/login',
      parameter: parameter,
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;

    final bool saved = await userController.save_auth_credentials_if_current(
      token: token,
      info: results.content!.userInfo,
      request_revision: request_revision,
      is_active: () => is_active,
    );
    if (!saved) return false;
    final int committed_revision = userController.auth_revision;
    // 只缓存本次成功登录的快照；两项写入同步启动，不能夹入别的登录缓存。
    final Future<bool> account_saved = StorageUtil.saveData(
      accountKey,
      aesEncryption(submitted_account),
    );
    final Future<void> password_saved = should_remember
        ? StorageUtil.saveData(passwordKey, aesEncryption(submitted_password))
        : StorageUtil.removeData(passwordKey);
    await Future.wait<void>([account_saved, password_saved]);
    if (!is_active ||
        !userController.is_auth_revision_current(committed_revision)) {
      return false;
    }

    // 登录后同步属于后台可恢复任务，不阻塞页面完成登录。
    PostLoginSyncService.start();

    // 用户主动登录成功后，才首次请求系统通知权限。
    unawaited(NotificationPermissionRequest.request_after_login());

    showBottomTip(easy.tr('login.success_01'));
    return true;
  }

  /// 执行注册请求（当账号未注册时使用）。
  Future<bool> register() async {
    if (!is_active) return false;
    final userController = Get.find<UserInformation>();
    final int request_revision = userController.auth_revision;
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

    final results = await _authentication_request(
      path: 'user/register',
      parameter: parameter,
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;

    final bool saved = await userController.save_auth_credentials_if_current(
      token: token,
      info: results.content!.userInfo,
      request_revision: request_revision,
      is_active: () => is_active,
    );
    if (!saved) return false;

    // 注册后同步属于后台可恢复任务，不阻塞页面完成注册。
    PostLoginSyncService.start();

    // 注册成功后用户已进入登录状态，按登录场景请求系统通知权限。
    unawaited(NotificationPermissionRequest.request_after_login());

    showBottomTip(easy.tr('register.success_01'));
    return true;
  }
}
