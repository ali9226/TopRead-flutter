import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:app/components/app_wrapper/utils/get_app_title.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/components/share_sheet/style.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 可导出为图片的小说分享卡片。
///
/// 组件只包含最终要写入相册的内容，不依赖弹窗的标题、色板或操作区。
/// 整体结构参考内容类 App 的摘录分享卡：上半部分突出摘录，底部集中展示
/// 书籍信息和二维码，避免旧方案在高饱和背景上堆叠过多信息。
class SharePosterCard extends StatelessWidget {
  /// 小说 ID。
  final int novel_id;

  /// 小说标题。
  final String novel_title;

  /// 小说作者名称。
  final String novel_author;

  /// 小说封面地址。
  final String novel_cover_url;

  /// 分享摘录内容。
  final String novel_intro;

  /// 分享者头像地址。
  final String user_avatar_url;

  /// 分享者昵称。
  final String user_nickname;

  /// 分享日期。
  final String date_text;

  /// 无头像时使用的本地 SVG 头像序号。
  final int fallback_avatar_index;

  /// 海报外框渐变色。
  final List<Color> canvas_colors;

  /// 当前配色的强调色。
  final Color accent_color;

  /// 当前配色的书籍信息区底色。
  final Color footer_color;

  /// 是否使用专为墨黑背景设计的高对比度文字配色。
  final bool use_dark_palette;

  const SharePosterCard({
    super.key,
    required this.novel_id,
    required this.novel_title,
    required this.novel_author,
    required this.novel_cover_url,
    required this.novel_intro,
    required this.user_avatar_url,
    required this.user_nickname,
    required this.date_text,
    required this.fallback_avatar_index,
    required this.canvas_colors,
    required this.accent_color,
    required this.footer_color,
    this.use_dark_palette = false,
  });

  /// 当前海报的纸张颜色。
  Color get _paper_color => use_dark_palette
      ? ShareSheetStyle.poster_paper_color_dark
      : ShareSheetStyle.poster_paper_color;

  /// 当前海报的主文字颜色。
  Color get _primary_text_color => use_dark_palette
      ? ShareSheetStyle.poster_primary_text_color_dark
      : ShareSheetStyle.poster_primary_text_color;

  /// 当前海报的次要文字颜色。
  Color get _secondary_text_color => use_dark_palette
      ? ShareSheetStyle.poster_secondary_text_color_dark
      : ShareSheetStyle.poster_secondary_text_color;

