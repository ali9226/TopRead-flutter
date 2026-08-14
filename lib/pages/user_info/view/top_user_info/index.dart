import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/auth_form_widgets/auth_brand_section.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:get/get.dart';
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

  /// 用户信息仓库。
  final userInformation = Get.find<UserInformation>();

  /// 项目配置仓库。
  final projectConfigStore = Get.find<ProjectConfigStore>();

  @override
  void initState() {
    super.initState();

    /// 初始化逻辑层。
    logic = Logic(context);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// 当前主题模式。
      final isDark = deviceInfo.dark.value;

      /// 当前用户名。
      final userName = userInformation.userInfo.value?.name ?? "";

      /// 当前是否已登录。
      final isLoggedIn = userInformation.isLoggedIn.value;

      /// 名言内容。
      final famousQuote = projectConfigStore.current.famous_quote;

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

          // 名言/口号区域：与福袋同行。
          const SizedBox(height: Style.nicknameBottomSpacing),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: Style.balanceLeftPadding),
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isLoggedIn && famousQuote.isNotEmpty)
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Text(
                      famousQuote,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorConstants.lightTextColor,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, 15),
                      child: AuthSlogan(
                        alignLeft: true,
                        color: ColorConstants.lightTextColor,
                      ),
                    ),
                  ),
                const Spacer(),
                if (widget.balanceTrailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
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
