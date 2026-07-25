import 'dart:io';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/get_chapter_content.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/device/save_body_font_size.dart';

/// 阅读页详情数据模型。
class ReadDetail {
  /// 书籍 id。
  final int story_id;

  /// 书籍标题。
  final String title;

  /// 封面地址。
  final String cover_url;

  /// 作者ID（数据库中的真实作者ID，用于关注接口）。
  final int author_id;

  /// 作者头像地址。
  final String author_avatar_url;

  /// 作者名称。
  final String author_name;

  /// 是否关注作者。
  final bool focus_on;

  /// 评分整数部分。
  final String score_major_text;

  /// 评分单位文案。
  final String score_minor_text;

  /// 点评人数文案。
  final String review_count_text;

  /// 在读人数整数部分。
  final String reading_major_text;

  /// 在读人数单位文案。
  final String reading_minor_text;

  /// 在读副标题文案。
  final String reading_subtitle_text;

  /// 字数整数部分。
  final String word_count_major_text;

  /// 字数单位文案。
  final String word_count_minor_text;

  /// 字数副标题文案。
  final String word_count_subtitle_text;

  /// 标签列表。
  final List<String> tag_list;

  /// 简介内容。
  final String intro_text;

  /// 第一章标题。
  final String chapter_title;

  /// 热门评论列表。
  final List<ReadComment> comment_list;

  const ReadDetail({
    required this.story_id,
    required this.title,
    required this.cover_url,
    required this.author_id,
    required this.author_avatar_url,
    required this.author_name,
    required this.focus_on,
    required this.score_major_text,
    required this.score_minor_text,
    required this.review_count_text,
    required this.reading_major_text,
    required this.reading_minor_text,
    required this.reading_subtitle_text,
    required this.word_count_major_text,
    required this.word_count_minor_text,
    required this.word_count_subtitle_text,
    required this.tag_list,
    required this.intro_text,
    required this.chapter_title,
    required this.comment_list,
  });
}

/// 阅读页评论数据模型。
class ReadComment {
  /// 评论人头像地址。
  final String avatar_url;

  /// 评论人名称。
  final String user_name;

  /// 评论内容。
  final String content;

  /// 评论星级。
  final int star_count;

  /// 评论人用户ID，用于 CommentAvatar 生成 SVG 兜底头像。
  final int user_id;

  const ReadComment({
    required this.avatar_url,
    required this.user_name,
    required this.content,
    required this.star_count,
    required this.user_id,
  });
}

/// 阅读页占位逻辑层。
class Logic extends GetxController {
  /// 路由传入的书籍 id。
  final int story_id;

  /// 路由传入的标题。
  final String story_title;

  /// 加载状态。
  var is_loading = true.obs;

  /// 是否正在加载下一章中（纯状态标记，不触发 UI 重建）。
  bool is_loading_next = false;

  /// 是否正在切换章节（上一章/下一章/进度跳转）。
  var is_switching_chapter = false.obs;

  /// 是否正在跳转章节（目录点击，显示骨架屏）。
  var is_jumping_chapter = false.obs;

  /// 跳转章节完成时间戳，用于冷却期间跳过滚动处理。
  DateTime jump_finished_time = DateTime.fromMillisecondsSinceEpoch(0);

  /// 错误状态。
  var is_error = false.obs;

  /// 当前阅读到的章节索引。
  var current_chapter_index = 0.obs;

  /// 当前阅读到的章节ID（可靠值，由 jump_to_chapter / load_next / load_prev 设置）。
  int current_chapter_db_id = 0;

  /// 当前已加载到的章节索引。
  int get loaded_chapter_index => _loaded_chapter_index;
  int _loaded_chapter_index = 0;

  /// 当前已加载的最小章节索引。
  int get min_loaded_chapter_index => _min_loaded_chapter_index;
  int _min_loaded_chapter_index = 0;

  /// 是否正在加载上一章中（纯状态标记，不触发 UI 重建）。
  bool is_loading_prev = false;

  /// 上一次加载上一章完成的时间戳，用于防抖机制。
  /// 防止加载完成后立即触发下一次加载。
  DateTime _last_load_prev_time = DateTime.fromMillisecondsSinceEpoch(0);

  /// 获取上次加载上一章的时间，用于外部防抖检查。
  DateTime get last_load_prev_time => _last_load_prev_time;

  /// 上一次加载下一章完成的时间戳，用于防抖机制。
  /// 防止加载完成后立即触发下一次加载。
  DateTime _last_load_next_time = DateTime.fromMillisecondsSinceEpoch(0);

  /// 获取上次加载下一章的时间，用于外部防抖检查。
  DateTime get last_load_next_time => _last_load_next_time;

  /// 加载上一章的冷却时间（毫秒）。
  /// 加载完成后等待此时间才能再次触发加载。
  static const int _load_prev_cooldown_ms = 500;

  /// 主动跳章时预先拼接到目标章前面的章节数。
  static const int _jump_window_before_count = 1;

  /// 主动跳章时预先拼接到目标章后面的章节数。
  static const int _jump_window_after_count = 1;

  /// 外部页面提供的“是否允许修改正文列表”的判断。
  ///
  /// 阅读页在用户拖动或惯性滚动期间会返回 false，避免 prepend/append 正文时改变
  /// ListView 高度并打断当前滚动。为空时默认允许，保证逻辑层在非页面场景也能工作。
  bool Function()? can_apply_chapter_mutation;

