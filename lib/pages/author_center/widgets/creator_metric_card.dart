// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:flutter/material.dart';

/// TODO 创作者工作台统计卡片。
class CreatorMetricCard extends StatelessWidget {
  /// TODO 指标图标。
  final IconData icon;

  /// TODO 指标数值。
  final String value;

  /// TODO 指标名称。
  final String label;

  /// TODO 指标强调色。
  final Color accent_color;

  /// TODO 当前是否夜间主题。
  final bool is_dark;

  /// TODO 点击行为。
  final VoidCallback? on_tap;

  const CreatorMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent_color,
    required this.is_dark,
    this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: on_tap,
        borderRadius: BorderRadius.circular(AuthorStyle.card_radius),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          decoration: BoxDecoration(
            color: AuthorStyle.surface(is_dark),
            borderRadius: BorderRadius.circular(AuthorStyle.card_radius),
            border: Border.all(
              color: accent_color.withValues(alpha: is_dark ? 0.18 : 0.18),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: is_dark ? 0.14 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent_color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accent_color, size: 18),
              ),
              const SizedBox(height: 13),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AuthorStyle.primary_text(is_dark),
                  fontSize: 21,
                  fontWeight: AuthorStyle.title_weight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
