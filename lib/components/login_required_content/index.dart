import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/components/customer_service/index.dart';
import 'package:app/components/submit_button/index.dart';
import 'package:app/components/login_required_content/style.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/router/run_navigation_action_once.dart';

/// 公用未登录提示组件。
///
/// 作用：
/// 1. 在页面未登录时展示统一占位内容。
/// 2. 通过标题和副标题定制不同页面的提示文案。
/// 3. 保持跳转登录入口与客服模块的一致交互。
class LoginRequiredContent extends StatelessWidget {
  /// 主要提示标题。
  final String title;

  /// 次级提示文案。
  final String subtitle;

  /// 主文本颜色。
  final Color primary_text_color;

  /// 次文本颜色。
  final Color secondary_text_color;

  /// 跳转登录的行为标识。
  final String action_key;

  const LoginRequiredContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primary_text_color,
    required this.secondary_text_color,
    required this.action_key,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: LoginRequiredContentStyle.content_padding,
      child: is_landscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
    );
  }

  /// 竖屏布局：图标在上，文字和按钮在下。
  Widget _buildPortraitLayout() {
    return Column(
      children: <Widget>[
        /// 未登录插图。
        Center(
          child: SvgPicture.asset(
            'assets/svg/no_login.svg',
            width: LoginRequiredContentStyle.icon_size,
            height: LoginRequiredContentStyle.icon_size,
          ),
        ),
        const SizedBox(height: LoginRequiredContentStyle.icon_bottom_spacing),

        /// 未登录主标题。
        Center(
          child: Text(
            title,
            style: TextStyle(
              color: primary_text_color,
              fontSize: LoginRequiredContentStyle.title_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(
          height: LoginRequiredContentStyle.title_bottom_spacing,
        ),

        /// 未登录描述文案。
        Center(
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondary_text_color,
              fontSize: LoginRequiredContentStyle.desc_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ),
        const SizedBox(height: LoginRequiredContentStyle.desc_bottom_spacing),

        /// 登录按钮。
        SubmitButton(
          title: easy.tr('message.no_login.go_login'),
          margin: 20,
          onTap: () {
            run_navigation_action_once(
              actionKey: action_key,
              action: () async {
                routerUtil(path: '/login');
              },
            );
          },
        ),
        const SizedBox(
          height: LoginRequiredContentStyle.customer_service_top_spacing,
        ),

        /// 客服模块。
        const CustomerServiceView(),
      ],
    );
  }

  /// 横屏布局：图标在左，标题和副标题在图标下方，登录按钮和客服在右。
  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 左侧：图标、标题和副标题。
        Expanded(
          flex: 2,
          child: Column(
            children: <Widget>[
              /// 未登录插图。
              Center(
                child: SvgPicture.asset(
                  'assets/svg/no_login.svg',
                  width: LoginRequiredContentStyle.icon_size * 0.8,
                  height: LoginRequiredContentStyle.icon_size * 0.8,
                ),
              ),
              const SizedBox(
                height: LoginRequiredContentStyle.icon_bottom_spacing,
              ),

              /// 未登录主标题。
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primary_text_color,
                  fontSize: LoginRequiredContentStyle.title_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
              const SizedBox(
                height: LoginRequiredContentStyle.title_bottom_spacing,
              ),

              /// 未登录描述文案。
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondary_text_color,
                  fontSize: LoginRequiredContentStyle.desc_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                ),
              ),
            ],
          ),
        ),

        /// 右侧：登录按钮和客服模块。
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 登录按钮（与图标顶部对齐）。
              SubmitButton(
                title: easy.tr('message.no_login.go_login'),
                margin: 0,
                onTap: () {
                  run_navigation_action_once(
                    actionKey: action_key,
                    action: () async {
                      routerUtil(path: '/login');
                    },
                  );
                },
              ),
              const SizedBox(
                height: LoginRequiredContentStyle.customer_service_top_spacing,
              ),

              /// 客服模块。
              const CustomerServiceView(),
            ],
          ),
        ),
      ],
    );
  }
}
