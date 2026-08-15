// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/language_change_handler.dart';

typedef HistoryListFetcher =
    Future<BookshelfListResult<ReadRecordItem>?> Function({
      required int page,
      required int page_size,
    });
typedef FavoriteListFetcher =
    Future<BookshelfListResult<FavoriteItem>?> Function({
      required int page,
      required int page_size,
    });
typedef FocusListFetcher =
    Future<BookshelfListResult<FocusAuthorItem>?> Function({
      required int page,
      required int page_size,
    });

/// 书架书籍项模型（用于历史和收藏的网格展示）。
class BookshelfBookItem {
  /// 数据唯一标识。
  final String id;

  /// 小说ID。
  final String novel_id;

  /// 标题文案。
  final String title;

  /// 发布状态：1=连载中, 2=已完结, 3=下架, 4=短篇。
  final int publish_status;

  /// 小说简介（用于封面兜底展示）。
  final String introduction;

  /// 分类名称（逗号分隔）。
  final String category_names;

  /// 进度文案国际化 key。
  final String progress_key;

  /// 进度文案参数。
  final Map<String, String> progress_args;

  /// 右上角标签国际化 key。
  final String? tag_key;

  /// 远程封面图地址。
  final String? cover_image_url;

  /// 封面渐变起始色。
  final Color cover_start_color;

  /// 封面渐变结束色。
  final Color cover_end_color;

  BookshelfBookItem({
    required this.id,
    required this.novel_id,
    required this.title,
    this.publish_status = 1,
    this.introduction = '',
    this.category_names = '',
    required this.progress_key,
    required this.progress_args,
    this.tag_key,
    this.cover_image_url,
    required this.cover_start_color,
    required this.cover_end_color,
  });
}

/// 预定义的封面渐变色列表，用于没有封面图时的兜底展示。
const List<List<Color>> _cover_gradient_colors = <List<Color>>[
  <Color>[Color(0xFFF7C9C0), Color(0xFFF2E0A6)],
  <Color>[Color(0xFFBBDCF7), Color(0xFFE4EFFA)],
  <Color>[Color(0xFFD7C7F6), Color(0xFFF0EAFE)],
  <Color>[Color(0xFFF7D1D7), Color(0xFFFCEBEC)],
  <Color>[Color(0xFFE7D4BA), Color(0xFFF8EEE0)],
  <Color>[Color(0xFFC6E6D7), Color(0xFFE8F6F0)],
  <Color>[Color(0xFFD0DCF7), Color(0xFFE8EEFF)],
  <Color>[Color(0xFFCFE8EC), Color(0xFFE9F5F7)],
  <Color>[Color(0xFFF3D2C7), Color(0xFFFDEEEA)],
  <Color>[Color(0xFFE2D7F4), Color(0xFFF3EEFB)],
];

/// 书架页面全局数据仓库。
///
/// 缓存历史、收藏、关注三个 Tab 的列表数据，
/// 避免切换 Tab 时数据丢失导致重复请求。
class BookshelfStore extends GetxController {
  BookshelfStore({
    HistoryListFetcher? fetch_history_list,
    FavoriteListFetcher? fetch_favorite_list,
    FocusListFetcher? fetch_focus_list,
  }) : _fetch_history_list = fetch_history_list ?? inquire_read_record_list,
       _fetch_favorite_list = fetch_favorite_list ?? inquire_favorite_list,
       _fetch_focus_list = fetch_focus_list ?? inquire_focus_author_list;

  /// 历史、收藏和关注列表的请求实现，测试时可注入可控异步结果。
  final HistoryListFetcher _fetch_history_list;
  final FavoriteListFetcher _fetch_favorite_list;
  final FocusListFetcher _fetch_focus_list;

  /// 语种刷新任务订阅。
  LanguageRefreshSubscription? _language_refresh_subscription;

  /// 语种刷新状态监听。
  ///
  /// 用于承接恰好在统一刷新流程中首次打开书架的场景。
  Worker? _language_refresh_worker;

  /// 当前书架多语言数据版本。
  ///
  /// 语种切换时递增，确保切换前发出的旧请求不能覆盖新语种数据。
  int _language_data_revision = 0;

