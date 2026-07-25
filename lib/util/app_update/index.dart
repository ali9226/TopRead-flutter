// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/api/post_request.dart';
import 'package:app/models/app_config_inquire.dart';
import 'package:app/util/dialog/show_upgrade_dialog.dart';
import 'package:app/util/log_util.dart';

/* TODO
 * 检查 App 版本更新。
 *
 * 启动时调用，请求 app_config/inquire 接口获取最新版本配置，
 * 与本地当前版本号对比，决定是否弹出升级弹窗。
 *
 * 浏览器环境下跳过检查（不请求接口）。
 */
Future<void> checkAppUpdate() async {
  // TODO 浏览器环境跳过更新检查。
  if (kIsWeb) {
    logUtil(msg: 'app_update: 浏览器环境，跳过更新检查');
    return;
  }

  try {
    // TODO 请求 app_config/inquire 接口。
    final results = await postRequest<AppConfigInquire>(
      path: 'app_config/inquire',
      showTips: false,
      fromJson: (Map<String, dynamic> json) => AppConfigInquire.fromJson(json),
    );

    if (!results.status || results.content == null) {
      logUtil(msg: 'app_update: 接口请求失败或数据为空', type: 'w');
      return;
    }

    final AppConfigInquire config = results.content!;

    // TODO 获取本地 App 版本号。
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version;
    logUtil(msg: 'app_update: 当前版本=$currentVersion');

    // TODO 根据平台选择对应的版本号和升级地址。
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final String minVersion =
        isIOS ? config.min_ios_version : config.min_android_version;
    final String maxVersion =
        isIOS ? config.max_ios_version : config.max_android_version;
    final String upgradeUrl =
        isIOS ? config.ios_update_address : config.update_address;

    // TODO 版本号为空则跳过。
    if (minVersion.isEmpty || maxVersion.isEmpty) {
      logUtil(msg: 'app_update: 服务端版本号为空，跳过');
      return;
    }

    // TODO 对比版本号。
    final int compareMin = _compareVersion(currentVersion, minVersion);
    final int compareMax = _compareVersion(currentVersion, maxVersion);

    if (compareMin < 0) {
      // TODO 当前版本 < min_version，强制升级（不可取消）。
      logUtil(msg: 'app_update: 需要强制升级 $currentVersion -> $minVersion');
      _showForceUpdateDialog(
        updateContent: config.update_content,
        upgradeUrl: upgradeUrl,
        currentVersion: currentVersion,
        latestVersion: minVersion,
      );
    } else if (compareMax < 0) {
      // TODO min_version <= 当前版本 < max_version，可选升级（可取消）。
      logUtil(msg: 'app_update: 可选升级 $currentVersion -> $maxVersion');
      _showOptionalUpdateDialog(
        updateContent: config.update_content,
        upgradeUrl: upgradeUrl,
        currentVersion: currentVersion,
        latestVersion: maxVersion,
      );
    } else {
      logUtil(msg: 'app_update: 已是最新版本');
    }
  } catch (error) {
    logUtil(msg: 'app_update: 检查更新异常 $error', type: 'e');
  }
}

/* TODO
 * 比较两个版本号的大小。
 *
 * 返回值：
 * - 1：v1 > v2
 * - 0：v1 == v2
 * - -1：v1 < v2
 *
 * 参数 [v1]：第一个版本号（如 "2.0.4"）。
 * 参数 [v2]：第二个版本号（如 "2.0.5"）。
 */
int _compareVersion(String v1, String v2) {
  final List<int> parts1 = _parseVersionParts(v1);
  final List<int> parts2 = _parseVersionParts(v2);

  final int maxLen =
      parts1.length > parts2.length ? parts1.length : parts2.length;

  for (int i = 0; i < maxLen; i++) {
    final int p1 = i < parts1.length ? parts1[i] : 0;
    final int p2 = i < parts2.length ? parts2[i] : 0;
    if (p1 > p2) return 1;
    if (p1 < p2) return -1;
  }
  return 0;
}

/// 把版本号字符串拆成整数列表（如 "2.0.4" -> [2, 0, 4]）。
List<int> _parseVersionParts(String version) {
  return version
      .split('.')
      .map((String part) => int.tryParse(part) ?? 0)
      .toList();
}

/* TODO
 * 强制升级弹窗（不可取消、不可关闭）。
 *
 * 参数 [updateContent]：更新内容说明文案。
 * 参数 [upgradeUrl]：点击升级后跳转的地址。
 * 参数 [currentVersion]：当前安装的版本号。
 * 参数 [latestVersion]：服务端最新的版本号。
 */
void _showForceUpdateDialog({
  required String updateContent,
  required String upgradeUrl,
  required String currentVersion,
  required String latestVersion,
}) {
  final String message = updateContent.isNotEmpty
      ? updateContent
      : easy.tr('app_update.force_update_message');

  showUpgradeDialog(
    currentVersion: currentVersion,
    latestVersion: latestVersion,
    updateContent: message,
    rightButtonText: easy.tr('app_update.upgrade_now'),
    allowMaskDismiss: false,
    onRightPressed: () async {
      await _launchUpgradeUrl(upgradeUrl);
    },
  );
}

/* TODO
 * 可选升级弹窗（可以取消、可以关闭）。
 *
 * 参数 [updateContent]：更新内容说明文案。
 * 参数 [upgradeUrl]：点击升级后跳转的地址。
 * 参数 [currentVersion]：当前安装的版本号。
 * 参数 [latestVersion]：服务端最新的版本号。
 */
void _showOptionalUpdateDialog({
  required String updateContent,
  required String upgradeUrl,
  required String currentVersion,
  required String latestVersion,
}) {
  final String message = updateContent.isNotEmpty
      ? updateContent
      : easy.tr('app_update.optional_update_message');

  showUpgradeDialog(
    currentVersion: currentVersion,
    latestVersion: latestVersion,
    updateContent: message,
    leftButtonText: easy.tr('app_update.upgrade_later'),
    rightButtonText: easy.tr('app_update.upgrade_now'),
    allowMaskDismiss: true,
    onRightPressed: () async {
      await _launchUpgradeUrl(upgradeUrl);
    },
  );
}

/// 打开升级链接。
Future<void> _launchUpgradeUrl(String url) async {
  if (url.isEmpty) {
    logUtil(msg: 'app_update: 升级地址为空', type: 'w');
    return;
  }

  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    logUtil(msg: 'app_update: 无法打开升级链接 $url', type: 'e');
  }
}
