import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/util/router/run_navigation_action_once.dart';
import 'package:app/config/font_config.dart';

const double boxHeight = 40;
const double fontSize = 16;

class LoginRegisterButton extends StatefulWidget {
  const LoginRegisterButton({super.key});

  @override
  State<LoginRegisterButton> createState() => _LoginRegisterButtonState();
}

class _LoginRegisterButtonState extends State<LoginRegisterButton> {
  static const double _radius = 25;
  static const double _splitSlantWidth = 22;
  static const double _registerWidthCompensation = -1;
  static const double _textWidthSafetyPadding = 10;
  static const double _loginTextVisualOffsetX = -6;

  /// CJK 语系：中文字符紧凑，使用较宽松的内边距。
  static const double _leftOuterPaddingCjk = 24;
  static const double _leftInnerPaddingCjk = 14;
  static const double _rightOuterPaddingCjk = 24;
  static const double _rightInnerPaddingCjk = 14;
  static const double _segmentMinWidthCjk = 88;

  /// 非 CJK 语系：英文字母更宽，缩减内边距避免按钮过宽。
  static const double _leftOuterPaddingAlphabetic = 18;
  static const double _leftInnerPaddingAlphabetic = 10;
  static const double _rightOuterPaddingAlphabetic = 18;
  static const double _rightInnerPaddingAlphabetic = 10;
  static const double _segmentMinWidthAlphabetic = 80;

  final deviceInfo = Get.find<DeviceInfo>();

  @override
  Widget build(BuildContext context) {
    final bool isDark = deviceInfo.dark.value;
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

    /// 根据语种选择内边距。
    final double leftOuterPadding = is_cjk
        ? _leftOuterPaddingCjk
        : _leftOuterPaddingAlphabetic;
    final double leftInnerPadding = is_cjk
        ? _leftInnerPaddingCjk
        : _leftInnerPaddingAlphabetic;
    final double rightOuterPadding = is_cjk
        ? _rightOuterPaddingCjk
        : _rightOuterPaddingAlphabetic;
    final double rightInnerPadding = is_cjk
        ? _rightInnerPaddingCjk
        : _rightInnerPaddingAlphabetic;
    final double segmentMinWidth = is_cjk
        ? _segmentMinWidthCjk
        : _segmentMinWidthAlphabetic;

    final String loginText = easy.tr('UserInfo.login');
    final String registerText = easy.tr('UserInfo.register');
    final TextStyle textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
      height: 1,
    );
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final TextDirection textDirection = Directionality.of(context);

    final double loginWidth = _measureTextWidth(
      loginText,
      textStyle,
      textScaler,
      textDirection,
    );
    final double registerWidth = _measureTextWidth(
      registerText,
      textStyle,
      textScaler,
      textDirection,
    );
    final double leftSegmentWidth = math.max(
      segmentMinWidth,
      loginWidth +
          leftOuterPadding +
          leftInnerPadding +
          _splitSlantWidth +
          _textWidthSafetyPadding,
    );
    final double rightSegmentWidth = math.max(
      segmentMinWidth,
      registerWidth +
          rightOuterPadding +
          rightInnerPadding +
          _textWidthSafetyPadding +
          _registerWidthCompensation,
    );
    final double totalWidth = leftSegmentWidth + rightSegmentWidth;

    final Color rightBackgroundColor = isDark
        ? ColorConstants.nightBackgroundColor
        : ColorConstants.lightTextColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.20),
            blurRadius: isDark ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: CustomPaint(
          painter: _LoginRegisterButtonPainter(
            rightBackgroundColor: rightBackgroundColor,
            leftBackgroundColor: ColorConstants.themeColor,
            splitX: leftSegmentWidth,
            splitSlantWidth: _splitSlantWidth,
          ),
          child: SizedBox(
            width: totalWidth,
            height: boxHeight,
            child: Row(
              children: [
                SizedBox(
                  width: leftSegmentWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        run_navigation_action_once(
                          actionKey: 'user_info_login_entry',
                          action: () async {
                            routerUtil(path: '/login');
                          },
                        );
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: leftOuterPadding,
                          right: leftInnerPadding,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Transform.translate(
                            offset: const Offset(_loginTextVisualOffsetX, 0),
                            child: Text(
                              loginText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle.copyWith(
                                color: ColorConstants.lightTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: rightSegmentWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        run_navigation_action_once(
                          actionKey: 'user_info_register_entry',
                          action: () async {
                            routerUtil(path: '/register');
                          },
                        );
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: rightInnerPadding,
                          right: rightOuterPadding,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            registerText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle.copyWith(
                              color: ColorConstants.themeColor,
                            ),
                          ),
                        ),
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

  double _measureTextWidth(
    String text,
    TextStyle style,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    return painter.width;
  }
}

class _LoginRegisterButtonPainter extends CustomPainter {
  final Color rightBackgroundColor;
  final Color leftBackgroundColor;
  final double splitX;
  final double splitSlantWidth;

  const _LoginRegisterButtonPainter({
    required this.rightBackgroundColor,
    required this.leftBackgroundColor,
    required this.splitX,
    required this.splitSlantWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect clipRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(25),
    );

    canvas.save();
    canvas.clipRRect(clipRRect);

    final Paint rightPaint = Paint()..color = rightBackgroundColor;
    canvas.drawRect(Offset.zero & size, rightPaint);

    final Path leftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(splitX, 0)
      ..lineTo(splitX - splitSlantWidth, size.height)
      ..lineTo(0, size.height)
      ..close();
    final Paint leftPaint = Paint()..color = leftBackgroundColor;
    canvas.drawPath(leftPath, leftPaint);

    final Path dividerPath = Path()
      ..moveTo(splitX - 2, 0)
      ..lineTo(splitX - splitSlantWidth - 2, size.height)
      ..lineTo(splitX - splitSlantWidth + 2, size.height)
      ..lineTo(splitX + 2, 0)
      ..close();
    final Paint dividerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08);
    canvas.drawPath(dividerPath, dividerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoginRegisterButtonPainter oldDelegate) {
    return oldDelegate.rightBackgroundColor != rightBackgroundColor ||
        oldDelegate.leftBackgroundColor != leftBackgroundColor ||
        oldDelegate.splitX != splitX ||
        oldDelegate.splitSlantWidth != splitSlantWidth;
  }
}
