import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/auth_page/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/constant.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/router/router_util.dart';
import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';
import 'style.dart';

/// 路由：`/about_topread`
///
/// 关于TopRead页面，展示品牌信息、版本号和操作入口。
class AboutTopRead extends StatefulWidget {
  const AboutTopRead({super.key});

  @override
  State<AboutTopRead> createState() => _AboutTopReadState();
}

class _AboutTopReadState extends State<AboutTopRead> {
  /// 设备信息仓库。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 用户信息仓库。
  final userInformation = Get.find<UserInformation>();

  /// 项目配置仓库。
  final projectConfigStore = Get.find<ProjectConfigStore>();

  /// 页面逻辑层。
  late Logic logic;

  /// 当前地区法规是否要求展示可随时访问的广告隐私选项入口。
  bool _show_ad_privacy_options = false;

  /// 是否正在展示 UMP 隐私选项表单，防止用户重复点击。
  bool _is_opening_ad_privacy_options = false;

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
    unawaited(_refresh_ad_privacy_options_requirement());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isDark = deviceInfo.dark.value;
      final bool isLoggedIn = userInformation.isLoggedIn.value;
      final bool showDebug =
          isLoggedIn && userInformation.userInfo.value?.debug == 2;

      /// 背景色：与 user_info 页面保持一致。
      final Color bgColor = isDark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.whiteColor;

      /// 标题色：日间与背景同色系（深色文字），夜间与背景区分（白色文字）。
      final Color titleColor = isDark
          ? Colors.white
          : ColorConstants.lightTextColor;

      /// 次要文字色。
      final Color subColor = isDark
          ? Colors.white.withValues(alpha: 0.38)
          : ColorConstants.lightTextColor.withValues(alpha: 0.45);

