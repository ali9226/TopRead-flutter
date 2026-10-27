import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:flutter/material.dart';
import './style.dart';
import './text_viewport.dart';
import './toggle_button.dart';
import './compact_heading.dart';
import './body_layout.dart';

/// 跨作品类型复用的简介卡片；标题位置固定，正文支持连续裁切展开和收起。
class ExpandableSynopsis extends StatefulWidget {
  const ExpandableSynopsis({
    super.key,
    required this.description,
    required this.title,
    required this.empty_description,
    required this.expand_label,
    required this.collapse_label,
    required this.is_dark,
    this.initial_expanded = false,
    this.font_size,
    this.key_prefix = 'synopsis',
    this.embedded = false,
    this.surface_color,
    this.collapsed_lines = ExpandableSynopsisStyle.collapsed_lines,
    this.compact_toggle = false,
  }) : assert(collapsed_lines > 0);
  final String description;
  final String title;
  final String empty_description;
  final String expand_label;
  final String collapse_label;
  final bool is_dark;
  final bool initial_expanded;
  final double? font_size;
  final String key_prefix;

  /// 作品详情在同一正文纸面内排版，目录等独立卡片仍使用默认样式。
  final bool embedded;

  /// 明确提供实际纸面色，供短篇等不同深色背景与截断渐变保持一致。
  /// 未指定时沿用详情纸面或独立卡片的现有昼夜配色。
  final Color? surface_color;

  /// 不同作品类型可选择预览行数，默认保留小说的四行预览。
  final int collapsed_lines;

  /// 漫画使用无背景的小尺寸双箭头，保留完整的透明触控区域。
  final bool compact_toggle;

  @override
  State<ExpandableSynopsis> createState() => _ExpandableSynopsisState();
}

class _ExpandableSynopsisState extends State<ExpandableSynopsis> {
  late bool _expanded = widget.initial_expanded;

  /// 仅保存当前真实行宽下是否需要展开入口，不缓存任何文字或容器高度。
  bool? _embedded_can_expand;
  int _embedded_measure_generation = 0;

