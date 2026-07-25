import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app/models/rotation.dart';
import 'package:app/stores/share_store.dart';
import 'package:app/components/share_sheet/style.dart';
import 'package:app/components/share_sheet/widgets/share_icon_item.dart';
import 'package:app/components/share_sheet/widgets/card_preview_sheet.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

/// 分享弹窗组件。
///
/// 从屏幕底部弹出的分享面板，展示分享渠道图标行。
/// 第一个固定为「生成图片」，其余渠道从 ShareStore（redis/get type=24）动态读取，
/// 最后一个固定为「复制链接」。
///
/// 使用方式：
/// ```dart
/// showShareSheet(
///   context: context,
///   novel_id: 123,
///   novel_title: "小说标题",
///   novel_cover_url: "https://...",
///   novel_intro: "小说简介...",
/// );
/// ```
class ShareSheet extends StatelessWidget {
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

  /// 关闭弹窗回调。
  final VoidCallback on_close;

  /// 分享渠道全局状态。
  final ShareStore _share_store = Get.find<ShareStore>();

  ShareSheet({
    super.key,
    required this.novel_id,
    required this.novel_title,
    this.novel_author = '',
    required this.novel_cover_url,
    required this.novel_intro,
    required this.is_dark,
    required this.on_close,
  });

  @override
  Widget build(BuildContext context) {
    /// 背景色。
    final Color background_color = is_dark
        ? ShareSheetStyle.background_color_dark
        : ShareSheetStyle.background_color_light;

    /// 标题颜色。
    final Color title_color = is_dark
        ? ShareSheetStyle.title_color_dark
        : ShareSheetStyle.title_color_light;

    /// 拖拽指示条颜色。
    final Color drag_bar_color = is_dark
        ? ShareSheetStyle.drag_bar_color_dark
        : ShareSheetStyle.drag_bar_color_light;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background_color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ShareSheetStyle.border_radius_top),
          topRight: Radius.circular(ShareSheetStyle.border_radius_top),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// 顶部拖拽指示条。
          _buildDragBar(drag_bar_color),

          /// 标题「分享」。
          _buildTitle(title_color),

          /// 分享渠道图标行（动态数据）。
          _buildShareIconRow(context),

          /// 底部安全区域。
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  /// 构建顶部拖拽指示条。
  Widget _buildDragBar(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Container(
          width: ShareSheetStyle.drag_bar_width,
          height: ShareSheetStyle.drag_bar_height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              ShareSheetStyle.drag_bar_radius,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建弹窗标题。
  Widget _buildTitle(Color title_color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        easy.tr('share_sheet.title'),
        style: TextStyle(
          fontSize: ShareSheetStyle.title_font_size,
          fontWeight: ShareSheetStyle.title_font_weight,
          color: title_color,
        ),
      ),
    );
  }

  /// 构建分享渠道图标行。
  ///
  /// 布局顺序：生成图片 + 接口返回的分享渠道 + 复制链接。
  /// 竖屏（宽 < 高）时一行 4 个，横屏时一行 6 个，图标平均分配宽度。
  /// 最后一行不满时靠左对齐。
  Widget _buildShareIconRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        /// 从 ShareStore 获取分享渠道列表。
        final List<Rotation> share_list = _share_store.rotation_list;

        /// 所有图标项。
        final List<Widget> items = <Widget>[
          /// 第一个固定：生成图片。
          ShareIconItem(
            icon: null,
            icon_widget: SvgIcon(
              name: 'image',
              width: ShareSheetStyle.icon_inner_size,
              height: ShareSheetStyle.icon_inner_size,
              color: is_dark ? Colors.white : null,
            ),
            label: easy.tr('share_sheet.generate_image'),
            icon_color: const Color(0xFF667EEA),
            is_dark: is_dark,
            on_tap: () => _onGenerateImage(context),
          ),

          /// 动态渲染接口返回的分享渠道。
          ...share_list.map((Rotation item) {
            return ShareIconItem(
              icon: null,
              icon_widget: SvgIcon(
                name: item.represent,
                width: ShareSheetStyle.icon_inner_size,
                height: ShareSheetStyle.icon_inner_size,
                color: is_dark ? Colors.white : null,
              ),
              label: item.title,
              icon_color: is_dark ? Colors.white : Colors.black,
              is_dark: is_dark,
              on_tap: () => _onShareToChannel(context, item),
            );
          }),

          /// 最后固定：复制链接。
          ShareIconItem(
            icon: null,
            icon_widget: SvgIcon(
              name: 'link',
              width: ShareSheetStyle.icon_inner_size,
              height: ShareSheetStyle.icon_inner_size,
              color: is_dark ? Colors.white : null,
            ),
            label: easy.tr('share_sheet.copy_link'),
            icon_color: const Color(0xFFFF8E53),
            is_dark: is_dark,
            on_tap: () => _onCopyLink(context),
          ),
        ];

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            /// 根据屏幕方向决定每行数量。
            final Size screenSize = MediaQuery.sizeOf(context);
            final int crossAxisCount = screenSize.width < screenSize.height
                ? 4
                : 6;

