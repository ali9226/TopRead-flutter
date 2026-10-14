// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/router/router_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// 登录仅在收藏、评论、分享时要求，访客可以完整浏览漫画。
bool comics_require_login() {
  if (Get.isRegistered<UserInformation>() &&
      Get.find<UserInformation>().isLoggedIn.value) {
    return true;
  }
  showBottomTip(tr('comics.login_required'));
  routerUtil(path: '/login');
  return false;
}

/// 控制器生命周期安全通知，异步请求完成时不会更新已经关闭的页面。
class ComicsController extends ChangeNotifier {
  bool disposed = false;
  String? error;
  void emit() {
    if (!disposed) notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// 漫画列表分页浏览逻辑；请求序号防止旧响应覆盖新结果。
class ComicsBrowseLogic extends ComicsController {
  /// 当前页数据。
  final List<ComicItem> items = <ComicItem>[];

  /// 漫画分类原始列表，用于筛选栏展示。
  List<Map<String, dynamic>> categories = <Map<String, dynamic>>[];

  /// 是否正在加载首页数据。
  bool loading = false;

  /// 是否正在加载更多数据。
  bool loading_more = false;

  /// 分类是否已结束加载（无论成败）。
  bool categories_loaded = false;

  /// 当前过滤条件下的总条数。
  int total = 0;

  /// 当前已加载到的页码。
  int page = 0;

  /// 当前选中的分类 id，0 表示全部。
  int category_id = 0;

  /// 请求序号，用于丢弃过期响应。
  int _request_id = 0;

  /// 是否还有下一页。
  bool get has_more => items.length < total;

  Future<void> load_categories() async {
    try {
      final data = await comics_request('categories');
      if (disposed) return;
      categories = comics_list(data['list']);
      emit();
    } catch (_) {
      // 列表仍然可用；下拉刷新同时重试分类。
    } finally {
      // 无论成败都结束加载态，避免筛选栏永久停留在骨架屏。
      if (!disposed) {
        categories_loaded = true;
        emit();
      }
    }
  }

  Future<void> load({bool more = false}) async {
    if (disposed || (more && (loading || loading_more || !has_more))) return;
    final request_id = ++_request_id;
    final next_page = more ? page + 1 : 1;
    if (more) {
      loading_more = true;
    } else {
      loading = true;
      loading_more = false;
    }
    error = null;
    emit();
    try {
      final data = await comics_request('inquire', <String, dynamic>{
        'page': next_page,
        'page_size': ComicsStyle.page_size,
        if (category_id > 0) 'category_id': category_id,
      });
      if (disposed || request_id != _request_id) return;
      final next_items = comics_list(data['list']).map(ComicItem.from_json);
      if (!more) items.clear();
      final known_ids = items.map((item) => item.id).toSet();
      items.addAll(next_items.where((item) => !known_ids.contains(item.id)));
      total = comics_int(data['total']);
      page = next_page;
    } catch (failure) {
      if (disposed || request_id != _request_id) return;
      error = failure.toString();
    } finally {
      if (!disposed && request_id == _request_id) {
        loading = false;
        loading_more = false;
        emit();
      }
    }
  }

  void select_category(int value) {
    if (category_id == value) return;
    category_id = value;
    load();
  }

  Future<void> refresh() async {
    unawaited(load_categories());
    await load();
  }
}