  @override
  void didUpdateWidget(covariant ExpandableSynopsis old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.description != widget.description ||
        old_widget.initial_expanded != widget.initial_expanded ||
        old_widget.collapsed_lines != widget.collapsed_lines) {
      _expanded = widget.initial_expanded;
      _embedded_can_expand = null;
      _embedded_measure_generation++;
    }
  }

  /// 正文完成局部避让后同步可展开性，让按钮按自身坐标独立布局。
  void _report_embedded_overflow(bool can_expand) {
    final generation = ++_embedded_measure_generation;
    if (_embedded_can_expand == can_expand) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _embedded_measure_generation ||
          _embedded_can_expand == can_expand) {
        return;
      }
      setState(() => _embedded_can_expand = can_expand);
    });
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  /// 连续正文模式按文字自然布局；仅超过预览行数时提供展开操作。
  Widget _embedded_content(BuildContext context, bool cjk, String description) {
    final color = widget.is_dark
        ? ExpandableSynopsisStyle.embedded_text_dark
        : ExpandableSynopsisStyle.embedded_text_light;
    final title_color = widget.is_dark
        ? ExpandableSynopsisStyle.title_color_dark
        : ExpandableSynopsisStyle.title_color_light;
    final text_style = TextStyle(
      fontSize:
          widget.font_size ??
          (cjk
              ? ExpandableSynopsisStyle.embedded_font_size_cjk
              : ExpandableSynopsisStyle.embedded_font_size_alphabetic),
      height: cjk
          ? ExpandableSynopsisStyle.embedded_line_height_cjk
          : ExpandableSynopsisStyle.embedded_line_height_alphabetic,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      color: color,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: description,
            style: DefaultTextStyle.of(context).style.merge(text_style),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          maxLines: widget.collapsed_lines,
        )..layout(maxWidth: constraints.maxWidth);
        final can_expand = painter.didExceedMaxLines;
        painter.dispose();
        final label = _expanded ? widget.collapse_label : widget.expand_label;
        final show_toggle = _embedded_can_expand ?? can_expand;
        final title = Text(
          widget.title,
          // 展开只替换展示定位键，保留InkWell及其FocusNode的身份。
          key: ValueKey(
            '${widget.key_prefix}_${_expanded ? 'collapse' : 'header'}',
          ),
          style: TextStyle(
            fontSize: cjk
                ? ExpandableSynopsisStyle.embedded_title_size_cjk
                : ExpandableSynopsisStyle.embedded_title_size_alphabetic,
            height: ExpandableSynopsisStyle.embedded_title_height,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            color: title_color,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            WindowReservedRegionPadding(
              mode: WindowReservedRegionPaddingMode.heading,
              retain_when_above_viewport: true,
              child: InkWell(
                onTap: show_toggle && !widget.compact_toggle ? _toggle : null,
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(
                  ExpandableSynopsisStyle.interaction_overlay,
                ),
                child: widget.compact_toggle
                    ? CompactSynopsisHeading(
                        title: title,
                        key_prefix: widget.key_prefix,
                      )
                    : title,
              ),
            ),
            SizedBox(
              height: widget.compact_toggle
                  ? ExpandableSynopsisStyle.compact_title_gap
                  : ExpandableSynopsisStyle.embedded_title_gap,
            ),
            SynopsisBodyLayout(
              compact: widget.compact_toggle,
              expanded: _expanded,
              body: WindowReservedRegionPadding(
                mode: WindowReservedRegionPaddingMode.heading,
                retain_when_above_viewport: true,
                child: LayoutBuilder(
                  builder: (context, text_constraints) {
                    // 文字按避让后的真实宽度决定是否超过预览行数；按钮不继承正文边距。
                    final text_painter = TextPainter(
                      text: TextSpan(
                        text: description,
                        style: DefaultTextStyle.of(
                          context,
                        ).style.merge(text_style),
                      ),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                      locale: Localizations.maybeLocaleOf(context),
                      maxLines: widget.collapsed_lines,
                    )..layout(maxWidth: text_constraints.maxWidth);
                    final text_can_expand = text_painter.didExceedMaxLines;
                    text_painter.dispose();
                    _report_embedded_overflow(text_can_expand);
                    return ExpandableSynopsisTextViewport(
                      description: description,
                      expanded: _expanded,
                      on_collapse: _toggle,
                      key_prefix: widget.key_prefix,
                      style: text_style,
                      collapsed_lines: widget.collapsed_lines,
                      fade_line_ratio: widget.compact_toggle
                          ? ExpandableSynopsisStyle.compact_fade_line_ratio
                          : ExpandableSynopsisStyle.fade_line_ratio,
                      fade_surface_color:
                          widget.surface_color ??
                          WorkSectionCardStyle.background(widget.is_dark),
                    );
                  },
                ),
              ),
              toggle: !show_toggle
                  ? null
                  : WindowReservedRegionPadding(
                      mode: WindowReservedRegionPaddingMode.heading,
                      retain_when_above_viewport: true,
                      child: Center(
                        child: SynopsisToggleButton(
                          expanded: _expanded,
                          label: label,
                          key_prefix: widget.key_prefix,
                          on_pressed: _toggle,
                          compact: widget.compact_toggle,
                          is_dark: widget.is_dark,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final title_color = widget.is_dark
        ? ExpandableSynopsisStyle.title_color_dark
        : ExpandableSynopsisStyle.title_color_light;
    final label = _expanded ? widget.collapse_label : widget.expand_label;
    final description = widget.description.trim().isEmpty
        ? widget.empty_description
        : widget.description;

    if (widget.embedded) return _embedded_content(context, cjk, description);

    return WorkSectionCard(
      is_dark: widget.is_dark,
      padding: const EdgeInsets.all(ExpandableSynopsisStyle.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey(
              '${widget.key_prefix}_${_expanded ? 'collapse' : 'header'}',
            ),
            onTap: widget.compact_toggle ? null : _toggle,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(
              ExpandableSynopsisStyle.interaction_overlay,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ExpandableSynopsisStyle.action_extent,
              ),
              child: Row(
                children: [
                  Container(
                    width: ExpandableSynopsisStyle.accent_width,
                    height: ExpandableSynopsisStyle.accent_height,
                    decoration: BoxDecoration(
                      color: ExpandableSynopsisStyle.accent_color,
                      borderRadius: BorderRadius.circular(
                        ExpandableSynopsisStyle.accent_radius,
                      ),
                    ),
                  ),
                  const SizedBox(width: ExpandableSynopsisStyle.accent_gap),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: cjk
                            ? ExpandableSynopsisStyle.title_font_size_cjk
                            : ExpandableSynopsisStyle
                                  .title_font_size_alphabetic,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                        color: title_color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ExpandableSynopsisStyle.title_gap),
          SynopsisBodyLayout(
            compact: widget.compact_toggle,
            expanded: _expanded,
            toggle_gap: ExpandableSynopsisStyle.action_gap,
            body: ExpandableSynopsisTextViewport(
              description: description,
              expanded: _expanded,
              on_collapse: _toggle,
              key_prefix: widget.key_prefix,
              collapsed_lines: widget.collapsed_lines,
              fade_line_ratio: widget.compact_toggle
                  ? ExpandableSynopsisStyle.compact_fade_line_ratio
                  : ExpandableSynopsisStyle.fade_line_ratio,
              fade_surface_color:
                  widget.surface_color ??
                  WorkSectionCardStyle.card_background(widget.is_dark),
              style: TextStyle(
                fontSize:
                    widget.font_size ??
                    (cjk
                        ? ExpandableSynopsisStyle.font_size_cjk
                        : ExpandableSynopsisStyle.font_size_alphabetic),
                height: cjk
                    ? ExpandableSynopsisStyle.line_height_cjk
                    : ExpandableSynopsisStyle.line_height_alphabetic,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                color: widget.is_dark
                    ? ExpandableSynopsisStyle.text_color_dark
                    : ExpandableSynopsisStyle.text_color_light,
              ),
            ),
            toggle: Center(
              child: SynopsisToggleButton(
                expanded: _expanded,
                label: label,
                key_prefix: widget.key_prefix,
                on_pressed: _toggle,
                compact: widget.compact_toggle,
                is_dark: widget.is_dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
