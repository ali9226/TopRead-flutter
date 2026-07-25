// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config/font_config.dart';

import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/components/home_top_search_entry/index.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/language_util/index.dart';

/// 首页头部栏。
class HomeHeaderBar extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 搜索点击回调。
  final VoidCallback on_search_tap;

  /// 语种切换点击回调。
  final VoidCallback on_language_tap;

  const HomeHeaderBar({
    super.key,
    required this.is_dark,
    required this.on_search_tap,
    required this.on_language_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 读取全局语种状态。
    final LanguageStore languageStore = Get.find<LanguageStore>();

    /// 当前语种信息。
    final LanguageInfo? currentLanguageInfo = languageStore
        .find_supported_language_by_code(context.locale.languageCode);

    /// 当前语种图标地址。
    final String languageIconUrl = currentLanguageInfo?.icon ?? '';

    /// 当前语种代码。
    final String languageCode =
        currentLanguageInfo?.code.trim().toLowerCase() ??
        context.locale.languageCode.trim().toLowerCase();

    /// 当前语种名称。
    final String languageName = currentLanguageInfo?.title.isNotEmpty == true
        ? currentLanguageInfo!.title
        : LanguageUtil.get_language_name(languageCode);

    /// 语种文字颜色。
    final Color languageTextColor = is_dark
        ? Colors.white
        : ColorConstants.lightTextColor;

    return SizedBox(
      height: 58,
      child: Row(
        children: <Widget>[
          Expanded(
            /// 左侧放置搜索入口，点击后跳转搜索页。
            child: HomeTopSearchEntry(on_tap: on_search_tap, is_dark: is_dark),
          ),
          const SizedBox(width: 12),
          /// 右侧语种区域支持点击进入语言选择页。
          GestureDetector(
            onTap: on_language_tap,
            behavior: HitTestBehavior.translucent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipOval(
                  child: _buildLanguageIcon(
                    languageIconUrl: languageIconUrl,
                    languageCode: languageCode,
                  ),
                ),
                const SizedBox(width: 4),
                /// 展示当前语言名称。
                Text(
                  languageName,
                  maxLines: 1,
                  style: TextStyle(
                    color: languageTextColor,
                    fontSize: 15,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 6),
                /// 语言切换图标。
                SvgIcon(
                  name: 'translate',
                  color: languageTextColor,
                  width: 18,
                  height: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建语种图标。
  Widget _buildLanguageIcon({
    required String languageIconUrl,
    required String languageCode,
  }) {
    // 优先加载网络图标（接口数据）
    if (languageIconUrl.startsWith('http')) {
      return Image.network(
        languageIconUrl,
        width: 22,
        height: 22,
        fit: BoxFit.cover,
        // 如果网络图加载失败，回退到本地兜底逻辑
        errorBuilder: (_, __, ___) => _buildLocalIcon(languageCode),
      );
    }
    // 没有网络图时直接走本地兜底
    return _buildLocalIcon(languageCode);
  }

  /// 构建本地兜底图标。
  Widget _buildLocalIcon(String languageCode) {
    // 检查本地是否有对应代码的资源，如果没有则回退到英文 'en'
    final String assetPath = LanguageUtil.has_language_asset_image(languageCode)
        ? LanguageUtil.get_language_asset_image(languageCode)
        : LanguageUtil.get_language_asset_image('en');

    return Image.asset(
      assetPath,
      width: 22,
      height: 22,
      fit: BoxFit.cover,
      // 最后一层物理兜底，防止资源彻底丢失
      errorBuilder: (_, __, ___) =>
          Container(width: 22, height: 22, color: Colors.grey),
    );
  }
}
