// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 三个作品分类共用的空状态，使用 empty.svg 图标。
class CreatorEmptyState extends StatelessWidget {
  final int tab_index;
  final bool is_dark;
  final bool is_cjk;
  final VoidCallback on_create_work;

  const CreatorEmptyState({
    super.key,
    required this.tab_index,
    required this.is_dark,
    required this.is_cjk,
    required this.on_create_work,
  });

  @override
  Widget build(BuildContext context) {
    final Color icon_color = is_dark
        ? AuthorStyle.dark_secondary_text
        : AuthorStyle.light_secondary_text;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              'assets/svg/empty.svg',
              width: 80,
              height: 80,
              colorFilter: ColorFilter.mode(icon_color, BlendMode.srcIn),
            ),
            const SizedBox(height: 16),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthorStyle.primary_text(is_dark),
                fontSize: 15,
                height: 1.4,
                fontWeight: AuthorStyle.emphasis_weight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthorStyle.secondary_text(is_dark),
                fontSize: 12,
                height: 1.6,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: on_create_work,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(is_cjk ? '开始创作' : 'Start writing'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                backgroundColor: AuthorStyle.gold,
                foregroundColor: const Color(0xFF1A1A18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AuthorStyle.header_action_radius,
                  ),
                ),
                textStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: AuthorStyle.title_weight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title => switch (tab_index) {
    0 => is_cjk ? '还没有已发布的作品' : 'Your stories belong here',
    1 => is_cjk ? '暂无待审核作品' : 'Nothing in review',
    _ => easy.tr('creator_center.empty_my_drafts'),
  };

  String get _subtitle => switch (tab_index) {
    0 =>
      is_cjk
          ? '作品通过审核并发布后，就会在这里与读者见面。'
          : 'Your published stories will appear here, ready for readers.',
    1 =>
      is_cjk
          ? '草稿提交审核后，可在这里查看作品的审核状态。'
          : 'Submit a draft to follow its review status here.',
    _ =>
      is_cjk
          ? '随时保存每一次灵感，多份草稿都能安心续写。'
          : 'Save your ideas as drafts and pick up wherever you left off.',
  };
}
