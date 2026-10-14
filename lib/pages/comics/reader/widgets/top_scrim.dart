// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'package:app/pages/comics/reader/style.dart';
import 'package:app/pages/comics/style.dart';

/// 阅读页顶部渐变遮罩工具条：返回、章节标题、目录、评论。
///
/// 用细渐变替代厚重玻璃面板，控件悬浮在画布之上，沉浸感更强。
class ComicReaderTopScrim extends StatelessWidget {
  /// 章节标题。
  final String title;

  /// 返回回调。
  final VoidCallback on_back;

  /// 打开目录回调。
  final VoidCallback on_open_catalog;

  /// 打开评论回调。
  final VoidCallback on_comments;

  const ComicReaderTopScrim({
    super.key,
    required this.title,
    required this.on_back,
    required this.on_open_catalog,
    required this.on_comments,
  });

  @override
  Widget build(BuildContext context) {
    final double top_padding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: top_padding + ComicReaderStyle.top_bar_height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black.withValues(alpha: ComicReaderStyle.top_scrim_opacity),
              Colors.black.withValues(
                alpha: ComicReaderStyle.top_scrim_opacity * 0.45,
              ),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: top_padding),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ComicReaderStyle.top_padding_h,
            ),
            child: Row(
              children: <Widget>[
                _ScrimIconButton(
                  icon: Icons.arrow_back_rounded,
                  semantic_label: easy.tr('comics.cancel'),
                  onTap: on_back,
                ),
                const SizedBox(width: ComicReaderStyle.top_button_gap),
                Expanded(
                  child: Text(
                    title,
                    maxLines: ComicReaderStyle.title_max_lines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ComicReaderStyle.pick_font_size(
                        is_cjk: ComicsStyle.is_cjk(context),
                        cjk: ComicReaderStyle.title_font_size_cjk,
                        alphabetic:
                            ComicReaderStyle.title_font_size_alphabetic,
                      ),
                      fontWeight: ComicReaderStyle.weight_medium,
                    ),
                  ),
                ),
                const SizedBox(width: ComicReaderStyle.top_button_gap),
                _ScrimIconButton(
                  icon: Icons.format_list_numbered_rounded,
                  semantic_label: easy.tr('comics.chapters'),
                  onTap: on_open_catalog,
                ),
                _ScrimIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  semantic_label: easy.tr('comics.chapter_comments'),
                  onTap: on_comments,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 遮罩上的图标按钮，带无障碍标签。
class _ScrimIconButton extends StatelessWidget {
  /// 图标数据。
  final IconData icon;

  /// 无障碍标签。
  final String semantic_label;

  /// 点击回调。
  final VoidCallback onTap;

  const _ScrimIconButton({
    required this.icon,
    required this.semantic_label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: semantic_label,
    child: Semantics(
      button: true,
      label: semantic_label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox.square(
          dimension: ComicReaderStyle.top_icon_target,
          child: Icon(
            icon,
            size: ComicReaderStyle.top_icon_size,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
