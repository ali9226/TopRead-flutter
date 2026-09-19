// ignore_for_file: non_constant_identifier_names

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/components/paragraph_comment_composer/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' show Get, Inst;

import 'api.dart';
import 'logic.dart';
import 'style.dart';
import 'widgets/actions.dart';
import 'widgets/comment_item.dart';
import 'widgets/input_bar.dart';

export 'style.dart';

/// 长短篇共用的段评详情弹窗，调用方只传段落、配色及计数回调。
///
/// 视觉风格与小说主评论弹窗保持一致：相同的圆角、拖拽把手、标题栏布局。
class ParagraphCommentDetailSheet extends StatefulWidget {
  final int paragraph_id;
  final String paragraph_text;
  final int initial_comment_count;
  final bool is_dark;
  final bool is_cjk;
  final ValueChanged<int>? on_comment_count_changed;
  final ParagraphCommentRepository repository;
  final Future<bool> Function()? ensure_authenticated;

  const ParagraphCommentDetailSheet({
    super.key,
    required this.paragraph_id,
    required this.paragraph_text,
    required this.initial_comment_count,
    required this.is_dark,
    required this.is_cjk,
    this.on_comment_count_changed,
    this.repository = const ParagraphCommentRepository(),
    this.ensure_authenticated,
  });

  /// 拖动、遮罩或系统返回关闭时也返回最近一次服务器确认的评论总数。
  static Future<int?> show({
    required BuildContext context,
    required int paragraph_id,
    required String paragraph_text,
    required int initial_comment_count,
    required bool is_dark,
    required bool is_cjk,
    ValueChanged<int>? on_comment_count_changed,
  }) async {
    int latest_count = initial_comment_count;
    final int? result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParagraphCommentDetailSheet(
        paragraph_id: paragraph_id,
        paragraph_text: paragraph_text,
        initial_comment_count: initial_comment_count,
        is_dark: is_dark,
        is_cjk: is_cjk,
        on_comment_count_changed: (count) {
          latest_count = count;
          on_comment_count_changed?.call(count);
        },
      ),
    );
    return result ?? latest_count;
  }

  @override
  State<ParagraphCommentDetailSheet> createState() => _ParagraphCommentDetailSheetState();
}

class _ParagraphCommentDetailSheetState extends State<ParagraphCommentDetailSheet> {
  late final ParagraphCommentSheetLogic _logic;
  final ScrollController _scroll_controller = ScrollController();
  bool _opening_composer = false;

  bool get _is_active => mounted && _logic.is_active;

  @override
  void initState() {
    super.initState();
    _logic = ParagraphCommentSheetLogic(
      paragraph_id: widget.paragraph_id,
      initial_comment_count: widget.initial_comment_count,
      repository: widget.repository,
      ensure_authenticated: _authenticate,
      on_comment_count_changed: widget.on_comment_count_changed,
      on_error: (error) {
        if (!_is_active) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      },
    );
    _logic.load_comments();
  }

  Future<bool> _authenticate() => widget.ensure_authenticated?.call() ??
      showLoginRequiredDialog(title: tr('paragraph_comment.login_required'));

  /// 回复与新段评均复用同一个带图片、表情的编辑器。
  Future<void> _open_composer([ParagraphComment? reply]) async {
    if (!_is_active || _opening_composer || _logic.is_mutating) return;
    _opening_composer = true;
    try {
      if (!await _authenticate() || !mounted || !_logic.is_active) return;
      await show_paragraph_comment_composer(
        context,
        quote: reply == null ? widget.paragraph_text : '${reply.user_name}: ${reply.content}',
        is_dark: widget.is_dark,
        on_send: (content, images) => _logic.submit(
          content: content, images: images, parent_id: reply?.id,
        ),
      );
    } finally {
      _opening_composer = false;
    }
  }

