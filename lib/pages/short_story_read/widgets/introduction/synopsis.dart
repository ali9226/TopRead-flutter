import 'package:app/components/expandable_synopsis/text_viewport.dart';
import 'package:app/components/expandable_synopsis/toggle_button.dart';
import 'package:app/components/work_hero_glass_surface/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 短篇简介放在封面已有玻璃面板内；正文只读，由双箭头控制两行展开。
class ShortStorySynopsis extends StatefulWidget {
  const ShortStorySynopsis({
    super.key,
    required this.description,
    required this.is_dark,
    this.on_hero = true,
  });

  final String description;
  final bool is_dark;
  final bool on_hero;

  @override
  State<ShortStorySynopsis> createState() => _ShortStorySynopsisState();
}

class _ShortStorySynopsisState extends State<ShortStorySynopsis> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant ShortStorySynopsis old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.description != widget.description) _expanded = false;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final description = widget.description.trim();
    if (description.isEmpty) return const SizedBox.shrink();
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final text_style = TextStyle(
      color: ShortStoryIntroductionStyle.synopsis_foreground,
      fontSize: cjk
          ? ShortStoryIntroductionStyle.synopsis_size_cjk
          : ShortStoryIntroductionStyle.synopsis_size_alphabetic,
      height: cjk
          ? ShortStoryIntroductionStyle.synopsis_height_cjk
          : ShortStoryIntroductionStyle.synopsis_height_alphabetic,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );
    return WorkHeroGlassSurface(
      on_hero: widget.on_hero,
      is_dark: widget.is_dark,
      surface_key: const ValueKey('short_story_about_glass_surface'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ShortStoryIntroductionStyle.synopsis_padding_h,
          vertical: ShortStoryIntroductionStyle.synopsis_padding_v,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(
                text: description,
                style: DefaultTextStyle.of(context).style.merge(text_style),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              locale: Localizations.maybeLocaleOf(context),
              maxLines: ShortStoryIntroductionStyle.synopsis_collapsed_lines,
            )..layout(maxWidth: constraints.maxWidth);
            final can_expand = painter.didExceedMaxLines;
            painter.dispose();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        easy.tr('read.intro_title'),
                        key: const ValueKey('short_story_about_header'),
                        style: TextStyle(
                          color: ShortStoryIntroductionStyle.synopsis_heading,
                          fontSize: cjk
                              ? ShortStoryIntroductionStyle
                                    .synopsis_title_size_cjk
                              : ShortStoryIntroductionStyle
                                    .synopsis_title_size_alphabetic,
                          height:
                              ShortStoryIntroductionStyle.synopsis_title_height,
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (can_expand)
                      SynopsisToggleButton(
                        expanded: _expanded,
                        label: easy.tr(
                          _expanded ? 'comics.show_less' : 'comics.show_more',
                        ),
                        key_prefix: 'short_story_about',
                        on_pressed: _toggle,
                        compact: true,
                        is_dark: widget.is_dark,
                        foreground_color:
                            ShortStoryIntroductionStyle.synopsis_foreground,
                      ),
                  ],
                ),
                const SizedBox(
                  height: ShortStoryIntroductionStyle.synopsis_heading_gap,
                ),
                ExpandableSynopsisTextViewport(
                  description: description,
                  expanded: _expanded,
                  style: text_style,
                  on_collapse: _toggle,
                  key_prefix: 'short_story_about',
                  collapsed_lines:
                      ShortStoryIntroductionStyle.synopsis_collapsed_lines,
                  fade_line_ratio:
                      ShortStoryIntroductionStyle.synopsis_fade_line_ratio,
                  transparent_fade: true,
                  collapse_on_text_tap: false,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
