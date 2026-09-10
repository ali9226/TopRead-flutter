// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_section_card.dart';
import 'package:app/pages/work_editor/_shared/widgets/step_utils.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// TODO 步骤1：作品基本资料。
class StepBasic extends StatelessWidget {
  /// TODO 是否夜间主题。
  final bool is_dark;

  /// TODO 是否编辑模式（已有作品）。
  final bool is_editing;

  /// TODO 标题输入控制器。
  final TextEditingController title_controller;

  /// TODO 简介输入控制器。
  final TextEditingController introduction_controller;

  /// TODO 当前原始创作语种。
  final String language_code;

  /// TODO 本地封面图片路径（上传中使用）。
  final String? cover_local_path;

  /// TODO 已上传的封面 URL。
  final String? cover_url;

  /// TODO 是否正在上传封面。
  final bool is_uploading_cover;

  /// TODO 选择封面回调。
  final VoidCallback on_pick_cover;

  /// TODO 语种切换回调。
  final ValueChanged<String> on_language_changed;

  const StepBasic({
    super.key,
    required this.is_dark,
    required this.is_editing,
    required this.title_controller,
    required this.introduction_controller,
    required this.language_code,
    this.cover_local_path,
    this.cover_url,
    required this.is_uploading_cover,
    required this.on_pick_cover,
    required this.on_language_changed,
  });

  @override
  Widget build(BuildContext context) {
    return StepUtils.build_step_scroll_view(
      context: context,
      children: <Widget>[
        EditorSectionCard(
          title: easy.tr('creator_center.basic_title'),
          subtitle: easy.tr('creator_center.basic_subtitle'),
          is_dark: is_dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _build_cover_picker(context),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              StepUtils.build_field_label(
                easy.tr('creator_center.title_label'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 8),
              _build_title_field(context),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              StepUtils.build_field_label(
                easy.tr('creator_center.intro_label'),
                is_dark,
              ),
              const SizedBox(height: 8),
              _build_introduction_field(context),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              StepUtils.build_field_label(
                easy.tr('creator_center.language_label'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 8),
              _build_language_picker(context),
            ],
          ),
        ),
      ],
    );
  }

