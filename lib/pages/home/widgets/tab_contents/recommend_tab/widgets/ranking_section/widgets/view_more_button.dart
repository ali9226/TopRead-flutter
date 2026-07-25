import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/config/font_config.dart';

/// "查看更多"按钮组件。
///
/// 展示带下划线的"查看更多"文字和右侧箭头图标，
/// 点击后跳转到完整榜单页面。
/// 支持日间/夜间主题和 CJK/非 CJK 语种适配。
class ViewMoreButton extends StatelessWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 当前语种代码，用于判断是否为 CJK 语系。
  final String language_code;

  /// 点击回调。
  final VoidCallback? on_tap;

  const ViewMoreButton({
    super.key,
    required this.is_dark,
    required this.language_code,
    this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 根据语种判断是否为 CJK，选择对应的字号。
    final bool is_cjk = LanguageUtil.is_cjk_language(language_code);
    final double font_size = is_cjk
        ? RankingSectionStyle.view_more_font_size_cjk
        : RankingSectionStyle.view_more_font_size_alphabetic;

    /// 文字和箭头颜色：统一使用浅灰色。
    final Color content_color = is_dark
        ? Colors.white.withValues(alpha: 0.54)
        : const Color(0xFF999999);

    /// 下划线颜色：与文字颜色保持一致。
    final Color underline_color = content_color;

    return Padding(
      padding: const EdgeInsets.only(
        top: RankingSectionStyle.view_more_top_spacing,
        bottom: RankingSectionStyle.view_more_bottom_spacing,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on_tap,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 文字 + 图标行
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // "查看更多"文字
                  Text(
                    easy.tr('home.view_more'),
                    style: TextStyle(
                      fontSize: font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: content_color,
                    ),
                  ),
                  // 文字与图标间距
                  const SizedBox(
                    width: RankingSectionStyle.view_more_icon_gap,
                  ),
                  // 右侧箭头图标
                  SvgIcon(
                    name: 'right',
                    width: RankingSectionStyle.view_more_icon_size,
                    height: RankingSectionStyle.view_more_icon_size,
                    color: content_color,
                  ),
                ],
              ),
              // 下划线与文字间距
              const SizedBox(
                height: RankingSectionStyle.view_more_underline_gap,
              ),
              // 下划线（宽度跟随文字+图标）
              Container(
                height: RankingSectionStyle.view_more_underline_height,
                color: underline_color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
