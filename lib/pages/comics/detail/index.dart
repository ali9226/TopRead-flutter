// ignore_for_file: non_constant_identifier_names

import 'package:app/components/window_content_layout/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/detail/widgets/about_section.dart';
import 'package:app/pages/comics/detail/widgets/action_bar.dart';
import 'package:app/pages/comics/detail/widgets/chapter_list.dart';
import 'package:app/pages/comics/detail/widgets/hero_header.dart';
import 'package:app/pages/comics/detail/widgets/content_sliver.dart';
import 'package:app/pages/comics/detail/widgets/info_section.dart';
import 'package:app/pages/comics/detail/widgets/language_selector.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/util/router/router_back.dart';

/// 沉浸式海报与内容卡片保持同一表面色，目录按Sliver懒构建，阅读进度实时反映在行动栏。
class ComicDetailPage extends StatefulWidget {
  final int comic_id;
  final String? language;
  final ComicDetailLogic? controller;

  /// 可复用已预载的封面，生产默认从OBS地址读取。
  final Widget? cover_image;
  const ComicDetailPage({
    super.key,
    required this.comic_id,
    this.language,
    this.controller,
    this.cover_image,
  });
  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  late final ComicDetailLogic _logic =
      widget.controller ?? ComicDetailLogic(widget.comic_id);
  @override
  void initState() {
    super.initState();
    _logic.load(language: widget.language);
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  void _on_back() => routerBack(context);
  void _on_comments() => _logic.open_comments();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _logic,
    builder: (context, child) {
      final is_dark = ComicDetailStyle.is_dark(context);
      final is_cjk = ComicsStyle.is_cjk(context);
      final background = ComicDetailStyle.card_background(is_dark);
      final detail = _logic.detail;
      if (detail == null) {
        return Scaffold(
          backgroundColor: background,
          appBar: WindowAppBar(
            child: AppBar(
              backgroundColor: background,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _on_back,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(
                tr('comics.title'),
                style: ComicDetailStyle.text(context, strong: true),
              ),
            ),
          ),
          body: WindowContentLayout(
            child: Center(
              child: ComicsEmptyState(
                loading: _logic.loading,
                error: _logic.error,
                message: tr('comics.unavailable'),
                on_retry: _logic.load,
              ),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: background,
        body: RefreshIndicator(
          onRefresh: _logic.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              ComicDetailHeroHeader(
                detail: detail,
                is_dark: is_dark,
                cover_image: widget.cover_image,
                on_back: _on_back,
                on_comments: _on_comments,
              ),
              SliverToBoxAdapter(
                child: WindowContentLayout(
                  expand_height: false,
                  child: Container(
                    decoration: BoxDecoration(color: background),
                    padding: const EdgeInsets.fromLTRB(
                      ComicDetailStyle.content_padding_h,
                      ComicDetailStyle.content_padding_top,
                      ComicDetailStyle.content_padding_h,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ComicDetailInfoSection(
                          detail: detail,
                          is_dark: is_dark,
                          is_cjk: is_cjk,
                        ),
                        if (detail.languages.isNotEmpty) ...<Widget>[
                          _section_title(
                            context,
                            tr('comics.language'),
                            is_cjk,
                          ),
                          ComicDetailLanguageSelector(
                            detail: detail,
                            is_dark: is_dark,
                            enabled: !_logic.loading,
                            on_selected: (language) =>
                                _logic.load(language: language),
                          ),
                        ],
                        if (detail.selected_language?.description
                                .trim()
                                .isNotEmpty ==
                            true) ...<Widget>[
                          _section_title(context, tr('comics.about'), is_cjk),
                          ComicDetailAboutSection(
                            key: ValueKey(
                              'comic_about_${detail.selected_language_id}',
                            ),
                            description: detail.selected_language!.description,
                            is_dark: is_dark,
                            is_cjk: is_cjk,
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(
                            top: ComicDetailStyle.section_top_spacing,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  tr('comics.chapters'),
                                  style: _section_title_style(context, is_cjk),
                                ),
                              ),
                              if (_logic.loading)
                                const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: ComicDetailStyle.section_title_gap,
                        ),
                        if (_logic.error != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: ComicDetailStyle.section_title_gap,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _logic.error!,
                                  style: ComicDetailStyle.text(
                                    context,
                                    color: ComicDetailStyle.muted(context),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _logic.load,
                                  style: ComicDetailStyle.text_button(context),
                                  child: Text(tr('comics.retry')),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              ComicDetailContentSliver(
                child: SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ComicDetailStyle.content_padding_h,
                  ),
                  sliver: ComicDetailChapterList(
                    chapters: _logic.readable_chapters,
                    is_dark: is_dark,
                    resume_chapter_id: _logic.resume_record?.chapter.id ?? 0,
                    on_open: _logic.open_chapter,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: ComicDetailStyle.content_padding_bottom,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ComicDetailActionBar(
          collected: _logic.collected,
          collecting: _logic.collecting,
          can_read: !_logic.loading && _logic.start_chapter_id > 0,
          can_continue: _logic.can_continue,
          chapter_title: _logic.resume_chapter_title,
          on_collect: _logic.collect,
          on_read: () =>
              _logic.open_chapter(_logic.start_chapter_id, resume: true),
        ),
      );
    },
  );

  Widget _section_title(BuildContext context, String text, bool is_cjk) =>
      Padding(
        padding: const EdgeInsets.only(
          top: ComicDetailStyle.section_top_spacing,
          bottom: ComicDetailStyle.section_title_gap,
        ),
        child: Text(text, style: _section_title_style(context, is_cjk)),
      );
  TextStyle _section_title_style(BuildContext context, bool is_cjk) =>
      ComicDetailStyle.text(
        context,
        size: ComicDetailStyle.pick_font_size(
          is_cjk: is_cjk,
          cjk: ComicDetailStyle.section_title_font_size_cjk,
          alphabetic: ComicDetailStyle.section_title_font_size_alphabetic,
        ),
        strong: true,
      );
}
