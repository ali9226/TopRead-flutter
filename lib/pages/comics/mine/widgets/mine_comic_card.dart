// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/mine/style.dart';
import 'package:app/pages/comics/mine/widgets/status_badge.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 「我的漫画」卡片：封面 + 状态角标 + 标题 + 章节数。
///
/// 视觉语言与 [ComicCard] 一致，但操作目标是编辑器而非读者详情页，
/// 并在封面左上角叠加发布状态角标。
class MineComicCard extends StatelessWidget {
  /// 漫画数据。
  final ComicItem comic;

  /// 点击进入编辑器。
  final VoidCallback on_tap;

  const MineComicCard({super.key, required this.comic, required this.on_tap});

  @override
  Widget build(BuildContext context) {
    /// 当前是否夜间主题，决定卡片底色。
    final bool is_dark = ComicsStyle.is_dark(context);

    /// 卡片底色与详情卡片同源。
    final Color card_bg = is_dark ? ColorConstants.pages_home_widgets_tab_contents_recommend_tab_index_tone : ColorConstants.whiteColor;

    /// 标题颜色。
    final Color title_color = is_dark ? ColorConstants.whiteColor : ColorConstants.components_recommend_book_card_index_tone;

    /// 次要信息颜色。
    final Color meta_color = is_dark
        ? ColorConstants.components_recommend_book_card_index_tone_9effffff
        : ColorConstants.components_recommend_book_card_index_tone_ff8b93a2;

    return Semantics(
      button: true,
      label: '${comic.title} · ${_status_label()}',
      child: Material(
        color: card_bg,
        borderRadius: BorderRadius.circular(ComicCardStyle.card_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: on_tap,
          splashFactory: InkRipple.splashFactory,
          splashColor: ColorConstants.themeColor.withValues(
            alpha: ComicCardStyle.ripple_opacity,
          ),
          highlightColor: ColorConstants.themeColor.withValues(
            alpha: ComicCardStyle.highlight_opacity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 封面 + 状态角标。
              _build_cover(context, is_dark),

              /// 文案区：标题 + 章节/状态元信息。
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ComicCardStyle.content_padding_h,
                  ComicCardStyle.content_padding_top,
                  ComicCardStyle.content_padding_h,
                  ComicCardStyle.content_padding_bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      comic.title.trim().isEmpty
                          ? tr('comics.no_title')
                          : comic.title.trim(),
                      maxLines: ComicCardStyle.title_max_lines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: title_color,
                        fontSize: ComicsStyle.is_cjk(context)
                            ? ComicCardStyle.title_font_size_cjk
                            : ComicCardStyle.title_font_size_alphabetic,
                        height: ComicsStyle.is_cjk(context)
                            ? ComicCardStyle.title_height_cjk
                            : ComicCardStyle.title_height_alphabetic,
                        letterSpacing: ComicsStyle.is_cjk(context)
                            ? null
                            : ComicCardStyle.title_letter_spacing_alphabetic,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: LayoutConfig.space_6),
                    Text(
                      tr(
                        'comics.chapter_count',
                        namedArgs: <String, String>{
                          'count': '${comic.chapter_count}',
                        },
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: meta_color,
                        fontSize: ComicsStyle.is_cjk(context)
                            ? ComicCardStyle.description_font_size_cjk
                            : ComicCardStyle.description_font_size_alphabetic,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      ),
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

  /// 封面区域：竖版封面 + 左上角状态角标 + 底部渐变信息条。
  Widget _build_cover(BuildContext context, bool is_dark) {
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(ComicCardStyle.card_radius),
            topRight: Radius.circular(ComicCardStyle.card_radius),
          ),
          child: AspectRatio(
            aspectRatio: ComicsStyle.cover_ratio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ComicImage(url: comic.cover_url, semantic_label: comic.title),

                /// 底部渐变让角标与标题区自然衔接。
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: ComicCardStyle.cover_meta_padding_top,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          ColorConstants.meta_color_00222222,
                          ColorConstants.shadowColor.withValues(alpha: ComicCardStyle.cover_gradient_bottom_opacity),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        /// 状态角标：编辑态卡片的主识别信息。
        Positioned(
          top: ComicsMineStyle.status_margin.top,
          left: ComicsMineStyle.status_margin.left,
          child: ComicsStatusBadge(status: comic.status, is_dark: is_dark),
        ),
      ],
    );
  }

  /// 状态文案，用于语义标签。
  String _status_label() {
    switch (comic.status) {
      case 'pending':
        return tr('comics.status_pending');
      case 'published':
        return tr('comics.status_published');
      case 'rejected':
        return tr('comics.status_rejected');
      case 'hidden':
        return tr('comics.status_hidden');
      default:
        return tr('comics.status_draft');
    }
  }
}
