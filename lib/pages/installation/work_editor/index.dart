// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/installation/author_style.dart';
import 'package:app/pages/installation/chapter_editor/index.dart';
import 'package:app/pages/installation/models/creator_work.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'style.dart';
import 'widgets/editor_section_card.dart';
import 'widgets/editor_step_indicator.dart';

/// TODO 创建或编辑小说的三步交互页面。
///
/// 当前页面只负责 Flutter UI 和本地状态：
/// 1. 基本资料与封面；
/// 2. 长篇章节或短篇正文；
/// 3. 审核通过后的发布方式。
class CreatorWorkEditorPage extends StatefulWidget {
  /// TODO 已有作品；为空表示创建新作品。
  final CreatorWorkDraft? initial_work;

  const CreatorWorkEditorPage({super.key, this.initial_work});

  @override
  State<CreatorWorkEditorPage> createState() => _CreatorWorkEditorPageState();
}

class _CreatorWorkEditorPageState extends State<CreatorWorkEditorPage> {
  /// TODO 设备主题状态。
  final DeviceInfo _device_info = Get.find<DeviceInfo>();

  /// TODO 页面步骤控制器。
  final PageController _page_controller = PageController();

  /// TODO 封面选择器。
  final ImagePicker _image_picker = ImagePicker();

  /// TODO 标题输入控制器。
  late final TextEditingController _title_controller;

  /// TODO 简介输入控制器。
  late final TextEditingController _introduction_controller;

  /// TODO 短篇正文输入控制器。
  late final TextEditingController _short_content_controller;

  /// TODO 当前步骤索引。
  int _current_step = 0;

  /// TODO 当前选择的篇幅类型。
  late CreatorWorkType _work_type;

  /// TODO 是否完结。
  late bool _is_completed;

  /// TODO 当前原始创作语种。
  late String _language_code;

  /// TODO 当前选择的分类。
  late Set<String> _selected_categories;

  /// TODO 长篇章节列表。
  late List<CreatorChapterDraft> _chapters;

  /// TODO 发布方式。
  late CreatorReleaseMode _release_mode;

  /// TODO 定时发布时刻。
  DateTime? _scheduled_publish_time;

  /// TODO 是否已确认原创和授权声明。
  bool _rights_confirmed = false;

  /// TODO 本轮选择的封面内存数据。
  Uint8List? _cover_bytes;

  /// TODO 是否正在读取封面。
  bool _is_picking_cover = false;

  @override
  void initState() {
    super.initState();

    final CreatorWorkDraft? work = widget.initial_work;
    _title_controller = TextEditingController(text: work?.title ?? '');
    _introduction_controller = TextEditingController(
      text: work?.introduction ?? '',
    );
    _short_content_controller = TextEditingController(
      text: work?.short_content ?? '',
    );
    _work_type = work?.work_type ?? CreatorWorkType.long;
    _is_completed = work?.is_completed ?? false;
    _language_code = work?.language_code ?? 'zh';
    _selected_categories = <String>{...?work?.categories};
    _chapters = <CreatorChapterDraft>[...?work?.chapters];
    _release_mode = work?.release_mode ?? CreatorReleaseMode.immediate;
    _scheduled_publish_time = work?.scheduled_publish_time;
  }

  @override
  void dispose() {
    _page_controller.dispose();
    _title_controller.dispose();
    _introduction_controller.dispose();
    _short_content_controller.dispose();
    super.dispose();
  }

  /// TODO 是否处于编辑已有作品状态。
  bool get _is_editing => widget.initial_work != null;

  /// TODO 读取短篇正文非空白字符数。
  int get _short_word_count {
    return _short_content_controller.text.replaceAll(RegExp(r'\s+'), '').length;
  }

  /// TODO 读取长篇所有章节总字数。
  int get _chapter_word_count {
    return _chapters.fold<int>(
      0,
      (int total, CreatorChapterDraft chapter) => total + chapter.word_count,
    );
  }

