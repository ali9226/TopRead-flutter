// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/get_chapter_content.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/device/save_body_font_size.dart';
import 'package:app/util/percentage_probability.dart';

import 'style.dart';
import 'utils/read_models.dart';
import 'utils/progress_calculator.dart';
import 'utils/chapter_cache.dart';
import 'utils/detail_builder.dart';
import 'logic/interaction_handler.dart';
import 'logic/progress_handler.dart';

export 'utils/read_models.dart';

/// 章节正文加载器。
typedef ChapterContentLoader = Future<String> Function(String chapter_id);

/// 阅读页逻辑层。
///
/// 负责章节加载、缓存管理、滚动导航等核心逻辑。
/// 互动操作抽离到 [ReadInteractionMixin]，进度计算抽离到 [ReadProgressMixin]。
class Logic extends GetxController with ReadInteractionMixin, ReadProgressMixin {
  /// 路由传入的书籍 id。
  final int story_id;

  /// 路由传入的标题。
  final String story_title;

  /// 加载状态。
  var is_loading = true.obs;

  /// 是否正在加载下一章中（纯状态标记，不触发 UI 重建）。
  bool is_loading_next = false;

  /// 当前下一章拼接任务完成信号。
  Completer<void>? _load_next_completer;

  /// 是否正在切换章节（上一章/下一章/进度跳转）。
  var is_switching_chapter = false.obs;

  /// 是否正在跳转章节（目录点击，显示骨架屏）。
  var is_jumping_chapter = false.obs;

  /// 错误状态。
  var is_error = false.obs;

  /// 当前阅读到的章节索引。
  var current_chapter_index = 0.obs;

  /// 当前阅读到的章节ID。
  int current_chapter_db_id = 0;

  /// 当前已加载到的章节索引。
  int get loaded_chapter_index => _loaded_chapter_index;
  int _loaded_chapter_index = 0;

  /// 当前已加载的最小章节索引。
  int get min_loaded_chapter_index => _min_loaded_chapter_index;
  int _min_loaded_chapter_index = 0;

  /// 是否正在加载上一章中。
  bool is_loading_prev = false;

  /// 主动跳章时预先拼接到目标章前面的章节数。
  static const int _jump_window_before_count = 1;

  /// 主动跳章时预先拼接到目标章后面的章节数。
  static const int _jump_window_after_count = 1;

  /// 当前阅读窗口版本。
  int _chapter_window_generation = 0;

  /// 正在进行的章节正文请求。
  final Map<int, Future<String>> _chapter_fetch_in_flight = <int, Future<String>>{};

  /// 外部页面提供的"等待主滚动区域空闲"回调。
  Future<void> Function()? wait_until_chapter_mutation_allowed;

  /// 外部页面提供的"保持可视锚点后执行插入"回调。
  Future<void> Function(VoidCallback mutation, int anchor_chapter_index)? preserve_chapter_anchor;

  /// 章节正文进入当前阅读窗口后的回调。
  ValueChanged<int>? on_chapter_loaded;

  /// 章节锚点 key 映射。
  final Map<int, GlobalKey> _chapter_keys = {};

  /// 当前阅读会话内每章的原生广告概率判断结果。
  final Map<int, bool> _chapter_native_ad_decisions = <int, bool>{};

  /// 当前阅读会话内每章的"看视频免广告"提示概率判断结果。
  final Map<int, bool> _chapter_video_ad_hint_decisions = <int, bool>{};

  /// 是否显示导航栏。
  var show_navigation = false.obs;

  /// 是否已点赞。
  var is_liked = false.obs;

  /// 点赞数。
  var like_count = 0.obs;

  /// 是否正在点赞请求中。
  var is_like_loading = false.obs;

  /// 是否正在收藏请求中。
  var is_favorite_loading = false.obs;

  /// 是否已收藏。
  var is_favorited = false.obs;

