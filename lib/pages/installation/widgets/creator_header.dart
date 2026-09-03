// ignore_for_file: non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/pages/installation/author_style.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 创作者中心的共享可折叠头部。
///
/// 该组件绘制在 Tab 内容上方，不参与 [TabBarView] 的横向位移。
/// [current_height] 完全由当前 Tab 的独立滚动控制器计算，因此头部可以响应
/// 当前内容的纵向滚动，同时不会迫使其他 Tab 复用同一个 ScrollPosition。
class CreatorHeaderOverlay extends StatelessWidget {
  /// 页面状态 Tab 控制器。
  final TabController tab_controller;

  /// 头部当前可见高度。
  final double current_height;

  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 当前是否为 CJK 语系。
  final bool is_cjk;

  /// 作者展示名称。
  final String author_name;

  /// 作品数量。
  final int works_count;

  /// 收藏数量展示文字。
  final String favorites_count;

  /// 评论数量展示文字。
  final String comments_count;

  /// 返回上一页回调。
  final VoidCallback on_back;

  /// 创建作品回调。
  final VoidCallback on_create_work;

  /// 继续最新草稿回调。
  final VoidCallback on_continue_writing;

  /// 打开创作说明回调。
  final VoidCallback on_open_guide;

  const CreatorHeaderOverlay({
    super.key,
    required this.tab_controller,
    required this.current_height,
    required this.is_dark,
    required this.is_cjk,
    required this.author_name,
    required this.works_count,
    required this.favorites_count,
    required this.comments_count,
    required this.on_back,
    required this.on_create_work,
    required this.on_continue_writing,
    required this.on_open_guide,
  });

