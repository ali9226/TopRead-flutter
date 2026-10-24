import 'dart:math' as math;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './style.dart';
import './title_layout.dart';

typedef WorkHeroTitleBuilder =
    Widget Function(BuildContext context, TextStyle style, bool on_hero);
typedef WorkHeroContentBuilder =
    Widget Function(BuildContext context, bool on_hero);
typedef WorkHeroActionsBuilder =
    Widget Function(BuildContext context, bool on_hero, bool compact);

/// 三类作品共用的封面简介：封面左、标题右，文字完整自然换行。
///
/// 始终使用封面在左、完整标题在右的同一排布。标题和系统大字自然换行，
/// 前景决定实际高度；操作位置按原字号两行、小字号四行的真实排版决定。
class WorkIntroductionHero extends StatefulWidget {
  const WorkIntroductionHero({
    super.key,
    required this.is_dark,
    required this.title,
    required this.cover,
    required this.backdrop,
    required this.metadata_builder,
    this.title_builder,
    this.is_loading = false,
    this.status_label,
    this.status_key,
    this.overflow_builder,
    this.genres_builder,
    this.actions_builder,
    this.on_back,
    this.on_share,
    this.overlap = WorkIntroductionHeroStyle.default_overlap,
    this.surface_color,
  }) : assert(overlap >= 0);

  final bool is_dark;

  /// 加载时沿用真实几何；日间使用浅色纸面，不叠加封面照片专用的暗幕。
  final bool is_loading;
  final String title;
  final Widget cover;
  final Widget backdrop;
  final WorkHeroTitleBuilder? title_builder;

  /// 来自业务数据的作品状态，贴在封面右上角；空值不显示。
  final String? status_label;
  final Key? status_key;

  /// 作者等核心元信息，与完整标题放在同一列。
  final WorkHeroContentBuilder metadata_builder;

  /// 统计信息始终独占整行，不再挤压标题或操作按钮。
  final WorkHeroContentBuilder? overflow_builder;

  /// 分类标签区域，渲染在统计下方，仍属于封面海报区内。
  final WorkHeroContentBuilder? genres_builder;
  final WorkHeroActionsBuilder? actions_builder;
  final VoidCallback? on_back;
  final VoidCallback? on_share;

  /// 海报末尾覆盖的主题圆角衔接区，同时为前景内容预留真实布局空间。
  final double overlap;

  /// 圆角纸面与紧接的阅读正文使用同色，短篇可以保留自身的夜间阅读底色。
  final Color? surface_color;

  @override
  State<WorkIntroductionHero> createState() => _WorkIntroductionHeroState();
}

class _WorkIntroductionHeroState extends State<WorkIntroductionHero> {
  /// 为作者关注等交互保留稳定的元信息子树身份。
  final _metadata_key = GlobalKey();
  final _actions_key = GlobalKey();

  /// 局部系统区域测量完成后，只同步标题档位，不缓存标题或海报高度。
  WorkHeroTitleTier? _measured_title_tier;

