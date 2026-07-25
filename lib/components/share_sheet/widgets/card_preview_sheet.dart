import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart' hide Trans;
import 'package:app/models/rotation.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/stores/share_store.dart';
import 'package:app/components/share_sheet/style.dart';
import 'package:app/components/share_sheet/widgets/share_poster_card.dart';
import 'package:app/components/share_sheet/widgets/share_icon_item.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

/// 卡片预览弹窗组件。
///
/// 从底部弹出，展示可分享的小说卡片。
/// 支持左右滑动切换卡片底色，底部有分享图标和「保存到相册」按钮。
///
/// 参数：
/// - [novel_id] 小说ID。
/// - [novel_title] 小说标题。
/// - [novel_cover_url] 小说封面图地址。
/// - [novel_intro] 小说简介。
/// - [is_dark] 当前是否为夜间模式。
class CardPreviewSheet extends StatefulWidget {
  /// 小说ID。
  final int novel_id;

  /// 小说标题。
  final String novel_title;

  /// 小说作者名称。
  final String novel_author;

  /// 小说封面图地址。
  final String novel_cover_url;

  /// 小说简介。
  final String novel_intro;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const CardPreviewSheet({
    super.key,
    required this.novel_id,
    required this.novel_title,
    this.novel_author = '',
    required this.novel_cover_url,
    required this.novel_intro,
    required this.is_dark,
  });

  @override
  State<CardPreviewSheet> createState() => _CardPreviewSheetState();
}

