// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/hero/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 仅透传阅读页已有的开始阅读与收藏动作，不自行创建业务状态。
class ReadIntroductionActions extends StatelessWidget {
  const ReadIntroductionActions({
    super.key,
    this.on_read,
    this.on_favorite,
    this.favorited = false,
    this.favorite_loading = false,
  });
  final VoidCallback? on_read;
  final VoidCallback? on_favorite;
  final bool favorited;
  final bool favorite_loading;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (on_read != null)
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ReadIntroductionHeroStyle.action_radius,
              ),
              gradient: const LinearGradient(
                colors: ReadIntroductionHeroStyle.action_gradient,
              ),
              border: Border.all(color: const Color(0xFFFFF7B0)),
              boxShadow: const [
                BoxShadow(color: Color(0x44FFD021), blurRadius: 18),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('novel_hero_read'),
                onTap: on_read,
                borderRadius: BorderRadius.circular(
                  ReadIntroductionHeroStyle.action_radius,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: ReadIntroductionHeroStyle.action_height,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ReadIntroductionHeroStyle.action_padding,
                      vertical:
                          ReadIntroductionHeroStyle.action_vertical_padding,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: ReadIntroductionHeroStyle.action_icon,
                          color: Color(0xFF242428),
                        ),
                        const SizedBox(
                          width: ReadIntroductionHeroStyle.action_gap,
                        ),
                        Expanded(
                          child: Text(
                            tr('comics.start_reading'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF242428),
                              fontSize:
                                  ReadIntroductionHeroStyle.action_font_size,
                              height:
                                  ReadIntroductionHeroStyle.action_text_height,
                              fontWeight: FontConfig.adjustedWeight(
                                FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (on_favorite != null) ...[
        if (on_read != null)
          const SizedBox(width: ReadIntroductionHeroStyle.action_gap),
        Semantics(
          toggled: favorited,
          child: IconButton(
            key: const ValueKey('novel_hero_favorite'),
            onPressed: favorite_loading ? null : on_favorite,
            tooltip: tr(favorited ? 'comics.collected' : 'comics.collect'),
            constraints: const BoxConstraints(
              minHeight: ReadIntroductionHeroStyle.action_height,
              minWidth: ReadIntroductionHeroStyle.action_height,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.3),
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                favorited
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey(favorited),
                size: ReadIntroductionHeroStyle.action_icon,
                color: ColorConstants.dangerColor,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
