import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import 'package:app/stores/device_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/comment_list/widgets/comment_header.dart';
import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/components/comment_list/widgets/comment_input.dart';
import 'package:app/components/comment_list/widgets/comment_skeleton.dart';
import 'package:app/components/no_internet/index.dart';
import 'package:app/components/login_required_dialog/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/api/novel_comment.dart';

/// 评论列表弹窗组件。
///
/// 从屏幕底部滑出的半屏弹窗，展示用户评论列表。
///
/// 功能：
/// - 从后端接口加载评论列表（支持分页）
/// - 展示评论列表（支持嵌套回复）
/// - 底部输入框（主题色发送按钮）
/// - 点赞、回复评论
/// - 骨架屏加载状态
/// - 无网络/加载失败时展示 NoInternet 组件
/// - 兼容日间/夜间模式
///
/// 使用方式：
/// ```dart
/// showCommentSheet(
///   context: context,
///   novel_id: 123,
///   on_close: () => Navigator.pop(context),
/// );
/// ```
class CommentSheet extends StatefulWidget {
  /// 关闭弹窗回调。
  final VoidCallback on_close;

  /// 小说ID（必传，用于请求评论数据）。
  final int novel_id;

  /// 需要定位的评论ID（可选，加载完成后自动滚动到该评论）。
  final int scroll_to_comment_id;

  /// 评论数量发生变化时通知弹窗路由，用于手势下滑关闭时返回最新数量。
  final ValueChanged<int>? on_count_changed;

