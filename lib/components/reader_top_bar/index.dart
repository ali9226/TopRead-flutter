// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/action_button.dart';
import 'package:app/components/reader_top_bar/style.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 长篇与漫画的同一顶部布局；标题仅在调用方原本提供时显示。
class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.is_dark,
    required this.on_back,
    required this.on_favorite,
    required this.on_share,
    this.title,
    this.favorited = false,
    this.favorite_loading = false,
    this.loading = false,
    this.show_share = true,
    this.favorite_icon,
    this.share_icon,
  });
  final bool is_dark;
  final VoidCallback on_back;
  final VoidCallback? on_favorite;
  final VoidCallback? on_share;
  final String? title;
  final bool favorited;
  final bool favorite_loading;
  final bool loading;
  final bool show_share;

  /// 漫画可复用短篇图形，其余调用方继续使用默认心形与单色分享。
  final Widget? favorite_icon;
  final Widget? share_icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ReaderTopBarStyle.background(is_dark),
      border: Border(
        bottom: BorderSide(
          color: ReaderTopBarStyle.border(is_dark),
          width: 0.5,
        ),
      ),
    ),
    child: Padding(
      padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
      child: WindowContentLayout(
        expand_height: false,
        child: SizedBox(
          height: ReaderTopBarStyle.toolbar_height(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ReaderTopBarStyle.horizontal_padding,
            ),
            child: Row(
              children: [
                ReaderTopBarAction(
                  asset: 'right',
                  reverse: true,
                  elastic: false,
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  color: ReaderTopBarStyle.foreground(is_dark),
                  on_pressed: on_back,
                ),
                Expanded(
                  child: title == null || title!.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ReaderTopBarStyle.foreground(is_dark),
                            fontSize: ReaderTopBarStyle.title_size(context),
                            height: ReaderTopBarStyle.title_line_height,
                            fontWeight: ReaderTopBarStyle.medium,
                          ),
                        ),
                ),
                ReaderTopBarAction(
                  icon_widget: favorite_icon,
                  icon: favorite_icon != null
                      ? null
                      : favorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: tr(favorited ? 'comics.collected' : 'comics.collect'),
                  color: ColorConstants.dangerColor,
                  selected: favorited,
                  loading: loading || favorite_loading,
                  on_pressed: on_favorite,
                ),
                if (show_share)
                  ReaderTopBarAction(
                    asset: 'share',
                    icon_widget: share_icon,
                    label: tr('comics.share'),
                    color: ReaderTopBarStyle.secondary(is_dark),
                    loading: loading,
                    on_pressed: on_share,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
