// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/installation/author_style.dart';
import 'package:app/pages/installation/work_editor/style.dart';
import 'package:flutter/material.dart';

/// TODO 三步作品创建流程指示器。
class EditorStepIndicator extends StatelessWidget {
  /// TODO 当前步骤索引。
  final int current_step;

  /// TODO 本地化后的步骤标题。
  final List<String> labels;

  /// TODO 是否为 CJK 语种。
  final bool is_cjk;

  /// TODO 当前是否夜间主题。
  final bool is_dark;

  const EditorStepIndicator({
    super.key,
    required this.current_step,
    required this.labels,
    required this.is_cjk,
    required this.is_dark,
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

          return Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: is_current ? 30 : 24,
                        height: is_current ? 30 : 24,
                        decoration: BoxDecoration(
                          color: is_active
                              ? AuthorStyle.gold
                              : AuthorStyle.secondary_surface(is_dark),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: is_active
                                ? AuthorStyle.gold
                                : AuthorStyle.border(is_dark),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: is_active && index < current_step
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
                                      : AuthorStyle.secondary_text(is_dark),
                                  fontSize: 12,
                                  fontWeight: AuthorStyle.emphasis_weight,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: is_current
                              ? AuthorStyle.primary_text(is_dark)
                              : AuthorStyle.secondary_text(is_dark),
                          fontSize: is_cjk
                              ? WorkEditorStyle.step_label_size_cjk
                              : WorkEditorStyle.step_label_size_alphabetic,
                          fontWeight: is_current
                              ? AuthorStyle.emphasis_weight
                              : AuthorStyle.body_weight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: index < current_step
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
