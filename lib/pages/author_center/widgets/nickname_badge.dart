// ignore_for_file: non_constant_identifier_names

import 'dart:math';

import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// TODO 用户昵称胶囊组件。
///
/// 用于导航栏显示用户头像和昵称。
/// 样式：主题色背景 + 黑色文字 + 头像/随机默认头像。
///
/// 头像规则（与 user_info 页面一致）：
/// - 有头像 URL 时显示网络头像
/// - 无头像时从 avatar_00 ~ avatar_09 随机选一个 SVG 图标
class NicknameBadge extends StatelessWidget {
  /// TODO 用户昵称。
  final String nickname;

  /// TODO 用户头像 URL（为空时使用随机默认头像）。
  final String? avatar_url;

  /// TODO 当前是否夜间主题。
  final bool is_dark;

  /// TODO 是否为 CJK 语系。
  final bool is_cjk;

  /// TODO 随机头像索引（首次创建时随机确定，保持一致）。
  final int random_avatar_index;

  const NicknameBadge({
    super.key,
    required this.nickname,
    required this.is_dark,
    required this.is_cjk,
    this.avatar_url,
    this.random_avatar_index = 0,
  });

  /// TODO 生成随机头像索引（0-9）。
  static int generate_random_index() {
    return Random().nextInt(10);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ColorConstants.themeColor,
        borderRadius: BorderRadius.circular(AuthorStyle.pill_radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _build_avatar(),
          const SizedBox(width: 5),
          Text(
            nickname,
            style: TextStyle(
              color: ColorConstants.lightTextColor,
              fontSize: is_cjk ? 12 : 11,
              fontWeight: AuthorStyle.emphasis_weight,
            ),
          ),
        ],
      ),
    );
  }

  /// TODO 构建头像组件。
  Widget _build_avatar() {
    final bool has_avatar = avatar_url != null && avatar_url!.isNotEmpty;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: has_avatar
            ? Colors.transparent
            : ColorConstants.lightTextColor.withValues(alpha: 0.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: has_avatar
          ? CachedNetworkImage(
              imageUrl: avatar_url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _build_default_avatar(),
              errorWidget: (_, __, ___) => _build_default_avatar(),
            )
          : _build_default_avatar(),
    );
  }

  /// TODO 构建默认随机头像。
  Widget _build_default_avatar() {
    final String avatar_name =
        'avatar_${random_avatar_index.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.all(2),
      child: SvgIcon(
        name: avatar_name,
        width: 16,
        height: 16,
      ),
    );
  }
}
