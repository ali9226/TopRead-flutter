import 'package:flutter/material.dart';
import 'package:app/components/inline_native_ad/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/pages/read/logic.dart' as read_logic;
import 'package:app/pages/read/widgets/introduction_section/index.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/native_ad_insert_index.dart';

import './style.dart';

/// 阅读页正文内容组件。
///
/// 负责展示小说正文内容，并在命中当前会话概率的章节正文中部插入
/// 与短篇阅读页一致的原生高级广告。
class ReadContent extends StatelessWidget {
  /// 页面逻辑层。
  final read_logic.Logic logic;

  /// 当前是否为夜间主题，用于控制正文区块的颜色。
  final bool is_dark;

  /// 详情数据。
  final read_logic.ReadDetail detail;

  /// 正文内容项列表。
  final List<ReadingContentItem> reading_items;

  /// 主阅读列表滚动控制器，用于延迟挂载屏幕外的平台广告视图。
  final ScrollController scroll_controller;

  /// 正文区块的锚点 key，用于点击底部胶囊后快速定位到正文。
  final GlobalKey? reading_section_key;

  /// 正文点击回调，由页面读取最新滚动状态并决定翻页或显示导航栏。
  final GestureTapDownCallback on_reading_tap_down;

  /// 关注状态变更回调。
  final ValueChanged<bool>? on_focus_changed;

  /// 当前小说唯一的原生广告配置。
  final AdConfig? native_ad_config;

  /// 当前小说是否正在请求原生广告配置。
  final bool is_native_ad_config_loading;

  /// 原生广告产生真实展示后的统计回调。
  final VoidCallback? on_native_ad_impression;

  const ReadContent({
    super.key,
    required this.logic,
    required this.is_dark,
    required this.detail,
    required this.reading_items,
    required this.scroll_controller,
    required this.on_reading_tap_down,
    this.reading_section_key,
    this.on_focus_changed,
    this.native_ad_config,
    this.is_native_ad_config_loading = false,
    this.on_native_ad_impression,
  });

