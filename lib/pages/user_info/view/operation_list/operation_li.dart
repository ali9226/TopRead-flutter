import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/stores/device_info.dart';
import 'style.dart';

class OperationLi extends StatefulWidget {
  final String icon;
  final String title;
  final int type;
  final bool showDivider;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 标题文字颜色，为空时使用默认主题色。
  final Color? titleColor;

  /// 图标颜色，为空时使用默认主题色。
  final Color? iconColor;

  /// 右侧箭头颜色，为空时使用默认次要色。
  final Color? arrowColor;

  const OperationLi({
    super.key,
    required this.icon,
    required this.title,
    this.type = 1,
    this.showDivider = true,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
    this.arrowColor,
  });

  @override
  State<OperationLi> createState() => _OperationLiState();
}

class _OperationLiState extends State<OperationLi>
    with SingleTickerProviderStateMixin {
  final deviceInfo = Get.find<DeviceInfo>();

  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _opacityAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showThemeChangeOverlay(bool darkMode) {
    bool themeChanged = false;
    final overlayState = Overlay.of(context, rootOverlay: true);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _opacityAnim,
          builder: (context, child) {
            return Stack(
              children: [
                const ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
                Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: Center(
                      child: Transform.scale(
                        scale: 0.5 + 0.5 * _opacityAnim.value,
                        child: SvgIcon(
                          name: darkMode ? "moon" : "sun",
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlayState.insert(_overlayEntry!);
    _controller.forward(from: 0);

    late VoidCallback listener;
    listener = () {
      if (_controller.value >= 0.5 && !themeChanged) {
        themeChanged = true;
        deviceInfo.changeTheme(darkMode ? ThemeMode.dark : ThemeMode.light);
      }
    };

    _controller.addListener(listener);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _controller.removeListener(listener);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final switchValue = deviceInfo.theme.value == ThemeMode.dark;
      final itemPadding = switchValue
          ? Style.darkItemPadding
          : Style.lightItemPadding;
      final bgColor = switchValue ? Colors.transparent : Colors.transparent;
      final textColor = switchValue
          ? ColorConstants.whiteColor
          : ColorConstants.lightTextColor;
      final subColor = switchValue
          ? Colors.white.withValues(alpha: 0.38)
          : ColorConstants.lightTextColor.withValues(alpha: 0.22);
      final iconWrapColor = switchValue
          ? Colors.white.withValues(alpha: 0.06)
          : ColorConstants.themeColor.withValues(alpha: 0.12);
      final borderColor = switchValue
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.06);

      return AnimatedContainer(
        duration: Duration(milliseconds: ThemeConstants.animationTime),
        color: bgColor,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.type == 2
                ? () {
                    _showThemeChangeOverlay(!switchValue);
                  }
                : widget.onTap,
            splashColor: ColorConstants.themeColor.withValues(alpha: 0.12),
            highlightColor: ColorConstants.themeColor.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: Duration(milliseconds: ThemeConstants.animationTime),
              curve: Curves.easeInOut,
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: Style.liHeight),
              padding: itemPadding,
              decoration: BoxDecoration(
                border: widget.showDivider
                    ? Border(bottom: BorderSide(color: borderColor, width: 1))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: Style.iconWrapSize,
                    height: Style.iconWrapSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconWrapColor,
                      borderRadius: BorderRadius.circular(Style.iconWrapRadius),
                    ),
                    child: SvgIcon(
                      name: widget.icon,
                      color: widget.iconColor ?? textColor,
                      width: 20,
                      height: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: Style.titleFontWeight,
                        color: widget.titleColor ?? textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.trailing != null)
                    widget.trailing!
                  else if (widget.type == 1)
                    SvgIcon(
                      name: "right",
                      width: 16,
                      height: 16,
                      color: widget.arrowColor ?? subColor,
                    )
                  else if (widget.type == 2)
                    IgnorePointer(
                      child: FlutterSwitch(
                        width: 54.0,
                        height: 28.0,
                        toggleSize: 22.0,
                        value: switchValue,
                        borderRadius: 20.0,
                        padding: 3.0,
                        activeColor: ColorConstants.themeColor,
                        inactiveColor: Colors.grey.shade300,
                        toggleColor: Colors.white,
                        activeIcon: SvgIcon(
                          name: "moon",
                          width: 14,
                          height: 14,
                        ),
                        inactiveIcon: SvgIcon(
                          name: "sun",
                          width: 14,
                          height: 14,
                        ),
                        onToggle: (_) {},
                      ),
                    )
                  else if (widget.type == 3)
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ColorConstants.themeColor.withValues(
                          alpha: switchValue ? 0.10 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ColorConstants.themeColor.withValues(
                            alpha: switchValue ? 0.18 : 0.24,
                          ),
                        ),
                      ),
                      child: SvgIcon(
                        name: "copy",
                        width: 18,
                        height: 18,
                        color: ColorConstants.themeColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
