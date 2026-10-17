// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy show tr;
import 'package:flutter/material.dart';
import 'package:app/pages/comics/detail/style.dart';

/// 简介始终保留同一份正文，展开时只动画裁剪高度与遮罩，避免maxLines切换闪跳。
class ComicDetailAboutSection extends StatefulWidget {
  final String description;
  final bool is_dark;
  final bool is_cjk;
  const ComicDetailAboutSection({
    super.key,
    required this.description,
    required this.is_dark,
    required this.is_cjk,
  });
  @override
  State<ComicDetailAboutSection> createState() =>
      _ComicDetailAboutSectionState();
}

class _ComicDetailAboutSectionState extends State<ComicDetailAboutSection> {
  bool _expanded = false;
  @override
  void didUpdateWidget(covariant ComicDetailAboutSection old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.description != widget.description) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.description.trim();
    if (text.isEmpty) return const SizedBox.shrink();
    final body_style = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        color: ComicDetailStyle.muted(context),
        fontSize: ComicDetailStyle.pick_font_size(
          is_cjk: widget.is_cjk,
          cjk: ComicDetailStyle.description_font_size_cjk,
          alphabetic: ComicDetailStyle.description_font_size_alphabetic,
        ),
        height: ComicDetailStyle.pick_font_size(
          is_cjk: widget.is_cjk,
          cjk: ComicDetailStyle.description_height_cjk,
          alphabetic: ComicDetailStyle.description_height_alphabetic,
        ),
        fontWeight: ComicDetailStyle.weight_regular,
      ),
    );
    final duration = ComicDetailStyle.animation_duration(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = TextPainter(
          text: TextSpan(text: text, style: body_style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final collapsed = TextPainter(
          text: TextSpan(text: text, style: body_style),
          maxLines: ComicDetailStyle.description_collapsed_lines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.localeOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final full_height = full.height;
        final collapsed_height = collapsed.height;
        final can_expand = full_height > collapsed_height;
        full.dispose();
        collapsed.dispose();
        final card_bg = ComicDetailStyle.card_background(widget.is_dark);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TweenAnimationBuilder<double>(
              key: const ValueKey('comic_about_size'),
              tween: Tween(
                begin: collapsed_height,
                end: _expanded || !can_expand ? full_height : collapsed_height,
              ),
              duration: duration,
              curve: Curves.easeInOutCubic,
              builder: (context, visible_height, child) => SizedBox(
                height: visible_height,
                width: constraints.maxWidth,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Text(text, style: body_style),
                    ),
                    if (can_expand)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: ComicDetailStyle.description_fade_height,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            key: const ValueKey('comic_about_fade'),
                            opacity: _expanded ? 0 : 1,
                            duration: duration,
                            curve: Curves.easeInOutCubic,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    card_bg.withValues(alpha: 0),
                                    card_bg.withValues(alpha: 0.94),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (can_expand)
              Padding(
                padding: const EdgeInsets.only(
                  top: ComicDetailStyle.description_toggle_spacing,
                ),
                child: Center(
                  child: Semantics(
                    button: true,
                    expanded: _expanded,
                    child: TextButton(
                      key: const ValueKey('comic_about_toggle'),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        foregroundColor: ComicDetailStyle.ink(context),
                        minimumSize: const Size(
                          ComicDetailStyle.touch_target,
                          ComicDetailStyle.touch_target,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              easy.tr(
                                _expanded
                                    ? 'comics.show_less'
                                    : 'comics.show_more',
                              ),
                              style: ComicDetailStyle.label_style(
                                context,
                                widget.is_cjk,
                                color: ComicDetailStyle.ink(context),
                                strong: true,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            key: const ValueKey('comic_about_arrow'),
                            turns: _expanded ? 0.5 : 0,
                            duration: duration,
                            curve: Curves.easeInOutCubic,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size:
                                  ComicDetailStyle.description_toggle_icon_size,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
