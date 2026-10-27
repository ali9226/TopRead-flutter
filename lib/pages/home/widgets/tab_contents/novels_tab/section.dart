// ignore_for_file: non_constant_identifier_names

import 'package:app/models/novel_discovery.dart';
import 'package:app/pages/novel_discovery/style.dart';
import 'package:app/pages/novel_discovery/widgets/discovery_grid/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 每个分类独立换批，封面不加额外外壳；底部操作条只承担两个清晰入口。
class NovelsHomeSection extends StatelessWidget {
  const NovelsHomeSection({
    super.key,
    required this.section,
    required this.revision,
    required this.shuffling,
    required this.on_shuffle,
    required this.on_more,
    this.error,
    this.on_open,
  });

  final NovelDiscoverySection section;
  final int revision;
  final bool shuffling;
  final String? error;
  final VoidCallback on_shuffle;
  final VoidCallback on_more;
  final ValueChanged<NovelDiscoveryItem>? on_open;

  @override
  Widget build(BuildContext context) {
    final dark = NovelDiscoveryStyle.is_dark(context);
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : NovelsTabStyle.batch_duration;
    return Padding(
      padding: const EdgeInsets.only(bottom: NovelsTabStyle.section_gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              NovelDiscoveryStyle.category_name(context, section.category),
              key: ValueKey('novels_home_heading_${section.id}'),
              style: TextStyle(
                color: NovelDiscoveryStyle.ink(context),
                fontSize: cjk
                    ? NovelsTabStyle.heading_size_cjk
                    : NovelsTabStyle.heading_size_alphabetic,
                height: cjk
                    ? NovelsTabStyle.heading_height_cjk
                    : NovelsTabStyle.heading_height_alphabetic,
                fontWeight: NovelsTabStyle.heading_weight,
              ),
            ),
          ),
          const SizedBox(height: NovelsTabStyle.heading_gap),
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topStart,
              children: [...previous, ?current],
            ),
            child: NovelDiscoveryGrid(
              key: ValueKey('novels_home_batch_${section.id}_$revision'),
              items: section.items
                  .take(NovelsTabStyle.section_item_count)
                  .toList(),
              on_open: on_open,
            ),
          ),
          const SizedBox(height: NovelsTabStyle.actions_top_gap),
          Material(
            color: NovelsTabStyle.actions_background(dark),
            borderRadius: BorderRadius.circular(NovelsTabStyle.actions_radius),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: _SectionAction(
                    key: ValueKey('novels_home_more_${section.id}'),
                    label: easy.tr('novel_discovery.discovery_more'),
                    icon: Icons.grid_view_rounded,
                    dark: dark,
                    cjk: cjk,
                    on_tap: on_more,
                  ),
                ),
                ColoredBox(
                  color: NovelsTabStyle.actions_divider(dark),
                  child: const SizedBox(
                    width: NovelsTabStyle.action_divider_width,
                    height: NovelsTabStyle.action_divider_height,
                  ),
                ),
                Expanded(
                  child: _SectionAction(
                    key: ValueKey('novels_home_shuffle_${section.id}'),
                    label: easy.tr('novel_discovery.discovery_shuffle'),
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
                      top: NovelsTabStyle.error_gap,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        easy.tr('novel_discovery.discovery_shuffle_error'),
                        key: ValueKey(
                          'novels_home_shuffle_error_${section.id}',
                        ),
                        style: TextStyle(
                          color: NovelDiscoveryStyle.muted(context),
                          fontSize: cjk
                              ? NovelsTabStyle.error_size_cjk
                              : NovelsTabStyle.error_size_alphabetic,
                          height: NovelsTabStyle.action_label_height,
                          fontWeight: NovelsTabStyle.action_weight,
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
    final foreground = NovelsTabStyle.actions_foreground(dark);
    return Semantics(
      button: true,
      enabled: on_tap != null,
      label: loading ? '${easy.tr('novel_discovery.loading')} $label' : label,
      excludeSemantics: true,
      child: InkWell(
        onTap: on_tap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: NovelsTabStyle.action_min_height,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NovelsTabStyle.action_padding_h,
              vertical: NovelsTabStyle.action_padding_v,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: NovelsTabStyle.action_icon_size,
                  child: loading && !MediaQuery.disableAnimationsOf(context)
                      ? CircularProgressIndicator(
                          color: foreground,
                          strokeWidth: NovelsTabStyle.loading_stroke_width,
                        )
                      : Icon(
                          loading ? Icons.hourglass_top_rounded : icon,
                          color: foreground,
                          size: NovelsTabStyle.action_icon_size,
                        ),
                ),
                const SizedBox(width: NovelsTabStyle.action_icon_gap),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: cjk
                          ? NovelsTabStyle.action_label_size_cjk
                          : NovelsTabStyle.action_label_size_alphabetic,
                      height: NovelsTabStyle.action_label_height,
                      fontWeight: NovelsTabStyle.action_weight,
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
