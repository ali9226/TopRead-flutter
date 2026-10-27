// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/search/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 空结果与请求失败分别展示；部分失败仍保留已成功返回的作品和重试入口。
class SearchResultFeedback extends StatelessWidget {
  const SearchResultFeedback({
    super.key,
    required this.is_dark,
    required this.has_error,
    required this.on_retry,
    this.compact = false,
  });

  final bool is_dark;
  final bool has_error;
  final VoidCallback on_retry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final color = is_dark
        ? ColorConstants.whiteColor.withValues(
            alpha: Style.secondary_text_dark_alpha,
          )
        : ColorConstants.hintColor;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact
            ? Style.feedback_compact_padding
            : Style.feedback_padding,
      ),
      child: Column(
        children: [
          if (!compact) ...[
            Icon(
              has_error ? Icons.wifi_off_rounded : Icons.search_off_rounded,
              size: Style.feedback_icon_size,
              color: color,
            ),
            const SizedBox(height: Style.feedback_gap),
          ],
          Text(
            tr(has_error ? 'search.load_failed' : 'search.empty_result'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: cjk
                  ? Style.feedback_size_cjk
                  : Style.feedback_size_alphabetic,
              height: cjk
                  ? Style.feedback_line_height_cjk
                  : Style.feedback_line_height_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
          if (has_error)
            TextButton(
              onPressed: on_retry,
              style: TextButton.styleFrom(
                foregroundColor: is_dark
                    ? ColorConstants.whiteColor
                    : ColorConstants.lightTextColor,
              ),
              child: Text(
                tr('search.retry'),
                style: TextStyle(
                  fontSize: cjk
                      ? Style.feedback_size_cjk
                      : Style.feedback_size_alphabetic,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
