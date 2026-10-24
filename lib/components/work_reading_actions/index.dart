import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'style.dart';
import 'widgets/favorite_button.dart';
import 'widgets/primary_button.dart';

/// 阅读主操作与收藏共用一行，极窄窗口下分行保留完整文字与触控区域。
/// [continuing] 仅接受调用方从真实历史/当前阅读位置得出的状态。
class WorkReadingActions extends StatelessWidget {
  const WorkReadingActions({
    super.key,
    this.on_read,
    this.on_favorite,
    this.can_read = true,
    this.continuing = false,
    this.favorited = false,
    this.favorite_loading = false,
    this.on_hero = true,
    this.is_dark = false,
    this.compact = false,
    this.read_key,
    this.favorite_key,
  });

  final VoidCallback? on_read;
  final VoidCallback? on_favorite;
  final bool can_read;
  final bool continuing;
  final bool favorited;
  final bool favorite_loading;
  final bool on_hero;
  final bool is_dark;

  /// 标题列中的作者下方操作使用紧凑尺寸，由调用方显式决定布局。
  final bool compact;
  final Key? read_key;
  final Key? favorite_key;

  @override
  Widget build(BuildContext context) {
    if (on_read == null && on_favorite == null) return const SizedBox.shrink();
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final read_label = tr(
      !can_read
          ? 'comics.unavailable'
          : continuing
          ? 'comics.continue_reading'
          : 'comics.start_reading',
    );
    final favorite_label = tr(
      favorited ? 'comics.collected' : 'comics.collect',
    );
    final primary = on_read == null
        ? null
        : WorkPrimaryReadingButton(
            label: read_label,
            on_pressed: on_read!,
            enabled: can_read,
            cjk: cjk,
            on_hero: on_hero,
            is_dark: is_dark,
            compact: compact,
            action_key: read_key,
          );
    final favorite = on_favorite == null
        ? null
        : WorkFavoriteButton(
            label: favorite_label,
            on_pressed: on_favorite!,
            favorited: favorited,
            loading: favorite_loading,
            on_hero: on_hero,
            is_dark: is_dark,
            compact: compact,
            action_key: favorite_key,
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (primary != null &&
            favorite != null &&
            constraints.maxWidth <
                (compact
                    ? WorkReadingActionsStyle.compact_min_inline_width
                    : WorkReadingActionsStyle.min_inline_width)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              primary,
              SizedBox(
                height: compact
                    ? WorkReadingActionsStyle.compact_gap
                    : WorkReadingActionsStyle.gap,
              ),
              Align(alignment: AlignmentDirectional.centerEnd, child: favorite),
            ],
          );
        }
        return Row(
          children: [
            if (primary != null) Expanded(child: primary),
            if (primary != null && favorite != null)
              SizedBox(
                width: compact
                    ? WorkReadingActionsStyle.compact_gap
                    : WorkReadingActionsStyle.gap,
              ),
            ?favorite,
          ],
        );
      },
    );
  }
}
