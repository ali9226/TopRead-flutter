// ignore_for_file: non_constant_identifier_names

import 'package:app/api/creator_work.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:app/pages/work_editor/widgets/steps/step_basic/step_basic.dart';
import 'package:app/pages/work_editor/widgets/steps/step_category/step_category.dart';
import 'package:app/pages/work_editor/widgets/steps/step_content/step_content.dart';
import 'package:app/pages/work_editor/widgets/steps/step_publish/step_publish.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/log_util.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'editor_form_manager.dart';
import 'editor_file_handler.dart';
import 'style.dart';
import 'widgets/editor_step_indicator.dart';

/// 创建或编辑小说的三步交互页面。
///
/// 当前页面只负责 Flutter UI 和本地状态：
/// 1. 基本资料与封面；
/// 2. 长篇章节或短篇正文；
/// 3. 审核通过后的发布方式。
///
/// 表单逻辑抽离到 [WorkEditorFormMixin]，文件处理抽离到 [WorkEditorFileMixin]。
class CreatorWorkEditorPage extends StatefulWidget {
  /// 已有作品；为空表示创建新作品。
  final CreatorWorkDraft? initial_work;

  const CreatorWorkEditorPage({super.key, this.initial_work});

  @override
  State<CreatorWorkEditorPage> createState() => _CreatorWorkEditorPageState();
}

