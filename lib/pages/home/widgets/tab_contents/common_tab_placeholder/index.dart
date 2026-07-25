import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/stores/device_info.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/pages/home/widgets/tab_contents/common_tab_placeholder/style.dart';
import 'package:app/config/font_config.dart';

/// Tab 通用占位块组件。
///
/// 临时替代各 Tab 的真实内容，用于测试 Tab 切换和滚动位置恢复。
/// 展示带序号的骨架条列表，点击可跳转到指定路由。
/// 包含足够的条目以确保可滚动。
class CommonTabPlaceholder extends StatelessWidget {
  /// 占位块条目数量，需要足够多以产生滚动条。
  final int item_count;

  /// 点击后跳转的路由路径。
  final String navigate_path;

  /// 用于保存滚动位置的唯一标识符。
  ///
  /// 每个 Tab 必须使用不同的标识符，以确保滚动位置独立保存。
  final String storage_key;

  const CommonTabPlaceholder({
    super.key,
    this.item_count = 30,
    this.navigate_path = '/ranking_full_list',
    this.storage_key = 'placeholder',
  });

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device_info = Get.find<DeviceInfo>();

    return Obx(() {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;

      return ListView.builder(
        key: PageStorageKey<String>(storage_key),
        padding: const EdgeInsets.only(
          left: TabPlaceholderStyle.list_horizontal_padding,
          right: TabPlaceholderStyle.list_horizontal_padding,
          top: TabPlaceholderStyle.list_top_padding,
          bottom: TabPlaceholderStyle.list_bottom_padding,
        ),
        itemCount: item_count,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < item_count - 1
                  ? TabPlaceholderStyle.card_spacing
                  : 0,
            ),
            child: _PlaceholderCard(
              index: index,
              is_dark: is_dark,
              navigate_path: navigate_path,
            ),
          );
        },
      );
    });
  }
}

/// 单个占位卡片组件。
///
/// 展示序号 + 标题骨架条 + 副标题骨架条，
/// 点击整行跳转到 [navigate_path]。
class _PlaceholderCard extends StatelessWidget {
  /// 当前卡片的序号索引（从 0 开始）。
  final int index;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击后跳转的路由路径。
  final String navigate_path;

  const _PlaceholderCard({
    required this.index,
    required this.is_dark,
    required this.navigate_path,
  });

  @override
  Widget build(BuildContext context) {
    /// 卡片背景色。
    final Color card_bg = is_dark
        ? TabPlaceholderStyle.card_bg_dark
        : TabPlaceholderStyle.card_bg_light;

    /// 骨架条颜色。
    final Color skeleton_color = is_dark
        ? TabPlaceholderStyle.skeleton_dark
        : TabPlaceholderStyle.skeleton_light;

    /// 序号文字颜色。
    final Color number_color = is_dark
        ? TabPlaceholderStyle.number_dark
        : TabPlaceholderStyle.number_light;

    /// 序号文本，从 1 开始。
    final String number_text = '${index + 1}';

    /// 标题骨架条宽度，交替变化模拟真实内容节奏。
    final double title_bar_width =
        TabPlaceholderStyle.title_bar_max_width -
            (index % 5) * 24.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => routerUtil(path: navigate_path, type: 'push'),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TabPlaceholderStyle.card_horizontal_padding,
          vertical: TabPlaceholderStyle.card_vertical_padding,
        ),
        decoration: BoxDecoration(
          color: card_bg,
          borderRadius: BorderRadius.circular(TabPlaceholderStyle.card_radius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // 序号
            SizedBox(
              width: TabPlaceholderStyle.number_width,
              child: Text(
                number_text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: TabPlaceholderStyle.number_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                  color: number_color,
                ),
              ),
            ),
            const SizedBox(width: TabPlaceholderStyle.number_content_gap),
            // 骨架条区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // 标题骨架条
                  Container(
                    width: title_bar_width.clamp(
                      TabPlaceholderStyle.title_bar_min_width,
                      TabPlaceholderStyle.title_bar_max_width,
                    ),
                    height: TabPlaceholderStyle.title_bar_height,
                    decoration: BoxDecoration(
                      color: skeleton_color,
                      borderRadius: BorderRadius.circular(
                        TabPlaceholderStyle.bar_radius,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: TabPlaceholderStyle.title_subtitle_gap,
                  ),
                  // 副标题骨架条
                  Container(
                    width: TabPlaceholderStyle.subtitle_bar_width,
                    height: TabPlaceholderStyle.subtitle_bar_height,
                    decoration: BoxDecoration(
                      color: skeleton_color,
                      borderRadius: BorderRadius.circular(
                        TabPlaceholderStyle.bar_radius,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
