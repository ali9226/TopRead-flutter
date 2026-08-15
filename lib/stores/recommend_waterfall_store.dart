// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app/components/recommend_book_card/book_list_item.dart';

/// 单个推荐瀑布流在当前 App 进程内的独立会话。
///
/// 页面 Widget 被路由或 Tab 销毁时，会话仍保留已加载数据、
/// 广告槽位与已测量高度。使用不同 [waterfall_id] 的组件
/// 始终互相隔离。
class RecommendWaterfallSession extends ChangeNotifier {
  RecommendWaterfallSession({required this.waterfall_id});

  /// 当前瀑布流的全局稳定标识。
  final String waterfall_id;

  /// 已加载的小说与广告槽位，顺序不随 Widget 重建改变。
  final List<BookListItem> items = <BookListItem>[];

  /// 正在执行删除动画的卡片 ID。
  final Set<String> removing_ids = <String>{};

  /// 已测量的卡片高度，用于恢复原有瀑布流排版。
  final Map<String, double> item_heights = <String, double>{};

  /// 当前显示操作遮罩的卡片 ID。
  String? active_overlay_id;

  /// 是否正在加载首屏数据。
  bool is_initial_loading = true;

  /// 是否正在加载下一批数据。
  bool is_loading_more = false;

  /// 后端是否可能还有更多数据。
  bool has_more = true;

  /// 当前会话是否已启动过首屏请求。
  bool has_initialized = false;

  /// 是否有一个首屏请求正在进行。
  bool is_initial_request_active = false;

  /// 当前数据对应的语种修订号。
  int language_revision = -1;

  /// 请求代次，用于阻止旧语种响应覆盖新数据。
  int request_generation = 0;

  /// 已分配的广告槽位数量。
  int ad_slot_sequence = 0;

  /// 生成当前会话内唯一，且跨 Widget 重建稳定的广告槽位 ID。
  String create_ad_slot_id() {
    ad_slot_sequence += 1;
    return 'masonry_ad_${waterfall_id}_$ad_slot_sequence';
  }

  /// 通知当前挂载的页面重新读取会话状态。
  void mark_changed() {
    notifyListeners();
  }
}

/// 推荐瀑布流全局会话仓库。
class RecommendWaterfallStore extends GetxController {
  final Map<String, RecommendWaterfallSession> _sessions =
      <String, RecommendWaterfallSession>{};

  /// 获取指定瀑布流的独立会话。
  RecommendWaterfallSession obtain(String waterfall_id) {
    assert(waterfall_id.trim().isNotEmpty, 'waterfall_id must not be empty');
    return _sessions.putIfAbsent(
      waterfall_id,
      () => RecommendWaterfallSession(waterfall_id: waterfall_id),
    );
  }

  /// 当前进程中保留的独立会话数，仅供测试验证。
  @visibleForTesting
  int get session_count => _sessions.length;

  @override
  void onClose() {
    for (final RecommendWaterfallSession session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
    super.onClose();
  }
}
