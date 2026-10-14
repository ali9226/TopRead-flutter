// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';

/// 底部操作栏：收藏切换 + 开始/继续阅读主按钮。
class ComicDetailActionBar extends StatelessWidget {
  /// 是否已收藏。
  final bool collected;

  /// 收藏请求是否进行中。
  final bool collecting;

  /// 是否可开始阅读（存在可读章节）。
  final bool can_read;

  /// 是否为继续阅读状态。
  final bool can_continue;

  /// 收藏按钮点击回调。
  final VoidCallback on_collect;

  /// 阅读按钮点击回调。
  final VoidCallback on_read;

  const ComicDetailActionBar({
    super.key,
    required this.collected,
    required this.collecting,
    required this.can_read,
    required this.can_continue,
    required this.on_collect,
    required this.on_read,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_dark = ComicsStyle.is_dark(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ComicDetailStyle.action_bar_padding_h,
          vertical: ComicDetailStyle.action_bar_padding_v,
        ),
        decoration: BoxDecoration(
          color: is_dark
              ? ComicDetailStyle.content_card_dark
              : ComicDetailStyle.content_card_light,
          border: Border(top: BorderSide(color: ComicsStyle.outline(context))),
        ),
        child: Row(
          children: <Widget>[
            /// 收藏切换：图标 + 文案，已收藏时主色填充。
            _CollectButton(
              collected: collected,
              collecting: collecting,
              is_dark: is_dark,
              onTap: on_collect,
            ),
            const SizedBox(width: ComicDetailStyle.action_bar_spacing),

            /// 主行动按钮：开始 / 继续阅读。
            Expanded(
              child: _PrimaryReadButton(
                enabled: can_read,
                can_continue: can_continue,
                onTap: on_read,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 收藏按钮。
class _CollectButton extends StatelessWidget {
  /// 是否已收藏。
  final bool collected;

  /// 请求是否进行中。
  final bool collecting;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback onTap;

  const _CollectButton({
    required this.collected,
    required this.collecting,
    required this.is_dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = collected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
        : is_dark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF161C28).withValues(alpha: 0.04);
    final Color foreground = collected
        ? Theme.of(context).colorScheme.primary
        : is_dark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF3A4150);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(
        ComicDetailStyle.action_bar_button_radius,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          ComicDetailStyle.action_bar_button_radius,
        ),
        onTap: collecting ? null : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: ComicDetailStyle.action_bar_secondary_min_width,
            maxWidth: ComicDetailStyle.action_bar_secondary_max_width,
          ),
          child: SizedBox(
            height: ComicDetailStyle.action_bar_button_height,
            child: collecting
                ? const Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        collected
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        size: 20,
                        color: foreground,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tr(collected ? 'comics.collected' : 'comics.collect'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: foreground,
                            fontSize:
                                ComicDetailStyle.action_bar_secondary_font_size,
                            fontWeight: ComicDetailStyle.weight_medium,
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

/// 主阅读按钮：渐变填充 + 轻微阴影。
class _PrimaryReadButton extends StatelessWidget {
  /// 是否可点击。
  final bool enabled;

  /// 是否显示「继续阅读」。
  final bool can_continue;

  /// 点击回调。
  final VoidCallback onTap;

  const _PrimaryReadButton({
    required this.enabled,
    required this.can_continue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(
      ComicDetailStyle.action_bar_button_radius,
    ),
    clipBehavior: Clip.antiAlias,
    color: enabled
        ? ColorConstants.themeColor
        : const Color(0xFFA8B0BE),
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: ComicDetailStyle.action_bar_button_height,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tr(
                  can_continue
                      ? 'comics.continue_reading'
                      : 'comics.start_reading',
                ),
                maxLines: 1,
                style: TextStyle(
                  color: ColorConstants.lightTextColor,
                  fontSize: ComicDetailStyle.action_bar_primary_font_size,
                  fontWeight: ComicDetailStyle.weight_medium,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
