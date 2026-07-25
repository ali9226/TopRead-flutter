import 'dart:async';
import 'package:app/config/font_config.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/components/novel_cover/index.dart';

import 'package:app/models/short_story_item.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';
import 'package:app/util/language_util/index.dart';

/// 短篇小说卡片组件。
///
/// 展示单条短篇小说信息，包含：
/// - 标题（最多两行）
/// - 简介（最多三行）
/// - 底部标签列表 + 点赞数
///
/// 点击有主题色波纹从点击位置扩散效果，支持日间/夜间模式。
/// 长按触发不喜欢理由底部弹窗，长按过程中仅内容整体缩小5%，卡片背景不变。
class ShortStoryCard extends StatefulWidget {
  /// 小说数据。
  final ShortStoryItem story_item;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点赞请求是否正在进行中。
  final bool is_like_loading;

  /// 点击回调。
  final VoidCallback? on_tap;

  /// 长按回调。
  final VoidCallback? on_long_press;

  /// 点赞图标点击回调。
  final VoidCallback? on_like_tap;

  /// 长按触发时长（毫秒），默认1500ms。
  final int long_press_duration_ms;

  const ShortStoryCard({
    super.key,
    required this.story_item,
    required this.is_dark,
    this.is_like_loading = false,
    this.on_tap,
    this.on_long_press,
    this.on_like_tap,
    this.long_press_duration_ms = ShortStoryTabStyle.long_press_duration_ms,
  });

  @override
  State<ShortStoryCard> createState() => _ShortStoryCardState();
}

