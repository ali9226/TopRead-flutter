// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/installation/author_style.dart';
import 'package:app/pages/installation/work_editor/style.dart';
import 'package:flutter/material.dart';

/// TODO 作品编辑页的统一表单卡片。
class EditorSectionCard extends StatelessWidget {
  /// TODO 区块标题。
  final String title;

  /// TODO 区块说明。
  final String subtitle;

  /// TODO 区块图标。
  final IconData icon;

  /// TODO 区块正文。
  final Widget child;

  /// TODO 当前是否夜间主题。
  final bool is_dark;

  const EditorSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorkEditorStyle.section_padding),
      decoration: BoxDecoration(
        color: AuthorStyle.surface(is_dark),
        borderRadius: BorderRadius.circular(WorkEditorStyle.section_radius),
        border: Border.all(color: AuthorStyle.border(is_dark)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: is_dark ? 0.16 : 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AuthorStyle.gold.withValues(
                    alpha: is_dark ? 0.16 : 0.20,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: AuthorStyle.primary_text(is_dark),
                        fontSize: 17,
                        fontWeight: WorkEditorStyle.section_title_weight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AuthorStyle.secondary_text(is_dark),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: AuthorStyle.body_weight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
