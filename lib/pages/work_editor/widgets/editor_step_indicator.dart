// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:flutter/material.dart';

/// TODO 四步作品创建流程指示器。
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
          /// 最后一个步骤不需要右侧横线。
          final bool is_last = index == labels.length - 1;

          return Expanded(
            child: Row(
              children: <Widget>[
                /// 圆圈区域（最后一步用固定宽度+左边距，其余居中）。
                is_last
                    ? GestureDetector(
                        onTap: on_step_tap != null
                            ? () => on_step_tap!(index)
                            : null,
                        child: Container(
                          height: WorkEditorStyle.step_indicator_height,
                          width: WorkEditorStyle.step_circle_size_large + 8,
                          padding: const EdgeInsets.only(left: 8),
                          alignment: Alignment.centerLeft,
                          child: _build_circle(
                              is_current, is_active, has_error, index),
                        ),
                      )
                    : Expanded(
                        child: GestureDetector(
                          onTap: on_step_tap != null
                              ? () => on_step_tap!(index)
                              : null,
                          child: SizedBox(
                            height: WorkEditorStyle.step_indicator_height,
                            child: Center(
                              child: _build_circle(
                                  is_current, is_active, has_error, index),
                            ),
                          ),
                        ),
                      ),

                /// 连接线（最后一步不显示）。
                if (!is_last)
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

  /// TODO 构建步骤圆圈。
  Widget _build_circle(
    bool is_current,
    bool is_active,
    bool has_error,
    int index,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: is_current
          ? WorkEditorStyle.step_circle_size_large
          : WorkEditorStyle.step_circle_size_small,
      height: is_current
          ? WorkEditorStyle.step_circle_size_large
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
          ? Icon(
              Icons.close_rounded,
              size: 15,
              color: is_dark ? AuthorStyle.dark_surface : Colors.white,
            )
          : is_active && index < current_step
              ? Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: is_dark ? AuthorStyle.dark_surface : ColorConstants.lightTextColor,
                )
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: is_active
                        ? (is_dark ? AuthorStyle.dark_surface : ColorConstants.lightTextColor)
                        : AuthorStyle.secondary_text(is_dark),
                    fontSize: 12,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                  ),
                ),
    );
  }
}
