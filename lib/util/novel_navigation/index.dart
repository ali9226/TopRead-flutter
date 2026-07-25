// ignore_for_file: non_constant_identifier_names

import 'package:app/util/router/router_util.dart';

/// 小说阅读页导航工具。
///
/// 统一处理小说点击后的页面跳转逻辑，避免各处重复维护。
/// 根据 [publish_status] 判断跳转目标：
/// - 短篇小说（publish_status == 4）→ 跳转短篇阅读页 `/short_story_read`
/// - 其他小说 → 跳转普通阅读页 `/read`
///
/// 参数：
/// - [id] 小说 ID。
/// - [title] 小说标题，用于普通阅读页的导航栏展示。
/// - [publish_status] 发布状态：1=连载中, 2=已完结, 3=下架, 4=短篇。
void navigate_to_novel({
  required int id,
  required String title,
  required int publish_status,
}) {
  if (publish_status == 4) {
    routerUtil(path: '/short_story_read?id=$id', type: 'push');
  } else {
    routerUtil(
      path: '/read?id=$id&title=${Uri.encodeComponent(title)}',
      type: 'push',
    );
  }
}
