import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/share_sheet/style.dart';

/// 分享图标按钮组件。
///
/// 展示单个分享渠道的纯图标 + 底部文字标签，
/// 用于分享弹窗底部的图标行。
/// 宽度由内容自动撑开，文字不做省略截断。
///
/// 参数：
/// - [icon] 图标数据（支持 IconData 或自定义 Widget）。
/// - [label] 图标下方的文字标签。
/// - [icon_color] 图标的主题色，用于给图标着色。
/// - [is_dark] 当前是否为夜间模式。
/// - [on_tap] 点击回调。
/// - [icon_widget] 自定义图标 Widget，优先级高于 [icon]。
class ShareIconItem extends StatelessWidget {
  /// 图标数据。
  final IconData? icon;

  /// 图标下方的文字标签。
  final String label;

  /// 图标的主题色。
  final Color icon_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback on_tap;

  /// 自定义图标 Widget，优先级高于 [icon]。
  final Widget? icon_widget;

  const ShareIconItem({
    super.key,
    this.icon,
    required this.label,
    required this.icon_color,
    required this.is_dark,
    required this.on_tap,
    this.icon_widget,
  });

  @override
  Widget build(BuildContext context) {
    /// 文字标签的颜色。
    final Color label_color = is_dark
        ? ShareSheetStyle.icon_label_color_dark
        : ShareSheetStyle.icon_label_color_light;

    return GestureDetector(
      onTap: on_tap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// 纯图标（无圆形背景）。
          SizedBox(
            width: ShareSheetStyle.icon_size,
            child: icon_widget ??
                Icon(
                  icon,
                  size: ShareSheetStyle.icon_inner_size,
                  color: icon_color,
                ),
          ),

          /// 图标与文字之间的间距。
          const SizedBox(height: 2),

          /// 文字标签（不截断，自动撑开宽度）。
          Text(
            label,
            style: TextStyle(
              fontSize: ShareSheetStyle.icon_label_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: label_color,
            ),
          ),
        ],
      ),
    );
  }
}