  /// 当前账号书架数据版本，清空时递增以废弃在途响应。
  int _store_data_revision = 0;

  /// 切换语种前历史列表是否已加载。
  bool _should_refresh_history = false;

  /// 切换语种前收藏列表是否已加载。
  bool _should_refresh_favorite = false;

  // ==================== 历史 Tab ====================

  /// 历史列表数据。
  final RxList<BookshelfBookItem> history_list = <BookshelfBookItem>[].obs;

  /// 历史列表当前页码。
  int _history_page = 1;

  /// 历史列表是否还有更多数据。
  final RxBool history_has_more = true.obs;

  /// 历史列表是否正在首屏加载。
  final RxBool history_is_loading = true.obs;

  /// 历史列表是否正在加载下一页。
  final RxBool history_is_loading_more = false.obs;

  /// 历史列表是否已加载过（懒加载标记）。
  bool _history_loaded = false;

  /// 历史列表是否已经发起过加载。
  ///
  /// 与 [_history_loaded] 分开记录，保证语种切换发生在首个请求途中时，
  /// 新语种仍会重新发起请求。
  bool _history_requested = false;

  /// 历史列表当前在途任务，重复调用复用同一 Future。
  Future<void>? _history_request;

  /// 当前历史在途任务对应的账号数据版本。
  int _history_request_store_revision = -1;

  /// 在途任务期间收到的刷新需求，最多合并为一次后续刷新。
  bool _history_refresh_pending = false;

  /// 待执行历史刷新所属的语种修订号。
  int? _history_pending_language_revision;

  // ==================== 收藏 Tab ====================

  /// 收藏列表数据。
  final RxList<BookshelfBookItem> favorite_list = <BookshelfBookItem>[].obs;

  /// 收藏列表当前页码。
  int _favorite_page = 1;

  /// 收藏列表是否还有更多数据。
  final RxBool favorite_has_more = true.obs;

  /// 收藏列表是否正在首屏加载。
  final RxBool favorite_is_loading = true.obs;

  /// 收藏列表是否正在加载下一页。
  final RxBool favorite_is_loading_more = false.obs;

  /// 收藏列表是否已加载过（懒加载标记）。
  bool _favorite_loaded = false;

  /// 收藏列表是否已经发起过加载。
  ///
  /// 与 [_favorite_loaded] 分开记录，避免语种切换中断首个请求后列表不再加载。
  bool _favorite_requested = false;

  /// 收藏列表当前在途任务，重复调用复用同一 Future。
  Future<void>? _favorite_request;

  /// 当前收藏在途任务对应的账号数据版本。
  int _favorite_request_store_revision = -1;

  /// 在途任务期间收到的刷新需求。
  bool _favorite_refresh_pending = false;

  /// 待执行收藏刷新所属的语种修订号。
  int? _favorite_pending_language_revision;

  // ==================== 关注 Tab ====================

  /// 关注作者列表数据。
  final RxList<FocusAuthorItem> focus_list = <FocusAuthorItem>[].obs;

  /// 关注列表当前页码。
  int _focus_page = 1;

  /// 关注列表是否还有更多数据。
  final RxBool focus_has_more = true.obs;

  /// 关注列表是否正在首屏加载。
  final RxBool focus_is_loading = true.obs;

  /// 关注列表是否正在加载下一页。
  final RxBool focus_is_loading_more = false.obs;

  /// 关注列表是否已加载过（懒加载标记）。
  bool _focus_loaded = false;

  /// 关注列表当前在途任务，重复调用复用同一 Future。
  Future<void>? _focus_request;

  /// 当前关注在途任务对应的账号数据版本。
  int _focus_request_store_revision = -1;

  /// 在途任务期间收到的刷新需求。
  bool _focus_refresh_pending = false;

  // ==================== 通用配置 ====================

  /// 每页数量。
  static const int _page_size = 20;

