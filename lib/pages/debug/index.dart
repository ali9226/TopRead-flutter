import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'logic.dart';
import 'style.dart';

/// 调试页面。
///
/// 提供开发调试工具，如获取 FCM Token 等。
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  /// 设备主题仓库。
  final deviceInfo = Get.find<DeviceInfo>();

  /// 页面逻辑层。
  late Logic logic;

  /// FCM Token 获取中状态。
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    logic = Logic();
  }

  /// 获取 FCM Token 并复制到剪贴板。
  Future<void> _getFcmToken() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final String? token = await logic.getFcmToken();

      if (token == null || token.isEmpty) {
        showBottomTip(easy.tr('debug.fcm_token_error'));
        return;
      }

      final bool ok = await copyToClipboard(token);
      if (ok) {
        showBottomTip(easy.tr('debug.fcm_token_success'));
      } else {
        showBottomTip(easy.tr('debug.fcm_token_error'));
      }
    } catch (e) {
      showBottomTip(easy.tr('debug.fcm_token_error'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = deviceInfo.dark.value;

      return Scaffold(
        backgroundColor: isDark
            ? ColorConstants.nightBackgroundColor
            : ColorConstants.whiteColor,
        appBar: AppBar(
          backgroundColor: isDark
              ? ColorConstants.nightBackgroundColor
              : ColorConstants.whiteColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : ColorConstants.lightTextColor,
              size: 20,
            ),
            onPressed: () => AppRouter.pop(),
          ),
          title: Text(
            easy.tr('debug.title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
              color: isDark ? Colors.white : ColorConstants.lightTextColor,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Style.pageHorizontalPadding,
            Style.pageTopPadding,
            Style.pageHorizontalPadding,
            MediaQuery.paddingOf(context).bottom + Style.pageBottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDebugItem(
                title: easy.tr('debug.fcm_token'),
                isDark: isDark,
                isLoading: _isLoading,
                onTap: _getFcmToken,
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建调试操作项。
  Widget _buildDebugItem({
    required String title,
    required bool isDark,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.nightHighlightColor
            : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(Style.itemRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE7ECF3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Style.itemRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Style.itemHorizontalPadding,
              vertical: Style.itemVerticalPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      color: isDark ? Colors.white : ColorConstants.lightTextColor,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorConstants.themeColor,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.38)
                        : ColorConstants.lightTextColor.withValues(alpha: 0.22),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}