  /// TODO 构建封面选择器。
  Widget _build_cover_picker(BuildContext context) {
    final bool has_cover = cover_url != null || cover_local_path != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 封面图片区域。
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: is_uploading_cover ? null : on_pick_cover,
          child: Container(
            width: WorkEditorStyle.cover_width,
            height: WorkEditorStyle.cover_height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AuthorStyle.secondary_surface(is_dark),
              border: Border.all(color: AuthorStyle.border(is_dark)),
            ),
            child: _build_cover_content(),
          ),
        ),
        const SizedBox(width: 16),

        /// 右侧文字和按钮。
        Expanded(
          child: SizedBox(
            height: WorkEditorStyle.cover_height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    StepUtils.build_field_label(
                      easy.tr('creator_center.cover'),
                      is_dark,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      easy.tr('creator_center.cover_hint'),
                      style: TextStyle(
                        color: AuthorStyle.secondary_text(is_dark),
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: AuthorStyle.body_weight,
                      ),
                    ),
                  ],
                ),
                /// 上传/更换按钮（向上偏移 5px）。
                Transform.translate(
                  offset: const Offset(0, -5),
                  child: _build_upload_button(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// TODO 构建封面内容（本地图片/网络图片/占位符）。
  Widget _build_cover_content() {
    /// 本地图片（上传中）。
    if (cover_local_path != null) {
      return Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(cover_local_path!),
              width: WorkEditorStyle.cover_width,
              height: WorkEditorStyle.cover_height,
              fit: BoxFit.cover,
            ),
          ),
          if (is_uploading_cover)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    /// 网络图片。
    if (cover_url != null && cover_url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: cover_url!,
          width: WorkEditorStyle.cover_width,
          height: WorkEditorStyle.cover_height,
          fit: BoxFit.cover,
          placeholder: (_, __) => Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AuthorStyle.secondary_text(is_dark),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _build_placeholder_icon(),
        ),
      );
    }

    /// 占位符。
    return _build_placeholder_icon();
  }

  /// TODO 构建占位符图标。
  Widget _build_placeholder_icon() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: AuthorStyle.secondary_text(is_dark),
          ),
          const SizedBox(height: 6),
          Text(
            easy.tr('creator_center.upload_cover'),
            style: TextStyle(
              color: AuthorStyle.secondary_text(is_dark),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// TODO 构建上传按钮。
  Widget _build_upload_button() {
    final bool has_cover = cover_url != null || cover_local_path != null;

    return InkWell(
      onTap: is_uploading_cover ? null : on_pick_cover,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ColorConstants.themeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgIcon(
              name: 'upgrade',
              width: 16,
              height: 16,
              color: ColorConstants.lightTextColor,
            ),
            const SizedBox(width: 4),
            Text(
              easy.tr(has_cover
                  ? 'creator_center.change_cover'
                  : 'creator_center.upload_cover'),
              style: TextStyle(
                fontSize: 12,
                color: ColorConstants.lightTextColor,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TODO 构建标题输入框。
  Widget _build_title_field(BuildContext context) {
    return TextField(
      controller: title_controller,
      style: StepUtils.input_text_style(is_dark),
      decoration: StepUtils.field_decoration(
        is_dark,
        hint: easy.tr('creator_center.title_hint'),
      ),
      maxLength: 60,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      buildCounter: _build_counter,
    );
  }

  /// TODO 构建简介输入框。
  Widget _build_introduction_field(BuildContext context) {
    return TextField(
      controller: introduction_controller,
      style: StepUtils.input_text_style(is_dark),
      decoration: StepUtils.field_decoration(
        is_dark,
        hint: easy.tr('creator_center.intro_hint'),
      ),
      minLines: 4,
      maxLines: 7,
      maxLength: 500,
      textInputAction: TextInputAction.newline,
      buildCounter: _build_counter,
    );
  }

  /// TODO 构建字数计数器。
  Widget _build_counter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) {
    return Text(
      '$currentLength/$maxLength',
      style: TextStyle(
        color: AuthorStyle.secondary_text(is_dark),
        fontSize: 11,
      ),
    );
  }

  /// TODO 构建语种选择器。
  Widget _build_language_picker(BuildContext context) {
    final LanguageStore store = Get.find<LanguageStore>();
    final LanguageInfo? current_lang = store.find_supported_language_by_code(
      language_code,
    );
    final String display_name =
        current_lang?.title ?? language_code.toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _show_language_sheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AuthorStyle.secondary_surface(is_dark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AuthorStyle.border(is_dark)),
        ),
        child: Row(
          children: <Widget>[
            _build_flag_icon(
              current_lang ?? LanguageInfo(code: language_code),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                display_name,
                style: StepUtils.input_text_style(is_dark),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AuthorStyle.secondary_text(is_dark),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// TODO 构建语种旗帜图标。
  Widget _build_flag_icon(LanguageInfo lang, {double size = 20}) {
    final String code = lang.language_code;

    if (code == 'en') {
      return Image.asset(
        'assets/img/en.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    if (code == 'sw') {
      return Image.asset(
        'assets/img/sw.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    if (lang.icon.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: lang.icon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => Image.asset(
          LanguageUtil.get_language_asset_image(code),
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }

    return Image.asset(
      LanguageUtil.get_language_asset_image(code),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  /// TODO 显示语种选择弹窗。
  void _show_language_sheet(BuildContext context) {
    final LanguageStore store = Get.find<LanguageStore>();
    final List<LanguageInfo> languages = store.visible_language_list;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheet_context) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AuthorStyle.surface(is_dark),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              BottomSheetDragHandle(is_dark: is_dark),
              Padding(
                padding:
                    const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                child: Row(
                  children: <Widget>[
                    Text(
                      easy.tr('creator_center.language_label'),
                      style: TextStyle(
                        color: AuthorStyle.primary_text(is_dark),
                        fontSize: 17,
                        fontWeight: WorkEditorStyle.section_title_weight,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheet_context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AuthorStyle.secondary_text(is_dark),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    MediaQuery.paddingOf(sheet_context).bottom + 16,
                  ),
                  itemCount: languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (BuildContext _, int index) {
                    final LanguageInfo lang = languages[index];
                    final bool is_selected =
                        lang.language_code == language_code;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(sheet_context);
                        on_language_changed(lang.language_code);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: is_selected
                              ? (is_dark
                                      ? AuthorStyle.gold
                                      : AuthorStyle.deep_gold)
                                  .withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: is_selected
                              ? Border.all(
                                  color: (is_dark
                                          ? AuthorStyle.gold
                                          : AuthorStyle.deep_gold)
                                      .withValues(alpha: 0.30),
                                )
                              : null,
                        ),
                        child: Row(
                          children: <Widget>[
                            _build_flag_icon(lang, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lang.title,
                                style: TextStyle(
                                  color: AuthorStyle.primary_text(is_dark),
                                  fontSize: 15,
                                  fontWeight: is_selected
                                      ? FontConfig.adjustedWeight(FontWeight.w600)
                                      : AuthorStyle.body_weight,
                                ),
                              ),
                            ),
                            if (is_selected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: is_dark
                                    ? AuthorStyle.gold
                                    : AuthorStyle.deep_gold,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
