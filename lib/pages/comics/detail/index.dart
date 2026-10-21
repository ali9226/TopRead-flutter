// ignore_for_file: non_constant_identifier_names

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/detail/widgets/detail_sheets.dart';
import 'package:app/pages/comics/detail/widgets/hero_header.dart';
import 'package:app/pages/comics/detail/widgets/overview_tab.dart';
import 'package:app/pages/comics/detail/widgets/quick_actions.dart';
import 'package:app/pages/comics/detail/widgets/warm_paper.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/index.dart';
import 'package:app/pages/comics/widgets/comment_sheet/index.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/util/router/router_back.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 漫画详情为海报与简介单一滚动页，目录和评论通过共享底部弹窗打开。
class ComicDetailPage extends StatefulWidget {
  const ComicDetailPage({
    super.key,
    required this.comic_id,
    this.language,
    this.controller,
    this.cover_image,
  });
  final int comic_id;
  final String? language;
  final ComicDetailLogic? controller;
  final Widget? cover_image;

  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  late final ComicDetailLogic _logic =
      widget.controller ?? ComicDetailLogic(widget.comic_id);
  int? _comment_count;

  @override
  void initState() {
    super.initState();
    _logic.load(language: widget.language).then((_) {
      if (mounted) _logic.load_similar();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _logic.dispose();
    super.dispose();
  }

  void _on_back() => routerBack(context);
  void _on_share() => show_comic_share_sheet(context, _logic.detail!);
  void _on_read() => _logic.open_chapter(_logic.start_chapter_id, resume: true);
  void _on_collect() => _logic.collect();
  void _on_chapters() => show_comic_chapter_sheet(
    context,
    comic_id: widget.comic_id,
    language: _logic.selected_code ?? widget.language,
    current_chapter_id: _logic.resume_record?.chapter.id,
    controller: _logic,
  );
  void _on_comments() => show_comic_comment_sheet(
    context,
    comic_id: widget.comic_id,
    on_count_changed: (count) {
      if (mounted && _comment_count != count) {
        setState(() => _comment_count = count);
      }
    },
  );
  void _on_see_all_similar() => show_comic_recommendations(
    context,
    _logic.similar_comics,
    _on_similar_tap,
  );
  void _on_similar_tap(int comic_id) =>
      routerUtil(path: '/comics/detail?id=$comic_id');

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _logic,
    builder: (context, _) {
      final dark = ComicDetailStyle.is_dark(context);
      final background = ComicDetailStyle.page_background(dark);
      final detail = _logic.detail;
      if (detail == null) {
        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            leading: BackButton(onPressed: _on_back),
          ),
          body: SafeArea(
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
        body: WindowContentLayout(
          max_width: 600,
          child: CustomScrollView(
            key: const PageStorageKey('comic_detail_scroll'),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              ComicDetailHeroHeader(
                detail: detail,
                on_back: _on_back,
                on_share: _on_share,
                on_read: _on_read,
                on_collect: _on_collect,
                is_dark: dark,
                cover_image: widget.cover_image,
                collected: _logic.collected,
                collecting: _logic.collecting,
                can_read:
                    !_logic.loading && _logic.readable_chapters.isNotEmpty,
                continuing: _logic.can_continue,
              ),
              SliverToBoxAdapter(
                child: ComicContentSurface(
                  is_dark: dark,
                  child: Column(
                    children: [
                      ComicDetailQuickActions(
                        chapter_count: _logic.readable_chapters.length,
                        comment_count:
                            _comment_count ?? detail.comic.comment_count,
                        on_chapters: _on_chapters,
                        on_comments: _on_comments,
                      ),
                      if (_logic.error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ComicDetailStyle.content_padding_h,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _logic.error!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ComicDetailStyle.muted(context),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _logic.load,
                                child: Text(tr('comics.retry')),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.paddingOf(context).bottom +
                              ComicDetailStyle.content_padding_bottom,
                        ),
                        child: ComicDetailOverviewTab(
                          detail: detail,
                          is_dark: dark,
                          similar_comics: _logic.similar_comics,
                          on_see_all_similar: _on_see_all_similar,
                          on_similar_tap: _on_similar_tap,
                          on_author: () =>
                              show_comic_author_sheet(context, detail),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
