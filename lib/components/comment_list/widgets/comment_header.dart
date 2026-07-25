import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 微信视频号式评论面板标题栏。
class CommentHeader extends StatelessWidget {
  final bool is_dark;
  final int comment_count;
  final VoidCallback on_close;
  final VoidCallback? on_drag_start;

  const CommentHeader({
    super.key,
    required this.is_dark,
    required this.comment_count,
    required this.on_close,
    this.on_drag_start,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final Color title_color = is_dark
        ? CommentListStyle.title_dark_color
        : CommentListStyle.title_light_color;
    final Color secondary_color = is_dark
        ? CommentListStyle.secondary_dark_color
        : CommentListStyle.secondary_light_color;
    final Color divider_color = is_dark
        ? CommentListStyle.divider_dark_color
        : CommentListStyle.divider_light_color;
    final String translated_count_title = tr(
      'comment.count_label',
      namedArgs: <String, String>{'count': '$comment_count'},
    );
    final String title = comment_count <= 0
        ? tr('comment.title')
        : translated_count_title == 'comment.count_label'
        ? '$comment_count ${tr('comment.title')}'
        : translated_count_title;

    return Listener(
      // Listener 不参与手势竞技，只在用户触碰顶部时先关闭键盘；之后的纵向移动
      // 仍完整交给系统 BottomSheet 处理，避免输入框 Overlay 与面板同时移动。
      onPointerDown: (_) => on_drag_start?.call(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: divider_color, width: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BottomSheetDragHandle(is_dark: is_dark),
            SizedBox(
              height: CommentListStyle.header_row_height,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: CommentListStyle.header_horizontal_padding,
                  right: CommentListStyle.header_right_padding,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: is_cjk
                              ? CommentListStyle.header_title_font_size_cjk
                              : CommentListStyle
                                    .header_title_font_size_alphabetic,
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w500,
                          ),
                          color: title_color,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: on_close,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: CommentListStyle.close_button_size,
                        height: CommentListStyle.close_button_size,
                        child: Center(
                          child: SvgIcon(
                            name: 'close',
                            width: CommentListStyle.close_icon_size,
                            height: CommentListStyle.close_icon_size,
                            color: secondary_color,
                            animateColor: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