  @override
  void onInit() {
    super.onInit();
    _language_refresh_subscription =
        LanguageChangeHandler.register_refresh_task(
          phase: LanguageRefreshPhase.content,
          on_prepare: _prepare_language_refresh,
          on_refresh: _refresh_for_language,
        );
    _language_refresh_worker = ever<bool>(
      LanguageChangeHandler.is_refreshing,
      _handle_language_refresh_state,
    );
  }

  @override
  void onClose() {
    _language_refresh_worker?.dispose();
    _language_refresh_subscription?.dispose();
    super.onClose();
  }

  /// Locale 切换前清除旧语种书架数据，并使在途请求失效。
  void _prepare_language_refresh(LanguageRefreshContext refresh_context) {
    _language_data_revision++;
    _should_refresh_history = _history_requested;
    _should_refresh_favorite = _favorite_requested;

    _history_page = 1;
    _history_loaded = false;
    history_list.clear();
    history_has_more.value = true;
    history_is_loading.value = _should_refresh_history;
    history_is_loading_more.value = false;

    _favorite_page = 1;
    _favorite_loaded = false;
    favorite_list.clear();
    favorite_has_more.value = true;
    favorite_is_loading.value = _should_refresh_favorite;
    favorite_is_loading_more.value = false;
  }

  /// 基础语种配置刷新完成后，重新加载切换前已访问的书架内容。
  Future<void> _refresh_for_language(
    LanguageRefreshContext refresh_context,
  ) async {
    if (!refresh_context.is_current ||
        !Get.find<UserInformation>().isLoggedIn.value) {
      return;
    }

    await Future.wait<void>(<Future<void>>[
      if (_should_refresh_history)
        _fetch_history(
          reset: true,
          language_revision: refresh_context.revision,
        ),
      if (_should_refresh_favorite)
        _fetch_favorite(
          reset: true,
          language_revision: refresh_context.revision,
        ),
    ]);
  }

  /// 统一语种刷新结束后补载刷新期间首次请求的书架内容。
  void _handle_language_refresh_state(bool is_refreshing) {
    final bool should_load_history = _history_requested && !_history_loaded;
    final bool should_load_favorite = _favorite_requested && !_favorite_loaded;

    if (is_refreshing ||
        !Get.find<UserInformation>().isLoggedIn.value ||
        (!should_load_history && !should_load_favorite)) {
      return;
    }

    unawaited(
      Future.wait<void>(<Future<void>>[
        if (should_load_history)
          _fetch_history(
            reset: true,
            language_revision: LanguageChangeHandler.current_revision,
          ),
        if (should_load_favorite)
          _fetch_favorite(
            reset: true,
            language_revision: LanguageChangeHandler.current_revision,
          ),
      ]),
    );
  }

  // ==================== 历史 Tab 操作 ====================

  /// 加载历史列表首屏数据（懒加载，仅首次调用时请求）。
  Future<void> load_history_if_needed() async {
    if (_history_loaded) return;
    _history_requested = true;
    if (LanguageChangeHandler.is_refreshing.value) {
      _should_refresh_history = true;
      history_is_loading.value = true;
      return;
    }

    final Future<void>? active_request = _history_request;
    if (active_request != null) {
      if (_history_request_store_revision != _store_data_revision) {
        _history_refresh_pending = true;
        _history_pending_language_revision =
            LanguageChangeHandler.current_revision;
      }
      await active_request;
      return;
    }
    await _fetch_history(reset: true);
  }

  /// 刷新历史列表数据。
  Future<void> refresh_history() async {
    _history_requested = true;
    if (LanguageChangeHandler.is_refreshing.value) {
      _should_refresh_history = true;
      history_is_loading.value = true;
      return;
    }
    await _fetch_history(reset: true);
  }

  /// 加载历史列表更多数据。
  Future<void> load_more_history() async {
    if (!history_has_more.value ||
        _history_request != null ||
        LanguageChangeHandler.is_refreshing.value) {
      return;
    }
    await _fetch_history(reset: false);
  }

  /// 从列表中移除指定历史记录。
  void remove_history_item(String item_id) {
    history_list.removeWhere((BookshelfBookItem item) => item.id == item_id);
  }