  Future<void> _show_actions(ParagraphComment comment) async {
    if (!_is_active) return;
    final int user_id = Get.isRegistered<UserInformation>()
        ? Get.find<UserInformation>().userInfo.value?.id ?? 0 : 0;
    final String? action = await show_paragraph_comment_actions(
      context: context,
      is_owner: user_id > 0 && comment.user_id == user_id,
      is_dark: widget.is_dark,
      is_cjk: widget.is_cjk,
    );
    if (!mounted || !_logic.is_active) return;
    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: comment.content));
        if (mounted && _logic.is_active) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(tr('paragraph_comment.copied'))),
          );
        }
      case 'reply':
        await _open_composer(comment);
      case 'delete':
        final bool confirmed = await confirm_paragraph_comment_delete(
          context: context, is_dark: widget.is_dark, is_cjk: widget.is_cjk,
        );
        if (confirmed && _is_active) await _logic.delete_comment(comment.id);
    }
  }

  @override
  void dispose() {
    _logic.dispose();
    _scroll_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<int>(
    onPopInvokedWithResult: (did_pop, _) {
      if (did_pop) _logic.deactivate();
    },
    child: ListenableBuilder(
      listenable: _logic,
      builder: (context, _) => Material(
        color: ParagraphCommentSheetStyle.surface(widget.is_dark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ParagraphCommentSheetStyle.sheet_radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * ParagraphCommentSheetStyle.height_ratio,
          child: Column(children: [
            _build_header(),
            Expanded(child: _build_list()),
            ParagraphCommentInputBar(
              is_dark: widget.is_dark,
              is_cjk: widget.is_cjk,
              is_busy: _logic.is_mutating,
              on_compose: _open_composer,
            ),
          ]),
        ),
      ),
    ),
  );

  /// 构建标题栏，与小说主评论弹窗保持一致的布局。
  Widget _build_header() {
    final Color title_color = widget.is_dark
        ? ParagraphCommentSheetStyle.title(widget.is_dark)
        : ParagraphCommentSheetStyle.title(widget.is_dark);
    final Color secondary_color = ParagraphCommentSheetStyle.secondary(widget.is_dark);
    final Color divider_color = ParagraphCommentSheetStyle.divider(widget.is_dark);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: divider_color, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽把手，与其他底部弹窗保持一致。
          BottomSheetDragHandle(is_dark: widget.is_dark),
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 标题 + 评论数。
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            tr('paragraph_comment.title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: widget.is_cjk ? 17 : 15,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                              color: title_color,
                            ),
                          ),
                        ),
                        if (_logic.comment_count > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${_logic.comment_count}',
                            style: TextStyle(
                              fontSize: widget.is_cjk ? 17 : 15,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                              color: secondary_color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 关闭按钮，使用与小说主评论一致的 SVG 图标。
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_logic.comment_count),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: SvgIcon(
                          name: 'close',
                          width: 18,
                          height: 18,
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
    );
  }

  Widget _build_list() {
    if (_logic.is_loading) return const Center(child: CircularProgressIndicator());
    if (_logic.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ParagraphCommentSheetStyle.horizontal_padding),
          child: _logic.load_error != null
              ? TextButton(
                  onPressed: _logic.load_comments,
                  style: ParagraphCommentSheetStyle.button(
                    is_dark: widget.is_dark, is_cjk: widget.is_cjk,
                  ),
                  child: Text(tr('comment.load_error_desc')),
                )
              : Text(tr('comment.empty'), textAlign: TextAlign.center,
                  style: ParagraphCommentSheetStyle.text(
                    is_dark: widget.is_dark, is_cjk: widget.is_cjk, secondary: true,
                  )),
        ),
      );
    }
    return ListView.separated(
      controller: _scroll_controller,
      padding: const EdgeInsets.symmetric(
        horizontal: ParagraphCommentSheetStyle.horizontal_padding,
        vertical: ParagraphCommentSheetStyle.vertical_padding,
      ),
      itemCount: _logic.comments.length + (_logic.has_more ? 1 : 0),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: ParagraphCommentSheetStyle.divider(widget.is_dark),
      ),
      itemBuilder: (context, index) => index == _logic.comments.length
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                key: const ValueKey('paragraph_load_more'),
                onPressed: _logic.is_loading_more ? null : () => _logic.load_comments(load_more: true),
                style: ParagraphCommentSheetStyle.button(
                  is_dark: widget.is_dark, is_cjk: widget.is_cjk,
                ),
                child: Text(tr(_logic.is_loading_more ? 'common.loading' : 'paragraph_comment.load_more')),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ParagraphCommentItem(
                key: ValueKey('paragraph_comment_${_logic.comments[index].id}'),
                comment: _logic.comments[index],
                logic: _logic,
                is_dark: widget.is_dark,
                is_cjk: widget.is_cjk,
                on_reply: _open_composer,
                on_actions: _show_actions,
              ),
            ),
    );
  }
}