  @override
  Widget build(BuildContext context) {
    final Color reading_text_color = is_dark
        ? ContentStyle.reading_text_color_dark
        : ContentStyle.reading_text_color_light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (logic.should_show_introduction) ...<Widget>[
          ReadIntroductionSection(
            is_dark: is_dark,
            detail: detail,
            on_focus_changed: on_focus_changed,
          ),
          SizedBox(height: ContentStyle.reading_top_spacing),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: on_reading_tap_down,
          child: Container(
            key: reading_section_key,
            width: double.infinity,
            color: Colors.transparent,
            margin: const EdgeInsets.only(
              bottom: ContentStyle.reading_container_bottom_margin,
            ),
            padding: ContentStyle.reading_padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _build_reading_widgets(
                reading_text_color: reading_text_color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 按章节收集正文段落长度，用于寻找正文内容 50% 后的完整段落边界。
  Map<int, List<int>> _resolve_chapter_paragraph_lengths() {
    final Map<int, List<int>> paragraph_lengths = <int, List<int>>{};
    for (final ReadingContentItem item in reading_items) {
      if (item.is_title) continue;
      paragraph_lengths
          .putIfAbsent(item.chapter_index, () => <int>[])
          .add(item.text.trim().runes.length);
    }
    return paragraph_lengths;
  }

  /// 为当前阅读窗口计算每个命中章节的广告段落位置。
  Map<int, int> _resolve_native_ad_insert_indexes() {
    if (!AdDisplayPolicy.can_show_ads()) return <int, int>{};

    const String log_prefix = '[ReadNativeAd]';
    final Map<int, int> insert_indexes = <int, int>{};
    final Map<int, List<int>> paragraph_lengths =
        _resolve_chapter_paragraph_lengths();
    for (final MapEntry<int, List<int>> entry in paragraph_lengths.entries) {
      final bool should_show = logic.should_show_native_ad_for_chapter(
        entry.key,
      );
      final bool has_native_ad =
          should_show &&
          (native_ad_config != null || is_native_ad_config_loading);
      final int? insert_index =
          resolve_native_ad_insert_index_by_paragraph_lengths(
            paragraph_lengths: entry.value,
            has_native_ad: has_native_ad,
            display_ratio: ContentStyle.native_ad_display_ratio,
            minimum_paragraph_count:
                ContentStyle.native_ad_minimum_paragraph_count,
          );
      if (should_show && insert_index == null) {
        logUtil(
          msg:
              '$log_prefix 广告未渲染, chapter=${entry.key}, '
              'should_show=$should_show, '
              'native_ad_config=${native_ad_config != null}, '
              'is_loading=$is_native_ad_config_loading, '
              'has_native_ad=$has_native_ad, '
              'paragraph_count=${entry.value.length}, '
              'min_paragraph=${ContentStyle.native_ad_minimum_paragraph_count}',
          type: 'w',
        );
      }
      if (insert_index != null) {
        insert_indexes[entry.key] = insert_index;
      }
    }
    return insert_indexes;
  }

  /// 构建正文标题、段落与各章唯一的原生广告卡片。
  List<Widget> _build_reading_widgets({required Color reading_text_color}) {
    final Set<int> assigned_chapter_keys = <int>{};
    final Map<int, int> rendered_paragraph_counts = <int, int>{};
    final Map<int, int> ad_insert_indexes = _resolve_native_ad_insert_indexes();
    final List<Widget> widgets = <Widget>[];

    for (final ReadingContentItem item in reading_items) {
      GlobalKey? item_key;
      if (item.is_title && assigned_chapter_keys.add(item.chapter_index)) {
        item_key = logic.get_chapter_key(item.chapter_index);
      }

      widgets.add(
        Container(
          key: item_key,
          padding: EdgeInsets.only(
            bottom: item.is_title
                ? ContentStyle.reading_paragraph_bottom_spacing * 1.5
                : ContentStyle.reading_paragraph_bottom_spacing,
            top: item.is_title
                ? ContentStyle.reading_paragraph_top_spacing * 2
                : 0,
          ),
          child: _ReaderParagraphItem(
            text: item.text,
            is_title: item.is_title,
            body_font_size: logic.body_font_size.value,
            text_color: item.is_title
                ? (is_dark
                      ? ContentStyle.reading_title_color_dark
                      : ContentStyle.reading_title_color_light)
                : reading_text_color,
          ),
        ),
      );

      if (!item.is_title) {
        final int rendered_count =
            (rendered_paragraph_counts[item.chapter_index] ?? 0) + 1;
        rendered_paragraph_counts[item.chapter_index] = rendered_count;
        if (rendered_count == ad_insert_indexes[item.chapter_index]) {
          widgets.add(_build_native_ad(item.chapter_index));
        }
      }
    }

    return widgets;
  }

  /// 构建单章正文中部的安全可视挂载广告位。
  Widget _build_native_ad(int chapter_index) {
    return ViewportAwareInlineNativeAdBanner(
      key: ValueKey<String>('read-native-ad-$chapter_index'),
      scroll_controller: scroll_controller,
      ad_unit_id: native_ad_config?.adsId ?? '',
      uuid: native_ad_config?.uuid ?? '',
      badge_text_key: 'short_story_read.ad_free',
      show_continue_hint: false,
      on_ad_impression: on_native_ad_impression,
    );
  }
}

/// 阅读页单段正文组件。
class _ReaderParagraphItem extends StatelessWidget {
  /// 当前段落文本内容。
  final String text;

  /// 是否为章节标题。
  final bool is_title;

  /// 正文字号。
  final double body_font_size;

  /// 段落文字颜色。
  final Color text_color;

  const _ReaderParagraphItem({
    required this.text,
    this.is_title = false,
    required this.body_font_size,
    required this.text_color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: text_color,
        fontSize: is_title
            ? ContentStyle.reading_title_font_size
            : body_font_size,
        height: ContentStyle.reading_paragraph_height,
        fontWeight: FontConfig.adjustedWeight(
          is_title ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );
  }
}
