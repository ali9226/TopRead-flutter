import 'package:app/components/work_introduction_hero/style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// TODO 与长篇第一屏共用封面、海报底色和竖向遮罩，日夜保持相同效果。
class BookHeaderBackdrop extends StatelessWidget {
  const BookHeaderBackdrop({
    super.key,
    required this.cover_url,
    required this.is_dark,
  });

  final String cover_url;
  final bool is_dark;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: WorkIntroductionHeroStyle.poster_background),
          if (cover_url.trim().isNotEmpty)
            CachedNetworkImage(
              imageUrl: cover_url,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(
                color: WorkIntroductionHeroStyle.poster_background,
              ),
              errorWidget: (_, _, _) => const ColoredBox(
                color: WorkIntroductionHeroStyle.poster_background,
              ),
            ),
          const DecoratedBox(
            key: ValueKey('read_directory_header_scrim'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: WorkIntroductionHeroStyle.scrim_colors,
                stops: WorkIntroductionHeroStyle.scrim_stops,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