  @override
  Widget build(BuildContext context) {
    final double expanded_height = is_cjk
        ? AuthorStyle.header_expanded_height_cjk
        : AuthorStyle.header_expanded_height_alphabetic;
    final double status_bar_height = MediaQuery.paddingOf(context).top;
    final double maximum_extent = status_bar_height + expanded_height;
    final double minimum_extent =
        status_bar_height +
        AuthorStyle.header_toolbar_height +
        AuthorStyle.header_tab_bar_height;
    final double available_range = maximum_extent - minimum_extent;
    final double safe_height = current_height.clamp(
      minimum_extent,
      maximum_extent,
    );
    final double collapse_progress = available_range <= 0
        ? 1
        : ((maximum_extent - safe_height) / available_range).clamp(0.0, 1.0);
    final double expanded_opacity =
        1 -
        Curves.easeIn.transform(
          (collapse_progress / AuthorStyle.expanded_content_fade_end).clamp(
            0.0,
            1.0,
          ),
        );
    final double compact_opacity = Curves.easeOut.transform(
      ((collapse_progress - AuthorStyle.compact_navigation_fade_start) /
              (1 - AuthorStyle.compact_navigation_fade_start))
          .clamp(0.0, 1.0),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: is_dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: SizedBox(
        height: safe_height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: _CreatorFlexibleHeader(
                  expanded_height: expanded_height,
                  is_dark: is_dark,
                  is_cjk: is_cjk,
                  author_name: author_name,
                  works_count: works_count,
                  favorites_count: favorites_count,
                  comments_count: comments_count,
                  on_back: on_back,
                  on_create_work: on_create_work,
                  on_continue_writing: on_continue_writing,
                  on_open_guide: on_open_guide,
                ),
              ),
            ),
            Positioned(
              left: AuthorStyle.header_navigation_hit_inset,
              top: status_bar_height + AuthorStyle.header_navigation_hit_top,
              child: _HeaderTapTarget(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                on_tap: on_back,
              ),
            ),
            Positioned(
              right: AuthorStyle.header_content_padding,
              top: status_bar_height + AuthorStyle.header_expanded_action_top,
              child: IgnorePointer(
                ignoring:
                    expanded_opacity <
                    AuthorStyle.header_action_interaction_opacity,
                child: Opacity(
                  opacity: expanded_opacity,
                  child: _HeaderTapTarget(
                    tooltip: easy.tr('creator_center.creator_guide'),
                    on_tap: on_open_guide,
                  ),
                ),
              ),
            ),
            Positioned(
              right:
                  AuthorStyle.compact_navigation_padding +
                  AuthorStyle.compact_action_size +
                  AuthorStyle.compact_action_spacing,
              top: status_bar_height + AuthorStyle.header_compact_action_top,
              child: IgnorePointer(
                ignoring:
                    compact_opacity <
                    AuthorStyle.header_action_interaction_opacity,
                child: Opacity(
                  opacity: compact_opacity,
                  child: _HeaderTapTarget(
                    tooltip: easy.tr('creator_center.creator_guide'),
                    on_tap: on_open_guide,
                  ),
                ),
              ),
            ),
            Positioned(
              right: AuthorStyle.compact_navigation_padding,
              top: status_bar_height + AuthorStyle.header_compact_action_top,
              child: IgnorePointer(
                ignoring:
                    compact_opacity <
                    AuthorStyle.header_action_interaction_opacity,
                child: Opacity(
                  opacity: compact_opacity,
                  child: _HeaderTapTarget(
                    tooltip: easy.tr('creator_center.create_work'),
                    on_tap: on_create_work,
                  ),
                ),
              ),
            ),
            Positioned(
              left: AuthorStyle.header_content_padding,
              right: AuthorStyle.header_content_padding,
              top:
                  maximum_extent -
                  AuthorStyle.header_tab_bar_height -
                  AuthorStyle.header_content_padding -
                  AuthorStyle.header_action_height -
                  AuthorStyle.expanded_content_translate_y * collapse_progress,
              height: AuthorStyle.header_action_height,
              child: IgnorePointer(
                ignoring:
                    expanded_opacity <
                    AuthorStyle.header_action_interaction_opacity,
                child: Opacity(
                  opacity: expanded_opacity,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 11,
                        child: _HeaderTapRegion(
                          on_tap: on_create_work,
                          semantic_label: easy.tr('creator_center.create_work'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 10,
                        child: _HeaderTapRegion(
                          on_tap: on_continue_writing,
                          semantic_label: easy.tr(
                            'creator_center.continue_writing',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AuthorStyle.header_tab_bar_height,
              child: _CreatorFilterTabBar(
                tab_controller: tab_controller,
                is_dark: is_dark,
                is_cjk: is_cjk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 根据 Sliver 当前高度绘制展开态与紧凑态。
class _CreatorFlexibleHeader extends StatelessWidget {
  final double expanded_height;
  final bool is_dark;
  final bool is_cjk;
  final String author_name;
  final int works_count;
  final String favorites_count;
  final String comments_count;
  final VoidCallback on_back;
  final VoidCallback on_create_work;
  final VoidCallback on_continue_writing;
  final VoidCallback on_open_guide;

  const _CreatorFlexibleHeader({
    required this.expanded_height,
    required this.is_dark,
    required this.is_cjk,
    required this.author_name,
    required this.works_count,
    required this.favorites_count,
    required this.comments_count,
    required this.on_back,
    required this.on_create_work,
    required this.on_continue_writing,
    required this.on_open_guide,
  });

  @override
  Widget build(BuildContext context) {
    final double status_bar_height = MediaQuery.paddingOf(context).top;
    final double maximum_extent = status_bar_height + expanded_height;
    final double minimum_extent =
        status_bar_height +
        AuthorStyle.header_toolbar_height +
        AuthorStyle.header_tab_bar_height;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available_range = maximum_extent - minimum_extent;
        final double collapse_progress = available_range <= 0
            ? 1
            : ((maximum_extent - constraints.maxHeight) / available_range)
                  .clamp(0.0, 1.0);
        final double expanded_opacity =
            1 -
            Curves.easeIn.transform(
              (collapse_progress / AuthorStyle.expanded_content_fade_end).clamp(
                0.0,
                1.0,
              ),
            );
        final double compact_opacity = Curves.easeOut.transform(
          ((collapse_progress - AuthorStyle.compact_navigation_fade_start) /
                  (1 - AuthorStyle.compact_navigation_fade_start))
              .clamp(0.0, 1.0),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: AuthorStyle.hero_gradient(is_dark),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              _build_background_glow(),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: maximum_extent - AuthorStyle.header_tab_bar_height,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -AuthorStyle.expanded_content_translate_y *
                        collapse_progress,
                  ),
                  child: IgnorePointer(
                    ignoring: expanded_opacity < 0.25,
                    child: Opacity(
                      opacity: expanded_opacity,
                      child: _build_expanded_content(
                        context,
                        status_bar_height,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: compact_opacity < 0.75,
                  child: Opacity(
                    opacity: compact_opacity,
                    child: _build_compact_navigation(
                      context,
                      status_bar_height,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建头部背景中的轻量光斑。
  Widget _build_background_glow() {
    return Positioned(
      right: -AuthorStyle.header_glow_size * 0.28,
      top: -AuthorStyle.header_glow_size * 0.34,
      child: Container(
        width: AuthorStyle.header_glow_size,
        height: AuthorStyle.header_glow_size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AuthorStyle.gold.withValues(alpha: is_dark ? 0.08 : 0.20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AuthorStyle.gold.withValues(alpha: is_dark ? 0.10 : 0.16),
              blurRadius: AuthorStyle.header_glow_blur,
              spreadRadius: AuthorStyle.header_glow_blur * 0.16,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展开态的导航、文案、数据与操作区。
  Widget _build_expanded_content(
    BuildContext context,
    double status_bar_height,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AuthorStyle.header_content_padding,
        status_bar_height,
        AuthorStyle.header_content_padding,
        AuthorStyle.header_content_padding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: AuthorStyle.header_expanded_navigation_height,
            child: Row(
              children: <Widget>[
                _HeaderIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  is_dark: is_dark,
                  show_background: false,
                  on_tap: on_back,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    easy.tr('creator_center.title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AuthorStyle.primary_text(is_dark),
                      fontSize: is_cjk ? 19 : 17,
                      fontWeight: AuthorStyle.title_weight,
                    ),
                  ),
                ),
                _HeaderIconButton(
                  icon: Icons.help_outline_rounded,
                  tooltip: easy.tr('creator_center.creator_guide'),
                  is_dark: is_dark,
                  show_background: false,
                  on_tap: on_open_guide,
                ),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              _build_verified_badge(),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  easy.tr(
                    'creator_center.greeting',
                    namedArgs: <String, String>{'name': author_name},
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AuthorStyle.secondary_text(is_dark),
                    fontSize: is_cjk ? 12 : 11,
                    fontWeight: AuthorStyle.body_weight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            easy.tr('creator_center.hero_title'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AuthorStyle.primary_text(is_dark),
              fontSize: is_cjk
                  ? AuthorStyle.hero_title_size_cjk
                  : AuthorStyle.hero_title_size_alphabetic,
              height: is_cjk ? 1.24 : 1.28,
              fontWeight: AuthorStyle.title_weight,
              letterSpacing: is_cjk ? 0.2 : -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            easy.tr('creator_center.hero_subtitle'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AuthorStyle.secondary_text(is_dark),
              fontSize: is_cjk ? 12.5 : 11.5,
              height: is_cjk ? 1.42 : 1.48,
              fontWeight: AuthorStyle.body_weight,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: AuthorStyle.metric_strip_height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AuthorStyle.header_glass(is_dark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuthorStyle.border(is_dark)),
              ),
              child: Row(
                children: <Widget>[
                  _build_metric(
                    value: '$works_count',
                    label: easy.tr('creator_center.stats_works'),
                    accent_color: AuthorStyle.blue,
                  ),
                  _build_metric_divider(),
                  _build_metric(
                    value: favorites_count,
                    label: easy.tr('creator_center.stats_favorites'),
                    accent_color: AuthorStyle.gold,
                  ),
                  _build_metric_divider(),
                  _build_metric(
                    value: comments_count,
                    label: easy.tr('creator_center.stats_comments'),
                    accent_color: AuthorStyle.coral,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: AuthorStyle.header_action_height,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 11,
                  child: _HeaderActionButton(
                    icon: Icons.add_rounded,
                    label: easy.tr('creator_center.create_work'),
                    is_primary: true,
                    is_dark: is_dark,
                    is_cjk: is_cjk,
                    on_tap: on_create_work,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: _HeaderActionButton(
                    icon: Icons.edit_note_rounded,
                    label: easy.tr('creator_center.continue_writing'),
                    is_primary: false,
                    is_dark: is_dark,
                    is_cjk: is_cjk,
                    on_tap: on_continue_writing,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建折叠后的紧凑导航。
  Widget _build_compact_navigation(
    BuildContext context,
    double status_bar_height,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: status_bar_height),
      child: SizedBox(
        height: AuthorStyle.header_toolbar_height,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AuthorStyle.compact_navigation_padding,
          ),
          child: Row(
            children: <Widget>[
              _HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                is_dark: is_dark,
                on_tap: on_back,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        easy.tr('creator_center.title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AuthorStyle.primary_text(is_dark),
                          fontSize: is_cjk ? 18 : 16.5,
                          fontWeight: AuthorStyle.title_weight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                icon: Icons.help_outline_rounded,
                tooltip: easy.tr('creator_center.creator_guide'),
                is_dark: is_dark,
                on_tap: on_open_guide,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.add_rounded,
                tooltip: easy.tr('creator_center.create_work'),
                is_dark: is_dark,
                is_accent: true,
                on_tap: on_create_work,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建认证作者胶囊。
  Widget _build_verified_badge() {
    final Color foreground = is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AuthorStyle.gold.withValues(alpha: is_dark ? 0.12 : 0.22),
        borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.verified_rounded, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            easy.tr('creator_center.verified'),
            style: TextStyle(
              color: foreground,
              fontSize: is_cjk ? 10.5 : 9.5,
              fontWeight: AuthorStyle.emphasis_weight,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建一个统计数据。
  Widget _build_metric({
    required String value,
    required String label,
    required Color accent_color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AuthorStyle.primary_text(is_dark),
                fontSize: 16,
                height: 1.05,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent_color,
                fontSize: is_cjk ? 10.5 : 9,
                height: 1,
                fontWeight: AuthorStyle.emphasis_weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建数据项之间的轻量分隔线。
  Widget _build_metric_divider() {
    return Container(
      width: 0.5,
      height: 24,
      color: AuthorStyle.border(is_dark),
    );
  }
}

/// 创作者作品状态筛选 Tab。
class _CreatorFilterTabBar extends StatelessWidget {
  final TabController tab_controller;
  final bool is_dark;
  final bool is_cjk;

  const _CreatorFilterTabBar({
    required this.tab_controller,
    required this.is_dark,
    required this.is_cjk,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> titles = <String>[
      easy.tr('creator_center.filter_all'),
      easy.tr('creator_center.filter_draft'),
      easy.tr('creator_center.filter_reviewing'),
      easy.tr('creator_center.filter_scheduled'),
      easy.tr('creator_center.filter_published'),
      easy.tr('creator_center.filter_rejected'),
    ];

    return Container(
      height: AuthorStyle.header_tab_bar_height,
      color: Colors.transparent,
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: tab_controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerHeight: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AuthorStyle.page_padding,
        ),
        labelPadding: EdgeInsets.only(left: is_cjk ? 16 : 10),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: AuthorStyle.gold),
          insets: EdgeInsets.only(bottom: 4),
        ),
        labelColor: AuthorStyle.primary_text(is_dark),
        unselectedLabelColor: AuthorStyle.secondary_text(is_dark),
        labelStyle: TextStyle(
          fontSize: is_cjk
              ? AuthorStyle.tab_font_size_cjk
              : AuthorStyle.tab_font_size_alphabetic,
          fontWeight: AuthorStyle.title_weight,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: is_cjk
              ? AuthorStyle.tab_font_size_cjk
              : AuthorStyle.tab_font_size_alphabetic,
          fontWeight: AuthorStyle.body_weight,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: List<Widget>.generate(
          titles.length,
          (int index) => _build_tab_title(index: index, title: titles[index]),
          growable: false,
        ),
      ),
    );
  }

  /// 使用字号缩放、字重和文字颜色平滑区分选中状态。
  Widget _build_tab_title({required int index, required String title}) {
    final double font_size = is_cjk
        ? AuthorStyle.tab_font_size_cjk
        : AuthorStyle.tab_font_size_alphabetic;
    final double selected_scale = is_cjk
        ? AuthorStyle.tab_selected_scale_cjk
        : AuthorStyle.tab_selected_scale_alphabetic;
    final Color selected_color = AuthorStyle.primary_text(is_dark);
    final Color unselected_color = AuthorStyle.secondary_text(is_dark);

    return AnimatedBuilder(
      animation: tab_controller.animation!,
      builder: (BuildContext context, Widget? child) {
        final double distance = (tab_controller.animation!.value - index)
            .abs()
            .clamp(0.0, 1.0);
        final double scale = selected_scale + (1 - selected_scale) * distance;
        final Color text_color =
            Color.lerp(selected_color, unselected_color, distance) ??
            unselected_color;
        final FontWeight font_weight =
            FontWeight.lerp(
              AuthorStyle.title_weight,
              AuthorStyle.body_weight,
              distance,
            ) ??
            AuthorStyle.body_weight;

        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AuthorStyle.tab_horizontal_padding,
              vertical: AuthorStyle.tab_vertical_padding,
            ),
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                color: text_color,
                fontSize: font_size,
                fontWeight: font_weight,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 头部圆形图标按钮。
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool is_dark;
  final bool is_accent;
  final bool show_background;
  final VoidCallback on_tap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.is_dark,
    required this.on_tap,
    this.is_accent = false,
    this.show_background = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = is_accent
        ? const Color(0xFF1D1B14)
        : AuthorStyle.primary_text(is_dark);
    final Color background = is_accent
        ? AuthorStyle.gold
        : show_background
        ? AuthorStyle.header_glass(is_dark)
        : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
        child: InkWell(
          onTap: on_tap,
          borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
          child: SizedBox(
            width: AuthorStyle.compact_action_size,
            height: AuthorStyle.compact_action_size,
            child: Icon(icon, size: 19, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// 展开头部的快捷操作按钮。
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool is_primary;
  final bool is_dark;
  final bool is_cjk;
  final VoidCallback on_tap;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.is_primary,
    required this.is_dark,
    required this.is_cjk,
    required this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = is_primary
        ? const Color(0xFF1D1B14)
        : AuthorStyle.primary_text(is_dark);
    final Color background = is_primary
        ? AuthorStyle.gold
        : AuthorStyle.header_glass(is_dark);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AuthorStyle.header_action_radius),
      child: InkWell(
        onTap: on_tap,
        borderRadius: BorderRadius.circular(AuthorStyle.header_action_radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: is_cjk
                        ? AuthorStyle.button_font_size_cjk
                        : AuthorStyle.button_font_size_alphabetic,
                    fontWeight: AuthorStyle.title_weight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 覆盖在头部可视图标上的无背景点击区。
class _HeaderTapTarget extends StatelessWidget {
  final String tooltip;
  final VoidCallback on_tap;

  const _HeaderTapTarget({required this.tooltip, required this.on_tap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on_tap,
          child: const SizedBox.square(
            dimension: AuthorStyle.compact_action_size,
          ),
        ),
      ),
    );
  }
}

/// 覆盖在头部快捷按钮上的无背景点击区。
class _HeaderTapRegion extends StatelessWidget {
  final String semantic_label;
  final VoidCallback on_tap;

  const _HeaderTapRegion({required this.semantic_label, required this.on_tap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic_label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on_tap,
        child: const SizedBox.expand(),
      ),
    );
  }
}
