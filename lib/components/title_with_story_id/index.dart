import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';
import 'widgets/replace_cover_button.dart';
import 'widgets/story_id_badge.dart';

/// 标题 + 小说 ID 徽标组合组件。
///
/// 在标题文字后方内联展示可复制的小说 ID 徽标：
/// 1. 仅登录且 debug = 2 的用户可见徽标，普通用户体验与普通标题完全一致；
/// 2. 标题过长换行时徽标跟随文字流动（WidgetSpan 内联布局）；
/// 3. 点击徽标复制 ID 并弹出底部提示。
///
/// [title] 标题文字。
/// [story_id] 小说 ID。
/// [title_style] 标题文字样式，徽标颜色自动跟随其文字颜色。
/// [on_cover_replaced] 替换封面成功回调，携带新的封面信息；不传则不展示按钮。
/// [text_align] 标题对齐方式，默认左对齐。
/// [max_lines] 标题最大行数，不传则不限制。
/// [overflow] 标题溢出方式，配合 [max_lines] 使用。
class TitleWithStoryId extends StatelessWidget {
  /// 标题文字。
  final String title;

  /// 小说 ID。
  final int story_id;

  /// 标题文字样式。
  final TextStyle title_style;

  /// 替换封面成功回调，携带新的封面地址与宽高；不传则不展示替换封面按钮。
  final void Function(String cover_url, int cover_width, int cover_height)?
  on_cover_replaced;

  /// 标题对齐方式。
  final TextAlign text_align;

  /// 标题最大行数。
  final int? max_lines;

  /// 标题溢出方式。
  final TextOverflow? overflow;

  const TitleWithStoryId({
    super.key,
    required this.title,
    required this.story_id,
    required this.title_style,
    this.on_cover_replaced,
    this.text_align = TextAlign.start,
    this.max_lines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // Obx 监听登录态与用户资料变化，实时决定徽标显隐。
    return Obx(() {
      // 不满足展示条件时不渲染徽标，退化为普通标题文本。
      final bool show_badge = should_show_story_id_badge(story_id);

      return Text.rich(
        TextSpan(
          text: title,
          style: title_style,
          children: show_badge
              ? <InlineSpan>[
                  // 内联徽标，跟随标题文字换行流动。
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        StoryIdBadge(
                          story_id: story_id,
                          // 徽标基色跟随标题文字颜色，未指定时回退到主题前景色。
                          base_color:
                              title_style.color ??
                              Theme.of(context).colorScheme.onSurface,
                        ),
                        // 调试用户附加替换封面操作，方便运营侧快速重置封面。
                        if (on_cover_replaced != null)
                          ReplaceCoverButton(
                            story_id: story_id,
                            base_color:
                                title_style.color ??
                                Theme.of(context).colorScheme.onSurface,
                            on_cover_replaced: on_cover_replaced!,
                          ),
                      ],
                    ),
                  ),
                ]
              : const <InlineSpan>[],
        ),
        textAlign: text_align,
        maxLines: max_lines,
        overflow: overflow,
      );
    });
  }
}
