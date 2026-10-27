// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:app/stores/user_information.dart';
import 'package:app/components/share_sheet/style.dart';
import 'package:app/components/share_sheet/widgets/text_selection_poster_card.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/share_excerpt.dart';
import 'package:app/components/share_sheet/selection_poster_metrics.dart';
import 'package:app/components/share_sheet/layout_style.dart';
import 'package:app/components/share_sheet/poster_export.dart';
import 'package:app/components/share_sheet/share_feedback.dart';
import 'package:app/components/share_sheet/share_work_url.dart';
import 'package:app/components/share_sheet/widgets/share_channel_grid.dart';
import 'package:app/components/window_content_layout/index.dart';

/// 段落选中文字的卡片预览弹窗。
///
/// 从底部弹出，展示以用户选中文字为摘录的分享卡片。
/// 支持左右滑动切换卡片底色，底部有分享图标和「保存到相册」按钮。
///
/// 参数：
/// - [novel_id] 小说 ID。
/// - [novel_title] 小说标题。
/// - [novel_author] 小说作者名称。
/// - [novel_cover_url] 小说封面图地址。
/// - [share_text] 用户选中的段落文字。
/// - [is_dark] 当前是否为夜间模式。
class TextSelectionPreviewSheet extends StatefulWidget {
  final int novel_id;
  final String novel_title;
  final String novel_author;
  final String novel_cover_url;

  /// 用户选中的段落文字，展示在卡片摘录区域。
  final String share_text;
  final ShareExcerpt? excerpt;
  final WorkShareKind work_kind;

  final bool is_dark;

  const TextSelectionPreviewSheet({
    super.key,
    required this.novel_id,
    required this.novel_title,
    this.novel_author = '',
    required this.novel_cover_url,
    required this.share_text,
    this.excerpt,
    this.work_kind = WorkShareKind.novel,
    required this.is_dark,
  });

  @override
  State<TextSelectionPreviewSheet> createState() =>
      _TextSelectionPreviewSheetState();
}

class _TextSelectionPreviewSheetState extends State<TextSelectionPreviewSheet> {
  /// 当前选中的卡片底色索引。
  int _current_color_index = 0;

  /// 每张海报独立使用一个 Key，切换页面时不会发生 GlobalKey 重挂载。
  late final List<GlobalKey> _card_keys;

  /// 控制海报分页，供左右滑动和色板圆点点击共同使用。
  late final PageController _page_controller;

  /// 是否正在保存。
  bool _is_saving = false;

  /// 卡片底色渐变列表。
  late final List<List<Color>> _gradient_colors;

  /// 用户头像地址。
  String _user_avatar_url = '';

  /// 用户昵称。
  String _user_nickname = '';

  /// 随机选择的 SVG 头像索引（当用户没有头像时使用）。
  late final int _random_avatar_index;

  @override
  void initState() {
    super.initState();
    _gradient_colors = ShareSheetStyle.card_gradient_colors;
    _card_keys = List<GlobalKey>.generate(
      _gradient_colors.length,
      (_) => GlobalKey(),
    );
    _page_controller = PageController();
    _random_avatar_index = Random().nextInt(10);
    _load_user_info();
  }

  @override
  void dispose() {
    _page_controller.dispose();
    super.dispose();
  }

