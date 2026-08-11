import 'dart:async';
import 'dart:math' as math;

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
import 'package:app/permission_request/notification_permission_request.dart';
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
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
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

class _CommentSheetState extends State<CommentSheet>
    with WidgetsBindingObserver {
  /// 评论列表数据。
  List<CommentData> _comments = [];

  /// 滚动控制器。
  final ScrollController _scroll_controller = ScrollController();

  /// 评论列表真实视口，用于计算键盘弹出后的可见区域。
  final GlobalKey _list_view_key = GlobalKey();

  /// 每条评论的真实布局锚点。
  final Map<int, GlobalKey> _comment_target_keys = <int, GlobalKey>{};

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

  /// 当前被回复评论的布局上下文。
  BuildContext? _reply_target_context;

  /// 正在提交点赞请求的评论 ID，防止快速重复点击导致状态反转。
  final Set<int> _like_loading_ids = <int>{};

  /// 键盘关闭动画结束后是否仍需重新聚焦。
  bool _pending_reply_focus = false;

  /// 合并同一帧内的多次键盘尺寸回调。
  bool _reply_visibility_scheduled = false;

  /// 防止重复发送。
  bool _is_sending = false;

  /// 取消过期高亮计时器。
  Timer? _highlight_timer;

  /// 使过期的首次加载请求失效。
  int _load_generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll_controller.addListener(_on_scroll);
    unawaited(_load_comments());
  }

  @override
  void dispose() {
    _load_generation += 1;
    _highlight_timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll_controller.removeListener(_on_scroll);
    _scroll_controller.dispose();
    _input_focus_node.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted || _reply_target == null) return;

    if (_read_keyboard_height() <=
        CommentListStyle.keyboard_close_hide_threshold) {
      if (_pending_reply_focus) {
        _pending_reply_focus = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _reply_target == null) return;
          _input_focus_node.requestFocus();
        });
      }
      return;
    }

    _schedule_reply_visibility();
  }

  GlobalKey _target_key_for(int comment_id) {
    return _comment_target_keys.putIfAbsent(comment_id, GlobalKey.new);
  }

  double _read_keyboard_height() {
    final view = View.maybeOf(context);
    if (view == null || view.devicePixelRatio == 0) return 0;
    return view.viewInsets.bottom / view.devicePixelRatio;
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
    final Map<int, String> nickname_map = {};
    void collect_nicknames(List<CommentData> replies) {
      for (final CommentData reply in replies) {
        nickname_map[reply.id] = reply.nickname;
        if (reply.replies.isNotEmpty) {
          collect_nicknames(reply.replies);
        }
      }
    }

    collect_nicknames(nested_replies);

    void flatten(List<CommentData> replies) {
      for (final CommentData reply in replies) {
        final String? inferred_nickname =
            reply.reply_to_nickname ?? nickname_map[reply.parent_id];
        flat.add(
          reply.copy_with(
            replies: const <CommentData>[],
            reply_to_nickname: inferred_nickname?.isNotEmpty == true
                ? inferred_nickname
                : null,
          ),
        );
        if (reply.replies.isNotEmpty) flatten(reply.replies);
      }
    }

    flatten(nested_replies);
    return flat;
  }

  /// 加载评论列表（首次加载或刷新）。
  Future<void> _load_comments() async {
    final int generation = ++_load_generation;
    setState(() {
      _load_status = 'loading';
      _current_page = 1;
      _has_more = true;
    });

    try {
      final CommentListResult? result = await inquire_comment_list(
        novel_id: widget.novel_id,
        page: 1,
        page_size: _page_size,
        highlight_id: widget.scroll_to_comment_id,
      );

      if (!mounted || generation != _load_generation) return;

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
        _has_more = result.page * result.page_size < result.total;
      });

      if (widget.scroll_to_comment_id > 0) {
        unawaited(_scroll_to_comment(widget.scroll_to_comment_id));
      }
    } catch (_) {
      if (!mounted || generation != _load_generation) return;
      setState(() {
        _load_status = 'error';
      });
    }
  }

  /// 滚动到指定评论ID所在的位置，并触发闪烁高亮。
  Future<void> _scroll_to_comment(int comment_id) async {
    if (!_comments.any(
      (CommentData comment) =>
          comment.id == comment_id ||
          comment.replies.any((CommentData reply) => reply.id == comment_id),
    )) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scroll_controller.hasClients) return;

    // highlight_id 会让后端把目标所在的顶层评论放到第一页首位。先回到列表
    // 顶部，确保目标真实布局完成，再按 RenderObject 的实际位置定位。
    _scroll_controller.jumpTo(0);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final BuildContext? target_context = _target_key_for(
      comment_id,
    ).currentContext;
    if (target_context == null || !target_context.mounted) return;

    await Scrollable.ensureVisible(
      target_context,
      alignment: 0.12,
      duration: const Duration(
        milliseconds: CommentListStyle.scroll_to_comment_animation_duration_ms,
      ),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    _highlight_timer?.cancel();
    setState(() => _highlighted_comment_id = comment_id);
    _highlight_timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlighted_comment_id = 0);
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
        final Set<int> existing_ids = _comments
            .map((CommentData comment) => comment.id)
            .toSet();
        final List<CommentData> new_comments = result.list
            .where((CommentData comment) => existing_ids.add(comment.id))
            .map((CommentData c) {
              if (c.replies.isEmpty) return c;
              return c.copy_with(replies: _flatten_replies(c.replies));
            })
            .toList();
        setState(() {
          _current_page = result.page;
          _comments = [..._comments, ...new_comments];
          _total_count = math.max(_total_count, result.total);
          _has_more = result.page * result.page_size < result.total;
        });
      }
    } catch (_) {
      // 保留当前分页状态，下一次触底时允许重试。
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
    if (!mounted || identical(_reply_target, comment)) return;
    setState(() {
      _reply_target = comment;
    });
  }

  /// 关闭输入框并退出回复模式。
  void _dismiss_input() {
    _pending_reply_focus = false;
    _reply_target_context = null;
    _input_focus_node.unfocus();
    if (_reply_target != null) {
      _set_reply_target(null);
    }
  }

  /// 处理回复操作。
  void _handle_reply(CommentData comment, BuildContext target_context) {
    _pending_reply_focus = false;
    _reply_target_context = target_context;
    _set_reply_target(comment);

    if (_input_focus_node.hasFocus) {
      _schedule_reply_visibility();
      return;
    }

    // iOS 键盘关闭动画未结束时立即 requestFocus 会产生先下滑再回弹。等待
    // viewInsets 真实归零后，由 didChangeMetrics 继续本次回复交互。
    if (_read_keyboard_height() >
        CommentListStyle.keyboard_close_hide_threshold) {
      _pending_reply_focus = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _reply_target?.id != comment.id) return;
      _input_focus_node.requestFocus();
    });
  }

  void _schedule_reply_visibility() {
    if (_reply_visibility_scheduled) return;
    _reply_visibility_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reply_visibility_scheduled = false;
      _keep_reply_target_visible();
    });
  }

  void _keep_reply_target_visible() {
    if (!mounted || !_scroll_controller.hasClients) return;

    final BuildContext? target_context =
        _reply_target_context ??
        (_reply_target == null
            ? null
            : _target_key_for(_reply_target!.id).currentContext);
    final BuildContext? viewport_context = _list_view_key.currentContext;
    final RenderObject? target_object = target_context?.findRenderObject();
    final RenderObject? viewport_object = viewport_context?.findRenderObject();
    if (target_object is! RenderBox ||
        viewport_object is! RenderBox ||
        !target_object.attached ||
        !viewport_object.attached) {
      return;
    }

    final double keyboard_height = _read_keyboard_height();
    if (keyboard_height <= CommentListStyle.keyboard_close_hide_threshold) {
      return;
    }

    final Rect target_rect =
        target_object.localToGlobal(Offset.zero) & target_object.size;
    final Rect viewport_rect =
        viewport_object.localToGlobal(Offset.zero) & viewport_object.size;
    final double keyboard_top =
        MediaQuery.sizeOf(context).height - keyboard_height;
    final double visible_top =
        viewport_rect.top + CommentListStyle.reply_visibility_margin;
    final double visible_bottom = math.min(
      viewport_rect.bottom,
      keyboard_top -
          CommentListStyle.input_area_height -
          CommentListStyle.reply_visibility_margin,
    );
    if (visible_bottom <= visible_top) return;

    double delta = 0;
    final double visible_height = visible_bottom - visible_top;
    if (target_rect.height > visible_height) {
      delta = target_rect.top - visible_top;
    } else if (target_rect.bottom > visible_bottom) {
      delta = target_rect.bottom - visible_bottom;
    } else if (target_rect.top < visible_top) {
      delta = target_rect.top - visible_top;
    }
    if (delta.abs() < 0.5) return;

    final ScrollPosition position = _scroll_controller.position;
    final double target_offset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target_offset - position.pixels).abs() < 0.5) return;
    _scroll_controller.jumpTo(target_offset);
  }

  /// 处理点赞操作。
  ///
  /// 未登录时弹出登录提示弹窗，已登录时调用点赞接口。
  Future<void> _handle_like(CommentData comment) async {
    if (comment.id <= 0) return;
    if (!_like_loading_ids.add(comment.id)) return;

    try {
      // TODO 登录检查
      final bool is_logged_in = await showLoginRequiredDialog(
        title: tr('short_story_read.login_required'),
      );
      if (!is_logged_in || !mounted) return;

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
    } finally {
      _like_loading_ids.remove(comment.id);
    }
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

  /// 处理发送评论（乐观更新，失败时保留草稿与回复目标）。
  Future<bool> _handle_send(String content) async {
    if (_is_sending || _load_status != 'success') return false;
    final CommentData? reply_target = _reply_target;
    final int parent_id = reply_target?.id ?? 0;
    final bool is_reply_to_nested =
        reply_target != null && reply_target.parent_id > 0;

    final bool is_logged_in = await showLoginRequiredDialog(
      title: tr('short_story_read.login_required'),
    );
    if (!is_logged_in || !mounted) return false;

    final user_info = Get.find<UserInformation>().userInfo.value;
    if (user_info == null) return false;

    final int temp_id = -DateTime.now().microsecondsSinceEpoch;
    final String now_str = DateTime.now().toUtc().toIso8601String();

    final CommentData comment_to_insert = CommentData(
      id: temp_id,
      user_id: user_info.id,
      avatar: user_info.avatarUrl,
      nickname: user_info.name,
      content: content,
      time: now_str,
      parent_id: parent_id,
      reply_to_nickname: is_reply_to_nested ? reply_target.nickname : null,
    );

    int root_index = -1;
    if (parent_id > 0) {
      root_index = _comments.indexWhere(
        (CommentData comment) =>
            comment.id == parent_id ||
            comment.replies.any((CommentData reply) => reply.id == parent_id),
      );
      if (root_index < 0) return false;
    }

    _is_sending = true;
    setState(() {
      if (parent_id > 0) {
        final List<CommentData> next_comments = List<CommentData>.of(_comments);
        final CommentData root = next_comments[root_index];
        next_comments[root_index] = root.copy_with(
          replies: <CommentData>[...root.replies, comment_to_insert],
        );
        _comments = next_comments;
      } else {
        _comments = <CommentData>[comment_to_insert, ..._comments];
      }
      _total_count += 1;
    });
    widget.on_count_changed?.call(_total_count);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll_controller.hasClients) return;
      if (parent_id == 0) {
        unawaited(
          _scroll_controller.animateTo(
            0,
            duration: const Duration(
              milliseconds:
                  CommentListStyle.scroll_to_top_animation_duration_ms,
            ),
            curve: Curves.easeOutCubic,
          ),
        );
        return;
      }

      final BuildContext? inserted_context = _target_key_for(
        temp_id,
      ).currentContext;
      if (inserted_context != null) {
        unawaited(
          Scrollable.ensureVisible(
            inserted_context,
            alignment: 0.82,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });

    bool success = false;
    try {
      success = await add_comment(
        novel_id: widget.novel_id,
        comment_content: content,
        parent_id: parent_id,
      );
    } catch (_) {
      success = false;
    }
    if (!mounted) return success;

    _is_sending = false;
    if (!success) {
      setState(() {
        _comments = _remove_optimistic_comment(_comments, temp_id);
        _total_count = math.max(0, _total_count - 1);
      });
      widget.on_count_changed?.call(_total_count);
      showBottomTip(tr('comment.send_failed'));
      return false;
    }

    _has_new_comments = true;
    _reply_target_context = null;
    _set_reply_target(null);

    // 评论成功落库后才申请系统通知权限，便于用户接收回复。
    unawaited(NotificationPermissionRequest.request_after_comment_published());
    return true;
  }

  /// 从顶层或扁平回复列表移除乐观更新失败的临时评论。
  List<CommentData> _remove_optimistic_comment(
    List<CommentData> comments,
    int temp_id,
  ) {
    return comments
        .where((CommentData comment) => comment.id != temp_id)
        .map(
          (CommentData comment) => comment.copy_with(
            replies: comment.replies
                .where((CommentData reply) => reply.id != temp_id)
                .toList(),
          ),
        )
        .toList();
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
                on_cancel_reply: () {
                  _reply_target_context = null;
                  _set_reply_target(null);
                },
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

    return KeyedSubtree(
      key: key,
      child: ListView.builder(
        key: _list_view_key,
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
          if (index == _comments.length) {
            return _buildLoadMoreIndicator(is_dark: is_dark);
          }

          final CommentData comment = _comments[index];
          return CommentItem(
            key: ValueKey<int>(comment.id),
            comment: comment,
            is_dark: is_dark,
            on_reply: _handle_reply,
            on_like: _handle_like,
            highlighted_comment_id: _highlighted_comment_id,
            target_key_builder: _target_key_for,
          );
        },
      ),
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
