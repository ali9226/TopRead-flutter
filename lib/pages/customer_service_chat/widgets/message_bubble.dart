// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/util/utc_time_util.dart';
import '../style.dart';

/// 聊天气泡组件。
///
/// 文字/表情：圆角矩形气泡 + 箭头
/// 图片：无气泡框，直接展示图片 + 圆角，上传中时显示遮罩进度
class MessageBubble extends StatelessWidget {
  final bool is_admin;
  final int message_type; // 1=文字 2=表情 3=图片
  final String content;
  final String server_content;
  final String create_time;
  final bool is_dark;
  final String sender_name;
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

  /// 计算气泡最大宽度。
  ///
  /// 公式：屏幕宽度 - 头像 - 箭头 - 左右间距 - 额外留白
  static double calc_max_width(double screen_width) {
    return screen_width -
        CustomerServiceChatStyle
            .avatar_size // 头像宽度
            -
        CustomerServiceChatStyle
            .bubble_arrow_width // 箭头宽度
            -
        (CustomerServiceChatStyle.avatar_bubble_spacing * 2) // 左右间距
        -
        CustomerServiceChatStyle.bubble_extra_padding; // 额外留白
  }

  @override
  Widget build(BuildContext context) {
    final double screen_width = MediaQuery.of(context).size.width;
    final double max_width = calc_max_width(screen_width);

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
    final String formatted_time = format_message_local_time(create_time);

    // 图片消息：不使用气泡框，直接展示图片
    if (message_type == 3) {
      return _build_image_bubble(formatted_time);
    }

    // 文字/表情消息：带气泡框和箭头
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (is_admin) ...[_build_arrow(bubble_bg, true)],
        Container(
          constraints: BoxConstraints(maxWidth: max_width),
          decoration: BoxDecoration(
            color: bubble_bg,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: is_admin
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: <Widget>[
              _build_content(text_color),
              if (formatted_time.isNotEmpty) ...<Widget>[
                const SizedBox(
                  height: CustomerServiceChatStyle.message_time_spacing,
                ),
                _build_time_text(formatted_time, text_color),
              ],
            ],
          ),
        ),
        if (!is_admin) ...[_build_arrow(bubble_bg, false)],
      ],
    );
  }

  /// 构建气泡箭头。
  Widget _build_arrow(Color color, bool point_right) {
    return Transform.translate(
      offset: Offset(point_right ? 1 : -1, 0),
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: CustomPaint(
          size: const Size(
            CustomerServiceChatStyle.bubble_arrow_width,
            CustomerServiceChatStyle.bubble_arrow_height,
          ),
          painter: _ArrowPainter(color: color, point_right: point_right),
        ),
      ),
    );
  }

  /// 构建图片气泡（无边框，直接展示图片）。
  Widget _build_image_bubble(String formatted_time) {
    final double max_size = 180;
    final String remote_url = server_content.isNotEmpty
        ? server_content
        : (_is_network_url(content) ? content : '');
    final String local_path = _is_network_url(content) ? '' : content;
    final Widget image_widget = remote_url.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: remote_url,
            width: max_size,
            height: max_size,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            useOldImageOnUrlChange: true,
            placeholder: (_, _) => _build_local_image(local_path, max_size),
            errorWidget: (_, _, _) => _build_local_image(local_path, max_size),
          )
        : _build_local_image(local_path, max_size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: <Widget>[
          image_widget,
          // 上传中遮罩
          if (is_uploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          if (formatted_time.isNotEmpty)
            Positioned(
              right: CustomerServiceChatStyle.image_time_inset,
              bottom: CustomerServiceChatStyle.image_time_inset,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CustomerServiceChatStyle.image_time_padding_h,
                  vertical: CustomerServiceChatStyle.image_time_padding_v,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(
                    CustomerServiceChatStyle.image_time_radius,
                  ),
                ),
                child: Text(
                  formatted_time,
                  style: TextStyle(
                    fontSize: CustomerServiceChatStyle.message_time_font_size,
                    fontWeight:
                        CustomerServiceChatStyle.message_time_font_weight,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// TODO 构建上传期间和网络图加载期间的本地预览。
  Widget _build_local_image(String local_path, double size) {
    if (local_path.isEmpty || !File(local_path).existsSync()) {
      return _build_image_error(size);
    }

    return Image.file(
      File(local_path),
      width: size,
      height: size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _build_image_error(size),
    );
  }

  /// TODO 判断图片内容是否为可加载的 HTTP(S) 地址。
  bool _is_network_url(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// 构建文字和表情气泡内的本地时间。
  Widget _build_time_text(String formatted_time, Color text_color) {
    return Text(
      formatted_time,
      style: TextStyle(
        fontSize: CustomerServiceChatStyle.message_time_font_size,
        fontWeight: CustomerServiceChatStyle.message_time_font_weight,
        color: text_color.withValues(alpha: 0.58),
        height: 1,
      ),
    );
  }

  /// 构建图片加载失败占位。
  Widget _build_image_error(double size) {
    return Container(
      width: size,
      height: size,
      color: is_dark
          ? CustomerServiceChatStyle.bubble_admin_bg_dark
          : CustomerServiceChatStyle.bubble_admin_bg_light,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: CustomerServiceChatStyle.empty_text_color,
          size: 32,
        ),
      ),
    );
  }

  /// 构建消息内容。
  Widget _build_content(Color text_color) {
    switch (message_type) {
      case 2:
        return SelectableText(
          content,
          cursorColor: ColorConstants.themeColor,
          style: const TextStyle(fontSize: 36),
        );
      default:
        return SelectableText(
          content,
          cursorColor: ColorConstants.themeColor,
          style: TextStyle(
            fontSize: CustomerServiceChatStyle.message_font_size,
            fontWeight: CustomerServiceChatStyle.message_font_weight,
            color: text_color,
            height: 1.3,
          ),
        );
    }
  }
}

/// 圆角三角形箭头绘制器。
class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool point_right;

  _ArrowPainter({required this.color, required this.point_right});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    final double cr = CustomerServiceChatStyle.bubble_arrow_corner_radius;

    final Path path = Path();

    if (point_right) {
      final Offset top = Offset(w, 0);
      final Offset tip = Offset(0, h / 2);
      final Offset bottom = Offset(w, h);
      _rounded_triangle(path, top, tip, bottom, cr);
    } else {
      final Offset top = Offset(0, 0);
      final Offset tip = Offset(w, h / 2);
      final Offset bottom = Offset(0, h);
      _rounded_triangle(path, top, tip, bottom, cr);
    }

    canvas.drawPath(path, paint);
  }

  /// 绘制三角形，只有箭头尖角（b点）有圆角，另外两个角是直角。
  void _rounded_triangle(Path path, Offset a, Offset b, Offset c, double r) {
    final Offset ba = a - b;
    final Offset bc = c - b;
    final Offset ba_n = ba / ba.distance;
    final Offset bc_n = bc / bc.distance;
    final Offset b_to_a = b + ba_n * r;
    final Offset b_to_c = b + bc_n * r;

    path.moveTo(a.dx, a.dy);
    path.lineTo(b_to_a.dx, b_to_a.dy);
    path.arcToPoint(b_to_c, radius: Radius.circular(r), clockwise: false);
    path.lineTo(c.dx, c.dy);
    path.close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
