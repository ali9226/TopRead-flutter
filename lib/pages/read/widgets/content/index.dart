import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/read/logic.dart' as read_logic;
import 'package:app/pages/read/widgets/introduction_section/index.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/ad_display_policy.dart';
import './style.dart';

/// 阅读页正文内容组件。
///
/// 负责展示小说正文内容，包括标题、提示信息以及逐段渲染的正文文本。
/// 同时集成了点击分区翻页的交互逻辑。
/// 以 10% 的稳定概率在章节标题后插入原生高级广告。
class ReadContent extends StatelessWidget {
  /// 页面逻辑层。
  final read_logic.Logic logic;

  /// 当前是否为夜间主题，用于控制正文区块的颜色。
  final bool is_dark;

  /// 详情数据。
  final read_logic.ReadDetail detail;

  /// 正文内容项列表。
  final List<ReadingContentItem> reading_items;

  /// 正文区块的锚点 key，用于点击底部胶囊后快速定位到正文。
  final GlobalKey? reading_section_key;

  /// 正文点击回调，由页面读取最新滚动状态并决定翻页或显示导航栏。
  final GestureTapDownCallback on_reading_tap_down;

  /// 关注状态变更回调。
  final ValueChanged<bool>? on_focus_changed;

  /// 小说 ID（用于稳定随机决定哪些章节插入广告）。
  final int novel_id;

  /// 原生广告单元 ID（为空时不展示广告）。
  final String ad_unit_id;

  /// 广告配置的唯一标识。
  final String ad_uuid;

  const ReadContent({
    super.key,
    required this.logic,
    required this.is_dark,
    required this.detail,
    required this.reading_items,
    required this.on_reading_tap_down,
    this.reading_section_key,
    this.on_focus_changed,
    this.novel_id = 0,
    this.ad_unit_id = '',
    this.ad_uuid = '',
  });

  /// 使用小说 ID 和章节索引生成稳定的 10% 随机判断。
  ///
  /// 同一本小说的同一章节每次打开都会得到相同结果，
  /// 避免刷新页面时广告位置跳变。
  bool _should_show_ad_for_chapter(int chapter_index) {
    final int hash = (novel_id * 31 + chapter_index * 17) & 0x7FFFFFFF;
    return hash % 100 < 10;
  }

  @override
  Widget build(BuildContext context) {
    // 正文主文字颜色根据主题切换，夜间提高透明度避免刺眼。
    final Color reading_text_color = is_dark
        ? ContentStyle.reading_text_color_dark
        : ContentStyle.reading_text_color_light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 阅读列表包含第一章时展示头部介绍区；目录跳转到中间章节时隐藏（跳转场景）。
        if (logic.should_show_introduction) ...[
          ReadIntroductionSection(
            is_dark: is_dark,
            detail: detail,
            on_focus_changed: on_focus_changed,
          ),
          SizedBox(height: ContentStyle.reading_top_spacing),
        ],
        // 正文容器：作为"开始阅读"定位锚点，并承载全文段落。
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
              children: <Widget>[
                // 逐项渲染正文，每项都支持点击分区翻页交互。
                // 记录已分配 GlobalKey 的章节索引，避免重复 key 导致报错。
                ...() {
                  final Set<int> assigned_chapter_keys = {};
                  // 记录已插入广告的章节索引，避免重复插入。
                  final Set<int> ad_inserted_chapters = {};
                  final bool has_ad =
                      AdDisplayPolicy.can_show_ads() &&
                      ad_unit_id.isNotEmpty &&
                      ad_uuid.isNotEmpty;

                  final List<Widget> widgets = <Widget>[];
                  for (final ReadingContentItem item in reading_items) {
                    GlobalKey? item_key;
                    if (item.is_title &&
                        !assigned_chapter_keys.contains(item.chapter_index)) {
                      item_key = logic.get_chapter_key(item.chapter_index);
                      assigned_chapter_keys.add(item.chapter_index);
                    }

                    widgets.add(
                      Container(
                        key: item_key,
                        padding: EdgeInsets.only(
                          bottom: item.is_title
                              ? ContentStyle.reading_paragraph_bottom_spacing *
                                    1.5
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

                    // 章节标题后以 10% 概率插入原生广告（每章最多一次）。
                    if (has_ad &&
                        item.is_title &&
                        !ad_inserted_chapters.contains(item.chapter_index) &&
                        _should_show_ad_for_chapter(item.chapter_index)) {
                      ad_inserted_chapters.add(item.chapter_index);
                      widgets.add(
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: NativeAdBanner(
                            ad_unit_id: ad_unit_id,
                            uuid: ad_uuid,
                            badge_text_key: 'short_story_read.ad_free',
                          ),
                        ),
                      );
                    }
                  }
                  return widgets;
                }(),
              ],
            ),
          ),
        ),
      ],
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

  /// 构造函数，注入段落渲染与交互依赖。
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
