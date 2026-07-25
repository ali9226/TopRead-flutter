import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import './style.dart';
import 'package:app/config/font_config.dart';

/// 阅读页简介摘要组件。
///
/// 展示小说的内容简介摘要。
/// 支持点击“更多”展开完整简介，并带有平滑过渡动画。
class ReadIntroSummarySection extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 简介文案。
  final String intro_text;

  /// 是否初始展开。
  final bool initial_expanded;

  const ReadIntroSummarySection({
    super.key,
    required this.is_dark,
    required this.intro_text,
    this.initial_expanded = false,
  });

  @override
  State<ReadIntroSummarySection> createState() =>
      _ReadIntroSummarySectionState();
}

class _ReadIntroSummarySectionState extends State<ReadIntroSummarySection> {
  /// 是否已展开完整简介。
  late bool _is_expanded;

  @override
  void initState() {
    super.initState();
    _is_expanded = widget.initial_expanded;
  }

  @override
  Widget build(BuildContext context) {
    // 简介正文使用次要文字色，保持信息层级低于标题与核心数据。
    final Color secondary_text_color = widget.is_dark
        ? IntroSummaryStyle.intro_text_color_dark
        : IntroSummaryStyle.intro_text_color_light;

    return AnimatedCrossFade(
      firstChild: _build_collapsed_summary(secondary_text_color),
      secondChild: _build_expanded_summary(secondary_text_color),
      crossFadeState: _is_expanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// 构建收起状态的摘要行。
  Widget _build_collapsed_summary(Color text_color) {
    return Row(
      children: <Widget>[
        // 简介文案区域占满剩余空间，超长时使用省略号截断。
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              right: IntroSummaryStyle.intro_right_padding,
            ),
            child: Text(
              widget.intro_text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text_color,
                fontSize: IntroSummaryStyle.intro_font_size,
                height: IntroSummaryStyle.intro_line_height,
              ),
            ),
          ),
        ),
        // “更多”作为右侧点击入口。
        GestureDetector(
          onTap: () => setState(() => _is_expanded = true),
          child: Text(
            easy.tr('read.more'),
            style: TextStyle(
              color: IntroSummaryStyle.more_button_color,
              fontSize: IntroSummaryStyle.more_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建展开状态的完整简介。
  Widget _build_expanded_summary(Color text_color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.intro_text,
          style: TextStyle(
            color: text_color,
            fontSize: IntroSummaryStyle.intro_font_size,
            height: IntroSummaryStyle.intro_line_height,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => _is_expanded = false),
            child: Text(
              easy.tr('read.collapse'),
              style: TextStyle(
                color: IntroSummaryStyle.more_button_color,
                fontSize: IntroSummaryStyle.more_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