  /// 同步点赞状态到底层数据（点赞/取消点赞后调用）。
  @override
  void sync_like_state(bool new_status, int new_count) {
    is_liked.value = new_status;
    like_count.value = new_count;
    final info = _store.novel_info.value;
    if (info == null) return;
    final updated = NovelInfo(
      id: info.id,
      title: info.title,
      subtitle: info.subtitle,
      score: info.score,
      focus_on: info.focus_on,
      is_liked: new_status,
      is_favorited: info.is_favorited,
      author_id: info.author_id,
      source_type: info.source_type,
      publish_status: info.publish_status,
      recommend_status: info.recommend_status,
      sorting: info.sorting,
      read_count: info.read_count,
      comment_count: info.comment_count,
      like_count: new_count.toString(),
      favorite_count: info.favorite_count,
      latest_chapter_no: info.latest_chapter_no,
      latest_update_time: info.latest_update_time,
      remark: info.remark,
      create_time: info.create_time,
      update_time: info.update_time,
      remove_status: info.remove_status,
      remove_time: info.remove_time,
      author_name: info.author_name,
      author_avatar: info.author_avatar,
      language_info: info.language_info,
      category_list: info.category_list,
      comment_list: info.comment_list,
      chapter_info: info.chapter_info,
    );
    _store.set_novel_info(updated);
  }

  /// 正文字号。
  late final RxDouble body_font_size;

  /// 字号最小值。
  static const double font_size_min = 16.0;

  /// 字号最大值。
  static const double font_size_max = 36.0;

  /// 字号调节步长。
  static const double font_size_step = 1.0;

  /// 是否正在自动阅读。
  var is_auto_reading = false.obs;

  /// 自动阅读速度。
  late final RxDouble auto_read_speed;

  /// 滚动方向检测状态。
  double _last_scroll_offset = 0;
  bool _is_scrolling_down = false;
  double _scroll_direction_anchor_offset = 0;
  bool? _last_scroll_direction_down;

  /// 小说阅读仓库。
  final NovelReadingStore _store;

  /// 章节正文加载器。
  final ChapterContentLoader _chapter_content_loader;

  /// 书籍总字数。
  int _total_word_count = 0;

  /// 标签颜色值列表。
  static final List<int> tag_color_value_list = ColorConstants.tagColorList
      .map((Color color) => color.value)
      .toList();

  // ==================== Mixin 接口实现 ====================

  @override
  NovelReadingStore get store => _store;

  @override
  int get total_word_count => _total_word_count;

  // ==================== 构造/析构 ====================

  /// 目录列表。
  List<NovelChapterInfo> get chapter_list => _store.chapter_list;

  /// 当前详情对应的 novel_main_language.id。
  int get current_novel_language_id =>
      int.tryParse(_store.novel_info.value?.language_info.id ?? '') ?? 0;

  /// 当前已进入阅读窗口的章节索引集合。
  Set<int> get loaded_chapter_indexes => _store.reading_items
      .map((ReadingContentItem item) => item.chapter_index)
      .where((int chapter_index) => chapter_index >= 0)
      .toSet();

  /// 最小合法书籍 id 阈值。
  static const int _min_valid_story_id = 0;

  /// 页面滚动控制器。
  late final ScrollController scroll_controller;

  Logic({
    required this.story_id,
    required this.story_title,
    NovelReadingStore? reading_store,
    ChapterContentLoader chapter_content_loader = get_chapter_content,
    double? initial_body_font_size,
    double? initial_auto_read_speed,
  }) : _store = reading_store ?? NovelReadingStore(),
       _chapter_content_loader = chapter_content_loader {
    scroll_controller = ScrollController();
    body_font_size = (initial_body_font_size ?? load_body_font_size() ?? 18.0).obs;
    auto_read_speed = (initial_auto_read_speed ?? load_auto_read_speed() ?? 0.2).obs;
    _store.clear_novel_info();
  }

  @override
  void onClose() {
    _chapter_window_generation++;
    _chapter_native_ad_decisions.clear();
    _chapter_video_ad_hint_decisions.clear();
    _chapter_fetch_in_flight.clear();
    scroll_controller.dispose();
    super.onClose();
  }

  // ==================== 广告概率判断 ====================

  /// 为指定章节完成一次性原生广告概率判断。
  bool resolve_chapter_native_ad_decision({
    required int chapter_index,
    required int probability,
    int? roll,
  }) {
    final bool? existing_decision = _chapter_native_ad_decisions[chapter_index];
    if (existing_decision != null) return existing_decision;

    final bool should_show = PercentageProbability.is_hit(probability, roll: roll);
    _chapter_native_ad_decisions[chapter_index] = should_show;
    return should_show;
  }

  /// 查询指定章节已经固定的原生广告展示结果。
  bool should_show_native_ad_for_chapter(int chapter_index) {
    return _chapter_native_ad_decisions[chapter_index] ?? false;
  }