  /// TODO 页面可选分类，直接复用作者申请已有的多语种题材文案。
  List<String> get _category_options => <String>[
    easy.tr('installation.genre_romance'),
    easy.tr('installation.genre_fantasy'),
    easy.tr('installation.genre_scifi'),
    easy.tr('installation.genre_mystery'),
    easy.tr('installation.genre_history'),
    easy.tr('installation.genre_urban'),
    easy.tr('installation.genre_martial'),
    easy.tr('installation.genre_horror'),
    easy.tr('installation.genre_fairy'),
  ];

  /// TODO 切换步骤并滚动回页面顶部。
  Future<void> _go_to_step(int step) async {
    if (step < 0 || step > 2 || step == _current_step) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _current_step = step);
    await _page_controller.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// TODO 选择相册或相机中的封面，并立即在本地预览。
  Future<void> _pick_cover(ImageSource source) async {
    if (_is_picking_cover) return;

    setState(() => _is_picking_cover = true);
    try {
      final XFile? image = await _image_picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() => _cover_bytes = bytes);
    } catch (_) {
      showBottomTip(easy.tr('creator_center.cover_pick_failed'));
    } finally {
      if (mounted) setState(() => _is_picking_cover = false);
    }
  }

  /// TODO 打开封面来源选择面板。
  Future<void> _open_cover_picker() async {
    await showImageSourceSheet(
      context: context,
      on_gallery: () => _pick_cover(ImageSource.gallery),
      on_camera: () => _pick_cover(ImageSource.camera),
    );
  }

  /// TODO 新增章节。
  Future<void> _add_chapter() async {
    final CreatorChapterDraft? chapter = await Navigator.of(context)
        .push<CreatorChapterDraft>(
          MaterialPageRoute<CreatorChapterDraft>(
            builder: (BuildContext context) =>
                ChapterEditorPage(chapter_number: _chapters.length + 1),
          ),
        );

    if (chapter == null || !mounted) return;
    setState(() => _chapters.add(chapter));
  }

  /// TODO 编辑指定章节。
  Future<void> _edit_chapter(int index) async {
    final CreatorChapterDraft current_chapter = _chapters[index];
    final CreatorChapterDraft? chapter = await Navigator.of(context)
        .push<CreatorChapterDraft>(
          MaterialPageRoute<CreatorChapterDraft>(
            builder: (BuildContext context) => ChapterEditorPage(
              chapter_number: index + 1,
              initial_chapter: current_chapter,
            ),
          ),
        );

    if (chapter == null || !mounted) return;
    setState(() => _chapters[index] = chapter);
  }

  /// TODO 删除章节前二次确认，避免误触导致本地长文本丢失。
  Future<void> _delete_chapter(int index) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog_context) {
        final bool is_dark = _device_info.dark.value;
        return AlertDialog(
          backgroundColor: AuthorStyle.surface(is_dark),
          title: Text(
            easy.tr('creator_center.delete_chapter'),
            style: TextStyle(color: AuthorStyle.primary_text(is_dark)),
          ),
          content: Text(
            easy.tr('creator_center.delete_chapter_confirm'),
            style: TextStyle(color: AuthorStyle.secondary_text(is_dark)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialog_context).pop(false),
              child: Text(easy.tr('constant.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialog_context).pop(true),
              child: Text(
                easy.tr('creator_center.delete'),
                style: TextStyle(color: ColorConstants.dangerColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    setState(() => _chapters.removeAt(index));
  }

  /// TODO 打开系统日期和时间选择器。
  Future<void> _select_schedule_time() async {
    final DateTime now = DateTime.now();
    final DateTime initial_time =
        _scheduled_publish_time ?? now.add(const Duration(days: 1));

    final DateTime? selected_date = await showDatePicker(
      context: context,
      initialDate: initial_time,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected_date == null || !mounted) return;

    final TimeOfDay? selected_time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial_time),
    );
    if (selected_time == null || !mounted) return;

    setState(() {
      _scheduled_publish_time = DateTime(
        selected_date.year,
        selected_date.month,
        selected_date.day,
        selected_time.hour,
        selected_time.minute,
      );
    });
  }

  /// TODO 构造要返回给创作者中心的本地作品模型。
  CreatorWorkDraft _build_work(CreatorWorkStatus status) {
    final DateTime now = DateTime.now();

    return CreatorWorkDraft(
      local_id:
          widget.initial_work?.local_id ?? 'work_${now.microsecondsSinceEpoch}',
      title: _title_controller.text.trim(),
      introduction: _introduction_controller.text.trim(),
      work_type: _work_type,
      is_completed: _is_completed,
      language_code: _language_code,
      categories: _selected_categories.toList(growable: false),
      short_content: _work_type == CreatorWorkType.short
          ? _short_content_controller.text.trim()
          : '',
      chapters: _work_type == CreatorWorkType.long
          ? List<CreatorChapterDraft>.unmodifiable(_chapters)
          : const <CreatorChapterDraft>[],
      status: status,
      release_mode: _release_mode,
      scheduled_publish_time: _release_mode == CreatorReleaseMode.scheduled
          ? _scheduled_publish_time
          : null,
      update_time: now,
      is_demo: false,
    );
  }

  /// TODO 保存本地草稿，不要求所有投稿字段已经完整。
  void _save_draft() {
    final CreatorWorkDraft draft = _build_work(CreatorWorkStatus.draft);
    showBottomTip(easy.tr('creator_center.draft_saved'));
    Navigator.of(context).pop<CreatorWorkDraft>(draft);
  }

  /// TODO 校验投稿资料并进入待审核状态。
  void _submit_for_review() {
    if (_title_controller.text.trim().isEmpty) {
      _go_to_step(0);
      showBottomTip(easy.tr('creator_center.required_title'));
      return;
    }
    if (_cover_bytes == null && !_is_editing) {
      _go_to_step(0);
      showBottomTip(easy.tr('creator_center.required_cover'));
      return;
    }
    if (_selected_categories.isEmpty) {
      _go_to_step(0);
      showBottomTip(easy.tr('creator_center.required_category'));
      return;
    }
    if (_work_type == CreatorWorkType.long && _chapters.isEmpty) {
      _go_to_step(1);
      showBottomTip(easy.tr('creator_center.required_chapter'));
      return;
    }
    if (_work_type == CreatorWorkType.short &&
        _short_content_controller.text.trim().isEmpty) {
      _go_to_step(1);
      showBottomTip(easy.tr('creator_center.required_short_content'));
      return;
    }
    if (_release_mode == CreatorReleaseMode.scheduled &&
        _scheduled_publish_time == null) {
      showBottomTip(easy.tr('creator_center.required_schedule'));
      return;
    }
    if (!_rights_confirmed) {
      showBottomTip(easy.tr('creator_center.required_rights'));
      return;
    }

    final CreatorWorkDraft reviewing_work = _build_work(
      CreatorWorkStatus.reviewing,
    );
    showBottomTip(easy.tr('creator_center.submitted'));
    Navigator.of(context).pop<CreatorWorkDraft>(reviewing_work);
  }

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

    return Obx(() {
      final bool is_dark = _device_info.dark.value;

      return Scaffold(
        backgroundColor: AuthorStyle.background(is_dark),
        appBar: AppBar(
          backgroundColor: AuthorStyle.surface(is_dark),
          surfaceTintColor: Colors.transparent,
          foregroundColor: AuthorStyle.primary_text(is_dark),
          elevation: 0,
          title: Text(
            _is_editing
                ? easy.tr('creator_center.edit_work_title')
                : easy.tr('creator_center.work_editor_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: AuthorStyle.title_weight,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: _save_draft,
              child: Text(
                easy.tr('creator_center.save_draft'),
                style: TextStyle(
                  color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                  fontWeight: AuthorStyle.emphasis_weight,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: <Widget>[
            EditorStepIndicator(
              current_step: _current_step,
              labels: <String>[
                easy.tr('creator_center.step_basic'),
                easy.tr('creator_center.step_content'),
                easy.tr('creator_center.step_publish'),
              ],
              is_cjk: is_cjk,
              is_dark: is_dark,
            ),
            Expanded(
              child: PageView(
                controller: _page_controller,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _build_basic_step(is_dark),
                  _build_content_step(is_dark),
                  _build_publish_step(is_dark),
                ],
              ),
            ),
            _build_bottom_bar(is_dark, is_cjk),
          ],
        ),
      );
    });
  }

  /// TODO 构建第一步：封面和基本资料。
  Widget _build_basic_step(bool is_dark) {
    return _build_step_scroll_view(
      children: <Widget>[
        EditorSectionCard(
          title: easy.tr('creator_center.basic_title'),
          subtitle: easy.tr('creator_center.basic_subtitle'),
          icon: Icons.auto_stories_rounded,
          is_dark: is_dark,
          child: Column(
            children: <Widget>[
              _build_cover_picker(is_dark),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              _build_field_label(
                easy.tr('creator_center.work_type'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 10),
              _build_work_type_selector(is_dark),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              _build_field_label(
                easy.tr('creator_center.title_label'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _title_controller,
                maxLength: 60,
                cursorColor: ColorConstants.themeColor,
                style: _input_text_style(is_dark),
                decoration: _field_decoration(
                  is_dark,
                  hint: easy.tr('creator_center.title_hint'),
                ),
              ),
              const SizedBox(height: 14),
              _build_field_label(
                easy.tr('creator_center.intro_label'),
                is_dark,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _introduction_controller,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                cursorColor: ColorConstants.themeColor,
                style: _input_text_style(is_dark),
                decoration: _field_decoration(
                  is_dark,
                  hint: easy.tr('creator_center.intro_hint'),
                ),
              ),
            ],
          ),
        ),
        EditorSectionCard(
          title: easy.tr('creator_center.classification_title'),
          subtitle: easy.tr('creator_center.classification_subtitle'),
          icon: Icons.tune_rounded,
          is_dark: is_dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _build_field_label(
                easy.tr('creator_center.language_label'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _language_code,
                dropdownColor: AuthorStyle.surface(is_dark),
                iconEnabledColor: AuthorStyle.secondary_text(is_dark),
                style: _input_text_style(is_dark),
                decoration: _field_decoration(is_dark),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'zh',
                    child: Text(easy.tr('creator_center.language_chinese')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text(easy.tr('creator_center.language_english')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'fr',
                    child: Text(easy.tr('creator_center.language_french')),
                  ),
                  DropdownMenuItem<String>(
                    value: 'sw',
                    child: Text(easy.tr('creator_center.language_swahili')),
                  ),
                ],
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => _language_code = value);
                },
              ),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              _build_field_label(
                easy.tr('creator_center.category_label'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 6),
              Text(
                easy.tr('creator_center.category_hint'),
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 12,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _category_options
                    .map((String category) {
                      final bool selected = _selected_categories.contains(
                        category,
                      );
                      return FilterChip(
                        selected: selected,
                        label: Text(category),
                        showCheckmark: false,
                        selectedColor: AuthorStyle.gold.withValues(alpha: 0.22),
                        backgroundColor: AuthorStyle.secondary_surface(is_dark),
                        side: BorderSide(
                          color: selected
                              ? AuthorStyle.gold
                              : AuthorStyle.border(is_dark),
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? (is_dark
                                    ? AuthorStyle.gold
                                    : AuthorStyle.deep_gold)
                              : AuthorStyle.secondary_text(is_dark),
                          fontWeight: selected
                              ? AuthorStyle.emphasis_weight
                              : AuthorStyle.body_weight,
                        ),
                        onSelected: (bool value) {
                          setState(() {
                            if (value && _selected_categories.length < 5) {
                              _selected_categories.add(category);
                            } else if (!value) {
                              _selected_categories.remove(category);
                            } else {
                              showBottomTip(
                                easy.tr('creator_center.category_limit'),
                              );
                            }
                          });
                        },
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              _build_field_label(
                easy.tr('creator_center.serialization_label'),
                is_dark,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _build_choice_button(
                      is_dark: is_dark,
                      selected: !_is_completed,
                      icon: Icons.edit_note_rounded,
                      title: easy.tr('creator_center.serializing'),
                      on_tap: () => setState(() => _is_completed = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _build_choice_button(
                      is_dark: is_dark,
                      selected: _is_completed,
                      icon: Icons.task_alt_rounded,
                      title: easy.tr('creator_center.completed'),
                      on_tap: () => setState(() => _is_completed = true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TODO 构建第二步：长篇章节或短篇正文。
  Widget _build_content_step(bool is_dark) {
    final bool is_long = _work_type == CreatorWorkType.long;

    return _build_step_scroll_view(
      children: <Widget>[
        EditorSectionCard(
          title: easy.tr('creator_center.content_title'),
          subtitle: easy.tr(
            is_long
                ? 'creator_center.content_long_subtitle'
                : 'creator_center.content_short_subtitle',
          ),
          icon: is_long ? Icons.view_agenda_rounded : Icons.subject_rounded,
          is_dark: is_dark,
          child: is_long
              ? _build_chapter_manager(is_dark)
              : _build_short_content_editor(is_dark),
        ),
      ],
    );
  }

  /// TODO 构建第三步：审核说明和发布方式。
  Widget _build_publish_step(bool is_dark) {
    return _build_step_scroll_view(
      children: <Widget>[
        EditorSectionCard(
          title: easy.tr('creator_center.publish_title'),
          subtitle: easy.tr('creator_center.publish_subtitle'),
          icon: Icons.verified_user_outlined,
          is_dark: is_dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AuthorStyle.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AuthorStyle.blue.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.mark_email_read_outlined,
                      color: AuthorStyle.blue,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            easy.tr('creator_center.review_tip_title'),
                            style: TextStyle(
                              color: AuthorStyle.primary_text(is_dark),
                              fontSize: 14,
                              fontWeight: AuthorStyle.emphasis_weight,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            easy.tr('creator_center.review_tip_content'),
                            style: TextStyle(
                              color: AuthorStyle.secondary_text(is_dark),
                              fontSize: 12,
                              height: 1.55,
                              fontWeight: AuthorStyle.body_weight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: WorkEditorStyle.field_spacing),
              _build_field_label(
                easy.tr('creator_center.release_mode'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 10),
              _build_release_option(
                is_dark: is_dark,
                mode: CreatorReleaseMode.immediate,
                icon: Icons.rocket_launch_outlined,
                title: easy.tr('creator_center.release_immediate'),
                subtitle: easy.tr('creator_center.release_immediate_desc'),
              ),
              const SizedBox(height: 10),
              _build_release_option(
                is_dark: is_dark,
                mode: CreatorReleaseMode.scheduled,
                icon: Icons.schedule_rounded,
                title: easy.tr('creator_center.release_scheduled'),
                subtitle: easy.tr('creator_center.release_scheduled_desc'),
              ),
              if (_release_mode == CreatorReleaseMode.scheduled) ...<Widget>[
                const SizedBox(height: 12),
                Material(
                  color: AuthorStyle.secondary_surface(is_dark),
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: _select_schedule_time,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.event_rounded,
                            color: is_dark
                                ? AuthorStyle.gold
                                : AuthorStyle.deep_gold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _scheduled_publish_time == null
                                  ? easy.tr(
                                      'creator_center.select_schedule_time',
                                    )
                                  : DateFormat(
                                      'yyyy-MM-dd HH:mm',
                                    ).format(_scheduled_publish_time!),
                              style: TextStyle(
                                color: _scheduled_publish_time == null
                                    ? AuthorStyle.secondary_text(is_dark)
                                    : AuthorStyle.primary_text(is_dark),
                                fontWeight: AuthorStyle.emphasis_weight,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AuthorStyle.secondary_text(is_dark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: WorkEditorStyle.field_spacing),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () =>
                      setState(() => _rights_confirmed = !_rights_confirmed),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Checkbox(
                          value: _rights_confirmed,
                          activeColor: AuthorStyle.gold,
                          checkColor: const Color(0xFF1A1A18),
                          side: BorderSide(
                            color: AuthorStyle.secondary_text(is_dark),
                          ),
                          onChanged: (bool? value) => setState(
                            () => _rights_confirmed = value ?? false,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 11),
                            child: Text(
                              easy.tr('creator_center.rights_confirm'),
                              style: TextStyle(
                                color: AuthorStyle.secondary_text(is_dark),
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: AuthorStyle.body_weight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TODO 统一构建步骤内的滚动区域。
  Widget _build_step_scroll_view({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        WorkEditorStyle.page_padding,
        WorkEditorStyle.section_spacing,
        WorkEditorStyle.page_padding,
        WorkEditorStyle.section_spacing + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WorkEditorStyle.content_max_width,
          ),
          child: Column(
            children: children
                .expand(
                  (Widget child) => <Widget>[
                    child,
                    const SizedBox(height: WorkEditorStyle.section_spacing),
                  ],
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  /// TODO 构建封面选择区域。
  Widget _build_cover_picker(bool is_dark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _open_cover_picker,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: WorkEditorStyle.cover_width,
              height: WorkEditorStyle.cover_height,
              decoration: BoxDecoration(
                color: AuthorStyle.secondary_surface(is_dark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _cover_bytes != null || _is_editing
                      ? AuthorStyle.gold
                      : AuthorStyle.border(is_dark),
                ),
                image: _cover_bytes == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(_cover_bytes!),
                        fit: BoxFit.cover,
                      ),
                gradient: _cover_bytes == null && _is_editing
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF54617A), Color(0xFF252A38)],
                      )
                    : null,
              ),
              child: _is_picking_cover
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _cover_bytes != null
                  ? const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xCC11131A),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          _is_editing
                              ? Icons.auto_stories_rounded
                              : Icons.add_photo_alternate_outlined,
                          color: _is_editing
                              ? Colors.white
                              : AuthorStyle.secondary_text(is_dark),
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          easy.tr('creator_center.cover'),
                          style: TextStyle(
                            color: _is_editing
                                ? Colors.white
                                : AuthorStyle.secondary_text(is_dark),
                            fontSize: 12,
                            fontWeight: AuthorStyle.emphasis_weight,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _build_field_label(
                easy.tr('creator_center.cover'),
                is_dark,
                required: true,
              ),
              const SizedBox(height: 7),
              Text(
                easy.tr('creator_center.cover_hint'),
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _open_cover_picker,
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(
                  easy.tr(
                    _cover_bytes == null && !_is_editing
                        ? 'creator_center.upload_cover'
                        : 'creator_center.change_cover',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: is_dark
                      ? AuthorStyle.gold
                      : AuthorStyle.deep_gold,
                  side: BorderSide(
                    color: AuthorStyle.gold.withValues(alpha: 0.65),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// TODO 构建长篇、短篇选择卡。
  Widget _build_work_type_selector(bool is_dark) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _build_type_card(
            is_dark: is_dark,
            type: CreatorWorkType.long,
            icon: Icons.menu_book_rounded,
            title: easy.tr('creator_center.long_work'),
            subtitle: easy.tr('creator_center.long_description'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _build_type_card(
            is_dark: is_dark,
            type: CreatorWorkType.short,
            icon: Icons.article_rounded,
            title: easy.tr('creator_center.short_work'),
            subtitle: easy.tr('creator_center.short_description'),
          ),
        ),
      ],
    );
  }

  /// TODO 构建单个篇幅类型卡片。
  Widget _build_type_card({
    required bool is_dark,
    required CreatorWorkType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = _work_type == type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _work_type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AuthorStyle.gold.withValues(alpha: is_dark ? 0.15 : 0.18)
                : AuthorStyle.secondary_surface(is_dark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: selected ? 1.5 : 1,
              color: selected ? AuthorStyle.gold : AuthorStyle.border(is_dark),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 24,
                    color: selected
                        ? (is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold)
                        : AuthorStyle.secondary_text(is_dark),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AuthorStyle.gold,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: AuthorStyle.primary_text(is_dark),
                  fontSize: 14,
                  fontWeight: AuthorStyle.emphasis_weight,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TODO 构建长篇章节管理区域。
  Widget _build_chapter_manager(bool is_dark) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                easy.tr(
                  'creator_center.chapter_summary',
                  namedArgs: <String, String>{
                    'count': _chapters.length.toString(),
                    'words': _chapter_word_count.toString(),
                  },
                ),
                style: TextStyle(
                  color: AuthorStyle.secondary_text(is_dark),
                  fontSize: 12,
                  fontWeight: AuthorStyle.body_weight,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _add_chapter,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(easy.tr('creator_center.add_chapter')),
              style: FilledButton.styleFrom(
                backgroundColor: AuthorStyle.gold,
                foregroundColor: const Color(0xFF1A1A18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_chapters.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
            decoration: BoxDecoration(
              color: AuthorStyle.secondary_surface(is_dark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AuthorStyle.border(is_dark)),
            ),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.note_add_outlined,
                  size: 36,
                  color: AuthorStyle.secondary_text(is_dark),
                ),
                const SizedBox(height: 10),
                Text(
                  easy.tr('creator_center.chapter_empty_title'),
                  style: TextStyle(
                    color: AuthorStyle.primary_text(is_dark),
                    fontWeight: AuthorStyle.emphasis_weight,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  easy.tr('creator_center.chapter_empty_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AuthorStyle.secondary_text(is_dark),
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: AuthorStyle.body_weight,
                  ),
                ),
              ],
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _chapters.length,
            onReorderItem: (int old_index, int new_index) {
              setState(() {
                final CreatorChapterDraft item = _chapters.removeAt(old_index);
                _chapters.insert(new_index, item);
              });
            },
            itemBuilder: (BuildContext context, int index) {
              final CreatorChapterDraft chapter = _chapters[index];
              return Padding(
                key: ValueKey<String>(chapter.local_id),
                padding: EdgeInsets.only(
                  bottom: index == _chapters.length - 1 ? 0 : 9,
                ),
                child: Material(
                  color: AuthorStyle.secondary_surface(is_dark),
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _edit_chapter(index),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
                      child: Row(
                        children: <Widget>[
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                color: AuthorStyle.secondary_text(is_dark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AuthorStyle.gold.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: is_dark
                                    ? AuthorStyle.gold
                                    : AuthorStyle.deep_gold,
                                fontWeight: AuthorStyle.emphasis_weight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  chapter.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AuthorStyle.primary_text(is_dark),
                                    fontSize: 14,
                                    fontWeight: AuthorStyle.emphasis_weight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  easy.tr(
                                    'creator_center.word_count',
                                    namedArgs: <String, String>{
                                      'count': chapter.word_count.toString(),
                                    },
                                  ),
                                  style: TextStyle(
                                    color: AuthorStyle.secondary_text(is_dark),
                                    fontSize: 11,
                                    fontWeight: AuthorStyle.body_weight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: easy.tr('creator_center.delete_chapter'),
                            onPressed: () => _delete_chapter(index),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                            color: ColorConstants.dangerColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  /// TODO 构建短篇全文编辑框。
  Widget _build_short_content_editor(bool is_dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _build_field_label(
                easy.tr('creator_center.short_content_label'),
                is_dark,
                required: true,
              ),
            ),
            Text(
              easy.tr(
                'creator_center.word_count',
                namedArgs: <String, String>{
                  'count': _short_word_count.toString(),
                },
              ),
              style: TextStyle(
                color: AuthorStyle.secondary_text(is_dark),
                fontSize: 12,
                fontWeight: AuthorStyle.body_weight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _short_content_controller,
          minLines: 18,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          cursorColor: ColorConstants.themeColor,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            color: AuthorStyle.primary_text(is_dark),
            fontSize: 16,
            height: 1.75,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
          decoration: _field_decoration(
            is_dark,
            hint: easy.tr('creator_center.short_content_hint'),
          ),
        ),
      ],
    );
  }

  /// TODO 构建发布方式选择项。
  Widget _build_release_option({
    required bool is_dark,
    required CreatorReleaseMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = _release_mode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _release_mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AuthorStyle.gold.withValues(alpha: is_dark ? 0.14 : 0.16)
                : AuthorStyle.secondary_surface(is_dark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AuthorStyle.gold : AuthorStyle.border(is_dark),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AuthorStyle.gold.withValues(alpha: 0.22)
                      : AuthorStyle.surface(is_dark),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: selected
                      ? (is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold)
                      : AuthorStyle.secondary_text(is_dark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: AuthorStyle.primary_text(is_dark),
                        fontSize: 14,
                        fontWeight: AuthorStyle.emphasis_weight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AuthorStyle.secondary_text(is_dark),
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: AuthorStyle.body_weight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AuthorStyle.gold
                    : AuthorStyle.secondary_text(is_dark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TODO 构建底部步骤操作栏。
  Widget _build_bottom_bar(bool is_dark, bool is_cjk) {
    final String primary_title = _current_step == 2
        ? easy.tr('creator_center.submit_review')
        : easy.tr('creator_center.next');

    return Container(
      constraints: const BoxConstraints(
        minHeight: WorkEditorStyle.bottom_bar_min_height,
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        11,
        16,
        11 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AuthorStyle.surface(is_dark),
        border: Border(top: BorderSide(color: AuthorStyle.border(is_dark))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: WorkEditorStyle.content_max_width,
          ),
          child: Row(
            children: <Widget>[
              if (_current_step == 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _save_draft,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AuthorStyle.primary_text(is_dark),
                      side: BorderSide(color: AuthorStyle.border(is_dark)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      easy.tr('creator_center.save_draft'),
                      style: TextStyle(
                        fontSize: is_cjk ? 14 : 12.5,
                        fontWeight: AuthorStyle.emphasis_weight,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _go_to_step(_current_step - 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(easy.tr('creator_center.previous')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AuthorStyle.primary_text(is_dark),
                      side: BorderSide(color: AuthorStyle.border(is_dark)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _current_step == 2
                      ? _submit_for_review
                      : () => _go_to_step(_current_step + 1),
                  icon: Icon(
                    _current_step == 2
                        ? Icons.send_rounded
                        : Icons.arrow_forward_rounded,
                    size: 19,
                  ),
                  label: Text(primary_title),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AuthorStyle.gold,
                    foregroundColor: const Color(0xFF1A1A18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: TextStyle(
                      fontSize: is_cjk ? 14 : 12.5,
                      fontWeight: AuthorStyle.title_weight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TODO 构建字段标题。
  Widget _build_field_label(
    String title,
    bool is_dark, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AuthorStyle.primary_text(is_dark),
          fontSize: 13,
          fontWeight: WorkEditorStyle.field_label_weight,
        ),
        children: <InlineSpan>[
          TextSpan(text: title),
          if (required)
            TextSpan(
              text: '  *',
              style: TextStyle(color: ColorConstants.dangerColor),
            ),
        ],
      ),
    );
  }

  /// TODO 构建连载状态选择按钮。
  Widget _build_choice_button({
    required bool is_dark,
    required bool selected,
    required IconData icon,
    required String title,
    required VoidCallback on_tap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: on_tap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? AuthorStyle.gold.withValues(alpha: 0.16)
                : AuthorStyle.secondary_surface(is_dark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AuthorStyle.gold : AuthorStyle.border(is_dark),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 19,
                color: selected
                    ? (is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold)
                    : AuthorStyle.secondary_text(is_dark),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? AuthorStyle.primary_text(is_dark)
                        : AuthorStyle.secondary_text(is_dark),
                    fontWeight: selected
                        ? AuthorStyle.emphasis_weight
                        : AuthorStyle.body_weight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TODO 输入框文字样式。
  TextStyle _input_text_style(bool is_dark) {
    return TextStyle(
      color: AuthorStyle.primary_text(is_dark),
      fontSize: 15,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    );
  }

  /// TODO 输入框统一装饰。
  InputDecoration _field_decoration(bool is_dark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AuthorStyle.secondary_text(is_dark),
        fontSize: 14,
        fontWeight: AuthorStyle.body_weight,
      ),
      filled: true,
      fillColor: AuthorStyle.secondary_surface(is_dark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AuthorStyle.border(is_dark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthorStyle.gold, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
