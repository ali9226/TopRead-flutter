// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/services/comics_progress/record.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// TODO 未知尺寸预留漫画页比例；原始比例到达后按原图高度显示，绝不裁切。
double comic_page_height(
  ComicImageData image,
  double width, {
  double? measured_ratio,
}) {
  final ratio =
      measured_ratio ??
      (image.width > 0 && image.height > 0
          ? image.width / image.height
          : ComicsStyle.cover_ratio);
  return width /
      (ratio.isFinite && ratio > 0 ? ratio : ComicsStyle.cover_ratio);
}

/// TODO 前缀高度决定可见图片，长条图和横页均使用同一页码算法。
int comic_page_index(List<double> heights, double offset) {
  double consumed = 0;
  for (int index = 0; index < heights.length; index++) {
    consumed += heights[index];
    if (offset < consumed) return index;
  }
  return heights.isEmpty ? 0 : heights.length - 1;
}

/// TODO 兼容旧调用方，账号解析实际由统一进度服务负责。
String comic_progress_key(int comic_id) => ComicsProgressService.storage_key(
  comic_id,
  ComicsProgressService.current_account_id(),
);

/// TODO 章节请求可淘汰旧响应；进度采用不可变快照交给页面外串行队列，关闭页面也不会串写。
class ComicReaderLogic extends ComicsController {
  final ScrollController scroll = ScrollController();
  final Future<ComicReading> Function(int)? read_chapter;
  final ComicsProgressService progress;
  ComicReading? reading;
  bool loading = true;
  bool controls_visible = true;
  int page_index = 0;
  int current_chapter_id = 0;
  double viewport_width = ComicsStyle.reader_width;
  final Map<int, double> measured_ratios = <int, double>{};
  int _request_id = 0;
  int _owner_id = 0;
  int _owner_revision = 0;
  String _owner_token = '';
  bool _restoring = false;
  bool _adjusting_layout = false;
  double _layout_fraction = 0;
  double _resume_fraction = 0;
  double _last_fraction = 0;
  Timer? _progress_timer;

  ComicReaderLogic({this.read_chapter, ComicsProgressService? progress})
    : progress = progress ?? ComicsProgressService.instance {
    scroll.addListener(_on_scroll);
  }

  List<double> get page_heights =>
      reading?.images
          .asMap()
          .entries
          .map(
            (entry) => comic_page_height(
              entry.value,
              viewport_width,
              measured_ratio: measured_ratios[entry.key],
            ),
          )
          .toList() ??
      <double>[];

  /// TODO 先快照保存旧章，再发新请求，不等待网络才允许导航；同作品保存顺序由共享队列保证。
  Future<void> load(int chapter_id, {int? initial_page}) async {
    if (disposed) return;
    if (chapter_id <= 0) {
      loading = false;
      error = tr('comics.unavailable');
      emit();
      return;
    }
    unawaited(save_progress());
    final request_id = ++_request_id;
    final owner = progress.account_id();
    final revision = progress.session_revision();
    final token_request = read_chapter == null
        ? progress.read_token()
        : Future<String>.value('');
    current_chapter_id = chapter_id;
    _progress_timer?.cancel();
    loading = true;
    error = null;
    emit();
    try {
      final token = await token_request;
      if (disposed || request_id != _request_id) return;
      if (owner != progress.account_id() ||
          revision != progress.session_revision()) {
        throw StateError(tr('comics.reader_account_changed'));
      }
      final result = read_chapter != null
          ? await read_chapter!(chapter_id)
          : await comics_read(chapter_id, authorization_token: token);
      final cached = await progress.read_record(
        result.comic.id,
        user_id: owner,
      );
      if (disposed || request_id != _request_id) return;
      if (owner != progress.account_id() ||
          revision != progress.session_revision() ||
          (result.read_record['user_id'] != null &&
              comics_int(result.read_record['user_id']) != owner)) {
        loading = false;
        error = tr('comics.reader_account_changed');
        emit();
        return;
      }
      final local = ComicProgressRecord.from_json(cached);
      final server = ComicProgressRecord.from_json(result.read_record);
      final valid_server =
          server.comic_id == result.comic.id && server.chapter_id > 0;
      final server_newer =
          !local.server_confirmed ||
          (server.updated_at != null &&
              (local.updated_at == null ||
                  server.updated_at!.isAfter(local.updated_at!)));
      final previous = valid_server && !local.pending_sync && server_newer
          ? server
          : local;
      reading = result;
      _owner_id = owner;
      _owner_revision = revision;
      _owner_token = token;
      measured_ratios.clear();
      final same_chapter = previous.chapter_id == result.chapter.id;
      if (same_chapter) {
        for (final entry in previous.image_dimensions.entries) {
          final index = int.tryParse(entry.key);
          final measurement = comics_map(entry.value);
          final ratio = double.tryParse('${measurement['ratio']}');
          if (index != null &&
              index >= 0 &&
              index < result.images.length &&
              ratio != null &&
              ratio.isFinite &&
              ratio > 0 &&
              measurement['url'] == result.images[index].image_url) {
            measured_ratios[index] = ratio;
          }
        }
      }
      final target = initial_page ?? (same_chapter ? previous.page_index : 0);
      page_index = target.clamp(
        0,
        result.images.isEmpty ? 0 : result.images.length - 1,
      );
      _resume_fraction =
          same_chapter &&
              (initial_page == null || target == previous.page_index)
          ? previous.page_fraction
          : 0;
      _last_fraction = _resume_fraction;
      _restoring = true;
      _adjusting_layout = false;
      loading = false;
      // TODO 进入章节即落盘第0页或续读页，不能依赖滚动和图片尺寸回报。
      unawaited(save_progress());
      emit();
      _restore_after_layout(request_id);
    } catch (failure) {
      if (!disposed && request_id == _request_id) {
        error = failure.toString();
        loading = false;
        emit();
      }
    }
  }