  /// Logo 在墨黑卡片上使用浅色承载面，保留原始 SVG 的黑黄细节。
  Color get _brand_surface_color => use_dark_palette
      ? ShareSheetStyle.poster_brand_surface_color_dark
      : ShareSheetStyle.poster_paper_color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ShareSheetStyle.poster_design_width,
      height: ShareSheetStyle.poster_design_height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: canvas_colors,
          ),
          borderRadius: BorderRadius.circular(
            ShareSheetStyle.preview_card_radius,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ShareSheetStyle.poster_frame_width),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ShareSheetStyle.poster_content_radius,
            ),
            child: ColoredBox(
              color: _paper_color,
              child: Column(
                children: <Widget>[
                  Expanded(child: _buildExcerptSection(context)),
                  _buildBookSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建以正文为视觉中心的摘录区域。
  Widget _buildExcerptSection(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      easy.EasyLocalization.of(context)?.locale.languageCode ?? 'en',
    );
    final String excerpt_text = novel_intro.trim().isNotEmpty
        ? novel_intro.trim()
        : easy.tr(
            'share_sheet.share_text',
            context: context,
            namedArgs: <String, String>{
              'app': getAppTitle(context),
              'title': novel_title,
            },
          );

    return Padding(
      padding: ShareSheetStyle.poster_excerpt_padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: ShareSheetStyle.poster_quote_mark_height,
            child: Text(
              '“',
              style: TextStyle(
                color: accent_color.withValues(alpha: 0.20),
                fontSize: ShareSheetStyle.poster_quote_mark_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                height: 0.9,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                excerpt_text,
                maxLines: ShareSheetStyle.poster_excerpt_max_lines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primary_text_color,
                  fontSize: is_cjk
                      ? ShareSheetStyle.poster_excerpt_font_size_cjk
                      : ShareSheetStyle.poster_excerpt_font_size_alphabetic,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  height: is_cjk ? 1.58 : 1.42,
                  letterSpacing: is_cjk ? 0.2 : 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: ShareSheetStyle.poster_excerpt_user_spacing),
          _buildUserSection(context),
        ],
      ),
    );
  }

  /// 构建分享者信息与品牌标识。
  Widget _buildUserSection(BuildContext context) {
    final String nickname = user_nickname.trim().isNotEmpty
        ? user_nickname.trim()
        : easy.tr('share_sheet.default_reader', context: context);

    return Row(
      children: <Widget>[
        _buildAvatar(),
        const SizedBox(width: ShareSheetStyle.poster_avatar_text_spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                easy.tr(
                  'share_sheet.excerpt_by',
                  context: context,
                  namedArgs: <String, String>{'name': nickname},
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primary_text_color,
                  fontSize: ShareSheetStyle.poster_nickname_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date_text,
                style: TextStyle(
                  color: _secondary_text_color,
                  fontSize: ShareSheetStyle.poster_date_font_size,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildBrandMark(),
      ],
    );
  }

  /// 构建用户头像，网络头像不可用时回退到项目内置头像。
  Widget _buildAvatar() {
    final String avatar_index = fallback_avatar_index
        .clamp(0, 9)
        .toString()
        .padLeft(2, '0');

    return Container(
      width: ShareSheetStyle.poster_avatar_size,
      height: ShareSheetStyle.poster_avatar_size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: accent_color.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: user_avatar_url.trim().isNotEmpty
            ? NetworkCoverImage(
                image_url: user_avatar_url,
                width: ShareSheetStyle.poster_avatar_size,
                height: ShareSheetStyle.poster_avatar_size,
                border_radius: ShareSheetStyle.poster_avatar_size / 2,
                fit: BoxFit.cover,
                is_dark: false,
              )
            : SvgPicture.asset(
                'assets/svg/avatar_$avatar_index.svg',
                width: ShareSheetStyle.poster_avatar_size,
                height: ShareSheetStyle.poster_avatar_size,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  /// 构建右侧的 App 品牌标识。
  Widget _buildBrandMark() {
    return Container(
      width: ShareSheetStyle.poster_brand_mark_size,
      height: ShareSheetStyle.poster_brand_mark_size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _brand_surface_color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent_color.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SvgPicture.asset(
          'assets/svg/logo.svg',
          fit: BoxFit.cover,
          placeholderBuilder: (_) =>
              Icon(Icons.auto_stories_rounded, size: 18, color: accent_color),
        ),
      ),
    );
  }

  /// 构建封面、书名、作者、共读提示与二维码区域。
  Widget _buildBookSection(BuildContext context) {
    final String app_title = getAppTitle(context);
    final String secondary_text = novel_author.trim().isNotEmpty
        ? novel_author.trim()
        : app_title;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          height: ShareSheetStyle.poster_footer_height,
          color: footer_color,
          padding: ShareSheetStyle.poster_footer_padding,
          child: Row(
            children: <Widget>[
              _buildNovelCover(),
              const SizedBox(width: ShareSheetStyle.poster_cover_text_spacing),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      novel_title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primary_text_color,
                        fontSize: ShareSheetStyle.poster_title_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                        height: 1.24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      secondary_text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _secondary_text_color,
                        fontSize: ShareSheetStyle.poster_author_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      easy.tr(
                        'share_sheet.read_together',
                        context: context,
                        namedArgs: <String, String>{'app': app_title},
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent_color,
                        fontSize: ShareSheetStyle.poster_cta_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ShareSheetStyle.poster_qr_spacing),
              _buildQrCode(context, app_title),
            ],
          ),
        ),
        Positioned(
          top: -ShareSheetStyle.poster_notch_size / 2,
          left: ShareSheetStyle.poster_notch_left,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: ShareSheetStyle.poster_notch_size,
              height: ShareSheetStyle.poster_notch_size,
              color: _paper_color,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建书籍封面。短篇没有封面时使用本地排版兜底，避免导出海报时
  /// 把网络占位骨架一并保存到相册。
  Widget _buildNovelCover() {
    if (novel_cover_url.trim().isNotEmpty) {
      return NovelCover(
        image_url: novel_cover_url,
        description: novel_title,
        width: ShareSheetStyle.poster_cover_width,
        height: ShareSheetStyle.poster_cover_height,
        border_radius: ShareSheetStyle.poster_cover_radius,
        fit: BoxFit.cover,
        is_dark: false,
      );
    }

    return Container(
      width: ShareSheetStyle.poster_cover_width,
      height: ShareSheetStyle.poster_cover_height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent_color.withValues(alpha: 0.92),
            accent_color.withValues(alpha: 0.62),
          ],
        ),
        borderRadius: BorderRadius.circular(
          ShareSheetStyle.poster_cover_radius,
        ),
      ),
      child: Center(
        child: Text(
          novel_title,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: use_dark_palette ? const Color(0xFF171717) : Colors.white,
            fontSize: 9,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            height: 1.35,
          ),
        ),
      ),
    );
  }

  /// 构建二维码；当前编码内容是可读的书籍分享信息。
  Widget _buildQrCode(BuildContext context, String app_title) {
    final String qr_data = '$app_title | novel:$novel_id | $novel_title';

    return Container(
      width: ShareSheetStyle.poster_qr_size,
      height: ShareSheetStyle.poster_qr_size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: QrImageView(
        data: qr_data,
        padding: EdgeInsets.zero,
        gapless: true,
        semanticsLabel: easy.tr('share_sheet.qr_semantics', context: context),
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: ShareSheetStyle.poster_qr_color,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: ShareSheetStyle.poster_qr_color,
        ),
      ),
    );
  }
}
