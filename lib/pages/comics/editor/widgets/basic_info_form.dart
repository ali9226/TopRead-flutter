// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/editor/logic.dart';
import 'package:app/pages/comics/editor/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 基本信息表单：封面、主标题、作品类型多选。
class BasicInfoForm extends StatelessWidget {
  /// 编辑器逻辑层。
  final ComicEditorLogic logic;

  /// 点击封面占位/预览，触发上传。
  final VoidCallback on_pick_cover;

  /// 是否允许编辑（审核中锁定）。
  final bool enabled;

  const BasicInfoForm({
    super.key,
    required this.logic,
    required this.on_pick_cover,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = ComicsStyle.is_cjk(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 分区标题。
        Text(
          tr('comics.basic_info'),
          style: ComicEditorStyle.section_title(context),
        ),
        const SizedBox(height: ComicEditorStyle.section_title_gap),

        /// 封面 + 标题/类型。
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _CoverPicker(
              enabled: enabled,
              logic: logic,
              on_pick: on_pick_cover,
            ),
            const SizedBox(width: ComicEditorStyle.cover_gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _FieldLabel(text: tr('comics.main_title')),
                  _TitleInput(enabled: enabled, logic: logic),
                  const SizedBox(height: ComicEditorStyle.field_spacing),
                  _FieldLabel(text: tr('comics.types')),
                  _CategoryTags(enabled: enabled, logic: logic, is_cjk: is_cjk),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 字段标签。
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      bottom: ComicEditorStyle.label_bottom_spacing,
    ),
    child: Text(text, style: ComicEditorStyle.label(context)),
  );
}

/// 封面选择器：竖版预览 + 替换操作。
class _CoverPicker extends StatelessWidget {
  final bool enabled;
  final ComicEditorLogic logic;
  final VoidCallback on_pick;

  const _CoverPicker({
    required this.enabled,
    required this.logic,
    required this.on_pick,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_dark = ComicsStyle.is_dark(context);
    final String cover_url = logic.data.cover_url;
    return Column(
      children: <Widget>[
        Semantics(
          button: true,
          label: tr('comics.cover'),
          child: GestureDetector(
            onTap: enabled ? on_pick : null,
            child: Container(
              width: ComicEditorStyle.cover_width,
              height: ComicEditorStyle.cover_height,
              decoration: BoxDecoration(
                color: ComicEditorStyle.input_fill(context),
                borderRadius: BorderRadius.circular(
                  ComicEditorStyle.cover_radius,
                ),
                border: Border.all(
                  color: ComicEditorStyle.input_border(context),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: cover_url.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: ComicEditorStyle.cover_icon_size,
                          color: ComicEditorStyle.input_hint(context),
                        ),
                        const SizedBox(height: LayoutConfig.space_8),
                        Text(
                          tr('comics.cover'),
                          style: ComicsStyle.text(
                            context,
                            color: ComicEditorStyle.input_hint(context),
                            size: ComicEditorStyle.cover_action_font_size,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ComicImage(
                          url: cover_url,
                          semantic_label: tr('comics.cover'),
                        ),

                        /// 上传中蒙层提示。
                        if (logic.uploading_image)
                          ColoredBox(
                            color: ColorConstants.lightTextColor.withValues(alpha: ComicEditorStyle.upload_mask_opacity),
                            child: const Center(
                              child: SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: LayoutConfig.space_8),
        TextButton(
          onPressed: enabled ? on_pick : null,
          child: Text(
            tr('comics.upload_pages'),
            style: TextStyle(
              fontSize: ComicEditorStyle.cover_action_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              color: is_dark
                  ? ColorConstants.components_load_more_footer_index_tone_bfffffff
                  : ColorConstants.themeColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// 主标题输入框。
class _TitleInput extends StatelessWidget {
  final bool enabled;
  final ComicEditorLogic logic;

  const _TitleInput({required this.enabled, required this.logic});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: enabled,
      initialValue: logic.data.title,
      onChanged: logic.set_title,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      decoration: _input_decoration(context, tr('comics.main_title')),
      style: ComicEditorStyle.input_text(context),
    );
  }
}

/// 分类多选标签组。
class _CategoryTags extends StatelessWidget {
  final bool enabled;
  final ComicEditorLogic logic;
  final bool is_cjk;

  const _CategoryTags({
    required this.enabled,
    required this.logic,
    required this.is_cjk,
  });

  @override
  Widget build(BuildContext context) {
    if (logic.categories.isEmpty) {
      return Text(
        tr('comics.loading'),
        style: ComicsStyle.text(context, color: ComicsStyle.muted(context)),
      );
    }
    return Wrap(
      spacing: ComicEditorStyle.tag_spacing,
      runSpacing: ComicEditorStyle.tag_run_spacing,
      children: logic.categories.map((Map<String, dynamic> category) {
        final int id = int.tryParse('${category['id']}') ?? 0;
        final bool selected = logic.data.category_ids.contains(id);

        /// 用 ColorConstants.resolveTagColor 做多色标签，未选中时压低饱和。
        final Color accent = ColorConstants.resolveTagColor(id);
        return FilterChip(
          label: Text(
            ComicsStyle.category_name(context, category),
            style: TextStyle(
              fontSize: is_cjk
                  ? ComicEditorStyle.tag_font_size_cjk
                  : ComicEditorStyle.tag_font_size_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              color: selected
                  ? accent
                  : ComicEditorStyle.tag_unselected_ink(context),
            ),
          ),
          selected: selected,
          onSelected: enabled ? (_) => logic.toggle_category(id) : null,
          showCheckmark: false,
          padding: ComicEditorStyle.tag_padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ComicEditorStyle.tag_radius),
          ),
          selectedColor: accent.withValues(alpha: 0.20),
          backgroundColor: ComicEditorStyle.tag_unselected(context),
        );
      }).toList(),
    );
  }
}

/// 统一输入框装饰：圆角填充 + 细边框。
InputDecoration _input_decoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: ComicsStyle.text(
      context,
      color: ComicEditorStyle.input_hint(context),
    ),
    filled: true,
    fillColor: ComicEditorStyle.input_fill(context),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: ComicEditorStyle.input_padding_h,
      vertical: ComicEditorStyle.input_padding_v,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ComicEditorStyle.input_radius),
      borderSide: BorderSide(color: ComicEditorStyle.input_border(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ComicEditorStyle.input_radius),
      borderSide: BorderSide(color: ComicEditorStyle.input_border(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ComicEditorStyle.input_radius),
      borderSide: BorderSide(
        color: ColorConstants.themeColor.withValues(alpha: 0.65),
        width: 1.4,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ComicEditorStyle.input_radius),
      borderSide: BorderSide(
        color: ComicEditorStyle.input_border(context).withValues(alpha: 0.5),
      ),
    ),
  );
}

/// 导出统一装饰，供语种/章节表单复用。
InputDecoration comic_editor_input_decoration(
  BuildContext context,
  String hint,
) => _input_decoration(context, hint);
