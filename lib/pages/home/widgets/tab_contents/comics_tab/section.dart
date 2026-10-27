// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/models/comics_discovery.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/discovery_grid/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 每个分类独立换批，封面不加额外外壳；底部操作条只承担两个清晰入口。
class ComicsHomeSection extends StatelessWidget {
  const ComicsHomeSection({
    super.key,
    required this.section,
    required this.revision,
    required this.shuffling,
    required this.on_shuffle,
    required this.on_more,
    this.error,
    this.on_open,
  });

  final ComicDiscoverySection section;
  final int revision;
  final bool shuffling;
  final String? error;
  final VoidCallback on_shuffle;
  final VoidCallback on_more;
  final ValueChanged<ComicItem>? on_open;

  @override
  Widget build(BuildContext context) {
    final dark = ComicsStyle.is_dark(context);
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : ComicsTabStyle.batch_duration;
    return Padding(
      padding: const EdgeInsets.only(bottom: ComicsTabStyle.section_gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              ComicsStyle.category_name(context, section.category),
              key: ValueKey('comics_home_heading_${section.id}'),
              style: TextStyle(
                color: ComicsStyle.ink(context),
                fontSize: cjk
                    ? ComicsTabStyle.heading_size_cjk
                    : ComicsTabStyle.heading_size_alphabetic,
                height: cjk
                    ? ComicsTabStyle.heading_height_cjk
                    : ComicsTabStyle.heading_height_alphabetic,
                fontWeight: ComicsTabStyle.heading_weight,
              ),
            ),
          ),
          const SizedBox(height: ComicsTabStyle.heading_gap),
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topStart,
              children: [...previous, ?current],
            ),
            child: ComicDiscoveryGrid(
              key: ValueKey('comics_home_batch_${section.id}_$revision'),
              items: section.items
                  .take(ComicsTabStyle.section_item_count)
                  .toList(),
              on_open: on_open,
            ),
          ),
          const SizedBox(height: ComicsTabStyle.actions_top_gap),
          Material(
            color: ComicsTabStyle.actions_background(dark),
            borderRadius: BorderRadius.circular(ComicsTabStyle.actions_radius),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: _SectionAction(
                    key: ValueKey('comics_home_more_${section.id}'),
                    label: easy.tr('comics.discovery_more'),
                    icon: Icons.grid_view_rounded,
                    dark: dark,
                    cjk: cjk,
                    on_tap: on_more,
                  ),
                ),
                ColoredBox(
                  color: ComicsTabStyle.actions_divider(dark),
                  child: const SizedBox(
                    width: ComicsTabStyle.action_divider_width,
                    height: ComicsTabStyle.action_divider_height,
                  ),
                ),
                Expanded(
                  child: _SectionAction(
                    key: ValueKey('comics_home_shuffle_${section.id}'),
                    label: easy.tr('comics.discovery_shuffle'),
                    icon: Icons.refresh_rounded,
                    dark: dark,
                    cjk: cjk,
                    loading: shuffling,
                    on_tap: shuffling ? null : on_shuffle,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: duration,
            alignment: AlignmentDirectional.topStart,
            curve: Curves.easeOutCubic,
            child: error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(
                      top: ComicsTabStyle.error_gap,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        easy.tr('comics.discovery_shuffle_error'),
                        key: ValueKey(
                          'comics_home_shuffle_error_${section.id}',
                        ),
                        style: TextStyle(
                          color: ComicsStyle.muted(context),
                          fontSize: cjk
                              ? ComicsTabStyle.error_size_cjk
                              : ComicsTabStyle.error_size_alphabetic,
                          height: ComicsTabStyle.action_label_height,
                          fontWeight: ComicsTabStyle.action_weight,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  const _SectionAction({
    super.key,
    required this.label,
    required this.icon,
    required this.dark,
    required this.cjk,
    required this.on_tap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final bool dark;
  final bool cjk;
  final bool loading;
  final VoidCallback? on_tap;

  @override
  Widget build(BuildContext context) {
    final foreground = ComicsTabStyle.actions_foreground(dark);
    return Semantics(
      button: true,
      enabled: on_tap != null,
      label: loading ? '${easy.tr('comics.loading')} $label' : label,
      excludeSemantics: true,
      child: InkWell(
        onTap: on_tap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ComicsTabStyle.action_min_height,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ComicsTabStyle.action_padding_h,
              vertical: ComicsTabStyle.action_padding_v,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: ComicsTabStyle.action_icon_size,
                  child: loading && !MediaQuery.disableAnimationsOf(context)
                      ? CircularProgressIndicator(
                          color: foreground,
                          strokeWidth: ComicsTabStyle.loading_stroke_width,
                        )
                      : Icon(
                          loading ? Icons.hourglass_top_rounded : icon,
                          color: foreground,
                          size: ComicsTabStyle.action_icon_size,
                        ),
                ),
                const SizedBox(width: ComicsTabStyle.action_icon_gap),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: cjk
                          ? ComicsTabStyle.action_label_size_cjk
                          : ComicsTabStyle.action_label_size_alphabetic,
                      height: ComicsTabStyle.action_label_height,
                      fontWeight: ComicsTabStyle.action_weight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
