import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/read/logic.dart' as read_logic;
import 'package:app/pages/read/widgets/introduction_section/index.dart';
import 'package:app/stores/novel_reading_store.dart';
import './style.dart';

/// 阅读页正文内容组件。
///
/// 负责展示小说正文内容，包括标题、提示信息以及逐段渲染的正文文本。
/// 同时集成了点击分区翻页的交互逻辑。
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

  /// 正文区块是否已经进入阅读状态，用于决定是否允许点击翻页。
  final bool is_reading_section_at_top;

  /// 上翻一屏回调。
  final VoidCallback on_page_up;

  /// 下翻一屏回调。
  final VoidCallback on_page_down;

  /// 中间区域点击回调。
  final VoidCallback on_middle_tap;

  /// 是否显示导航栏（顶部和底部）。
  final bool show_navigation;

  /// 关注状态变更回调。
  final ValueChanged<bool>? on_focus_changed;

  const ReadContent({
    super.key,
    required this.logic,
    required this.is_dark,
    required this.detail,
    required this.reading_items,
    required this.is_reading_section_at_top,
    required this.on_page_up,
    required this.on_page_down,
    required this.on_middle_tap,
    required this.show_navigation,
    this.reading_section_key,
    this.on_focus_changed,
  });

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
          onTapDown: (TapDownDetails details) {
            if (!is_reading_section_at_top) return;

            if (show_navigation) {
              on_middle_tap();
              return;
            }

            final double screen_height = MediaQuery.sizeOf(context).height;
            final double bottom_reserved_height =
                MediaQuery.viewPaddingOf(context).bottom +
                ContentStyle.reading_mask_height;
            final double effective_height =
                (screen_height - bottom_reserved_height).clamp(
                  0.0,
                  screen_height,
                );
            final Offset screen_position = details.globalPosition;
            final double block_height =
                effective_height / ContentStyle.reading_tap_block_count;

            if (screen_position.dy <= block_height) {
              on_page_up();
            } else if (screen_position.dy >=
                block_height * ContentStyle.reading_tap_middle_block_factor) {
              on_page_down();
            } else {
              on_middle_tap();
            }
          },
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
                  return reading_items.map((ReadingContentItem item) {
                    GlobalKey? item_key;
                    if (item.is_title &&
                        !assigned_chapter_keys.contains(item.chapter_index)) {
                      item_key = logic.get_chapter_key(item.chapter_index);
                      assigned_chapter_keys.add(item.chapter_index);
                    }

                    return Container(
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
                        is_reading_section_at_top: is_reading_section_at_top,
                        on_page_up: on_page_up,
                        on_page_down: on_page_down,
                        on_middle_tap: on_middle_tap,
                        show_navigation: show_navigation,
                      ),
                    );
                  });
                }(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 阅读页单段正文组件，负责处理点击分区翻页逻辑。
class _ReaderParagraphItem extends StatelessWidget {
  /// 当前段落文本内容。
  final String text;

  /// 是否为章节标题。
  final bool is_title;

  /// 正文字号。
  final double body_font_size;

  /// 段落文字颜色。
  final Color text_color;

  /// 正文是否已经贴顶，未贴顶时禁用点击翻页逻辑。
  final bool is_reading_section_at_top;

  /// 上翻一屏回调。
  final VoidCallback on_page_up;

  /// 下翻一屏回调。
  final VoidCallback on_page_down;

  /// 中间区域点击回调。
  final VoidCallback on_middle_tap;

  /// 是否显示导航栏（顶部和底部）。
  final bool show_navigation;

  /// 构造函数，注入段落渲染与交互依赖。
  const _ReaderParagraphItem({
    required this.text,
    this.is_title = false,
    required this.body_font_size,
    required this.text_color,
    required this.is_reading_section_at_top,
    required this.on_page_up,
    required this.on_page_down,
    required this.on_middle_tap,
    required this.show_navigation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) {
        // 正文未贴顶时忽略点击，避免封面区域误触触发翻页。
        if (!is_reading_section_at_top) {
          return;
        }

        // 当出现上下导航栏时，如果点击小说内容区域，直接隐藏导航栏，不触发上一页/下一页。
        if (show_navigation) {
          on_middle_tap();
          return;
        }
        // 获取当前屏幕总高度，用于后续三段分区计算。
        final double screen_height = MediaQuery.sizeOf(context).height;
        // 底部保留区 = 安全区 + 阅读遮罩高度，点击分区要排除这部分。
        final double bottom_reserved_height =
            MediaQuery.viewPaddingOf(context).bottom +
            ContentStyle.reading_mask_height;
        // 实际可用于点击分区的高度，限制在 0 到屏幕高度之间。
        final double effective_height = (screen_height - bottom_reserved_height)
            .clamp(0.0, screen_height);
        // 读取本次点击在全局坐标中的位置。
        final Offset screen_position = details.globalPosition;
        // 将可点击区域等分成三段，上中下分别对应不同交互。
        final double block_height =
            effective_height / ContentStyle.reading_tap_block_count;

        // 点击上 1/3 区域时执行上翻。
        if (screen_position.dy <= block_height) {
          on_page_up();
          return;
        }

        // 点击中 1/3 区域预留给未来菜单能力，当前只打印日志。
        if (screen_position.dy > block_height &&
            screen_position.dy <
                (block_height * ContentStyle.reading_tap_middle_block_factor)) {
          on_middle_tap();
          return;
        }

        // 点击下 1/3 区域时执行下翻。
        if (screen_position.dy >=
            block_height * ContentStyle.reading_tap_middle_block_factor) {
          on_page_down();
        }
      },
      child: Text(
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
      ),
    );
  }
}
