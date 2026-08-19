import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart' as dio_lib;
import 'package:app/api/dio_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/short_story_read_data.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/stores/short_story_catalog_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/device/save_body_font_size.dart';
import 'package:app/pages/short_story_read/utils/short_story_content_cache.dart';

/// 短篇小说阅读页面逻辑层。
///
/// 负责管理短篇小说内容的加载、交互状态和 UI 控制。
///
/// 主要职责：
/// - 加载小说详情和正文内容
/// - 管理导航栏和评论栏的显示/隐藏
/// - 处理点赞/收藏等用户交互
/// - 处理滚动事件（向下滚动自动隐藏导航栏）
class ShortStoryReadLogic {
  /// 当前页面上下文。
  final BuildContext context;

  /// 小说 ID。
  final int story_id;

  /// 当前逻辑实例是否已经退出使用。
  ///
  /// 页面切换小说或退出后，旧请求可能仍在网络层执行。该标记用于阻止旧请求
  /// 回写响应式状态和共享目录，避免新页面被过期结果覆盖。
  bool _is_disposed = false;

  /// 短篇小说目录列表 Store。
  final ShortStoryCatalogStore _catalog_store =
      Get.find<ShortStoryCatalogStore>();

  // ==================== 数据状态 ====================

  /// 小说详情数据（从接口加载）。
  final Rxn<ShortStoryReadData> story_data = Rxn<ShortStoryReadData>();

  /// 小说正文内容（从远程 txt 文件加载）。
  final RxString content = ''.obs;

  /// 预加载的上一篇正文内容。
  final RxString previous_story_content = ''.obs;

  /// 预加载的下一篇正文内容。
  final RxString next_story_content = ''.obs;

  /// 上一篇正文是否正在后台预加载。
  final RxBool is_previous_story_preloading = false.obs;

  /// 下一篇正文是否正在后台预加载。
  final RxBool is_next_story_preloading = false.obs;

  // ==================== 加载状态 ====================

  /// 是否正在加载中（骨架屏显示条件）。
  final RxBool is_loading = true.obs;

  /// 是否加载失败（错误状态显示条件）。
  final RxBool is_error = false.obs;

  /// 是否正在加载正文内容。
  final RxBool is_content_loading = true.obs;

  /// 当前短篇小说是否已通过激励视频广告解锁。
  late final RxBool is_story_unlocked;

  // ==================== UI 控制状态 ====================

  /// 顶部导航栏是否可见。
  ///
  /// 点击阅读区域或滚动时自动切换。
  final RxBool is_appbar_visible = true.obs;

  /// 底部评论栏是否可见。
  ///
  /// 与导航栏联动，同时显示/隐藏。
  final RxBool is_bottom_bar_visible = true.obs;

  /// 当前阅读进度（0.0 ~ 1.0）。
  ///
  /// 用于进度条显示和拖动跳转。
  final RxDouble reading_progress = 0.0.obs;

  /// 当前正文字号大小。
  ///
  /// 可通过阅读设置调节，范围 16 ~ 36，默认值根据语种自动选择。
  late final RxDouble body_font_size;

  /// 字号最小值。
  static const double font_size_min = 16.0;

  /// 字号最大值。
  static const double font_size_max = 36.0;

  /// 字号调节步长。
  static const double font_size_step = 1.0;

  /// 是否正在自动阅读。
  final RxBool is_auto_reading = false.obs;

  /// 自动阅读速度（0.0 = 最慢，1.0 = 最快，默认 0.2）。
  late final RxDouble auto_read_speed;

  /// 是否正在点赞请求中（防止重复点击）。
  final RxBool is_like_loading = false.obs;

  /// 是否正在收藏请求中（防止重复点击）。
  final RxBool is_favorite_loading = false.obs;

  /// 上一次滚动偏移量（用于计算滚动方向）。
  double _last_scroll_offset = 0;

  /// 当前滚动方向开始时的偏移量。
  ///
  /// 使用方向累计距离而不是单帧位移，慢速滚动也能稳定触发栏位显隐。
  double _scroll_direction_anchor_offset = 0;

