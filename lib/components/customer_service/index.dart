// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:get/get.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/rotation.dart';
import 'package:app/stores/customer_service_store.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/config/font_config.dart';

import 'logic.dart';
import 'style.dart';

/// 客服列表公共组件。
class CustomerServiceView extends StatefulWidget {
  const CustomerServiceView({super.key});

  @override
  State<CustomerServiceView> createState() => _CustomerServiceViewState();
}

class _CustomerServiceViewState extends State<CustomerServiceView> {
  /// 主题信息。
  final DeviceInfo device_info = Get.find<DeviceInfo>();

  /// 全局客服数据。
  final CustomerServiceStore customer_service_store =
      Get.find<CustomerServiceStore>();

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
      final List<Rotation> rotation_list = customer_service_store.rotation_list
          .toList();

      if (rotation_list.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: CustomerServiceStyle.title_container_height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: CustomerServiceStyle.slogan_width,
                    height: CustomerServiceStyle.slogan_height,
                    decoration: CustomerServiceStyle.slogan_gradient_bar(
                      is_dark: device_info.dark.value,
                      side: CustomerServiceStyle.left_side,
                    ),
                  ),
                  const SizedBox(
                    width: CustomerServiceStyle.title_horizontal_spacing,
                  ),
                  Text(
                    easy.tr('CustomerService.title'),
                    style: TextStyle(
                      fontSize: CustomerServiceStyle.title_font_size,
                      color: device_info.dark.value
                          ? ColorConstants.nightTextColor
                          : ColorConstants.hintColor,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
                  const SizedBox(
                    width: CustomerServiceStyle.title_horizontal_spacing,
                  ),
                  Container(
                    width: CustomerServiceStyle.slogan_width,
                    height: CustomerServiceStyle.slogan_height,
                    decoration: CustomerServiceStyle.slogan_gradient_bar(
                      is_dark: device_info.dark.value,
                      side: CustomerServiceStyle.right_side,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CustomerServiceStyle.list_top_spacing),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: CustomerServiceStyle.item_horizontal_spacing,
                runSpacing: CustomerServiceStyle.item_vertical_spacing,
                children: rotation_list
                    .map((Rotation item) => _build_customer_service_item(item))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建单个客服入口。
  Widget _build_customer_service_item(Rotation item) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => logic.handle_customer_service_tap(item),
      child: SizedBox(
        width: CustomerServiceStyle.item_width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _build_customer_service_icon(item),
            const SizedBox(height: CustomerServiceStyle.icon_bottom_spacing),
            Text(
              logic.get_customer_service_title(item),
              style: TextStyle(
                color: device_info.dark.value
                    ? ColorConstants.nightTextColor
                    : ColorConstants.hintColor,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                fontSize: CustomerServiceStyle.item_title_font_size,
              ),
              textAlign: TextAlign.center,
              maxLines: CustomerServiceStyle.item_title_max_lines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 根据接口字段决定展示网络图还是本地 svg。
  Widget _build_customer_service_icon(Rotation item) {
    if (item.address.trim().isNotEmpty) {
      return NetworkCoverImage(
        image_url: item.address.trim(),
        width: CustomerServiceStyle.icon_size,
        height: CustomerServiceStyle.icon_size,
        border_radius: CustomerServiceStyle.icon_border_radius,
        fit: BoxFit.cover,
        is_dark: device_info.dark.value,
      );
    }

    return SvgIcon(
      name: logic.get_customer_service_svg_name(item),
      width: CustomerServiceStyle.icon_size,
      height: CustomerServiceStyle.icon_size,
    );
  }
}
