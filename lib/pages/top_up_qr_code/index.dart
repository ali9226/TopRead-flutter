import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/language_selection/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/theme.dart';
import 'package:app/models/recharge_add_result.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/layout/page_header_spacing.dart';
import 'package:app/util/number_util.dart';
import 'package:app/util/router/router_util.dart';
import 'logic.dart';
import 'style.dart';
import 'widgets/top_up_qr_content_card.dart';
import 'widgets/top_up_qr_hero_card.dart';
import 'widgets/top_up_qr_notice_card.dart';

/// 充值二维码页面。
///
/// 页面只通过路由拿到一个订单 id，
/// 然后再主动请求订单详情接口，
/// 用于渲染充值金额、二维码地址和注意事项。
class TopUpQrCode extends StatefulWidget {
  /// 充值订单 id。
  final int id;

  const TopUpQrCode({super.key, required this.id});

  @override
  State<TopUpQrCode> createState() => _TopUpQrCodeState();
}

class _TopUpQrCodeState extends State<TopUpQrCode> {
  /// 设备主题仓库。
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

  /// 充值二维码页逻辑层。
  late final Logic logic;

  /// 当前充值订单详情。
  RechargeAddResult? detail;

  /// 页面是否处于请求中。
  bool loading = false;

  @override
  void initState() {
    super.initState();

    /// 初始化逻辑层。
    logic = Logic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// 首帧后再请求详情，避免影响页面初始渲染。
      initPage();
    });
  }

  Future<void> initPage() async {
    /// 路由没有带合法订单 id 时，直接视为当前页不可用。
    if (widget.id <= 0) {
      showBottomTip(easy.tr('top_up_qr_code_page.unavailable'));
      routerUtil(path: '/user_info', type: 'replace');
      return;
    }

    /// 防止重复请求。
    if (loading) return;

    setState(() {
      /// 打开加载状态。
      loading = true;
    });

    try {
      /// 查询订单详情。
      final RechargeAddResult? results = await logic.getRechargeInfo(
        id: widget.id,
      );
      if (!mounted) return;

      /// 没有详情或者没有二维码地址时，当前页也视为不可用。
      if (results == null || results.payQrCode.isEmpty) {
        showBottomTip(easy.tr('top_up_qr_code_page.unavailable'));
        routerUtil(path: '/user_info', type: 'replace');
        return;
      }

      setState(() {
        /// 保存充值详情，驱动页面展示真实内容。
        detail = results;
      });
    } finally {
      if (mounted) {
        setState(() {
          /// 请求结束后关闭 loading。
          loading = false;
        });
      }
    }
  }

  String displayAmount(double value) {
    /// 先使用项目统一的数字格式化规则处理小数位。
    final String formatted = formatNumberValue(value);

    /// 再转成数字补千分位，保证金额展示更稳定。
    final double parsed = double.tryParse(formatted) ?? value;
    return '\$${thousandsSeparator(parsed)}';
  }

  Future<void> copyAddress() async {
    /// 从详情里取当前支付地址。
    final String value = detail?.payQrCode ?? '';

    /// 空地址不允许复制。
    if (value.isEmpty) return;

    /// 执行复制。
    final bool status = await copyToClipboard(value);

    /// 页面已销毁或复制失败时不提示。
    if (!mounted || !status) return;

    /// 复制成功提示。
    showBottomTip(easy.tr('top_up_qr_code_page.copy_success'));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// 当前是否深色模式。
      final bool isDark = deviceInfo.dark.value;

      /// 页面底色。
      final Color backgroundColor = isDark
          ? ColorConstants.nightBackgroundColor
          : ColorConstants.lightBackgroundColor;

      /// 二维码卡片内部的底色。
      final Color qrBackgroundColor = isDark
          ? const Color(0xFF121521)
          : Colors.white;

      /// 页面辅助文案颜色。
      final Color hintColor = isDark
          ? ColorConstants.whiteColor.withValues(alpha: 0.62)
          : ColorConstants.hintColor;

      /// 媒体信息与安全区。
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      final EdgeInsets safePadding = mediaQuery.padding;

      /// 主内容顶部起始位置。
      final double contentTopPadding = resolvePageHeaderContentTopPadding(
        mediaQuery: mediaQuery,
      );

      return Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: ThemeConstants.animationTime),
          curve: Curves.easeInOut,
          color: backgroundColor,
          child: Stack(
            children: <Widget>[
              // 页面底层背景渐变。
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? const <Color>[
                              Color(0xFF181B29),
                              Color(0xFF11131D),
                              Color(0xFF0C0D14),
                            ]
                          : const <Color>[
                              Color(0xFFFFF3C1),
                              Color(0xFFF7F7F2),
                              Color(0xFFFFFFFF),
                            ],
                    ),
                  ),
                ),
              ),
              // 主内容滚动层。
              // 依次展示金额摘要、二维码主体和注意事项卡片。
              SafeArea(
                top: false,
                bottom: false,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(0, contentTopPadding, 0, 0),
                  children: <Widget>[
                    Padding(
                      padding:
                          EdgeInsets.symmetric(
                            horizontal:
                                Style.pageHorizontalPadding + safePadding.left,
                          ).copyWith(
                            right:
                                Style.pageHorizontalPadding + safePadding.right,
                          ),
                      child: TopUpQrHeroCard(
                        isDark: isDark,
                        detail: detail,

                        /// 详情还没回来时先显示占位。
                        amountText: detail == null
                            ? '--'
                            : displayAmount(detail!.payPayable),
                        onTapRecords: () {
                          routerUtil(path: '/top_up_record');
                        },
                      ),
                    ),
                    const SizedBox(height: Style.sectionSpacing),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(
                            horizontal:
                                Style.pageHorizontalPadding + safePadding.left,
                          ).copyWith(
                            right:
                                Style.pageHorizontalPadding + safePadding.right,
                          ),
                      child: TopUpQrContentCard(
                        isDark: isDark,
                        detail: detail,
                        hintColor: hintColor,
                        qrBackgroundColor: qrBackgroundColor,

                        /// 点击复制地址按钮时执行复制逻辑。
                        onCopyAddress: copyAddress,
                        onTapDone: () {
                          /// 用户确认完成后回到个人中心。
                          routerUtil(path: '/user_info', type: 'replace');
                        },
                      ),
                    ),
                    const SizedBox(height: Style.bottomNoticeTopSpacing),
                    TopUpQrNoticeCard(
                      isDark: isDark,
                      hintColor: hintColor,
                      detail: detail,
                      isBottomDocked: true,
                      safeBottomPadding: 0,
                    ),
                  ],
                ),
              ),
              // 顶部固定标题栏。
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          backgroundColor.withValues(alpha: 0.98),
                          backgroundColor.withValues(alpha: 0.82),
                          backgroundColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: LanguageSelection(
                      darkBackground: isDark,
                      title: easy.tr('top_up_qr_code_page.title'),
                    ),
                  ),
                ),
              ),
              // 请求中的轻量遮罩。
              if (loading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.12),
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