  @override
  void didUpdateWidget(covariant WorkIntroductionHero old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.title != widget.title) {
      _measured_title_tier = null;
    }
  }

  // 测量器在帧结束后报告，比较两种字号的真实InlineSpan和占位控件。
  void _report_title_tier(WorkHeroTitleTier tier) {
    if (mounted && _measured_title_tier != tier) {
      setState(() => _measured_title_tier = tier);
    }
  }

  WorkHeroTitleTier _resolve_title_tier(
    BuildContext context,
    bool cjk,
    double width,
  ) => resolve_work_hero_title_tier(
    context: context,
    title: widget.title,
    max_width: math.max(0, width),
    regular_style: _title_style(cjk, reduced: false),
    reduced_style: _title_style(cjk, reduced: true),
  );

  bool get _light_loading => widget.is_loading && !widget.is_dark;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content_width = math.min(
        constraints.maxWidth,
        WorkIntroductionHeroStyle.max_content_width,
      );
      final inner_width = math.max(
        0.0,
        content_width - WorkIntroductionHeroStyle.horizontal_padding * 2,
      );
      final cjk = LanguageUtil.is_cjk_language(
        Localizations.localeOf(context).languageCode,
      );
      final cover_width = math.min(
        WorkIntroductionHeroStyle.cover_max_width,
        inner_width * WorkIntroductionHeroStyle.cover_width_ratio,
      );
      final title_width =
          inner_width - cover_width - WorkIntroductionHeroStyle.content_gap;
      final tier =
          _measured_title_tier ??
          _resolve_title_tier(context, cjk, title_width);
      final compact_actions = tier != WorkHeroTitleTier.extended;
      final title_and_author = _metadata(context, cjk, compact_actions, tier);
      final surface_color =
          widget.surface_color ??
          (widget.is_dark
              ? ColorConstants.nightBackgroundColor
              : ColorConstants.whiteColor);
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: _light_loading
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: SizedBox(
          key: const ValueKey('work_introduction_poster'),
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 背景只填充前景实际算出的高度，不参与尺寸约束。
              Positioned.fill(
                child: ColoredBox(
                  color: _light_loading
                      ? ColorConstants.lightBackgroundColor
                      : WorkIntroductionHeroStyle.poster_background,
                  child: widget.backdrop,
                ),
              ),
              if (!_light_loading)
                const Positioned.fill(
                  child: DecoratedBox(
                    key: ValueKey('work_introduction_scrim'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: WorkIntroductionHeroStyle.scrim_colors,
                        stops: WorkIntroductionHeroStyle.scrim_stops,
                      ),
                    ),
                  ),
                ),
              SafeArea(
                bottom: false,
                left: false,
                right: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: SizedBox(
                    width: content_width,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        WorkIntroductionHeroStyle.horizontal_padding,
                        WorkIntroductionHeroStyle.nav_top,
                        WorkIntroductionHeroStyle.horizontal_padding,
                        WorkIntroductionHeroStyle.content_bottom +
                            widget.overlap,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.on_back != null ||
                              widget.on_share != null) ...[
                            WindowReservedRegionPadding(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (widget.on_back != null)
                                    _navigation(
                                      context,
                                      icon: Icons.chevron_left_rounded,
                                      label: MaterialLocalizations.of(
                                        context,
                                      ).backButtonTooltip,
                                      on_tap: widget.on_back!,
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (widget.on_share != null)
                                    _navigation(
                                      context,
                                      icon: Icons.share_outlined,
                                      label: MaterialLocalizations.of(
                                        context,
                                      ).shareButtonLabel,
                                      on_tap: widget.on_share!,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: WorkIntroductionHeroStyle.nav_content_gap,
                            ),
                          ],
                          // 整行以稳定的封面区域避让系统顶角；不会因标题缩字、
                          // 按钮迁移和底部对齐改变标题Y位置而来回切换档位。
                          WindowReservedRegionPadding(
                            mode: WindowReservedRegionPaddingMode.heading,
                            retain_when_above_viewport: true,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _cover(cover_width),
                                const SizedBox(
                                  width: WorkIntroductionHeroStyle.content_gap,
                                ),
                                Expanded(child: title_and_author),
                              ],
                            ),
                          ),
                          ..._supporting_content(context, compact_actions),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.overlap > 0)
                Positioned(
                  // 相邻背景的分数像素边缘会分别抗锯齿，露出一行头图底色。
                  // 只扩展绘制，不改变海报高度、正文锚点或滚动进度。
                  bottom: -WorkIntroductionHeroStyle.surface_paint_overlap,
                  left: 0,
                  right: 0,
                  height:
                      widget.overlap +
                      WorkIntroductionHeroStyle.surface_paint_overlap,
                  child: DecoratedBox(
                    key: const ValueKey('work_introduction_surface'),
                    decoration: BoxDecoration(
                      color: surface_color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(
                          WorkIntroductionHeroStyle.panel_radius,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _cover(double width) => SizedBox(
    key: const ValueKey('work_introduction_cover'),
    width: width,
    child: AspectRatio(
      aspectRatio: WorkIntroductionHeroStyle.cover_width_to_height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            WorkIntroductionHeroStyle.cover_radius,
          ),
          boxShadow: _light_loading
              ? const []
              : WorkIntroductionHeroStyle.cover_shadows,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            WorkIntroductionHeroStyle.cover_radius,
          ),
          border: Border.all(
            color: _light_loading
                ? ColorConstants.lightTextColor.withValues(alpha: 0.08)
                : WorkIntroductionHeroStyle.cover_border,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            WorkIntroductionHeroStyle.cover_radius,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.cover,
              if (widget.status_label?.trim().isNotEmpty == true)
                Positioned(
                  top: WorkIntroductionHeroStyle.status_margin,
                  bottom: WorkIntroductionHeroStyle.status_margin,
                  left: WorkIntroductionHeroStyle.status_margin,
                  right: WorkIntroductionHeroStyle.status_margin,
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.topEnd,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: math.max(
                            0,
                            width - WorkIntroductionHeroStyle.status_margin * 2,
                          ),
                        ),
                        child: _status_badge(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _status_badge() {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return Container(
      key: widget.status_key ?? const ValueKey('work_hero_status'),
      padding: const EdgeInsets.symmetric(
        horizontal: WorkIntroductionHeroStyle.status_padding_h,
        vertical: WorkIntroductionHeroStyle.status_padding_v,
      ),
      decoration: BoxDecoration(
        color: WorkIntroductionHeroStyle.nav_background,
        borderRadius: BorderRadius.circular(
          WorkIntroductionHeroStyle.status_radius,
        ),
      ),
      child: Text(
        widget.status_label!.trim(),
        softWrap: true,
        style: TextStyle(
          color: WorkIntroductionHeroStyle.status_ink,
          fontSize: cjk
              ? WorkIntroductionHeroStyle.status_size_cjk
              : WorkIntroductionHeroStyle.status_size_alphabetic,
          height: WorkIntroductionHeroStyle.status_line_height,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
        ),
      ),
    );
  }

  Widget _metadata(
    BuildContext context,
    bool cjk,
    bool compact_actions,
    WorkHeroTitleTier tier,
  ) => KeyedSubtree(
    key: _metadata_key,
    child: Column(
      key: const ValueKey('work_introduction_metadata'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkHeroTitleMeasure(
          regular_style: _title_style(cjk, reduced: false),
          reduced_style: _title_style(cjk, reduced: true),
          on_tier_changed: _report_title_tier,
          child: Builder(
            builder: (context) {
              final style = _title_style(
                cjk,
                reduced: tier != WorkHeroTitleTier.regular,
              );
              return widget.title_builder?.call(context, style, true) ??
                  Text(widget.title, style: style);
            },
          ),
        ),
        const SizedBox(height: WorkIntroductionHeroStyle.title_gap),
        widget.metadata_builder(context, true),
        if (compact_actions && widget.actions_builder != null) ...[
          const SizedBox(height: WorkIntroductionHeroStyle.inline_actions_gap),
          _actions(context, compact: true),
        ],
      ],
    ),
  );

  /// 统计始终全宽；只有小字号四行仍放不下时，阅读操作保留在统计下方。
  List<Widget> _supporting_content(
    BuildContext context,
    bool compact_actions,
  ) => [
    if (widget.overflow_builder != null) ...[
      const SizedBox(height: WorkIntroductionHeroStyle.overflow_gap),
      WindowReservedRegionPadding(
        mode: WindowReservedRegionPaddingMode.heading,
        retain_when_above_viewport: true,
        child: KeyedSubtree(
          key: const ValueKey('work_introduction_overflow'),
          child: widget.overflow_builder!(context, true),
        ),
      ),
    ],
    if (widget.genres_builder != null) ...[
      const SizedBox(height: WorkIntroductionHeroStyle.genres_gap),
      WindowReservedRegionPadding(
        mode: WindowReservedRegionPaddingMode.heading,
        retain_when_above_viewport: true,
        child: KeyedSubtree(
          key: const ValueKey('work_introduction_genres'),
          child: widget.genres_builder!(context, true),
        ),
      ),
    ],
    if (!compact_actions && widget.actions_builder != null) ...[
      const SizedBox(height: WorkIntroductionHeroStyle.metadata_actions_gap),
      _actions(context, compact: false),
    ],
  ];

  Widget _actions(BuildContext context, {required bool compact}) {
    // 身份键放在两种外部宽度约束之内，迁移时保留按钮及其焦点/加载子树。
    final content = KeyedSubtree(
      key: _actions_key,
      child: KeyedSubtree(
        key: const ValueKey('work_introduction_actions'),
        child: widget.actions_builder!(context, true, compact),
      ),
    );
    return compact
        ? Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: WorkIntroductionHeroStyle.inline_actions_max_width,
              ),
              child: content,
            ),
          )
        : WindowReservedRegionPadding(
            mode: WindowReservedRegionPaddingMode.heading,
            retain_when_above_viewport: true,
            child: content,
          );
  }

  TextStyle _title_style(bool cjk, {required bool reduced}) => TextStyle(
    color: _light_loading
        ? ColorConstants.lightTextColor
        : ColorConstants.whiteColor,
    fontFamily: cjk ? null : 'Georgia',
    fontFamilyFallback: cjk ? null : const ['Times New Roman', 'serif'],
    shadows: _light_loading
        ? const []
        : WorkIntroductionHeroStyle.title_shadows,
    fontSize: reduced
        ? cjk
              ? WorkIntroductionHeroStyle.reduced_title_size_cjk
              : WorkIntroductionHeroStyle.reduced_title_size_alphabetic
        : cjk
        ? WorkIntroductionHeroStyle.title_size_cjk
        : WorkIntroductionHeroStyle.title_size_alphabetic,
    height: cjk
        ? WorkIntroductionHeroStyle.title_height_cjk
        : WorkIntroductionHeroStyle.title_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
  );

  Widget _navigation(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback on_tap,
  }) => IconButton(
    tooltip: label,
    onPressed: on_tap,
    style: IconButton.styleFrom(
      foregroundColor: _light_loading
          ? ColorConstants.lightTextColor
          : ColorConstants.whiteColor,
      backgroundColor: _light_loading
          ? ColorConstants.lightTextColor.withValues(alpha: 0.06)
          : WorkIntroductionHeroStyle.nav_background,
      minimumSize: const Size.square(WorkIntroductionHeroStyle.nav_size),
      maximumSize: const Size.square(WorkIntroductionHeroStyle.nav_size),
    ),
    icon: Icon(icon, size: WorkIntroductionHeroStyle.nav_icon_size),
  );
}