  /// 请求历史列表数据。
  Future<void> _fetch_history({
    required bool reset,
    int? language_revision,
  }) async {
    final Future<void>? active_request = _history_request;
    if (active_request != null) {
      if (reset) {
        _history_refresh_pending = true;
        _history_pending_language_revision = language_revision;
      }
      await active_request;
      return;
    }

    late final Future<void> request;
    request = _drain_history_requests(
      reset: reset,
      language_revision: language_revision,
    );
    _history_request_store_revision = _store_data_revision;
    _history_request = request;

    try {
      await request;
    } finally {
      if (identical(_history_request, request)) {
        _history_request = null;
      }
    }
  }

  /// 串行执行历史请求；在途期间多次刷新只追加一轮。
  Future<void> _drain_history_requests({
    required bool reset,
    int? language_revision,
  }) async {
    bool next_reset = reset;
    int? next_language_revision = language_revision;

    do {
      _history_refresh_pending = false;
      _history_pending_language_revision = null;
      await _fetch_history_once(
        reset: next_reset,
        language_revision: next_language_revision,
      );

      next_reset = _history_refresh_pending;
      next_language_revision = _history_pending_language_revision;
    } while (next_reset);
  }

  /// 执行一轮历史列表请求。
  Future<void> _fetch_history_once({
    required bool reset,
    int? language_revision,
  }) async {
    _history_requested = true;
    final int data_revision = _language_data_revision;
    final int store_revision = _store_data_revision;
    _history_request_store_revision = store_revision;
    final UserInformation? user_information =
        Get.isRegistered<UserInformation>()
        ? Get.find<UserInformation>()
        : null;
    final int? auth_revision = user_information?.auth_revision;
    final int request_page = reset ? 1 : _history_page + 1;
    if (reset) {
      history_is_loading.value = true;
    } else {
      history_is_loading_more.value = true;
    }

    try {
      final BookshelfListResult<ReadRecordItem>? result =
          await _fetch_history_list(page: request_page, page_size: _page_size);

      if (data_revision != _language_data_revision ||
          store_revision != _store_data_revision ||
          (language_revision != null &&
              !LanguageChangeHandler.is_current_revision(language_revision)) ||
          !_can_apply_authenticated_response(user_information, auth_revision)) {
        return;
      }

      if (result == null) {
        if (reset) history_list.clear();
        history_has_more.value = false;
        _history_loaded = true;
        return;
      }

      final List<BookshelfBookItem> new_items = result.list
          .asMap()
          .entries
          .map(
            (MapEntry<int, ReadRecordItem> entry) => _convert_history_item(
              entry.value,
              reset ? entry.key : history_list.length + entry.key,
            ),
          )
          .toList(growable: false);
      history_list.assignAll(
        _merge_unique_items<BookshelfBookItem>(
          current_items: reset ? const <BookshelfBookItem>[] : history_list,
          incoming_items: new_items,
          identity_of: (BookshelfBookItem item) => item.id,
        ),
      );
      _history_page = request_page;
      history_has_more.value = result.list.length >= _page_size;
      _history_loaded = true;
    } catch (error) {
      debugPrint('BookshelfStore history request failed: $error');
    } finally {
      if (data_revision == _language_data_revision &&
          store_revision == _store_data_revision) {
        if (reset) history_is_loading.value = false;
        history_is_loading_more.value = false;
      }
    }
  }

  /// 将阅读记录转换为书架书籍项。
  BookshelfBookItem _convert_history_item(ReadRecordItem item, int index) {
    final List<Color> colors =
        _cover_gradient_colors[index % _cover_gradient_colors.length];
    final bool has_progress = item.read_progress > 0;

    String progress_key;
    Map<String, String> progress_args;
    if (has_progress) {
      progress_key = 'bookshelf.progress.read_progress';
      progress_args = <String, String>{
        'progress': item.read_progress.toStringAsFixed(0),
      };
    } else {
      progress_key = 'bookshelf.progress.unread';
      progress_args = <String, String>{};
    }

    return BookshelfBookItem(
      id: item.id,
      novel_id: item.novel_id,
      title: item.novel_title,
      publish_status: item.publish_status,
      introduction: item.introduction,
      category_names: item.category_names,
      progress_key: progress_key,
      progress_args: progress_args,
      cover_image_url: item.cover_url.isNotEmpty ? item.cover_url : null,
      cover_start_color: colors[0],
      cover_end_color: colors[1],
    );
  }

