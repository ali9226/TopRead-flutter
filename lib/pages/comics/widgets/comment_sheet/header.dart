// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/comics/widgets/comment_sheet/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 共用小说面板拖动条；清晰标题、独立计数与轻量关闭按钮形成紧凑层级。
class ComicCommentSheetHeader extends StatelessWidget {
  const ComicCommentSheetHeader({
    super.key,
    required this.is_dark,
    required this.count,
    required this.on_close,
    required this.on_drag_start,
  });
  final bool is_dark;
  final int count;
  final VoidCallback on_close;
  final VoidCallback on_drag_start;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => on_drag_start(),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ComicCommentSheetStyle.line(is_dark),
            width: ComicCommentSheetStyle.border_width,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetDragHandle(is_dark: is_dark),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ComicCommentSheetStyle.horizontal_padding,
              0,
              ComicCommentSheetStyle.horizontal_padding - LayoutConfig.space_8,
              ComicCommentSheetStyle.header_bottom_padding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tr('comment.title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ComicCommentSheetStyle.foreground(is_dark),
                      fontSize: ComicCommentSheetStyle.localized_size(
                        context,
                        ComicCommentSheetStyle.header_title_cjk,
                        ComicCommentSheetStyle.header_title_alphabetic,
                      ),
                      fontWeight: ComicCommentSheetStyle.medium,
                    ),
                  ),
                ),
                const SizedBox(width: ComicCommentSheetStyle.header_gap),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ComicCommentSheetStyle.count_padding_h,
                    vertical: ComicCommentSheetStyle.count_padding_v,
                  ),
                  decoration: BoxDecoration(
                    color: ComicCommentSheetStyle.soft_surface(is_dark),
                    borderRadius: BorderRadius.circular(
                      ComicCommentSheetStyle.close_surface,
                    ),
                  ),
                  child: Text(
                    count > 999 ? '999+' : '$count',
                    style: TextStyle(
                      color: ComicCommentSheetStyle.secondary(is_dark),
                      fontSize: ComicCommentSheetStyle.localized_size(
                        context,
                        ComicCommentSheetStyle.count_size_cjk,
                        ComicCommentSheetStyle.count_size_alphabetic,
                      ),
                      fontWeight: ComicCommentSheetStyle.medium,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('comic_comment_sheet_close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: on_close,
                  constraints: const BoxConstraints.tightFor(
                    width: ComicCommentSheetStyle.close_target,
                    height: ComicCommentSheetStyle.close_target,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Container(
                    width: ComicCommentSheetStyle.close_surface,
                    height: ComicCommentSheetStyle.close_surface,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ComicCommentSheetStyle.soft_surface(is_dark),
                    ),
                    child: Center(
                      child: SvgIcon(
                        name: 'close',
                        width: ComicCommentSheetStyle.close_icon,
                        height: ComicCommentSheetStyle.close_icon,
                        color: ComicCommentSheetStyle.secondary(is_dark),
                        animateColor: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
