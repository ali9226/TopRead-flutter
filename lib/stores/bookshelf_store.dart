// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:get/get.dart';
import 'package:app/api/bookshelf.dart';
import 'package:app/pages/bookshelf/logic.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/language_util/language_change_handler.dart';

/// 书架页面全局数据仓库。
///
/// 缓存历史、收藏、关注三个 Tab 的列表数据，
/// 避免切换 Tab 时数据丢失导致重复请求。
class BookshelfStore extends GetxController {
  /// 语种刷新任务订阅。
  late final LanguageRefreshSubscription _language_refresh_subscription;

  /// 语种刷新状态监听。
  ///
  /// 用于承接恰好在统一刷新流程中首次打开书架的场景。
  late final Worker _language_refresh_worker;

  /// 当前书架多语言数据版本。
  ///
  /// 语种切换时递增，确保切换前发出的旧请求不能覆盖新语种数据。
  int _language_data_revision = 0;

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

  /// 历史列表是否已加载过（懒加载标记）。
  bool _history_loaded = false;

  /// 历史列表是否已经发起过加载。
  ///
  /// 与 [_history_loaded] 分开记录，保证语种切换发生在首个请求途中时，
  /// 新语种仍会重新发起请求。
  bool _history_requested = false;

  // ==================== 收藏 Tab ====================

  /// 收藏列表数据。
  final RxList<BookshelfBookItem> favorite_list = <BookshelfBookItem>[].obs;

  /// 收藏列表当前页码。
  int _favorite_page = 1;

  /// 收藏列表是否还有更多数据。
  final RxBool favorite_has_more = true.obs;

  /// 收藏列表是否正在首屏加载。
  final RxBool favorite_is_loading = true.obs;

  /// 收藏列表是否已加载过（懒加载标记）。
  bool _favorite_loaded = false;

  /// 收藏列表是否已经发起过加载。
  ///
  /// 与 [_favorite_loaded] 分开记录，避免语种切换中断首个请求后列表不再加载。
  bool _favorite_requested = false;

  // ==================== 关注 Tab ====================

  /// 关注作者列表数据。
  final RxList<FocusAuthorItem> focus_list = <FocusAuthorItem>[].obs;

  /// 关注列表当前页码。
  int _focus_page = 1;

  /// 关注列表是否还有更多数据。
  final RxBool focus_has_more = true.obs;

  /// 关注列表是否正在首屏加载。
  final RxBool focus_is_loading = true.obs;

  /// 关注列表是否已加载过（懒加载标记）。
  bool _focus_loaded = false;

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
    _language_refresh_worker.dispose();
    _language_refresh_subscription.dispose();
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

    _favorite_page = 1;
    _favorite_loaded = false;
    favorite_list.clear();
    favorite_has_more.value = true;
    favorite_is_loading.value = _should_refresh_favorite;
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
    if (!history_has_more.value || LanguageChangeHandler.is_refreshing.value) {
      return;
    }
    _history_page++;
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
    _history_requested = true;
    final int data_revision = _language_data_revision;
    if (reset) {
      _history_page = 1;
      history_is_loading.value = true;
    }

    final result = await inquire_read_record_list(
      page: _history_page,
      page_size: _page_size,
    );

    if (data_revision != _language_data_revision ||
        (language_revision != null &&
            !LanguageChangeHandler.is_current_revision(language_revision))) {
      return;
    }

    if (result != null) {
      final List<BookshelfBookItem> new_items = result.list
          .asMap()
          .map(
            (int index, ReadRecordItem item) => MapEntry(
              index,
              _convert_history_item(
                item,
                reset ? index : history_list.length + index,
              ),
            ),
          )
          .values
          .toList();

      if (reset) {
        history_list.assignAll(new_items);
      } else {
        history_list.addAll(new_items);
      }
      history_has_more.value = result.list.length >= _page_size;
    } else {
      if (reset) {
        history_list.clear();
      }
      history_has_more.value = false;
    }

    history_is_loading.value = false;
    _history_loaded = true;
  }

  /// 将阅读记录转换为书架书籍项。
  BookshelfBookItem _convert_history_item(ReadRecordItem item, int index) {
    final colors = cover_gradient_colors[index % cover_gradient_colors.length];
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
    if (!favorite_has_more.value || LanguageChangeHandler.is_refreshing.value) {
      return;
    }
    _favorite_page++;
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
    _favorite_requested = true;
    final int data_revision = _language_data_revision;
    if (reset) {
      _favorite_page = 1;
      favorite_is_loading.value = true;
    }

    final result = await inquire_favorite_list(
      page: _favorite_page,
      page_size: _page_size,
    );

    if (data_revision != _language_data_revision ||
        (language_revision != null &&
            !LanguageChangeHandler.is_current_revision(language_revision))) {
      return;
    }

    if (result != null) {
      final List<BookshelfBookItem> new_items = result.list
          .asMap()
          .map(
            (int index, FavoriteItem item) => MapEntry(
              index,
              _convert_favorite_item(
                item,
                reset ? index : favorite_list.length + index,
              ),
            ),
          )
          .values
          .toList();

      if (reset) {
        favorite_list.assignAll(new_items);
      } else {
        favorite_list.addAll(new_items);
      }
      favorite_has_more.value = result.list.length >= _page_size;
    } else {
      if (reset) {
        favorite_list.clear();
      }
      favorite_has_more.value = false;
    }

    favorite_is_loading.value = false;
    _favorite_loaded = true;
  }

  /// 将收藏项转换为书架书籍项。
  BookshelfBookItem _convert_favorite_item(FavoriteItem item, int index) {
    final colors = cover_gradient_colors[index % cover_gradient_colors.length];
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
    await _fetch_focus(reset: true);
  }

  /// 刷新关注列表数据。
  Future<void> refresh_focus() async {
    await _fetch_focus(reset: true);
  }

  /// 加载关注列表更多数据。
  Future<void> load_more_focus() async {
    if (!focus_has_more.value) return;
    _focus_page++;
    await _fetch_focus(reset: false);
  }

  /// 从列表中移除指定关注作者。
  void remove_focus_item(String item_id) {
    focus_list.removeWhere((FocusAuthorItem item) => item.id == item_id);
  }

  /// 请求关注列表数据。
  Future<void> _fetch_focus({required bool reset}) async {
    if (reset) {
      _focus_page = 1;
      focus_is_loading.value = true;
    }

    final result = await inquire_focus_author_list(
      page: _focus_page,
      page_size: _page_size,
    );

    if (result != null) {
      if (reset) {
        focus_list.assignAll(result.list);
      } else {
        focus_list.addAll(result.list);
      }
      focus_has_more.value = result.list.length >= _page_size;
    } else {
      if (reset) {
        focus_list.clear();
      }
      focus_has_more.value = false;
    }

    focus_is_loading.value = false;
    _focus_loaded = true;
  }
}