  // ==================== 收藏 Tab 操作 ====================

  /// 加载收藏列表首屏数据（懒加载，仅首次调用时请求）。
  Future<void> load_favorite_if_needed() async {
    if (_favorite_loaded) return;
    _favorite_requested = true;
    if (LanguageChangeHandler.is_refreshing.value) {
      _should_refresh_favorite = true;
      favorite_is_loading.value = true;
      return;
    }

    final Future<void>? active_request = _favorite_request;
    if (active_request != null) {
      if (_favorite_request_store_revision != _store_data_revision) {
        _favorite_refresh_pending = true;
        _favorite_pending_language_revision =
            LanguageChangeHandler.current_revision;
      }
      await active_request;
      return;
    }
    await _fetch_favorite(reset: true);
  }

  /// 刷新收藏列表数据。
  Future<void> refresh_favorite() async {
    _favorite_requested = true;
    if (LanguageChangeHandler.is_refreshing.value) {
      _should_refresh_favorite = true;
      favorite_is_loading.value = true;
      return;
    }
    await _fetch_favorite(reset: true);
  }

  /// 加载收藏列表更多数据。
  Future<void> load_more_favorite() async {
    if (!favorite_has_more.value ||
        _favorite_request != null ||
        LanguageChangeHandler.is_refreshing.value) {
      return;
    }
    await _fetch_favorite(reset: false);
  }

  /// 从列表中移除指定收藏记录。
  void remove_favorite_item(String item_id) {
    favorite_list.removeWhere((BookshelfBookItem item) => item.id == item_id);
  }

  /// 请求收藏列表数据。
  Future<void> _fetch_favorite({
    required bool reset,
    int? language_revision,
  }) async {
    final Future<void>? active_request = _favorite_request;
    if (active_request != null) {
      if (reset) {
        _favorite_refresh_pending = true;
        _favorite_pending_language_revision = language_revision;
      }
      await active_request;
      return;
    }

    late final Future<void> request;
    request = _drain_favorite_requests(
      reset: reset,
      language_revision: language_revision,
    );
    _favorite_request_store_revision = _store_data_revision;
    _favorite_request = request;

    try {
      await request;
    } finally {
      if (identical(_favorite_request, request)) {
        _favorite_request = null;
      }
    }
  }

  /// 串行执行收藏请求；在途期间多次刷新只追加一轮。
  Future<void> _drain_favorite_requests({
    required bool reset,
    int? language_revision,
  }) async {
    bool next_reset = reset;
    int? next_language_revision = language_revision;

    do {
      _favorite_refresh_pending = false;
      _favorite_pending_language_revision = null;
      await _fetch_favorite_once(
        reset: next_reset,
        language_revision: next_language_revision,
      );

      next_reset = _favorite_refresh_pending;
      next_language_revision = _favorite_pending_language_revision;
    } while (next_reset);
  }

