import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/util/language_util/index.dart';

import 'style.dart';

/// 长篇阅读页"看视频免广告"提示组件。
///
/// 用于在广告下方或章节末尾展示一行居中的可点击提示文字，
/// 引导用户观看视频以获得 30 分钟免广告时长。
class AdFreeTimeHint extends StatelessWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击提示文字的回调。
  final VoidCallback? on_tap;

  /// 免广告到期时间。
  ///
  /// 非空时展示“免广告至……· 再看一个，续30分钟”。
  final DateTime? expire_time;

  const AdFreeTimeHint({
    super.key,
    required this.is_dark,
    this.expire_time,
    this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    final String language_code = Localizations.localeOf(context).languageCode;
    final bool is_cjk = LanguageUtil.is_cjk_language(language_code);
    final String hint_text = expire_time == null
        ? easy.tr('read.watch_video_ad_hint')
        : easy.tr(
            'read.ad_free_until_continue',
            args: <String>[_format_expire_time(context, expire_time!)],
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdFreeTimeHintStyle.horizontal_padding,
        AdFreeTimeHintStyle.top_spacing,
        AdFreeTimeHintStyle.horizontal_padding,
        AdFreeTimeHintStyle.bottom_spacing,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: on_tap,
        child: Center(
          child: Text(
            hint_text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: is_cjk
                  ? AdFreeTimeHintStyle.font_size_cjk
                  : AdFreeTimeHintStyle.font_size_alphabetic,
              fontWeight: AdFreeTimeHintStyle.font_weight,
              color: is_dark
                  ? AdFreeTimeHintStyle.text_color_dark
                  : AdFreeTimeHintStyle.text_color_light,
            ),
          ),
        ),
      ),
    );
  }

  /// 格式化到期时间为简洁形式。
  ///
  /// 今天：只显示时间（如 23:59）
  /// 明天：显示"明天 23:59"
  /// 更晚：显示"8/31 23:59"
  String _format_expire_time(BuildContext context, DateTime expire_time) {
    final DateTime local = expire_time.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    final DateTime expire_date = DateTime(local.year, local.month, local.day);

    final bool use_24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final String time_text = use_24h
        ? '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}'
        : '${local.hour > 12 ? local.hour - 12 : local.hour == 0 ? 12 : local.hour}:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}';

    if (expire_date == today) return time_text;
    if (expire_date == tomorrow) {
      return easy.tr('read.ad_free_tomorrow', args: <String>[time_text]);
    }
    return '${local.month}/${local.day} $time_text';
  }
}

/// 单个章节底部的免广告状态插槽。
///
/// 插槽在章节创建时始终存在，免广告状态异步到达或叠加后，
/// 只重建当前插槽就能立即显示截止时间和续时入口。
class AdFreeTimeHintSlot extends StatelessWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 免广告截止时间监听器。
  final ValueListenable<DateTime?> expire_time_listenable;

  /// 未处于免广告期时，是否显示原有的30分钟视频入口。
  final bool show_inactive_hint;

  /// 点击观看激励视频的回调。
  final VoidCallback? on_tap;

  const AdFreeTimeHintSlot({
    super.key,
    required this.is_dark,
    required this.expire_time_listenable,
    required this.show_inactive_hint,
    this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: expire_time_listenable,
      builder: (BuildContext context, DateTime? expire_time, Widget? child) {
        final bool is_ad_free_active =
            expire_time != null && expire_time.isAfter(DateTime.now());
        if (!is_ad_free_active && !show_inactive_hint) {
          return const SizedBox.shrink();
        }
        return AdFreeTimeHint(
          is_dark: is_dark,
          expire_time: is_ad_free_active ? expire_time : null,
          on_tap: on_tap,
        );
      },
    );
  }
}
