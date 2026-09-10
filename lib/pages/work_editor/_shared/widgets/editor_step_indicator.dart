// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:flutter/material.dart';

/// TODO 长短篇共用步骤指示器，切换时固定布局高度，仅圆点内部缩放。
class EditorStepIndicator extends StatelessWidget {
  /// TODO 当前步骤索引。
  final int current_step;

  /// TODO 本地化后的步骤标题。
  final List<String> labels;

  /// TODO 当前是否夜间主题。
  final bool is_dark;

  /// TODO 存在错误的步骤索引集合（仅对当前步骤之前的步骤生效）。
  final Set<int> error_steps;

  /// TODO 点击步骤时的回调。
  final ValueChanged<int>? on_step_tap;

  const EditorStepIndicator({
    super.key,
    required this.current_step,
    required this.labels,
    required this.is_dark,
    this.error_steps = const <int>{},
    this.on_step_tap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuthorStyle.surface(is_dark),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 15),
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool is_active = index <= current_step;
          final bool is_current = index == current_step;

          /// 错误状态仅对当前步骤之前的步骤生效。
          final bool has_error =
              index < current_step && error_steps.contains(index);

          return Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: on_step_tap != null
                        ? () => on_step_tap!(index)
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          width: WorkEditorStyle.step_indicator_height,
                          height: WorkEditorStyle.step_indicator_height,
                          // TODO 预留当前圆点的最大尺寸，避免两个圆点一缩一放时整栏先收缩再撑开。
                          child: Center(
                            child: AnimatedContainer(
                              duration: WorkEditorStyle
                                  .step_indicator_animation_duration,
                              width: is_current
                                  ? WorkEditorStyle.step_indicator_height
                                  : WorkEditorStyle.step_circle_size_small,
                              height: is_current
                                  ? WorkEditorStyle.step_indicator_height
                                  : WorkEditorStyle.step_circle_size_small,
                              decoration: BoxDecoration(
                                color: has_error
                                    ? ColorConstants.dangerColor
                                    : is_active
                                    ? AuthorStyle.gold
                                    : AuthorStyle.secondary_surface(is_dark),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: has_error
                                      ? ColorConstants.dangerColor
                                      : is_active
                                      ? AuthorStyle.gold
                                      : AuthorStyle.border(is_dark),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: has_error
                                  ? const Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    )
                                  : is_active && index < current_step
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: Color(0xFF1A1A18),
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: is_active
                                            ? const Color(0xFF1A1A18)
                                            : AuthorStyle.secondary_text(
                                                is_dark,
                                              ),
                                        fontSize: 12,
                                        fontWeight: AuthorStyle.emphasis_weight,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: has_error
                          ? ColorConstants.dangerColor
                          : index < current_step
                          ? AuthorStyle.gold
                          : AuthorStyle.border(is_dark),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
