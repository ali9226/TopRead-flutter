import 'package:app/components/work_reading_actions/index.dart';
import 'package:flutter/material.dart';

/// 长篇只透传真实阅读与收藏状态，操作的视觉和布局由作品共享组件维护。
class ReadIntroductionActions extends StatelessWidget {
  const ReadIntroductionActions({
    super.key,
    this.on_read,
    this.on_favorite,
    this.favorited = false,
    this.favorite_loading = false,
    this.continuing = false,
    this.on_hero = true,
    this.is_dark = false,
    this.compact = false,
  });
  final VoidCallback? on_read;
  final VoidCallback? on_favorite;
  final bool favorited;
  final bool favorite_loading;
  final bool continuing;
  final bool on_hero;
  final bool is_dark;
  final bool compact;

  @override
  Widget build(BuildContext context) => WorkReadingActions(
    compact: compact,
    on_read: on_read,
    on_favorite: on_favorite,
    favorited: favorited,
    favorite_loading: favorite_loading,
    continuing: continuing,
    on_hero: on_hero,
    is_dark: is_dark,
    read_key: const ValueKey('novel_hero_read'),
    favorite_key: const ValueKey('novel_hero_favorite'),
  );
}
