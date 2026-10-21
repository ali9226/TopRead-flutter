// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/components/catalog_card/index.dart';
import 'package:app/components/content_category_tag/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/short_story_read/widgets/catalog/catalog_header.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TODO 详情页补充面板统一使用安全区、限高滚动与日夜主题表面色。
Future<void> _show_sheet(BuildContext context, String title, Widget body) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      builder: (context) => WindowContentLayout(
        expand_height: false,
        max_width: 600,
        child: Material(
          key: const ValueKey('comic_detail_sheet_surface'),
          color: CatalogCardStyle.sheet_background(
            ComicDetailStyle.is_dark(context),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CatalogCardStyle.sheet_radius),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(context).height *
                  CatalogCardStyle.sheet_height_ratio,
            ),
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CatalogHeader(
                    is_dark: ComicDetailStyle.is_dark(context),
                    title: title,
                    on_close: () => Navigator.pop(context),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(
                        CatalogCardStyle.list_padding,
                      ),
                      child: body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

/// TODO 复制带当前语种的真实作品链接；复制成功后提供可感知反馈。
Future<void> show_comic_share_sheet(BuildContext context, ComicDetail detail) {
  final language = detail.selected_language;
  final uri = Uri.parse(ComicDetailStyle.public_url).replace(
    path: '/comics/detail',
    queryParameters: {
      'id': '${detail.comic.id}',
      if (language != null) 'language': language.language,
    },
  );
  return _show_sheet(
    context,
    tr('comics.share_heading'),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language?.title ?? detail.comic.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: ComicDetailStyle.weight_medium,
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(
          uri.toString(),
          style: TextStyle(color: ComicDetailStyle.muted(context)),
        ),
        const SizedBox(height: 20),
        Builder(
          builder: (sheet_context) => FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ComicDetailStyle.accent(context),
              foregroundColor: const Color(0xFF242428),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: uri.toString()));
              if (!sheet_context.mounted) return;
              Navigator.pop(sheet_context);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(tr('comics.copied'))));
              }
            },
            icon: const Icon(Icons.link_rounded),
            label: Text(tr('share_sheet.copy_link')),
          ),
        ),
      ],
    ),
  );
}

/// TODO 语言列表使用版本代码作为身份，避免将翻译记录 ID 误作语言 ID。
Future<void> show_comic_language_sheet(
  BuildContext context,
  ComicDetailLogic logic,
) => _show_sheet(
  context,
  tr('comics.language'),
  Column(
    children: [
      for (final language in logic.detail!.languages)
        Builder(
          builder: (sheet_context) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language_rounded),
            title: Text(LanguageUtil.get_language_name(language.language)),
            subtitle: Text(language.title),
            trailing:
                language.language == logic.selected_code ||
                    language.id == logic.detail!.selected_language_id
                ? Icon(
                    Icons.check_circle_rounded,
                    color: ComicDetailStyle.accent(context),
                  )
                : null,
            onTap: () {
              Navigator.pop(sheet_context);
              if (!logic.loading) logic.load(language: language.language);
            },
          ),
        ),
    ],
  ),
);

/// TODO 作者面板只展示服务端已提供的资料，不虚构简介或作品数量。
Future<void> show_comic_author_sheet(
  BuildContext context,
  ComicDetail detail,
) => _show_sheet(
  context,
  tr('comics.author'),
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipOval(
        child: SizedBox.square(
          dimension: 64,
          child: ComicImage(
            url: detail.comic.author_avatar,
            semantic_label: detail.comic.author_name,
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.comic.author_name,
              style: TextStyle(
                fontSize: 21,
                fontWeight: ComicDetailStyle.weight_medium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail.comic.title,
              style: TextStyle(color: ComicDetailStyle.muted(context)),
            ),
          ],
        ),
      ),
    ],
  ),
);

/// TODO 推荐列表与短篇目录共用面板层级、卡片表面和文字比例，点击先关闭面板再进入作品。
Future<void> show_comic_recommendations(
  BuildContext context,
  List<ComicItem> comics,
  ValueChanged<int> on_open,
) => _show_sheet(
  context,
  tr('comics.similar_comics'),
  Column(
    children: [
      if (comics.isEmpty)
        Padding(
          padding: const EdgeInsets.all(CatalogCardStyle.list_padding),
          child: Text(
            tr('comics.empty_discover'),
            style: TextStyle(color: ComicDetailStyle.muted(context)),
          ),
        ),
      for (final comic in comics)
        Padding(
          padding: const EdgeInsets.only(bottom: CatalogCardStyle.list_gap),
          child: Builder(
            builder: (sheet_context) => _RecommendationCard(
              comic: comic,
              on_open: () {
                Navigator.pop(sheet_context);
                on_open(comic.id);
              },
            ),
          ),
        ),
    ],
  ),
);

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.comic, required this.on_open});
  final ComicItem comic;
  final VoidCallback on_open;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final dark = ComicDetailStyle.is_dark(context);
    return CatalogCardSurface(
      is_dark: dark,
      child: InkWell(
        onTap: on_open,
        child: Padding(
          padding: EdgeInsets.all(
            cjk
                ? CatalogCardStyle.padding_cjk
                : CatalogCardStyle.padding_alphabetic,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: cjk
                      ? CatalogCardStyle.title_size_cjk
                      : CatalogCardStyle.title_size_alphabetic,
                  height: cjk
                      ? CatalogCardStyle.title_height_cjk
                      : CatalogCardStyle.title_height_alphabetic,
                  color: ComicDetailStyle.ink(context),
                  fontWeight: ComicDetailStyle.weight_medium,
                ),
              ),
              const SizedBox(height: CatalogCardStyle.gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      comic.description.isNotEmpty
                          ? comic.description
                          : comic.author_name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: cjk
                            ? CatalogCardStyle.description_size_cjk
                            : CatalogCardStyle.description_size_alphabetic,
                        height: CatalogCardStyle.description_height,
                        color: ComicDetailStyle.muted(context),
                        fontWeight: ComicDetailStyle.weight_regular,
                      ),
                    ),
                  ),
                  if (comic.cover_url.isNotEmpty) ...[
                    const SizedBox(width: CatalogCardStyle.gap),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        CatalogCardStyle.cover_radius,
                      ),
                      child: SizedBox(
                        width: CatalogCardStyle.cover_width,
                        height: CatalogCardStyle.cover_height,
                        child: ComicImage(
                          url: comic.cover_url,
                          semantic_label: comic.title,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (comic.categories.isNotEmpty) ...[
                const SizedBox(height: CatalogCardStyle.gap),
                Wrap(
                  spacing: ContentCategoryTagStyle.spacing,
                  runSpacing: ContentCategoryTagStyle.spacing,
                  children: comic.categories
                      .take(2)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                        final translations = entry.value['translations'];
                        final code = Localizations.localeOf(
                          context,
                        ).languageCode;
                        final name = translations is Map
                            ? translations[code]?.toString()
                            : null;
                        return ContentCategoryTag(
                          label: name ?? entry.value['name']?.toString() ?? '',
                          color: ContentCategoryTagStyle.color_for(
                            content_id: comic.id,
                            index: entry.key,
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
