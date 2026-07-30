// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;

import 'package:app/config/color_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/interest_preference/style.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 兴趣偏好页面顶部导航栏组件。
///
/// 包含左侧返回按钮和右侧保存按钮。
/// 返回按钮在内容滚动到与导航栏重叠时显示半透明圆圈背景。
/// 保存按钮支持 loading 状态和置灰禁用状态，状态切换带有过渡动画。
/// 支持日间/夜间主题切换。
class TopBar extends StatelessWidget {
  /// 是否为夜间模式。
  final bool isDark;

  /// 内容是否已滚动到与导航栏重叠（控制返回按钮背景显隐）。
  final bool scrolled;

  /// 状态栏高度（用于顶部安全区内边距）。
  final double statusBarHeight;

  /// 页面是否处于加载中状态（初始查询或提交保存）。
  final bool isLoading;

  /// 保存按钮是否可点击（false 时置灰且不可交互）。
  final bool canSave;

  /// 保存按钮点击回调。
  final VoidCallback onSave;

  /// 返回按钮点击回调，由页面层统一控制返回逻辑（弹窗拦截等）。
  final VoidCallback onBack;

  /// 跳过按钮点击回调。
  ///
  /// 仅注册完成专用页面传入，普通兴趣偏好页面保持 null。
  final VoidCallback? onSkip;

  /// 跳过按钮是否可点击。
  final bool isSkipEnabled;

  const TopBar({
    super.key,
    required this.isDark,
    required this.scrolled,
    required this.statusBarHeight,
    required this.isLoading,
    required this.canSave,
    required this.onSave,
    required this.onBack,
    this.onSkip,
    this.isSkipEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      /// 顶部安全区内边距。
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Container(
        /// 导航栏固定高度。
        height: InterestPreferenceStyle.topBarHeight,

        /// 左右内边距，与页面内容对齐。
        padding: const EdgeInsets.symmetric(
          horizontal: InterestPreferenceStyle.pageHorizontalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            /// 左侧返回按钮。
            _build_back_button(),

            /// 右侧操作区：普通页面仅保存，注册专用页面为保存 + 跳过。
            _build_action_buttons(context),
          ],
        ),
      ),
    );
  }

  /// 构建右侧操作按钮组。
  Widget _build_action_buttons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _build_save_button(context),
        if (onSkip != null) ...<Widget>[
          const SizedBox(width: InterestPreferenceStyle.topBarActionSpacing),
          _build_skip_button(context),
        ],
      ],
    );
  }

  /// 构建返回按钮。
  ///
  /// 点击后调用 [onBack] 回调，由页面层统一处理返回逻辑。
  /// 内容滚动重叠时显示半透明圆圈背景，带有 200ms 动画过渡。
  Widget _build_back_button() {
    return GestureDetector(
      onTap: onBack,
      child: AnimatedContainer(
        /// 背景显隐动画时长。
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scrolled
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08))
              : Colors.transparent,
        ),
        child: Transform.rotate(
          /// 旋转 180 度使箭头朝左。
          angle: 3.141592653589793,
          child: SvgIcon(
            name: 'right',
            width: 20,
            height: 20,
            color: InterestPreferenceStyle.topBarIconColor(isDark: isDark),
          ),
        ),
      ),
    );
  }

  /// 构建保存按钮。
  ///
  /// 按钮状态：
  /// - 正常可点击：主题色背景 + 黑色文字
  /// - 置灰不可点击：40% 透明度背景 + 40% 透明度文字
  /// - 提交中 loading：40% 透明度背景 + 转圈动画
  /// 背景颜色和文字颜色切换均带有 300ms easeInOut 过渡动画。
  Widget _build_save_button(BuildContext context) {
    /// 按钮是否处于禁用状态（loading 或无变化）。
    final bool disabled = isLoading || !canSave;

    return GestureDetector(
      /// 禁用状态下点击无响应。
      onTap: disabled ? null : onSave,
      child: AnimatedContainer(
        /// 背景颜色过渡动画。
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: InterestPreferenceStyle.topBarButtonHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: InterestPreferenceStyle.saveButtonHorizontalPadding,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled
              ? ColorConstants.themeColor.withValues(alpha: 0.4)
              : ColorConstants.themeColor,
          borderRadius: BorderRadius.circular(
            InterestPreferenceStyle.topBarButtonHeight / 2,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : AnimatedDefaultTextStyle(
                /// 文字颜色过渡动画。
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: _resolve_action_font_size(context),
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: canSave
                      ? Colors.black
                      : Colors.black.withValues(alpha: 0.4),
                ),
                child: Text(easy.tr('interest_preference.save')),
              ),
      ),
    );
  }

  /// 构建注册流程专用的跳过按钮。
  ///
  /// 使用轻量文字按钮与高强调保存按钮形成清晰层级，最小点击区域满足移动端
  /// 触控尺寸，同时根据 CJK/非 CJK 语种调整字号。
  Widget _build_skip_button(BuildContext context) {
    return TextButton(
      onPressed: isSkipEnabled ? onSkip : null,
      style: TextButton.styleFrom(
        minimumSize: const Size(
          InterestPreferenceStyle.skipButtonMinWidth,
          InterestPreferenceStyle.skipButtonMinHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: InterestPreferenceStyle.skipButtonHorizontalPadding,
        ),
        foregroundColor: InterestPreferenceStyle.topBarIconColor(
          isDark: isDark,
        ),
        disabledForegroundColor: InterestPreferenceStyle.topBarIconColor(
          isDark: isDark,
        ).withValues(alpha: 0.35),
        textStyle: TextStyle(
          fontSize: _resolve_action_font_size(context),
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        ),
      ),
      child: Text(easy.tr('interest_preference.skip')),
    );
  }

  /// 根据当前语种返回顶部操作按钮字号。
  double _resolve_action_font_size(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    return is_cjk
        ? InterestPreferenceStyle.topBarActionFontSizeCjk
        : InterestPreferenceStyle.topBarActionFontSizeAlphabetic;
  }
}
