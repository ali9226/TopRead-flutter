import 'package:get/get.dart';
import 'package:app/stores/bookshelf_store.dart';

/// 书架数据同步入口。
///
/// 阅读、收藏和关注页面通过此服务通知常驻书架 Store，避免业务页面直接了解
/// 各 Tab 的加载状态和并发请求合并细节。
class BookshelfSyncService {
  const BookshelfSyncService._();

  /// 阅读历史发生变化后刷新已加载列表。
  static Future<void> history_changed() async {
    if (!Get.isRegistered<BookshelfStore>()) return;
    await Get.find<BookshelfStore>().refresh_history_if_requested();
  }

  /// 收藏关系发生变化后刷新已加载列表。
  static Future<void> favorite_changed() async {
    if (!Get.isRegistered<BookshelfStore>()) return;
    await Get.find<BookshelfStore>().refresh_favorite_if_requested();
  }

  /// 关注关系发生变化后刷新已加载列表。
  static Future<void> focus_changed() async {
    if (!Get.isRegistered<BookshelfStore>()) return;
    await Get.find<BookshelfStore>().refresh_focus_if_loaded();
  }
}
