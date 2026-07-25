import 'package:easy_localization/easy_localization.dart' as easy;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/models/app_config_inquire.dart';
import 'package:app/models/language_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/dialog/show_upgrade_dialog.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/websocket/websocket_auth.dart';
import 'package:app/message/message_service.dart';
import 'package:app/fcm/fcm_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'operation_li.dart';
import 'logic.dart';
import 'style.dart';

/// 用户中心操作列表区。
///
/// 根据当前登录状态，动态展示设置操作和账号安全操作。
class OperationList extends StatefulWidget {
  const OperationList({super.key});

  @override
  State<OperationList> createState() => _OperationListState();
}

class _OperationListState extends State<OperationList> {
  /// 用户信息仓库。
  final userInformation = Get.find<UserInformation>();

  /// 设备主题仓库。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 语种状态仓库。
  final languageStore = Get.find<LanguageStore>();

  /// 操作区逻辑层。
  late Logic logic;

  @override
  void initState() {
    super.initState();

    /// 初始化逻辑层。
    logic = Logic(context);
  }

  /// 构建圆形语种旗帜图片。
  Widget _buildLanguageFlag(String localeCode) {
    /// 获取当前语种信息。
    final LanguageInfo? currentLanguage = languageStore.find_supported_language_by_code(localeCode);

    /// 获取语种图标地址（优先使用后端返回的网络图标）。
    final String iconUrl = currentLanguage?.icon.trim() ?? '';

    /// 获取本地语种图标资源路径。
    final String localAsset = LanguageUtil.get_language_asset_image(localeCode);

    return ClipOval(
      child: iconUrl.isNotEmpty
          ? Image.network(
              iconUrl,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  localAsset,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                );
              },
            )
          : Image.asset(
              localAsset,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 读取当前语种，语种变化时触发组件重建，确保多语种文字即时刷新。
    final String localeCode = context.locale.languageCode;

    /// 构建未读消息数角标。
    Widget _buildUnreadBadge(int count) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: ColorConstants.dangerColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Obx(
      key: ValueKey(localeCode),
      () {
      /// 当前是否已登录。
      final isLoggedIn = userInformation.isLoggedIn.value;

      /// 构建各组的操作项列表。
      final List<Widget> group1Children = [];
      final List<Widget> group2Children = [];
      final List<Widget> group3Children = [];

      // 第一组：用户信息相关（按单个操作判断）。
      if (isLoggedIn) {
        group1Children.add(
          OperationLi(
            icon: "invitation_code",
            title:
                "${easy.tr('UserInfo.invitation_code')}:${userInformation.userInfo.value?.invitationCode}",
            type: 3,
            showDivider: true,
            onTap: () async {
              final code =
                  userInformation.userInfo.value?.invitationCode ?? '';
              final ok = await copyToClipboard(code);
              if (ok) {
                showBottomTip(easy.tr("UserInfo.copy_invitation_code"));
              } else {
                logUtil(msg: "复制邀请码失败");
                showBottomTip("复制失败");
              }
            },
          ),
        );
      }
      if (isLoggedIn) {
        group1Children.add(
          OperationLi(
            icon: "love_03",
            title: easy.tr('UserInfo.interest_preference'),
            type: 1,
            showDivider: false,
            onTap: () {
              routerUtil(path: '/interest_preference');
            },
          ),
        );
      }

      // 第二组：通用设置操作（按单个操作判断）。
      group2Children.add(
        OperationLi(
          icon: "night_mode",
          title: easy.tr('UserInfo.night_mode'),
          type: 2,
          showDivider: true,
        ),
      );
      group2Children.add(
        OperationLi(
          icon: "customer_service",
          title: easy.tr('UserInfo.online_customer_service'),
          type: 1,
          showDivider: true,
          trailing: Obx(() {
            final unread = Get.find<MessageStore>().chat_unread.value;
            if (unread > 0) {
              return _buildUnreadBadge(unread);
            }
            // 没有未读数时显示箭头。
            return SvgIcon(
              name: "right",
              width: 16,
              height: 16,
              color: deviceInfo.dark.value
                  ? Colors.white.withValues(alpha: 0.38)
                  : ColorConstants.lightTextColor.withValues(alpha: 0.22),
            );
          }),
          onTap: () {
            GoRouter.of(context).push('/customer_service_chat');
          },
        ),
      );
      group2Children.add(
        OperationLi(
          icon: "translate",
          title: easy.tr('UserInfo.language_selection'),
          type: 1,
          showDivider: false,
          trailing: _buildLanguageFlag(localeCode),
          onTap: () {
            routerUtil(path: '/selection_language');
          },
        ),
      );

      // 第三组：账号安全与退出操作（按单个操作判断）。
      if (isLoggedIn) {
        group3Children.add(
          OperationLi(
            icon: "password",
            title: easy.tr('UserInfo.change_password'),
            type: 1,
            onTap: () async {
              await logic.updatePassword();
            },
          ),
        );
      }
      if (isLoggedIn) {
        group3Children.add(
          OperationLi(
            icon: "quit",
            title: easy.tr('UserInfo.sign_out'),
            type: 1,
            onTap: () {
              showMessage(
                message: easy.tr('UserInfo.tips_01'),
                leftButtonText: easy.tr('UserInfo.no'),
                rightButtonText: easy.tr('UserInfo.yes'),
                rightButtonColor: ColorConstants.dangerColor,
                iconColor: ColorConstants.dangerColor,
                onRightPressed: () async {
                  userInformation.clearUserInfo();
                  Get.find<MessageStore>().clear();
                  await StorageUtil.removeData(Constant.tokenKey);
                  await WebSocketAuth.onLogout();
                  await MessageService.fetchVisitorUnread();
                  await FcmAuth.onLogout();
                  showBottomTip(easy.tr('UserInfo.success_02'));
                },
              );
            },
          ),
        );
      }
      // 关于 - 始终显示。
      group3Children.add(
        OperationLi(
          icon: "upgrade_02",
          title: easy.tr('UserInfo.about_top_read'),
          type: 1,
          showDivider: false,
          trailing: Text(
            'V${Constant.appVersion}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: deviceInfo.dark.value
                  ? Colors.white.withValues(alpha: 0.38)
                  : ColorConstants.lightTextColor.withValues(alpha: 0.45),
            ),
          ),
          onTap: () => _checkUpdate(),
        ),
      );

      return Column(
        children: [
          if (group1Children.isNotEmpty)
            _OperationGroup(
              accentColor: const Color(0xFFFFD45A),
              glowColor: const Color(0x22FFD45A),
              children: group1Children,
            ),
          if (group2Children.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isLoggedIn ? 0 : 20),
              child: _OperationGroup(
                accentColor: const Color(0xFF8DB7FF),
                glowColor: const Color(0x1A8DB7FF),
                children: group2Children,
              ),
            ),
          if (group3Children.isNotEmpty)
            _OperationGroup(
              accentColor: const Color(0xFFFF9E80),
              glowColor: const Color(0x1AFF9E80),
              children: group3Children,
            ),
        ],
      );
    });
  }

  /// 检查应用更新。
  ///
  /// 请求 app_config/inquire 接口对比版本号：
  /// - 已是最新版：吐司提示
  /// - 有可升级版本：弹出升级弹窗
  Future<void> _checkUpdate() async {
    // 浏览器环境跳过。
    if (kIsWeb) return;

    try {
      final results = await postRequest<AppConfigInquire>(
        path: 'app_config/inquire',
        showTips: false,
        fromJson: (Map<String, dynamic> json) => AppConfigInquire.fromJson(json),
      );

      if (!mounted) return;

      if (!results.status || results.content == null) {
        showBottomTip(easy.tr('app_update.already_latest'));
        return;
      }

      final AppConfigInquire config = results.content!;

      // 根据平台选择对应的版本号和升级地址。
      final bool is_ios = defaultTargetPlatform == TargetPlatform.iOS;
      final String max_version =
          is_ios ? config.max_ios_version : config.max_android_version;
      final String upgrade_url =
          is_ios ? config.ios_update_address : config.update_address;

      // 版本号为空则提示已是最新。
      if (max_version.isEmpty) {
        showBottomTip(easy.tr('app_update.already_latest'));
        return;
      }

      // 对比版本号。
      final int compare = _compare_version(Constant.appVersion, max_version);

      if (compare < 0) {
        // 当前版本 < 最新版本，弹出升级弹窗。
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
        // 已是最新版本。
        showBottomTip(easy.tr('app_update.already_latest'));
      }
    } catch (error) {
      logUtil(msg: 'app_version: 检查更新异常 $error', type: 'e');
      if (mounted) {
        showBottomTip(easy.tr('app_update.already_latest'));
      }
    }
  }

  /// 比较两个版本号的大小。
  static int _compare_version(String v1, String v2) {
    final List<int> parts1 = _parse_version_parts(v1);
    final List<int> parts2 = _parse_version_parts(v2);

    final int max_len =
        parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < max_len; i++) {
      final int p1 = i < parts1.length ? parts1[i] : 0;
      final int p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// 把版本号字符串拆成整数列表。
  /// 支持格式：1.0.0 或 1.0.0+2（忽略 + 后面的 build number）。
  static List<int> _parse_version_parts(String version) {
    // 移除 + 及后面的 build number，只保留版本名部分
    final String versionName = version.split('+').first;
    return versionName
        .split('.')
        .map((String part) => int.tryParse(part) ?? 0)
        .toList();
  }
}