  /// 为指定章节完成一次性"看视频免广告"提示概率判断。
  bool resolve_chapter_video_ad_hint_decision({
    required int chapter_index,
    required int probability,
    int? roll,
  }) {
    final bool? existing_decision = _chapter_video_ad_hint_decisions[chapter_index];
    if (existing_decision != null) return existing_decision;

    final bool should_show = PercentageProbability.is_hit(probability, roll: roll);
    _chapter_video_ad_hint_decisions[chapter_index] = should_show;
    return should_show;
  }

  // ==================== 数据初始化 ====================

  /// 更新总字数。
  void _update_total_word_count() {
    int total = 0;
    for (var chapter in _store.chapter_list) {
      total += chapter.word_count;
    }
    if (total > 0) {
      _total_word_count = total;
    }
  }

  /// 请求书籍详情接口。
  Future<void> fetch_info({
    bool force = false,
    bool show_loading = true,
    bool bypass_chapter_cache = false,
  }) async {
    if (!force && _store.novel_info.value != null && _store.reading_items.isNotEmpty) {
      is_loading.value = false;
      return;
    }

    final bool has_existing_content = _store.reading_items.isNotEmpty;
    is_loading.value = show_loading || !has_existing_content;
    is_error.value = false;
    _chapter_window_generation++;
    _chapter_native_ad_decisions.clear();
    _chapter_video_ad_hint_decisions.clear();
    _loaded_chapter_index = 0;
    _min_loaded_chapter_index = 0;
    current_chapter_index.value = 0;
    current_chapter_db_id = 0;
    _chapter_keys.clear();
    if (bypass_chapter_cache) {
      _store.clear_chapter_content_cache();
    }

    final ResultsType<NovelInfo> results = await postRequest<NovelInfo>(
      path: 'novel/get_info',
      parameter: <String, dynamic>{'id': story_id},
      fromJson: (Map<String, dynamic> json) => NovelInfo.from_json(json),
    );

    if (results.status && results.content != null) {
      _store.set_novel_info(results.content!);
      unawaited(BookshelfSyncService.history_changed());
      _total_word_count = results.content!.language_info.word_count;

      is_liked.value = results.content!.is_liked;
      like_count.value = int.tryParse(results.content!.like_count) ?? 0;
      is_favorited.value = results.content!.is_favorited;

      await fetch_directory(results.content!.language_info.id);

      if (_store.chapter_list.isNotEmpty) {
        final NovelChapterInfo first_chapter = _store.chapter_list.first;
        final String content = await _fetch_chapter_content(0, force: bypass_chapter_cache);
        _store.set_initial_content(
          first_chapter.title,
          first_chapter.chapter_no,
          0,
          0,
          first_chapter.word_count,
          content,
        );
        on_chapter_loaded?.call(0);
        _loaded_chapter_index = 0;
        _min_loaded_chapter_index = 0;
        current_chapter_index.value = 0;
        current_chapter_db_id = int.tryParse(first_chapter.id) ?? 0;
        _preload_adjacent_chapters(0);
      }

      is_loading.value = false;
    } else {
      is_error.value = !(force && has_existing_content && !show_loading);
      is_loading.value = false;
    }
  }

  /// 请求章节目录接口。
  Future<void> fetch_directory(String novel_language_id) async {
    final ResultsType<List<NovelChapterInfo>> results =
        await postRequest<List<NovelChapterInfo>>(
          path: 'novel_chapter/inquire',
          parameter: <String, dynamic>{'novel_language_id': novel_language_id},
          fromJsonList: (List<dynamic> json) {
            return json
                .map((e) => NovelChapterInfo.from_json(Map<String, dynamic>.from(e)))
                .toList();
          },
        );

    if (results.status && results.content != null) {
      _store.set_chapter_list(results.content!);
      _update_total_word_count();
    }
  }

  // ==================== 章节加载 ====================

  /// 等待到滚动空闲后再修改正文列表。
  Future<void> _wait_until_chapter_mutation_allowed() async {
    await wait_until_chapter_mutation_allowed?.call();
  }

