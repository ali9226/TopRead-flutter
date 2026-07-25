// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:get/get.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/rotation.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/stores/device_info.dart';
import 'logic.dart';
import 'style.dart';
import 'package:app/config/font_config.dart';

/// 授权登录列表公共组件。
class AuthorizedLoginView extends StatefulWidget {
  const AuthorizedLoginView({super.key});

  @override
  State<AuthorizedLoginView> createState() => _AuthorizedLoginViewState();
}

class _AuthorizedLoginViewState extends State<AuthorizedLoginView> {
  /// 主题信息
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 全局授权登录数据
  final AuthorizedLoginStore authorized_login_store =
      Get.find<AuthorizedLoginStore>();

  /// 交互逻辑
  late Logic logic;

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<Rotation> rotation_list = authorized_login_store.rotation_list
          .toList();

      if (rotation_list.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: AuthorizedLoginStyle.title_container_height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: AuthorizedLoginStyle.slogan_width,
                    height: AuthorizedLoginStyle.slogan_height,
                    decoration: AuthorizedLoginStyle.slogan_gradient_bar(
                      is_dark: device_info.dark.value,
                      side: AuthorizedLoginStyle.left_side,
                    ),
                  ),
                  const SizedBox(
                    width: AuthorizedLoginStyle.title_horizontal_spacing,
                  ),
                  Text(
                    easy.tr('AuthorizedLogin.title'),
                    style: TextStyle(
                      fontSize: AuthorizedLoginStyle.title_font_size,
                      color: device_info.dark.value
                          ? ColorConstants.nightTextColor
                          : ColorConstants.hintColor,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
                  const SizedBox(
                    width: AuthorizedLoginStyle.title_horizontal_spacing,
                  ),
                  Container(
                    width: AuthorizedLoginStyle.slogan_width,
                    height: AuthorizedLoginStyle.slogan_height,
                    decoration: AuthorizedLoginStyle.slogan_gradient_bar(
                      is_dark: device_info.dark.value,
                      side: AuthorizedLoginStyle.right_side,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuthorizedLoginStyle.list_top_spacing),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AuthorizedLoginStyle.item_horizontal_spacing,
                runSpacing: AuthorizedLoginStyle.item_vertical_spacing,
                children: rotation_list
                    .map((Rotation item) => _build_authorized_login_item(item))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建单个授权登录入口。
  Widget _build_authorized_login_item(Rotation item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => logic.handle_authorized_login_tap(item),
      child: SizedBox(
        width: AuthorizedLoginStyle.item_width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _build_authorized_login_icon(item),
            const SizedBox(height: AuthorizedLoginStyle.icon_bottom_spacing),
            Text(
              logic.get_authorized_login_title(item),
              style: TextStyle(
                color: device_info.dark.value
                    ? ColorConstants.nightTextColor
                    : ColorConstants.hintColor,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                fontSize: AuthorizedLoginStyle.item_title_font_size,
              ),
              textAlign: TextAlign.center,
              maxLines: AuthorizedLoginStyle.item_title_max_lines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 根据接口字段决定展示网络图还是本地 svg。
  Widget _build_authorized_login_icon(Rotation item) {
    final String item_title = item.title.trim().toLowerCase();
    final String loading_platform =
        authorized_login_store.loading_platform.value;
    final bool is_current_loading_item =
        authorized_login_store.loading.value &&
        (loading_platform.isEmpty
            ? item_title == 'google'
            : loading_platform == item_title);

    // 如果正在加载且是当前点击的项，展示转圈。
    if (is_current_loading_item) {
      return Container(
        width: AuthorizedLoginStyle.icon_size,
        height: AuthorizedLoginStyle.icon_size,
        decoration: BoxDecoration(
          color: device_info.dark.value
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(
            AuthorizedLoginStyle.icon_border_radius,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.themeColor,
              ),
            ),
          ),
        ),
      );
    }

    if (item.address.trim().isNotEmpty) {
      return NetworkCoverImage(
        image_url: item.address.trim(),
        width: AuthorizedLoginStyle.icon_size,
        height: AuthorizedLoginStyle.icon_size,
        border_radius: AuthorizedLoginStyle.icon_border_radius,
        fit: BoxFit.cover,
        is_dark: device_info.dark.value,
      );
    }

    return SvgIcon(
      name: logic.get_authorized_login_svg_name(item),
      width: AuthorizedLoginStyle.icon_size,
      height: AuthorizedLoginStyle.icon_size,
    );
  }
}
