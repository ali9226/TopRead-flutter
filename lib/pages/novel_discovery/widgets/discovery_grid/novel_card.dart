// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/novel_discovery.dart';
import 'package:app/pages/novel_discovery/style.dart';
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/util/router/router_util.dart';
import 'package:flutter/material.dart';

import 'style.dart';
import 'skeleton.dart';

/// 封面优先的轻量书目卡；全文标题仍保留在辅助功能语义中。
class NovelDiscoveryCard extends StatelessWidget {
  const NovelDiscoveryCard({super.key, required this.novel, this.on_open});

  final NovelDiscoveryItem novel;
  final ValueChanged<NovelDiscoveryItem>? on_open;

  @override
  Widget build(BuildContext context) {
    final cjk = NovelDiscoveryStyle.is_cjk(context);
    final scaler = MediaQuery.textScalerOf(context);
    final category_text = novel.categories
        .map(
          (category) =>
              NovelDiscoveryStyle.category_name(context, category).trim(),
        )
        .where((name) => name.isNotEmpty)
        .take(2)
        .join(' · ');
    final radius = BorderRadius.circular(NovelDiscoveryGridStyle.cover_radius);
    return Semantics(
      button: true,
      label: [
        novel.title,
        category_text,
      ].where((text) => text.isNotEmpty).join(', '),
      excludeSemantics: true,
      child: Material(
        color: ColorConstants.transparent,
        child: InkWell(
          onTap: () => on_open != null
              ? on_open!(novel)
              : routerUtil(
                  path: Uri(
                    path: '/read',
                    queryParameters: {
                      'id': '${novel.id}',
                      'title': novel.title,
                    },
                  ).toString(),
                  type: 'push',
                ),
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: NovelDiscoveryGridStyle.cover_ratio,
                child: ClipRRect(
                  borderRadius: radius,
                  child: LayoutBuilder(
                    builder: (context, constraints) => novel.cover_url.isEmpty
                        ? ColoredBox(
                            color: NovelDiscoveryStyle.muted(context)
                                .withValues(
                                  alpha: NovelDiscoveryStyle.empty_cover_tint,
                                ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: NovelDiscoveryStyle.muted(context),
                            ),
                          )
                        : NetworkCoverImage(
                            image_url: novel.cover_url,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            border_radius: NovelDiscoveryGridStyle.cover_radius,
                            is_dark: NovelDiscoveryStyle.is_dark(context),
                            mem_cache_width:
                                (constraints.maxWidth *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .ceil(),
                            loading_placeholder: (_) =>
                                const NovelDiscoveryCoverSkeleton(),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: NovelDiscoveryGridStyle.title_gap),
              SizedBox(
                height: NovelDiscoveryGridStyle.title_extent(scaler, cjk),
                child: Text(
                  novel.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: NovelDiscoveryStyle.ink(context),
                    fontSize: cjk
                        ? NovelDiscoveryGridStyle.title_size_cjk
                        : NovelDiscoveryGridStyle.title_size_alphabetic,
                    height: cjk
                        ? NovelDiscoveryGridStyle.title_height_cjk
                        : NovelDiscoveryGridStyle.title_height_alphabetic,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: NovelDiscoveryGridStyle.category_gap),
              SizedBox(
                height: NovelDiscoveryGridStyle.category_extent(scaler, cjk),
                child: Text(
                  category_text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: NovelDiscoveryStyle.muted(context),
                    fontSize: cjk
                        ? NovelDiscoveryGridStyle.category_size_cjk
                        : NovelDiscoveryGridStyle.category_size_alphabetic,
                    height: cjk
                        ? NovelDiscoveryGridStyle.category_height_cjk
                        : NovelDiscoveryGridStyle.category_height_alphabetic,
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
