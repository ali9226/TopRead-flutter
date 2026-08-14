// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:get/get.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/rotation.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/project_config_store.dart';
import '../logic.dart';
import '../style.dart';
import 'style.dart';

/// 苹果审核模式下的快捷登录组件。
///
/// 为了通过 Apple App Store 审核，此组件将每个快捷登录入口渲染为
/// 符合 Apple HIG 规范的独立按钮：
/// - 每行一个按钮，占据接近全宽
/// - 图标在左侧，文字居中
/// - 圆角矩形外观，最小高度 44pt
/// - 与常规模式（图标网格）完全独立，互不影响
class AppleReviewLoginView extends StatefulWidget {
  /// 登录前的拦截回调，返回 false 可阻止登录流程继续。
  final Future<bool> Function()? onBeforeLogin;

  const AppleReviewLoginView({super.key, this.onBeforeLogin});

  @override
  State<AppleReviewLoginView> createState() => _AppleReviewLoginViewState();
}

class _AppleReviewLoginViewState extends State<AppleReviewLoginView> {
  /// 主题信息。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 全局授权登录数据。
  final AuthorizedLoginStore authorized_login_store =
      Get.find<AuthorizedLoginStore>();

  /// 项目配置仓库。
  final ProjectConfigStore projectConfigStore = Get.find<ProjectConfigStore>();

  /// 交互逻辑。
  late Logic logic;

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!projectConfigStore.current.is_authorized_login_enabled) {
        return const SizedBox.shrink();
      }

      final List<Rotation> rotation_list =
          authorized_login_store.rotation_list.toList();

      if (rotation_list.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _build_title(),
          const SizedBox(height: AppleReviewStyle.list_top_spacing),
          ...rotation_list.map(
            (Rotation item) => Padding(
              padding: EdgeInsets.only(
                bottom: AppleReviewStyle.button_vertical_spacing,
              ),
              child: _build_login_button(item),
            ),
          ),
        ],
      );
    });
  }

  /// 构建"快捷登录"标题栏，与常规模式保持一致。
  Widget _build_title() {
    return SizedBox(
      height: AppleReviewStyle.title_container_height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: AppleReviewStyle.slogan_width,
            height: AppleReviewStyle.slogan_height,
            decoration: AuthorizedLoginStyle.slogan_gradient_bar(
              is_dark: device_info.dark.value,
              side: AppleReviewStyle.left_side,
            ),
          ),
          const SizedBox(width: AppleReviewStyle.title_horizontal_spacing),
          Text(
            easy.tr('AuthorizedLogin.title'),
            style: TextStyle(
              fontSize: AppleReviewStyle.title_font_size,
              color: device_info.dark.value
                  ? ColorConstants.nightTextColor
                  : ColorConstants.lightTextColor,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
          const SizedBox(width: AppleReviewStyle.title_horizontal_spacing),
          Container(
            width: AppleReviewStyle.slogan_width,
            height: AppleReviewStyle.slogan_height,
            decoration: AuthorizedLoginStyle.slogan_gradient_bar(
              is_dark: device_info.dark.value,
              side: AppleReviewStyle.right_side,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个符合 Apple HIG 规范的快捷登录按钮。
  Widget _build_login_button(Rotation item) {
    final String item_title = item.title.trim().toLowerCase();
    final bool is_authentication_loading = authorized_login_store.loading.value;
    final bool is_current_loading_item =
        is_authentication_loading &&
        authorized_login_store.loading_platform.value == item_title;

    return Semantics(
      button: true,
      enabled: !is_authentication_loading,
      child: AnimatedOpacity(
        duration: AppleReviewStyle.state_duration,
        opacity: is_authentication_loading && !is_current_loading_item
            ? AppleReviewStyle.disabled_opacity
            : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: is_authentication_loading
              ? null
              : () async {
                  if (widget.onBeforeLogin != null &&
                      !(await widget.onBeforeLogin!())) {
                    return;
                  }
                  await logic.handle_authorized_login_tap(item);
                },
          child: Container(
            height: AppleReviewStyle.button_height,
            margin: const EdgeInsets.symmetric(
              horizontal: AppleReviewStyle.button_horizontal_margin,
            ),
            decoration: BoxDecoration(
              color: device_info.dark.value
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(
                AppleReviewStyle.button_border_radius,
              ),
              border: Border.all(
                color: device_info.dark.value
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: AppleReviewStyle.button_padding_left),
                _build_button_icon(
                  item,
                  is_current_loading_item: is_current_loading_item,
                ),
                const SizedBox(width: AppleReviewStyle.icon_text_spacing),
                Expanded(
                  child: Text(
                    '${logic.get_authorized_login_title(item)} ${easy.tr('register.login_now')}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppleReviewStyle.button_font_size,
                      color: device_info.dark.value
                          ? ColorConstants.nightTextColor
                          : ColorConstants.lightTextColor,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: device_info.dark.value
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2),
                ),
                const SizedBox(width: AppleReviewStyle.button_padding_left),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建按钮左侧图标。
  Widget _build_button_icon(
    Rotation item, {
    required bool is_current_loading_item,
  }) {
    if (is_current_loading_item) {
      return SizedBox(
        width: AppleReviewStyle.icon_size,
        height: AppleReviewStyle.icon_size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            ColorConstants.themeColor,
          ),
        ),
      );
    }

    if (item.address.trim().isNotEmpty) {
      return NetworkCoverImage(
        image_url: item.address.trim(),
        width: AppleReviewStyle.icon_size,
        height: AppleReviewStyle.icon_size,
        border_radius: AppleReviewStyle.icon_border_radius,
        fit: BoxFit.cover,
        is_dark: device_info.dark.value,
      );
    }

    final String svgName = logic.get_authorized_login_svg_name(item);

    return SvgIcon(
      name: svgName,
      width: AppleReviewStyle.icon_size,
      height: AppleReviewStyle.icon_size,
      color: (device_info.dark.value && svgName == 'apple')
          ? Colors.white
          : null,
    );
  }
}