  /// 等待到滚动空闲后再修改正文列表。
  ///
  /// 章节内容可以提前请求和缓存，但真正 append/prepend 到 reading_items 必须避开
  /// ScrollActivity 活跃期，否则会出现第一次滑动卡住、边界拼接卡顿的问题。
  Future<void> _wait_until_chapter_mutation_allowed() async {
    int retry_count = 0;
    while (can_apply_chapter_mutation != null &&
        !can_apply_chapter_mutation!() &&
        retry_count < 120) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      retry_count++;
    }
  }

  /// 章节正文磁盘缓存有效期。
  ///
  /// 缓存过期后会自动删除并重新请求远程正文，避免长期命中过旧内容。
  static const Duration _chapter_disk_cache_ttl = Duration(days: 7);

  /// 章节锚点 key 映射，用于精确滚动到指定章节。
  final Map<int, GlobalKey> _chapter_keys = {};

  /// 是否显示导航栏（顶部和底部）。
  var show_navigation = false.obs;

  /// 评论数（从 novel_info 读取）。
  int get comment_count {
    final info = _store.novel_info.value;
    if (info == null) return 0;
    return int.tryParse(info.comment_count) ?? 0;
  }

  /// 更新评论数（评论弹窗关闭后同步最新数量）。
  void update_comment_count(int new_count) {
    final info = _store.novel_info.value;
    if (info == null) return;
    final updated = NovelInfo(
      id: info.id,
      title: info.title,
      subtitle: info.subtitle,
      score: info.score,
      focus_on: info.focus_on,
      is_liked: info.is_liked,
      is_favorited: info.is_favorited,
      author_id: info.author_id,
      source_type: info.source_type,
      publish_status: info.publish_status,
      recommend_status: info.recommend_status,
      sorting: info.sorting,
      read_count: info.read_count,
      comment_count: new_count.toString(),
      like_count: info.like_count,
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

  /// 同步点赞状态到底层数据（点赞/取消点赞后调用）。
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

  /// 同步关注状态到底层数据（关注/取消关注后调用）。
  void update_focus_on(bool new_status) {
    final info = _store.novel_info.value;
    if (info == null) return;

    final updated = NovelInfo(
      id: info.id,
      title: info.title,
      subtitle: info.subtitle,
      score: info.score,
      focus_on: new_status,
      is_liked: info.is_liked,
      is_favorited: info.is_favorited,
      author_id: info.author_id,
      source_type: info.source_type,
      publish_status: info.publish_status,
      recommend_status: info.recommend_status,
      sorting: info.sorting,
      read_count: info.read_count,
      comment_count: info.comment_count,
      like_count: info.like_count,
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

  /// 自动阅读速度（0.0 最慢，1.0 最快）。
  late final RxDouble auto_read_speed;

  /// 滚动方向检测：上一帧滚动偏移量。
  double _last_scroll_offset = 0;

  /// 滚动方向检测：当前是否在向下滑动（内容向上移动）。
  bool _is_scrolling_down = false;

  /// 滚动方向检测：导航栏可见时的滚动偏移量。
  double _scroll_offset_when_visible = 0;

  /// 小说阅读仓库。
  final NovelReadingStore _store = Get.put(NovelReadingStore());

  /// 书籍总字数。
  int _total_word_count = 0;

  /// 标签颜色值列表。
  static final List<int> tag_color_value_list = ColorConstants.tagColorList
      .map((Color color) => color.value)
      .toList();

  /// 目录列表。
  List<NovelChapterInfo> get chapter_list => _store.chapter_list;

  /// 更新总字数，基于目录列表。
  void _update_total_word_count() {
    int total = 0;
    for (var chapter in _store.chapter_list) {
      total += chapter.word_count;
    }
    if (total > 0) {
      _total_word_count = total;
    }
  }

  /// 最小合法书籍 id 阈值。
  static const int _min_valid_story_id = 0;

  /// 页面滚动控制器，由于 Logic 被持久化，此控制器也能跨主题切换重建而保持。
  late final ScrollController scroll_controller;

  Logic({required this.story_id, required this.story_title}) {
    scroll_controller = ScrollController();
    // 初始化字号。
    body_font_size = (load_body_font_size() ?? 18.0).obs;
    // 初始化自动阅读速度。
    auto_read_speed = (load_auto_read_speed() ?? 0.2).obs;
    // 刚进入 read 页面时，清空之前拿到的全局数据，确保展示的是当前书籍的内容。
    _store.clear_novel_info();
  }

  @override
  void onClose() {
    scroll_controller.dispose();
    super.onClose();
  }

  /// 增加正文字号。
  void increase_font_size() {
    final double next = body_font_size.value + font_size_step;
    if (next <= font_size_max) {
      body_font_size.value = next;
      save_body_font_size(next);
    }
  }

  /// 减少正文字号。
  void decrease_font_size() {
    final double next = body_font_size.value - font_size_step;
    if (next >= font_size_min) {
      body_font_size.value = next;
      save_body_font_size(next);
    }
  }

  /// 切换点赞状态（乐观更新）。
  ///
  /// 立即切换本地状态，然后发起请求。
  /// 请求失败时回退状态，请求成功时保持不变。
  /// 请求期间通过 is_like_loading 防止重复点击。
  Future<void> toggle_like() async {
    if (is_like_loading.value) return;

    is_like_loading.value = true;

    // 乐观更新：立即切换状态。
    final bool previous_status = is_liked.value;
    final int previous_count = like_count.value;
    final bool optimistic_status = !previous_status;
    final int optimistic_count = (previous_count + (optimistic_status ? 1 : -1)).clamp(0, 999999);
    sync_like_state(optimistic_status, optimistic_count);

    try {
      final ResultsType<Map<String, dynamic>> results =
          await postRequest<Map<String, dynamic>>(
            path: 'novel_like/click',
            parameter: <String, dynamic>{'novel_id': story_id},
            fromJson: (Map<String, dynamic> json) => json,
          );

      if (!results.status || results.content == null) {
        // 请求失败，回退状态。
        sync_like_state(previous_status, previous_count);
        return;
      }

      final bool server_status = results.content!['like'] == true;
      // 服务端状态与乐观更新不一致时，以服务端为准。
      if (server_status != optimistic_status) {
        final int server_count = (previous_count + (server_status ? 1 : -1)).clamp(0, 999999);
        sync_like_state(server_status, server_count);
      }
    } catch (_) {
      // 异常时回退状态。
      sync_like_state(previous_status, previous_count);
    } finally {
      is_like_loading.value = false;
    }
  }

  /// 切换收藏状态（乐观更新）。
  ///
  /// 立即切换本地状态，然后发起请求。
  /// 请求失败时回退状态，请求成功时保持不变。
  /// 请求期间通过 is_favorite_loading 防止重复点击。
  Future<void> toggle_favorite() async {
    if (is_favorite_loading.value) return;

    is_favorite_loading.value = true;

    // 乐观更新：立即切换状态。
    final bool previous_status = is_favorited.value;
    final bool optimistic_status = !previous_status;
    is_favorited.value = optimistic_status;

    // 同步到 store 中的 novel_info。
    final info = _store.novel_info.value;
    NovelInfo? previous_info;
    if (info != null) {
      previous_info = info;
      final int delta = optimistic_status ? 1 : -1;
      final int new_count = (int.tryParse(info.favorite_count) ?? 0) + delta;
      final updated = NovelInfo(
        id: info.id,
        title: info.title,
        subtitle: info.subtitle,
        score: info.score,
        focus_on: info.focus_on,
        is_liked: info.is_liked,
        is_favorited: optimistic_status,
        author_id: info.author_id,
        source_type: info.source_type,
        publish_status: info.publish_status,
        recommend_status: info.recommend_status,
        sorting: info.sorting,
        read_count: info.read_count,
        comment_count: info.comment_count,
        like_count: info.like_count,
        favorite_count: new_count.toString(),
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

    try {
      final ResultsType<Map<String, dynamic>> results =
          await postRequest<Map<String, dynamic>>(
            path: 'novel_favorite/click',
            parameter: <String, dynamic>{'novel_id': story_id},
            fromJson: (Map<String, dynamic> json) => json,
          );

      if (!results.status || results.content == null) {
        // 请求失败，回退状态。
        _revert_favorite(previous_status, previous_info);
        return;
      }

      final bool server_status = results.content!['favorite'] == true;
      // 服务端状态与乐观更新不一致时，以服务端为准。
      if (server_status != optimistic_status) {
        is_favorited.value = server_status;
        if (previous_info != null) {
          final int server_delta = server_status ? 1 : -1;
          final int server_count = (int.tryParse(previous_info.favorite_count) ?? 0) + server_delta;
          _store.set_novel_info(NovelInfo(
            id: previous_info.id,
            title: previous_info.title,
            subtitle: previous_info.subtitle,
            score: previous_info.score,
            focus_on: previous_info.focus_on,
            is_liked: previous_info.is_liked,
            is_favorited: server_status,
            author_id: previous_info.author_id,
            source_type: previous_info.source_type,
            publish_status: previous_info.publish_status,
            recommend_status: previous_info.recommend_status,
            sorting: previous_info.sorting,
            read_count: previous_info.read_count,
            comment_count: previous_info.comment_count,
            like_count: previous_info.like_count,
            favorite_count: server_count.toString(),
            latest_chapter_no: previous_info.latest_chapter_no,
            latest_update_time: previous_info.latest_update_time,
            remark: previous_info.remark,
            create_time: previous_info.create_time,
            update_time: previous_info.update_time,
            remove_status: previous_info.remove_status,
            remove_time: previous_info.remove_time,
            author_name: previous_info.author_name,
            author_avatar: previous_info.author_avatar,
            language_info: previous_info.language_info,
            category_list: previous_info.category_list,
            comment_list: previous_info.comment_list,
            chapter_info: previous_info.chapter_info,
          ));
        }
      }
    } catch (_) {
      // 异常时回退状态。
      _revert_favorite(previous_status, previous_info);
    } finally {
      is_favorite_loading.value = false;
    }
  }

  /// 回退收藏状态。
  void _revert_favorite(bool previous_status, NovelInfo? previous_info) {
    is_favorited.value = previous_status;
    if (previous_info != null) {
      _store.set_novel_info(previous_info);
    }
  }

  /// 长篇小说章节正文磁盘缓存目录。
  Directory get _chapter_cache_directory {
    return Directory('${Directory.systemTemp.path}/read_chapter_content_cache');
  }

  /// 将章节正文 url 转换成可安全落盘的文件名。
  ///
  /// [content_url] 章节正文远程地址。
  /// 返回经过编码并裁剪长度后的 txt 文件名。
  String _chapter_cache_file_name(String content_url) {
    final String encoded = Uri.encodeComponent(
      content_url,
    ).replaceAll('%', '_').replaceAll('.', '_').replaceAll('-', '_');
    if (encoded.length <= 180) {
      return '$encoded.txt';
    }
    return '${encoded.substring(0, 180)}_${content_url.hashCode.abs()}.txt';
  }

  /// 获取指定章节正文 url 对应的磁盘缓存文件。
  ///
  /// [content_url] 章节正文远程地址。
  File _chapter_cache_file(String content_url) {
    return File(
      '${_chapter_cache_directory.path}/${_chapter_cache_file_name(content_url)}',
    );
  }

  /// 从磁盘缓存读取章节正文。
  ///
  /// [content_url] 章节正文远程地址。
  /// 返回缓存文本；缓存不存在、过期或读取失败时返回 null。
  Future<String?> _read_chapter_content_from_disk_cache(
    String content_url,
  ) async {
    try {
      final File file = _chapter_cache_file(content_url);
      if (!await file.exists()) {
        return null;
      }

      final DateTime modified = await file.lastModified();
      final bool expired =
          DateTime.now().difference(modified) > _chapter_disk_cache_ttl;
      if (expired) {
        await file.delete();
        return null;
      }

      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// 将章节正文写入磁盘缓存。
  ///
  /// [content_url] 章节正文远程地址。
  /// [content] 章节正文文本。
  Future<void> _write_chapter_content_to_disk_cache(
    String content_url,
    String content,
  ) async {
    if (content_url.isEmpty || content.isEmpty) {
      return;
    }

    try {
      final Directory directory = _chapter_cache_directory;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final File file = _chapter_cache_file(content_url);
      await file.writeAsString(content, flush: false);
    } catch (_) {
      // 缓存失败不影响阅读。
    }
  }

  /// 请求书籍详情接口，用于页面进入时拉取最新小说数据。
  ///
  /// [force] 是否强制刷新，默认为 false。
  Future<void> fetch_info({
    bool force = false,
    bool show_loading = true,
    bool bypass_chapter_cache = false,
  }) async {
    // 如果不是强制刷新，且 Store 中已经有数据，则跳过请求，避免重复加载。
    if (!force &&
        _store.novel_info.value != null &&
        _store.reading_items.isNotEmpty) {
      is_loading.value = false;
      return;
    }

    final bool has_existing_content = _store.reading_items.isNotEmpty;
    is_loading.value = show_loading || !has_existing_content;
    is_error.value = false;
    _loaded_chapter_index = 0;
    _min_loaded_chapter_index = 0;
    current_chapter_index.value = 0;
    current_chapter_db_id = 0;
    _chapter_keys.clear();
    if (bypass_chapter_cache) {
      _store.clear_chapter_content_cache();
    }

    // 调用全局封装的 POST 请求，请求小说详情。
    final ResultsType<NovelInfo> results = await postRequest<NovelInfo>(
      path: 'novel/get_info',
      parameter: <String, dynamic>{'id': story_id},
      fromJson: (Map<String, dynamic> json) => NovelInfo.from_json(json),
    );

    if (results.status && results.content != null) {
      // 请求成功，保存到 Store。
      _store.set_novel_info(results.content!);
      _total_word_count = results.content!.language_info.word_count;

      // TODO 初始化点赞状态、点赞数、收藏状态。
      is_liked.value = results.content!.is_liked;
      like_count.value = int.tryParse(results.content!.like_count) ?? 0;
      is_favorited.value = results.content!.is_favorited;

      // 获取章节目录。
      await fetch_directory(results.content!.language_info.id);

      // 继续拉取第一章的正文内容。
      if (_store.chapter_list.isNotEmpty) {
        final NovelChapterInfo first_chapter = _store.chapter_list.first;
        // 获取第一章内容并写入缓存。
        final String content = await _fetch_chapter_content(
          0,
          force: bypass_chapter_cache,
        );
        _store.set_initial_content(
          first_chapter.title,
          first_chapter.chapter_no,
          0,
          0,
          first_chapter.word_count,
          content,
        );
        _loaded_chapter_index = 0;
        _min_loaded_chapter_index = 0;
        current_chapter_index.value = 0;
        current_chapter_db_id = int.tryParse(first_chapter.id) ?? 0;

        // 异步预加载第二章到缓存，不阻塞页面渲染。
        _preload_adjacent_chapters(0);
      }

      is_loading.value = false;
    } else {
      // 请求失败。
      is_error.value = !(force && has_existing_content && !show_loading);
      is_loading.value = false;
    }
  }

  /// 请求章节目录接口。
  ///
  /// [novel_language_id] 小说语种 id。
  Future<void> fetch_directory(String novel_language_id) async {
    final ResultsType<List<NovelChapterInfo>> results =
        await postRequest<List<NovelChapterInfo>>(
          path: 'novel_chapter/inquire',
          parameter: <String, dynamic>{'novel_language_id': novel_language_id},
          fromJsonList: (List<dynamic> json) {
            return json
                .map(
                  (e) =>
                      NovelChapterInfo.from_json(Map<String, dynamic>.from(e)),
                )
                .toList();
          },
        );

    if (results.status && results.content != null) {
      _store.set_chapter_list(results.content!);
      _update_total_word_count();
    }
  }

  /// 加载并追加下一章内容。
  ///
  /// 自然阅读场景：用户滚动到接近底部时自动触发。
  /// 优先从缓存读取，缓存未命中则发起网络请求。
  /// 加载完成后自动预加载更后面的章节到缓存。
  Future<void> load_next_chapter() async {
    // 已经在加载中，或者没有目录，或者已经加载完所有章节，则不继续。
    if (is_loading_next ||
        _store.chapter_list.isEmpty ||
        _loaded_chapter_index >= _store.chapter_list.length - 1) {
      return;
    }

    is_loading_next = true;

    try {
      final int next_index = _loaded_chapter_index + 1;
      final NovelChapterInfo next_chapter = _store.chapter_list[next_index];

      // 获取内容（优先缓存，否则网络请求）。
      final String content = await _fetch_chapter_content(next_index);

      // 等待滚动空闲后再追加到 Store，避免滚动过程中改变内容高度。
      await _wait_until_chapter_mutation_allowed();

      // 追加到 Store。
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

      // 更新已加载索引。
      _loaded_chapter_index = next_index;

      // 异步预加载更后面的章节到缓存。
      _preload_adjacent_chapters(next_index);

      // 记录加载完成时间，用于防抖。
      _last_load_next_time = DateTime.now();
    } catch (e) {
      debugPrint('加载下一章失败: $e');
    } finally {
      is_loading_next = false;
    }
  }

  /// 确保当前阅读章节的下一章已经拼接到正文末尾。
  ///
  /// [chapter_index] 当前正在阅读的章节索引。
  /// 当用户进入第 N 章时，如果第 N+1 章还没有追加到正文列表，就立即加载并追加；
  /// 章节正文获取仍然走“内存 -> 磁盘 -> 网络”的缓存链路。
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
  ///
  /// 自然阅读场景：用户向上滚动到正文顶部附近时自动触发。
  /// 优先从缓存读取，缓存未命中则发起网络请求。
  /// 加载完成后自动预加载更前面的章节到缓存。
  Future<void> load_prev_chapter() async {
    // 已经在加载中，或者没有目录，或者已经加载到第一章，则不继续。
    if (is_loading_prev ||
        _store.chapter_list.isEmpty ||
        _min_loaded_chapter_index <= 0) {
      return;
    }

    // 防抖检查：上次加载完成后冷却时间内不允许再次加载。
    final int time_since_last_load = DateTime.now()
        .difference(_last_load_prev_time)
        .inMilliseconds;
    if (time_since_last_load < _load_prev_cooldown_ms) {
      return;
    }

    is_loading_prev = true;

    try {
      final int prev_index = _min_loaded_chapter_index - 1;
      final NovelChapterInfo prev_chapter = _store.chapter_list[prev_index];

      // 获取内容（优先缓存，否则网络请求）。
      final String content = await _fetch_chapter_content(prev_index);

      // 计算该章节之前的字数。
      int words_before = 0;
      for (int i = 0; i < prev_index; i++) {
        words_before += _store.chapter_list[i].word_count;
      }

      // 等待滚动空闲后再插入到 Store，避免滚动过程中改变内容高度并打断手势。
      await _wait_until_chapter_mutation_allowed();

      // 记录加载前的滚动状态，用于加载后恢复相对位置。
      double old_max_scroll_extent = 0;
      double old_offset = 0;
      if (scroll_controller.hasClients) {
        old_max_scroll_extent = scroll_controller.position.maxScrollExtent;
        old_offset = scroll_controller.offset;
      }

      // 插入到 Store 头部。
      _store.prepend_chapter_content(
        prev_chapter.title,
        prev_chapter.chapter_no,
        prev_index,
        words_before,
        prev_chapter.word_count,
        content,
      );

      // 更新最小已加载索引。
      _min_loaded_chapter_index = prev_index;

      // 核心：在下一帧恢复滚动位置，实现无缝向上加载。
      // 使用 addPostFrameCallback 确保在布局完成后执行。
      if (scroll_controller.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll_controller.hasClients) {
            double new_max_scroll_extent =
                scroll_controller.position.maxScrollExtent;
            double delta = new_max_scroll_extent - old_max_scroll_extent;
            if (delta > 0) {
              // 保持原来的滚动位置，让用户感觉内容是在上方插入的。
              scroll_controller.jumpTo(old_offset + delta);
            }
          }
        });
      }

      // 异步预加载更前面的章节到缓存。
      _preload_adjacent_chapters(prev_index);

      // 记录加载完成时间，用于防抖。
      _last_load_prev_time = DateTime.now();
    } catch (e) {
      debugPrint('加载上一章失败: $e');
    } finally {
      is_loading_prev = false;
    }
  }

  /// 跳转到指定章节。
  ///
  /// 主动跳转不是只渲染目标单章，而是把目标章前后各一章一起拼接进
  /// reading_items。这样从第 15 章 10% 恢复时，第 14 章已经真实存在于
  /// 列表上方，用户向上滑动不会遇到上一章迟迟不加载的问题。
  Future<void> jump_to_chapter(int index) async {
    if (index < 0 || index >= _store.chapter_list.length) return;

    is_jumping_chapter.value = true;

    try {
      current_chapter_index.value = index;
      current_chapter_db_id = int.tryParse(_store.chapter_list[index].id) ?? 0;

      final NovelChapterInfo chapter = _store.chapter_list[index];
      debugPrint(
        '📖 [jump_to_chapter] index=$index, chapter_id=${chapter.id}, '
        'chapter_no=${chapter.chapter_no}, title=${chapter.title}',
      );

      await _rebuild_reading_window_around_chapter(index);

      show_navigation.value = false;
      is_loading_prev = false;
      is_loading_next = false;
      _last_load_prev_time = DateTime.now();
    } finally {
      // 先重置滚动位置，再隐藏骨架屏，避免 ListView 显示时位置不对导致抖动。
      if (scroll_controller.hasClients) {
        scroll_controller.jumpTo(0);
      }
      is_jumping_chapter.value = false;
      jump_finished_time = DateTime.now();

      // 预加载链在后台执行，不阻塞 UI。
      _preload_chain_after_jump(index);
    }
  }

  /// 重建以目标章节为中心的阅读窗口。
  ///
  /// [index] 目标章节索引。
  /// 会同步拉取目标章前后一章的正文并从缓存重建 reading_items。
  Future<void> _rebuild_reading_window_around_chapter(int index) async {
    final int total_count = _store.chapter_list.length;
    if (total_count <= 0) {
      return;
    }

    final int start_index = (index - _jump_window_before_count).clamp(
      0,
      total_count - 1,
    );
    final int end_index = (index + _jump_window_after_count).clamp(
      0,
      total_count - 1,
    );

    for (
      int chapter_index = start_index;
      chapter_index <= end_index;
      chapter_index++
    ) {
      final String content = await _fetch_chapter_content(chapter_index);
      _store.cache_chapter_content(chapter_index, content);
    }

    _store.rebuild_reading_items_from_cache(
      start_index,
      end_index,
      _store.chapter_list,
    );

    _min_loaded_chapter_index = start_index;
    _loaded_chapter_index = end_index;
  }

  /// 跳转后的预加载链：提前把目标章节前后多章写入缓存。
  ///
  /// 目录从第 5 章跳到第 18 章后，用户第一次滑动时最容易遇到上下章拼接。
  /// 因此这里不只缓存相邻 1 章，而是前后各缓存 2 章，降低首次滑动等待网络的概率。
  /// 这里只做缓存，不修改 reading_items。
  void _preload_chain_after_jump(int index) {
    _preload_chapter_window(index, radius: 2);
  }

  /// 获取章节内容，优先从缓存读取，缓存未命中则发起网络请求并写入缓存。
  ///
  /// 这是所有章节数据获取的唯一入口，保证缓存一致性。
  ///
  /// [index] 章节在目录中的索引。
  /// 返回章节正文文本。
  Future<String> _fetch_chapter_content(int index, {bool force = false}) async {
    if (index < 0 || index >= _store.chapter_list.length) {
      return '';
    }

    final NovelChapterInfo chapter = _store.chapter_list[index];
    final String content_url = chapter.content_url;

    // 内存缓存命中，直接返回。
    if (!force) {
      final String? cached = _store.get_cached_chapter_content(index);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // 磁盘缓存命中，回写内存缓存后返回。
    if (!force) {
      final String? disk_cached = await _read_chapter_content_from_disk_cache(
        content_url,
      );
      if (disk_cached != null && disk_cached.isNotEmpty) {
        _store.cache_chapter_content(index, disk_cached);
        return disk_cached;
      }
    }

    // 缓存未命中，发起网络请求。
    final String content = await get_chapter_content(chapter.content_url);
    if (content.isNotEmpty) {
      _store.cache_chapter_content(index, content);
      await _write_chapter_content_to_disk_cache(content_url, content);
    }
    return content;
  }

  /// 异步预加载指定章节附近的章节到缓存（不更新 reading_items）。
  ///
  /// 当用户正在阅读第 N 章时，提前将 N 前后 2 章内容缓存，
  /// 这样自然滚动或跳转时可以直接从缓存读取，无需等待网络请求。
  ///
  /// [current_index] 当前章节索引。
  void _preload_adjacent_chapters(int current_index) {
    _preload_chapter_window(current_index, radius: 2);
  }

  /// 预加载指定章节前后窗口内的正文到缓存。
  ///
  /// 只请求/写缓存，不 append/prepend 正文列表，因此不会改变当前滚动高度。
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

  /// 判断当前路由参数是否合法。
  bool get has_valid_story_id => story_id > _min_valid_story_id;

  /// 切换导航栏显示状态。
  void toggle_navigation() {
    show_navigation.value = !show_navigation.value;
  }

  /// 根据滚动方向自动显示/隐藏导航栏。
  ///
  /// 上滑（内容向上移动）时隐藏，下滑（内容向下移动）时显示。
  /// 使用 8px 阈值防止误触。
  /// 接近顶部 300px 以内时，上滑不显示导航栏，避免在简介区域频繁闪烁。
  void on_scroll(double offset) {
    // TODO 接近顶部阈值（300px），在此范围内上滑不显示导航栏
    const double near_top_threshold = 300.0;

    // 判断滚动方向：offset 增大 = 向下滑动（看更晚的内容）。
    _is_scrolling_down = offset > _last_scroll_offset;
    final double delta = (offset - _last_scroll_offset).abs();
    _last_scroll_offset = offset;

    // 记录导航栏可见时的偏移量。
    if (_scroll_offset_when_visible == 0 && show_navigation.value) {
      _scroll_offset_when_visible = offset;
    }
    final double scroll_distance = (offset - _scroll_offset_when_visible).abs();

    // 接近顶部时，强制隐藏导航栏并返回，不处理上滑显示逻辑。
    if (offset < near_top_threshold) {
      if (show_navigation.value) {
        show_navigation.value = false;
      }
      _scroll_offset_when_visible = 0;
      return;
    }

    // 下滑 + 可见 + 累计距离 > 8px → 隐藏。
    if (_is_scrolling_down && show_navigation.value && scroll_distance > 8) {
      show_navigation.value = false;
    }

    // 上滑 + 隐藏 + 瞬时 delta > 8px → 显示（仅在远离顶部时生效）。
    if (!_is_scrolling_down && !show_navigation.value && delta > 8) {
      show_navigation.value = true;
      _scroll_offset_when_visible = offset;
    }
  }

  /// 是否为第一章。
  bool get is_first_chapter => current_chapter_index.value == 0;

  /// 当前阅读列表是否包含并展示小说简介。
  ///
  /// 自然从第一章开始阅读时，即使当前章节已经推进到第二章、第三章，简介仍然在列表顶部；
  /// 只有目录跳转到非第一章且列表从中间章节开始时，才隐藏简介。
  bool get should_show_introduction => _min_loaded_chapter_index == 0;

  /// 是否为最后一章。
  bool get is_last_chapter =>
      _store.chapter_list.isEmpty ||
      current_chapter_index.value >= _store.chapter_list.length - 1;

  /// 跳转到上一章。
  Future<void> jump_to_prev_chapter() async {
    if (current_chapter_index.value > 0) {
      final int prev_index = current_chapter_index.value - 1;

      // 如果上一章还没加载，则先加载
      if (prev_index < _min_loaded_chapter_index) {
        await load_prev_chapter();
      }

      current_chapter_index.value = prev_index;
      show_navigation.value = false;
    }
  }

  /// 跳转到下一章。
  Future<void> jump_to_next_chapter() async {
    if (current_chapter_index.value < _store.chapter_list.length - 1) {
      final int next_index = current_chapter_index.value + 1;

      // 如果下一章还没加载，则先加载
      if (next_index > _loaded_chapter_index) {
        await load_next_chapter();
      }

      current_chapter_index.value = next_index;
      show_navigation.value = false;
    }
  }

  /// 根据进度比例跳转章节。
  Future<void> jump_by_progress(double ratio) async {
    if (_store.chapter_list.isEmpty) return;
    final int index = (ratio * (_store.chapter_list.length - 1)).round();
    await jump_to_chapter(index);
  }

  /// 构建占位详情数据。
  ReadDetail build_detail() {
    final NovelInfo? info = _store.novel_info.value;

    if (info == null) {
      // 如果 Store 为空（加载中或加载失败），返回基础占位数据。
      return _build_placeholder_detail();
    }

    // 根据 publish_status 确定字数副标题文案。
    String word_count_subtitle = '';
    if (info.publish_status == 1) {
      word_count_subtitle = easy.tr('read.status_serializing');
    } else if (info.publish_status == 2) {
      word_count_subtitle = easy.tr('read.status_completed');
    } else if (info.publish_status == 3) {
      word_count_subtitle = easy.tr('read.status_removed');
    }

    // 将 NovelInfo 映射为 ReadDetail。
    return ReadDetail(
      story_id: int.tryParse(info.id) ?? story_id,
      title: info.language_info.title,
      cover_url: info.language_info.cover_url,
      author_id: int.tryParse(info.author_id) ?? 0,
      author_avatar_url: info.author_avatar,
      author_name: info.author_name,
      focus_on: info.focus_on,
      score_major_text: info.score.toStringAsFixed(1),
      score_minor_text: easy.tr('read.score_unit'),
      review_count_text: easy.tr(
        'read.review_count',
        args: [info.comment_count],
      ),
      reading_major_text: info.read_count,
      reading_minor_text: easy.tr('read.reading_unit'),
      reading_subtitle_text: easy.tr('read.reading_status'),
      word_count_major_text: (info.language_info.word_count / 10000)
          .toStringAsFixed(1),
      word_count_minor_text: easy.tr('read.word_count_unit'),
      word_count_subtitle_text: word_count_subtitle,
      tag_list: info.category_list,
      intro_text: info.language_info.introduction,
      chapter_title:
          info.chapter_info?.title ??
          (_store.chapter_list.isNotEmpty
              ? _store.chapter_list.first.title
              : ''),
      comment_list: info.comment_list
          .map(
            (c) => ReadComment(
              avatar_url: c.avatar_url,
              user_name: c.name,
              content: c.comment_content,
              star_count: c.score,
              user_id: int.tryParse(c.user_id) ?? 0,
            ),
          )
          .toList(),
    );
  }

  /// 构建基础占位详情数据。
  ReadDetail _build_placeholder_detail() {
    // 标题为空时使用兜底标题，避免封面区出现空文本。
    final String resolved_title = story_title.trim().isEmpty
        ? '未命名小说 $story_id'
        : story_title.trim();

    return ReadDetail(
      story_id: story_id,
      title: resolved_title,
      cover_url: '',
      author_id: 0,
      author_avatar_url: '',
      author_name: '',
      focus_on: false,
      score_major_text: '0.0',
      score_minor_text: easy.tr('read.score_unit'),
      review_count_text: easy.tr('read.review_count', args: ['0']),
      reading_major_text: '0',
      reading_minor_text: easy.tr('read.reading_unit'),
      reading_subtitle_text: easy.tr('read.reading_status'),
      word_count_major_text: '0',
      word_count_minor_text: easy.tr('read.word_count_unit'),
      word_count_subtitle_text: easy.tr('image_text.loading'),
      tag_list: const <String>[],
      intro_text: easy.tr('image_text.loading'),
      chapter_title: '',
      comment_list: const <ReadComment>[],
    );
  }

  /// 构建正文内容项列表。
  List<ReadingContentItem> build_reading_items() {
    final List<ReadingContentItem> items = _store.reading_items;

    if (items.isEmpty) {
      // 如果正文内容为空，返回一个提示占位。
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

  /// 根据滚动位置计算阅读百分比。
  ///
  /// 基于当前章节索引和章节内进度换算全书进度，
  /// 避免因只加载部分章节导致进度计算偏差。
  ///
  /// [scroll_offset] 当前滚动偏移量。
  /// [max_scroll_extent] 最大滚动范围。
  /// [reading_section_offset] 正文区块距离列表顶部的绝对高度。
  double calculate_reading_progress(
    double scroll_offset,
    double max_scroll_extent, {
    double reading_section_offset = 0,
  }) {
    if (_total_word_count <= 0 || _store.chapter_list.isEmpty) {
      return 0;
    }

    // 获取当前章节索引。
    final int chapter_index = current_chapter_index.value;
    if (chapter_index < 0 || chapter_index >= _store.chapter_list.length) {
      return 0;
    }

    // 基于章节字数计算全书进度。
    return calculate_total_progress_percent_for_chapter(
      chapter_index: chapter_index,
      chapter_progress_percent: _current_chapter_progress,
    );
  }

  /// 根据全书阅读百分比推算所在章节索引。
  ///
  /// 遍历章节字数累加，找到进度百分比落入的章节。
  /// 返回章节索引；章节列表为空时返回 0。
  int find_chapter_index_by_progress(double progress_percent) {
    if (_store.chapter_list.isEmpty) return 0;

    int total_words = _total_word_count;
    if (total_words <= 0) {
      for (final ch in _store.chapter_list) {
        total_words += ch.word_count;
      }
    }
    if (total_words <= 0) return 0;

    final double target_words = total_words * progress_percent / 100;
    int cumulative = 0;
    for (int i = 0; i < _store.chapter_list.length; i++) {
      cumulative += _store.chapter_list[i].word_count;
      if (cumulative >= target_words) return i;
    }
    return _store.chapter_list.length - 1;
  }

  /// 根据全书阅读进度换算指定章节内部的阅读百分比。
  ///
  /// [reading_progress_percent] 当前全书阅读百分比，来自现有滚动进度计算。
  /// [chapter_index] 需要换算的章节索引，通常为当前正在阅读的章节。
  /// 返回 0-100 的章节内进度百分比；章节字数缺失时返回 0。
  double calculate_chapter_progress_percent({
    required double reading_progress_percent,
    required int chapter_index,
  }) {
    if (chapter_index < 0 || chapter_index >= _store.chapter_list.length) {
      return 0;
    }

    int total_word_count = _total_word_count;
    if (total_word_count <= 0) {
      for (final NovelChapterInfo chapter in _store.chapter_list) {
        total_word_count += chapter.word_count;
      }
    }

    final NovelChapterInfo chapter = _store.chapter_list[chapter_index];
    if (total_word_count <= 0 || chapter.word_count <= 0) {
      return 0;
    }

    int words_before_chapter = 0;
    for (int i = 0; i < chapter_index; i++) {
      words_before_chapter += _store.chapter_list[i].word_count;
    }

    final double estimated_read_words =
        total_word_count * (reading_progress_percent.clamp(0.0, 100.0) / 100);
    final double read_words_in_chapter =
        (estimated_read_words - words_before_chapter).clamp(
          0.0,
          chapter.word_count.toDouble(),
        );

    return ((read_words_in_chapter / chapter.word_count) * 100).clamp(
      0.0,
      100.0,
    );
  }

  /// 根据章节索引和章节内进度换算全书阅读进度。
  ///
  /// [chapter_index] 当前章节索引。
  /// [chapter_progress_percent] 当前章节内阅读百分比，取值 0 到 100。
  double calculate_total_progress_percent_for_chapter({
    required int chapter_index,
    required double chapter_progress_percent,
  }) {
    if (chapter_index < 0 || chapter_index >= _store.chapter_list.length) {
      return 0;
    }

    int total_word_count = _total_word_count;
    if (total_word_count <= 0) {
      for (final NovelChapterInfo chapter in _store.chapter_list) {
        total_word_count += chapter.word_count;
      }
    }
    if (total_word_count <= 0) {
      return 0;
    }

    int words_before_chapter = 0;
    for (int i = 0; i < chapter_index; i++) {
      words_before_chapter += _store.chapter_list[i].word_count;
    }

    final NovelChapterInfo chapter = _store.chapter_list[chapter_index];
    final double chapter_read_words =
        chapter.word_count * (chapter_progress_percent.clamp(0.0, 100.0) / 100);
    final double read_words = words_before_chapter + chapter_read_words;
    return ((read_words / total_word_count) * 100).clamp(0.0, 100.0);
  }

  /// 获取指定章节的 GlobalKey。
  GlobalKey get_chapter_key(int index) {
    return _chapter_keys.putIfAbsent(index, () => GlobalKey());
  }

  /// 当前章节内阅读进度百分比（0-100）。
  ///
  /// 由外部（index.dart）通过 [update_chapter_progress] 更新。
  double _current_chapter_progress = 0;

  /// 更新当前章节内阅读进度。
  void update_chapter_progress(double progress) {
    _current_chapter_progress = progress.clamp(0.0, 100.0);
  }
}