      /// 分割线色。
      final Color dividerColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06);

      /// AppBar背景色：日间固定白色，夜间与页面背景区分。
      final Color appBarBgColor = isDark
          ? ColorConstants.nightHighlightColor
          : ColorConstants.whiteColor;

      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            easy.tr('UserInfo.about_top_read'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: titleColor,
            ),
          ),
          centerTitle: true,
          backgroundColor: appBarBgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: titleColor,
              size: 20,
            ),
            onPressed: () => AppRouter.pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              /// Logo区域。
              const SizedBox(height: Style.logo_top_spacing),
              Center(
                child: SvgIcon(
                  name: 'logo',
                  color: titleColor,
                  width: Style.logo_size,
                  height: Style.logo_size,
                ),
              ),

              /// 口号区域（自定义，无固定高度）。
              const SizedBox(height: Style.logo_to_slogan_spacing),
              _buildSlogan(isDark, titleColor),

              /// 版本号。
              const SizedBox(height: Style.slogan_to_version_spacing),
              Text(
                'V${Constant.appVersion}',
                style: TextStyle(
                  fontSize: Style.version_font_size,
                  fontWeight: Style.version_weight,
                  color: titleColor,
                ),
              ),

              /// 间距。
              const SizedBox(height: Style.version_to_list_spacing),

              /// 操作列表（无外框）。
              Column(
                children: [
                  if (projectConfigStore.current.is_rating_enabled)
                    _buildListItem(
                      title: easy.tr('AboutTopRead.rate_us'),
                      textColor: titleColor,
                      subColor: subColor,
                      dividerColor: dividerColor,
                      showDivider: false,
                      onTap: () => _openRateUs(),
                    ),
                  _buildListItem(
                    title: easy.tr('AboutTopRead.user_agreement'),
                    textColor: titleColor,
                    subColor: subColor,
                    dividerColor: dividerColor,
                    showDivider: false,
                    onTap: () {
                      routerUtil(path: '/image_text?type=60');
                    },
                  ),
                  _buildListItem(
                    title: easy.tr('AboutTopRead.privacy_policy'),
                    textColor: titleColor,
                    subColor: subColor,
                    dividerColor: dividerColor,
                    showDivider: true,
                    onTap: () {
                      routerUtil(path: '/image_text?type=61');
                    },
                  ),
                  if (_show_ad_privacy_options)
                    _buildListItem(
                      title: easy.tr('AboutTopRead.ad_privacy_options'),
                      textColor: titleColor,
                      subColor: subColor,
                      dividerColor: dividerColor,
                      showDivider: false,
                      onTap: () {
                        unawaited(_open_ad_privacy_options());
                      },
                    ),
                  _buildListItem(
                    title: easy.tr('AboutTopRead.version_update'),
                    textColor: titleColor,
                    subColor: subColor,
                    dividerColor: dividerColor,
                    showDivider: false,
                    trailing: Text(
                      'V${Constant.appVersion}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: titleColor,
                      ),
                    ),
                    onTap: () => logic.checkUpdate(),
                  ),
                  if (showDebug)
                    _buildListItem(
                      title: easy.tr('debug.title'),
                      textColor: titleColor,
                      subColor: subColor,
                      dividerColor: dividerColor,
                      showDivider: false,
                      onTap: () => routerUtil(path: '/debug'),
                    ),
                  if (isLoggedIn)
                    _buildListItem(
                      title: easy.tr('UserInfo.delete_account'),
                      textColor: ColorConstants.dangerColor,
                      subColor: ColorConstants.dangerColor,
                      dividerColor: dividerColor,
                      showDivider: false,
                      onTap: () => _handleDeleteAccount(),
                    ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }

  /// 打开应用商店评分页面。
  Future<void> _openRateUs() async {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final Uri uri = Uri.parse(
      isIOS
          ? 'https://apps.apple.com/us/app/topread/id6787079131'
          : 'https://play.google.com/store/apps/details?id=com.topread.novel',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 刷新 UMP 对“隐私选项”入口的法规要求，并仅在需要时展示列表项。
  Future<void> _refresh_ad_privacy_options_requirement() async {
    // 广告开关关闭时不显示广告隐私选项。
    if (!projectConfigStore.current.is_ads_enabled) {
      if (mounted && _show_ad_privacy_options) {
        setState(() => _show_ad_privacy_options = false);
      }
      return;
    }

    final bool is_required =
        await AdMobConsentPermissionRequest.is_privacy_options_required();
    if (!mounted || _show_ad_privacy_options == is_required) return;

    setState(() => _show_ad_privacy_options = is_required);
  }

  /// 展示 UMP 隐私选项表单，让用户修改或撤回广告隐私选择。
  Future<void> _open_ad_privacy_options() async {
    if (_is_opening_ad_privacy_options) return;

    setState(() => _is_opening_ad_privacy_options = true);
    try {
      final bool success =
          await AdMobConsentPermissionRequest.show_privacy_options_form();
      if (!success && mounted) {
        showBottomTip(easy.tr('AboutTopRead.ad_privacy_options_unavailable'));
      }
    } finally {
      if (mounted) {
        setState(() => _is_opening_ad_privacy_options = false);
      }
      unawaited(_refresh_ad_privacy_options_requirement());
    }
  }

  /// 处理删除账户操作。
  void _handleDeleteAccount() {
    showMessage(
      message:
          '${easy.tr('UserInfo.delete_account_confirm_title')}\n\n${easy.tr('UserInfo.delete_account_confirm_message')}',
      leftButtonText: easy.tr('UserInfo.delete_account_cancel_button'),
      rightButtonText: easy.tr('UserInfo.delete_account_confirm_button'),
      rightButtonColor: ColorConstants.dangerColor,
      iconColor: ColorConstants.dangerColor,
      onRightPressed: () async {
        final bool success = await logic.deleteAccount();
        if (!success) return;

        if (!mounted) return;
        showMessage(
          message: easy.tr('UserInfo.delete_account_success_message'),
          rightButtonText: easy.tr('UserInfo.yes'),
          allowMaskDismiss: false,
          onRightPressed: () async {
            routerUtil(path: '/', type: 'replace');
          },
        );
      },
    );
  }

  /// 构建单个列表项（纯文字+右侧元素）。
  Widget _buildListItem({
    required String title,
    required Color textColor,
    required Color subColor,
    required Color dividerColor,
    required bool showDivider,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: ColorConstants.themeColor.withValues(alpha: 0.12),
            highlightColor: ColorConstants.themeColor.withValues(alpha: 0.05),
            child: Container(
              height: Style.list_item_height,
              padding: const EdgeInsets.symmetric(
                horizontal: Style.list_horizontal_padding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: Style.list_title_font_size,
                        fontWeight: Style.list_title_weight,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  trailing ??
                      SvgIcon(
                        name: 'right',
                        width: 16,
                        height: 16,
                        color: subColor,
                      ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 0.5, thickness: 0.5, color: dividerColor),
      ],
    );
  }

  /// 构建口号组件（无固定高度限制）。
  Widget _buildSlogan(bool isDark, Color textColor) {
    final LanguageStore languageStore = Get.find<LanguageStore>();
    final String localeCode =
        easy.EasyLocalization.of(context)?.locale.languageCode ?? 'zh';
    final LanguageInfo? currentLanguageInfo = languageStore
        .find_supported_language_by_code(localeCode);
    final String sloganText =
        (currentLanguageInfo != null && currentLanguageInfo.remark.isNotEmpty)
        ? currentLanguageInfo.remark
        : easy.tr('login.slogan');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: AuthPageStyle.sloganWidth,
          height: AuthPageStyle.sloganHeight,
          decoration: AuthPageStyle.sloganGradientBar(
            isDark: isDark,
            reverse: false,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            sloganText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: AuthPageStyle.sloganWidth,
          height: AuthPageStyle.sloganHeight,
          decoration: AuthPageStyle.sloganGradientBar(
            isDark: isDark,
            reverse: true,
          ),
        ),
      ],
    );
  }
}
