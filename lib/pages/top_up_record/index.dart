import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/back_to_top_button/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/language_selection/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/layout/page_header_spacing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'logic.dart';
import 'style.dart';
import 'widgets/bottom_action.dart';
import 'widgets/empty_state.dart';
import 'widgets/hero_card.dart';
import 'widgets/record_card.dart';

/// 充值记录页面。
///
/// 这个文件只负责页面级 UI 编排，不承担接口请求、分页判断、金额格式化等业务逻辑。
/// 结构上分成四层：
/// 1. 背景渐变和装饰光斑。
/// 2. 可滚动的主体内容列表。
/// 3. 固定在顶部的标题栏。
/// 4. loading 遮罩和返回顶部悬浮按钮。
///
/// 这样拆分后，`index.dart` 保持“只关心页面长什么样”，
/// 而不需要在这里混入过多状态判断和数据处理细节。
class TopUpRecord extends StatefulWidget {
  const TopUpRecord({super.key});

  @override
  State<TopUpRecord> createState() => _TopUpRecordState();
}

class _TopUpRecordState extends State<TopUpRecord> {
  /// 统一从 GetX 中读取当前设备信息。
  ///
  /// 当前页面主要依赖其中的 `dark` 状态来切换整套深浅色主题。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 页面逻辑控制器。
  ///
  /// 页面所有与数据相关的状态都托管给它：
  /// - 首次加载
  /// - 下拉刷新
  /// - 自动加载更多
  /// - 返回顶部显隐
  /// - 文本格式化
  late final TopUpRecordLogic logic;

