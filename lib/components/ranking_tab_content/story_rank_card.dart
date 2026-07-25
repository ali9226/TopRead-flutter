import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'package:app/components/network_cover_image/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/home/style.dart';
import 'package:app/config/font_config.dart';

/// 首页榜单小说条目卡片。
///
/// 每个条目固定为左侧封面、右侧序号与内容的结构，
/// 用于首页榜单 tab 内的双列布局展示。
class StoryRankCard extends StatelessWidget {
  /// 当前书籍在榜单中的序号。
  final int ranking_index;

  /// 书籍标题。
  final String title;

  /// 书籍人气值，单位为“万”。
  final String popularity_count;

  /// 书籍封面链接。
  final String cover_url;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 点击卡片时触发的回调。
  final VoidCallback? on_tap;

  const StoryRankCard({
    super.key,
    required this.ranking_index,
    required this.title,
    required this.popularity_count,
    required this.cover_url,
    required this.is_dark,
    this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 标题颜色。
    final Color title_color = is_dark ? Colors.white : Colors.black;

    /// 人气文字颜色。
    final Color popularity_color = is_dark
        ? Colors.white.withValues(alpha: 0.50)
        : const Color(0xFFB5B5B5);

    /// 序号颜色。
    final Color ranking_index_color = ranking_index <= 3
        ? ColorConstants.resolveMessageTypeAccentColor(ranking_index - 1)
        : (is_dark ? Colors.white : Colors.black);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: on_tap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NetworkCoverImage(
            image_url: cover_url,
            width: Style.ranking_cover_width,
            height: Style.ranking_cover_height,
            border_radius: Style.ranking_cover_radius,
            is_dark: is_dark,
            error_text: '$ranking_index',
          ),
          const SizedBox(width: Style.ranking_cover_to_content_gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    top: Style.ranking_index_top_spacing,
                  ),
                  child: Text(
                    '$ranking_index',
                    style: TextStyle(
                      color: ranking_index_color,
                      fontSize: Style.ranking_index_font_size,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      height: Style.ranking_title_height,
                    ),
                  ),
                ),
                const SizedBox(width: Style.ranking_index_to_content_gap),
                Expanded(
                  child: SizedBox(
                    height: Style.ranking_cover_height,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: Style.ranking_title_container_height,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: title_color,
                                fontSize: Style.ranking_title_font_size,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                height: Style.ranking_title_height,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Style.ranking_popularity_height,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              easy.tr(
                                'home.ranking_popularity',
                                namedArgs: <String, String>{
                                  'count': popularity_count,
                                },
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: popularity_color,
                                fontSize: Style.ranking_popularity_font_size,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
