// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:flutter/material.dart';

/// 已发布编辑器加载态骨架屏。
///
/// 布局与 [StepBasic] / [StepCategory] 实际内容一一对应：
/// 封面行、标题字段、简介字段、语种选择器（Tab 0）
/// 或多个偏好区块（Tab 1）。
class SkeletonContent extends StatefulWidget {
  final bool is_dark;
  final int tab_index;

  const SkeletonContent({
    super.key,
    required this.is_dark,
    required this.tab_index,
  });

  @override
  State<SkeletonContent> createState() => _SkeletonContentState();
}

class _SkeletonContentState extends State<SkeletonContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final Color base = widget.is_dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFE8E8E8);
        final Color highlight = widget.is_dark
            ? const Color(0xFF3A3A3A)
            : const Color(0xFFF5F5F5);
        final double t = _controller.value;
        final Gradient gradient = LinearGradient(
          begin: const Alignment(-1.0, 0.0),
          end: const Alignment(1.0, 0.0),
          colors: <Color>[base, Color.lerp(base, highlight, t)!, base],
          stops: const <double>[0.0, 0.5, 1.0],
        );

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            WorkEditorStyle.page_padding,
            WorkEditorStyle.section_spacing,
            WorkEditorStyle.page_padding,
            WorkEditorStyle.section_spacing,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: WorkEditorStyle.content_max_width,
              ),
              child: widget.tab_index == 0
                  ? _build_basic_skeleton(gradient)
                  : _build_category_skeleton(gradient),
            ),
          ),
        );
      },
    );
  }

  /// 作品资料骨架屏：封面 + 标题 + 简介 + 语种。
  Widget _build_basic_skeleton(Gradient gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 封面行：与 _build_cover_picker 一致。
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _shimmer(
              gradient,
              width: WorkEditorStyle.cover_width,
              height: WorkEditorStyle.cover_height,
              radius: 16,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: WorkEditorStyle.cover_height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _shimmer(gradient, width: 40, height: 13, radius: 3),
                        const SizedBox(height: 8),
                        _shimmer(gradient, width: 140, height: 12, radius: 3),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -5),
                      child: _shimmer(gradient, width: 100, height: 30, radius: 8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: WorkEditorStyle.field_spacing),

        /// 标题字段：label + input。
        _shimmer(gradient, width: 36, height: 13, radius: 3),
        const SizedBox(height: 8),
        _shimmer(gradient, width: double.infinity, height: 48, radius: 14),
        const SizedBox(height: WorkEditorStyle.field_spacing),

        /// 简介字段：label + 多行 input。
        _shimmer(gradient, width: 32, height: 13, radius: 3),
        const SizedBox(height: 8),
        _shimmer(gradient, width: double.infinity, height: 120, radius: 14),
        const SizedBox(height: WorkEditorStyle.field_spacing),

        /// 语种选择器：label + 带图标的选择器。
        _shimmer(gradient, width: 60, height: 13, radius: 3),
        const SizedBox(height: 8),
        _shimmer(gradient, width: double.infinity, height: 52, radius: 14),
      ],
    );
  }

  /// 类型与分类骨架屏：多个偏好区块。
  Widget _build_category_skeleton(Gradient gradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _build_preference_section_skeleton(gradient, chip_count: 4),
        const SizedBox(height: 20),
        _build_preference_section_skeleton(gradient, chip_count: 3),
        const SizedBox(height: 20),
        _build_preference_section_skeleton(gradient, chip_count: 6),
      ],
    );
  }

  Widget _build_preference_section_skeleton(
    Gradient gradient, {
    required int chip_count,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _shimmer(gradient, width: 56, height: 15, radius: 4),
            const SizedBox(width: 8),
            _shimmer(gradient, width: 72, height: 12, radius: 4),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List<Widget>.generate(chip_count, (_) {
            return _shimmer(gradient, width: 80, height: 36, radius: 18);
          }),
        ),
      ],
    );
  }

  Widget _shimmer(
    Gradient gradient, {
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
      ),
    );
  }
}