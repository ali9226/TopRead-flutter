import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/config/font_config.dart';

import 'package:app/common_style/selection_chip/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/components/novel_cover/index.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/pages/home/widgets/tab_contents/short_story_tab/style.dart';
import 'package:app/util/number_format_util.dart';
import 'package:app/util/language_util/index.dart';

/// 目录列表卡片组件。
///
/// 以卡片形式展示单条短篇小说信息，包含：
/// - 标题（最多 2 行，当前小说使用主题色）
/// - 简介（最多 2 行，次要文字颜色）
/// - 底部：标签列表 + 点赞数
/// - 当前阅读中的小说显示主题色左边框和"阅读中"标记
///
/// 视觉特征：
/// - 圆角卡片（12px）+ 轻阴影
/// - 卡片之间有间距
/// - 点击时有波纹效果
/// - 长按时有缩放效果（与首页卡片一致）
class CatalogItem extends StatefulWidget {
  /// 短篇小说数据。
  final ShortStoryItem item;

  /// 是否为当前阅读中的小说。
  final bool is_current;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback on_tap;

  /// 点赞按钮点击回调（可选，不传则点赞区域不可点击）。
  final VoidCallback? on_like_tap;

  /// 是否正在点赞请求中（为 true 时显示加载指示器）。
  final bool is_like_loading;

  /// 当前阅读进度（0.0 ~ 1.0），仅当前小说有效。
  final double reading_progress;

  const CatalogItem({
    super.key,
    required this.item,
    required this.is_current,
    required this.is_dark,
    required this.on_tap,
    this.on_like_tap,
    this.is_like_loading = false,
    this.reading_progress = 0.0,
  });

  @override
  State<CatalogItem> createState() => _CatalogItemState();
}

