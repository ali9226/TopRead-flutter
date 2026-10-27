// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/util/router/router_util.dart';
import 'package:flutter/material.dart';

import 'style.dart';
import 'skeleton.dart';

/// 封面优先的轻量书目卡；全文标题仍保留在辅助功能语义中。
class ComicDiscoveryCard extends StatelessWidget {
  const ComicDiscoveryCard({super.key, required this.comic, this.on_open});

  final ComicItem comic;
  final ValueChanged<ComicItem>? on_open;

  @override
  Widget build(BuildContext context) {
    final cjk = ComicsStyle.is_cjk(context);
    final scaler = MediaQuery.textScalerOf(context);
    final category_text = comic.categories
        .map((category) => ComicsStyle.category_name(context, category).trim())
        .where((name) => name.isNotEmpty)
        .take(2)
        .join(' · ');
    final radius = BorderRadius.circular(ComicDiscoveryGridStyle.cover_radius);
    return Semantics(
      button: true,
      label: [
        comic.title,
        category_text,
      ].where((text) => text.isNotEmpty).join(', '),
      excludeSemantics: true,
      child: Material(
        color: ColorConstants.transparent,
        child: InkWell(
          onTap: () => on_open != null
              ? on_open!(comic)
              : routerUtil(path: '/comics/detail?id=${comic.id}', type: 'push'),
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: ComicDiscoveryGridStyle.cover_ratio,
                child: ClipRRect(
                  borderRadius: radius,
                  child: LayoutBuilder(
                    builder: (context, constraints) => ComicImage(
                      url: comic.cover_url,
                      semantic_label: comic.title,
                      cache_width:
                          (constraints.maxWidth *
                                  MediaQuery.devicePixelRatioOf(context))
                              .ceil(),
                      loading_placeholder: (_) =>
                          const ComicDiscoveryCoverSkeleton(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ComicDiscoveryGridStyle.title_gap),
              SizedBox(
                height: ComicDiscoveryGridStyle.title_extent(scaler, cjk),
                child: Text(
                  comic.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ComicsStyle.ink(context),
                    fontSize: cjk
                        ? ComicDiscoveryGridStyle.title_size_cjk
                        : ComicDiscoveryGridStyle.title_size_alphabetic,
                    height: cjk
                        ? ComicDiscoveryGridStyle.title_height_cjk
                        : ComicDiscoveryGridStyle.title_height_alphabetic,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: ComicDiscoveryGridStyle.category_gap),
              SizedBox(
                height: ComicDiscoveryGridStyle.category_extent(scaler, cjk),
                child: Text(
                  category_text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ComicsStyle.muted(context),
                    fontSize: cjk
                        ? ComicDiscoveryGridStyle.category_size_cjk
                        : ComicDiscoveryGridStyle.category_size_alphabetic,
                    height: cjk
                        ? ComicDiscoveryGridStyle.category_height_cjk
                        : ComicDiscoveryGridStyle.category_height_alphabetic,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
