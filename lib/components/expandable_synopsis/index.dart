import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';
import './style.dart';
import './text_viewport.dart';

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
  });
  final String description;
  final String title;
  final String empty_description;
  final String expand_label;
  final String collapse_label;
  final bool is_dark;
  final bool initial_expanded;
  final double? font_size;
  final String key_prefix;

  @override
  State<ExpandableSynopsis> createState() => _ExpandableSynopsisState();
}

class _ExpandableSynopsisState extends State<ExpandableSynopsis> {
  late bool _expanded = widget.initial_expanded;

  @override
  void didUpdateWidget(covariant ExpandableSynopsis old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.description != widget.description ||
        old_widget.initial_expanded != widget.initial_expanded) {
      _expanded = widget.initial_expanded;
    }
  }

  void _toggle() => setState(() => _expanded = !_expanded);

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

    return Material(
      color: widget.is_dark
          ? ExpandableSynopsisStyle.background_dark
          : ExpandableSynopsisStyle.background_light,
      borderRadius: BorderRadius.circular(ExpandableSynopsisStyle.radius),
      child: Padding(
        padding: const EdgeInsets.all(ExpandableSynopsisStyle.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: ValueKey(
                '${widget.key_prefix}_${_expanded ? 'collapse' : 'header'}',
              ),
              onTap: _toggle,
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
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w600,
                          ),
                          color: title_color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ExpandableSynopsisStyle.title_gap),
            ExpandableSynopsisTextViewport(
              description: description,
              expanded: _expanded,
              on_collapse: _toggle,
              key_prefix: widget.key_prefix,
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
            const SizedBox(height: ExpandableSynopsisStyle.action_gap),
            Center(
              child: Semantics(
                button: true,
                expanded: _expanded,
                label: label,
                child: IconButton(
                  key: ValueKey('${widget.key_prefix}_toggle'),
                  onPressed: _toggle,
                  tooltip: label,
                  constraints: const BoxConstraints.tightFor(
                    width: ExpandableSynopsisStyle.action_extent,
                    height: ExpandableSynopsisStyle.action_extent,
                  ),
                  icon: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : ExpandableSynopsisStyle.expand_duration,
                    curve: Curves.easeInOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: ExpandableSynopsisStyle.toggle_size,
                      color: title_color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
