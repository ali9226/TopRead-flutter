// ignore_for_file: non_constant_identifier_names

import 'package:app/components/comment_list/style.dart';
import 'package:app/pages/comics/widgets/comment_sheet/header.dart';
import 'package:app/pages/comics/widgets/comment_sheet/style.dart';
import 'package:app/pages/comics/comments/index.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:flutter/material.dart';

/// TODO 漫画与长篇阅读器使用相同的底部评论面板、拖动标题、输入框和动画。
/// 作品评论省略 chapter_id；指定章节时保持后端现有的独立章评范围。
Future<int?> show_comic_comment_sheet(
  BuildContext context, {
  required int comic_id,
  int? chapter_id,
  ValueChanged<int>? on_count_changed,
  ComicCommentsLogic? controller,
}) async {
  int? changed_count;
  final result = await showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    requestFocus: false,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.none,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(
        context,
      ).width.clamp(0, ComicCommentSheetStyle.max_width),
    ),
    barrierColor: Colors.black.withValues(
      alpha: CommentListStyle.sheet_barrier_alpha,
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(
        milliseconds: CommentListStyle.sheet_transition_duration_ms,
      ),
      reverseDuration: Duration(
        milliseconds: CommentListStyle.sheet_transition_duration_ms,
      ),
    ),
    builder: (context) => ComicCommentSheet(
      comic_id: comic_id,
      chapter_id: chapter_id,
      controller: controller,
      on_count_changed: (count) {
        changed_count = count;
        on_count_changed?.call(count);
      },
    ),
  );
  return result ?? changed_count;
}

/// TODO 面板只组合公共评论 UI，数据请求与发送继续由现有漫画控制器负责。
class ComicCommentSheet extends StatefulWidget {
  const ComicCommentSheet({
    super.key,
    required this.comic_id,
    this.chapter_id,
    this.on_count_changed,
    this.controller,
  });

  final int comic_id;
  final int? chapter_id;
  final ValueChanged<int>? on_count_changed;

  /// TODO 可注入控制器复用会话或进行真实 UI 回归；由调用方持有时不在面板内释放。
  final ComicCommentsLogic? controller;

  @override
  State<ComicCommentSheet> createState() => _ComicCommentSheetState();
}

class _ComicCommentSheetState extends State<ComicCommentSheet> {
  late final ComicCommentsLogic _logic =
      widget.controller ??
      ComicCommentsLogic(
        comic_id: widget.comic_id,
        chapter_id: widget.chapter_id,
      );

  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = _logic.comment_count;
  }

  /// TODO 子页面在帧末通知，避免首次加载时标题的兄弟节点在构建阶段被标脏。
  void _on_count_changed(int count) {
    if (_count != count) setState(() => _count = count);
    widget.on_count_changed?.call(count);
  }

  void _dismiss_input() => FocusManager.instance.primaryFocus?.unfocus();

  void _close() {
    _dismiss_input();
    Navigator.pop(context, _logic.page > 0 ? _logic.comment_count : null);
  }

  @override
  void dispose() {
    if (widget.controller == null) _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark
        ? CommentListStyle.sheet_dark_bg
        : CommentListStyle.sheet_light_bg;
    return RepaintBoundary(
      child: Container(
        key: const ValueKey<String>('comic_comment_sheet'),
        height:
            MediaQuery.sizeOf(context).height *
            CommentListStyle.max_height_ratio,
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ComicCommentSheetStyle.radius),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: dark
                    ? CommentListStyle.sheet_shadow_alpha_dark
                    : CommentListStyle.sheet_shadow_alpha_light,
              ),
              blurRadius: CommentListStyle.sheet_shadow_blur,
              offset: const Offset(0, CommentListStyle.sheet_shadow_offset_y),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ComicCommentSheetStyle.radius),
          ),
          child: Column(
            children: [
              ComicCommentSheetHeader(
                is_dark: dark,
                count: _count,
                on_close: _close,
                on_drag_start: _dismiss_input,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _dismiss_input,
                  behavior: HitTestBehavior.translucent,
                  child: ComicCommentsPage(
                    comic_id: widget.comic_id,
                    chapter_id: widget.chapter_id,
                    controller: _logic,
                    embedded: true,
                    in_sheet: true,
                    on_total_changed: _on_count_changed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