  /// 加载并追加下一章内容。
  Future<void> load_next_chapter() async {
    if (is_loading_next) {
      await _load_next_completer?.future;
      return;
    }

    if (_store.chapter_list.isEmpty || _loaded_chapter_index >= _store.chapter_list.length - 1) {
      return;
    }

    is_loading_next = true;
    final Completer<void> load_completer = Completer<void>();
    _load_next_completer = load_completer;

    try {
      final int window_generation = _chapter_window_generation;
      final int expected_loaded_index = _loaded_chapter_index;
      final int next_index = _loaded_chapter_index + 1;
      final NovelChapterInfo next_chapter = _store.chapter_list[next_index];

      final String content = await _fetch_chapter_content(next_index);
      if (content.isEmpty) return;

      await _wait_until_chapter_mutation_allowed();

      if (window_generation != _chapter_window_generation ||
          expected_loaded_index != _loaded_chapter_index ||
          is_jumping_chapter.value) {
        return;
      }

      int words_before = 0;
      for (int i = 0; i < next_index; i++) {
        words_before += _store.chapter_list[i].word_count;
      }

      _store.append_chapter_content(
        next_chapter.title,
        next_chapter.chapter_no,
        next_index,
        words_before,
        next_chapter.word_count,
        content,
      );
      on_chapter_loaded?.call(next_index);

      _loaded_chapter_index = next_index;
      _preload_adjacent_chapters(next_index);
    } catch (e) {
      debugPrint('加载下一章失败: $e');
    } finally {
      is_loading_next = false;
      if (!load_completer.isCompleted) {
        load_completer.complete();
      }
      if (identical(_load_next_completer, load_completer)) {
        _load_next_completer = null;
      }
    }
  }

  /// 确保当前阅读章节的下一章已经拼接到正文末尾。
  Future<void> ensure_next_chapter_appended_after(int chapter_index) async {
    if (_store.chapter_list.isEmpty ||
        chapter_index < _min_loaded_chapter_index ||
        chapter_index > _loaded_chapter_index ||
        chapter_index >= _store.chapter_list.length - 1 ||
        _loaded_chapter_index > chapter_index ||
        is_loading_next) {
      return;
    }

    await load_next_chapter();
  }

  /// 加载并插入上一章内容。
  Future<void> load_prev_chapter() async {
    if (is_loading_prev || _store.chapter_list.isEmpty || _min_loaded_chapter_index <= 0) {
      return;
    }

    is_loading_prev = true;

    try {
      final int window_generation = _chapter_window_generation;
      final int expected_min_loaded_index = _min_loaded_chapter_index;
      final int prev_index = _min_loaded_chapter_index - 1;
      final NovelChapterInfo prev_chapter = _store.chapter_list[prev_index];

      final String content = await _fetch_chapter_content(prev_index);
      if (content.isEmpty) return;

      int words_before = 0;
      for (int i = 0; i < prev_index; i++) {
        words_before += _store.chapter_list[i].word_count;
      }

      await _wait_until_chapter_mutation_allowed();

      if (window_generation != _chapter_window_generation ||
          expected_min_loaded_index != _min_loaded_chapter_index ||
          is_jumping_chapter.value) {
        return;
      }

      void apply_prepend() {
        _store.prepend_chapter_content(
          prev_chapter.title,
          prev_chapter.chapter_no,
          prev_index,
          words_before,
          prev_chapter.word_count,
          content,
        );
        _min_loaded_chapter_index = prev_index;
        on_chapter_loaded?.call(prev_index);
      }

      final preserve_anchor = preserve_chapter_anchor;
      if (preserve_anchor == null) {
        apply_prepend();
      } else {
        await preserve_anchor(apply_prepend, expected_min_loaded_index);
      }

      _preload_adjacent_chapters(prev_index);
    } catch (e) {
      debugPrint('加载上一章失败: $e');
    } finally {
      is_loading_prev = false;
    }
  }

  /// 跳转到指定章节。
  Future<int?> jump_to_chapter(int index) async {
    if (index < 0 || index >= _store.chapter_list.length) return null;

    final int generation = ++_chapter_window_generation;
    is_jumping_chapter.value = true;

    try {
      final NovelChapterInfo chapter = _store.chapter_list[index];

      final bool rebuilt = await _rebuild_reading_window_around_chapter(index, generation: generation);
      if (generation != _chapter_window_generation) {
        return null;
      }
      if (!rebuilt) {
        complete_chapter_jump(generation);
        return null;
      }

      current_chapter_index.value = index;
      current_chapter_db_id = int.tryParse(chapter.id) ?? 0;
      show_navigation.value = false;

      _preload_chain_after_jump(index);
      return generation;
    } catch (error) {
      debugPrint('跳转章节失败: $error');
      complete_chapter_jump(generation);
      return null;
    }
  }

