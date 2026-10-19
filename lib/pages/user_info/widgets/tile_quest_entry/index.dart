// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/router/router_util.dart';
import 'style.dart';

/// 无需登录即可进入的独立小游戏入口；不依赖个人中心业务状态。
class TileQuestEntry extends StatelessWidget {
  const TileQuestEntry({super.key, required this.is_dark, this.on_open});

  final bool is_dark;
  final VoidCallback? on_open;

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final Color ink = is_dark
        ? TileQuestEntryStyle.dark_ink
        : TileQuestEntryStyle.light_ink;
    return Padding(
      padding: TileQuestEntryStyle.margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TileQuestEntryStyle.radius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: is_dark
                  ? TileQuestEntryStyle.dark_colors
                  : TileQuestEntryStyle.light_colors,
            ),
            borderRadius: BorderRadius.circular(TileQuestEntryStyle.radius),
            border: Border.all(
              color: TileQuestEntryStyle.accent.withValues(alpha: 0.18),
            ),
          ),
          child: InkWell(
            key: const ValueKey('tile_quest_entry'),
            onTap: on_open ?? () => routerUtil(path: '/tile_quest'),
            child: Padding(
              padding: TileQuestEntryStyle.padding,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      TileQuestEntryStyle.icon_radius,
                    ),
                    child: Image.asset(
                      'assets/img/tile_quest/app_icon.png',
                      width: TileQuestEntryStyle.icon_size,
                      height: TileQuestEntryStyle.icon_size,
                      fit: BoxFit.contain,
                      cacheWidth: 192,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: TileQuestEntryStyle.content_gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tile Quest',
                          style: TextStyle(
                            color: ink,
                            fontSize: is_cjk
                                ? TileQuestEntryStyle.title_size_cjk
                                : TileQuestEntryStyle.title_size_alphabetic,
                            fontWeight: TileQuestEntryStyle.title_weight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tile_quest.entry_subtitle'.tr(),
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.72),
                            fontWeight: TileQuestEntryStyle.subtitle_weight,
                            fontSize: is_cjk
                                ? TileQuestEntryStyle.subtitle_size_cjk
                                : TileQuestEntryStyle.subtitle_size_alphabetic,
                            height: is_cjk
                                ? TileQuestEntryStyle.line_height_cjk
                                : TileQuestEntryStyle.line_height_alphabetic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: TileQuestEntryStyle.action_size,
                    height: TileQuestEntryStyle.action_size,
                    decoration: BoxDecoration(
                      color: TileQuestEntryStyle.accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
