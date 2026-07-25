import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/back_to_top_button/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/language_selection/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/layout/page_header_spacing.dart';

import 'logic.dart';
import 'style.dart';
import 'widgets/bottom_action.dart';
import 'widgets/empty_state.dart';
import 'widgets/hero_card.dart';
import 'widgets/record_card.dart';

/// 提现记录页面。
///
/// 页面本身不直接处理分页和状态文案映射，
/// 而是把“数据状态”交给 `WithdrawRecordLogic`，
/// 自己只负责把当前状态渲染成背景、列表、头部和悬浮按钮。
class WithdrawRecord extends StatefulWidget {
  const WithdrawRecord({super.key});

  @override
  State<WithdrawRecord> createState() => _WithdrawRecordState();
}

class _WithdrawRecordState extends State<WithdrawRecord> {
  /// 全局设备主题仓库。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 提现记录页逻辑层。
  late final WithdrawRecordLogic logic;

  @override
  void initState() {
    super.initState();

    /// 初始化逻辑层。
    logic = WithdrawRecordLogic();

    /// 监听逻辑层状态变化，统一刷新页面。
    logic.addListener(_handleLogicChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// 首帧后再拉取数据，避免阻塞页面首次渲染。
      logic.init();
    });
  }

  @override
  void dispose() {
    /// 页面销毁前取消监听，避免释放后继续回调。
    logic.removeListener(_handleLogicChanged);

    /// 释放逻辑层内部资源。
    logic.dispose();
    super.dispose();
  }

  void _handleLogicChanged() {
    /// 页面已经销毁时，不再触发刷新。
    if (!mounted) return;

    /// 逻辑层状态变化后同步刷新 UI。
    setState(() {});
  }

  /// 下拉刷新成功后提示「刷新成功」（多语种 `constant.refresh_success`）。
  Future<void> _handlePullRefresh() async {
    final bool ok = await logic.refresh();
    if (!mounted || !ok) return;
    showBottomTip(context.tr('constant.refresh_success'));
  }

  Future<void> _handleCopy(String value) async {
    /// 空字符串和占位值不允许复制。
    if (value.trim().isEmpty || value.trim() == '--') return;

    /// 调用统一剪贴板工具执行复制。
    final status = await copyToClipboard(value);

    /// 复制失败或页面已销毁时不再提示。
    if (!mounted || !status) return;

    /// 复制成功后给出底部轻提示。
    showBottomTip(context.tr('withdraw_record_page.copy_success'));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// 当前是否深色模式。
      final isDark = deviceInfo.dark.value;

      /// 页面底色。
      final backgroundColor = isDark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.lightBackgroundColor;

      /// 媒体信息，用于计算安全区和头部留白。
      final mediaQuery = MediaQuery.of(context);
      final safePadding = mediaQuery.padding;

      /// 主内容顶部起始位置。
      final contentTopPadding = resolvePageHeaderContentTopPadding(
        mediaQuery: mediaQuery,
        headerBottomFadeSpacing: TopUpRecordStyle.headerBottomFadeSpacing,
      );

      return Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: ThemeConstants.animationTime),
          curve: Curves.easeInOut,
          color: backgroundColor,
          child: Stack(
            children: [
              /// 页面主背景渐变层。
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? TopUpRecordStyle.darkBackgroundGradient
                          : TopUpRecordStyle.lightBackgroundGradient,
                    ),
                  ),
                ),
              ),

              /// 右上装饰光斑。
              Positioned(
                top: TopUpRecordStyle.decorCircleOneTop,
                right: TopUpRecordStyle.decorCircleOneRight,
                child: IgnorePointer(
                  child: Container(
                    width: TopUpRecordStyle.decorCircleOneSize,
                    height: TopUpRecordStyle.decorCircleOneSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConstants.themeColor.withValues(
                        alpha: isDark
                            ? TopUpRecordStyle.decorCircleOneDarkOpacity
                            : TopUpRecordStyle.decorCircleOneLightOpacity,
                      ),
                    ),
                  ),
                ),
              ),

              /// 左侧辅助光斑。
              Positioned(
                top: TopUpRecordStyle.decorCircleTwoTop,
                left: TopUpRecordStyle.decorCircleTwoLeft,
                child: IgnorePointer(
                  child: Container(
                    width: TopUpRecordStyle.decorCircleTwoSize,
                    height: TopUpRecordStyle.decorCircleTwoSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConstants.successColor.withValues(
                        alpha: TopUpRecordStyle.decorCircleTwoOpacity,
                      ),
                    ),
                  ),
                ),
              ),

              /// 主列表区域，支持下拉刷新。
              RefreshIndicator(
                onRefresh: _handlePullRefresh,
                child: ListView(
                  /// 绑定逻辑层滚动控制器，便于统一处理返回顶部按钮。
                  controller: logic.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    TopUpRecordStyle.pageHorizontalPadding + safePadding.left,
                    contentTopPadding,
                    TopUpRecordStyle.pageHorizontalPadding + safePadding.right,
                    TopUpRecordStyle.pageBottomPadding + safePadding.bottom,
                  ),
                  children: [
                    /// 顶部说明卡。
                    WithdrawRecordHeroCard(isDark: isDark),
                    const SizedBox(height: TopUpRecordStyle.heroBottomSpacing),

                    /// 没有记录且当前不在加载时，展示空状态。
                    if (logic.records.isEmpty && !logic.loading)
                      WithdrawRecordEmptyState(isDark: isDark),

                    /// 有记录时，依次渲染每条提现流水卡片。
                    if (logic.records.isNotEmpty) ...[
                      ...logic.records.map(
                        (item) => WithdrawRecordCard(
                          isDark: isDark,
                          item: item,
                          amountText: logic.displayAmount(item.amountPayable),
                          serialNumberText: logic.displayText(
                            item.serialNumber,
                          ),
                          createTimeText: logic.displayUtcTime(item.createTime),
                          payTimeText: logic.displayUtcTime(item.payTime),
                          payQrCodeText: logic.displayText(item.payQrCode),
                          showPayTime: logic.shouldShowPayTime(item),
                          statusText: logic.statusText(context, item),
                          statusColor: logic.statusColor(isDark, item),
                          onCopySerialNumber: () {
                            _handleCopy(item.serialNumber);
                          },
                          onCopyPayQrCode: () {
                            _handleCopy(item.payQrCode);
                          },
                        ),
                      ),

                      /// 列表和底部操作区之间的间距。
                      const SizedBox(
                        height: TopUpRecordStyle.listBottomSpacing,
                      ),

                      /// 底部分页状态区。
                      WithdrawRecordBottomAction(
                        isDark: isDark,
                        loadingMore: logic.loadingMore,
                        hasMore: logic.hasMore,
                      ),
                    ],
                  ],
                ),
              ),

              /// 顶部固定标题栏。
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.only(
                      bottom: TopUpRecordStyle.headerBottomFadeSpacing,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          backgroundColor.withValues(
                            alpha: TopUpRecordStyle.headerGradientStartOpacity,
                          ),
                          backgroundColor.withValues(
                            alpha: TopUpRecordStyle.headerGradientMiddleOpacity,
                          ),
                          backgroundColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: LanguageSelection(
                      darkBackground: isDark,
                    ),
                  ),
                ),
              ),

              /// 首次加载和刷新期间的轻量遮罩。
              if (logic.loading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: TopUpRecordStyle.loadingMaskOpacity,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: TopUpRecordStyle.loadingCardPadding,
                        decoration: BoxDecoration(
                          color: isDark
                              ? TopUpRecordStyle.darkLoadingCardColor
                              : TopUpRecordStyle.lightLoadingCardColor,
                          borderRadius: BorderRadius.circular(
                            TopUpRecordStyle.loadingCardRadius,
                          ),
                        ),
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),

              /// 右下角返回顶部按钮。
              Positioned(
                right:
                    floating_back_to_top_style.FloatingBackToTopStyle.right +
                    safePadding.right,
                bottom:
                    floating_back_to_top_style
                        .FloatingBackToTopStyle
                        .page_bottom +
                    safePadding.bottom,
                child: AnimatedSlide(
                  duration: const Duration(
                    milliseconds: TopUpRecordStyle.backToTopSlideDurationMs,
                  ),
                  curve: Curves.easeOutCubic,
                  offset: logic.showBackToTop
                      ? Offset.zero
                      : const Offset(
                          0,
                          TopUpRecordStyle.backToTopHiddenOffsetY,
                        ),
                  child: AnimatedOpacity(
                    duration: const Duration(
                      milliseconds: TopUpRecordStyle.backToTopOpacityDurationMs,
                    ),
                    opacity: logic.showBackToTop ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !logic.showBackToTop,
                      child: BackToTopButton(
                        isDark: isDark,
                        onTap: logic.scrollToTop,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
