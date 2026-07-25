import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/language_util/index.dart';
import 'logic.dart';
import 'style.dart';

/// 用户中心统计摘要区。
class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  /// TODO 设备主题仓库。
  final deviceInfo = Get.find<DeviceInfo>();

  /// TODO 统计逻辑层。
  final logic = Logic();

  /// 评论颜色（清透蓝）。
  static const Color _comment_color = Color(0xFF8DB7FF);

  /// 点赞颜色（暖珊瑚）。
  static const Color _like_color = Color(0xFFFF9E80);

  /// 收藏颜色（主题金）。
  static const Color _favorite_color = Color(0xFFFFD45A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      /// TODO 当前是否深色模式。
      final isDark = deviceInfo.theme.value == ThemeMode.dark;

      /// TODO 数值主文案颜色。
      final titleColor = isDark ? Colors.white : ColorConstants.lightTextColor;

      /// TODO 标签副文案颜色。
      final subtitleColor = isDark
          ? Colors.white.withValues(alpha: 0.58)
          : ColorConstants.lightTextColor.withValues(alpha: 0.56);

      /// 根据当前语种判断是否为 CJK，用于调整卡片高度和标签字号。
      final bool is_cjk = LanguageUtil.is_cjk_language(
        context.locale.languageCode,
      );

      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => logic.go_to_message(2),
                child: _StatCard(
                  value: '${logic.comment_total}',
                  unread: logic.comment_unread,
                  label: easy.tr('message.stats.comment'),
                  accentColor: _comment_color,
                  startColor: isDark
                      ? const Color(0xFF18222F)
                      : const Color(0xFFF2F7FF),
                  endColor: isDark
                      ? const Color(0xFF101721)
                      : const Color(0xFFFBFDFF),
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  is_cjk: is_cjk,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => logic.go_to_message(3),
                child: _StatCard(
                  value: '${logic.like_total}',
                  unread: logic.like_unread,
                  label: easy.tr('message.stats.like'),
                  accentColor: _like_color,
                  startColor: isDark
                      ? const Color(0xFF2B1B17)
                      : const Color(0xFFFFEFEA),
                  endColor: isDark
                      ? const Color(0xFF1A120F)
                      : const Color(0xFFFFFBF9),
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  is_cjk: is_cjk,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => logic.go_to_message(5),
                child: _StatCard(
                  value: '${logic.favorite_total}',
                  unread: logic.favorite_unread,
                  label: easy.tr('message.stats.favorite'),
                  accentColor: _favorite_color,
                  startColor: isDark
                      ? const Color(0xFF262113)
                      : const Color(0xFFFFF4D3),
                  endColor: isDark
                      ? const Color(0xFF17140E)
                      : const Color(0xFFFFFCF0),
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
                  is_cjk: is_cjk,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final int unread;
  final String label;
  final Color accentColor;
  final Color startColor;
  final Color endColor;
  final Color titleColor;
  final Color subtitleColor;
  final bool is_cjk;

  const _StatCard({
    required this.value,
    required this.unread,
    required this.label,
    required this.accentColor,
    required this.startColor,
    required this.endColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.is_cjk,
  });

  @override
  Widget build(BuildContext context) {
    /// 根据语种选择字号：CJK 使用 12px，非 CJK 使用 11px 避免长标签溢出。
    final double label_font_size = is_cjk
        ? Style.cardLabelFontSizeCjk
        : Style.cardLabelFontSizeAlphabetic;

    /// 根据语种选择卡片高度：非 CJK 语系英文标签更长，增加卡片高度避免拥挤。
    final double card_height = is_cjk
        ? Style.cardHeightCjk
        : Style.cardHeightAlphabetic;

    return Container(
      height: card_height,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Style.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  color: titleColor,
                ),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${unread.clamp(0, 99)}${easy.tr('message.stats.unread_suffix')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: label_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