  /// 上一次有效滚动方向；null 表示尚未发生滚动。
  bool? _last_scroll_direction_down;

  /// 导航栏显隐需要累计的滚动距离。
  static const double _bar_visibility_scroll_threshold = 8;

  ShortStoryReadLogic({required this.context, required this.story_id}) {
    final double? saved_size = load_body_font_size();
    body_font_size = (saved_size ?? 18.0).obs;

    final double? saved_speed = load_auto_read_speed();
    auto_read_speed = (saved_speed ?? 0.2).obs;

    // 广告开关关闭时直接解锁所有内容。
    final ProjectConfigStore projectConfigStore = Get.find<ProjectConfigStore>();
    final bool ads_disabled = !projectConfigStore.current.is_ads_enabled;
    if (ads_disabled) {
      _unlocked_story_ids.add(story_id);
    }
    is_story_unlocked = (_unlocked_story_ids.contains(story_id) || ads_disabled).obs;
  }

  /// 增加正文字号（步长 2，最大 36），并持久化。
  void increase_font_size() {
    final double next = body_font_size.value + font_size_step;
    if (next <= font_size_max) {
      body_font_size.value = next;
      save_body_font_size(next);
    }
  }

  /// 减少正文字号（步长 2，最小 16），并持久化。
  void decrease_font_size() {
    final double next = body_font_size.value - font_size_step;
    if (next >= font_size_min) {
      body_font_size.value = next;
      save_body_font_size(next);
    }
  }

  /// 目录列表数据（从 Store 获取）。
  RxList<ShortStoryItem> get catalog_list => _catalog_store.catalog_list;

  /// 目录列表是否正在加载中（从 Store 获取）。
  RxBool get is_catalog_loading => _catalog_store.is_loading;

  /// 目录列表是否加载失败（从 Store 获取）。
  RxBool get is_catalog_error => _catalog_store.is_error;

  /// 使用已有目录数据初始化（翻页时避免重新请求目录列表）。
  ///
  /// 传入 [existing_catalog] 后，目录列表将直接使用该数据，
  /// 不会再触发网络请求。
  void set_existing_catalog(List<ShortStoryItem> existing_catalog) {
    _skip_catalog_fetch = true;
    _catalog_store.set_catalog_list(existing_catalog);
    _catalog_store.is_loading.value = false;
    _catalog_store.is_error.value = false;
  }

  /// 是否跳过目录请求（翻页时复用已有数据）。
  bool _skip_catalog_fetch = false;

  /// 获取当前语种代码。
  String get _current_language_code {
    return context.locale.languageCode.trim().toLowerCase();
  }

  /// 生成包含语种的缓存 key。
  ///
  /// 同一小说在不同语种下内容不同，需要分开缓存。
  String _cache_key(int story_id) {
    return '${story_id}_$_current_language_code';
  }

  /// 详情内存缓存。
  ///
  /// 用于切换上一篇/下一篇时减少等待；点赞等强实时字段仍会在用户操作后同步更新当前页面。
  /// key 格式："{story_id}_{language_code}"，避免语种切换后命中旧语种缓存。
  static final LinkedHashMap<String, ShortStoryReadData>
  _story_detail_memory_cache = LinkedHashMap<String, ShortStoryReadData>();

  /// 详情内存缓存最多保留的小说数量。
  static const int _story_detail_memory_cache_capacity = 40;

  /// 正文内存缓存。
  static final LinkedHashMap<String, String> _content_memory_cache =
      LinkedHashMap<String, String>();

  /// 正文内存缓存最多保留的小说数量。
  static const int _content_memory_cache_capacity = 12;

  /// 正在进行的正文加载任务，避免预加载与页面加载重复下载同一文件。
  static final Map<String, Future<String>> _content_load_futures =
      <String, Future<String>>{};

  /// 当前应用会话中已解锁的短篇 ID。
  ///
  /// 切换上下篇或重新进入页面时保留解锁状态，应用重启后重置。
  static final Set<int> _unlocked_story_ids = <int>{};

  /// 正文文件连接超时。
  static const Duration _content_connect_timeout = Duration(seconds: 12);

