import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/util/language_util/index.dart';
import '../style.dart';

/// 语种列表项。
///
/// 每一行展示一种语言的国旗、名称、口号和选中状态。
/// 选中时整行有主题色背景和右侧勾选图标。
class LanguageCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前语言是否已被选中。
  final bool isSelected;

  /// 当前语种数据，用来读取接口返回的图标地址。
  final LanguageInfo languageInfo;

  /// 语言主标题。
  final String title;

  /// 语言口号（remark 字段）。
  final String subtitle;

  /// 点击卡片后的回调。
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.isDark,
    required this.isSelected,
    required this.languageInfo,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  /// 根据语种代码构建国旗图标组件。
  Widget _build_flag_icon() {
    final String language_code = languageInfo.language_code;
    if (language_code == 'en') {
      return Image.asset(
        'assets/img/en.png',
        width: Style.flagSize,
        height: Style.flagSize,
        fit: BoxFit.cover,
      );
    }
    if (language_code == 'sw') {
      return Image.asset(
        'assets/img/sw.png',
        width: Style.flagSize,
        height: Style.flagSize,
        fit: BoxFit.cover,
      );
    }
    final String asset_path = languageInfo.icon.trim();
    if (asset_path.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: asset_path,
        width: Style.flagSize,
        height: Style.flagSize,
        fit: BoxFit.cover,
      );
    }
    return Image.asset(
      LanguageUtil.get_language_asset_image(language_code),
      width: Style.flagSize,
      height: Style.flagSize,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    /// 选中态背景色。
    final Color selectedBg = ColorConstants.themeColor.withValues(
      alpha: isDark ? 0.12 : 0.08,
    );

    /// 未选中态背景色。
    final Color normalBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.70);

    /// 标题文字色。
    final Color titleColor = isDark
        ? Colors.white
        : ColorConstants.lightTextColor;

    /// 口号文字色。
    final Color subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.50)
        : ColorConstants.lightTextColor.withValues(alpha: 0.45);

    /// 国旗图标背景色。
    final Color flagWrapBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : ColorConstants.themeColor.withValues(alpha: 0.08);

    /// 选中指示器背景色。
    final Color checkBg = ColorConstants.themeColor.withValues(
      alpha: isDark ? 0.18 : 0.14,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Style.itemGap),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Style.itemRadius),
          splashColor: ColorConstants.themeColor.withValues(alpha: 0.10),
          highlightColor: ColorConstants.themeColor.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: Style.itemHeight),
            padding: Style.itemPadding,
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : normalBg,
              borderRadius: BorderRadius.circular(Style.itemRadius),
              border: Border.all(
                color: isSelected
                    ? ColorConstants.themeColor.withValues(
                        alpha: isDark ? 0.20 : 0.16,
                      )
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03)),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // ── 国旗图标 ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: Style.flagWrapSize,
                  height: Style.flagWrapSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorConstants.themeColor.withValues(alpha: 0.14)
                        : flagWrapBg,
                    borderRadius: BorderRadius.circular(Style.flagWrapRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _build_flag_icon(),
                  ),
                ),
                const SizedBox(width: 12),

                // ── 文字区 ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Style.titleFontSize,
                          fontWeight: Style.titleWeight,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Style.subtitleFontSize,
                              fontWeight: Style.subtitleWeight,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── 选中指示器 ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: Style.checkSize,
                  height: Style.checkSize,
                  decoration: BoxDecoration(
                    color: isSelected ? checkBg : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? ColorConstants.themeColor.withValues(
                              alpha: isDark ? 0.40 : 0.50,
                            )
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08)),
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1 : 0,
                    child: Center(
                      child: SvgIcon(
                        name: 'check_03',
                        width: Style.checkIconSize,
                        height: Style.checkIconSize,
                        color: ColorConstants.themeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
