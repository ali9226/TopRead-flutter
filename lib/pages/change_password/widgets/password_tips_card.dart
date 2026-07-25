import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/pages/change_password/style.dart';

/// 密码小贴士卡片组件。
///
/// 展示密码设置建议，包含标题和三条提示内容。
/// 卡片背景带有书本羽毛装饰，呼应设计图风格。
///
/// 参数说明：
/// [isDark] - 当前是否为夜间模式。
class PasswordTipsCard extends StatelessWidget {
  /// 当前是否为夜间模式。
  final bool isDark;

  const PasswordTipsCard({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: Style.tipsCardPadding,
      decoration: BoxDecoration(
        color: Style.tipsCardBackground(isDark: isDark),
        borderRadius: BorderRadius.circular(Style.tipsCardRadius),
        border: Border.all(
          color: Style.tipsCardBorder(isDark: isDark),
        ),
      ),
      child: Stack(
        children: <Widget>[
          /// 右侧书本羽毛装饰。
          Positioned(
            right: -8,
            bottom: -8,
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.15 : 0.25,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: Style.tipsDecorationWidth,
                  color: Style.tipsTitleColor(isDark: isDark),
                ),
              ),
            ),
          ),

          /// 内容区域。
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// 标题行（灯泡图标 + 标题文字）。
              Row(
                children: <Widget>[
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: Style.tipsTitleColor(isDark: isDark),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    easy.tr('UserInfo.password_tips_title'),
                    style: TextStyle(
                      fontSize: Style.tipsTitleSize,
                      fontWeight: Style.tipsTitleWeight,
                      color: Style.tipsTitleColor(isDark: isDark),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Style.tipsTitleBottomSpacing),

              /// 提示内容列表。
              _buildTipItem(
                easy.tr('UserInfo.password_tip_1'),
                isDark,
              ),
              SizedBox(height: Style.tipsItemSpacing),
              _buildTipItem(
                easy.tr('UserInfo.password_tip_2'),
                isDark,
              ),
              SizedBox(height: Style.tipsItemSpacing),
              _buildTipItem(
                easy.tr('UserInfo.password_tip_3'),
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单条提示内容（勾选图标 + 文字）。
  Widget _buildTipItem(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 勾选图标。
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_rounded,
            size: 14,
            color: Style.tipsCheckColor(isDark: isDark),
          ),
        ),
        const SizedBox(width: 6),

        /// 提示文字。
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: Style.tipsItemSize,
              height: Style.tipsItemHeight,
              color: Style.tipsItemColor(isDark: isDark),
            ),
          ),
        ),
      ],
    );
  }
}
