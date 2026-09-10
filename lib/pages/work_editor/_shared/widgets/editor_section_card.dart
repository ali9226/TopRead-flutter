// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:flutter/material.dart';

/// 作品编辑页的统一表单区块。
///
/// 简洁设计：无卡片边框、无阴影、无图标。
class EditorSectionCard extends StatelessWidget {
  /// 区块标题。
  final String title;

  /// 区块说明。
  final String subtitle;

  /// 区块图标（保留参数兼容，但不使用）。
  final IconData? icon;

  /// 区块正文。
  final Widget child;

  /// 当前是否夜间主题。
  final bool is_dark;

  const EditorSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    required this.child,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标题区域
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: AuthorStyle.primary_text(is_dark),
                  fontSize: 20,
                  fontWeight: WorkEditorStyle.section_title_weight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ],
          ),
        ),

        /// 正文内容
        child,
      ],
    );
  }
}
