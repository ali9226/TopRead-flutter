import 'package:flutter/material.dart';

import 'style.dart';

/// 全局统一提交按钮组件。
///
/// 所有页面（登录、注册、修改密码、修改昵称等）共用此按钮，
/// 保证视觉样式完全一致。支持日间/夜间主题、loading 状态和点击波纹。
///
/// 参数说明：
/// [title] - 按钮展示文案。
/// [isDark] - 当前是否为夜间模式。
/// [loading] - 是否处于提交加载状态，为 true 时显示 loading 指示器并禁用点击。
/// [onTap] - 点击回调。
/// [horizontalMargin] - 按钮水平外边距，0 表示撑满父容器宽度。
/// [suffix] - 可选的右侧图标，不传则不显示。
class CommonSubmitButton extends StatelessWidget {
  /// 按钮展示文案。
  final String title;

  /// 当前是否为夜间模式。
  final bool isDark;

  /// 是否处于提交加载状态。
  final bool loading;

  /// 点击回调。
  final VoidCallback? onTap;

  /// 按钮水平外边距，0 表示撑满父容器宽度。
  final double horizontalMargin;

  /// 可选的右侧图标，不传则不显示。
  final Widget? suffix;

  const CommonSubmitButton({
    super.key,
    required this.title,
    required this.isDark,
    this.loading = false,
    this.onTap,
    this.horizontalMargin = 0.0,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final Gradient? bgGradient = CommonSubmitButtonStyle.gradient(isDark: isDark);
    final Color? bgColor = CommonSubmitButtonStyle.solidColor(isDark: isDark);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      width: double.infinity,
      height: CommonSubmitButtonStyle.height,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(CommonSubmitButtonStyle.radius),
        boxShadow: CommonSubmitButtonStyle.shadow(isDark: isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CommonSubmitButtonStyle.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(CommonSubmitButtonStyle.radius),
          onTap: loading ? null : onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: bgColor,
              gradient: bgGradient,
              borderRadius: BorderRadius.circular(CommonSubmitButtonStyle.radius),
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: CommonSubmitButtonStyle.loadingSize,
                      height: CommonSubmitButtonStyle.loadingSize,
                      child: CircularProgressIndicator(
                        strokeWidth: CommonSubmitButtonStyle.loadingStrokeWidth,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          CommonSubmitButtonStyle.loadingColor(isDark: isDark),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: CommonSubmitButtonStyle.fontSize,
                            fontWeight: CommonSubmitButtonStyle.fontWeight,
                            color: CommonSubmitButtonStyle.textColor(
                              isDark: isDark,
                            ),
                          ),
                        ),
                        if (suffix != null) ...<Widget>[
                          const SizedBox(width: 6),
                          suffix!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
