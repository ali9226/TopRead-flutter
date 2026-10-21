// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/reader_theme_options/index.dart';
import 'package:app/components/reader_theme_transition/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/widgets/reading_panels/brightness_session.dart';
import 'package:app/pages/comics/reader/widgets/reading_panels/style.dart';
import 'package:app/pages/read/widgets/auto_read_settings_sheet/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

export 'brightness_session.dart';

bool _dark(BuildContext context) => Get.isRegistered<DeviceInfo>()
    ? Get.find<DeviceInfo>().theme.value == ThemeMode.dark
    : Theme.of(context).brightness == Brightness.dark;

TextStyle _text(
  BuildContext context, {
  bool title = false,
  bool muted = false,
}) {
  final cjk = LanguageUtil.is_cjk_language(
    Localizations.localeOf(context).languageCode,
  );
  return TextStyle(
    fontSize: title
        ? (cjk
              ? ComicReadingPanelStyle.title_cjk
              : ComicReadingPanelStyle.title_alphabetic)
        : (cjk
              ? ComicReadingPanelStyle.text_cjk
              : ComicReadingPanelStyle.text_alphabetic),
    fontWeight: FontConfig.adjustedWeight(
      title ? FontWeight.w500 : FontWeight.w400,
    ),
    color: _dark(context)
        ? (muted ? Colors.white70 : Colors.white)
        : (muted
              ? ComicReadingPanelStyle.light_muted
              : ComicReadingPanelStyle.light_ink),
  );
}

