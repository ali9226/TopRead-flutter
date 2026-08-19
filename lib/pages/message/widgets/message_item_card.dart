// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/message/style.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/config/font_config.dart';

/// 消息项卡片。
class MessageItemCard extends StatelessWidget {
  /// 左侧 SVG 图标名称。
  final String icon_name;

  /// 消息标题。
  final String title;

  /// 消息内容摘要。
  final String subtitle;

  /// 时间文案。
  final String time_text;

  /// 消息分类标签。
  final String badge_text;

  /// 当前消息类型主色。
  final Color accent_color;

  /// 是否未读（未读时显示红点）。
  final bool is_unread;

  /// 小说封面URL（可选，有封面时左侧显示封面，图标移到右侧）。
  final String? novel_cover;

  /// 消息类型（用于收藏类型特殊样式）。
  final int message_type;

  /// 未读数量（大于1时在左上角显示角标）。
  final int unread_count;

  const MessageItemCard({
    super.key,
    required this.icon_name,
    required this.title,
    required this.subtitle,
    required this.time_text,
    required this.badge_text,
    required this.accent_color,
    required this.message_type,
    this.is_unread = false,
    this.novel_cover,
    this.unread_count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    final bool is_dark = device_info.theme.value == ThemeMode.dark;
    final bool has_cover = novel_cover != null && novel_cover!.isNotEmpty;

    final Color card_color = is_dark ? const Color(0xFF171C28) : Colors.white;
    final Color title_color = is_dark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;
    final Color subtitle_color = is_dark
        ? ColorConstants.whiteColor.withValues(alpha: 0.64)
        : ColorConstants.hintColor;

    final Color icon_and_badge_bg_color = accent_color.withValues(alpha: 0.16);
    final Color icon_and_badge_text_color = accent_color;

    /// 收藏类型在日间模式下使用纯色背景 + lightTextColor 文字。
    final bool is_favorite = message_type == 5;
    final Color badge_bg_color = (!is_dark && is_favorite)
        ? accent_color
        : icon_and_badge_bg_color;
    final Color badge_text_color = (!is_dark && is_favorite)
        ? ColorConstants.lightTextColor
        : icon_and_badge_text_color;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(MessageStyle.card_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(MessageStyle.card_radius),
        splashColor: ColorConstants.themeColor.withValues(alpha: 0.16),
        highlightColor: ColorConstants.themeColor.withValues(alpha: 0.08),
        child: Ink(
          padding: MessageStyle.card_padding,
          decoration: BoxDecoration(
            color: card_color,
            borderRadius: BorderRadius.circular(MessageStyle.card_radius),
            border: Border.all(
              color: ColorConstants.themeColor.withValues(
                alpha: is_dark ? 0.18 : 0.10,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              /// 左侧：有封面显示封面，否则显示图标
              if (has_cover)
                ClipRRect(
                  borderRadius: BorderRadius.circular(MessageStyle.cover_radius),
                  child: CachedNetworkImage(
                    imageUrl: novel_cover!,
                    width: MessageStyle.cover_width,
                    height: MessageStyle.cover_height,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        _build_icon(icon_and_badge_bg_color, icon_and_badge_text_color),
                  ),
                )
              else
                _build_icon(icon_and_badge_bg_color, icon_and_badge_text_color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// 标题行：未读红点 + 标题 + 时间
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        if (is_unread && unread_count <= 1)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: ColorConstants.dangerColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: title_color,
                              fontSize: 15,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                            ),
                          ),
                        ),
                        Text(
                          time_text,
                          style: TextStyle(
                            color: subtitle_color,
                            fontSize: 11,
                            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    /// 内容行：副标题 + 标签
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return SizeTransition(
                                sizeFactor: animation,
                                axisAlignment: -1.0,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              subtitle,
                              key: ValueKey(subtitle),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitle_color,
                                fontSize: 12,
                                height: 1.55,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: MessageStyle.badge_padding,
                          decoration: BoxDecoration(
                            color: badge_bg_color,
                            borderRadius: BorderRadius.circular(
                              MessageStyle.badge_radius,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (has_cover) ...[
                                SvgPicture.asset(
                                  'assets/svg/$icon_name.svg',
                                  width: 12,
                                  height: 12,
                                  colorFilter: ColorFilter.mode(
                                    badge_text_color,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                badge_text,
                                style: TextStyle(
                                  color: badge_text_color,
                                  fontSize: 11,
                                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建左侧圆形图标。
  Widget _build_icon(Color bg_color, Color icon_color) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: MessageStyle.icon_wrap_size,
          height: MessageStyle.icon_wrap_size,
          decoration: BoxDecoration(
            color: bg_color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/svg/$icon_name.svg',
            width: MessageStyle.icon_size,
            height: MessageStyle.icon_size,
            colorFilter: ColorFilter.mode(
              icon_color,
              BlendMode.srcIn,
            ),
          ),
        ),
        if (unread_count > 1)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: ColorConstants.dangerColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              alignment: Alignment.center,
              child: Text(
                unread_count > 99 ? '99+' : '$unread_count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
