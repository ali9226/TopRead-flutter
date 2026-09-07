// ignore_for_file: non_constant_identifier_names

import 'package:app/components/bottom_sheet_drag_handle/index.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/language_info.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:app/pages/work_editor/widgets/editor_section_card.dart';
import 'package:app/pages/work_editor/widgets/step_utils.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';

class StepBasic extends StatelessWidget {
  final bool is_dark;
  final bool is_editing;
  final TextEditingController title_controller;
  final TextEditingController introduction_controller;
  final String language_code;
  final Uint8List? cover_bytes;
  final bool is_picking_cover;
  final VoidCallback on_open_cover_picker;
  final ValueChanged<String> on_language_changed;

  const StepBasic({
    super.key,
    required this.is_dark,
    required this.is_editing,
    required this.title_controller,
    required this.introduction_controller,
    required this.language_code,
    required this.cover_bytes,
    required this.is_picking_cover,
    required this.on_open_cover_picker,
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
          icon: Icons.auto_stories_rounded,
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
                required: true,
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

  Widget _build_cover_picker(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: is_picking_cover ? null : on_open_cover_picker,
          child: Container(
            width: WorkEditorStyle.cover_width,
            height: WorkEditorStyle.cover_height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AuthorStyle.secondary_surface(is_dark),
              border: Border.all(color: AuthorStyle.border(is_dark)),
              image: _build_cover_image(),
            ),
            child: _build_cover_placeholder(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              StepUtils.build_field_label(easy.tr('creator_center.cover'), is_dark, required: true),
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
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: is_picking_cover ? null : on_open_cover_picker,
                icon: is_picking_cover
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Icon(Icons.upload_rounded, size: 16),
                label: Text(
                  easy.tr(cover_bytes != null ? 'creator_center.change_cover' : 'creator_center.upload_cover'),
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                  side: BorderSide(
                    color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DecorationImage? _build_cover_image() {
    if (cover_bytes == null) return null;
    return DecorationImage(
      image: MemoryImage(cover_bytes!),
      fit: BoxFit.cover,
    );
  }

  Widget? _build_cover_placeholder(BuildContext context) {
    if (cover_bytes != null) return null;

    if (is_editing) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AuthorStyle.gold.withValues(alpha: 0.15),
              AuthorStyle.blue.withValues(alpha: 0.10),
            ],
          ),
        ),
        child: Center(
          child: is_picking_cover
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : SvgIcon(
                  name: 'icon_image',
                  width: 32,
                  height: 32,
                  color: AuthorStyle.secondary_text(is_dark),
                ),
        ),
      );
    }

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

  Widget _build_title_field(BuildContext context) {
    return TextField(
      controller: title_controller,
      style: StepUtils.input_text_style(is_dark),
      decoration: StepUtils.field_decoration(is_dark, hint: easy.tr('creator_center.title_hint')),
      maxLength: 60,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      buildCounter: _build_counter,
    );
  }

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

  Widget _build_language_picker(BuildContext context) {
    final LanguageStore store = Get.find<LanguageStore>();
    final LanguageInfo? current_lang = store.find_supported_language_by_code(
      language_code,
    );
    final String display_name = current_lang?.title ?? language_code.toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _show_language_sheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              BottomSheetDragHandle(is_dark: is_dark),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
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
                    20,
                    8,
                    20,
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
                          horizontal: 14,
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
                                      ? FontWeight.w600
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
