import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/app_config_inquire.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/bookshelf_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_upgrade_dialog.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:app/fcm/fcm_auth.dart';
import 'package:app/message/message_service.dart';
import 'package:app/websocket/websocket_auth.dart';

/// 关于TopRead页面逻辑层。
class Logic {
  final BuildContext context;

  Logic(this.context);

  /// 检查应用更新。
  ///
  /// 请求 app_config/inquire 接口对比版本号：
  /// - 已是最新版：吐司提示
  /// - 有可升级版本：弹出升级弹窗
  Future<void> checkUpdate() async {
    if (kIsWeb) return;

    try {
      final results = await postRequest<AppConfigInquire>(
        path: 'app_config/inquire',
        showTips: false,
        fromJson: (Map<String, dynamic> json) =>
            AppConfigInquire.fromJson(json),
      );

      if (!context.mounted) return;

      if (!results.status || results.content == null) {
        showBottomTip(easy.tr('app_update.already_latest'));
        return;
      }

      final AppConfigInquire config = results.content!;

      final bool is_ios = defaultTargetPlatform == TargetPlatform.iOS;
      final String max_version = is_ios
          ? config.max_ios_version
          : config.max_android_version;
      final String upgrade_url = is_ios
          ? config.ios_update_address
          : config.update_address;

      if (max_version.isEmpty) {
        showBottomTip(easy.tr('app_update.already_latest'));
        return;
      }

      final int compare = _compareVersion(Constant.appVersion, max_version);

      if (compare < 0) {
        final String message = config.update_content.isNotEmpty
            ? config.update_content
            : easy.tr('app_update.optional_update_message');

        showUpgradeDialog(
          currentVersion: Constant.appVersion,
          latestVersion: max_version,
          updateContent: message,
          leftButtonText: easy.tr('app_update.upgrade_later'),
          rightButtonText: easy.tr('app_update.upgrade_now'),
          allowMaskDismiss: true,
          onRightPressed: () async {
            if (upgrade_url.isNotEmpty) {
              final Uri uri = Uri.parse(upgrade_url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
        );
      } else {
        showBottomTip(easy.tr('app_update.already_latest'));
      }
    } catch (error) {
      logUtil(msg: 'app_version: 检查更新异常 $error', type: 'e');
      if (context.mounted) {
        showBottomTip(easy.tr('app_update.already_latest'));
      }
    }
  }

  /// 删除当前账户。
  ///
  /// 调用 user/delete 接口，成功后清除本地登录状态并切换为访客模式。
  Future<bool> deleteAccount() async {
    final results = await postRequest<dynamic>(
      path: 'user/delete',
      showTips: false,
    );
    if (!results.status) return false;

    final UserInformation user_information = Get.find<UserInformation>();
    final MessageStore message_store = Get.find<MessageStore>();
    final BookshelfStore bookshelf_store = Get.find<BookshelfStore>();

    final int logout_revision = user_information.begin_logout();
    message_store.clear();
    bookshelf_store.clear();

    await StorageUtil.removeData(Constant.tokenKey);

    unawaited(_complete_logout_cleanup(logout_revision));

    return true;
  }

  /// 完成退出后的后台服务切换。
  Future<void> _complete_logout_cleanup(int logout_revision) async {
    try {
      await Future.wait<void>(<Future<void>>[
        _switch_to_visitor_session(logout_revision),
        FcmAuth.onLogout(),
      ]);
    } catch (error) {
      logUtil(msg: '退出后台清理失败: $error', type: 'e');
    }
  }

  /// 切换为访客 WebSocket，并在会话仍为访客态时刷新访客未读数。
  Future<void> _switch_to_visitor_session(int logout_revision) async {
    final UserInformation user_information = Get.find<UserInformation>();
    if (!user_information.can_apply_visitor_response(logout_revision)) {
      return;
    }

    await WebSocketAuth.onLogout();
    if (!user_information.can_apply_visitor_response(logout_revision)) {
      return;
    }

    await MessageService.fetchVisitorUnread();
  }

  /// 比较两个版本号的大小。
  static int _compareVersion(String v1, String v2) {
    final List<int> parts1 = _parseVersionParts(v1);
    final List<int> parts2 = _parseVersionParts(v2);

    final int max_len = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;

    for (int i = 0; i < max_len; i++) {
      final int p1 = i < parts1.length ? parts1[i] : 0;
      final int p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// 把版本号字符串拆成整数列表。
  static List<int> _parseVersionParts(String version) {
    final String versionName = version.split('+').first;
    return versionName
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
