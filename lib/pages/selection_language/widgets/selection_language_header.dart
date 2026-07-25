import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import '../style.dart';
import 'package:app/config/font_config.dart';

/// 语言选择页顶部操作栏。
///
/// 负责关闭按钮和完成按钮，主页面只关心状态和回调。
class SelectionLanguageHeader extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 页面基础背景色。
  final Color backgroundColor;

  /// 头部图标和文字颜色。
  final Color titleColor;

  /// 当前语言是否发生了变化。
  final bool changed;

  /// 点击关闭后的回调。
  final VoidCallback onTapClose;

  /// 点击完成后的回调。
  final VoidCallback onTapDone;

  const SelectionLanguageHeader({
    super.key,
    required this.isDark,
    required this.backgroundColor,
    required this.titleColor,
    required this.changed,
    required this.onTapClose,
    required this.onTapDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            backgroundColor.withValues(alpha: isDark ? 0.94 : 0.96),
            backgroundColor.withValues(alpha: isDark ? 0.76 : 0.72),
            backgroundColor.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: Style.headerPadding,
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: onTapClose,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: Style.headerActionSize,
                  height: Style.headerActionSize,
                  child: Center(
                    child: SvgIcon(
                      name: 'close',
                      width: 18,
                      height: 18,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: changed ? 1 : 0.92,
                child: ElevatedButton(
                  onPressed: onTapDone,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: ColorConstants.themeColor,
                    foregroundColor: ColorConstants.lightTextColor,
                    minimumSize: const Size(
                      Style.doneButtonWidth,
                      Style.doneButtonHeight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Style.doneButtonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    easy.tr('SelectionLanguage.done'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
