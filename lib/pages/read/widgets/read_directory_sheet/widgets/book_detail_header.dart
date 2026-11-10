import 'package:app/api/bookshelf.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'book_detail_header_style.dart';
import 'book_header_backdrop.dart';
import 'book_header_statistics.dart';

/// TODO 章节弹窗封面 Hero；统计来自真实详情，未提供的计数显示破折号。
class BookDetailHeader extends StatefulWidget {
  /// TODO [chapter_count] 为当前作品目录总数，[favorite_count] 为服务端收藏计数。
  /// TODO [subtitle] 使用作品原始副标题，缺失时不从书名猜测或补造。
  const BookDetailHeader({
    super.key,
    required this.detail,
    required this.is_dark,
    this.on_focus_changed,
    this.chapter_count,
    this.favorite_count,
    this.subtitle = '',
    this.show_backdrop = true,
  });

  final ReadDetail detail;
  final bool is_dark;
  final ValueChanged<bool>? on_focus_changed;
  final int? chapter_count;
  final String? favorite_count;
  final String subtitle;
  final bool show_backdrop;

  @override
  State<BookDetailHeader> createState() => _BookDetailHeaderState();
}

class _BookDetailHeaderState extends State<BookDetailHeader> {
  late bool _is_focused;
  bool _is_loading = false;
  int _follow_generation = 0;

  @override
  void initState() {
    super.initState();
    _is_focused = widget.detail.focus_on;
  }