class _CardPreviewSheetState extends State<CardPreviewSheet> {
  /// 分享渠道全局状态。
  final ShareStore _share_store = Get.find<ShareStore>();

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
    _loadUserInfo();
  }

  @override
  void dispose() {
    _page_controller.dispose();
    super.dispose();
  }

  /// 加载用户信息。
  void _loadUserInfo() {
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
    /// 背景色。
    final Color background_color = widget.is_dark
        ? ShareSheetStyle.background_color_dark
        : ShareSheetStyle.background_color_light;

    /// 标题颜色。
    final Color title_color = widget.is_dark
        ? ShareSheetStyle.title_color_dark
        : ShareSheetStyle.title_color_light;

    /// 拖拽指示条颜色。
    final Color drag_bar_color = widget.is_dark
        ? ShareSheetStyle.drag_bar_color_dark
        : ShareSheetStyle.drag_bar_color_light;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: background_color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ShareSheetStyle.border_radius_top),
          topRight: Radius.circular(ShareSheetStyle.border_radius_top),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// 顶部拖拽指示条。
          _buildDragBar(drag_bar_color),

          /// 标题「卡片预览」。
          _buildTitle(title_color),

          /// 卡片预览区域（可滑动切换底色）。
          Expanded(child: _buildCardPager()),

          /// 底部指示器。
          _buildIndicator(),

          /// 底部操作栏（分享图标 + 保存按钮）。
          _buildBottomActionBar(),

          /// 底部安全区域。
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  /// 构建顶部拖拽指示条。
  Widget _buildDragBar(Color color) {
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
  Widget _buildTitle(Color title_color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
  ///
  /// 海报使用固定设计尺寸渲染，再根据可用空间等比缩放。这样小屏设备不会
  /// 溢出，导出图片的排版和清晰度也不会随手机尺寸变化。
  Widget _buildCardPager() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double design_width = ShareSheetStyle.poster_design_width;
        const double design_height = ShareSheetStyle.poster_design_height;
        const double horizontal_padding =
            ShareSheetStyle.preview_card_horizontal_padding;
        final double available_width = max(
          0,
          constraints.maxWidth - horizontal_padding * 2,
        );
        final double available_height = min(
          constraints.maxHeight,
          ShareSheetStyle.poster_preview_max_height,
        );

        double preview_width = min(design_width, available_width);
        double preview_height = preview_width / (design_width / design_height);
        if (preview_height > available_height) {
          preview_height = available_height;
          preview_width = preview_height * (design_width / design_height);
        }

        return PageView.builder(
          controller: _page_controller,
          itemCount: _gradient_colors.length,
          onPageChanged: (int index) {
            setState(() {
              _current_color_index = index;
            });
          },
          itemBuilder: (BuildContext context, int index) {
            return Center(
              child: SizedBox(
                width: preview_width,
                height: preview_height,
                child: FittedBox(fit: BoxFit.contain, child: _buildCard(index)),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建一张固定设计尺寸的分享海报。
  Widget _buildCard(int color_index) {
    return RepaintBoundary(
      key: _card_keys[color_index],
      child: SharePosterCard(
        novel_id: widget.novel_id,
        novel_title: widget.novel_title,
        novel_author: widget.novel_author,
        novel_cover_url: widget.novel_cover_url,
        novel_intro: widget.novel_intro,
        user_avatar_url: _user_avatar_url,
        user_nickname: _user_nickname,
        date_text: _formatDate(DateTime.now()),
        fallback_avatar_index: _random_avatar_index,
        canvas_colors: _gradient_colors[color_index],
        accent_color: ShareSheetStyle.card_accent_colors[color_index],
        footer_color: ShareSheetStyle.card_footer_colors[color_index],
        use_dark_palette: color_index == ShareSheetStyle.card_dark_style_index,
      ),
    );
  }

  /// 将日期格式化为稳定的海报展示文本，避免受系统地区格式影响。
  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }

  /// 构建与海报配色一致的色板指示器。
  Widget _buildIndicator() {
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
            key: ValueKey<String>('share_color_indicator_$index'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _onColorIndicatorTap(index),
            child: SizedBox(
              width:
                  ShareSheetStyle.indicator_slot_size +
                  ShareSheetStyle.indicator_spacing,
              height: ShareSheetStyle.indicator_slot_size,
              child: Center(
                child: AnimatedContainer(
                  key: ValueKey<String>('share_color_indicator_dot_$index'),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: is_active
                      ? ShareSheetStyle.indicator_active_width
                      : ShareSheetStyle.indicator_size,
                  height: is_active
                      ? ShareSheetStyle.indicator_active_width
                      : ShareSheetStyle.indicator_size,
                  padding: EdgeInsets.all(is_active ? 3 : 0),
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
  void _onColorIndicatorTap(int index) {
    if (index == _current_color_index || !_page_controller.hasClients) return;

    _page_controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// 构建底部操作栏（分享图标 + 保存到相册）。
  ///
  /// 分享图标从 ShareStore 动态读取，使用 represent 字段加载本地 SVG 图标。
  /// 竖屏一行4个，横屏一行6个，宽度平分，内容居中。
  /// 第二行不足时靠左对齐。
  Widget _buildBottomActionBar() {
    // TODO 底部操作栏水平内边距，与卡片预览的左右间距保持一致
    const double action_bar_horizontal_padding =
        ShareSheetStyle.preview_card_horizontal_padding;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: action_bar_horizontal_padding),
      child: Column(
        children: <Widget>[
          /// 分享图标网格（从 ShareStore 动态读取）。
          Obx(() {
            final List<Rotation> share_list = _share_store.rotation_list;

            // TODO 根据屏幕方向决定每行图标数量
            final bool is_landscape =
                MediaQuery.of(context).orientation == Orientation.landscape;
            final int cross_axis_count = is_landscape ? 6 : 4;

            return _buildShareIconGrid(share_list, cross_axis_count);
          }),

          /// 间距。
          const SizedBox(height: 16),

          /// 保存到相册按钮。
          _buildSaveButton(),

          /// 底部安全区域。
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  /// 构建分享图标网格。
  ///
  /// [share_list] 分享渠道列表。
  /// [cross_axis_count] 每行显示的图标数量。
  Widget _buildShareIconGrid(List<Rotation> share_list, int cross_axis_count) {
    // TODO 计算行数
    final int row_count = (share_list.length / cross_axis_count).ceil();

    return Column(
      children: List.generate(row_count, (int row_index) {
        final int start_index = row_index * cross_axis_count;
        final int end_index = (start_index + cross_axis_count).clamp(
          0,
          share_list.length,
        );
        final List<Rotation> row_items = share_list.sublist(
          start_index,
          end_index,
        );
        final bool is_last_row = row_index == row_count - 1;

        return Column(
          children: [
            // TODO 最后一行且不足时，靠左对齐并用空位填充
            if (is_last_row && row_items.length < cross_axis_count)
              Row(
                children: [
                  ...row_items.map(
                    (Rotation item) =>
                        Expanded(child: _buildShareIconItem(item)),
                  ),
                  // TODO 空位填充，保持宽度均分
                  ...List.generate(
                    cross_axis_count - row_items.length,
                    (_) => const Expanded(child: SizedBox()),
                  ),
                ],
              )
            else
              // TODO 完整行，宽度均分
              Row(
                children: row_items
                    .map(
                      (Rotation item) =>
                          Expanded(child: _buildShareIconItem(item)),
                    )
                    .toList(),
              ),

            // TODO 行间距（最后一行不添加）
            if (!is_last_row) const SizedBox(height: 15),
          ],
        );
      }),
    );
  }

  /// 构建单个分享图标项。
  Widget _buildShareIconItem(Rotation item) {
    return ShareIconItem(
      icon: null,
      icon_widget: SvgIcon(
        name: item.represent,
        width: ShareSheetStyle.icon_inner_size,
        height: ShareSheetStyle.icon_inner_size,
        color: widget.is_dark ? Colors.white : null,
      ),
      label: item.title,
      icon_color: widget.is_dark ? Colors.white : Colors.black,
      is_dark: widget.is_dark,
      on_tap: () {
        // TODO 对接真实分享：使用 item.jump 作为分享链接
      },
    );
  }

  /// 构建「保存到相册」按钮。
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _is_saving ? null : _onSaveToAlbum,
      child: Container(
        width: double.infinity,
        height: ShareSheetStyle.save_button_height,
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
                    const SizedBox(width: 8),
                    Text(
                      easy.tr('share_sheet.save_to_album'),
                      style: TextStyle(
                        fontSize: ShareSheetStyle.save_button_font_size,
                        fontWeight: ShareSheetStyle.save_button_font_weight,
                        color: ShareSheetStyle.save_button_text_color,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 将卡片捕获为图片并保存到相册。
  ///
  /// 使用 RepaintBoundary 将当前选中的卡片渲染为 PNG 图片，
  /// 然后保存到设备相册。
  Future<void> _onSaveToAlbum() async {
    if (_is_saving) return;

    setState(() {
      _is_saving = true;
    });

    try {
      if (kIsWeb) {
        showBottomTip(easy.tr('share_sheet.save_failed'));
        return;
      }

      /// 先请求系统相册的新增权限。用户拒绝时不继续执行耗时截图。
      final bool has_access =
          await Gal.hasAccess() || await Gal.requestAccess();
      if (!has_access) {
        showBottomTip(easy.tr('share_sheet.photo_permission_denied'));
        return;
      }

      /// 等待当前色板页面完成绘制，确保网络图已加载到的最新画面被捕获。
      await WidgetsBinding.instance.endOfFrame;

      /// 只查找当前海报的边界，不会包含弹窗标题、色板或底部操作区。
      final RenderRepaintBoundary? boundary =
          _card_keys[_current_color_index].currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        showBottomTip(easy.tr('share_sheet.save_failed'));
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byte_data;
      try {
        byte_data = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }

      if (byte_data == null) {
        showBottomTip(easy.tr('share_sheet.save_failed'));
        return;
      }

      final Uint8List png_bytes = byte_data.buffer.asUint8List();
      final String image_name =
          'topread_${widget.novel_id}_${DateTime.now().millisecondsSinceEpoch}';
      await Gal.putImageBytes(png_bytes, name: image_name);
      showBottomTip(easy.tr('share_sheet.save_success'));
    } on GalException catch (error) {
      final String message_key = error.type == GalExceptionType.accessDenied
          ? 'share_sheet.photo_permission_denied'
          : 'share_sheet.save_failed';
      showBottomTip(easy.tr(message_key));
    } catch (_) {
      showBottomTip(easy.tr('share_sheet.save_failed'));
    } finally {
      if (mounted) {
        setState(() {
          _is_saving = false;
        });
      }
    }
  }
}

/// 显示卡片预览弹窗的便捷方法。
///
/// 参数：
/// - [context] BuildContext。
/// - [novel_id] 小说ID。
/// - [novel_title] 小说标题。
/// - [novel_author] 小说作者名称。
/// - [novel_cover_url] 小说封面图地址。
/// - [novel_intro] 小说简介。
/// - [is_dark] 当前是否为夜间模式，不传则自动根据主题判断。
void showCardPreviewSheet({
  required BuildContext context,
  required int novel_id,
  required String novel_title,
  String novel_author = '',
  required String novel_cover_url,
  required String novel_intro,
  bool? is_dark,
}) {
  /// 是否为夜间模式。
  final bool current_is_dark =
      is_dark ?? Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return CardPreviewSheet(
        novel_id: novel_id,
        novel_title: novel_title,
        novel_author: novel_author,
        novel_cover_url: novel_cover_url,
        novel_intro: novel_intro,
        is_dark: current_is_dark,
      );
    },
  );
}
