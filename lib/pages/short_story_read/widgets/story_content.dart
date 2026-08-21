import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

import 'package:app/pages/short_story_read/style.dart';
import 'package:app/util/language_util/index.dart';

/// 正文内容组件。
///
/// 展示小说的正文内容，按段落（换行符 `\n`）拆分渲染。
/// 空段落会被自动过滤。
///
/// 支持：
/// - CJK / 非 CJK 语系的字号和行高适配。
/// - 加载中状态展示骨架屏占位。
/// - 在指定位置插入原生广告（可选）。
class StoryContent extends StatelessWidget {
  /// 正文内容字符串（以 `\n` 分隔段落）。
  final String content;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 是否正在加载中（为 true 时展示骨架屏）。
  final bool is_loading;

  /// 正文字号大小（由阅读设置调节）。
  final double font_size;

  /// 原生广告横幅组件（可选）。
  ///
  /// 非空时在正文 [ShortStoryReadStyle.native_ad_display_ratio] 位置插入。
  final Widget? native_ad_widget;

  const StoryContent({
    super.key,
    required this.content,
    required this.is_dark,
    this.is_loading = false,
    this.font_size = 17.0,
    this.native_ad_widget,
  });

  @override
  Widget build(BuildContext context) {
    /// 正文文字颜色。
    final Color body_color = is_dark
        ? ShortStoryReadStyle.body_dark_color
        : ShortStoryReadStyle.body_light_color;

    /// 当前语种是否为 CJK。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );

    /// 正文字号（使用外部传入的动态字号）。
    final double body_font_size = font_size;

    /// 正文行高（CJK 语系 1.8，非 CJK 语系 1.7）。
    final double body_height = is_cjk
        ? ShortStoryReadStyle.body_height_cjk
        : ShortStoryReadStyle.body_height_alphabetic;

    // 加载中状态：展示骨架屏。
    if (is_loading) {
      return _buildLoadingSkeleton(is_dark: is_dark);
    }

    // 内容为空：不渲染任何内容。
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按换行符拆分段落，过滤空行后逐段渲染。
    final List<String> paragraphs = content
        .split('\n')
        .where((String p) => p.trim().isNotEmpty)
        .toList();

    // 计算原生广告插入位置（正文 1/3 处的段落下标）。
    final int? ad_insert_index = _get_ad_insert_index(
      paragraph_count: paragraphs.length,
      has_native_ad: native_ad_widget != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _build_paragraph_widgets(
        paragraphs: paragraphs,
        body_font_size: body_font_size,
        body_color: body_color,
        body_height: body_height,
        ad_insert_index: ad_insert_index,
      ),
    );
  }

  /// 构建加载中骨架屏。
  ///
  /// 模拟 12 行正文段落的占位效果，每 4 行中第 1 行使用较短宽度。
  Widget _buildLoadingSkeleton({required bool is_dark}) {
    /// 骨架屏底色。
    final Color base_color = is_dark
        ? ShortStoryReadStyle.skeleton_dark_base
        : ShortStoryReadStyle.skeleton_light_base;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(12, (int index) {
        /// 每 4 行中第 1 行使用较短宽度，模拟段落末行效果。
        final double width = index % 4 == 0 ? 160 : double.infinity;
        return Padding(
          padding: const EdgeInsets.only(
            bottom: ShortStoryReadStyle.paragraph_spacing,
          ),
          child: Container(
            width: width,
            height: 16,
            decoration: BoxDecoration(
              color: base_color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  /// 计算原生广告在段落列表中的插入位置。
  ///
  /// 返回需要在该下标之前插入广告的段落下标。
  /// 段落数不足 4 段时不在正文中插入广告（过短的内容不适合嵌入广告）。
  /// 返回 null 表示不插入广告。
  int? _get_ad_insert_index({
    required int paragraph_count,
    required bool has_native_ad,
  }) {
    if (!has_native_ad || paragraph_count < 4) return null;
    // 在正文 1/3 处的段落之后插入广告。
    return (paragraph_count * ShortStoryReadStyle.native_ad_display_ratio)
        .ceil()
        .clamp(1, paragraph_count);
  }

  /// 构建段落列表，可在指定位置插入原生广告。
  List<Widget> _build_paragraph_widgets({
    required List<String> paragraphs,
    required double body_font_size,
    required Color body_color,
    required double body_height,
    required int? ad_insert_index,
  }) {
    final List<Widget> children = <Widget>[];

    for (int index = 0; index < paragraphs.length; index++) {
      // 在指定位置之前插入原生广告。
      if (ad_insert_index != null && index == ad_insert_index) {
        children.add(native_ad_widget!);
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(
            bottom: ShortStoryReadStyle.paragraph_spacing,
          ),
          child: Text(
            paragraphs[index],
            style: TextStyle(
              fontSize: body_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: body_color,
              height: body_height,
            ),
          ),
        ),
      );
    }

    // 广告位置在最后一个段落之后时，追加到末尾。
    if (ad_insert_index != null && ad_insert_index >= paragraphs.length) {
      children.add(native_ad_widget!);
    }

    return children;
  }
}