            /// 按每行数量分组，逐行渲染。
            final List<Widget> rows = <Widget>[];
            for (int i = 0; i < items.length; i += crossAxisCount) {
              final int rowEnd = (i + crossAxisCount).clamp(0, items.length);
              final List<Widget> rowItems = <Widget>[];

              /// 当前行的实际数量。
              final int currentRowCount = rowEnd - i;
              final bool isLastRowIncomplete =
                  currentRowCount < crossAxisCount &&
                  i + crossAxisCount >= items.length;

              for (int j = i; j < rowEnd; j++) {
                /// 最后一行不满时用固定宽度靠左，否则等分宽度。
                if (isLastRowIncomplete) {
                  rowItems.add(
                    SizedBox(
                      width: constraints.maxWidth / crossAxisCount,
                      child: items[j],
                    ),
                  );
                } else {
                  rowItems.add(Expanded(child: items[j]));
                }
              }

              rows.add(Row(children: rowItems));

              if (i + crossAxisCount < items.length) {
                rows.add(const SizedBox(height: 22));
              }
            }

            return Column(mainAxisSize: MainAxisSize.min, children: rows);
          },
        );
      }),
    );
  }

  /// 点击「生成图片」，打开卡片预览弹窗。
  ///
  /// 直接打开卡片预览弹窗，覆盖在分享弹窗之上。
  void _onGenerateImage(BuildContext context) {
    showCardPreviewSheet(
      context: context,
      novel_id: novel_id,
      novel_title: novel_title,
      novel_author: novel_author,
      novel_cover_url: novel_cover_url,
      novel_intro: novel_intro,
      is_dark: is_dark,
    );
  }

  /// 点击「复制链接」，将分享链接复制到剪贴板。
  void _onCopyLink(BuildContext context) {
    final String share_text = easy.tr(
      'share_sheet.share_text',
      namedArgs: {'app': 'Novel', 'title': novel_title},
    );
    Clipboard.setData(ClipboardData(text: share_text));
    showBottomTip(easy.tr('share_sheet.copy_success'));
    on_close();
  }

  /// 点击分享到指定渠道（占位，后续对接真实分享）。
  ///
  /// 参数 [item] 为 ShareStore 中对应的 Rotation 数据，
  /// 包含 title（渠道名称）、jump（跳转地址）等信息。
  void _onShareToChannel(BuildContext context, Rotation item) {
    // TODO 对接真实分享：使用 item.jump 作为分享链接
    on_close();
  }
}

/// 显示分享弹窗的便捷方法。
///
/// 参数：
/// - [context] BuildContext。
/// - [novel_id] 小说ID。
/// - [novel_title] 小说标题。
/// - [novel_author] 小说作者名称。
/// - [novel_cover_url] 小说封面图地址。
/// - [novel_intro] 小说简介。
/// - [is_dark] 当前是否为夜间模式，不传则自动根据主题判断。
void showShareSheet({
  required BuildContext context,
  required int novel_id,
  required String novel_title,
  String novel_author = '',
  required String novel_cover_url,
  required String novel_intro,
  bool? is_dark,
}) {
  /// 用户打开分享面板时提前缓存封面，进入图片预览后可直接绘制和导出。
  if (novel_cover_url.trim().isNotEmpty) {
    precacheImage(CachedNetworkImageProvider(novel_cover_url), context);
  }

  /// 是否为夜间模式。
  final bool current_is_dark =
      is_dark ?? Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return ShareSheet(
        novel_id: novel_id,
        novel_title: novel_title,
        novel_author: novel_author,
        novel_cover_url: novel_cover_url,
        novel_intro: novel_intro,
        is_dark: current_is_dark,
        on_close: () => Navigator.pop(ctx),
      );
    },
  );
}
