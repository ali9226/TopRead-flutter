// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy show tr;
import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';

/// 简介区：默认收起 4 行 + 底部渐变遮罩 + 居中箭头，点击展开/收起。
///
/// 展开时箭头旋转为向上；收起时渐变微微遮住末行文字，箭头浮在渐变中。
class ComicDetailAboutSection extends StatefulWidget {
  /// 简介正文。
  final String description;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 当前界面是否为 CJK 语种。
  final bool is_cjk;

  const ComicDetailAboutSection({
    super.key,
    required this.description,
    required this.is_dark,
    required this.is_cjk,
  });

  @override
  State<ComicDetailAboutSection> createState() =>
      _ComicDetailAboutSectionState();
}

class _ComicDetailAboutSectionState extends State<ComicDetailAboutSection> {
  /// 是否已展开全文。
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final String text = widget.description.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    /// 内容卡片背景色，渐变终点与此一致，让遮罩自然融入卡片。
    final Color card_bg = widget.is_dark
        ? ComicDetailStyle.content_card_dark
        : ComicDetailStyle.content_card_light;

    final TextStyle body_style = TextStyle(
      color: ComicsStyle.muted(context),
      fontSize: ComicDetailStyle.pick_font_size(
        is_cjk: widget.is_cjk,
        cjk: ComicDetailStyle.description_font_size_cjk,
        alphabetic: ComicDetailStyle.description_font_size_alphabetic,
      ),
      height: ComicDetailStyle.pick_font_size(
        is_cjk: widget.is_cjk,
        cjk: ComicDetailStyle.description_height_cjk,
        alphabetic: ComicDetailStyle.description_height_alphabetic,
      ),
      fontWeight: ComicDetailStyle.weight_regular,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        /// 文本 + 渐变遮罩 + 居中箭头。
        Stack(
          children: <Widget>[
            /// 简介正文：收起 4 行 + 省略号。
            Text(
              text,
              maxLines: _expanded
                  ? null
                  : ComicDetailStyle.description_collapsed_lines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: body_style,
            ),

            /// 收起态：底部渐变微微遮住末行文字。
            if (!_expanded)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: ComicDetailStyle.description_fade_height,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          card_bg.withValues(alpha: 0.0),
                          card_bg.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            /// 居中箭头按钮：浮在渐变中间，点击展开/收起。
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: ComicDetailStyle.description_fade_height,
              child: Center(
                child: _build_toggle_button(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 展开/收起箭头按钮：点击区域 48px，箭头随状态旋转 180°。
  Widget _build_toggle_button() {
    return Semantics(
      button: true,
      label: _expanded
          ? easy.tr('comics.show_less')
          : easy.tr('comics.show_more'),
      child: Tooltip(
        message: _expanded
            ? easy.tr('comics.show_less')
            : easy.tr('comics.show_more'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _expanded = !_expanded),
          child: SizedBox.square(
            dimension: ComicsStyle.touch_target,
            child: Center(
              child: AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(
                  milliseconds: ComicDetailStyle.description_toggle_animation_ms,
                ),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: ComicDetailStyle.description_toggle_icon_size,
                  color: ColorConstants.themeColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
