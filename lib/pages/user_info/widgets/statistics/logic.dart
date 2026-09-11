// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:get/get.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/pages/author_center/logic.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/shell_tab_info.dart';
import 'package:app/util/router/router_util.dart';

// TODO 个人中心统计模块逻辑层
class Logic {
  /// 消息页对应的 Shell 路由。
  static const String _message_path = '/message';

  /// TODO 消息仓库。
  final MessageStore message_store = Get.find<MessageStore>();

  /// Shell 层级的 tab 状态仓库。
  final ShellTabInfo shell_tab_info = Get.find<ShellTabInfo>();

  /// 作者 Dashboard 统计数据。
  final total_works = 0.obs;
  final total_favorites = 0.obs;
  final total_comments = 0.obs;

  Logic();

  /// 加载作者 Dashboard 统计数据。
  Future<void> load_dashboard() async {
    try {
      final result = await CreatorLogic.getDashboard();
      if (result != null) {
        total_works.value = int.tryParse('${result['total_works']}') ?? 0;
        total_favorites.value = int.tryParse('${result['total_favorites']}') ?? 0;
        total_comments.value = int.tryParse('${result['total_comments']}') ?? 0;
      }
    } catch (_) {}
  }

  /// 切换到消息页并应用指定筛选。
  ///
  /// [filter_type]：2=评论，3=点赞，5=收藏。
  void go_to_message(int filter_type) {
    // set_filter_type 会同步切换当前消息桶，再异步加载该桶的数据。
    unawaited(message_store.set_filter_type(filter_type));

    // 消息页是 Shell 常驻 tab，必须使用 go 切换，不能重复 push 路由栈。
    shell_tab_info.updateActivePath(_message_path);
    AppRouter.go(_message_path);
  }

  /// 进入创作中心并展示作者作品列表。
  void go_to_creator_center() {
    routerUtil(path: '/author_center');
  }

  /// 获取评论总数。
  int get comment_total => message_store.comment_total.value;

  /// 获取评论未读数。
  int get comment_unread => message_store.comment_unread.value;

  /// 获取点赞总数。
  int get like_total => message_store.like_total.value;

  /// 获取点赞未读数。
  int get like_unread => message_store.like_unread.value;

  /// 获取收藏总数。
  int get favorite_total => message_store.favorite_total.value;

  /// 获取收藏未读数。
  int get favorite_unread => message_store.favorite_unread.value;
}