  /// 执行一轮收藏列表请求。
  Future<void> _fetch_favorite_once({
    required bool reset,
    int? language_revision,
  }) async {
    _favorite_requested = true;
    final int data_revision = _language_data_revision;
    final int store_revision = _store_data_revision;
    _favorite_request_store_revision = store_revision;
    final UserInformation? user_information =
        Get.isRegistered<UserInformation>()
        ? Get.find<UserInformation>()
        : null;
    final int? auth_revision = user_information?.auth_revision;
    final int request_page = reset ? 1 : _favorite_page + 1;
    if (reset) {
      favorite_is_loading.value = true;
    } else {
      favorite_is_loading_more.value = true;
    }

    try {
      final BookshelfListResult<FavoriteItem>? result =
          await _fetch_favorite_list(page: request_page, page_size: _page_size);

      if (data_revision != _language_data_revision ||
          store_revision != _store_data_revision ||
          (language_revision != null &&
              !LanguageChangeHandler.is_current_revision(language_revision)) ||
          !_can_apply_authenticated_response(user_information, auth_revision)) {
        return;
      }

      if (result == null) {
        if (reset) favorite_list.clear();
        favorite_has_more.value = false;
        _favorite_loaded = true;
        return;
      }

      final List<BookshelfBookItem> new_items = result.list
          .asMap()
          .entries
          .map(
            (MapEntry<int, FavoriteItem> entry) => _convert_favorite_item(
              entry.value,
              reset ? entry.key : favorite_list.length + entry.key,
            ),
          )
          .toList(growable: false);
      favorite_list.assignAll(
        _merge_unique_items<BookshelfBookItem>(
          current_items: reset ? const <BookshelfBookItem>[] : favorite_list,
          incoming_items: new_items,
          identity_of: (BookshelfBookItem item) => item.id,
        ),
      );
      _favorite_page = request_page;
      favorite_has_more.value = result.list.length >= _page_size;
      _favorite_loaded = true;
    } catch (error) {
      debugPrint('BookshelfStore favorite request failed: $error');
    } finally {
      if (data_revision == _language_data_revision &&
          store_revision == _store_data_revision) {
        if (reset) favorite_is_loading.value = false;
        favorite_is_loading_more.value = false;
      }
    }
  }

  /// 将收藏项转换为书架书籍项。
  BookshelfBookItem _convert_favorite_item(FavoriteItem item, int index) {
    final List<Color> colors =
        _cover_gradient_colors[index % _cover_gradient_colors.length];
    final bool has_progress = item.read_progress > 0;

    String? tag_key;
    if (item.publish_status == 2) {
      tag_key = 'bookshelf.tags.completed';
    } else if (item.publish_status == 1) {
      tag_key = 'bookshelf.tags.serializing';
    }

    String progress_key;
    Map<String, String> progress_args;
    if (has_progress) {
      progress_key = 'bookshelf.progress.read_progress';
      progress_args = <String, String>{
        'progress': item.read_progress.toStringAsFixed(0),
      };
    } else if (item.chapter_count > 0) {
      progress_key = 'bookshelf.progress.chapters';
      progress_args = <String, String>{'count': item.chapter_count.toString()};
    } else {
      progress_key = 'bookshelf.progress.unread';
      progress_args = <String, String>{};
    }

    return BookshelfBookItem(
      id: item.id,
      novel_id: item.novel_id,
      title: item.novel_title,
      publish_status: item.publish_status,
      introduction: item.introduction,
      category_names: item.category_names,
      progress_key: progress_key,
      progress_args: progress_args,
      tag_key: tag_key,
      cover_image_url: item.cover_url.isNotEmpty ? item.cover_url : null,
      cover_start_color: colors[0],
      cover_end_color: colors[1],
    );
  }

  // ==================== 关注 Tab 操作 ====================

  /// 加载关注列表首屏数据（懒加载，仅首次调用时请求）。
  Future<void> load_focus_if_needed() async {
    if (_focus_loaded) return;

    final Future<void>? active_request = _focus_request;
    if (active_request != null) {
      if (_focus_request_store_revision != _store_data_revision) {
        _focus_refresh_pending = true;
      }
      await active_request;
      return;
    }
    await _fetch_focus(reset: true);
  }

  /// 刷新关注列表数据。
  Future<void> refresh_focus() async {
    await _fetch_focus(reset: true);
  }

  /// 加载关注列表更多数据。
  Future<void> load_more_focus() async {
    if (!focus_has_more.value || _focus_request != null) return;
    await _fetch_focus(reset: false);
  }

  /// 从列表中移除指定关注作者。
  void remove_focus_item(String item_id) {
    focus_list.removeWhere((FocusAuthorItem item) => item.id == item_id);
  }

