import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/pages/short_story_read/style.dart';
import 'package:app/config/font_config.dart';

/// 错误状态组件。
///
/// 当内容加载失败时展示，包含错误图标、提示文案和重试按钮。
/// 支持日间/夜间主题切换。
class ErrorState extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 重试按钮点击回调。
  final VoidCallback on_retry;

  const ErrorState({
    super.key,
    required this.is_dark,
    required this.on_retry,
  });

  @override
  Widget build(BuildContext context) {
    /// 主文字颜色（错误标题）。
    final Color text_color = is_dark
        ? ShortStoryReadStyle.body_dark_color
        : ShortStoryReadStyle.body_light_color;

    /// 次要文字颜色（错误描述）。
    final Color secondary_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 重试按钮背景色（使用标签色系）。
    final Color button_color = is_dark
        ? ShortStoryReadStyle.tag_dark_color
        : ShortStoryReadStyle.tag_light_color;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          /// 错误图标。
          Icon(
            Icons.error_outline,
            size: 64,
            color: secondary_color,
          ),
          const SizedBox(height: 16),

          /// 错误标题（国际化）。
          Text(
            tr('short_story_read.load_failed'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: text_color,
            ),
          ),
          const SizedBox(height: 8),

          /// 错误描述（国际化）。
          Text(
            tr('short_story_read.load_failed_hint'),
            style: TextStyle(
              fontSize: 14,
              color: secondary_color,
            ),
          ),
          const SizedBox(height: 24),

          /// 重试按钮（胶囊形状）。
          ElevatedButton(
            onPressed: on_retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: button_color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              tr('short_story_read.retry'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
