// ignore_for_file: non_constant_identifier_names
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../style.dart';
import 'package:app/config/color_config.dart';

/// 第一行保留返回和红色删除，第二行独立显示左对齐 Tab。
class PublishedEditorHeader extends StatelessWidget {
  const PublishedEditorHeader({
    super.key,
    required this.controller,
    required this.is_dark,
    required this.is_cjk,
    required this.on_back,
    required this.on_delete,
  });
  final TabController controller;
  final bool is_dark;
  final bool is_cjk;
  final VoidCallback on_back;
  final VoidCallback? on_delete;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: (is_dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Colors.transparent),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: AuthorStyle.hero_gradient(is_dark),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -AuthorStyle.header_glow_size * 0.28,
            top: -AuthorStyle.header_glow_size * 0.34,
            child: Container(
              width: AuthorStyle.header_glow_size,
              height: AuthorStyle.header_glow_size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuthorStyle.gold.withValues(alpha: is_dark ? 0.08 : 0.20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AuthorStyle.gold.withValues(alpha: is_dark ? 0.10 : 0.16),
                    blurRadius: AuthorStyle.header_glow_blur,
                    spreadRadius: AuthorStyle.header_glow_blur * 0.16,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    BackButton(
                      color: AuthorStyle.primary_text(is_dark),
                      onPressed: on_back,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: on_delete,
                      tooltip: tr('creator_center.delete'),
                      icon: SvgIcon(
                        name: 'delete',
                        width: PublishedEditorStyle.toolbar_icon_size,
                        height: PublishedEditorStyle.toolbar_icon_size,
                        color: ColorConstants.dangerColor,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    controller: controller,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerHeight: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: PublishedEditorStyle.tab_outer_padding,
                    ),
                    labelPadding: EdgeInsets.symmetric(
                      horizontal: is_cjk
                          ? PublishedEditorStyle.tab_spacing_cjk
                          : PublishedEditorStyle.tab_spacing_alphabetic,
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: AuthorStyle.tab_indicator_width,
                        color: AuthorStyle.gold,
                      ),
                    ),
                    splashFactory: NoSplash.splashFactory,
                    tabs: List.generate(
                      3,
                      (index) => AnimatedBuilder(
                        animation: controller.animation!,
                        builder: (context, _) {
                          final distance = (controller.animation!.value - index)
                              .abs()
                              .clamp(0.0, 1.0);
                          final selected_scale = is_cjk
                              ? AuthorStyle.tab_selected_scale_cjk
                              : AuthorStyle.tab_selected_scale_alphabetic;
                          return Tab(
                            child: Transform.scale(
                              scale:
                                  selected_scale + (1 - selected_scale) * distance,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AuthorStyle.tab_horizontal_padding,
                                ),
                                child: Text(
                                  tr(
                                    [
                                      'creator_workspace.details',
                                      'published_editor.settings',
                                      'creator_workspace.chapters',
                                    ][index],
                                  ),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: is_cjk
                                        ? AuthorStyle.tab_font_size_cjk
                                        : AuthorStyle.tab_font_size_alphabetic,
                                    fontWeight: FontWeight.lerp(
                                      AuthorStyle.title_weight,
                                      AuthorStyle.body_weight,
                                      distance,
                                    ),
                                    color: Color.lerp(
                                      AuthorStyle.primary_text(is_dark),
                                      AuthorStyle.secondary_text(is_dark),
                                      distance,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