  /// 加载用户信息。
  void _load_user_info() {
    try {
      final UserInformation user_info = Get.find<UserInformation>();
      final info = user_info.userInfo.value;
      if (info != null) {
        _user_avatar_url = info.avatarUrl;
        _user_nickname = info.name;
      }
    } catch (_) {
      // 用户信息未初始化，使用默认值
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color background_color = widget.is_dark
        ? ShareSheetStyle.background_color_dark
        : ShareSheetStyle.background_color_light;
    final Color title_color = widget.is_dark
        ? ShareSheetStyle.title_color_dark
        : ShareSheetStyle.title_color_light;
    final Color drag_bar_color = widget.is_dark
        ? ShareSheetStyle.drag_bar_color_dark
        : ShareSheetStyle.drag_bar_color_light;

    return Container(
      width: double.infinity,
      // 按实际内容收拢，只有超出窗口上限时才滚动。
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height *
            ShareLayoutStyle.sheet_height_ratio,
      ),
      decoration: BoxDecoration(
        color: background_color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ShareSheetStyle.border_radius_top),
          topRight: Radius.circular(ShareSheetStyle.border_radius_top),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /// 顶部拖拽指示条。
            _build_drag_bar(drag_bar_color),

            /// 标题「卡片预览」。
            _build_title(title_color),

            /// 卡片预览区域（可滑动切换配色）。
            SizedBox(
              height: min(
                ShareSheetStyle.poster_preview_max_height,
                max(
                  ShareLayoutStyle.min_preview_height,
                  MediaQuery.sizeOf(context).height *
                          ShareLayoutStyle.sheet_height_ratio -
                      ShareLayoutStyle.preview_controls_reserved_height,
                ),
              ),
              child: _build_card_pager(),
            ),

            /// 底部指示器。
            _build_indicator(),

            /// 底部操作栏（分享图标 + 保存按钮）。
            _build_bottom_action_bar(),
          ],
        ),
      ),
    );
  }

  /// 构建顶部拖拽指示条。
  Widget _build_drag_bar(Color color) {
    return Padding(
      padding: ShareSheetStyle.title_padding,
      child: Container(
        width: ShareSheetStyle.drag_bar_width,
        height: ShareSheetStyle.drag_bar_height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(ShareSheetStyle.drag_bar_radius),
        ),
      ),
    );
  }

  /// 构建弹窗标题。
  Widget _build_title(Color title_color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LayoutConfig.space_16),
      child: Text(
        easy.tr('share_sheet.card_preview_title'),
        style: TextStyle(
          fontSize: ShareSheetStyle.preview_title_font_size,
          fontWeight: ShareSheetStyle.preview_title_font_weight,
          color: title_color,
        ),
      ),
    );
  }

  /// 构建卡片分页器（左右滑动切换配色）。
  Widget _build_card_pager() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final design_size = selection_poster_design_size(
          context,
          widget.excerpt ?? ShareExcerpt.selected_only(widget.share_text),
        );
        final double design_width = design_size.width;
        final double design_height = design_size.height;
        const double horizontal_padding =
            ShareSheetStyle.preview_card_horizontal_padding;
        final double available_width = max(
          0,
          constraints.maxWidth - horizontal_padding * 2,
        );
        // 长海报按宽度显示并可纵向查看，不把整段缩成细小的不可读长条。
        final double preview_width = min(design_width, available_width);
        final double preview_height =
            preview_width / (design_width / design_height);

        return PageView.builder(
          controller: _page_controller,
          physics: _is_saving ? const NeverScrollableScrollPhysics() : null,
          itemCount: _gradient_colors.length,
          onPageChanged: (int index) {
            setState(() {
              _current_color_index = index;
            });
          },
          itemBuilder: (BuildContext context, int index) {
            return Align(
              alignment: Alignment.topCenter,
              child: Scrollbar(
                interactive: false,
                child: SingleChildScrollView(
                  key: ValueKey('selection_poster_scroll_$index'),
                  primary: false,
                  child: SizedBox(
                    width: preview_width,
                    height: preview_height,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _build_card(index),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建一张固定设计尺寸的分享海报。
  Widget _build_card(int color_index) {
    return RepaintBoundary(
      key: _card_keys[color_index],
      child: TextSelectionPosterCard(
        novel_id: widget.novel_id,
        novel_title: widget.novel_title,
        novel_author: widget.novel_author,
        novel_cover_url: widget.novel_cover_url,
        share_text: widget.share_text,
        excerpt: widget.excerpt,
        work_kind: widget.work_kind,
        user_avatar_url: _user_avatar_url,
        user_nickname: _user_nickname,
        date_text: _format_date(DateTime.now()),
        fallback_avatar_index: _random_avatar_index,
        canvas_colors: _gradient_colors[color_index],
        accent_color: ShareSheetStyle.card_accent_colors[color_index],
        footer_color: ShareSheetStyle.card_footer_colors[color_index],
        use_dark_palette: color_index == ShareSheetStyle.card_dark_style_index,
      ),
    );
  }

  /// 将日期格式为稳定的海报展示文本，避免受系统地区格式影响。
  String _format_date(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }

  /// 构建与海报配色一致的色板指示器。
  Widget _build_indicator() {
    return Padding(
      padding: const EdgeInsets.only(
        top: ShareSheetStyle.indicator_top_padding,
        bottom: ShareSheetStyle.indicator_bottom_padding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_gradient_colors.length, (int index) {
          final bool is_active = index == _current_color_index;
          return GestureDetector(
            key: ValueKey<String>('text_share_color_indicator_$index'),
            behavior: HitTestBehavior.opaque,
            onTap: _is_saving ? null : () => _on_color_indicator_tap(index),
            child: SizedBox(
              width:
                  ShareSheetStyle.indicator_slot_size +
                  ShareSheetStyle.indicator_spacing,
              height: ShareSheetStyle.indicator_slot_size,
              child: Center(
                child: AnimatedContainer(
                  key: ValueKey<String>(
                    'text_share_color_indicator_dot_$index',
                  ),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: is_active
                      ? ShareSheetStyle.indicator_active_width
                      : ShareSheetStyle.indicator_size,
                  height: is_active
                      ? ShareSheetStyle.indicator_active_width
                      : ShareSheetStyle.indicator_size,
                  padding: EdgeInsets.all(is_active ? LayoutConfig.space_3 : 0),
                  decoration: BoxDecoration(
                    color: _gradient_colors[index].first,
                    shape: BoxShape.circle,
                    border: is_active
                        ? Border.all(
                            color: ShareSheetStyle.indicator_ring_color,
                            width: 1,
                          )
                        : null,
                  ),
                  child: is_active
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: _gradient_colors[index].last,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 点击色板圆点后平滑跳转到对应海报。
  void _on_color_indicator_tap(int index) {
    if (_is_saving ||
        index == _current_color_index ||
        !_page_controller.hasClients) {
      return;
    }
    _page_controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// 构建底部操作栏（分享图标 + 保存到相册）。
  Widget _build_bottom_action_bar() {
    const double action_bar_horizontal_padding =
        ShareSheetStyle.preview_card_horizontal_padding;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: action_bar_horizontal_padding),
      child: Column(
        children: <Widget>[
          /// 选文与三类作品分享共用渠道数组。
          ShareChannelGrid(
            work_id: widget.novel_id,
            title: widget.novel_title,
            is_dark: widget.is_dark,
            work_kind: widget.work_kind,
            language: Localizations.localeOf(context).languageCode,
          ),

          const SizedBox(height: LayoutConfig.space_16),

          /// 保存到相册按钮。
          _build_save_button(),

          /// 底部安全区域。
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  /// 构建「保存到相册」按钮。
  Widget _build_save_button() {
    return GestureDetector(
      onTap: _is_saving ? null : _on_save_to_album,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: ShareSheetStyle.save_button_height,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutConfig.space_16,
          vertical: LayoutConfig.space_12,
        ),
        decoration: BoxDecoration(
          color: ShareSheetStyle.save_button_bg_color,
          borderRadius: BorderRadius.circular(
            ShareSheetStyle.save_button_radius,
          ),
        ),
        child: Center(
          child: _is_saving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ShareSheetStyle.save_button_text_color,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: ShareSheetStyle.save_button_text_color,
                    ),
                    const SizedBox(width: LayoutConfig.space_8),
                    Flexible(
                      child: Text(
                        easy.tr('share_sheet.save_to_album'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ShareSheetStyle.save_button_font_size,
                          fontWeight: ShareSheetStyle.save_button_font_weight,
                          color: ShareSheetStyle.save_button_text_color,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 与普通作品海报共用权限、截图和保存生命周期。
  Future<void> _on_save_to_album() async {
    if (_is_saving) return;
    setState(() => _is_saving = true);
    final result = await save_share_poster(
      boundary_key: _card_keys[_current_color_index],
      image_name:
          'topread_text_${widget.novel_id}_${DateTime.now().millisecondsSinceEpoch}',
      is_current: () => mounted,
    );
    if (!mounted) return;
    setState(() => _is_saving = false);
    show_share_feedback(context, switch (result) {
      PosterSaveResult.saved => 'share_sheet.save_success',
      PosterSaveResult.access_denied => 'share_sheet.photo_permission_denied',
      PosterSaveResult.unavailable ||
      PosterSaveResult.failed => 'share_sheet.save_failed',
    });
  }
}

/// 显示段落选中文字卡片预览弹窗的便捷方法。
///
/// 参数：
/// - [context] BuildContext。
/// - [novel_id] 小说 ID。
/// - [novel_title] 小说标题。
/// - [novel_author] 小说作者名称。
/// - [novel_cover_url] 小说封面图地址。
/// - [share_text] 用户选中的段落文字。
/// - [is_dark] 当前是否为夜间模式，不传则自动根据主题判断。
void showTextSelectionPreviewSheet({
  required BuildContext context,
  required int novel_id,
  required String novel_title,
  String novel_author = '',
  required String novel_cover_url,
  required String share_text,
  ShareExcerpt? excerpt,
  WorkShareKind work_kind = WorkShareKind.novel,
  bool? is_dark,
}) {
  final bool current_is_dark =
      is_dark ?? Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: ColorConstants.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
    builder: (BuildContext ctx) {
      // 只有内容避让安全区，面板背景必须一直覆盖到窗口底部。
      return WindowContentLayout(
        expand_height: false,
        max_width: ShareLayoutStyle.max_width,
        child: TextSelectionPreviewSheet(
          novel_id: novel_id,
          novel_title: novel_title,
          novel_author: novel_author,
          novel_cover_url: novel_cover_url,
          share_text: share_text,
          excerpt: excerpt,
          work_kind: work_kind,
          is_dark: current_is_dark,
        ),
      );
    },
  );
}