  /// 清空当前账号的书架缓存（退出或切换账号时调用）。
  ///
  /// 在途 Future 仍保留作为请求锁，但其响应会因数据版本变更而被丢弃。
  void clear() {
    _store_data_revision++;
    _should_refresh_history = false;
    _should_refresh_favorite = false;

    _history_page = 1;
    _history_loaded = false;
    _history_requested = false;
    _history_refresh_pending = false;
    _history_pending_language_revision = null;
    history_list.clear();
    history_has_more.value = true;
    history_is_loading.value = true;
    history_is_loading_more.value = false;

    _favorite_page = 1;
    _favorite_loaded = false;
    _favorite_requested = false;
    _favorite_refresh_pending = false;
    _favorite_pending_language_revision = null;
    favorite_list.clear();
    favorite_has_more.value = true;
    favorite_is_loading.value = true;
    favorite_is_loading_more.value = false;

    _focus_page = 1;
    _focus_loaded = false;
    _focus_refresh_pending = false;
    focus_list.clear();
    focus_has_more.value = true;
    focus_is_loading.value = true;
    focus_is_loading_more.value = false;
  }

  /// 请求关注列表数据。
  Future<void> _fetch_focus({required bool reset}) async {
    final Future<void>? active_request = _focus_request;
    if (active_request != null) {
      if (reset) _focus_refresh_pending = true;
      await active_request;
      return;
    }

    late final Future<void> request;
    request = _drain_focus_requests(reset: reset);
    _focus_request_store_revision = _store_data_revision;
    _focus_request = request;

    try {
      await request;
    } finally {
      if (identical(_focus_request, request)) {
        _focus_request = null;
      }
    }
  }

  /// 串行执行关注请求；在途期间多次刷新只追加一轮。
  Future<void> _drain_focus_requests({required bool reset}) async {
    bool next_reset = reset;
    do {
      _focus_refresh_pending = false;
      await _fetch_focus_once(reset: next_reset);
      next_reset = _focus_refresh_pending;
    } while (next_reset);
  }

  /// 执行一轮关注作者列表请求。
  Future<void> _fetch_focus_once({required bool reset}) async {
    final int store_revision = _store_data_revision;
    _focus_request_store_revision = store_revision;
    final UserInformation? user_information =
        Get.isRegistered<UserInformation>()
        ? Get.find<UserInformation>()
        : null;
    final int? auth_revision = user_information?.auth_revision;
    final int request_page = reset ? 1 : _focus_page + 1;
    if (reset) {
      focus_is_loading.value = true;
    } else {
      focus_is_loading_more.value = true;
    }

    try {
      final BookshelfListResult<FocusAuthorItem>? result =
          await _fetch_focus_list(page: request_page, page_size: _page_size);
      if (store_revision != _store_data_revision ||
          !_can_apply_authenticated_response(user_information, auth_revision)) {
        return;
      }

      if (result == null) {
        if (reset) focus_list.clear();
        focus_has_more.value = false;
        _focus_loaded = true;
        return;
      }

      focus_list.assignAll(
        _merge_unique_items<FocusAuthorItem>(
          current_items: reset ? const <FocusAuthorItem>[] : focus_list,
          incoming_items: result.list,
          identity_of: (FocusAuthorItem item) => item.id,
        ),
      );
      _focus_page = request_page;
      focus_has_more.value = result.list.length >= _page_size;
      _focus_loaded = true;
    } catch (error) {
      debugPrint('BookshelfStore focus request failed: $error');
    } finally {
      if (store_revision == _store_data_revision) {
        if (reset) focus_is_loading.value = false;
        focus_is_loading_more.value = false;
      }
    }
  }

  /// 校验请求响应是否仍属于发起请求时的登录会话。
  bool _can_apply_authenticated_response(
    UserInformation? user_information,
    int? auth_revision,
  ) {
    if (user_information == null) return true;
    return auth_revision != null &&
        user_information.can_apply_authenticated_response(auth_revision);
  }

  /// 合并分页数据并按稳定身份去重，同时处理单页内重复。
  List<T> _merge_unique_items<T>({
    required Iterable<T> current_items,
    required Iterable<T> incoming_items,
    required String Function(T item) identity_of,
  }) {
    final Set<String> identities = <String>{};
    final List<T> result = <T>[];
    for (final T item in <T>[...current_items, ...incoming_items]) {
      if (identities.add(identity_of(item))) result.add(item);
    }
    return result;
  }
}