  void _restore_after_layout(int request_id, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (disposed || request_id != _request_id) return;
      if (!scroll.hasClients) {
        if (attempt < 3) {
          _restore_after_layout(request_id, attempt: attempt + 1);
        }
        return;
      }
      jump_to_page(page_index, fraction: _resume_fraction);
      _restoring = false;
    });
  }

  /// TODO 横竖屏切换维持图片页及页内比例；重排不算用户新的阅读位置。
  void set_width(double width) {
    if (width <= 0 || viewport_width == width) return;
    final fraction = _page_fraction;
    viewport_width = width;
    if (scroll.hasClients && !_restoring) {
      _adjusting_layout = true;
      _layout_fraction = fraction;
      final request_id = _request_id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (disposed || request_id != _request_id) return;
        jump_to_page(page_index, fraction: fraction);
        _adjusting_layout = false;
      });
    }
  }

  double image_height(int index) => comic_page_height(
    reading!.images[index],
    viewport_width,
    measured_ratio: measured_ratios[index],
  );

  double get _page_fraction {
    if (_restoring) return _resume_fraction;
    if (!scroll.hasClients) return _last_fraction;
    if (_adjusting_layout) return _layout_fraction;
    final heights = page_heights;
    if (heights.isEmpty || page_index >= heights.length) return 0;
    final prefix = heights
        .take(page_index)
        .fold<double>(0, (sum, height) => sum + height);
    return ((scroll.offset - prefix) / heights[page_index]).clamp(0, 1);
  }

  /// TODO 图片尺寸异步到达时锚定当前页内比例，前面长条图片变高不会把读者推到别章或别页。
  void report_ratio(int index, double ratio, {int? chapter_id}) {
    if (disposed ||
        reading == null ||
        index < 0 ||
        index >= reading!.images.length ||
        (chapter_id != null && reading!.chapter.id != chapter_id) ||
        !ratio.isFinite ||
        ratio <= 0 ||
        measured_ratios[index] == ratio) {
      return;
    }
    final anchor = page_index;
    final fraction = _page_fraction;
    measured_ratios[index] = ratio;
    if (index <= anchor) {
      _adjusting_layout = true;
      _layout_fraction = fraction;
      final request_id = _request_id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (disposed || request_id != _request_id) return;
        jump_to_page(anchor, fraction: fraction);
        _adjusting_layout = false;
      });
    }
    _schedule_save();
    emit();
  }

  void jump_to_page(int index, {double fraction = 0}) {
    if (!scroll.hasClients || reading == null) return;
    final heights = page_heights;
    if (heights.isEmpty) return;
    final target = index.clamp(0, heights.length - 1);
    final offset =
        heights.take(target).fold<double>(0, (sum, height) => sum + height) +
        heights[target] * fraction;
    scroll.jumpTo(offset.clamp(0, scroll.position.maxScrollExtent));
    page_index = target;
    _last_fraction = fraction.clamp(0, 1);
    emit();
  }

  void _on_scroll() {
    if (reading == null ||
        loading ||
        _restoring ||
        _adjusting_layout ||
        !scroll.hasClients) {
      return;
    }
    final next_index = comic_page_index(page_heights, scroll.offset);
    if (next_index != page_index) {
      page_index = next_index;
      emit();
    }
    _last_fraction = _page_fraction;
    // TODO 同一张长条图内部滚动也要保存页内位置，不能只在跨页时持久化。
    _schedule_save();
  }

  void _schedule_save() {
    _progress_timer?.cancel();
    _progress_timer = Timer(
      const Duration(milliseconds: ComicsStyle.progress_delay_ms),
      () => unawaited(save_progress()),
    );
  }

  void toggle_controls() {
    controls_visible = !controls_visible;
    emit();
  }

  Future<void> save_progress() async {
    _progress_timer?.cancel();
    final value = reading;
    if (value == null || value.images.isEmpty) return;
    final snapshot = ComicProgressRecord(
      comic_id: value.comic.id,
      chapter_id: value.chapter.id,
      chapter_title: value.chapter.title,
      page_index: page_index,
      language: value.language.language,
      comic_language_id: value.language.id,
      updated_at: DateTime.now().toUtc(),
      page_fraction: _page_fraction,
      image_dimensions: measured_ratios.map(
        (index, ratio) => MapEntry('$index', <String, dynamic>{
          'url': value.images[index].image_url,
          'ratio': ratio,
        }),
      ),
    );
    await progress.save(
      snapshot,
      user_id: _owner_id,
      auth_revision: _owner_revision,
      authorization_token: _owner_token,
    );
  }

  Future<void> flush() async {
    final value = reading;
    await save_progress();
    if (value != null) {
      await progress.flush(user_id: _owner_id, comic_id: value.comic.id);
    }
  }

  @override
  void dispose() {
    _progress_timer?.cancel();
    unawaited(flush());
    _request_id++;
    scroll.dispose();
    super.dispose();
  }
}
