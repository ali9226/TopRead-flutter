import 'package:flutter/material.dart';
import 'package:app/pages/read/widgets/introduction_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/author_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/stat_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/tag_section/style.dart';
import 'package:app/pages/read/widgets/main_list/style.dart';
import './style.dart';

/// 阅读页骨架屏组件。
class ReadSkeleton extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const ReadSkeleton({super.key, required this.is_dark});

  @override
  State<ReadSkeleton> createState() => _ReadSkeletonState();
}

class _ReadSkeletonState extends State<ReadSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: ReadSkeletonStyle.animation_duration_ms,
      ),
    )..repeat();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base_color = widget.is_dark
        ? ReadSkeletonStyle.dark_base_color
        : ReadSkeletonStyle.light_base_color;

    final Color highlight_color = widget.is_dark
        ? ReadSkeletonStyle.dark_highlight_color
        : ReadSkeletonStyle.light_highlight_color;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double slide_value = Tween<double>(
          begin: -1,
          end: 1,
        ).transform(_animation.value);

        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.6 + slide_value, -0.3),
              end: Alignment(1.6 + slide_value, 0.3),
              colors: [
                base_color,
                base_color,
                highlight_color,
                base_color,
                base_color,
              ],
              stops: ReadSkeletonStyle.gradient_stops,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: _build_content(base_color),
    );
  }

  Widget _build_content(Color color) {
    return Column(
      children: <Widget>[
        /// 内容区域骨架屏。
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              MainListStyle.page_horizontal_padding,
              60,
              MainListStyle.page_horizontal_padding,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 封面居中显示，对齐 ReadIntroductionSection 布局
                Align(
                  child: _build_box(
                    width: IntroductionStyle.cover_width,
                    height: IntroductionStyle.cover_height,
                    radius: IntroductionStyle.cover_radius,
                    color: color,
                  ),
                ),
                const SizedBox(height: IntroductionStyle.title_top_spacing),
                // 标题居中显示
                Center(
                  child: _build_box(
                    width: ReadSkeletonStyle.title_width,
                    height: ReadSkeletonStyle.title_height,
                    color: color,
                  ),
                ),
                const SizedBox(height: AuthorStyle.author_top_spacing),
                // 作者栏居中显示
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _build_box(
                        width: AuthorStyle.author_avatar_size,
                        height: AuthorStyle.author_avatar_size,
                        radius: 999,
                        color: color,
                      ),
                      const SizedBox(
                        width: AuthorStyle.author_name_left_spacing,
                      ),
                      _build_box(
                        width: ReadSkeletonStyle.author_name_width,
                        height: 14,
                        color: color,
                      ),
                      const SizedBox(
                        width: AuthorStyle.follow_tag_left_spacing,
                      ),
                      _build_box(
                        width: ReadSkeletonStyle.follow_btn_width,
                        height: 22,
                        radius: AuthorStyle.follow_tag_radius,
                        color: color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StatStyle.stat_panel_top_spacing),
                // 统计区：三列布局
                Row(
                  children: [
                    Expanded(child: _build_stat_item(color)),
                    _build_box(
                      width: 1,
                      height: 24,
                      color: color.withOpacity(0.3),
                    ),
                    Expanded(child: _build_stat_item(color)),
                    _build_box(
                      width: 1,
                      height: 24,
                      color: color.withOpacity(0.3),
                    ),
                    Expanded(child: _build_stat_item(color)),
                  ],
                ),
                const SizedBox(
                  height:
                      TagStyle.section_title_font_size +
                      TagStyle.tag_title_top_padding,
                ),
                // 标签区：左侧标题 + 右侧标签
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: TagStyle.tag_title_top_padding,
                      ),
                      child: _build_box(
                        width: 32,
                        height: TagStyle.section_title_font_size,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: TagStyle.tag_wrap_left_spacing),
                    Expanded(
                      child: Wrap(
                        spacing: TagStyle.tag_spacing,
                        runSpacing: TagStyle.tag_run_spacing,
                        alignment: WrapAlignment.end,
                        children: [
                          _build_box(
                            width: 48,
                            height: 22,
                            radius: 999,
                            color: color,
                          ),
                          _build_box(
                            width: 56,
                            height: 22,
                            radius: 999,
                            color: color,
                          ),
                          _build_box(
                            width: 48,
                            height: 22,
                            radius: 999,
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IntroductionStyle.intro_top_spacing),
                // 简介区
                Row(
                  children: [
                    Expanded(
                      child: _build_box(
                        width: double.infinity,
                        height: 14,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _build_box(width: 32, height: 14, color: color),
                  ],
                ),
                const SizedBox(height: 40),
                // 评论区
                _build_box(width: 100, height: 20, color: color),
                const SizedBox(height: 16),
                ...List.generate(
                  2,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _build_box(
                          width: 32,
                          height: 32,
                          radius: 999,
                          color: color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _build_box(width: 80, height: 12, color: color),
                              const SizedBox(height: 8),
                              _build_box(
                                width: double.infinity,
                                height: 12,
                                color: color,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // 正文区
                _build_box(width: 120, height: 24, color: color),
                const SizedBox(height: 8),
                _build_box(width: 180, height: 16, color: color),
                const SizedBox(height: 20),
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _build_box(
                      width: double.infinity,
                      height: 16,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _build_stat_item(Color color) {
    return Column(
      children: [
        _build_box(
          width: ReadSkeletonStyle.stat_major_width,
          height: 18,
          color: color,
        ),
        const SizedBox(height: StatStyle.stat_subtitle_top_spacing),
        _build_box(
          width: ReadSkeletonStyle.stat_subtitle_width,
          height: 12,
          color: color,
        ),
      ],
    );
  }

  Widget _build_box({
    required double width,
    required double height,
    double radius = 4,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
