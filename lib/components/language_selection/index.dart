// ignore_for_file: non_constant_identifier_names

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/util/language_util/index.dart';
import 'style.dart';
import 'logic.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:get/get.dart';

// TODO 语种选择
class LanguageSelection extends StatefulWidget {
  final bool showLeftIcon;
  final bool showLeftLogo;
  final bool showRightLanguageEntry;
  final bool darkBackground;
  final String? title;
  final VoidCallback? onLeftTapOverride;
  final bool useSafeAreaTop;
  final double topOffset;
  final double horizontalPadding;
  final Widget? customLeftChild;

  /// 个人中心等浅色背景顶栏：强制使用深色字（与全局日夜间主题无关）。
  ///
  /// Web 首帧 [AppRouter.currentRouteName] 可能尚未同步到嵌套 Shell 子路由，
  /// 仅依赖路由名会出现夜间主题下误用白字的问题；在宿主页显式传 true 可首帧即正确。
  final bool userInfoContrastText;

  const LanguageSelection({
    super.key,
    this.showLeftIcon = true, // TODO 是否显示左侧关闭的图标
    this.showLeftLogo = false, // TODO 是否显示左侧logo
    this.showRightLanguageEntry = true, // TODO 是否显示右侧语种切换入口
    this.darkBackground = false, // TODO 是否深色背景
    this.title,
    this.onLeftTapOverride,
    this.useSafeAreaTop = true,
    this.topOffset = 0,
    this.horizontalPadding = 16,
    this.customLeftChild,
    this.userInfoContrastText = false,
  });

  @override
  State<LanguageSelection> createState() => _LanguageSelectionState();
}

class _LanguageSelectionState extends State<LanguageSelection> {
  late Logic logic;

  final deviceInfo = Get.find<DeviceInfo>();
  final GlobalKey _leftKey = GlobalKey();
  final GlobalKey _rightKey = GlobalKey();
  double _leftWidth = 44;
  double _rightWidth = 120;

  /// 是否在「个人中心」场景使用深色字：宿主显式声明，或路由名 / 路径已就绪。
  bool get _keepDarkTextOnUserInfo {
    if (widget.userInfoContrastText) {
      return true;
    }
    if (AppRouter.currentRouteName() == 'user_info') {
      return true;
    }
    return AppRouter.currentPath() == '/user_info';
  }

  /// 仅在特定页面横屏时隐藏整个右侧语种入口。
  bool _should_hide_right_language_entry(BuildContext context) {
    final bool is_landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    if (!is_landscape) {
      return false;
    }
    if (AppRouter.currentRouteName() == 'game') {
      return true;
    }
    return AppRouter.currentPath() == '/game';
  }

