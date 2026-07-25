import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/login_required_content/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/message/style.dart';
import 'package:app/config/font_config.dart';

/// 消息页未登录占位组件。
///
/// 作用：
/// 1. 在用户未登录时，替代消息列表内容。
/// 2. 展示未登录插图与提示文案。
/// 3. 提供按钮，点击后跳转到登录页。
class NoLoginEntry extends StatelessWidget {
  /// 是否为暗黑主题。
  final bool is_dark;

  /// 状态栏高度，用于顶部安全区留白。
  final double status_bar_height;

  /// 主文本颜色。
  final Color primary_text_color;

  /// 次文本颜色。
  final Color secondary_text_color;

  const NoLoginEntry({
    super.key,
    required this.is_dark,
    required this.status_bar_height,
    required this.primary_text_color,
    required this.secondary_text_color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ColorConstants.themeColor,
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 260));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: MessageStyle.page_padding.copyWith(
          top: status_bar_height + MessageStyle.page_top_padding,
        ),
        children: <Widget>[
          /// 页面标题。
          Text(
            easy.tr('message.title'),
            style: TextStyle(
              color: primary_text_color,
              fontSize: MessageStyle.title_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
          const SizedBox(height: MessageStyle.no_login_top_spacing),

          /// 公用未登录占位内容。
          LoginRequiredContent(
            title: easy.tr('message.no_login.title'),
            subtitle: easy.tr('message.no_login.desc'),
            primary_text_color: primary_text_color,
            secondary_text_color: secondary_text_color,
            action_key: 'message_no_login_entry_to_login',
          ),
        ],
      ),
    );
  }
}
