// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/logic.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 未提供宽高时用漫画页比例预留位置；获得原图尺寸后自然显示整张长条图片。
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
  return width / ratio;
}

/// 按真实图片高度计算正在阅读的页，兼容横页、竖页和长条图混排。
int comic_page_index(List<double> heights, double offset) {
  double consumed = 0;
  for (int index = 0; index < heights.length; index++) {
    consumed += heights[index];
    if (offset < consumed) return index;
  }
  return heights.isEmpty ? 0 : heights.length - 1;
}

String comic_progress_key(int comic_id) {
  final user_id = Get.isRegistered<UserInformation>()
      ? Get.find<UserInformation>().userInfo.value?.id ?? 0
      : 0;
  return 'comics_progress_${user_id}_$comic_id';
}

/// 章节阅读及节流保存。保存参数用当前章节快照，避免切章请求串写。
class ComicReaderLogic extends ComicsController {
  final ScrollController scroll = ScrollController();
  ComicReading? reading;
  bool loading = true;
  bool controls_visible = true;
  int page_index = 0;
  int current_chapter_id = 0;
  bool _adjusting_layout = false;
  double viewport_width = ComicsStyle.reader_width;
  final Map<int, double> measured_ratios = <int, double>{};
  int _request_id = 0;
  Timer? _progress_timer;
  int _last_saved_index = -1;
  bool _restoring = false;
  bool _has_scrolled = false;
  ComicReaderLogic() {
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

  Future<void> load(int chapter_id, {int initial_page = 0}) async {
    if (loading && current_chapter_id != 0) return;
    current_chapter_id = chapter_id;
    final request_id = ++_request_id;
    if (reading != null) await save_progress();
    if (disposed) return;
    loading = true;
    error = null;
    _progress_timer?.cancel();
    emit();
    try {
      final result = await comics_read(chapter_id);
      if (disposed || request_id != _request_id) return;
      reading = result;
      measured_ratios.clear();
      final cached = await StorageUtil.getData(
        comic_progress_key(result.comic.id),
      );
      if (disposed || request_id != _request_id) return;
      int? cached_page_index;
      if (cached != null) {
        try {
          final previous = comics_map(jsonDecode(cached));
          if (comics_int(previous['chapter_id']) == result.chapter.id) {
            final dimensions = comics_map(previous['image_dimensions']);
            for (final entry in dimensions.entries) {
              final index = int.tryParse(entry.key);
              final measurement = comics_map(entry.value);
              final ratio = double.tryParse('${measurement['ratio']}');
              if (index != null &&
                  index >= 0 &&
                  index < result.images.length &&
                  ratio != null &&
                  ratio > 0 &&
                  measurement['url'] == result.images[index].image_url) {
                measured_ratios[index] = ratio;
              }
            }
            // 记录本地进度页码，供未显式传入起始页时恢复阅读位置。
            cached_page_index = comics_int(previous['page_index']);
          }
        } catch (_) {
          /* 旧版本缓存缺少尺寸时正常按默认比例构建。 */
        }
      }
      // 调用方显式指定起始页时优先使用；否则回退到本地缓存进度。
      final int resume_page = initial_page > 0
          ? initial_page
          : (cached_page_index ?? 0);
      page_index = resume_page.clamp(
        0,
        result.images.isEmpty ? 0 : result.images.length - 1,
      );
      _last_saved_index = -1;
      _has_scrolled = false;
      _restoring = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (disposed || request_id != _request_id) return;
        jump_to_page(page_index);
        _restoring = false;
      });
    } catch (failure) {
      if (!disposed && request_id == _request_id) error = failure.toString();
    } finally {
      if (!disposed && request_id == _request_id) {
        loading = false;
        emit();
      }
    }
  }

  void set_width(double width) {
    viewport_width = width;
  }

  double image_height(int index) => comic_page_height(
    reading!.images[index],
    viewport_width,
    measured_ratio: measured_ratios[index],
  );

  /// 图片真实比例到达时保留可见页及页内位置，加载长条图不会把续读位置推到别页。
  void report_ratio(int index, double ratio) {
    if (disposed ||
        measured_ratios[index] == ratio ||
        ratio <= 0 ||
        reading == null) {
      return;
    }
    final anchor = page_index;
    final previous_heights = page_heights;
    final old_prefix = previous_heights
        .take(anchor)
        .fold<double>(0, (sum, height) => sum + height);
    final within_page = scroll.hasClients
        ? (scroll.offset - old_prefix).clamp(0.0, previous_heights[anchor])
        : 0.0;
    measured_ratios[index] = ratio;
    _last_saved_index = -1;
    _progress_timer?.cancel();
    _progress_timer = Timer(
      const Duration(milliseconds: ComicsStyle.progress_delay_ms),
      () => save_progress(),
    );
    final request_id = _request_id;
    if (index <= anchor) {
      _adjusting_layout = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (disposed || request_id != _request_id || !scroll.hasClients) return;
        final next_heights = page_heights;
        final prefix = next_heights
            .take(anchor)
            .fold<double>(0, (sum, height) => sum + height);
        final adjusted_within = previous_heights[anchor] > 0
            ? within_page * next_heights[anchor] / previous_heights[anchor]
            : 0.0;
        scroll.jumpTo(
          (prefix + adjusted_within).clamp(
            0.0,
            scroll.position.maxScrollExtent,
          ),
        );
        _adjusting_layout = false;
      });
    }
    emit();
  }

  void jump_to_page(int index) {
    if (!scroll.hasClients || reading == null) return;
    final heights = page_heights;
    final target = index.clamp(0, heights.isEmpty ? 0 : heights.length - 1);
    final offset = heights
        .take(target)
        .fold<double>(0, (total, height) => total + height);
    scroll.jumpTo(offset.clamp(0, scroll.position.maxScrollExtent));
    page_index = target;
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
    _has_scrolled = true;
    final next_index = comic_page_index(page_heights, scroll.offset);
    if (next_index == page_index) return;
    page_index = next_index;
    emit();
    _progress_timer?.cancel();
    _progress_timer = Timer(
      const Duration(milliseconds: ComicsStyle.progress_delay_ms),
      () => save_progress(),
    );
  }

  void toggle_controls() {
    controls_visible = !controls_visible;
    emit();
  }

  Future<void> save_progress() async {
    final value = reading;
    if (value == null ||
        value.images.isEmpty ||
        _restoring ||
        (!_has_scrolled && page_index == 0 && loading) ||
        _last_saved_index == page_index) {
      return;
    }
    final saved_index = page_index;
    final progress = <String, dynamic>{
      'comic_id': value.comic.id,
      'chapter_id': value.chapter.id,
      'page_index': saved_index,
      'language': value.language.language,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'image_dimensions': measured_ratios.map(
        (index, ratio) => MapEntry('$index', <String, dynamic>{
          'url': value.images[index].image_url,
          'ratio': ratio,
        }),
      ),
    };
    try {
      await StorageUtil.saveData(
        comic_progress_key(value.comic.id),
        jsonEncode(progress),
      );
      if (Get.isRegistered<UserInformation>() &&
          Get.find<UserInformation>().isLoggedIn.value) {
        await comics_request('save_progress', <String, dynamic>{
          'comic_id': value.comic.id,
          'chapter_id': value.chapter.id,
          'page_index': saved_index,
        });
        // 阅读进度变化后刷新书架历史列表。
        unawaited(BookshelfSyncService.history_changed());
      }
      if (reading?.chapter.id == value.chapter.id) {
        _last_saved_index = saved_index;
      }
    } catch (_) {
      // 本地进度保留；下一次页码变化会重新尝试服务器同步。
    }
  }

  @override
  void dispose() {
    _progress_timer?.cancel();
    unawaited(save_progress());
    scroll.dispose();
    super.dispose();
  }
}