  /// 完成主动跳章。
  void complete_chapter_jump(int generation) {
    if (generation != _chapter_window_generation) return;
    is_jumping_chapter.value = false;
  }

  /// 重建以目标章节为中心的阅读窗口。
  Future<bool> _rebuild_reading_window_around_chapter(int index, {required int generation}) async {
    final int total_count = _store.chapter_list.length;
    if (total_count <= 0) return false;

    final int start_index = (index - _jump_window_before_count).clamp(0, total_count - 1);
    final int end_index = (index + _jump_window_after_count).clamp(0, total_count - 1);

    final List<int> chapter_indexes = <int>[
      for (int chapter_index = start_index; chapter_index <= end_index; chapter_index++)
        chapter_index,
    ];
    final List<String> contents = <String>[];
    for (final int chapter_index in chapter_indexes) {
      try {
        contents.add(await _fetch_chapter_content(chapter_index));
      } catch (error) {
        debugPrint('加载跳转窗口章节 $chapter_index 失败: $error');
        contents.add('');
      }
      if (generation != _chapter_window_generation) return false;
    }

    if (index > 0) {
      final int previous_content_index = index - 1 - start_index;
      if (previous_content_index >= 0 &&
          previous_content_index < contents.length &&
          contents[previous_content_index].isEmpty) {
        try {
          contents[previous_content_index] = await _fetch_chapter_content(index - 1, force: true);
        } catch (error) {
          debugPrint('重试加载上一章 ${index - 1} 失败: $error');
        }
      }
    }
    if (generation != _chapter_window_generation) return false;

    final int target_content_index = index - start_index;
    if (target_content_index < 0 ||
        target_content_index >= contents.length ||
        contents[target_content_index].isEmpty) {
      return false;
    }

    for (int index = 0; index < chapter_indexes.length; index++) {
      if (contents[index].isNotEmpty) {
        _store.cache_chapter_content(chapter_indexes[index], contents[index]);
      }
    }

    int actual_start_index = index;
    while (actual_start_index > start_index && contents[actual_start_index - start_index - 1].isNotEmpty) {
      actual_start_index--;
    }
    int actual_end_index = index;
    while (actual_end_index < end_index && contents[actual_end_index - start_index + 1].isNotEmpty) {
      actual_end_index++;
    }

    _store.rebuild_reading_items_from_cache(actual_start_index, actual_end_index, _store.chapter_list);
    for (int chapter_index = actual_start_index; chapter_index <= actual_end_index; chapter_index++) {
      on_chapter_loaded?.call(chapter_index);
    }

    _min_loaded_chapter_index = actual_start_index;
    _loaded_chapter_index = actual_end_index;
    return true;
  }

  /// 跳转后的预加载链。
  void _preload_chain_after_jump(int index) {
    _preload_chapter_window(index, radius: 2);
  }

  // ==================== 缓存管理 ====================

  /// 获取章节内容，优先从缓存读取。
  Future<String> _fetch_chapter_content(int index, {bool force = false}) async {
    if (index < 0 || index >= _store.chapter_list.length) return '';

    if (!force) {
      final Future<String>? in_flight = _chapter_fetch_in_flight[index];
      if (in_flight != null) return in_flight;
    }

    final Future<String> request = _load_chapter_content(index, force: force);
    if (!force) {
      _chapter_fetch_in_flight[index] = request;
    }

    try {
      return await request;
    } finally {
      if (!force && identical(_chapter_fetch_in_flight[index], request)) {
        _chapter_fetch_in_flight.remove(index);
      }
    }
  }

  /// 执行单个章节的真实缓存读取与网络请求。
  Future<String> _load_chapter_content(int index, {required bool force}) async {
    final NovelChapterInfo chapter = _store.chapter_list[index];
    final String chapter_id = chapter.id;

    if (!force) {
      final String? cached = _store.get_cached_chapter_content(index);
      if (cached != null && cached.isNotEmpty) return cached;
    }

    if (!force) {
      final String? disk_cached = await ChapterCache.read(chapter_id);
      if (disk_cached != null && disk_cached.isNotEmpty) {
        _store.cache_chapter_content(index, disk_cached);
        return disk_cached;
      }
    }

    final String content = await _chapter_content_loader(chapter_id);
    if (content.isNotEmpty) {
      _store.cache_chapter_content(index, content);
      await ChapterCache.write(chapter_id, content);
    }
    return content;
  }

