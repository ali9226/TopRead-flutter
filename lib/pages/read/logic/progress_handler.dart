// ignore_for_file: non_constant_identifier_names

import 'package:app/models/novel_info.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/device/save_body_font_size.dart';
import 'package:get/get.dart';

import '../utils/progress_calculator.dart';

/// 阅读页进度与设置 Mixin。
///
/// 负责阅读进度计算、字号调节、自动阅读设置等。
mixin ReadProgressMixin {
  /// 小说阅读仓库。
  NovelReadingStore get store;

  /// 书籍总字数。
  int get total_word_count;

  /// 当前阅读到的章节索引。
  RxInt get current_chapter_index;

  /// 正文字号。
  RxDouble get body_font_size;

  /// 字号最小值。
  static const double font_size_min = 16.0;

  /// 字号最大值。
  static const double font_size_max = 36.0;

  /// 字号调节步长。
  static const double font_size_step = 1.0;

  /// 是否正在自动阅读。
  RxBool get is_auto_reading;

  /// 自动阅读速度（0.0 最慢，1.0 最快）。
  RxDouble get auto_read_speed;

  /// 当前章节内阅读进度百分比（0-100）。
  double _current_chapter_progress = 0;

  /// 获取进度计算器实例。
  ProgressCalculator get _progress_calculator => ProgressCalculator(
    chapter_list: store.chapter_list,
    total_word_count: total_word_count,
  );

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

  /// 更新当前章节内阅读进度。
  void update_chapter_progress(double progress) {
    _current_chapter_progress = progress.clamp(0.0, 100.0);
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
    if (total_word_count <= 0 || store.chapter_list.isEmpty) {
      return 0;
    }

    // 获取当前章节索引。
    final int chapter_index = current_chapter_index.value;
    if (chapter_index < 0 || chapter_index >= store.chapter_list.length) {
      return 0;
    }

    // 基于章节字数计算全书进度。
    return calculate_total_progress_percent_for_chapter(
      chapter_index: chapter_index,
      chapter_progress_percent: _current_chapter_progress,
    );
  }

  /// 根据全书阅读百分比推算所在章节索引。
  int find_chapter_index_by_progress(double progress_percent) {
    return _progress_calculator.find_chapter_index_by_progress(progress_percent);
  }

  /// 根据全书阅读进度换算指定章节内部的阅读百分比。
  double calculate_chapter_progress_percent({
    required double reading_progress_percent,
    required int chapter_index,
  }) {
    return _progress_calculator.calculate_chapter_progress_percent(
      reading_progress_percent: reading_progress_percent,
      chapter_index: chapter_index,
    );
  }

  /// 根据章节索引和章节内进度换算全书阅读进度。
  double calculate_total_progress_percent_for_chapter({
    required int chapter_index,
    required double chapter_progress_percent,
  }) {
    return _progress_calculator.calculate_total_progress_percent_for_chapter(
      chapter_index: chapter_index,
      chapter_progress_percent: chapter_progress_percent,
    );
  }
}