class _CreatorWorkEditorPageState extends State<CreatorWorkEditorPage>
    with WorkEditorFormMixin, WorkEditorFileMixin {
  /// 设备主题状态。
  final DeviceInfo _device_info = Get.find<DeviceInfo>();

  /// 页面步骤控制器。
  final PageController _page_controller = PageController();

  /// 封面选择器。
  final ImagePicker _image_picker = ImagePicker();

  /// 标题输入控制器。
  late final TextEditingController _title_controller;

  /// 简介输入控制器。
  late final TextEditingController _introduction_controller;

  /// 短篇正文输入控制器。
  late final TextEditingController _short_content_controller;

  /// 长篇章节标题输入控制器。
  late final TextEditingController _chapter_title_controller;

  /// 长篇章节正文输入控制器。
  late final TextEditingController _chapter_content_controller;

  /// 当前步骤索引。
  int _current_step = 0;

  /// 是否完结。
  late bool _is_completed;

  /// 当前原始创作语种。
  late String _language_code;

  /// 各偏好分类的选中项。
  late Map<int, Set<int>> _selected_preference_map;

  /// 长篇章节列表。
  late List<CreatorChapterDraft> _chapters;

  /// 发布方式。
  late CreatorReleaseMode _release_mode;

  /// 定时发布时刻。
  DateTime? _scheduled_publish_time;

  /// 是否已确认原创和授权声明。
  bool _rights_confirmed = false;

  /// 本地封面图片路径。
  String? _cover_local_path;

  /// 已上传的封面 URL。
  String? _cover_url;

  /// 是否正在上传封面。
  bool _is_uploading_cover = false;

  /// 存在错误的步骤索引集合。
  final Set<int> _error_steps = <int>{};

  /// 后端作品ID（保存后更新）。
  int? _novel_id;

  /// 后端修订版本ID（保存后更新）。
  int? _revision_id;

  /// 后端语种版本ID（保存后更新）。
  int? _novel_language_id;

  /// 乐观锁版本号（保存后更新）。
  int? _lock_version;

  // ==================== Mixin 接口实现 ====================

  @override
  void Function(void Function()) get notifyStateChanged => setState;

  @override
  DeviceInfo get device_info => _device_info;

  @override
  ImagePicker get image_picker => _image_picker;

  @override
  List<CreatorChapterDraft> get chapters => _chapters;

  @override
  String? get cover_local_path => _cover_local_path;

  @override
  set cover_local_path(String? value) => _cover_local_path = value;

  @override
  String? get cover_url => _cover_url;

  @override
  set cover_url(String? value) => _cover_url = value;

  @override
  bool get is_uploading_cover => _is_uploading_cover;

  @override
  set is_uploading_cover(bool value) => _is_uploading_cover = value;

  @override
  Map<int, Set<int>> get selected_preference_map => _selected_preference_map;

  @override
  bool get rights_confirmed => _rights_confirmed;

  @override
  CreatorReleaseMode get release_mode => _release_mode;

  @override
  DateTime? get scheduled_publish_time => _scheduled_publish_time;

  @override
  Set<int> get error_steps => _error_steps;

  @override
  dynamic get title_controller => _title_controller;

  @override
  dynamic get introduction_controller => _introduction_controller;

  @override
  dynamic get short_content_controller => _short_content_controller;

  @override
  dynamic get chapter_title_controller => _chapter_title_controller;

  @override
  dynamic get chapter_content_controller => _chapter_content_controller;

  // ==================== 生命周期 ====================

  @override
  void initState() {
    super.initState();

    final CreatorWorkDraft? work = widget.initial_work;
    _title_controller = TextEditingController(text: work?.title ?? '');
    _introduction_controller = TextEditingController(text: work?.introduction ?? '');
    _short_content_controller = TextEditingController(text: work?.short_content ?? '');
    _chapter_title_controller = TextEditingController(text: work?.chapter_title ?? '');
    _chapter_content_controller = TextEditingController(text: work?.chapter_content ?? '');
    _is_completed = work?.is_completed ?? false;
    _language_code = work?.language_code ?? 'zh';
    _chapters = <CreatorChapterDraft>[...?work?.chapters];

    // 恢复所有偏好选择。
    if (work != null && work.preferences.isNotEmpty) {
      _selected_preference_map = <int, Set<int>>{};
      work.preferences.forEach((key, value) {
        final int? intKey = int.tryParse(key);
        if (intKey != null) {
          _selected_preference_map[intKey] = Set<int>.from(value);
        }
      });
    } else {
      _selected_preference_map = <int, Set<int>>{
        2: <int>{...?work?.category_ids},
      };

      // 编辑模式下，根据 work_type 设置篇幅偏好。
      if (work != null && work.work_type == CreatorWorkType.long) {
        _selected_preference_map[WorkEditorStyle.short_work_id] = <int>{WorkEditorStyle.long_work_id};
      }

      // 新增作品时，设置各偏好默认值。
      if (work == null) {
        set_default_preferences();
      }
    }
    _release_mode = work?.release_mode ?? CreatorReleaseMode.immediate;
    _scheduled_publish_time = work?.scheduled_publish_time;
    _rights_confirmed = work?.rights_confirmed ?? false;

    // 初始化后端ID
    _novel_id = work?.novel_id;
    _revision_id = work?.revision_id;
    _novel_language_id = work?.novel_language_id;
    _lock_version = work?.lock_version;

    // 恢复保存时的步骤进度。
    if (work != null && work.saved_step > 0) {
      _current_step = work.saved_step;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _page_controller.jumpToPage(_current_step);
      });
    }

    // 恢复完成后刷新错误状态（标记未填步骤）。
    refresh_error_steps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 新增作品时，首次设置默认语种为 app 当前语种。
    if (widget.initial_work == null && _language_code == 'zh') {
      _language_code = context.locale.languageCode;
    }
  }

  @override
  void dispose() {
    _page_controller.dispose();
    _title_controller.dispose();
    _introduction_controller.dispose();
    _short_content_controller.dispose();
    _chapter_title_controller.dispose();
    _chapter_content_controller.dispose();
    super.dispose();
  }

  // ==================== 计算属性 ====================

  /// 是否处于编辑已有作品状态。
  bool get _is_editing => widget.initial_work != null;

  /// 读取短篇正文非空白字符数。
  int get _short_word_count {
    return _short_content_controller.text.replaceAll(RegExp(r'\s+'), '').length;
  }

  /// 读取长篇所有章节总字数。
  int get _chapter_word_count {
    return _chapters.fold<int>(
      0,
      (int total, CreatorChapterDraft chapter) => total + chapter.word_count,
    );
  }

  /// 读取当前输入的长篇章节字数。
  int get _current_chapter_word_count {
    return _chapter_content_controller.text.replaceAll(RegExp(r'\s+'), '').length;
  }

  // ==================== 步骤导航 ====================

  Future<void> _go_to_step(int step) async {
    if (step < 0 || step > 3 || step == _current_step) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _current_step = step;
      refresh_error_steps();
    });
    await _page_controller.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// 进入下一步，同时刷新错误状态标记未填步骤。
  Future<void> _try_next_step() async {
    refresh_error_steps();
    await _go_to_step(_current_step + 1);
  }

  // ==================== 保存/提交 ====================

  /// 保存草稿到后端数据库。
  Future<void> _save_draft() async {
    refresh_error_steps();

    // 准备偏好数据
    final Map<String, List<int>> prefs = {};
    _selected_preference_map.forEach((key, value) {
      prefs[key.toString()] = value.toList();
    });

    // 准备分类快照
    final List<Map<String, dynamic>> categorySnapshot = selected_category_ids
        .map((id) => {'category_id': id})
        .toList();

    try {
      // 如果没有 novel_id，需要先创建作品
      if (_novel_id == null) {
        final int languageId = await LanguageUtil.get_language_id();
        final createResult = await CreatorWorkApi.createDraft(
          workType: work_type == CreatorWorkType.long ? 1 : 2,
          languageId: languageId,
          title: _title_controller.text.trim(),
          introduction: _introduction_controller.text.trim(),
        );

        if (!createResult.status || createResult.content == null) {
          if (!mounted) return;
          showBottomTip(createResult.message.isNotEmpty
              ? createResult.message
              : easy.tr('creator_center.draft_save_failed'));
          return;
        }

        // 更新状态变量
        setState(() {
          _novel_id = _parseIntNullable(createResult.content!['novel_id']);
          _revision_id = _parseIntNullable(createResult.content!['revision_id']);
          _novel_language_id = _parseIntNullable(createResult.content!['novel_language_id']);
          _lock_version = 0;
        });
      }

      // 计算字数
      final int wordCount = work_type == CreatorWorkType.short
          ? _short_content_controller.text.replaceAll(RegExp(r'\s+'), '').length
          : _chapters.fold<int>(0, (total, chapter) => total + chapter.word_count);

      // 语言代码转语言ID
      final int languageId = await _getLanguageId(_language_code);

      // 短篇内容和长篇临时章节分开处理
      final String? shortContent = work_type == CreatorWorkType.short
          ? _short_content_controller.text
          : null;
      final String? tempChapterTitle = work_type == CreatorWorkType.long
          ? _chapter_title_controller.text.trim()
          : null;
      final String? tempChapterContent = work_type == CreatorWorkType.long
          ? _chapter_content_controller.text
          : null;

      // 保存草稿到后端
      final saveResult = await CreatorWorkApi.saveDraft(
        novelId: _novel_id!,
        revisionId: _revision_id!,
        title: _title_controller.text.trim(),
        introduction: _introduction_controller.text.trim(),
        coverUrl: _cover_url,
        wordCount: wordCount,
        serializationStatus: _is_completed ? 2 : 1,
        categorySnapshot: categorySnapshot,
        lockVersion: _lock_version,
        preferences: prefs,
        savedStep: _current_step,
        rightsConfirmed: _rights_confirmed,
        releaseMode: _release_mode == CreatorReleaseMode.immediate ? 1 : 2,
        scheduledPublishTime: _scheduled_publish_time?.toIso8601String(),
        tempChapterTitle: tempChapterTitle,
        tempChapterContent: tempChapterContent,
        languageId: languageId,
        shortContent: shortContent,
      );

      if (!saveResult.status) {
        if (!mounted) return;
        showBottomTip(saveResult.message.isNotEmpty
            ? saveResult.message
            : easy.tr('creator_center.draft_save_failed'));
        return;
      }

      // 更新 lock_version
      final newLockVersion = _parseIntNullable(saveResult.content?['lock_version']);
      if (newLockVersion != null) {
        setState(() {
          _lock_version = newLockVersion;
        });
      }

      // 构建返回的草稿对象
      final CreatorWorkDraft draft = build_work(
        CreatorWorkStatus.draft,
        local_id: widget.initial_work?.local_id ?? 'work_${DateTime.now().microsecondsSinceEpoch}',
        language_code: _language_code,
        current_step: _current_step,
        cover_url: _cover_url,
      ).copy_with(
        novel_id: _novel_id,
        revision_id: _revision_id,
        novel_language_id: _novel_language_id,
        lock_version: _lock_version,
      );

      if (!mounted) return;
      showBottomTip(easy.tr('creator_center.draft_saved'));
      Navigator.of(context).pop<CreatorWorkDraft>(draft);
    } catch (e) {
      logUtil(msg: '保存草稿异常: $e', type: 'e');
      if (!mounted) return;
      showBottomTip(easy.tr('creator_center.draft_save_failed'));
    }
  }

  /// 安全解析可空整数
  int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// 语言代码转语言ID
  Future<int> _getLanguageId(String languageCode) async {
    // 常见语言代码映射
    const Map<String, int> languageMap = {
      'zh': 1,
      'en': 2,
      'fr': 3,
      'es': 4,
      'ar': 5,
      'pt': 6,
      'id': 7,
      'ja': 8,
      'ko': 9,
      'de': 10,
      'it': 11,
      'tr': 12,
      'th': 13,
      'vi': 14,
      'ms': 15,
      'sw': 16,
    };
    return languageMap[languageCode] ?? 2; // 默认英语
  }

  /// 语言ID转语言代码
  String _getLanguageCode(int languageId) {
    const Map<int, String> languageMap = {
      1: 'zh',
      2: 'en',
      3: 'fr',
      4: 'es',
      5: 'ar',
      6: 'pt',
      7: 'id',
      8: 'ja',
      9: 'ko',
      10: 'de',
      11: 'it',
      12: 'tr',
      13: 'th',
      14: 'vi',
      15: 'ms',
      16: 'sw',
    };
    return languageMap[languageId] ?? 'en';
  }

  /// 校验投稿资料并进入待审核状态。
  Future<void> _submit_for_review() async {
    if (_title_controller.text.trim().isEmpty) {
      _go_to_step(0);
      showBottomTip(easy.tr('creator_center.required_title'));
      return;
    }
    if (selected_category_ids.isEmpty) {
      _go_to_step(1);
      showBottomTip(easy.tr('creator_center.required_category'));
      return;
    }
    if (work_type == CreatorWorkType.long && _chapters.isEmpty) {
      _go_to_step(2);
      showBottomTip(easy.tr('creator_center.required_chapter'));
      return;
    }
    if (work_type == CreatorWorkType.short && _short_content_controller.text.trim().isEmpty) {
      _go_to_step(2);
      showBottomTip(easy.tr('creator_center.required_short_content'));
      return;
    }
    if (_release_mode == CreatorReleaseMode.scheduled && _scheduled_publish_time == null) {
      showBottomTip(easy.tr('creator_center.required_schedule'));
      return;
    }
    if (!_rights_confirmed) {
      showBottomTip(easy.tr('creator_center.required_rights'));
      return;
    }

    if (_novel_id == null || _revision_id == null) {
      // 需要先保存草稿
      await _save_draft();
      return;
    }

    try {
      // 先保存最新数据
      await _save_draft_only();

      // 提交审核
      final submitResult = await CreatorWorkApi.submit(
        novelId: _novel_id!,
        revisionId: _revision_id!,
        submissionType: 1, // 首次投稿
      );

      if (!submitResult.status) {
        if (!mounted) return;
        showBottomTip(submitResult.message.isNotEmpty
            ? submitResult.message
            : easy.tr('creator_center.submit_failed'));
        return;
      }

      final CreatorWorkDraft reviewing_work = build_work(
        CreatorWorkStatus.reviewing,
        local_id: widget.initial_work?.local_id ?? 'work_${DateTime.now().microsecondsSinceEpoch}',
        language_code: _language_code,
        current_step: _current_step,
        cover_url: _cover_url,
      ).copy_with(
        novel_id: _novel_id,
        revision_id: _revision_id,
      );

      if (!mounted) return;
      showBottomTip(easy.tr('creator_center.submitted'));
      Navigator.of(context).pop<CreatorWorkDraft>(reviewing_work);
    } catch (e) {
      logUtil(msg: '提交审核异常: $e', type: 'e');
      if (!mounted) return;
      showBottomTip(easy.tr('creator_center.submit_failed'));
    }
  }

  /// 仅保存草稿不返回（用于提交前的自动保存）。
  Future<bool> _save_draft_only() async {
    if (_novel_id == null || _revision_id == null) return false;

    try {
      final Map<String, List<int>> prefs = {};
      _selected_preference_map.forEach((key, value) {
        prefs[key.toString()] = value.toList();
      });

      final List<Map<String, dynamic>> categorySnapshot = selected_category_ids
          .map((id) => {'category_id': id})
          .toList();

      final int wordCount = work_type == CreatorWorkType.short
          ? _short_content_controller.text.replaceAll(RegExp(r'\s+'), '').length
          : _chapters.fold<int>(0, (total, chapter) => total + chapter.word_count);

      final saveResult = await CreatorWorkApi.saveDraft(
        novelId: _novel_id!,
        revisionId: _revision_id!,
        title: _title_controller.text.trim(),
        introduction: _introduction_controller.text.trim(),
        coverUrl: _cover_url,
        wordCount: wordCount,
        serializationStatus: _is_completed ? 2 : 1,
        categorySnapshot: categorySnapshot,
        lockVersion: _lock_version,
        preferences: prefs,
        savedStep: _current_step,
        rightsConfirmed: _rights_confirmed,
        releaseMode: _release_mode == CreatorReleaseMode.immediate ? 1 : 2,
        scheduledPublishTime: _scheduled_publish_time?.toIso8601String(),
        tempChapterTitle: _chapter_title_controller.text.trim(),
        tempChapterContent: _chapter_content_controller.text,
      );

      if (saveResult.status) {
        // 更新 lock_version
        final newLockVersion = _parseIntNullable(saveResult.content?['lock_version']);
        if (newLockVersion != null) {
          _lock_version = newLockVersion;
        }
      }

      return saveResult.status;
    } catch (e) {
      logUtil(msg: '保存草稿异常: $e', type: 'e');
      return false;
    }
  }

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);

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
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: _save_draft,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.themeColor,
                  foregroundColor: ColorConstants.lightTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: AuthorStyle.emphasis_weight,
                  ),
                ),
                child: Text(easy.tr('creator_center.save_draft')),
              ),
            ),
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
                    cover_local_path: _cover_local_path,
                    cover_url: _cover_url,
                    is_uploading_cover: _is_uploading_cover,
                    on_pick_cover: open_cover_picker,
                    on_language_changed: (String code) => setState(() => _language_code = code),
                  ),
                  StepCategory(
                    is_dark: is_dark,
                    selected_preference_map: _selected_preference_map,
                    on_toggle_preference: toggle_preference,
                  ),
                  StepContent(
                    is_dark: is_dark,
                    work_type: work_type,
                    is_editing: _is_editing,
                    chapters: _chapters,
                    short_content_controller: _short_content_controller,
                    chapter_title_controller: _chapter_title_controller,
                    chapter_content_controller: _chapter_content_controller,
                    chapter_word_count: _chapter_word_count,
                    short_word_count: _short_word_count,
                    current_chapter_word_count: _current_chapter_word_count,
                    on_edit_chapter: edit_chapter,
                    on_delete_chapter: delete_chapter,
                    on_reorder_chapters: (int old_index, int new_index) {
                      setState(() {
                        final CreatorChapterDraft item = _chapters.removeAt(old_index);
                        _chapters.insert(new_index, item);
                      });
                    },
                    on_short_content_changed: () => setState(() {}),
                    on_chapter_content_changed: () => setState(() {}),
                    on_short_file_upload: upload_short_file,
                    on_long_file_upload: upload_long_file,
                  ),
                  StepPublish(
                    is_dark: is_dark,
                    is_editing: _is_editing,
                    release_mode: _release_mode,
                    scheduled_publish_time: _scheduled_publish_time,
                    rights_confirmed: _rights_confirmed,
                    on_release_mode_changed: (CreatorReleaseMode mode) =>
                        setState(() => _release_mode = mode),
                    on_select_schedule_time: () => select_schedule_time(
                      scheduled_publish_time: _scheduled_publish_time,
                      on_time_selected: (DateTime? time) {
                        setState(() => _scheduled_publish_time = time);
                      },
                    ),
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
      constraints: const BoxConstraints(minHeight: WorkEditorStyle.bottom_bar_min_height),
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
          constraints: const BoxConstraints(maxWidth: WorkEditorStyle.content_max_width),
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
                  onPressed: _current_step == 3 ? _submit_for_review : _try_next_step,
                  icon: Icon(
                    _current_step == 3 ? Icons.send_rounded : Icons.arrow_forward_rounded,
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
