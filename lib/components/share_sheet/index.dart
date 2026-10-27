// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/components/share_sheet/layout_style.dart';
import 'package:app/components/share_sheet/share_work_url.dart';
import 'package:app/components/share_sheet/widgets/card_preview_sheet.dart';
import 'package:app/components/share_sheet/widgets/share_channel_grid.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

export 'share_work_url.dart' show WorkShareKind;

/// 长篇、短篇与漫画共用的分享入口；渠道只读取公共配置，不依赖远程列表或Get初始化。
class ShareSheet extends StatelessWidget {
  const ShareSheet({
    super.key,
    required this.novel_id,
    required this.novel_title,
    this.novel_author = '',
    required this.novel_cover_url,
    required this.novel_intro,
    required this.is_dark,
    required this.on_close,
    this.work_kind = WorkShareKind.novel,
    this.language,
  });

  final int novel_id;
  final String novel_title;
  final String novel_author;
  final String novel_cover_url;
  final String novel_intro;
  final bool is_dark;
  final VoidCallback on_close;
  final WorkShareKind work_kind;
  final String? language;

  @override
  Widget build(BuildContext context) => Material(
    color: is_dark
        ? ShareSheetStyle.background_color_dark
        : ShareSheetStyle.background_color_light,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(ShareSheetStyle.border_radius_top),
    ),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            ShareLayoutStyle.sheet_height_ratio,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            LayoutConfig.space_20,
            LayoutConfig.space_12,
            LayoutConfig.space_20,
            LayoutConfig.space_24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ShareSheetStyle.drag_bar_width,
                height: ShareSheetStyle.drag_bar_height,
                decoration: BoxDecoration(
                  color: is_dark
                      ? ShareSheetStyle.drag_bar_color_dark
                      : ShareSheetStyle.drag_bar_color_light,
                  borderRadius: BorderRadius.circular(
                    ShareSheetStyle.drag_bar_radius,
                  ),
                ),
              ),
              const SizedBox(height: LayoutConfig.space_12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      easy.tr('share_sheet.title', context: context),
                      style: TextStyle(
                        color: is_dark
                            ? ShareSheetStyle.title_color_dark
                            : ShareSheetStyle.title_color_light,
                        fontSize: ShareSheetStyle.title_font_size,
                        fontWeight: ShareSheetStyle.title_font_weight,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: on_close,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: LayoutConfig.space_20),
              ShareChannelGrid(
                work_id: novel_id,
                title: novel_title,
                is_dark: is_dark,
                work_kind: work_kind,
                language: language,
                on_generate_image: () => showCardPreviewSheet(
                  context: context,
                  novel_id: novel_id,
                  novel_title: novel_title,
                  novel_author: novel_author,
                  novel_cover_url: novel_cover_url,
                  novel_intro: novel_intro,
                  work_kind: work_kind,
                  language: language,
                  is_dark: is_dark,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 公共弹窗容器随窗口限宽并避让Duo保留区域；内容可滚动，不因未来新增渠道溢出。
Future<void> showShareSheet({
  required BuildContext context,
  required int novel_id,
  required String novel_title,
  String novel_author = '',
  required String novel_cover_url,
  required String novel_intro,
  WorkShareKind work_kind = WorkShareKind.novel,
  String? language,
  bool? is_dark,
}) {
  if (novel_cover_url.trim().isNotEmpty) {
    unawaited(
      precacheImage(
        CachedNetworkImageProvider(novel_cover_url),
        context,
        onError: (_, _) {},
      ),
    );
  }
  final dark = is_dark ?? Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ColorConstants.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
    builder: (ctx) => WindowContentLayout(
      expand_height: false,
      max_width: ShareLayoutStyle.max_width,
      child: ShareSheet(
        novel_id: novel_id,
        novel_title: novel_title,
        novel_author: novel_author,
        novel_cover_url: novel_cover_url,
        novel_intro: novel_intro,
        work_kind: work_kind,
        language: language,
        is_dark: dark,
        on_close: () => Navigator.pop(ctx),
      ),
    ),
  );
}
