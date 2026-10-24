// ignore_for_file: non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/mine/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 作品状态角标：草稿 / 审核中 / 已发布 / 已驳回 / 已隐藏。
///
/// 语义色由 [ComicsMineStatusStyle] 统一管理，字阶与内边距按语种自适应。
class ComicsStatusBadge extends StatelessWidget {
  /// 后端状态字符串：draft / pending / published / rejected / hidden。
  final String status;

  /// 是否处于夜间主题（用于文字对比微调）。
  final bool is_dark;

  const ComicsStatusBadge({
    super.key,
    required this.status,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    /// 当前语种是否 CJK，决定角标内边距。
    final bool is_cjk = ComicsStyle.is_cjk(context);

    /// 状态语义色。
    final Color color = ComicsMineStatusStyle.of(context, status);

    /// 胶囊底色：语义色以固定不透明度叠在半透明白底上，压在封面渐变上仍可读。
    final Color background = color.withValues(
      alpha: ComicsMineStyle.status_background_opacity,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: is_cjk
            ? ComicsMineStatusStyle.badge_padding_h_cjk
            : ComicsMineStatusStyle.badge_padding_h_alphabetic,
        vertical: ComicsMineStatusStyle.badge_padding_v,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ComicsMineStatusStyle.badge_radius),
      ),
      child: Text(
        _label(context),
        style: TextStyle(
          color: ColorConstants.whiteColor,
          fontSize: ComicsMineStatusStyle.badge_font_size,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          letterSpacing: is_cjk ? null : 0.2,
        ),
      ),
    );
  }

  /// 状态文案映射到 i18n。
  String _label(BuildContext context) {
    switch (status) {
      case 'pending':
        return tr('comics.status_pending');
      case 'published':
        return tr('comics.status_published');
      case 'rejected':
        return tr('comics.status_rejected');
      case 'hidden':
        return tr('comics.status_hidden');
      default:
        return tr('comics.status_draft');
    }
  }
}
