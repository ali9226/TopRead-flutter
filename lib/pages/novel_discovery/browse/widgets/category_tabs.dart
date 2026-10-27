// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show lerpDouble;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/novel_discovery.dart';
import 'package:app/pages/novel_discovery/browse/style.dart';
import 'package:app/pages/novel_discovery/style.dart';
import 'package:app/pages/home/widgets/home_tab_bar/style.dart';
import 'package:flutter/material.dart';

/// 真实分类可横滑切换；TabBar 自动把初始分类和新选中的分类移入视口。
class NovelBrowseCategoryTabs extends StatelessWidget {
  const NovelBrowseCategoryTabs({
    super.key,
    required this.categories,
    required this.controller,
    required this.is_dark,
  });
  final List<Map<String, dynamic>> categories;
  final TabController controller;
  final bool is_dark;

  @override
  Widget build(BuildContext context) => WindowContentLayout(
    expand_height: false,
    max_width: NovelDiscoveryStyle.content_width,
    child: Padding(
      padding: const EdgeInsets.only(bottom: NovelBrowseStyle.tab_bottom_gap),
      child: SizedBox(
        height: NovelBrowseStyle.tab_height(context),
        child: TabBar(
          key: const ValueKey('novel_browse_category_tabs'),
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 0,
          padding: const EdgeInsets.only(
            right: NovelBrowseStyle.horizontal_padding,
          ),
          labelPadding: EdgeInsets.only(
            left: NovelBrowseStyle.is_cjk(context)
                ? HomeTabBarStyle.tab_label_padding_left_cjk
                : HomeTabBarStyle.tab_label_padding_left_alphabetic,
          ),
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: ColorConstants.themeColor,
              width: NovelBrowseStyle.indicator_width,
            ),
            insets: EdgeInsets.only(
              bottom: NovelBrowseStyle.tab_indicator_bottom_offset,
            ),
          ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(
            ColorConstants.transparent,
          ),
          tabs: [
            for (var index = 0; index < categories.length; index++)
              Tab(
                key: ValueKey(
                  'novel_browse_category_${novel_discovery_int(categories[index]['id'])}',
                ),
                child: AnimatedBuilder(
                  animation: controller.animation!,
                  builder: (context, child) {
                    final distance = (controller.animation!.value - index)
                        .abs()
                        .clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: lerpDouble(
                        NovelBrowseStyle.selected_scale(context),
                        1,
                        distance,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NovelBrowseStyle.tab_inner_padding,
                        ),
                        child: Text(
                          NovelDiscoveryStyle.category_name(
                            context,
                            categories[index],
                          ),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: NovelBrowseStyle.tab_font_size(context),
                            height: NovelBrowseStyle.tab_line_height,
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                            color: Color.lerp(
                              NovelBrowseStyle.foreground(is_dark),
                              NovelBrowseStyle.muted(is_dark),
                              distance,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
