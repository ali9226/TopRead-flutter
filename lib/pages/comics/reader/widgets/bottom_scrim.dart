// ignore_for_file: non_constant_identifier_names

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:app/pages/comics/reader/style.dart';

/// 阅读页底部渐变遮罩控制条：上一章 / 页码胶囊 / 下一章。
///
/// 顶部叠一条细进度条，底部渐变遮罩让控件悬浮于画面之上。
class ComicReaderBottomScrim extends StatelessWidget {
  /// 当前页码（从 0 开始）。
  final int page_index;

  /// 总页数。
  final int page_count;

  /// 是否有上一章。
  final bool has_previous_chapter;

  /// 是否有下一章。
  final bool has_next_chapter;

  /// 上一章点击回调。
  final VoidCallback on_previous_chapter;

  /// 下一章点击回调。
  final VoidCallback on_next_chapter;

  const ComicReaderBottomScrim({
    super.key,
    required this.page_index,
    required this.page_count,
    required this.has_previous_chapter,
    required this.has_next_chapter,
    required this.on_previous_chapter,
    required this.on_next_chapter,
  });

  @override
  Widget build(BuildContext context) {
    final double bottom_padding = MediaQuery.paddingOf(context).bottom;
    final String page_label = page_count > 0
        ? '${page_index + 1} / $page_count'
        : '';

    return SizedBox(
      height: ComicReaderStyle.bottom_bar_height + bottom_padding,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          /// 底部渐变遮罩。
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: ComicReaderStyle.bottom_scrim_opacity * 0.5,
                    ),
                    Colors.black.withValues(
                      alpha: ComicReaderStyle.bottom_scrim_opacity,
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 控件行。
          Positioned(
            left: ComicReaderStyle.bottom_padding_h,
            right: ComicReaderStyle.bottom_padding_h,
            bottom: bottom_padding,
            height: ComicReaderStyle.bottom_bar_height,
            child: Row(
              children: <Widget>[
                _NavButton(
                  icon: Icons.skip_previous_rounded,
                  enabled: has_previous_chapter,
                  onTap: on_previous_chapter,
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ComicReaderStyle.page_pill_padding_h,
                        vertical: ComicReaderStyle.page_pill_padding_v,
                      ),
                      decoration: BoxDecoration(
                        color: ComicReaderStyle.pill_background,
                        borderRadius: BorderRadius.circular(
                          ComicReaderStyle.page_pill_radius,
                        ),
                      ),
                      child: Text(
                        page_label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ComicReaderStyle.page_font_size,
                          fontWeight: ComicReaderStyle.weight_medium,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _NavButton(
                  icon: Icons.skip_next_rounded,
                  enabled: has_next_chapter,
                  onTap: on_next_chapter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 章节切换图标按钮。
class _NavButton extends StatelessWidget {
  /// 图标数据。
  final IconData icon;

  /// 是否可点击。
  final bool enabled;

  /// 点击回调。
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: enabled ? onTap : null,
    child: SizedBox.square(
      dimension: ComicReaderStyle.nav_button_size,
      child: Icon(
        icon,
        size: ComicReaderStyle.nav_icon_size,
        color: enabled ? Colors.white : ComicReaderStyle.disabled_icon,
      ),
    ),
  );
}
