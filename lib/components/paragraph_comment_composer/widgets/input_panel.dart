// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import 'package:app/components/comment_list/widgets/emoji_panel.dart';

import '../logic.dart';

/// 位于系统键盘后方的实体面板，键盘圆角透出时也只显示弹窗底色。
class ParagraphCommentInputPanel extends StatelessWidget {
  const ParagraphCommentInputPanel({
    required this.logic,
    required this.is_dark,
    required this.height,
    required this.safe_bottom,
    super.key,
  });

  final ParagraphCommentComposerLogic logic;
  final bool is_dark;
  final double height;
  final double safe_bottom;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey<String>('paragraph_comment_input_panel'),
    height: height,
    width: double.infinity,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 面板的网格间隙属于编辑区域，不能冒泡为关闭弹窗的点击。
      onTap: () {},
      child: logic.input_panel.paint_emoji
          ? ClipRect(
              child: SingleChildScrollView(
                primary: false,
                padding: EdgeInsets.only(bottom: safe_bottom),
                child: CommentEmojiPanel(
                  is_dark: is_dark,
                  on_emoji_selected: logic.insert_emoji,
                ),
              ),
            )
          : null,
    ),
  );
}