class _CatalogItemState extends State<CatalogItem>
    with SingleTickerProviderStateMixin {
  /// 缩放动画控制器。
  late AnimationController _scale_controller;

  /// 缩放动画：1.0 → 0.95。
  late Animation<double> _scale_animation;

  @override
  void initState() {
    super.initState();
    _scale_controller = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: ShortStoryTabStyle.long_press_scale_duration_ms),
    );

    _scale_animation = Tween<double>(
      begin: 1.0,
      end: ShortStoryTabStyle.long_press_scale,
    ).animate(CurvedAnimation(
      parent: _scale_controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _scale_controller.dispose();
    super.dispose();
  }

  /// 手指按下：启动缩放动画。
  void _on_pointer_down(PointerDownEvent event) {
    _scale_controller.forward();
  }

  /// 手指抬起：恢复缩放。
  void _on_pointer_up(PointerUpEvent event) {
    _scale_controller.reverse();
  }

  /// 手指取消：恢复缩放。
  void _on_pointer_cancel(PointerCancelEvent event) {
    _scale_controller.reverse();
  }

  /// 是否有封面图片。
  bool get _has_cover => widget.item.cover_url.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    /// 标题文字颜色（当前小说日间和夜间都用红色）。
    final Color title_color = widget.is_current
        ? ColorConstants.dangerColor
        : (widget.is_dark
            ? ShortStoryTabStyle.card_title_dark_text
            : ShortStoryTabStyle.card_title_light_text);

    /// 当前阅读中卡片的高亮色（日间和夜间都用红色）。
    final Color current_highlight_color = ColorConstants.dangerColor;

    /// 简介文字颜色（与首页卡片一致）。
    final Color desc_color = widget.is_dark
        ? ShortStoryTabStyle.card_desc_dark_text
        : ShortStoryTabStyle.card_desc_light_text;

    /// 点赞图标颜色（已点赞使用红色，未点赞使用首页卡片颜色）。
    final Color like_color = widget.item.is_liked
        ? ColorConstants.dangerColor
        : (widget.is_dark
            ? ShortStoryTabStyle.card_like_dark_text
            : ShortStoryTabStyle.card_like_light_text);

    /// 卡片背景色（与首页卡片一致）。
    final Color card_bg = widget.is_dark
        ? ShortStoryTabStyle.card_dark_bg
        : ShortStoryTabStyle.card_light_bg;

    /// 当前语种是否为 CJK。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );

    /// 标题字号（与首页卡片一致）。
    final double title_font_size = is_cjk
        ? ShortStoryTabStyle.card_title_font_size_cjk
        : ShortStoryTabStyle.card_title_font_size_alphabetic;

    /// 简介字号（与首页卡片一致）。
    final double desc_font_size = is_cjk
        ? ShortStoryTabStyle.card_description_font_size_cjk
        : ShortStoryTabStyle.card_description_font_size_alphabetic;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutConfig.page_horizontal_padding,
        vertical: 4,
      ),
      child: Listener(
        onPointerDown: _on_pointer_down,
        onPointerUp: _on_pointer_up,
        onPointerCancel: _on_pointer_cancel,
        child: Material(
          color: card_bg,
          borderRadius: BorderRadius.circular(ShortStoryTabStyle.card_border_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.on_tap,
            splashColor: ColorConstants.themeColor.withValues(alpha: 0.12),
            highlightColor: ColorConstants.themeColor.withValues(alpha: 0.06),
            child: AnimatedBuilder(
              animation: _scale_animation,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: _scale_animation.value,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ShortStoryTabStyle.card_border_radius),
                  border: widget.is_current
                      ? Border.all(
                          color: current_highlight_color.withValues(alpha: 0.3),
                          width: 1.5,
                        )
                      : null,
                ),
                child: _has_cover
                    ? _buildCardWithCover(
                        title_color: title_color,
                        current_highlight_color: current_highlight_color,
                        desc_color: desc_color,
                        like_color: like_color,
                        title_font_size: title_font_size,
                        desc_font_size: desc_font_size,
                        is_cjk: is_cjk,
                      )
                    : _buildCardWithoutCover(
                        title_color: title_color,
                        current_highlight_color: current_highlight_color,
                        desc_color: desc_color,
                        like_color: like_color,
                        title_font_size: title_font_size,
                        desc_font_size: desc_font_size,
                        is_cjk: is_cjk,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建有封面的卡片布局（封面在简介右侧）。
  Widget _buildCardWithCover({
    required Color title_color,
    required Color current_highlight_color,
    required Color desc_color,
    required Color like_color,
    required double title_font_size,
    required double desc_font_size,
    required bool is_cjk,
  }) {
    /// 简介行高。
    final double desc_height = is_cjk
        ? ShortStoryTabStyle.card_desc_height_cjk
        : ShortStoryTabStyle.card_desc_height_alphabetic;

    /// 简介最大行数。
    const int desc_max_lines = 2;

    /// 封面高度 = 简介字号 * 行高 * 行数，与2行简介文字等高。
    final double cover_height = desc_font_size * desc_height * desc_max_lines;

    /// 封面宽度 = 高度 * (100/75)（100:75 横向比例）。
    final double cover_width = cover_height * (100 / 75);

    return Padding(
      padding: EdgeInsets.all(is_cjk
          ? ShortStoryTabStyle.card_vertical_padding_cjk
          : ShortStoryTabStyle.card_vertical_padding_alphabetic),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// 标题行（标题 + 当前阅读标记）。
          _buildTitleRow(
            title_color: title_color,
            current_highlight_color: current_highlight_color,
            title_font_size: title_font_size,
            is_cjk: is_cjk,
          ),

          /// 标题与简介间距。
          SizedBox(height: is_cjk
              ? ShortStoryTabStyle.card_title_desc_gap_cjk
              : ShortStoryTabStyle.card_title_desc_gap_alphabetic),

          /// 简介行：左侧简介文字，右侧封面图片。
          if (widget.item.description.isNotEmpty)
            _buildDescriptionWithCover(
              desc_color: desc_color,
              desc_font_size: desc_font_size,
              desc_height: desc_height,
              desc_max_lines: desc_max_lines,
              cover_width: cover_width,
              cover_height: cover_height,
              is_cjk: is_cjk,
            ),

          /// 简介与底部标签栏间距。
          SizedBox(height: is_cjk
              ? ShortStoryTabStyle.card_desc_bottom_gap_cjk
              : ShortStoryTabStyle.card_desc_bottom_gap_alphabetic),

          /// 底部：标签列表 + 点赞数。
          _buildBottomRow(
            like_color: like_color,
            is_cjk: is_cjk,
          ),
        ],
      ),
    );
  }

  /// 构建简介行（左侧简介文字，右侧封面图片）。
  Widget _buildDescriptionWithCover({
    required Color desc_color,
    required double desc_font_size,
    required double desc_height,
    required int desc_max_lines,
    required double cover_width,
    required double cover_height,
    required bool is_cjk,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 左侧简介文字（占据剩余空间）。
        Expanded(
          child: Text(
            widget.item.description,
            maxLines: desc_max_lines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: desc_font_size,
              color: desc_color,
              height: desc_height,
            ),
          ),
        ),

        /// 间距。
        const SizedBox(width: 10),

        /// 右侧封面图片。
        ClipRRect(
          borderRadius: BorderRadius.circular(SelectionChipStyle.borderRadius),
          child: NovelCover(
            image_url: widget.item.cover_url,
            description: widget.item.description,
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

  /// 构建无封面的卡片布局（纯文字）。
  Widget _buildCardWithoutCover({
    required Color title_color,
    required Color current_highlight_color,
    required Color desc_color,
    required Color like_color,
    required double title_font_size,
    required double desc_font_size,
    required bool is_cjk,
  }) {
    return Padding(
      padding: EdgeInsets.all(is_cjk
          ? ShortStoryTabStyle.card_vertical_padding_cjk
          : ShortStoryTabStyle.card_vertical_padding_alphabetic),
      child: _buildTextContent(
        title_color: title_color,
        current_highlight_color: current_highlight_color,
        desc_color: desc_color,
        like_color: like_color,
        title_font_size: title_font_size,
        desc_font_size: desc_font_size,
        is_cjk: is_cjk,
      ),
    );
  }

  /// 构建文字内容区域（标题 + 简介 + 底部标签）。
  Widget _buildTextContent({
    required Color title_color,
    required Color current_highlight_color,
    required Color desc_color,
    required Color like_color,
    required double title_font_size,
    required double desc_font_size,
    required bool is_cjk,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        /// 标题行（标题 + 当前阅读标记）。
        _buildTitleRow(
          title_color: title_color,
          current_highlight_color: current_highlight_color,
          title_font_size: title_font_size,
          is_cjk: is_cjk,
        ),

        /// 简介（最多 2 行）。
        if (widget.item.description.isNotEmpty) ...[
          SizedBox(height: is_cjk
              ? ShortStoryTabStyle.card_title_desc_gap_cjk
              : ShortStoryTabStyle.card_title_desc_gap_alphabetic),
          Text(
            widget.item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: desc_font_size,
              color: desc_color,
              height: is_cjk
                  ? ShortStoryTabStyle.card_desc_height_cjk
                  : ShortStoryTabStyle.card_desc_height_alphabetic,
            ),
          ),
        ],

        SizedBox(height: is_cjk
            ? ShortStoryTabStyle.card_desc_bottom_gap_cjk
            : ShortStoryTabStyle.card_desc_bottom_gap_alphabetic),

        /// 底部：标签列表 + 点赞数。
        _buildBottomRow(
          like_color: like_color,
          is_cjk: is_cjk,
        ),
      ],
    );
  }

  /// 构建底部行（标签 + 点赞数）。
  ///
  /// 参数：
  /// - [like_color] 点赞图标和文字颜色。
  /// - [is_cjk] 当前语种是否为 CJK。
  Widget _buildBottomRow({
    required Color like_color,
    required bool is_cjk,
  }) {
    /// 标签字号（与首页卡片一致）。
    final double tag_font_size = is_cjk
        ? ShortStoryTabStyle.card_tag_font_size_cjk
        : ShortStoryTabStyle.card_tag_font_size_alphabetic;

    /// 标签水平内边距（与首页卡片一致）。
    final double tag_horizontal_padding = is_cjk
        ? ShortStoryTabStyle.card_tag_horizontal_padding_cjk
        : ShortStoryTabStyle.card_tag_horizontal_padding_alphabetic;

    return Row(
      children: <Widget>[
        /// 标签列表（与首页卡片一致）。
        Expanded(
          child: Wrap(
            spacing: ShortStoryTabStyle.card_tag_spacing,
            runSpacing: ShortStoryTabStyle.card_tag_spacing,
            children: List<Widget>.generate(
              widget.item.tags.take(3).length,
              (int index) {
                /// 标签颜色（使用 tagColorList，通过 id 和 index 生成固定索引）。
                final Color tag_color = ColorConstants.tagColorList[
                    (widget.item.id * 7 + index * 3) %
                        ColorConstants.tagColorList.length];

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tag_horizontal_padding,
                    vertical: ShortStoryTabStyle.card_tag_vertical_padding,
                  ),
                  decoration: BoxDecoration(
                    color: tag_color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                        ShortStoryTabStyle.card_tag_border_radius),
                  ),
                  child: Text(
                    widget.item.tags[index],
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

        const SizedBox(width: 8),

        /// 点赞数（图标 + 数字，与首页卡片一致）。
        GestureDetector(
          onTap: widget.is_like_loading ? null : widget.on_like_tap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.is_like_loading)
                  SizedBox(
                    width: ShortStoryTabStyle.card_like_icon_size,
                    height: ShortStoryTabStyle.card_like_icon_size,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(like_color),
                    ),
                  )
                else
                  SvgPicture.asset(
                    widget.item.is_liked
                        ? 'assets/svg/love_02.svg'
                        : 'assets/svg/love.svg',
                    width: ShortStoryTabStyle.card_like_icon_size,
                    height: ShortStoryTabStyle.card_like_icon_size,
                    colorFilter: ColorFilter.mode(like_color, BlendMode.srcIn),
                  ),
                SizedBox(width: ShortStoryTabStyle.card_like_gap),
                Text(
                  NumberFormatUtil.format_count(widget.item.like_count),
                  style: TextStyle(
                    fontSize: ShortStoryTabStyle.card_like_font_size,
                    color: like_color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建标题行（标题 + 当前阅读标记）。
  Widget _buildTitleRow({
    required Color title_color,
    required Color current_highlight_color,
    required double title_font_size,
    required bool is_cjk,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            widget.item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: title_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: title_color,
              height: is_cjk
                  ? ShortStoryTabStyle.card_title_height_cjk
                  : ShortStoryTabStyle.card_title_height_alphabetic,
            ),
          ),
        ),

        /// 当前阅读标记。
        if (widget.is_current)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: current_highlight_color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${tr('short_story_read.reading')} ${(widget.reading_progress * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                color: current_highlight_color,
              ),
            ),
          ),
      ],
    );
  }
}
