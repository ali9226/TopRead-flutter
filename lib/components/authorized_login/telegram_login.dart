// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/constant.dart';
import 'package:app/fcm/fcm_auth.dart';
import 'package:app/models/login.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/pop_up_input.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:telegram_login_flutter/telegram_login_flutter.dart';

/*
  执行telegram登录逻辑。
 */
Future<void> telegram_login(BuildContext context) async {
  const String telegramUrl = "https://novel_telegram_login.kingbet.co.tz";
  const String botId = "8776242482";
  final Uri? telegram_auth_url = Uri.tryParse(telegramUrl);
  if (telegram_auth_url == null ||
      telegram_auth_url.scheme.isEmpty ||
      telegram_auth_url.host.isEmpty) {
    logUtil(msg: "Telegram 后端鉴权地址无效: $telegramUrl", type: 'e');
    showBottomTip(context.tr('AuthorizedLogin.telegram_auth_url_invalid'));
    return;
  }

  // 1. 弹出公共弹窗要求输入手机号
  String? phoneNumber;
  await popUpInput(
    context: context,
    message: context.tr('AuthorizedLogin.telegram_title'),
    hintText: context.tr('AuthorizedLogin.telegram_phone_hint'),
    leftButtonText: context.tr('constant.cancel'),
    rightButtonText: context.tr('AuthorizedLogin.authorize_login'),
    onRightPressed: (value) async {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        showBottomTip(context.tr('AuthorizedLogin.telegram_phone_required'));
        return false;
      }
      if (!trimmed.startsWith('+')) {
        showBottomTip(
          context.tr('AuthorizedLogin.telegram_phone_code_required'),
        );
        return false;
      }
      phoneNumber = trimmed;
      return true;
    },
  );

  // 如果用户取消了弹窗，phoneNumber 为空
  if (phoneNumber == null) {
    return;
  }

  try {
    logUtil(msg: "开始 Telegram 授权登录, 手机号: $phoneNumber");

    // 2. 使用 TelegramAuth 进行授权流程
    final TelegramAuth telegramAuth = TelegramAuth(
      phoneNumber: phoneNumber!,
      botId: botId,
      botDomain: telegramUrl,
    );

    // 打开 Telegram 应用
    await telegramAuth.launchTelegram();
    // 发起登录请求
    await telegramAuth.initiateLogin();

    // 轮询检查状态，直到成功或超时
    final startTime = DateTime.now();
    const timeout = Duration(seconds: 60);
    TelegramUser? telegram_user;

    while (DateTime.now().difference(startTime) < timeout) {
      if (await telegramAuth.checkLoginStatus()) {
        telegram_user = await telegramAuth.getUserData();
        break;
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!context.mounted) {
      return;
    }

    if (telegram_user == null) {
      logUtil(msg: "Telegram 授权超时或取消");
      showBottomTip(context.tr('AuthorizedLogin.telegram_auth_timeout'));
      return;
    }

    logUtil(msg: "Telegram 授权成功，开始请求后端鉴权");
    await _request_telegram_backend_auth(
      context: context,
      telegram_auth_url: telegram_auth_url,
      telegram_user: telegram_user,
    );
  } catch (error) {
    logUtil(msg: "Telegram 授权登录失败: $error", type: 'e');
    if (context.mounted) {
      showBottomTip(context.tr('AuthorizedLogin.telegram_auth_failed'));
    }
  }
}

Future<void> _request_telegram_backend_auth({
  required BuildContext context,
  required Uri telegram_auth_url,
  required TelegramUser telegram_user,
}) async {
  final ResultsType<Login> results = await postRequest<Login>(
    prefix: '',
    baseUrl: _resolve_telegram_auth_base_url(telegram_auth_url),
    path: _resolve_telegram_auth_path(telegram_auth_url),
    parameter: <String, dynamic>{
      ...telegram_user.toJson(),
      'telegram_user': telegram_user.toJson(),
    },
    fromJson: (Map<String, dynamic> json) => Login.fromJson(json),
  );

  if (!context.mounted) {
    return;
  }

  if (!results.status || results.content == null) {
    return;
  }

  final String token = results.content?.token.toString() ?? '';
  if (token.isEmpty) {
    showBottomTip(context.tr('AuthorizedLogin.telegram_auth_failed'));
    return;
  }

  await StorageUtil.saveData(Constant.tokenKey, token);

  final UserInformation user_controller = Get.put(UserInformation());
  user_controller.saveUserInfo(results.content!.userInfo);

  // 绑定 FCM Token 到用户。
  FcmAuth.onLoginSuccess();

  routerUtil(path: '/', type: 'replace');
}

String _resolve_telegram_auth_base_url(Uri telegram_auth_url) {
  return '${telegram_auth_url.scheme}://${telegram_auth_url.authority}';
}

String _resolve_telegram_auth_path(Uri telegram_auth_url) {
  final String path = telegram_auth_url.path.isEmpty
      ? '/'
      : telegram_auth_url.path;
  if (telegram_auth_url.query.isEmpty) {
    return path;
  }

  return '$path?${telegram_auth_url.query}';
}
