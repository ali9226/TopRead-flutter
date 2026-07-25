import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/config/font_config.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/pages/short_story_read/style.dart';

/// 目录弹窗头部组件。
///
/// 展示在目录弹窗顶部，包含：
/// - 左侧标题文字（"目录"，多语种）
/// - 右侧关闭按钮（X 图标）
/// - 底部分割线
class CatalogHeader extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 关闭按钮点击回调。
  final VoidCallback on_close;

  const CatalogHeader({
    super.key,
    required this.is_dark,
    required this.on_close,
  });

  @override
  Widget build(BuildContext context) {
    /// 标题文字颜色。
    final Color title_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    /// 关闭图标颜色。
    final Color icon_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 分割线颜色。
    final Color divider_color = is_dark
        ? ShortStoryReadStyle.bottom_bar_dark_divider
        : ShortStoryReadStyle.bottom_bar_light_divider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BottomSheetDragHandle(is_dark: is_dark),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: <Widget>[
              /// 标题文字。
              Text(
                tr('short_story_read.catalog'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: title_color,
                ),
              ),

              const Spacer(),

              /// 关闭按钮。
              GestureDetector(
                onTap: on_close,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/svg/close.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(icon_color, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 底部分割线。
        Divider(height: 0.5, color: divider_color),
      ],
    );
  }
}
