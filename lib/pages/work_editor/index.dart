// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/style.dart';
import 'package:app/pages/work_editor/widgets/steps/step_basic/step_basic.dart';
import 'package:app/pages/work_editor/widgets/steps/step_category/step_category.dart';
import 'package:app/pages/work_editor/widgets/steps/step_content/step_content.dart';
import 'package:app/pages/work_editor/widgets/steps/step_publish/step_publish.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/log_util.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'draft_persistence.dart';
import 'chapter_editing_session.dart';
import 'editor_form_manager.dart';
import 'editor_file_handler.dart';
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
  late final ChapterEditingSession _chapter_session;

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

  late final CreatorDraftPersistence _persistence;
  bool _is_saving = false;
  bool _has_changes = false;
  bool _allow_pop = false;
  int _chapter_change_version = 0;
  CreatorWorkDraft? _last_saved;
  bool _language_initialized = false;

  @override
  CreatorWorkType get fallback_work_type =>
      widget.initial_work?.work_type ?? CreatorWorkType.short;

  // ==================== Mixin 接口实现 ====================

  @override
  void Function(void Function()) get notifyStateChanged =>
      (change) => setState(() {
        change();
        _has_changes = true;
      });

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
    _introduction_controller = TextEditingController(
      text: work?.introduction ?? '',
    );
    _short_content_controller = TextEditingController(
      text: work?.short_content ?? '',
    );
    _chapter_title_controller = TextEditingController(
      text: work?.chapter_title ?? '',
    );
    _chapter_content_controller = TextEditingController(
      text: work?.chapter_content ?? '',
    );
    _is_completed = work?.is_completed ?? false;
    _cover_url = work?.cover_url;
    _persistence = CreatorDraftPersistence(initialWork: work);
    _language_code = work?.language_code ?? 'zh';
    _chapters = <CreatorChapterDraft>[...?work?.chapters];
    _chapter_session = ChapterEditingSession(
      chapters: _chapters,
      titleController: _chapter_title_controller,
      contentController: _chapter_content_controller,
    );
    _chapter_session.addListener(_on_chapter_changed);

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
        final group = find_preference_group_by_item_id(
          WorkEditorStyle.long_work_id,
        );
        if (group != null) {
          _selected_preference_map[group] = <int>{WorkEditorStyle.long_work_id};
        }
      }

      // 新增作品时，设置各偏好默认值。
      if (work == null) {
        set_default_preferences();
      }
    }
    _release_mode = work?.release_mode ?? CreatorReleaseMode.immediate;
    _scheduled_publish_time = work?.scheduled_publish_time;
    _rights_confirmed = work?.rights_confirmed ?? false;

    // 恢复保存时的步骤进度。
    if (work != null && work.saved_step > 0) {
      _current_step = work.saved_step.clamp(0, 3);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page_controller.hasClients) {
          _page_controller.jumpToPage(_current_step);
        }
      });
    }

    // 恢复完成后刷新错误状态（标记未填步骤）。
    refresh_error_steps();
    _title_controller.addListener(_mark_changed);
    _introduction_controller.addListener(_mark_changed);
    _short_content_controller.addListener(_mark_changed);
  }

  void _mark_changed() {
    if (mounted) setState(() => _has_changes = true);
  }

  Future<void> _request_leave() async {
    if (_is_saving) return;
    if (!_has_changes) {
      await _leave_editor(_last_saved);
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuthorStyle.surface(_device_info.dark.value),
        title: const Text('保存这次修改？'),
        content: const Text('你有尚未同步的修改，保存后下次可以继续写作。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('不保存离开'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('保存并离开'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') await _persist_work(leave: true);
    if (choice == 'discard') await _leave_editor(_last_saved);
  }

  Future<void> _leave_editor([CreatorWorkDraft? result]) async {
    setState(() {
      _allow_pop = true;
      _is_saving = false;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (context.mounted) Navigator.of(context).pop<CreatorWorkDraft>(result);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 新增作品时，首次设置默认语种为 app 当前语种。
    if (!_language_initialized) {
      _language_initialized = true;
      if (widget.initial_work == null) {
        _language_code = context.locale.languageCode;
      }
    }
  }

  @override
  void dispose() {
    _chapter_session.dispose();
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
    return _chapter_content_controller.text
        .replaceAll(RegExp(r'\s+'), '')
        .length;
  }

  // ==================== 步骤导航 ====================

  Future<void> _go_to_step(int step) async {
    if (_is_saving || step < 0 || step > 3 || step == _current_step) return;

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

  /// 保存和提交共用同一份完整表单，失败后留在编辑器以便重试。
  Future<void> _save_draft() => _persist_work();

  int _resolve_language_id() {
    final initial = widget.initial_work;
    if (initial != null &&
        initial.language_code == _language_code &&
        initial.language_id != null) {
      return initial.language_id!;
    }
    if (Get.isRegistered<LanguageStore>()) {
      final language = Get.find<LanguageStore>()
          .find_supported_language_by_code(_language_code);
      if (language != null && language.id > 0) return language.id;
    }
    throw const CreatorDraftException('语种配置尚未加载，请稍后重试');
  }

  Future<void> _persist_work({
    bool submitForReview = false,
    bool leave = false,
  }) async {
    if (_is_saving) return;
    if (_is_uploading_cover) {
      showBottomTip('封面正在上传，请稍候');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _is_saving = true);
    try {
      refresh_error_steps();
      final draft =
          build_work(
            CreatorWorkStatus.draft,
            local_id:
                widget.initial_work?.local_id ??
                'work_${DateTime.now().microsecondsSinceEpoch}',
            language_code: _language_code,
            current_step: _current_step,
            cover_url: _cover_url,
          ).copy_with(
            is_completed: work_type == CreatorWorkType.short || _is_completed,
            chapter_title: '',
            chapter_content: '',
          );
      final saved = await _persistence.save(
        draft,
        languageId: _resolve_language_id(),
        submitForReview: submitForReview,
      );
      if (!mounted) return;
      showBottomTip(submitForReview ? '已提交审核' : '草稿已保存');
      setState(() {
        _has_changes = false;
        _last_saved = saved;
      });
      if (submitForReview || leave) await _leave_editor(saved);
    } catch (error) {
      logUtil(msg: '保存或提交作品失败: $error', type: 'e');
      if (!mounted) return;
      showBottomTip(
        error is CreatorDraftException
            ? error.message
            : (submitForReview ? '提交审核失败，请重试' : '保存草稿失败，请重试'),
      );
    } finally {
      if (mounted) setState(() => _is_saving = false);
    }
  }

  void _on_chapter_changed() {
    if (!mounted) return;
    setState(() {
      if (_chapter_change_version != _chapter_session.changeVersion) {
        _chapter_change_version = _chapter_session.changeVersion;
        _has_changes = true;
      }
    });
  }

  void _select_chapter(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    _chapter_session.select(index);
  }

  Future<void> _remove_chapter(int index) async {
    final chapter = _chapters[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AuthorStyle.surface(_device_info.dark.value),
        title: const Text('删除这一章？'),
        content: Text(
          '“${chapter.title.isEmpty ? '未命名章节' : chapter.title}”将从草稿中移除。已发布的内容会在更新审核通过后删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留章节'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final current = _chapters.indexWhere(
        (c) => c.local_id == chapter.local_id,
      );
      _chapter_session.remove(current);
    }
  }

  Future<void> _submit_for_review() async {
    if (_is_saving) return;
    if (_title_controller.text.trim().isEmpty) {
      _go_to_step(0);
      showBottomTip('请填写作品标题');
      return;
    }
    if (selected_category_ids.isEmpty) {
      _go_to_step(1);
      showBottomTip('请选择作品分类');
      return;
    }
    if (work_type == CreatorWorkType.long) {
      if (_chapters.isEmpty ||
          _chapters.any(
            (chapter) =>
                chapter.title.trim().isEmpty || chapter.content.trim().isEmpty,
          )) {
        _go_to_step(2);
        showBottomTip('请至少完成一个章节，并补全章节标题和正文');
        return;
      }
    } else if (_short_content_controller.text.trim().isEmpty) {
      _go_to_step(2);
      showBottomTip('请填写短篇正文');
      return;
    }
    if (_release_mode == CreatorReleaseMode.scheduled &&
        (_scheduled_publish_time == null ||
            !_scheduled_publish_time!.isAfter(DateTime.now()))) {
      _go_to_step(3);
      showBottomTip('请选择未来的发布时间');
      return;
    }
    if (!_rights_confirmed) {
      _go_to_step(3);
      showBottomTip('请确认原创及授权声明');
      return;
    }
    await _persist_work(submitForReview: true);
  }

  // ==================== UI 构建 ====================

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

    final writingWithKeyboard =
        _current_step == 2 &&
        work_type == CreatorWorkType.long &&
        MediaQuery.viewInsetsOf(context).bottom > 0;
    return Obx(() {
      final bool is_dark = _device_info.dark.value;

      return PopScope(
        canPop:
            !_is_saving &&
            (_allow_pop || (!_has_changes && _last_saved == null)),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_is_saving) _request_leave();
        },
        child: Scaffold(
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
                  onPressed: _is_saving ? null : _save_draft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.themeColor,
                    foregroundColor: ColorConstants.lightTextColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                  child: Text(
                    _is_saving ? '保存中…' : easy.tr('creator_center.save_draft'),
                  ),
                ),
              ),
            ],
          ),
          body: AbsorbPointer(
            absorbing: _is_saving,
            child: Column(
              children: <Widget>[
                if (!writingWithKeyboard &&
                    widget.initial_work?.status == CreatorWorkStatus.published)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    color: AuthorStyle.gold.withValues(
                      alpha: is_dark ? .10 : .13,
                    ),
                    child: Text(
                      '正在编辑更新草稿 · 审核通过前，读者仍看到已发布版本',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: is_dark
                            ? AuthorStyle.gold
                            : AuthorStyle.deep_gold,
                      ),
                    ),
                  ),
                if (!writingWithKeyboard)
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
                        on_language_changed: (String code) => setState(() {
                          _language_code = code;
                          _has_changes = true;
                        }),
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
                        on_save_current_chapter: _chapter_session.add,
                        active_chapter_index: _chapter_session.activeIndex,
                        on_edit_chapter: _select_chapter,
                        on_delete_chapter: _remove_chapter,
                        on_reorder_chapters: _chapter_session.reorder,
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
                            setState(() {
                              _release_mode = mode;
                              _has_changes = true;
                            }),
                        on_select_schedule_time: () => select_schedule_time(
                          scheduled_publish_time: _scheduled_publish_time,
                          on_time_selected: (DateTime? time) {
                            setState(() => _scheduled_publish_time = time);
                          },
                        ),
                        on_rights_confirmed_changed: (bool value) =>
                            setState(() {
                              _rights_confirmed = value;
                              _has_changes = true;
                            }),
                      ),
                    ],
                  ),
                ),
                if (!writingWithKeyboard) _build_bottom_bar(is_dark, is_cjk),
              ],
            ),
          ),
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
                    onPressed: _is_saving ? null : _save_draft,
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
                  onPressed: _is_saving
                      ? null
                      : (_current_step == 3
                            ? _submit_for_review
                            : _try_next_step),
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