  @override
  void initState() {
    super.initState();

    // 初始化页面逻辑对象，并监听逻辑层的状态变更。
    // 这里不直接使用更重的状态管理方案，而是让逻辑层继承 ChangeNotifier，
    // 这样当前页面可以用最小成本完成“状态变化 -> 刷新 UI”的闭环。
    logic = TopUpRecordLogic();
    logic.addListener(_handleLogicChanged);

    // 等页面首帧绘制完成后再触发初始化逻辑，
    // 可以避免在 initState 的同步阶段直接触发网络请求导致的时机问题。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logic.init();
    });
  }

  @override
  void dispose() {
    // 页面销毁时需要显式解绑监听并释放逻辑层资源，
    // 否则会留下无效监听器或滚动控制器泄漏。
    logic.removeListener(_handleLogicChanged);
    logic.dispose();
    super.dispose();
  }

  void _handleLogicChanged() {
    // 逻辑层有状态更新时，驱动页面重建。
    // mounted 判断是必要的，避免异步回调晚于页面销毁时触发 setState。
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleCopyPayQrCode(String value) async {
    // 纯空白二维码内容没有复制意义，直接拦截。
    if (value.trim().isEmpty) return;

    // 调起系统剪贴板复制。
    final status = await copyToClipboard(value);

    // 页面销毁或复制失败时，都不再展示成功提示。
    if (!mounted || !status) return;
    showBottomTip(easy.tr('top_up_record_page.copy_success'));
  }

  Future<void> _handleCopySerialNumber(String value) async {
    // 当流水号为空，或已经被格式化成占位值 `--` 时，不允许继续复制。
    if (value.trim().isEmpty || value.trim() == '--') return;

    // 把真实流水号写入系统剪贴板。
    final status = await copyToClipboard(value);

    // 只有当前页仍然存在且复制成功时，才提示用户。
    if (!mounted || !status) return;
    showBottomTip(easy.tr('top_up_record_page.copy_success'));
  }

  /// 下拉刷新成功后提示「刷新成功」（多语种 `constant.refresh_success`）。
  Future<void> _handlePullRefresh() async {
    final bool ok = await logic.refresh();
    if (!mounted || !ok) return;
    showBottomTip(easy.tr('constant.refresh_success'));
  }

  Future<void> _showQrDialog({
    required bool isDark,
    required String value,
  }) async {
    // 没有二维码原文时，不弹空白弹窗。
    if (value.trim().isEmpty) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        // 这两组颜色根据主题切换标题和辅助文案的可读性。
        final titleColor = isDark
            ? ColorConstants.whiteColor
            : ColorConstants.lightTextColor;
        final hintColor = isDark
            ? ColorConstants.whiteColor.withValues(alpha: 0.62)
            : ColorConstants.hintColor;
        final mediaQuery = MediaQuery.of(dialogContext);

        // 计算弹窗理论可用宽度，扣掉左右 insetPadding 后再用于内部布局。
        final availableWidth = mediaQuery.size.width - 48;

        // 计算弹窗理论可用高度，扣掉上下边缘安全留白，避免小屏设备溢出。
        final availableHeight = mediaQuery.size.height - 96;

        // 二维码尺寸在“宽度受限”和“高度受限”两种场景下都要能自适应，
        // 所以这里取更紧张的一边再做 clamp，避免二维码过大挤压按钮和文案。
        final qrSize = availableWidth < availableHeight
            ? (availableWidth - 40).clamp(
                160.0,
                TopUpRecordStyle.qrDialogQrSize,
              )
            : (availableHeight - 220).clamp(
                140.0,
                TopUpRecordStyle.qrDialogQrSize,
              );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: availableWidth,
              maxHeight: availableHeight,
            ),
            child: Container(
              padding: TopUpRecordStyle.qrDialogPadding,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171A27) : Colors.white,
                borderRadius: BorderRadius.circular(
                  TopUpRecordStyle.qrDialogRadius,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      easy.tr('top_up_record_page.pay_qr_code'),
                      style: TextStyle(
                        color: titleColor,
                        fontSize: TopUpRecordStyle.qrDialogTitleSize,
                        fontWeight: TopUpRecordStyle.qrDialogTitleWeight,
                      ),
                    ),
                    const SizedBox(
                      height: TopUpRecordStyle.qrDialogTitleBottomSpacing,
                    ),
                    Container(
                      // 二维码外层强制使用白底，保证无论深浅色主题都具备足够识别度。
                      padding: const EdgeInsets.all(
                        TopUpRecordStyle.qrDialogQrWrapPadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          TopUpRecordStyle.qrDialogQrWrapRadius,
                        ),
                      ),
                      child: QrImageView(
                        data: value,
                        size: qrSize,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      height: TopUpRecordStyle.qrDialogAddressTopSpacing,
                    ),
                    Text(
                      // 这里额外展示二维码原文，方便用户在扫码失败时手动复制核对。
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: hintColor,
                        fontSize: TopUpRecordStyle.qrDialogAddressSize,
                        height: TopUpRecordStyle.qrDialogAddressHeight,
                        fontWeight: TopUpRecordStyle.qrDialogAddressWeight,
                      ),
                    ),
                    const SizedBox(
                      height: TopUpRecordStyle.qrDialogButtonTopSpacing,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // 底部唯一按钮只负责关闭弹窗，不承担复制等额外交互，保持操作单一。
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: ColorConstants.themeColor,
                          foregroundColor: ColorConstants.lightTextColor,
                          minimumSize: const Size.fromHeight(
                            TopUpRecordStyle.qrDialogButtonHeight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgIcon(
                              name: 'qr_code',
                              width: 16,
                              height: 16,
                              color: ColorConstants.lightTextColor,
                            ),
                            const SizedBox(width: 8),
                            Text(easy.tr('constant.ok')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 只要依赖了 dark.value，当前页面就会在主题切换时自动重建。
      final isDark = deviceInfo.dark.value;
      final backgroundColor = isDark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.lightBackgroundColor;

      // 读取系统安全区，避免横屏或异形屏时内容和悬浮按钮被遮挡。
      final mediaQuery = MediaQuery.of(context);
      final safePadding = mediaQuery.padding;
      final contentTopPadding = resolvePageHeaderContentTopPadding(
        mediaQuery: mediaQuery,
        headerBottomFadeSpacing: TopUpRecordStyle.headerBottomFadeSpacing,
      );

      return Scaffold(
        body: AnimatedContainer(
          // 整个页面使用 AnimatedContainer 包裹，
          // 让主题切换时背景色和部分外观变化更柔和，而不是生硬闪变。
          duration: const Duration(milliseconds: ThemeConstants.animationTime),
          curve: Curves.easeInOut,
          color: backgroundColor,
          child: Stack(
            children: [
              // 第一层：页面基础渐变背景。
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
              // 第二层：右上装饰光斑，主要用于强化页面层次感。
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
              // 第三层：左上辅助光斑，让顶部区域不要过于单薄。
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
              // 第四层：真正的页面滚动内容。
              // 顶部不再额外套 SafeArea，否则列表内容会被限制在安全区内，
              // 用户上滑时看不到内容继续进入状态栏区域的层叠效果。
              RefreshIndicator(
                onRefresh: _handlePullRefresh,
                child: ListView(
                  // 滚动控制器由逻辑层持有。
                  // 这样滚动监听和“返回顶部”动画都能集中在 logic.dart 内处理。
                  controller: logic.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    TopUpRecordStyle.pageHorizontalPadding + safePadding.left,
                    contentTopPadding,
                    TopUpRecordStyle.pageHorizontalPadding + safePadding.right,
                    TopUpRecordStyle.pageBottomPadding + safePadding.bottom,
                  ),
                  children: [
                    // 顶部 hero 卡片负责建立页面第一视觉焦点。
                    TopUpRecordHeroCard(isDark: isDark),
                    const SizedBox(height: TopUpRecordStyle.heroBottomSpacing),

                    // 列表为空且不在首次 loading 时，展示空状态。
                    // 这样可以避免“空态和 loading 遮罩同时出现”的视觉冲突。
                    if (logic.records.isEmpty && !logic.loading)
                      TopUpRecordEmptyState(isDark: isDark),

                    // 只有真正有记录时，才渲染记录卡片和底部状态区域。
                    if (logic.records.isNotEmpty) ...[
                      ...logic.records.map(
                        (item) => TopUpRecordCard(
                          isDark: isDark,
                          item: item,
                          amountText: logic.displayAmount(item.amountPayable),
                          payableText: logic.displayAmount(item.payPayable),
                          serialNumberText: logic.displayText(
                            item.serialNumber,
                          ),
                          createTimeText: logic.displayUtcTime(item.createTime),
                          payTimeText: logic.displayUtcTime(item.payTime),
                          payQrCodeText: logic.displayText(item.payQrCode),
                          showPayQrCode: logic.shouldShowPayQrCode(item),
                          showCountdown: logic.shouldShowCountdown(item),
                          countdownText: logic.countdownText(item),
                          statusText: logic.statusText(item),
                          statusColor: logic.statusColor(isDark, item),
                          onCopySerialNumber: () {
                            _handleCopySerialNumber(item.serialNumber);
                          },
                          onCopyPayQrCode: () {
                            _handleCopyPayQrCode(item.payQrCode);
                          },
                          onShowQrCode: () {
                            _showQrDialog(
                              isDark: isDark,
                              value: item.payQrCode,
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: TopUpRecordStyle.listBottomSpacing,
                      ),
                      TopUpRecordBottomAction(
                        isDark: isDark,
                        loadingMore: logic.loadingMore,
                        hasMore: logic.hasMore,
                      ),
                    ],
                  ],
                ),
              ),
              // 顶部固定标题栏。
              // 通过额外渐变层和正文内容做视觉过渡，避免像硬切一刀。
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
                      title: easy.tr('top_up_record_page.title'),
                    ),
                  ),
                ),
              ),

              // 首次进入页面或手动要求遮罩式加载时，展示全局 loading。
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

              // 返回顶部按钮固定在右下角。
              // 按钮的显隐和点击行为都来自逻辑层，页面这里只负责摆放。
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