  /// 正文文件接收超时。
  static const Duration _content_receive_timeout = Duration(seconds: 25);

  /// 从 LRU 缓存读取数据，并把命中的条目移动到队尾。
  static T? _read_memory_cache<T>(LinkedHashMap<String, T> cache, String key) {
    final T? value = cache.remove(key);
    if (value != null) {
      cache[key] = value;
    }
    return value;
  }

  /// 写入 LRU 缓存，并在超过容量后移除最久未使用的条目。
  static void _write_memory_cache<T>(
    LinkedHashMap<String, T> cache,
    String key,
    T value,
    int capacity,
  ) {
    cache.remove(key);
    cache[key] = value;
    while (cache.length > capacity) {
      cache.remove(cache.keys.first);
    }
  }

  /// 读取详情内存缓存。
  ShortStoryReadData? _read_story_detail_cache(int target_story_id) {
    return _read_memory_cache<ShortStoryReadData>(
      _story_detail_memory_cache,
      _cache_key(target_story_id),
    );
  }

  /// 写入详情内存缓存。
  void _write_story_detail_cache(
    int target_story_id,
    ShortStoryReadData detail,
  ) {
    _write_memory_cache<ShortStoryReadData>(
      _story_detail_memory_cache,
      _cache_key(target_story_id),
      detail,
      _story_detail_memory_cache_capacity,
    );
  }



  /// 加载正文文本，优先走内存缓存，其次磁盘缓存，最后网络。
  Future<String> _fetch_content_text_with_cache(String content_url) async {
    if (content_url.isEmpty) return '';

    final String? memory_text = _read_memory_cache<String>(
      _content_memory_cache,
      content_url,
    );
    if (memory_text != null) return memory_text;

    final Future<String>? existing_future = _content_load_futures[content_url];
    if (existing_future != null) return existing_future;

    final Future<String> load_future = _load_content_text(content_url);
    _content_load_futures[content_url] = load_future;
    try {
      return await load_future;
    } finally {
      if (identical(_content_load_futures[content_url], load_future)) {
        _content_load_futures.remove(content_url);
      }
    }
  }

  Future<String> _load_content_text(String content_url) async {
    final String? disk_text = await ShortStoryContentCache.read(content_url);
    if (disk_text != null) {
      _write_memory_cache<String>(
        _content_memory_cache,
        content_url,
        disk_text,
        _content_memory_cache_capacity,
      );
      return disk_text;
    }

    /// 复用全局 Dio 单例，超时通过单次请求 Options 覆盖。
    final dio_lib.Dio dio = DioClient().instance;
    final dio_lib.Response<String> response = await dio.get<String>(
      content_url,
      options: dio_lib.Options(
        responseType: dio_lib.ResponseType.plain,
        connectTimeout: _content_connect_timeout,
        receiveTimeout: _content_receive_timeout,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final String text = response.data!;
      _write_memory_cache<String>(
        _content_memory_cache,
        content_url,
        text,
        _content_memory_cache_capacity,
      );
      await ShortStoryContentCache.write(content_url, text);
      return text;
    }

    return '';
  }

  // ==================== 计算属性 ====================

  /// 标题。
  String get title => story_data.value?.title ?? '';

  /// 阅读数。
  int get read_count => story_data.value?.read_count ?? 0;

  /// 评论数。
  int get comment_count => story_data.value?.comment_count ?? 0;

  /// 更新评论数（评论弹窗关闭后同步最新数量）。
  void update_comment_count(int new_count) {
    if (story_data.value == null) return;
    final updated = story_data.value!.copyWith(comment_count: new_count);
    story_data.value = updated;
    // 同步更新内存缓存，避免下次进入时读到旧数据。
    _write_story_detail_cache(story_id, updated);
  }

  /// 点赞数。
  int get like_count => story_data.value?.like_count ?? 0;

  /// 收藏数。
  int get favorite_count => story_data.value?.favorite_count ?? 0;

  /// 评分。
  String get score => story_data.value?.score ?? '';

  /// 分类标签列表。
  List<String> get category_list => story_data.value?.category_list ?? [];

  /// 是否已点赞。
  bool get is_liked => story_data.value?.is_liked ?? false;

  /// 是否已收藏。
  bool get is_favorited => story_data.value?.is_favorited ?? false;

  /// 是否有上一篇小说。
  ///
  /// 当前小说在目录列表中不是第一个时返回 true。
  bool get has_previous_story {
    if (catalog_list.isEmpty) return false;
    final int current_index = catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == story_id,
    );
    return current_index > 0;
  }