/// 操作列表分组容器。
class _OperationGroup extends StatelessWidget {
  final Color accentColor;
  final Color glowColor;
  final List<Widget> children;

  const _OperationGroup({
    required this.accentColor,
    required this.glowColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<DeviceInfo>().dark.value;
    final horizontalInset = isDark
        ? Style.darkHorizontalInset
        : Style.lightHorizontalInset;
    final outerRadius = isDark ? Style.groupRadius : 0.0;
    final innerRadius = isDark ? Style.innerRadius : 0.0;
    final outerBorder = isDark
        ? Border.all(color: accentColor.withValues(alpha: 0.18))
        : Border(
            top: BorderSide(color: accentColor.withValues(alpha: 0.10)),
            bottom: BorderSide(color: accentColor.withValues(alpha: 0.10)),
          );
    final innerBorder = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.04))
        : null;

    /// 夜间模式保留底部内边距，日间模式取消。
    final double bottomPadding = isDark ? 16 : 0;

    return AnimatedPadding(
      duration: Duration(milliseconds: ThemeConstants.animationTime),
      curve: Curves.easeInOut,
      padding: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? ColorConstants.nightHighlightColor
              : ColorConstants.whiteColor,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [ColorConstants.nightHighlightColor, const Color(0xFF1C2230)]
                : [const Color(0xFFFFFAF2), const Color(0xFFF5F8FF)],
          ),
          borderRadius: BorderRadius.circular(outerRadius),
          border: outerBorder,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.16)
                  : const Color(0xFFD8E0EC).withValues(alpha: 0.18),
              blurRadius: isDark ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isDark)
              Positioned(
                top: -18,
                right: -12,
                child: IgnorePointer(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          glowColor.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: -32,
              left: -24,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: isDark ? 0.06 : 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                width: 22,
                height: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            AnimatedPadding(
              duration: Duration(milliseconds: ThemeConstants.animationTime),
              curve: Curves.easeInOut,
              padding: EdgeInsets.fromLTRB(0, 18, 0, isDark ? 10 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white.withValues(alpha: 0.90),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.04),
                              Colors.white.withValues(alpha: 0.015),
                            ]
                          : [const Color(0xFFFFFCF7), const Color(0xFFF8FBFF)],
                    ),
                    borderRadius: BorderRadius.circular(innerRadius),
                    border: innerBorder,
                  ),
                  child: Stack(
                    children: [
                      if (isDark)
                        Positioned(
                          top: -22,
                          right: -14,
                          child: IgnorePointer(
                            child: Container(
                              width: Style.innerDecorSize,
                              height: Style.innerDecorSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    glowColor.withValues(alpha: 0.16),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!isDark)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 96,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    accentColor.withValues(alpha: 0.12),
                                    accentColor.withValues(alpha: 0.05),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: -28,
                        left: -10,
                        child: IgnorePointer(
                          child: Container(
                            width: Style.innerDecorSize,
                            height: Style.innerDecorSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accentColor.withValues(
                                    alpha: isDark ? 0.08 : 0.06,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 14,
                        right: 14,
                        child: IgnorePointer(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  accentColor.withValues(
                                    alpha: isDark ? 0.08 : 0.12,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(children: children),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