Future<void> _show_panel(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(
        maxWidth: ComicReadingPanelStyle.max_width,
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              ComicReadingPanelStyle.max_height_ratio,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );

/// TODO 当前章节的连续图片进度；拖动预览与落点分离，松手才定位并保存。
Future<void> show_comic_progress_sheet(
  BuildContext context, {
  required ComicReaderLogic logic,
  required VoidCallback on_start_auto_read,
}) => _show_panel(
  context,
  _ProgressPanel(logic: logic, on_start: on_start_auto_read),
);

class _ProgressPanel extends StatefulWidget {
  const _ProgressPanel({required this.logic, required this.on_start});
  final ComicReaderLogic logic;
  final VoidCallback on_start;
  @override
  State<_ProgressPanel> createState() => _ProgressPanelState();
}

class _ProgressPanelState extends State<_ProgressPanel> {
  double? _drag;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.logic, widget.logic.scroll]),
    builder: (context, _) {
      final progress = (_drag ?? widget.logic.chapter_progress).clamp(0.0, 1.0);
      final can_seek =
          !widget.logic.loading &&
          (widget.logic.reading?.images.isNotEmpty ?? false);
      return _Panel(
        title: tr('comics.reading_progress'),
        children: [
          Text(
            widget.logic.reading?.chapter.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _text(context, muted: true),
          ),
          const SizedBox(height: ComicReadingPanelStyle.gap),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: ComicReadingPanelStyle.gap,
            runSpacing: ComicReadingPanelStyle.gap,
            children: [
              Text(
                tr(
                  'bookshelf.progress.read_progress',
                  namedArgs: {'progress': '${(progress * 100).round()}'},
                ),
                style: _text(context),
              ),
              Text(
                tr(
                  'comics.reader_page_progress',
                  namedArgs: {
                    'page': '${widget.logic.page_index + 1}',
                    'total': '${widget.logic.reading?.images.length ?? 0}',
                  },
                ),
                style: _text(context, muted: true),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('comic_chapter_progress_slider'),
            value: progress,
            activeColor: ColorConstants.themeColor,
            onChanged: can_seek
                ? (value) => setState(() => _drag = value)
                : null,
            onChangeEnd: can_seek
                ? (value) {
                    unawaited(
                      widget.logic.animate_to_progress(value).whenComplete(() {
                        if (mounted) setState(() => _drag = null);
                      }),
                    );
                  }
                : null,
          ),
          Center(
            child: TextButton.icon(
              onPressed: can_seek
                  ? () {
                      Navigator.of(context).pop();
                      widget.on_start();
                    }
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                tr('short_story_read.auto_read'),
                style: _text(context),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// TODO 日夜主题写入小说共用DeviceInfo；真实亮度属于当前阅读会话，退出时由session恢复。
Future<void> show_comic_appearance_sheet(
  BuildContext context, {
  required ComicReaderBrightnessSession brightness,
}) async {
  await brightness.refresh();
  if (!context.mounted) return;
  return _show_panel(context, _AppearancePanel(brightness: brightness));
}

class _AppearancePanel extends StatefulWidget {
  const _AppearancePanel({required this.brightness});
  final ComicReaderBrightnessSession brightness;

  @override
  State<_AppearancePanel> createState() => _AppearancePanelState();
}

class _AppearancePanelState extends State<_AppearancePanel>
    with SingleTickerProviderStateMixin {
  late final ReaderThemeTransition _theme_transition;

  @override
  void initState() {
    super.initState();
    _theme_transition = ReaderThemeTransition(vsync: this);
  }

  @override
  void dispose() {
    _theme_transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final brightness = widget.brightness;
    final device = Get.find<DeviceInfo>();
    final dark = device.theme.value == ThemeMode.dark;
    return _Panel(
      title: tr('short_story_read.reading_settings'),
      children: [
        ReaderThemeOptions(
          is_dark: dark,
          on_change: (to_dark) =>
              unawaited(_theme_transition.change(context, to_dark: to_dark)),
        ),
        const SizedBox(height: ComicReadingPanelStyle.section_gap),
        AnimatedBuilder(
          animation: brightness,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('comics.screen_brightness'), style: _text(context)),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/svg/sun_2.svg',
                    width: ComicReadingPanelStyle.brightness_small_icon,
                    height: ComicReadingPanelStyle.brightness_small_icon,
                    colorFilter: ColorFilter.mode(
                      _text(context, muted: true).color!,
                      BlendMode.srcIn,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      key: const ValueKey('comic_brightness_slider'),
                      min: ComicReadingPanelStyle.brightness_min,
                      value: brightness.value,
                      activeColor: ColorConstants.themeColor,
                      onChanged: brightness.available
                          ? brightness.set_value
                          : null,
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/svg/sun_2.svg',
                    width: ComicReadingPanelStyle.brightness_large_icon,
                    height: ComicReadingPanelStyle.brightness_large_icon,
                    colorFilter: ColorFilter.mode(
                      _text(context, muted: true).color!,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
              if (brightness.initialized && !brightness.available)
                Text(
                  tr('comics.brightness_unavailable'),
                  style: _text(context, muted: true),
                ),
            ],
          ),
        ),
      ],
    );
  });
}

/// TODO 自动阅读速度与长篇小说共用RxDouble、存储键与设置面板，避免维护第二套速度交互。
Future<void> show_comic_auto_read_settings(
  BuildContext context, {
  required RxDouble speed,
  required VoidCallback on_stop,
}) => _show_panel(
  context,
  Builder(
    builder: (context) => ColoredBox(
      color: _dark(context)
          ? ComicReadingPanelStyle.dark_background
          : ComicReadingPanelStyle.light_background,
      child: SafeArea(
        top: false,
        child: AutoReadSettingsSheet(
          auto_read_speed: speed,
          on_close: () => Navigator.of(context).pop(),
          on_exit: () {
            Navigator.of(context).pop();
            on_stop();
          },
        ),
      ),
    ),
  ),
);

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final dark = _dark(context);
    return Container(
      key: const ValueKey('comic_reading_panel_surface'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark
            ? ComicReadingPanelStyle.dark_background
            : ComicReadingPanelStyle.light_background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ComicReadingPanelStyle.radius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomSheetDragHandle(is_dark: dark),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ComicReadingPanelStyle.padding,
                0,
                8,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: _text(context, title: true)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: Icon(
                      Icons.close_rounded,
                      color: _text(context, muted: true).color,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ComicReadingPanelStyle.padding,
                ComicReadingPanelStyle.gap,
                ComicReadingPanelStyle.padding,
                ComicReadingPanelStyle.padding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
