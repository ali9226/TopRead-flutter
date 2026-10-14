// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/detail/widgets/about_section.dart';
import 'package:app/pages/comics/detail/widgets/action_bar.dart';
import 'package:app/pages/comics/detail/widgets/chapter_list.dart';
import 'package:app/pages/comics/detail/widgets/hero_header.dart';
import 'package:app/pages/comics/detail/widgets/info_section.dart';
import 'package:app/pages/comics/detail/widgets/language_selector.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/util/router/router_util.dart';

/// 漫画详情页：沉浸式海报 + 内容卡片 + 章节目录 + 底部行动栏。
class ComicDetailPage extends StatefulWidget {
  /// 作品 ID。
  final int comic_id;

  /// 可注入的逻辑控制器（测试用）。
  final ComicDetailLogic? controller;

  const ComicDetailPage({super.key, required this.comic_id, this.controller});

  @override
  State<ComicDetailPage> createState() => _ComicDetailPageState();
}

class _ComicDetailPageState extends State<ComicDetailPage> {
  /// 详情页业务逻辑。
  late final ComicDetailLogic _logic =
      widget.controller ?? ComicDetailLogic(widget.comic_id);

  @override
  void initState() {
    super.initState();
    _logic.load();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  /// 返回上一页；栈底时回首页。
  void _on_back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      routerUtil(path: '/', type: 'replace');
    }
  }

  /// 打开评论页。
  void _on_comments() {
    routerUtil(path: '/comics/comments?comic_id=${widget.comic_id}');
  }

  /// 打开章节阅读。
  void _on_open_chapter(int chapter_id) {
    _logic.open_chapter(chapter_id);
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = ComicsStyle.is_dark(context);
    final bool is_cjk = ComicsStyle.is_cjk(context);
    final Color background = is_dark
        ? ComicDetailStyle.content_card_dark
        : ComicDetailStyle.content_card_light;

    return AnimatedBuilder(
      animation: _logic,
      builder: (context, child) {
        final detail = _logic.detail;
        if (detail == null) {
          return Scaffold(
            backgroundColor: background,
            body: Center(
              child: ComicsEmptyState(
                loading: _logic.loading,
                error: _logic.error,
                message: tr('comics.unavailable'),
                on_retry: _logic.load,
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: background,
          body: _build_body(context, detail, is_dark, is_cjk, background),
          bottomNavigationBar: ComicDetailActionBar(
            collected: _logic.collected,
            collecting: _logic.collecting,
            can_read: _logic.start_chapter_id > 0,
            can_continue: _logic.can_continue,
            on_collect: _logic.collect,
            on_read: () => _logic.open_chapter(
              _logic.start_chapter_id,
              resume: true,
            ),
          ),
        );
      },
    );
  }

  /// 页面主体：海报头 + 内容卡片（信息、语种、简介、章节）。
  Widget _build_body(
    BuildContext context,
    ComicDetail detail,
    bool is_dark,
    bool is_cjk,
    Color background,
  ) {
    final String? description = detail.selected_language?.description;

    return RefreshIndicator(
      onRefresh: _logic.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          /// 沉浸式海报头。
          ComicDetailHeroHeader(
            detail: detail,
            is_dark: is_dark,
            on_back: _on_back,
            on_comments: _on_comments,
          ),

          /// 内容卡片：上移叠在海报渐变之上。
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -ComicDetailStyle.content_card_overlap),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: ComicsStyle.content_width),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(ComicDetailStyle.content_card_radius),
                    topRight: Radius.circular(ComicDetailStyle.content_card_radius),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  ComicDetailStyle.content_padding_h,
                  ComicDetailStyle.content_padding_top,
                  ComicDetailStyle.content_padding_h,
                  ComicDetailStyle.content_padding_bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// 标题 + 作者 + 数据 + 标签。
                    ComicDetailInfoSection(
                      detail: detail,
                      is_dark: is_dark,
                      is_cjk: is_cjk,
                    ),

                    /// 语种选择。
                    if (detail.languages.isNotEmpty) ...<Widget>[
                      _section_title(context, tr('comics.language'), is_cjk),
                      ComicDetailLanguageSelector(
                        detail: detail,
                        is_dark: is_dark,
                        on_selected: (language) =>
                            _logic.load(language: language),
                      ),
                    ],

                    /// 简介。
                    if (description != null && description.trim().isNotEmpty) ...<Widget>[
                      _section_title(context, tr('comics.about'), is_cjk),
                      ComicDetailAboutSection(
                        description: description,
                        is_dark: is_dark,
                        is_cjk: is_cjk,
                      ),
                    ],

                    /// 章节标题行（含加载指示）。
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: ComicDetailStyle.section_title_gap,
                    ),
                    if (_logic.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _logic.error!,
                              style: TextStyle(
                                color: ComicsStyle.muted(context),
                                fontSize: ComicDetailStyle.pick_font_size(
                                  is_cjk: is_cjk,
                                  cjk: ComicDetailStyle
                                      .description_font_size_cjk,
                                  alphabetic: ComicDetailStyle
                                      .description_font_size_alphabetic,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _logic.load,
                                child: Text(tr('comics.retry')),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// 章节目录。
                    ComicDetailChapterList(
                      chapters: detail.chapters,
                      is_dark: is_dark,
                      on_open: _on_open_chapter,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建区块标题占位。
  Widget _section_title(BuildContext context, String text, bool is_cjk) => Padding(
    padding: const EdgeInsets.only(
      top: ComicDetailStyle.section_top_spacing,
      bottom: ComicDetailStyle.section_title_gap,
    ),
    child: Text(text, style: _section_title_style(context, is_cjk)),
  );

  /// 区块标题样式。
  TextStyle _section_title_style(BuildContext context, bool is_cjk) => TextStyle(
    color: ComicsStyle.ink(context),
    fontSize: ComicDetailStyle.pick_font_size(
      is_cjk: is_cjk,
      cjk: ComicDetailStyle.section_title_font_size_cjk,
      alphabetic: ComicDetailStyle.section_title_font_size_alphabetic,
    ),
    fontWeight: ComicDetailStyle.weight_medium,
  );
}
