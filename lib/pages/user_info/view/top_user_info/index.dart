import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/auth_form_widgets/auth_brand_section.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/device_info.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/string/to_string.dart';
import 'style.dart';
import 'logic.dart';

/// 用户中心顶部资料区。
///
/// 负责展示昵称、余额和余额刷新入口，
/// 是个人中心页最核心的一块头部信息。
class TopUserInfo extends StatefulWidget {
  /// 余额区域右下角可选扩展组件。
  final Widget? balanceTrailing;

  const TopUserInfo({super.key, this.balanceTrailing});

  @override
  State<TopUserInfo> createState() => _TopUserInfoState();
}

class _TopUserInfoState extends State<TopUserInfo> {
  /// 设备主题仓库。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 顶部资料区逻辑层。
  late Logic logic;

  /// 刷新余额按钮 loading 状态。
  bool loading = false;

  /// 用户信息仓库。
  final userInformation = Get.find<UserInformation>();

  @override
  void initState() {
    super.initState();

    /// 初始化逻辑层。
    logic = Logic(context);
  }

  Future<void> _refreshBalance() async {
    /// 正在刷新时不重复请求。
    if (loading) return;

    setState(() => loading = true);
    try {
      /// 主动更新一次用户资料，刷新余额显示。
      await logic.updateUserInformation();
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  InlineSpan _buildBalanceTextSpan(double balance) {
    /// 先把余额转成金额文本。
    final balanceText = formatMoney(balance);

    /// 找到小数点位置，方便把整数和小数部分分开渲染。
    final dotIndex = balanceText.indexOf('.');
    final integerPart = dotIndex >= 0
        ? balanceText.substring(0, dotIndex)
        : balanceText;
    final decimalPart = dotIndex >= 0 ? balanceText.substring(dotIndex) : '';

    return TextSpan(
      children: [
        TextSpan(
          /// 整数部分使用更大的字号，强调主视觉数字。
          text: integerPart,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
            height: 0.95,
            letterSpacing: -0.8,
          ),
        ),
        if (decimalPart.isNotEmpty)
          TextSpan(
            /// 小数部分用更小字号，保持层级区分。
            text: decimalPart,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              height: 0.95,
              letterSpacing: -0.4,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// 当前主题模式。
      final isDark = deviceInfo.dark.value;

      /// 当前用户名。
      final userName = userInformation.userInfo.value?.name ?? "";
      return Column(
        children: [
          // 展示用户名。
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // 确保子元素垂直居中。
            children: [
              GestureDetector(
                onTap: () {
                  /// 点击昵称时进入资料编辑。
                  logic.updateUserInfo();
                },
                child: ConstrainedBox(
                  /// 限制昵称最大宽度，避免超长文本把头部撑坏。
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Tooltip(
                    /// 鼠标悬停或长按时展示完整昵称。
                    message: userName,
                    waitDuration: const Duration(milliseconds: 200),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        /// 昵称变化时做一次淡入淡出。
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        userName,
                        key: ValueKey(userName),
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorConstants.nightHighlightColor,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  /// 右侧编辑图标也复用同一个资料编辑入口。
                  logic.updateUserInfo();
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : ColorConstants.themeColor.withValues(alpha: 0.35),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.drive_file_rename_outline_rounded,
                    size: 12,
                    color: ColorConstants.lightTextColor.withValues(
                      alpha: 0.82,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // TODO: 余额区域已隐藏，等待替换为新内容
          // const SizedBox(height: Style.nicknameBottomSpacing),
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.only(left: Style.balanceLeftPadding),
          //   alignment: Alignment.centerLeft,
          //   child: Row(
          //     crossAxisAlignment: CrossAxisAlignment.end,
          //     children: [
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Row(
          //               mainAxisSize: MainAxisSize.min,
          //               children: [
          //                 Text(
          //                   /// "金币" 标题。
          //                   easy.tr('UserInfo.balance'),
          //                   style: TextStyle(
          //                     fontSize: 12,
          //                     fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          //                     letterSpacing: 1.2,
          //                     color: ColorConstants.nightHighlightColor
          //                         .withValues(alpha: 0.64),
          //                   ),
          //                 ),
          //                 const SizedBox(width: 4),
          //                 GestureDetector(
          //                   onTap: loading ? null : _refreshBalance,
          //                   child: loading
          //                       ? SizedBox(
          //                           /// 刷新余额时显示小尺寸 loading。
          //                           width: 14,
          //                           height: 14,
          //                           child: CircularProgressIndicator(
          //                             strokeWidth: 2,
          //                             valueColor: AlwaysStoppedAnimation<Color>(
          //                               ColorConstants.nightHighlightColor,
          //                             ),
          //                           ),
          //                         )
          //                       : SvgIcon(
          //                           /// 非 loading 时显示刷新图标。
          //                           name: "refresh",
          //                           width: 12,
          //                           height: 12,
          //                           color: ColorConstants.nightHighlightColor
          //                               .withValues(alpha: 0.78),
          //                         ),
          //                 ),
          //               ],
          //             ),
          //             const SizedBox(height: 8),
          //             GestureDetector(
          //               onTap: loading ? null : _refreshBalance,
          //               child: RichText(
          //                 text: TextSpan(
          //                   style: TextStyle(
          //                     color: ColorConstants.nightHighlightColor,
          //                   ),
          //                   children: [
          //                     /// 把余额按整数和小数拆分成富文本显示。
          //                     _buildBalanceTextSpan(
          //                       userInformation.userInfo.value?.balance ?? 0.0,
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       if (widget.balanceTrailing != null)
          //         Padding(
          //           /// 可选的右侧扩展区域，例如充值按钮。
          //           padding: const EdgeInsets.only(right: 10, bottom: 6),
          //           child: widget.balanceTrailing!,
          //         ),
          //     ],
          //   ),
          // ),
          // 口号：与登录页保持一致，靠左对齐
          const SizedBox(height: Style.nicknameBottomSpacing),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: Style.balanceLeftPadding),
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AuthSlogan(alignLeft: true),
                ),
                if (widget.balanceTrailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 6),
                    child: widget.balanceTrailing!,
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