  @override
  void didUpdateWidget(covariant BookDetailHeader old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.detail.story_id != widget.detail.story_id ||
        old_widget.detail.author_id != widget.detail.author_id) {
      _follow_generation++;
      _is_loading = false;
      _is_focused = widget.detail.focus_on;
    } else if (old_widget.detail.focus_on != widget.detail.focus_on) {
      _is_focused = widget.detail.focus_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final bool compact =
        MediaQuery.sizeOf(context).height <
        BookDetailHeaderStyle.compact_viewport_height;
    final statistics = BookHeaderStatistics(
      items: _statistics(context),
      is_dark: widget.is_dark,
      compact: compact,
    );

    return Stack(
      key: const ValueKey('directory_book_hero'),
      children: [
        if (widget.show_backdrop)
          Positioned.fill(
            child: BookHeaderBackdrop(
              cover_url: widget.detail.cover_url,
              is_dark: widget.is_dark,
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact
                ? BookDetailHeaderStyle.compact_horizontal_padding
                : BookDetailHeaderStyle.horizontal_padding,
            BookDetailHeaderStyle.top_padding,
            compact
                ? BookDetailHeaderStyle.compact_horizontal_padding
                : BookDetailHeaderStyle.horizontal_padding,
            compact
                ? BookDetailHeaderStyle.compact_bottom_padding
                : BookDetailHeaderStyle.bottom_padding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _cover(compact),
                  SizedBox(
                    width: compact
                        ? BookDetailHeaderStyle.compact_cover_gap
                        : BookDetailHeaderStyle.cover_gap,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: widget.detail.title,
                          child: Text(
                            widget.detail.title,
                            key: const ValueKey('directory_book_title'),
                            maxLines: compact
                                ? BookDetailHeaderStyle.compact_title_lines
                                : BookDetailHeaderStyle.title_lines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: BookDetailHeaderStyle.ink,
                              fontSize: compact
                                  ? (cjk
                                        ? BookDetailHeaderStyle
                                              .compact_title_size_cjk
                                        : BookDetailHeaderStyle
                                              .compact_title_size_alphabetic)
                                  : (cjk
                                        ? BookDetailHeaderStyle.title_size_cjk
                                        : BookDetailHeaderStyle
                                              .title_size_alphabetic),
                              height: cjk
                                  ? BookDetailHeaderStyle.title_height_cjk
                                  : BookDetailHeaderStyle
                                        .title_height_alphabetic,
                              fontWeight: FontConfig.adjustedWeight(
                                FontWeight.w500,
                              ),
                              shadows: BookDetailHeaderStyle.title_shadows,
                            ),
                          ),
                        ),
                        if (!compact && widget.subtitle.trim().isNotEmpty) ...[
                          const SizedBox(
                            height: BookDetailHeaderStyle.subtitle_gap,
                          ),
                          Text(
                            widget.subtitle.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _secondary_style(cjk),
                          ),
                        ],
                        if (!compact &&
                            widget.detail.author_name.trim().isNotEmpty) ...[
                          const SizedBox(
                            height: BookDetailHeaderStyle.author_gap,
                          ),
                          _author(cjk),
                        ],
                        SizedBox(
                          height: compact
                              ? BookDetailHeaderStyle.compact_metadata_gap
                              : BookDetailHeaderStyle.metadata_gap,
                        ),
                        _metadata(cjk),
                        if (compact) ...[
                          const SizedBox(
                            height:
                                BookDetailHeaderStyle.compact_statistics_gap,
                          ),
                          statistics,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: BookDetailHeaderStyle.statistics_gap),
                statistics,
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// TODO 封面固定比例并保留亮边，加载及缺图状态不改变头部几何。
  Widget _cover(bool compact) {
    final double width = compact
        ? BookDetailHeaderStyle.compact_cover_width
        : BookDetailHeaderStyle.cover_width;
    final double height = compact
        ? BookDetailHeaderStyle.compact_cover_height
        : BookDetailHeaderStyle.cover_height;
    return DecoratedBox(
      key: const ValueKey('directory_book_cover'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BookDetailHeaderStyle.cover_radius),
        boxShadow: BookDetailHeaderStyle.cover_shadows,
      ),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(BookDetailHeaderStyle.cover_border_width),
        decoration: BoxDecoration(
          color: BookDetailHeaderStyle.ink.withValues(
            alpha: BookDetailHeaderStyle.cover_border_opacity,
          ),
          borderRadius: BorderRadius.circular(
            BookDetailHeaderStyle.cover_radius,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            BookDetailHeaderStyle.cover_radius -
                BookDetailHeaderStyle.cover_border_width,
          ),
          child: widget.detail.cover_url.trim().isEmpty
              ? _cover_placeholder()
              : NetworkCoverImage(
                  image_url: widget.detail.cover_url,
                  width: width,
                  height: height,
                  border_radius: BookDetailHeaderStyle.cover_radius,
                  is_dark: widget.is_dark,
                  loading_placeholder: (_) => _cover_placeholder(),
                ),
        ),
      ),
    );
  }

  Widget _cover_placeholder() => ColoredBox(
    color: BookDetailHeaderStyle.background,
    child: Center(
      child: Icon(
        Icons.auto_stories_rounded,
        size: BookDetailHeaderStyle.statistic_icon_size,
        color: BookDetailHeaderStyle.muted_ink,
      ),
    ),
  );

  TextStyle _secondary_style(bool cjk) => TextStyle(
    color: BookDetailHeaderStyle.muted_ink,
    fontSize: cjk
        ? BookDetailHeaderStyle.subtitle_size_cjk
        : BookDetailHeaderStyle.subtitle_size_alphabetic,
    height: cjk
        ? BookDetailHeaderStyle.subtitle_height_cjk
        : BookDetailHeaderStyle.subtitle_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    shadows: BookDetailHeaderStyle.title_shadows,
  );

  /// TODO 作者名允许省略，关注按钮按实际文字宽度决定是否换到下一行。
  Widget _author(bool cjk) => LayoutBuilder(
    builder: (context, constraints) {
      final name = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: BookDetailHeaderStyle.author_icon_size,
            color: BookDetailHeaderStyle.muted_ink,
          ),
          const SizedBox(width: BookDetailHeaderStyle.token_icon_gap),
          Flexible(
            child: Text(
              widget.detail.author_name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _secondary_style(cjk),
            ),
          ),
        ],
      );
      if (widget.detail.author_id <= 0) return name;
      final painter = TextPainter(
        text: TextSpan(
          text: tr(_is_focused ? 'read.followed' : 'read.follow'),
          style: DefaultTextStyle.of(context).style.merge(_follow_style(cjk)),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final required_width =
          painter.width +
          BookDetailHeaderStyle.follow_padding_h * 2 +
          BookDetailHeaderStyle.author_gap +
          BookDetailHeaderStyle.author_min_width;
      painter.dispose();
      if (required_width > constraints.maxWidth) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [name, _follow_button(cjk)],
        );
      }
      return Row(
        children: [
          Expanded(child: name),
          const SizedBox(width: BookDetailHeaderStyle.author_gap),
          _follow_button(cjk),
        ],
      );
    },
  );

  TextStyle _follow_style(bool cjk) => TextStyle(
    color: _is_focused
        ? BookDetailHeaderStyle.muted_ink
        : BookDetailHeaderStyle.accent,
    fontSize: cjk
        ? BookDetailHeaderStyle.follow_font_size_cjk
        : BookDetailHeaderStyle.follow_font_size_alphabetic,
    height: BookDetailHeaderStyle.metadata_line_height,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    shadows: BookDetailHeaderStyle.title_shadows,
  );

  Widget _follow_button(bool cjk) => Semantics(
    button: true,
    enabled: !_is_loading,
    child: InkWell(
      key: const ValueKey('directory_author_follow'),
      onTap: _is_loading ? null : _handle_follow_toggle,
      borderRadius: BorderRadius.circular(BookDetailHeaderStyle.status_radius),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: BookDetailHeaderStyle.follow_target_height,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: BookDetailHeaderStyle.follow_padding_h,
          vertical: BookDetailHeaderStyle.follow_padding_v,
        ),
        decoration: BoxDecoration(
          color: BookDetailHeaderStyle.ink.withValues(
            alpha: BookDetailHeaderStyle.follow_surface_opacity,
          ),
          borderRadius: BorderRadius.circular(
            BookDetailHeaderStyle.status_radius,
          ),
          border: Border.all(
            color: BookDetailHeaderStyle.ink.withValues(
              alpha: BookDetailHeaderStyle.follow_border_opacity,
            ),
            width: BookDetailHeaderStyle.follow_border_width,
          ),
        ),
        child: Text(
          tr(_is_focused ? 'read.followed' : 'read.follow'),
          style: _follow_style(cjk),
        ),
      ),
    ),
  );

  /// TODO 状态、章节总数与真实字数自然换行，不锁定系统大字的行高。
  Widget _metadata(bool cjk) {
    final style = TextStyle(
      color: BookDetailHeaderStyle.muted_ink,
      fontSize: cjk
          ? BookDetailHeaderStyle.metadata_size_cjk
          : BookDetailHeaderStyle.metadata_size_alphabetic,
      height: BookDetailHeaderStyle.metadata_line_height,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      shadows: BookDetailHeaderStyle.title_shadows,
    );
    final words =
        widget.detail.word_count_value_text ??
        '${widget.detail.word_count_major_text}${widget.detail.word_count_minor_text}';
    final word_label =
        widget.detail.word_count_label_text ??
        tr('read.chapter_word_count_suffix');
    return Wrap(
      key: const ValueKey('directory_book_metadata'),
      spacing: BookDetailHeaderStyle.token_spacing,
      runSpacing: BookDetailHeaderStyle.token_run_spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.detail.status_text.trim().isNotEmpty)
          Container(
            key: const ValueKey('directory_book_status'),
            padding: const EdgeInsets.symmetric(
              horizontal: BookDetailHeaderStyle.status_padding_h,
              vertical: BookDetailHeaderStyle.status_padding_v,
            ),
            decoration: BoxDecoration(
              color: BookDetailHeaderStyle.accent,
              borderRadius: BorderRadius.circular(
                BookDetailHeaderStyle.status_radius,
              ),
            ),
            child: Text(
              widget.detail.status_text,
              style: style.copyWith(
                color: BookDetailHeaderStyle.status_ink,
                shadows: const [],
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              ),
            ),
          ),
        _metadata_token(
          icon: Icons.menu_book_outlined,
          label: tr(
            'comics.chapter_count_label',
            namedArgs: {'count': widget.chapter_count?.toString() ?? '—'},
          ),
          style: style,
        ),
        _metadata_token(
          icon: Icons.notes_rounded,
          label: cjk ? '$words$word_label' : '$words $word_label',
          style: style,
        ),
      ],
    );
  }

  Widget _metadata_token({
    required IconData icon,
    required String label,
    required TextStyle style,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: BookDetailHeaderStyle.token_icon_size,
        color: BookDetailHeaderStyle.muted_ink,
      ),
      const SizedBox(width: BookDetailHeaderStyle.token_icon_gap),
      Flexible(child: Text(label, style: style)),
    ],
  );

  /// TODO 评分遵循服务端开关；未知计数显示破折号，不从带单位的字符串猜测。
  List<WorkHeroStat> _statistics(BuildContext context) {
    final config = Get.isRegistered<ProjectConfigStore>()
        ? Get.find<ProjectConfigStore>().current
        : null;
    final score = double.tryParse(widget.detail.score_major_text.trim());
    final bool show_score =
        config == null ||
        (config.is_rating_enabled && !config.is_apple_review_mode);
    return [
      if (show_score)
        WorkHeroStat(
          icon: Icons.star_rounded,
          value: score != null && score.isFinite && score > 0
              ? widget.detail.score_major_text
              : '—',
          label: widget.detail.review_count_text.isNotEmpty
              ? widget.detail.review_count_text
              : tr('comics.ratings'),
        ),
      WorkHeroStat(
        icon: Icons.local_fire_department_rounded,
        value:
            widget.detail.reading_value_text ??
            '${widget.detail.reading_major_text}${widget.detail.reading_minor_text}',
        label:
            widget.detail.reading_label_text ??
            widget.detail.reading_subtitle_text,
      ),
      WorkHeroStat(
        icon: Icons.bookmark_border_rounded,
        value: _format_count(widget.favorite_count, context.locale.toString()),
        label: tr('comics.favorites'),
      ),
    ];
  }

  String _format_count(String? raw_count, String locale) {
    final value = num.tryParse(raw_count?.trim() ?? '');
    if (value == null || !value.isFinite || value < 0) return '—';
    final number_locale = Intl.verifiedLocale(
      locale,
      NumberFormat.localeExists,
      onFailure: (_) => 'en',
    );
    return NumberFormat.compact(locale: number_locale).format(value);
  }

  /// TODO 保留作者关注的登录校验、乐观反馈、失败回滚及跨作品请求隔离。
  Future<void> _handle_follow_toggle() async {
    if (_is_loading || widget.detail.author_id <= 0) return;
    final generation = ++_follow_generation;
    final author_id = widget.detail.author_id;
    setState(() => _is_loading = true);
    final allowed = await showLoginRequiredDialog(
      title: tr('short_story_read.login_required'),
    );
    if (!mounted || generation != _follow_generation) return;
    if (!allowed) {
      setState(() => _is_loading = false);
      return;
    }
    final previous_status = _is_focused;
    setState(() => _is_focused = !previous_status);
    widget.on_focus_changed?.call(_is_focused);
    final result = await toggle_focus_author(author_id: author_id);
    if (result != null) await BookshelfSyncService.focus_changed();
    if (!mounted || generation != _follow_generation) return;
    setState(() {
      _is_loading = false;
      _is_focused = result?.focus ?? previous_status;
    });
    widget.on_focus_changed?.call(_is_focused);
  }
}
