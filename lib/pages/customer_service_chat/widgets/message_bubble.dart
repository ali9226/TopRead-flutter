// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/utc_time_util.dart';
import '../style.dart';

/// 单条客服聊天消息气泡。
///
/// 文字气泡的主体与尾巴由同一个形状路径绘制，不会在缩放或高像素
/// 密度设备上出现接缝。图片保持原始宽高比，并限制解码及显示尺寸。
class MessageBubble extends StatelessWidget {
  /// 是否为客服发送的消息。
  final bool is_admin;

  /// 消息类型：1 文字、2 表情、3 图片。
  final int message_type;

  /// 本地内容或服务端文字内容。
  final String content;

  /// 图片上传完成后的服务端地址。
  final String server_content;

  /// 服务端 UTC 创建时间。
  final String create_time;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 发送方名称。
  final String sender_name;

  /// 图片是否正在上传。
  final bool is_uploading;

  const MessageBubble({
    super.key,
    required this.is_admin,
    required this.message_type,
    required this.content,
    required this.create_time,
    required this.is_dark,
    this.server_content = '',
    this.sender_name = '',
    this.is_uploading = false,
  });

  /// 根据屏幕宽度计算气泡最大宽度。
  static double calc_max_width(double screen_width) {
    return math.min(
      screen_width * CustomerServiceChatStyle.bubble_max_width_ratio,
      CustomerServiceChatStyle.bubble_max_width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screen_width = MediaQuery.sizeOf(context).width;
    final String formatted_time = format_message_local_time(create_time);

    if (message_type == 3) {
      return _build_image_bubble(context, formatted_time, screen_width);
    }

    final Color bubble_bg = is_admin
        ? (is_dark
              ? CustomerServiceChatStyle.bubble_admin_bg_dark
              : CustomerServiceChatStyle.bubble_admin_bg_light)
        : CustomerServiceChatStyle.bubble_user_bg;
    final Color text_color = is_admin
        ? (is_dark
              ? CustomerServiceChatStyle.bubble_admin_text_dark
              : CustomerServiceChatStyle.bubble_admin_text_light)
        : CustomerServiceChatStyle.bubble_user_text;
    final double tail_width = CustomerServiceChatStyle.bubble_arrow_width;

    return Container(
      constraints: BoxConstraints(maxWidth: calc_max_width(screen_width)),
      decoration: ShapeDecoration(
        color: bubble_bg,
        shape: _ChatBubbleShape(is_left: is_admin),
      ),
      padding: EdgeInsets.only(
        left:
            CustomerServiceChatStyle.bubble_padding_h +
            (is_admin ? tail_width : 0),
        top: CustomerServiceChatStyle.bubble_padding_v,
        right:
            CustomerServiceChatStyle.bubble_padding_h +
            (is_admin ? 0 : tail_width),
        bottom: CustomerServiceChatStyle.bubble_padding_v,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: is_admin
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: <Widget>[
          _build_content(context, text_color),
          if (formatted_time.isNotEmpty) ...<Widget>[
            const SizedBox(
              height: CustomerServiceChatStyle.message_time_spacing,
            ),
            _build_time_text(formatted_time, text_color),
          ],
        ],
      ),
    );
  }

  /// 构建保留原始比例的图片消息。
  Widget _build_image_bubble(
    BuildContext context,
    String formatted_time,
    double screen_width,
  ) {
    final double max_width = math.min(
      screen_width * CustomerServiceChatStyle.image_max_width_ratio,
      CustomerServiceChatStyle.image_max_width,
    );
    final double device_pixel_ratio = MediaQuery.devicePixelRatioOf(context);
    final int cache_width = (max_width * device_pixel_ratio).round();
    final String remote_url = server_content.isNotEmpty
        ? server_content
        : (_is_network_url(content) ? content : '');
    final String local_path = _is_network_url(content) ? '' : content;
    final Widget image_widget = remote_url.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: remote_url,
            fit: BoxFit.contain,
            memCacheWidth: cache_width,
            maxWidthDiskCache: cache_width,
            fadeInDuration: const Duration(milliseconds: 120),
            fadeOutDuration: Duration.zero,
            useOldImageOnUrlChange: true,
            placeholder: (_, _) => _build_local_image(local_path, cache_width),
            errorWidget: (_, _, _) =>
                _build_local_image(local_path, cache_width),
          )
        : _build_local_image(local_path, cache_width);

    return RepaintBoundary(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: max_width,
          maxHeight: CustomerServiceChatStyle.image_max_height,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            CustomerServiceChatStyle.image_radius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              image_widget,
              if (is_uploading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.38),
                    child: Center(
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
              if (formatted_time.isNotEmpty)
                Positioned(
                  right: CustomerServiceChatStyle.image_time_inset,
                  bottom: CustomerServiceChatStyle.image_time_inset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(
                        CustomerServiceChatStyle.image_time_radius,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal:
                            CustomerServiceChatStyle.image_time_padding_h,
                        vertical: CustomerServiceChatStyle.image_time_padding_v,
                      ),
                      child: Text(
                        formatted_time,
                        style: TextStyle(
                          fontSize:
                              CustomerServiceChatStyle.message_time_font_size,
                          fontWeight:
                              CustomerServiceChatStyle.message_time_font_weight,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建上传阶段的本地图片预览。
  ///
  /// 不在 build 阶段同步读取文件系统，文件不存在时由 Image 的异步
  /// 解码错误回调处理，避免快速滚动过程中阻塞 UI 线程。
  Widget _build_local_image(String local_path, int cache_width) {
    if (local_path.isEmpty) return _build_image_error();

    return Image.file(
      File(local_path),
      fit: BoxFit.contain,
      cacheWidth: cache_width,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _build_image_error(),
    );
  }

  /// 判断内容是否为可加载的 HTTP(S) 地址。
  bool _is_network_url(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// 构建气泡内的本地时间。
  Widget _build_time_text(String formatted_time, Color text_color) {
    return Text(
      formatted_time,
      style: TextStyle(
        fontSize: CustomerServiceChatStyle.message_time_font_size,
        fontWeight: CustomerServiceChatStyle.message_time_font_weight,
        color: text_color.withValues(alpha: 0.52),
        height: 1,
      ),
    );
  }

  /// 构建图片加载失败占位。
  Widget _build_image_error() {
    return SizedBox.square(
      dimension: CustomerServiceChatStyle.image_placeholder_size,
      child: ColoredBox(
        color: is_dark
            ? CustomerServiceChatStyle.bubble_admin_bg_dark
            : CustomerServiceChatStyle.bubble_admin_bg_light,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: CustomerServiceChatStyle.empty_text_color,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// 根据消息类型构建文字或大号表情。
  Widget _build_content(BuildContext context, Color text_color) {
    if (message_type == 2) {
      return SelectableText(
        content,
        cursorColor: ColorConstants.themeColor,
        style: const TextStyle(fontSize: 36, height: 1.15),
      );
    }

    final bool is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return SelectableText(
      content,
      cursorColor: ColorConstants.themeColor,
      style: TextStyle(
        fontSize: is_cjk
            ? CustomerServiceChatStyle.message_font_size_cjk
            : CustomerServiceChatStyle.message_font_size_alphabetic,
        fontWeight: CustomerServiceChatStyle.message_font_weight,
        color: text_color,
        height: is_cjk
            ? CustomerServiceChatStyle.message_line_height_cjk
            : CustomerServiceChatStyle.message_line_height_alphabetic,
      ),
    );
  }
}

/// 将气泡主体与左侧或右侧尾巴绘制为一个连续路径。
class _ChatBubbleShape extends ShapeBorder {
  /// 尾巴是否位于左侧。
  final bool is_left;

  const _ChatBubbleShape({required this.is_left});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double tail_width = CustomerServiceChatStyle.bubble_arrow_width;
    final double radius = math.min(
      CustomerServiceChatStyle.bubble_radius,
      rect.shortestSide / 2,
    );
    final double tail_top =
        rect.top + CustomerServiceChatStyle.bubble_arrow_top;
    final double tail_bottom =
        tail_top + CustomerServiceChatStyle.bubble_arrow_height;
    final double tail_tip_y = tail_top + 2;

    return is_left
        ? _build_left_path(
            rect,
            radius,
            tail_width,
            tail_top,
            tail_bottom,
            tail_tip_y,
          )
        : _build_right_path(
            rect,
            radius,
            tail_width,
            tail_top,
            tail_bottom,
            tail_tip_y,
          );
  }

  /// 构建尾巴朝向头像的左侧气泡。
  Path _build_left_path(
    Rect rect,
    double radius,
    double tail_width,
    double tail_top,
    double tail_bottom,
    double tail_tip_y,
  ) {
    final double body_left = rect.left + tail_width;
    return Path()
      ..moveTo(body_left + radius, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
      ..lineTo(rect.right, rect.bottom - radius)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - radius,
        rect.bottom,
      )
      ..lineTo(body_left + radius, rect.bottom)
      ..quadraticBezierTo(
        body_left,
        rect.bottom,
        body_left,
        rect.bottom - radius,
      )
      ..lineTo(body_left, tail_bottom)
      ..cubicTo(
        body_left - 1,
        tail_bottom - 2,
        rect.left + 1,
        tail_tip_y + 2,
        rect.left,
        tail_tip_y,
      )
      ..cubicTo(
        rect.left + 2,
        tail_tip_y - 1,
        body_left - 1,
        tail_top,
        body_left,
        tail_top,
      )
      ..lineTo(body_left, rect.top + radius)
      ..quadraticBezierTo(body_left, rect.top, body_left + radius, rect.top)
      ..close();
  }

  /// 构建尾巴朝向头像的右侧气泡。
  Path _build_right_path(
    Rect rect,
    double radius,
    double tail_width,
    double tail_top,
    double tail_bottom,
    double tail_tip_y,
  ) {
    final double body_right = rect.right - tail_width;
    return Path()
      ..moveTo(rect.left + radius, rect.top)
      ..lineTo(body_right - radius, rect.top)
      ..quadraticBezierTo(body_right, rect.top, body_right, rect.top + radius)
      ..lineTo(body_right, tail_top)
      ..cubicTo(
        body_right + 1,
        tail_top,
        rect.right - 2,
        tail_tip_y - 1,
        rect.right,
        tail_tip_y,
      )
      ..cubicTo(
        rect.right - 1,
        tail_tip_y + 2,
        body_right + 1,
        tail_bottom - 2,
        body_right,
        tail_bottom,
      )
      ..lineTo(body_right, rect.bottom - radius)
      ..quadraticBezierTo(
        body_right,
        rect.bottom,
        body_right - radius,
        rect.bottom,
      )
      ..lineTo(rect.left + radius, rect.bottom)
      ..quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left,
        rect.bottom - radius,
      )
      ..lineTo(rect.left, rect.top + radius)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
