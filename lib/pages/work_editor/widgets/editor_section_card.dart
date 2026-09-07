// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/interest_preference/style.dart';
import 'package:flutter/material.dart';

/// TODO 作品编辑页的表单区块标题组件。
///
/// 设计规范（与步骤2统一）：
/// - 大标题 24px，字重 w500
/// - 副标题 13px，字重 w400
/// - 无图标、无外框、无阴影
/// - 左对齐，简洁清爽
class EditorSectionCard extends StatelessWidget {
  /// TODO 区块标题。
  final String title;

  /// TODO 区块说明。
  final String subtitle;

  /// TODO 区块图标（保留参数兼容，但不使用）。
  final IconData? icon;

  /// TODO 区块 SVG 图标名称（保留参数兼容，但不使用）。
  final String? iconSvgName;

  /// TODO SVG 图标颜色（保留参数兼容，但不使用）。
  final Color? iconColor;

  /// TODO 区块正文。
  final Widget child;

  /// TODO 当前是否夜间主题。
  final bool is_dark;

  const EditorSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconSvgName,
    this.iconColor,
    required this.child,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 标题区域（与步骤2统一）。
        _build_title_section(),

        /// 正文内容。
        child,
      ],
    );
  }

  /// TODO 构建标题区域。
  Widget _build_title_section() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: InterestPreferenceStyle.titleFontSize,
              fontWeight: InterestPreferenceStyle.titleFontWeight,
              color: AuthorStyle.primary_text(is_dark),
              height: 1.3,
            ),
          ),
          const SizedBox(height: InterestPreferenceStyle.titleBottomSpacing),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: InterestPreferenceStyle.subtitleFontSize,
              fontWeight: InterestPreferenceStyle.subtitleFontWeight,
              color: AuthorStyle.secondary_text(is_dark),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
