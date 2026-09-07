// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/preference.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/chapter_editor/index.dart';
import 'package:app/pages/author_center/logic.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/steps/step_basic/step_basic.dart';
import 'package:app/pages/work_editor/steps/step_category/step_category.dart';
import 'package:app/pages/work_editor/steps/step_content/step_content.dart';
import 'package:app/pages/work_editor/steps/step_publish/step_publish.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'style.dart';
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

  /// TODO 当前选择的分类 id（从偏好 map 中提取）。
  Set<int> get _selected_category_ids {
    const int category_type_id = 2;
    return _selected_preference_map[category_type_id] ?? <int>{};
  }

  /// TODO 各偏好分类的选中项（key 为偏好类别 id，value 为已选选项 id 集合）。
  late Map<int, Set<int>> _selected_preference_map;

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

  /// TODO 存在错误的步骤索引集合。
  final Set<int> _error_steps = <int>{};

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
    _work_type = work?.work_type ?? CreatorWorkType.short;
    _is_completed = work?.is_completed ?? false;
    _language_code = work?.language_code ?? 'zh';
    _selected_preference_map = <int, Set<int>>{
      2: <int>{...?work?.category_ids},
    };
    _chapters = <CreatorChapterDraft>[...?work?.chapters];

    /// 新增作品时，设置各偏好默认值。
    if (work == null) {
      _set_default_preferences();
    }
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

  /// TODO 页面可选分类，取自全局偏好缓存中的「内容偏好」分组。
  List<PreferenceItem> get _category_options => CreatorLogic.category_options;

  /// TODO 新增作品时设置各偏好默认值。
  ///
  /// 性别偏好：无所谓（ID 113）
  /// 篇幅：短篇（ID 119）
  /// 状态：连载中（按标题匹配）
  void _set_default_preferences() {
    final PreferenceStore store = Get.find<PreferenceStore>();

    /// 按 ID 直接设置默认值（性别无所谓=113，篇幅短篇=119）。
    _set_preference_by_id(store, 113);
    _set_preference_by_id(store, 119);

    /// 状态（连载中）按标题匹配。
    for (final Preference pref in store.preference_list) {
      final String title = pref.title;
      if (title.contains('完结') || title.toLowerCase().contains('complet')) {
        for (final PreferenceItem item in pref.data_list) {
          if (item.title.contains('连载') || item.title.toLowerCase().contains('serial')) {
            _selected_preference_map[pref.id] = <int>{item.id};
            return;
          }
        }
        return;
      }
    }
  }

  /// TODO 根据选项 ID 设置其所属偏好分组的默认选中。
  void _set_preference_by_id(PreferenceStore store, int item_id) {
    for (final Preference pref in store.preference_list) {
      for (final PreferenceItem item in pref.data_list) {
        if (item.id == item_id) {
          _selected_preference_map[pref.id] = <int>{item_id};
          return;
        }
      }
    }
  }

  /// TODO 判断是否为强制单选偏好（状态、篇幅）。
  bool _is_force_single_preference(Preference pref) {
    final String title = pref.title;
    if (title.contains('完结') || title.toLowerCase().contains('complet')) {
      return true;
    }
    return title.contains('篇幅') || title.toLowerCase().contains('length');
  }

  /// TODO 切换偏好选中状态。
  ///
  /// 单选偏好：再次点击取消，否则替换为仅该项。
  /// 多选偏好：追加或移除。
  void _toggle_preference(int preference_id, int item_id) {
    setState(() {
      final Set<int> current =
          _selected_preference_map[preference_id] ?? <int>{};

      /// 查找偏好配置判断单选/多选，本地强制单选优先。
      final PreferenceStore store = Get.find<PreferenceStore>();
      final Preference? pref = store.find_preference_by_id(preference_id);
      final bool is_single =
          pref != null ? _is_force_single_preference(pref) || pref.is_single_select : true;

      if (is_single) {
        /// 单选：再次点击取消，否则替换。
        if (current.contains(item_id)) {
          _selected_preference_map[preference_id] = <int>{};
        } else {
          _selected_preference_map[preference_id] = <int>{item_id};
        }
      } else {
        /// 多选：追加或移除。
        final Set<int> next = Set<int>.from(current);
        if (next.contains(item_id)) {
          next.remove(item_id);
        } else {
          next.add(item_id);
        }
        _selected_preference_map[preference_id] = next;
      }
    });
  }

  /// TODO 校验指定步骤是否填写完整，返回 true 表示通过。
  bool _validate_step(int step) {
    switch (step) {
      case 0:
        return _title_controller.text.trim().isNotEmpty &&
            (_cover_bytes != null || _is_editing);
      case 1:
        return _selected_category_ids.isNotEmpty;
      case 2:
        if (_work_type == CreatorWorkType.long) {
          return _chapters.isNotEmpty;
        }
        return _short_content_controller.text.trim().isNotEmpty;
      case 3:
        if (_release_mode == CreatorReleaseMode.scheduled) {
          return _scheduled_publish_time != null && _rights_confirmed;
        }
        return _rights_confirmed;
      default:
        return true;
    }
  }

  /// TODO 刷新所有步骤的错误状态集合。
  void _refresh_error_steps() {
    _error_steps.clear();
    for (int i = 0; i < 4; i++) {
      if (!_validate_step(i)) {
        _error_steps.add(i);
      }
    }
  }

  Future<void> _go_to_step(int step) async {
    if (step < 0 || step > 3 || step == _current_step) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _current_step = step;
      _refresh_error_steps();
    });
    await _page_controller.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// TODO 进入下一步，同时刷新错误状态标记未填步骤。
  Future<void> _try_next_step() async {
    _refresh_error_steps();
    await _go_to_step(_current_step + 1);
  }

  /// TODO 上传短篇文件（txt、word等），解析内容到正文框。
  ///
  /// 需要添加 file_picker 依赖：`flutter pub add file_picker`
  Future<void> _upload_short_file() async {
    // TODO: 实现文件上传功能，需要安装 file_picker 包
    showBottomTip(easy.tr('creator_center.file_upload_coming_soon'));
  }

  /// TODO 上传长篇文件（txt、word等），解析内容为新章节。
  ///
  /// 需要添加 file_picker 依赖：`flutter pub add file_picker`
  Future<void> _upload_long_file() async {
    // TODO: 实现文件上传功能，需要安装 file_picker 包
    showBottomTip(easy.tr('creator_center.file_upload_coming_soon'));
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
      category_ids: _selected_category_ids.toList(growable: false),
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
    if (_selected_category_ids.isEmpty) {
      _go_to_step(1);
      showBottomTip(easy.tr('creator_center.required_category'));
      return;
    }
    if (_work_type == CreatorWorkType.long && _chapters.isEmpty) {
      _go_to_step(2);
      showBottomTip(easy.tr('creator_center.required_chapter'));
      return;
    }
    if (_work_type == CreatorWorkType.short &&
        _short_content_controller.text.trim().isEmpty) {
      _go_to_step(2);
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
                easy.tr('creator_center.step_category'),
                easy.tr('creator_center.step_content'),
                easy.tr('creator_center.step_publish'),
              ],
              is_dark: is_dark,
              error_steps: _error_steps,
              on_step_tap: (int step) => _go_to_step(step),
            ),
            Expanded(
              child: PageView(
                controller: _page_controller,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  StepBasic(
                    is_dark: is_dark,
                    is_editing: _is_editing,
                    title_controller: _title_controller,
                    introduction_controller: _introduction_controller,
                    language_code: _language_code,
                    cover_bytes: _cover_bytes,
                    is_picking_cover: _is_picking_cover,
                    on_open_cover_picker: _open_cover_picker,
                    on_language_changed: (String code) =>
                        setState(() => _language_code = code),
                  ),
                  StepCategory(
                    is_dark: is_dark,
                    selected_preference_map: _selected_preference_map,
                    on_toggle_preference: _toggle_preference,
                  ),
                  StepContent(
                    is_dark: is_dark,
                    work_type: _work_type,
                    is_editing: _is_editing,
                    chapters: _chapters,
                    short_content_controller: _short_content_controller,
                    chapter_word_count: _chapter_word_count,
                    short_word_count: _short_word_count,
                    on_add_chapter: _add_chapter,
                    on_edit_chapter: _edit_chapter,
                    on_delete_chapter: _delete_chapter,
                    on_reorder_chapters: (int old_index, int new_index) {
                      setState(() {
                        final CreatorChapterDraft item =
                            _chapters.removeAt(old_index);
                        _chapters.insert(new_index, item);
                      });
                    },
                    on_short_content_changed: () => setState(() {}),
                    on_short_file_upload: _upload_short_file,
                    on_long_file_upload: _upload_long_file,
                  ),
                  StepPublish(
                    is_dark: is_dark,
                    is_editing: _is_editing,
                    release_mode: _release_mode,
                    scheduled_publish_time: _scheduled_publish_time,
                    rights_confirmed: _rights_confirmed,
                    on_release_mode_changed: (CreatorReleaseMode mode) =>
                        setState(() => _release_mode = mode),
                    on_select_schedule_time: _select_schedule_time,
                    on_rights_confirmed_changed: (bool value) =>
                        setState(() => _rights_confirmed = value),
                  ),
                ],
              ),
            ),
            _build_bottom_bar(is_dark, is_cjk),
          ],
        ),
      );
    });
  }
  Widget _build_bottom_bar(bool is_dark, bool is_cjk) {
    final String primary_title = _current_step == 3
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
                  onPressed: _current_step == 3
                      ? _submit_for_review
                      : _try_next_step,
                  icon: Icon(
                    _current_step == 3
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
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