  const CommentSheet({
    super.key,
    required this.on_close,
    required this.novel_id,
    this.scroll_to_comment_id = 0,
    this.on_count_changed,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

/// 显示评论列表弹窗。
///
/// 使用与目录、设置一致的系统 ModalBottomSheet 路由，支持整张面板上下拖动、
/// 阈值回弹和下滑关闭。真实输入框仍放在根 Overlay 中，因此键盘不会推动面板。
///
/// 返回值：弹窗关闭后的最新评论总数（若无变化返回 null）。
Future<int?> showCommentSheet({
  required BuildContext context,
  required int novel_id,
  required VoidCallback on_close,
  int scroll_to_comment_id = 0,
}) async {
  int? changed_comment_count;
  final int? route_result = await showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    requestFocus: false,
    backgroundColor: Colors.transparent,
    clipBehavior: Clip.none,
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
    builder: (BuildContext sheet_context) {
      return CommentSheet(
        on_close: on_close,
        novel_id: novel_id,
        scroll_to_comment_id: scroll_to_comment_id,
        on_count_changed: (int count) {
          changed_comment_count = count;
        },
      );
    },
  );
  return route_result ?? changed_comment_count;
}

class _CommentSheetState extends State<CommentSheet> {
  /// 评论列表数据。
  List<CommentData> _comments = [];

  /// 滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 输入框焦点节点（用于关闭键盘）。
  final FocusNode _input_focus_node = FocusNode();

  /// 是否有新增评论（用于关闭时返回最新总数）。
  bool _has_new_comments = false;

  /// 加载状态：loading（加载中）、success（加载成功）、error（加载失败）。
  String _load_status = 'loading';

  /// 当前页码。
  int _current_page = 1;

  /// 总评论数。
  int _total_count = 0;

  /// 每页数量。
  final int _page_size = 20;

  /// 是否正在加载更多。
  bool _is_loading_more = false;

  /// 是否还有更多数据。
  bool _has_more = true;

  /// 回复目标评论（用于回复时预填信息）。
  CommentData? _reply_target;

  /// 当前高亮的评论ID（用于闪烁动画，0 表示无高亮）。
  int _highlighted_comment_id = 0;

  @override
  void initState() {
    super.initState();
    // TODO 监听滚动事件，实现上拉加载更多
    _scroll_controller.addListener(_on_scroll);
    // TODO 首次加载评论数据
    _load_comments();
  }

  @override
  void dispose() {
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    _input_focus_node.dispose();
    super.dispose();
  }

  /// 滚动监听，触底时加载更多。
  void _on_scroll() {
    if (!_scroll_controller.hasClients) return;
    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent -
            CommentListStyle.load_more_trigger_distance) {
      _load_more();
    }
  }

  /// 展平嵌套回复树为扁平列表。
  ///
  /// 后端返回的 replies 是嵌套树结构（reply.replies 包含子回复），
  /// 但 UI 的回复区域需要扁平列表。展平后每条回复保留 reply_to_nickname，
  /// 用于显示"A → B"的回复关系。
  List<CommentData> _flatten_replies(List<CommentData> nested_replies) {
    final List<CommentData> flat = [];
    // TODO 构建回复ID -> 昵称的映射，用于推导 reply_to_nickname
    final Map<int, String> nickname_map = {};
    void collect_nicknames(List<CommentData> replies) {
      for (final r in replies) {
        nickname_map[r.id] = r.nickname;
        if (r.replies.isNotEmpty) collect_nicknames(r.replies);
      }
    }

    collect_nicknames(nested_replies);

    // TODO 递归展平
    void flatten(List<CommentData> replies) {
      for (final reply in replies) {
        flat.add(reply);
        if (reply.replies.isNotEmpty) flatten(reply.replies);
      }
    }

    flatten(nested_replies);

    // TODO 为每条回复设置正确的 reply_to_nickname（基于 parent_id）
    return flat.map((reply) {
      // TODO 如果已有 reply_to_nickname（来自后端），保持不变
      if (reply.reply_to_nickname != null) return reply;
      // TODO 通过 parent_id 查找被回复者的昵称
      final parent_nickname = nickname_map[reply.parent_id];
      if (parent_nickname != null && parent_nickname.isNotEmpty) {
        return reply.copy_with(reply_to_nickname: parent_nickname);
      }
      return reply;
    }).toList();
  }

  /// 加载评论列表（首次加载或刷新）。
  Future<void> _load_comments() async {
    setState(() {
      _load_status = 'loading';
      _current_page = 1;
      _has_more = true;
    });

    try {
      // highlight_id 传给后端，由后端将目标评论的顶层父评论排到第一位
      debugPrint('TODO _load_comments: highlight_id=${widget.scroll_to_comment_id}');
      final CommentListResult? result = await inquire_comment_list(
        novel_id: widget.novel_id,
        page: 1,
        page_size: _page_size,
        highlight_id: widget.scroll_to_comment_id,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _load_status = 'error';
        });
        return;
      }

      setState(() {
        _load_status = 'success';
        _comments = result.list.map((CommentData c) {
          if (c.replies.isEmpty) return c;
          return c.copy_with(replies: _flatten_replies(c.replies));
        }).toList();
        _total_count = result.total;
        _has_more = result.list.length >= _page_size;
      });

      // TODO 加载完成后，滚动到顶部（目标评论已置顶）
      if (widget.scroll_to_comment_id > 0) {
        _scroll_to_comment(widget.scroll_to_comment_id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _load_status = 'error';
      });
    }
  }

  /// 滚动到指定评论ID所在的位置，并触发闪烁高亮。
  void _scroll_to_comment(int comment_id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll_controller.hasClients) return;

      // 查找目标评论：先在顶层找，再在回复中找
      int target_index = _comments.indexWhere((c) => c.id == comment_id);
      int reply_offset = 0;

      if (target_index < 0) {
        // 在子回复中查找，记录回复位置偏移
        for (int i = 0; i < _comments.length; i++) {
          final reply_index = _comments[i].replies.indexWhere(
            (r) => r.id == comment_id,
          );
          if (reply_index >= 0) {
            target_index = i;
            reply_offset = reply_index;
            break;
          }
        }
      }

      if (target_index < 0) return;

      // 估算目标位置：主评论高度 + 回复区域内的偏移
      final double main_height =
          CommentListStyle.scroll_to_comment_estimated_item_height;
      final double target_offset =
          target_index * main_height + reply_offset * 48.0;
      final double max_offset = _scroll_controller.position.maxScrollExtent;
      final double offset = target_offset.clamp(0.0, max_offset);

      _scroll_controller
          .animateTo(
        offset,
        duration: const Duration(
          milliseconds:
              CommentListStyle.scroll_to_comment_animation_duration_ms,
        ),
        curve: Curves.easeOutCubic,
      )
          .then((_) {
        // 滚动完成后触发闪烁高亮
        if (mounted) {
          setState(() => _highlighted_comment_id = comment_id);
          Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _highlighted_comment_id = 0);
          });
        }
      });
    });
  }

  /// 加载更多评论（翻页）。
  Future<void> _load_more() async {
    if (_is_loading_more || !_has_more || _load_status != 'success') return;

    setState(() {
      _is_loading_more = true;
    });

    try {
      final CommentListResult? result = await inquire_comment_list(
        novel_id: widget.novel_id,
        page: _current_page + 1,
        page_size: _page_size,
      );

      if (!mounted) return;

      if (result != null) {
        // TODO 展平每条评论的嵌套回复为扁平列表
        final new_comments = result.list.map((CommentData c) {
          if (c.replies.isEmpty) return c;
          return c.copy_with(replies: _flatten_replies(c.replies));
        }).toList();
        setState(() {
          _current_page = result.page;
          _comments = [..._comments, ...new_comments];
          _has_more = result.list.length >= _page_size;
        });
      }
    } catch (e) {
      // TODO 加载更多失败时不提示，静默处理
    } finally {
      if (mounted) {
        setState(() {
          _is_loading_more = false;
        });
      }
    }
  }

  /// 处理关闭弹窗。
  ///
  /// 有新增评论时返回最新评论总数，否则返回 null。
  void _handle_close() {
    final int? result = _has_new_comments ? _total_count : null;
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  /// 设置回复目标。
  void _set_reply_target(CommentData? comment) {
    setState(() {
      _reply_target = comment;
    });
  }

  /// 输入框是否仍处于本轮交互中。
  ///
  /// iOS 在焦点释放后键盘还会继续执行一段关闭动画，因此除了焦点，也要检查
  /// viewInsets。只要任一状态仍然存在，点击评论就应当完成关闭，而不是立刻重开。
  bool _is_input_active() {
    if (_input_focus_node.hasFocus) return true;
    final view = View.maybeOf(context);
    if (view == null || view.devicePixelRatio == 0) return false;
    final double keyboard_height =
        view.viewInsets.bottom / view.devicePixelRatio;
    return keyboard_height > CommentListStyle.keyboard_close_hide_threshold;
  }

  /// 关闭输入框并退出回复模式。
  void _dismiss_input() {
    _input_focus_node.unfocus();
    if (_reply_target != null) {
      _set_reply_target(null);
    }
  }

  /// 处理回复操作。
  void _handle_reply(CommentData comment) {
    // 输入框已打开或键盘仍在关闭动画中时，本次点击只负责收起。避免 iOS 同一
    // 次点击先 unfocus、随后又 requestFocus，造成键盘下滑后立即回弹。
    if (_is_input_active()) {
      _dismiss_input();
      return;
    }

    _set_reply_target(comment);
    // TODO 等当前帧渲染完成后再聚焦，避免键盘弹出时的卡顿
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _input_focus_node.requestFocus();
    });
  }

  /// 处理点赞操作。
  ///
  /// 未登录时弹出登录提示弹窗，已登录时调用点赞接口。
  Future<void> _handle_like(CommentData comment) async {
    // TODO 登录检查
    final bool is_logged_in = await showLoginRequiredDialog(
      title: tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;

    // TODO 先乐观更新UI
    final bool new_liked = !comment.is_liked;
    final int new_count = new_liked
        ? comment.like_count + 1
        : (comment.like_count > 0 ? comment.like_count - 1 : 0);

    _update_comment_like_state(comment.id, new_liked, new_count);

    // TODO 调用接口
    final CommentLikeResult? result = await like_comment(
      comment_id: comment.id,
    );

    if (!mounted) return;

    if (result == null) {
      // TODO 接口失败，回滚UI状态
      _update_comment_like_state(
        comment.id,
        comment.is_liked,
        comment.like_count,
      );
      return;
    }

    // TODO 用接口返回的真实数据更新UI
    _update_comment_like_state(comment.id, result.like, result.like_count);

    // TODO 提示点赞/取消点赞成功
    showBottomTip(
      tr(result.like ? 'like_tip.add_success' : 'like_tip.remove_success'),
    );
  }

  /// 更新评论的点赞状态（在列表中查找并更新）。
  void _update_comment_like_state(
    int comment_id,
    bool is_liked,
    int like_count,
  ) {
    setState(() {
      _comments = _comments.map((CommentData c) {
        if (c.id == comment_id) {
          return c.copy_with(is_liked: is_liked, like_count: like_count);
        }
        // TODO 检查子回复
        if (c.replies.isNotEmpty) {
          final updated_replies = c.replies.map((CommentData reply) {
            if (reply.id == comment_id) {
              return reply.copy_with(
                is_liked: is_liked,
                like_count: like_count,
              );
            }
            return reply;
          }).toList();
          return c.copy_with(replies: updated_replies);
        }
        return c;
      }).toList();
    });
  }

  /// 处理发送评论（乐观更新）。
  ///
  /// 先在本地插入评论，立即展示给用户，后端请求静默进行。
  /// 失败时回滚本地数据。
  Future<void> _handle_send(String content) async {
    // 输入组件发送后会立刻关闭并取消回复状态，因此必须在首次 await 前保存目标。
    final CommentData? reply_target = _reply_target;
    final int parent_id = reply_target?.id ?? 0;
    final bool is_reply_to_nested =
        reply_target != null && reply_target.parent_id > 0;

    // TODO 登录检查（在乐观更新之前）
    final bool is_logged_in = await showLoginRequiredDialog(
      title: tr('short_story_read.login_required'),
    );
    if (!is_logged_in) return;

    if (!mounted) return;

    // TODO 获取当前用户信息，用于构建本地评论
    final user_info = Get.find<UserInformation>().userInfo.value;
    if (user_info == null) return;

    // TODO 使用负数临时ID，避免与后端真实ID冲突
    final int temp_id = -DateTime.now().millisecondsSinceEpoch;
    final String now_str = DateTime.now().toString().substring(0, 19);

    // TODO 构建本地评论，立即插入列表
    CommentData comment_to_insert = CommentData(
      id: temp_id,
      user_id: user_info.id,
      avatar: user_info.avatarUrl,
      nickname: user_info.name,
      content: content,
      time: now_str,
      parent_id: parent_id,
      reply_to_nickname: is_reply_to_nested ? reply_target.nickname : null,
    );

    // TODO 清除回复目标
    _set_reply_target(null);

    // TODO 提示评论成功
    showBottomTip(tr('comment.send_success'));

    // TODO 立即插入本地列表
    setState(() {
      if (parent_id > 0) {
        // TODO 回复评论：递归查找目标评论，追加到其 replies 列表
        CommentData? try_add_reply(CommentData c) {
          if (c.id == parent_id) {
            return c.copy_with(replies: [...c.replies, comment_to_insert]);
          }
          if (c.replies.isNotEmpty) {
            for (int i = 0; i < c.replies.length; i++) {
              final updated = try_add_reply(c.replies[i]);
              if (updated != null) {
                final new_replies = [...c.replies];
                new_replies[i] = updated;
                return c.copy_with(replies: new_replies);
              }
            }
          }
          return null;
        }

        _comments = _comments.map((CommentData c) {
          return try_add_reply(c) ?? c;
        }).toList();
      } else {
        // TODO 顶层评论：插入到列表顶部
        _comments.insert(0, comment_to_insert);
      }
      _total_count += 1;
      _has_new_comments = true;
    });
    widget.on_count_changed?.call(_total_count);

    // TODO 滚动到顶部，让用户看到新评论
    if (_scroll_controller.hasClients) {
      _scroll_controller.animateTo(
        0,
        duration: const Duration(
          milliseconds: CommentListStyle.scroll_to_top_animation_duration_ms,
        ),
        curve: Curves.easeOut,
      );
    }

    // TODO 后台静默请求后端，失败时回滚本地数据
    add_comment(
      novel_id: widget.novel_id,
      comment_content: content,
      parent_id: parent_id,
    ).then((bool success) {
      if (!success && mounted) {
        // TODO 后端失败，回滚乐观更新
        setState(() {
          _remove_optimistic_comment(_comments, temp_id);
          _total_count -= 1;
        });
        widget.on_count_changed?.call(_total_count);
      }
    });
  }

  /// 递归移除乐观更新失败的临时评论。
  List<CommentData> _remove_optimistic_comment(
    List<CommentData> comments,
    int temp_id,
  ) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == temp_id) {
        comments.removeAt(i);
        return comments;
      }
      if (comments[i].replies.isNotEmpty) {
        _remove_optimistic_comment(comments[i].replies, temp_id);
      }
    }
    return comments;
  }

  @override
  Widget build(BuildContext context) {
    /// 设备信息仓库（获取当前主题模式）。
    final DeviceInfo device_info = Get.find<DeviceInfo>();

    /// 是否为夜间模式。
    final bool is_dark = device_info.theme.value == ThemeMode.dark;

    /// 弹窗背景色。
    final Color bg_color = is_dark
        ? CommentListStyle.sheet_dark_bg
        : CommentListStyle.sheet_light_bg;

    /// 屏幕高度。
    final double screen_height = MediaQuery.sizeOf(context).height;

    /// 评论区高度。
    final double sheet_height =
        screen_height * CommentListStyle.max_height_ratio;

    // ModalBottomSheet 路由负责面板拖拽、回弹、遮罩点击和下滑关闭；评论内容
    // 仍是固定高度，键盘仅影响根 Overlay 中的真实输入框，不改变这里的布局。
    return RepaintBoundary(
      child: Container(
        height: sheet_height,
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CommentListStyle.sheet_radius),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: is_dark
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
            top: Radius.circular(CommentListStyle.sheet_radius),
          ),
          child: Column(
            children: <Widget>[
              CommentHeader(
                is_dark: is_dark,
                comment_count: _total_count,
                on_close: _handle_close,
                on_drag_start: _dismiss_input,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _dismiss_input,
                  behavior: HitTestBehavior.translucent,
                  child: RepaintBoundary(
                    child: _buildContent(is_dark: is_dark),
                  ),
                ),
              ),
              CommentInput(
                is_dark: is_dark,
                on_send: _handle_send,
                reply_target: _reply_target,
                on_cancel_reply: () => _set_reply_target(null),
                focus_node: _input_focus_node,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据加载状态构建内容区域。
  ///
  /// 使用 [AnimatedSwitcher] 在骨架屏、错误状态、空状态和评论列表之间
  /// 做交叉淡入淡出过渡，避免状态切换时的突兀跳变。
  Widget _buildContent({required bool is_dark}) {
    return AnimatedSwitcher(
      duration: const Duration(
        milliseconds: CommentListStyle.skeleton_switch_duration_ms,
      ),
      child: switch (_load_status) {
        'loading' => CommentSkeleton(
          key: const ValueKey<String>('skeleton'),
          is_dark: is_dark,
        ),
        'error' => _buildErrorState(
          key: const ValueKey<String>('error'),
          is_dark: is_dark,
        ),
        _ => _buildCommentList(
          key: const ValueKey<String>('list'),
          is_dark: is_dark,
        ),
      },
    );
  }

  /// 构建评论列表。
  Widget _buildCommentList({Key? key, required bool is_dark}) {
    if (_comments.isEmpty) {
      return _buildEmptyState(key: key, is_dark: is_dark);
    }

    return ListView.builder(
      key: key,
      controller: _scroll_controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      scrollCacheExtent: const ScrollCacheExtent.pixels(
        CommentListStyle.list_cache_extent,
      ),
      addRepaintBoundaries: false,
      padding: const EdgeInsets.symmetric(
        vertical: CommentListStyle.list_vertical_padding,
      ),
      itemCount: _comments.length + (_is_loading_more ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        // TODO 最后一项：加载更多指示器
        if (index == _comments.length) {
          return _buildLoadMoreIndicator(is_dark: is_dark);
        }

        final CommentData comment = _comments[index];
        return CommentItem(
          key: ValueKey<int>(comment.id),
          comment: comment,
          is_dark: is_dark,
          on_reply: (CommentData target) => _handle_reply(target),
          on_like: (CommentData target) => _handle_like(target),
          highlighted_comment_id: _highlighted_comment_id,
        );
      },
    );
  }

  /// 构建加载更多指示器。
  Widget _buildLoadMoreIndicator({required bool is_dark}) {
    /// 次要文字颜色。
    final Color text_color = is_dark
        ? CommentListStyle.secondary_dark_color
        : CommentListStyle.secondary_light_color;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: CommentListStyle.load_more_padding_vertical,
      ),
      child: Center(
        child: SizedBox(
          width: CommentListStyle.load_more_indicator_size,
          height: CommentListStyle.load_more_indicator_size,
          child: CircularProgressIndicator(
            strokeWidth: CommentListStyle.load_more_indicator_stroke_width,
            valueColor: AlwaysStoppedAnimation<Color>(text_color),
          ),
        ),
      ),
    );
  }

  /// 构建错误状态（使用 NoInternet 组件）。
  Widget _buildErrorState({Key? key, required bool is_dark}) {
    return NoInternet(
      key: key,
      is_dark: is_dark,
      title: tr('comment.load_error_title'),
      description: tr('comment.load_error_desc'),
      on_reload: _load_comments,
    );
  }

  /// 构建空状态提示。
  Widget _buildEmptyState({Key? key, required bool is_dark}) {
    /// 文字颜色。
    final Color text_color = is_dark
        ? CommentListStyle.secondary_dark_color
        : CommentListStyle.secondary_light_color;

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: CommentListStyle.empty_padding_vertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.chat_bubble_outline,
              size: CommentListStyle.empty_icon_size,
              color: text_color.withValues(
                alpha: CommentListStyle.empty_icon_opacity,
              ),
            ),
            const SizedBox(height: CommentListStyle.empty_icon_text_spacing),
            Text(
              tr('comment.empty'),
              style: TextStyle(
                fontSize: CommentListStyle.empty_text_font_size,
                color: text_color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