  /// 是否有下一篇小说。
  ///
  /// 当前小说在目录列表中不是最后一个时返回 true。
  bool get has_next_story {
    if (catalog_list.isEmpty) return false;
    final int current_index = catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == story_id,
    );
    return current_index >= 0 && current_index < catalog_list.length - 1;
  }

  /// 获取上一篇小说的 ID。
  ///
  /// 如果没有上一篇，返回 null。
  int? get previous_story_id {
    if (!has_previous_story) return null;
    final int current_index = catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == story_id,
    );
    return catalog_list[current_index - 1].id;
  }

  /// 获取上一篇小说数据。
  ///
  /// 如果没有上一篇，返回 null。
  ShortStoryItem? get previous_story_item {
    if (!has_previous_story) return null;
    final int current_index = catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == story_id,
    );
    return catalog_list[current_index - 1];
  }

  /// 获取下一篇小说数据。
  ///
  /// 如果没有下一篇，返回 null。
  ShortStoryItem? get next_story_item {
    if (!has_next_story) return null;
    final int current_index = catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == story_id,
    );
    return catalog_list[current_index + 1];
  }

  /// 获取下一篇小说的 ID。
  ///
  /// 如果没有下一篇，返回 null。
  int? get next_story_id {
    if (!has_next_story) return null;
    final int current_index = catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == story_id,
    );
    return catalog_list[current_index + 1].id;
  }

  // ==================== 初始化 ====================

  /// 初始化页面数据。
  ///
  /// 开始加载小说详情和正文。
  Future<bool> initialize() {
    return _load_story_detail();
  }

  /// 加载小说详情。
  ///
  /// 调用 `novel/short_story_read` 接口获取短篇小说详情，
  /// 成功后加载正文内容。
  /// 骨架屏持续到所有内容加载完成才消失。
  Future<bool> _load_story_detail() async {
    if (_is_disposed) return false;

    is_loading.value = true;
    is_error.value = false;

    try {
      final ShortStoryReadData? cached_detail = _read_story_detail_cache(
        story_id,
      );
      final ResultsType<ShortStoryReadData> results =
          await postRequest<ShortStoryReadData>(
            path: 'novel/short_story_read',
            parameter: <String, dynamic>{'id': story_id},
            fromJson: (Map<String, dynamic> json) =>
                ShortStoryReadData.from_json(json),
          );

      if (_is_disposed) return false;

      final ShortStoryReadData? detail =
          results.status && results.content != null
          ? results.content
          : cached_detail;
      if (detail == null) {
        is_loading.value = false;
        is_error.value = true;
        is_content_loading.value = false;
        return false;
      }
      _write_story_detail_cache(story_id, detail);

      if (_is_disposed) return false;
      story_data.value = detail;

      // 加载正文内容（优先内存/磁盘缓存，其次远程 txt）。
      final bool content_loaded = await _load_story_content(detail.content_url);

      if (_is_disposed) return false;

      if (!content_loaded) {
        is_loading.value = false;
        is_error.value = true;
        return false;
      }

      // 骨架屏持续到内容加载完成才消失。
      is_loading.value = false;

      // 小说详情加载完成后立即预加载目录列表（不等用户打开弹窗）。
      unawaited(_load_catalog());

      // 如果目录已经复用完成，也立即预加载上一篇/下一篇正文。
      if (catalog_list.isNotEmpty) {
        _preload_adjacent_story_contents();
      }
      return true;
    } catch (e) {
      if (_is_disposed) return false;
      is_loading.value = false;
      is_error.value = true;
      is_content_loading.value = false;
      return false;
    }
  }

  /// 加载小说正文内容。
  ///
  /// 从 [content_url] 下载 txt 文件并解析内容。
  /// 加载失败时 content 设为空字符串，不影响页面展示。
  Future<bool> _load_story_content(String content_url) async {
    if (content_url.isEmpty) {
      content.value = '';
      is_content_loading.value = false;
      return false;
    }

    is_content_loading.value = true;

    try {
      final String loaded_content = await _fetch_content_text_with_cache(
        content_url,
      );
      if (_is_disposed) return false;
      content.value = loaded_content;
      return loaded_content.trim().isNotEmpty;
    } catch (e) {
      if (_is_disposed) return false;
      content.value = '';
      return false;
    } finally {
      if (!_is_disposed) {
        is_content_loading.value = false;
      }
    }
  }

  /// 预加载目录列表。
  ///
  /// 小说详情加载成功后立即调用，将当前小说的id传给接口，
  /// 使该小说在目录列表中排在最前面。
  /// 加载失败不影响页面展示，用户打开弹窗时会看到空状态。
  /// 如果已通过 [set_existing_catalog] 设置了已有数据，则跳过请求。
  ///
  /// 特殊处理：列表接口使用 INNER JOIN novel_main_language，
  /// 如果当前语种缺少语言记录，当前小说会被静默过滤。
  /// 所以加载完成后会检查当前小说是否在列表中，不在则用已加载的详情数据补到首位。
  Future<void> _load_catalog() async {
    if (_is_disposed) return;

    if (_skip_catalog_fetch) {
      _preload_adjacent_story_contents();
      return;
    }

    _catalog_store.is_loading.value = true;
    _catalog_store.is_error.value = false;
    try {
      final ResultsType<List<ShortStoryItem>> results =
          await postRequest<List<ShortStoryItem>>(
            path: 'novel/short_story',
            parameter: <String, dynamic>{'id': story_id},
            fromJsonList: (List<dynamic> json) =>
                ShortStoryItem.from_json_list(json),
          );

      if (_is_disposed) return;

      if (results.status && results.content != null) {
        final bool server_has_more = results.content!.isNotEmpty;
        List<ShortStoryItem> items = results.content!;

        // 列表接口可能因语种记录缺失等原因未返回当前小说，
        // 用已加载的详情数据补到列表首位，保证目录中一定有当前小说。
        final bool has_current = items.any(
          (ShortStoryItem item) => item.id == story_id,
        );
        if (!has_current && story_data.value != null) {
          final ShortStoryReadData detail = story_data.value!;
          final ShortStoryItem current_item = ShortStoryItem(
            id: detail.id,
            title: detail.title,
            description: detail.introduction,
            cover_url: detail.cover_url,
            tags: detail.category_list,
            like_count: detail.like_count,
            is_liked: detail.is_liked,
          );
          items = <ShortStoryItem>[current_item, ...items];
        }

        _catalog_store.set_catalog_list(items);
        _catalog_store.has_more = server_has_more;
        _preload_adjacent_story_contents();
      } else {
        _catalog_store.is_error.value = true;
      }
    } catch (e) {
      if (_is_disposed) return;
      _catalog_store.is_error.value = true;
    } finally {
      if (!_is_disposed) {
        _catalog_store.is_loading.value = false;
      }
    }
  }

  /// 后台静默预加载上一篇和下一篇正文。
  ///
  /// 当前正文已经显示后再执行，不阻塞页面阅读；切换上下篇时，如果缓存命中，
  /// 新页面可以直接从内存/磁盘读取正文，减少骨架屏等待时间。
  void _preload_adjacent_story_contents() {
    final int? previous_id = previous_story_id;
    final int? next_id = next_story_id;

    if (previous_id != null) {
      _preload_story_content_by_id(previous_id, is_next: false);
    } else {
      previous_story_content.value = '';
    }

    if (next_id != null) {
      _preload_story_content_by_id(next_id, is_next: true);
    } else {
      next_story_content.value = '';
    }
  }

  /// 后台预加载指定小说的详情和正文。
  Future<void> _preload_story_content_by_id(
    int target_story_id, {
    required bool is_next,
  }) async {
    final RxBool loading_flag = is_next
        ? is_next_story_preloading
        : is_previous_story_preloading;
    final RxString target_content = is_next
        ? next_story_content
        : previous_story_content;

    if (loading_flag.value) return;
    loading_flag.value = true;

    try {
      ShortStoryReadData? detail = _read_story_detail_cache(target_story_id);

      if (detail == null) {
        // TODO 预加载使用 preview 接口，不记录历史、不增加阅读数
        final ResultsType<ShortStoryReadData> results =
            await postRequest<ShortStoryReadData>(
              path: 'novel/short_story_read_preview',
              parameter: <String, dynamic>{'id': target_story_id},
              fromJson: (Map<String, dynamic> json) =>
                  ShortStoryReadData.from_json(json),
            );

        if (_is_disposed || !results.status || results.content == null) {
          return;
        }
        detail = results.content!;
        _write_story_detail_cache(target_story_id, detail);
      }

      final String text = await _fetch_content_text_with_cache(
        detail.content_url,
      );

      if (_is_disposed) return;
      if (is_next && next_story_id == target_story_id) {
        target_content.value = text;
      }
      if (!is_next && previous_story_id == target_story_id) {
        target_content.value = text;
      }
    } catch (_) {
      // 静默预加载失败不影响当前阅读；用户真正切换时仍会正常加载。
    } finally {
      if (!_is_disposed) {
        loading_flag.value = false;
      }
    }
  }

  /// 重新加载目录列表。
  ///
  /// 目录弹窗中点击重试时调用。
  Future<void> reload_catalog() async {
    _skip_catalog_fetch = false;
    await _load_catalog();
  }

  // ==================== UI 交互 ====================

  /// 切换顶部导航栏和底部评论栏的显示状态。
  ///
  /// 点击阅读区域时触发，同时切换两者的可见性。
  void toggle_bars_visibility() {
    is_appbar_visible.value = !is_appbar_visible.value;
    is_bottom_bar_visible.value = !is_bottom_bar_visible.value;

    _scroll_direction_anchor_offset = _last_scroll_offset;
    _last_scroll_direction_down = null;
  }

  /// 解锁当前短篇小说的全部正文。
  void unlock_current_story() {
    _unlocked_story_ids.add(story_id);
    is_story_unlocked.value = true;
  }

  /// 处理滚动事件。
  ///
  /// 向下滚动超过阈值时自动隐藏导航栏和评论栏。
  /// 向上滚动超过阈值时自动显示导航栏和评论栏。
  ///
  /// 参数：
  /// - [offset] 当前滚动偏移量。
  void on_scroll(double offset) {
    // 滚动到顶部时，自动显示导航栏和评论栏。
    if (offset <= 0 && !is_appbar_visible.value) {
      is_appbar_visible.value = true;
      is_bottom_bar_visible.value = true;
      _last_scroll_offset = 0;
      _scroll_direction_anchor_offset = 0;
      _last_scroll_direction_down = null;
      return;
    }

    if (offset == _last_scroll_offset) return;

    final bool is_scrolling_down = offset > _last_scroll_offset;
    if (_last_scroll_direction_down == null ||
        _last_scroll_direction_down != is_scrolling_down) {
      _scroll_direction_anchor_offset = _last_scroll_offset;
      _last_scroll_direction_down = is_scrolling_down;
    }
    _last_scroll_offset = offset;

    final double scroll_distance = (offset - _scroll_direction_anchor_offset)
        .abs();

    // 向下滚动且超过阈值：隐藏导航栏和评论栏。
    if (is_scrolling_down &&
        is_appbar_visible.value &&
        scroll_distance > _bar_visibility_scroll_threshold) {
      is_appbar_visible.value = false;
      is_bottom_bar_visible.value = false;
      _scroll_direction_anchor_offset = offset;
    }

    // 向上滚动且超过阈值：显示导航栏和评论栏。
    if (!is_scrolling_down &&
        !is_appbar_visible.value &&
        scroll_distance > _bar_visibility_scroll_threshold) {
      is_appbar_visible.value = true;
      is_bottom_bar_visible.value = true;
      _scroll_direction_anchor_offset = offset;
    }
  }

  /// 更新阅读进度。
  ///
  /// 由滚动事件触发，计算当前滚动位置占总内容的百分比。
  ///
  /// 参数：
  /// - [scroll_offset] 当前滚动偏移量。
  /// - [max_scroll_extent] 最大滚动距离（内容总高度 - 可视区域高度）。
  /// - [max_progress] 当前可见内容在完整正文中的最大进度。
  void update_reading_progress(
    double scroll_offset,
    double max_scroll_extent, {
    double max_progress = 1.0,
  }) {
    if (max_scroll_extent <= 0) {
      reading_progress.value = 0.0;
      return;
    }
    final double safe_max_progress = max_progress.clamp(0.0, 1.0);
    final double visible_progress = (scroll_offset / max_scroll_extent).clamp(
      0.0,
      1.0,
    );
    // 接近当前可见区域末尾时直接设为它对应的完整正文进度，
    // 避免进度数字在边界附近抖动。
    if (visible_progress > 0.98) {
      reading_progress.value = safe_max_progress;
    } else {
      reading_progress.value = visible_progress * safe_max_progress;
    }
  }

  // ==================== 点赞/收藏 ====================

  /// 点击点赞/取消点赞（乐观更新）。
  ///
  /// 立即切换本地状态，然后发起请求。
  /// 请求失败时回退状态，请求成功时保持不变。
  /// 请求期间通过 is_like_loading 防止重复点击。
  Future<bool?> toggle_like() async {
    if (story_data.value == null || is_like_loading.value) return null;

    is_like_loading.value = true;

    // 乐观更新：立即切换状态。
    final bool previous_status = story_data.value!.is_liked;
    final int previous_count = story_data.value!.like_count;
    final bool optimistic_status = !previous_status;
    final int optimistic_count = optimistic_status
        ? previous_count + 1
        : (previous_count > 0 ? previous_count - 1 : 0);

    final optimistic_data = story_data.value!.copyWith(
      is_liked: optimistic_status,
      like_count: optimistic_count,
    );
    story_data.value = optimistic_data;
    _write_story_detail_cache(story_id, optimistic_data);
    sync_like_to_catalog(
      story_id,
      optimistic_status,
      optimistic_status ? 1 : -1,
    );

    try {
      final ResultsType<Map<String, dynamic>> results =
          await postRequest<Map<String, dynamic>>(
            path: 'novel_like/click',
            parameter: <String, dynamic>{'novel_id': story_id},
            fromJson: (Map<String, dynamic> json) => json,
          );

      if (!results.status || results.content == null) {
        // 请求失败，回退状态。
        final reverted = story_data.value!.copyWith(
          is_liked: previous_status,
          like_count: previous_count,
        );
        story_data.value = reverted;
        _write_story_detail_cache(story_id, reverted);
        sync_like_to_catalog(
          story_id,
          previous_status,
          previous_status ? 1 : -1,
        );
        return null;
      }

      final dynamic server_like = results.content!['like'];
      final bool server_status = server_like == true || server_like == 1;
      // 服务端状态与乐观更新不一致时，以服务端为准。
      if (server_status != optimistic_status) {
        final server_data = story_data.value!.copyWith(
          is_liked: server_status,
          like_count: previous_count,
        );
        story_data.value = server_data;
        _write_story_detail_cache(story_id, server_data);
        sync_like_to_catalog(story_id, server_status, server_status ? 1 : -1);
      }
      return story_data.value?.is_liked;
    } catch (_) {
      // 异常时回退状态。
      final reverted = story_data.value!.copyWith(
        is_liked: previous_status,
        like_count: previous_count,
      );
      story_data.value = reverted;
      _write_story_detail_cache(story_id, reverted);
      sync_like_to_catalog(story_id, previous_status, previous_status ? 1 : -1);
      return null;
    } finally {
      is_like_loading.value = false;
    }
  }

  /// 点击收藏/取消收藏（乐观更新）。
  ///
  /// 立即切换本地状态，然后发起请求。
  /// 请求失败时回退状态，请求成功时保持不变。
  /// 请求期间通过 is_favorite_loading 防止重复点击。
  Future<bool?> toggle_favorite() async {
    if (story_data.value == null || is_favorite_loading.value) return null;

    is_favorite_loading.value = true;

    // 乐观更新：立即切换状态。
    final bool previous_status = story_data.value!.is_favorited;
    final int previous_count = story_data.value!.favorite_count;
    final bool optimistic_status = !previous_status;
    final int optimistic_count = optimistic_status
        ? previous_count + 1
        : (previous_count > 0 ? previous_count - 1 : 0);

    final optimistic_data = story_data.value!.copyWith(
      is_favorited: optimistic_status,
      favorite_count: optimistic_count,
    );
    story_data.value = optimistic_data;
    _write_story_detail_cache(story_id, optimistic_data);

    try {
      final ResultsType<Map<String, dynamic>> results =
          await postRequest<Map<String, dynamic>>(
            path: 'novel_favorite/click',
            parameter: <String, dynamic>{'novel_id': story_id},
            fromJson: (Map<String, dynamic> json) => json,
          );

      if (!results.status || results.content == null) {
        // 请求失败，回退状态。
        final reverted = story_data.value!.copyWith(
          is_favorited: previous_status,
          favorite_count: previous_count,
        );
        story_data.value = reverted;
        _write_story_detail_cache(story_id, reverted);
        return null;
      }

      final dynamic server_favorite = results.content!['favorite'];
      final bool server_status =
          server_favorite == true || server_favorite == 1;
      // 服务端状态与乐观更新不一致时，以服务端为准。
      if (server_status != optimistic_status) {
        final server_data = story_data.value!.copyWith(
          is_favorited: server_status,
          favorite_count: previous_count,
        );
        story_data.value = server_data;
        _write_story_detail_cache(story_id, server_data);
      }

      // 只在服务端确认短篇小说已加入收藏后申请系统通知权限。
      if (server_status) {
        unawaited(NotificationPermissionRequest.request_after_novel_favorite());
      }
      return story_data.value?.is_favorited;
    } catch (_) {
      // 异常时回退状态。
      final reverted = story_data.value!.copyWith(
        is_favorited: previous_status,
        favorite_count: previous_count,
      );
      story_data.value = reverted;
      _write_story_detail_cache(story_id, reverted);
      return null;
    } finally {
      is_favorite_loading.value = false;
    }
  }

  /// 重新加载内容。
  ///
  /// 错误状态下的重试按钮调用此方法。
  Future<void> retry() async {
    await _load_story_detail();
  }

  /// 同步当前详情到内存缓存。
  ///
  /// 目录弹窗内操作当前小说时会直接更新详情对象，需要同时刷新缓存，
  /// 防止切换离开再返回后重新显示旧状态。
  void sync_current_story_cache() {
    final ShortStoryReadData? detail = story_data.value;
    if (detail == null) return;
    _write_story_detail_cache(story_id, detail);
  }

  /// 停止当前逻辑实例接收异步结果。
  void dispose({bool clear_catalog = false}) {
    _is_disposed = true;
    if (clear_catalog) {
      _catalog_store.clear();
    }
  }

  /// 同步点赞状态到目录列表。
  ///
  /// 当正文底部栏点赞/取消点赞后，更新目录列表中对应小说的状态，
  /// 保证打开目录弹窗时点赞状态一致。
  ///
  /// 参数：
  /// - [target_story_id] 被点赞的小说 ID。
  /// - [is_liked] 最新点赞状态。
  /// - [count_delta] 点赞数变化量（+1 或 -1）。
  void sync_like_to_catalog(
    int target_story_id,
    bool is_liked,
    int count_delta,
  ) {
    final int index = catalog_list.indexWhere(
      (ShortStoryItem item) => item.id == target_story_id,
    );
    if (index == -1) return;

    final ShortStoryItem old_item = catalog_list[index];
    final int next_count = old_item.like_count + count_delta;
    catalog_list[index] = old_item.copyWith(
      is_liked: is_liked,
      like_count: next_count < 0 ? 0 : next_count,
    );
  }
}