  @override
  void initState() {
    super.initState();
    logic = Logic(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSideWidths();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppRouter.routeChangeListenable(),
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          logic.ensure_offline_language_fallback();
        });
        return _buildLanguageBar(context);
      },
    );
  }

  /// 构建顶栏：依赖路由监听，使 Web 上路由晚一拍同步时仍能刷新文字色。
  Widget _buildLanguageBar(BuildContext context) {
    final String lang_code = context.locale.languageCode;
    final String language_name = LanguageUtil.get_language_name(lang_code);

    final content = Container(
      margin: EdgeInsets.only(top: widget.topOffset),
      height: Style.containerHeight,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titlePadding =
              (_leftWidth > _rightWidth ? _leftWidth : _rightWidth) + 16;
          final bool hasCustomLeftChild = widget.customLeftChild != null;

          return Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasCustomLeftChild)
                    Expanded(
                      child: Container(
                        key: _leftKey,
                        constraints: const BoxConstraints(minWidth: 44),
                        height: Style.containerHeight,
                        alignment: Alignment.centerLeft,
                        child: _buildLeftAction(),
                      ),
                    )
                  else
                    Container(
                      key: _leftKey,
                      constraints: const BoxConstraints(minWidth: 44),
                      height: Style.containerHeight,
                      alignment: Alignment.centerLeft,
                      child: _buildLeftAction(),
                    ),
                  if (hasCustomLeftChild) const SizedBox(width: 12),
                  Container(
                    key: _rightKey,
                    height: Style.containerHeight,
                    alignment: Alignment.centerRight,
                    child: _buildLanguageAction(lang_code, language_name),
                  ),
                ],
              ),
              if (widget.title != null && widget.title!.trim().isNotEmpty)
                IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: min<double>(
                        titlePadding,
                        constraints.maxWidth / 2 - 12,
                      ),
                    ),
                    child: Obx(() {
                      final isDark = deviceInfo.theme.value == ThemeMode.dark;
                      return AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: Style.titleStyle.copyWith(
                          color: widget.darkBackground
                              ? ColorConstants.whiteColor
                              : _keepDarkTextOnUserInfo
                              ? ColorConstants.lightTextColor
                              : isDark
                              ? ColorConstants.whiteColor
                              : ColorConstants.lightTextColor,
                        ),
                        child: Text(
                          widget.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (!widget.useSafeAreaTop) {
      return content;
    }

    return SafeArea(bottom: false, child: content);
  }

  @override
  void didUpdateWidget(covariant LanguageSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSideWidths();
    });
  }

  void _updateSideWidths() {
    final leftContext = _leftKey.currentContext;
    final rightContext = _rightKey.currentContext;
    if (leftContext == null || rightContext == null) return;

    final leftBox = leftContext.findRenderObject() as RenderBox?;
    final rightBox = rightContext.findRenderObject() as RenderBox?;
    if (leftBox == null || rightBox == null) return;

    final nextLeftWidth = leftBox.size.width;
    final nextRightWidth = rightBox.size.width;

    if ((nextLeftWidth - _leftWidth).abs() < 1 &&
        (nextRightWidth - _rightWidth).abs() < 1) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _leftWidth = nextLeftWidth;
      _rightWidth = nextRightWidth;
    });
  }

  Widget? _buildLeftAction() {
    if (widget.customLeftChild != null) {
      return widget.customLeftChild;
    }

    if (widget.showLeftIcon && !widget.showLeftLogo) {
      return Obx(() {
        final isDark = deviceInfo.theme.value == ThemeMode.dark;
        return GestureDetector(
          onTap: widget.onLeftTapOverride ?? logic.onLeftTap,
          child: SvgIcon(
            name: "close",
            color: widget.darkBackground
                ? ColorConstants.whiteColor
                : isDark
                ? ColorConstants.whiteColor
                : ColorConstants.lightTextColor,
            width: Style.closeSize,
            height: Style.closeSize,
          ),
        );
      });
    }

    if (widget.showLeftLogo && !widget.showLeftIcon) {
      return Obx(() {
        final isDark = deviceInfo.dark.value;
        return SvgIcon(
          name: "logo",
          color: isDark
              ? ColorConstants.whiteColor
              : ColorConstants.lightTextColor,
          width: Style.logoSize,
          height: Style.logoSize,
        );
      });
    }

    return null;
  }

  /// TODO 构建语种入口图标。
  Widget _buildLanguageIcon({
    required String languageIconUrl,
    required String languageCode,
  }) {
    final String assetFallbackPath =
        LanguageUtil.has_language_asset_image(languageCode)
            ? LanguageUtil.get_language_asset_image(languageCode)
            : 'assets/img/en.png';

    if (languageIconUrl.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: languageIconUrl,
        width: Style.nationSize,
        height: Style.nationSize,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) {
          return Image.asset(
            assetFallbackPath,
            width: Style.nationSize,
            height: Style.nationSize,
            fit: BoxFit.cover,
          );
        },
      );
    }

    return Image.asset(
      assetFallbackPath,
      width: Style.nationSize,
      height: Style.nationSize,
      fit: BoxFit.cover,
    );
  }

  Widget _buildLanguageAction(String langCode, String language_name) {
    if (!widget.showRightLanguageEntry) {
      return const SizedBox.shrink();
    }
    if (_should_hide_right_language_entry(context)) {
      return const SizedBox.shrink();
    }

    final LanguageStore languageStore = Get.find<LanguageStore>();
    final LanguageInfo? currentLanguageInfo = languageStore
        .find_supported_language_by_code(langCode);
    final String resolved_language_code =
        currentLanguageInfo?.code.trim().toLowerCase() ??
        langCode.trim().toLowerCase();
    final String languageIconUrl = currentLanguageInfo?.icon ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: logic.onRightTap,
          behavior: HitTestBehavior.translucent,
          child: ClipOval(
            child: _buildLanguageIcon(
              languageIconUrl: languageIconUrl,
              languageCode: resolved_language_code,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Obx(() {
          final isDark = deviceInfo.theme.value == ThemeMode.dark;
          return GestureDetector(
            onTap: logic.onRightTap,
            behavior: HitTestBehavior.translucent,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: Style.textStyle.copyWith(
                color: widget.darkBackground
                    ? ColorConstants.whiteColor
                    : _keepDarkTextOnUserInfo
                    ? ColorConstants.lightTextColor
                    : isDark
                    ? ColorConstants.whiteColor
                    : ColorConstants.lightTextColor,
              ),
              child: Text(
                language_name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Obx(() {
          final isDark = deviceInfo.theme.value == ThemeMode.dark;
          return GestureDetector(
            onTap: logic.onRightTap,
            behavior: HitTestBehavior.translucent,
            child: SvgIcon(
              name: "translate",
              color: widget.darkBackground
                  ? ColorConstants.whiteColor
                  : _keepDarkTextOnUserInfo
                  ? ColorConstants.lightTextColor
                  : isDark
                  ? ColorConstants.whiteColor
                  : ColorConstants.lightTextColor,
              width: Style.nationSize * 0.8,
              height: Style.nationSize * 0.8,
            ),
          );
        }),
      ],
    );
  }
}