class _ShortStoryCardState extends State<ShortStoryCard>
    with TickerProviderStateMixin {
  /// 缩放动画控制器（长按卡片缩小）。
  late AnimationController _scale_animation_controller;

  /// 缩放动画：1.0 → 0.95。
  late Animation<double> _scale_animation;

  /// 点赞弹跳动画控制器。
  late AnimationController _like_animation_controller;

  /// 点赞弹跳动画：1.0 → 1.3 → 1.0。
  late Animation<double> _like_scale_animation;

  /// 上次点赞点击时间戳（微秒），用于防抖。
  int _last_like_tap_us = 0;

  /// 长按计时器：到达指定时长后触发回调。
  Timer? _long_press_timer;

  /// 手指是否仍在按下状态。
  bool _is_pointer_down = false;

  /// 标记长按已触发（防止重复触发）。
  bool _long_press_fired = false;

  /// 标记手指是否按在点赞区域，用于阻止卡片缩放动画。
  bool _is_like_area_down = false;

  /// 手指按下时的初始位置，用于判断是否滑动。
  Offset _pointer_start_position = Offset.zero;

  /// 手指移动超过此距离（像素）则取消长按。
  static const double _move_cancel_threshold = 10.0;

  @override
  void initState() {
    super.initState();
    _scale_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: ShortStoryTabStyle.long_press_scale_duration_ms),
    );

    _scale_animation = Tween<double>(
      begin: 1.0,
      end: ShortStoryTabStyle.long_press_scale,
    ).animate(CurvedAnimation(
      parent: _scale_animation_controller,
      curve: Curves.easeOutCubic,
    ));

    /// 点赞弹跳动画：1.0 → 1.3 → 1.0。
    _like_animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: ShortStoryTabStyle.like_bounce_duration_ms),
    );

    _like_scale_animation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
                begin: 1.0, end: ShortStoryTabStyle.like_bounce_scale)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
                begin: ShortStoryTabStyle.like_bounce_scale, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_like_animation_controller);
  }

  @override
  void dispose() {
    _long_press_timer?.cancel();
    _scale_animation_controller.dispose();
    _like_animation_controller.dispose();
    super.dispose();
  }

  /// 手指按下：启动缩放动画和长按计时器。
  void _on_pointer_down(PointerDownEvent event) {
    setState(() {
      _is_pointer_down = true;
    });
    _long_press_fired = false;
    _pointer_start_position = event.position;

    /// 点赞区域内按下时跳过卡片缩放和长按计时。
    if (_is_like_area_down) return;

    _scale_animation_controller.forward();
    _long_press_timer = Timer(
      Duration(milliseconds: widget.long_press_duration_ms),
      _on_long_press_triggered,
    );
  }

  /// 手指移动：超过阈值时取消长按（列表滚动场景）。
  void _on_pointer_move(PointerMoveEvent event) {
    if (_is_like_area_down) return;
    if (_is_pointer_down && !_long_press_fired) {
      final double distance =
          (event.position - _pointer_start_position).distance;
      if (distance > _move_cancel_threshold) {
        _cancel_long_press();
      }
    }
  }

  /// 手指抬起：取消计时器，恢复缩放。
  void _on_pointer_up(PointerUpEvent event) {
    if (_is_like_area_down) return;
    setState(() {
      _is_pointer_down = false;
    });
    _long_press_timer?.cancel();
    _scale_animation_controller.reverse();
  }

  /// 手指移出：取消计时器，恢复缩放。
  void _on_pointer_cancel(PointerCancelEvent event) {
    if (_is_like_area_down) return;
    setState(() {
      _is_pointer_down = false;
    });
    _long_press_timer?.cancel();
    _scale_animation_controller.reverse();
  }

  /// 取消长按：停止计时器，恢复缩放动画。
  void _cancel_long_press() {
    _long_press_timer?.cancel();
    if (_scale_animation_controller.isAnimating ||
        _scale_animation_controller.value > 0) {
      _scale_animation_controller.reverse();
    }
  }

  /// 长按到达指定时长时触发：显示弹窗并保持缩小状态。
  void _on_long_press_triggered() {
    if (_is_pointer_down && !_long_press_fired) {
      _long_press_fired = true;
      /// 保持缩小状态，同时触发回调显示弹窗。
      widget.on_long_press?.call();
    }
  }

  /// 点赞点击处理：防抖 + 播放弹跳动画 + 触发回调。
  void _on_like_tap() {
    /// 正在请求中，跳过。
    if (widget.is_like_loading) return;

    final int now_us = DateTime.now().microsecondsSinceEpoch;
    if (now_us - _last_like_tap_us <
        ShortStoryTabStyle.like_debounce_ms * 1000) {
      return;
    }
    _last_like_tap_us = now_us;

    /// 播放弹跳动画（重置后从头播放，支持连续点击时重新触发）。
    _like_animation_controller.forward(from: 0.0);
    widget.on_like_tap?.call();
  }

  /// 是否有封面图片。
  bool get _has_cover => widget.story_item.cover_url.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    /// 语种适配。
    final bool is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final double title_font_size = is_cjk
        ? ShortStoryTabStyle.card_title_font_size_cjk
        : ShortStoryTabStyle.card_title_font_size_alphabetic;
    final double desc_font_size = is_cjk
        ? ShortStoryTabStyle.card_description_font_size_cjk
        : ShortStoryTabStyle.card_description_font_size_alphabetic;
    final double title_height = is_cjk
        ? ShortStoryTabStyle.card_title_height_cjk
        : ShortStoryTabStyle.card_title_height_alphabetic;
    final double desc_height = is_cjk
        ? ShortStoryTabStyle.card_desc_height_cjk
        : ShortStoryTabStyle.card_desc_height_alphabetic;
    final double title_desc_gap = is_cjk
        ? ShortStoryTabStyle.card_title_desc_gap_cjk
        : ShortStoryTabStyle.card_title_desc_gap_alphabetic;
    final double card_vertical_padding = is_cjk
        ? ShortStoryTabStyle.card_vertical_padding_cjk
        : ShortStoryTabStyle.card_vertical_padding_alphabetic;
    final double desc_bottom_gap = is_cjk
        ? ShortStoryTabStyle.card_desc_bottom_gap_cjk
        : ShortStoryTabStyle.card_desc_bottom_gap_alphabetic;
    final double tag_font_size = is_cjk
        ? ShortStoryTabStyle.card_tag_font_size_cjk
        : ShortStoryTabStyle.card_tag_font_size_alphabetic;
    final double tag_horizontal_padding = is_cjk
        ? ShortStoryTabStyle.card_tag_horizontal_padding_cjk
        : ShortStoryTabStyle.card_tag_horizontal_padding_alphabetic;

    /// 卡片背景色。
    final Color card_bg = widget.is_dark
        ? ShortStoryTabStyle.card_dark_bg
        : ShortStoryTabStyle.card_light_bg;

    /// 标题文字色。
    final Color title_color = widget.is_dark
        ? ShortStoryTabStyle.card_title_dark_text
        : ShortStoryTabStyle.card_title_light_text;

    /// 简介文字色。
    final Color desc_color = widget.is_dark
        ? ShortStoryTabStyle.card_desc_dark_text
        : ShortStoryTabStyle.card_desc_light_text;

    /// 波纹颜色（主题色浅色系）。
    final Color ripple_color =
        ColorConstants.themeColor.withValues(alpha: 0.12);

    /// 高亮颜色（主题色更浅）。
    final Color highlight_color =
        ColorConstants.themeColor.withValues(alpha: 0.06);

    /// 点赞图标和文字颜色（已点赞用 dangerColor，未点赞用默认色）。
    final Color like_icon_color = widget.story_item.is_liked
        ? ColorConstants.dangerColor
        : (widget.is_dark
            ? ShortStoryTabStyle.card_like_dark_text
            : ShortStoryTabStyle.card_like_light_text);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShortStoryTabStyle.list_horizontal_padding,
      ),
      child: Listener(
        onPointerDown: _on_pointer_down,
        onPointerMove: _on_pointer_move,
        onPointerUp: _on_pointer_up,
        onPointerCancel: _on_pointer_cancel,
        child: Material(
          color: card_bg,
          borderRadius:
              BorderRadius.circular(ShortStoryTabStyle.card_border_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.on_tap,
            splashFactory: InkRipple.splashFactory,
            splashColor: ripple_color,
            highlightColor: highlight_color,
            radius: 240,
            child: AnimatedBuilder(
              animation: _scale_animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: _scale_animation.value,
                  child: child,
                );
              },
              child: Padding(
                padding: EdgeInsets.all(card_vertical_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// 标题（最多两行）。
                    Text(
                      widget.story_item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: title_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: title_color,
                        height: title_height,
                        letterSpacing: is_cjk ? null : ShortStoryTabStyle.card_title_letter_spacing_alphabetic,
                      ),
                    ),

                    /// 标题与简介间距。
                    SizedBox(height: title_desc_gap),

                    /// 简介行：有封面时左侧简介右侧封面，无封面时纯简介。
                    if (widget.story_item.description.isNotEmpty)
                      _build_description_row(
                        desc_font_size: desc_font_size,
                        desc_height: desc_height,
                        desc_color: desc_color,
                        is_cjk: is_cjk,
                      ),

                    /// 简介与底部标签栏间距。
                    SizedBox(height: desc_bottom_gap),

                    /// 底部：标签列表 + 点赞数。
                    Row(
                      children: <Widget>[
                        /// 标签列表（使用 tagColorList 颜色）。
                        Expanded(
                          child: Wrap(
                            spacing: ShortStoryTabStyle.card_tag_spacing,
                            runSpacing: ShortStoryTabStyle.card_tag_spacing,
                            children: List<Widget>.generate(
                              widget.story_item.tags.length,
                              (int index) {
                                /// 从 tagColorList 随机取色，作为标签背景色。
                                final Color tag_color =
                                    ColorConstants.tagColorList[
                                        (widget.story_item.id * 7 +
                                                index * 3) %
                                            ColorConstants
                                                .tagColorList.length];
                                /// 背景色使用浅色系。
                                final Color tag_bg =
                                    tag_color.withValues(alpha: 0.12);
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: tag_horizontal_padding,
                                      vertical: ShortStoryTabStyle
                                          .card_tag_vertical_padding),
                                  decoration: BoxDecoration(
                                    color: tag_bg,
                                    borderRadius: BorderRadius.circular(
                                        ShortStoryTabStyle
                                            .card_tag_border_radius),
                                  ),
                                  child: Text(
                                    widget.story_item.tags[index],
                                    style: TextStyle(
                                      fontSize: tag_font_size,
                                      color: tag_color,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        /// 点赞图标 + 数字。
                        /// 外层 Listener 拦截指针事件，阻止冒泡到卡片层触发缩放。
                        Listener(
                          onPointerDown: (_) {
                            _is_like_area_down = true;
                          },
                          onPointerUp: (_) {
                            _is_like_area_down = false;
                          },
                          onPointerCancel: (_) {
                            _is_like_area_down = false;
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _on_like_tap,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  AnimatedBuilder(
                                    animation: _like_scale_animation,
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return Transform.scale(
                                        scale: _like_scale_animation.value,
                                        child: child,
                                      );
                                    },
                                    child: widget.is_like_loading
                                        ? SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: like_icon_color,
                                            ),
                                          )
                                        : SvgIcon(
                                            name: widget.story_item.is_liked
                                                ? 'love_02'
                                                : 'love',
                                            width: ShortStoryTabStyle
                                                .card_like_icon_size,
                                            height: ShortStoryTabStyle
                                                .card_like_icon_size,
                                            color: like_icon_color,
                                          ),
                                  ),
                                  const SizedBox(
                                      width: ShortStoryTabStyle.card_like_gap),
                                  Text(
                                    _format_like_count(
                                        widget.story_item.like_count),
                                    style: TextStyle(
                                      fontSize: ShortStoryTabStyle
                                          .card_like_font_size,
                                      color: like_icon_color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 格式化点赞数显示。
  String _format_like_count(int count) {
    if (count >= 10000) {
      return 'number_unit.ten_thousand'
          .tr(namedArgs: {'count': (count / 10000).toStringAsFixed(1)});
    }
    if (count >= 1000) {
      return 'number_unit.thousand'
          .tr(namedArgs: {'count': (count / 1000).toStringAsFixed(1)});
    }
    return count.toString();
  }

  /// 构建简介行（有封面时左侧简介右侧封面，无封面时纯简介）。
  Widget _build_description_row({
    required double desc_font_size,
    required double desc_height,
    required Color desc_color,
    required bool is_cjk,
  }) {
    /// 简介最大行数。
    const int desc_max_lines = 3;

    final TextStyle desc_style = TextStyle(
      fontSize: desc_font_size,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      color: desc_color,
      height: desc_height,
      letterSpacing: is_cjk ? null : ShortStoryTabStyle.card_desc_letter_spacing_alphabetic,
    );

    /// 无封面时：纯简介文字。
    if (!_has_cover) {
      return Text(
        widget.story_item.description,
        maxLines: desc_max_lines,
        overflow: TextOverflow.ellipsis,
        style: desc_style,
      );
    }

    /// 有封面时：左侧简介，右侧封面。
    /// 封面高度 = 简介字号 * 行高 * 3行。
    final double cover_height = desc_font_size * desc_height * desc_max_lines;
    /// 封面宽度 = 高度 * (100/75)（100:75 横向比例）。
    final double cover_width = cover_height * (100 / 75);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 左侧简介文字（占据剩余空间）。
        Expanded(
          child: Text(
            widget.story_item.description,
            maxLines: desc_max_lines,
            overflow: TextOverflow.ellipsis,
            style: desc_style,
          ),
        ),

        /// 间距。
        const SizedBox(width: 10),

        /// 右侧封面图片。
        ClipRRect(
          borderRadius: BorderRadius.circular(SelectionChipStyle.borderRadius),
          child: NovelCover(
            image_url: widget.story_item.cover_url,
            description: widget.story_item.description,
            width: cover_width,
            height: cover_height,
            border_radius: SelectionChipStyle.borderRadius,
            is_dark: widget.is_dark,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