  /// 异步预加载指定章节附近的章节到缓存。
  void _preload_adjacent_chapters(int current_index) {
    _preload_chapter_window(current_index, radius: 2);
  }

  /// 预加载指定章节前后窗口内的正文到缓存。
  void _preload_chapter_window(int center_index, {int radius = 2}) {
    final int total = _store.chapter_list.length;
    if (total <= 0) return;

    final int start = (center_index - radius).clamp(0, total - 1);
    final int end = (center_index + radius).clamp(0, total - 1);

    for (int i = start; i <= end; i++) {
      if (i == center_index) continue;
      _fetch_chapter_content(i).catchError((e) {
        debugPrint('预加载章节 $i 失败: $e');
        return '';
      });
    }
  }

  // ==================== 滚动/导航 ====================

  /// 判断当前路由参数是否合法。
  bool get has_valid_story_id => story_id > _min_valid_story_id;

  /// 切换导航栏显示状态。
  void toggle_navigation() {
    show_navigation.value = !show_navigation.value;
    _scroll_direction_anchor_offset = _last_scroll_offset;
    _last_scroll_direction_down = null;
  }

  /// 同步程序化定位后的滚动基准。
  void sync_scroll_offset(double offset) {
    _last_scroll_offset = offset;
    _scroll_direction_anchor_offset = offset;
    _last_scroll_direction_down = null;
  }

  /// 根据滚动方向自动显示/隐藏导航栏。
  void on_scroll(double offset) {
    if (offset == _last_scroll_offset) return;

    _is_scrolling_down = offset > _last_scroll_offset;
    if (_last_scroll_direction_down == null || _last_scroll_direction_down != _is_scrolling_down) {
      _scroll_direction_anchor_offset = _last_scroll_offset;
      _last_scroll_direction_down = _is_scrolling_down;
    }
    _last_scroll_offset = offset;
    final double scroll_distance = (offset - _scroll_direction_anchor_offset).abs();

    if (offset < Style.navigation_force_hidden_top_threshold) {
      if (show_navigation.value) {
        show_navigation.value = false;
      }
      _scroll_direction_anchor_offset = offset;
      _last_scroll_direction_down = null;
      return;
    }

    if (_is_scrolling_down && show_navigation.value && scroll_distance > Style.navigation_visibility_scroll_threshold) {
      show_navigation.value = false;
      _scroll_direction_anchor_offset = offset;
    }

    if (!_is_scrolling_down && !show_navigation.value && scroll_distance > Style.navigation_visibility_scroll_threshold) {
      show_navigation.value = true;
      _scroll_direction_anchor_offset = offset;
    }
  }

  // ==================== 状态查询 ====================

  /// 是否为第一章。
  bool get is_first_chapter => current_chapter_index.value == 0;

  /// 当前阅读列表是否包含并展示小说简介。
  bool get should_show_introduction => _min_loaded_chapter_index == 0;

  /// 是否为最后一章。
  bool get is_last_chapter =>
      _store.chapter_list.isEmpty || current_chapter_index.value >= _store.chapter_list.length - 1;

  // ==================== 构建方法 ====================

  /// 构建占位详情数据。
  ReadDetail build_detail() {
    return DetailBuilder.build(store: _store, story_id: story_id, story_title: story_title);
  }

  /// 构建正文内容项列表。
  List<ReadingContentItem> build_reading_items() {
    final List<ReadingContentItem> items = _store.reading_items;

    if (items.isEmpty) {
      return <ReadingContentItem>[
        ReadingContentItem(
          text: easy.tr('image_text.loading'),
          is_title: false,
          chapter_no: 0,
          chapter_index: 0,
          words_before_this_chapter: 0,
          chapter_total_words: 0,
        ),
      ];
    }

    return items;
  }

  /// 获取指定章节的 GlobalKey。
  GlobalKey get_chapter_key(int index) {
    return _chapter_keys.putIfAbsent(index, () => GlobalKey());
  }
}
