import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

import 'package:app/components/no_internet/style.dart';
import 'package:app/components/no_internet/cute_no_internet_cloud.dart';
import 'package:app/util/language_util/index.dart';

/// 无网络状态组件。
///
/// 当网络请求失败时展示的空状态占位组件，
/// 包含可爱断网云朵、标题和描述文案。
///
/// 交互规则：
/// - 点击图标或文字区域均触发 [on_reload] 回调，用于重新请求数据。
/// - 整体内容垂直水平居中。
///
/// 多语种适配：
/// - 标题和描述文案通过 [title] 和 [description] 传入，
///   调用方根据当前语种传入对应翻译文本。
/// - 字号自动适配 CJK / 非 CJK 语系。
///
/// 主题适配：
/// - 支持日间/夜间模式，通过 [is_dark] 控制。
class NoInternet extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 标题文案（由调用方传入已翻译的文本）。
  final String title;

  /// 描述文案（由调用方传入已翻译的文本）。
  final String description;

  /// 重新加载回调（点击图标或文字触发）。
  final VoidCallback on_reload;

  const NoInternet({
    super.key,
    required this.is_dark,
    required this.title,
    required this.description,
    required this.on_reload,
  });

  @override
  Widget build(BuildContext context) {
    /// 当前语种是否为 CJK。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );

    /// 标题文字颜色。
    final Color title_color = is_dark
        ? NoInternetStyle.title_dark_color
        : NoInternetStyle.title_light_color;

    /// 描述文字颜色。
    final Color desc_color = is_dark
        ? NoInternetStyle.desc_dark_color
        : NoInternetStyle.desc_light_color;

    /// 标题字号（CJK 语系字号稍大）。
    final double title_font_size = is_cjk
        ? NoInternetStyle.title_font_size_cjk
        : NoInternetStyle.title_font_size_alphabetic;

    /// 描述字号（CJK 语系字号稍大）。
    final double desc_font_size = is_cjk
        ? NoInternetStyle.desc_font_size_cjk
        : NoInternetStyle.desc_font_size_alphabetic;

    return Center(
      child: GestureDetector(
        onTap: on_reload,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            /// 可爱断网云朵图标。
            CuteNoInternetCloud(
              size: NoInternetStyle.icon_size,
              isDark: is_dark,
            ),
            const SizedBox(height: NoInternetStyle.icon_bottom_spacing),

            /// 标题文案。
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NoInternetStyle.desc_horizontal_padding,
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: title_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: title_color,
                ),
              ),
            ),
            const SizedBox(height: NoInternetStyle.title_bottom_spacing),

            /// 描述文案。
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NoInternetStyle.desc_horizontal_padding,
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: desc_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  color: desc_color,
                  height: NoInternetStyle.desc_height,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
