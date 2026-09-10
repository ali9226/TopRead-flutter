// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_basic/step_basic.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_category/step_category.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_content/step_content.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_publish/step_publish.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/util/log_util.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../_shared/draft_persistence.dart';
import '../_shared/editor_publish_policy.dart';
import '../_shared/widgets/editor_actions.dart';
import '../_shared/editor_form_manager.dart';
import '../_shared/editor_file_handler.dart';
import '../_shared/widgets/editor_step_indicator.dart';
import '../_shared/widgets/editor_keyboard_layout.dart';

/// 短篇小说编辑页面。
///
/// 固定为短篇类型，步骤：
/// 1. 基本资料与封面
/// 2. 偏好选择（分类）
/// 3. 正文编辑
/// 4. 发布方式
class ShortNovelEditorPage extends StatefulWidget {
  /// 已有作品；为空表示创建新作品。
  final CreatorWorkDraft? initial_work;

  final bool metadataOnly;
  final bool saveOnly;
  final bool restorePending;

  const ShortNovelEditorPage({
    super.key,
    this.initial_work,
    this.metadataOnly = false,
    this.saveOnly = false,
    this.restorePending = false,
  });

  @override
  State<ShortNovelEditorPage> createState() => _ShortNovelEditorPageState();
}

class _ShortNovelEditorPageState extends State<ShortNovelEditorPage>
    with WorkEditorFormMixin, WorkEditorFileMixin {
  final DeviceInfo _device_info = Get.find<DeviceInfo>();
  final PageController _page_controller = PageController();
  final ImagePicker _image_picker = ImagePicker();

  late final TextEditingController _title_controller;
  late final TextEditingController _introduction_controller;
  late final TextEditingController _short_content_controller;
  late final TextEditingController _chapter_title_controller;
  late final TextEditingController _chapter_content_controller;

  int _current_step = 0;
  late String _language_code;
  late Map<int, Set<int>> _selected_preference_map;
  late List<CreatorChapterDraft> _chapters;
  late CreatorReleaseMode _release_mode;
  DateTime? _scheduled_publish_time;
  bool _rights_confirmed = false;
  String? _cover_local_path;
  String? _cover_url;
  bool _is_uploading_cover = false;
  final Set<int> _error_steps = <int>{};

  late final CreatorDraftPersistence _persistence;
  bool _is_saving = false;
  bool _has_changes = false;
  bool _allow_pop = false;
  CreatorWorkDraft? _last_saved;
  bool _language_initialized = false;

  @override
  CreatorWorkType get fallback_work_type => CreatorWorkType.short;

  @override
  CreatorWorkType get work_type => CreatorWorkType.short;

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
  int get active_chapter_index => -1;

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
    _chapter_title_controller = TextEditingController();
    _chapter_content_controller = TextEditingController();
    _cover_url = work?.cover_url;
    _persistence = CreatorDraftPersistence(initialWork: work);
    _language_code = work?.language_code ?? 'zh';
    _chapters = <CreatorChapterDraft>[];

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

      // 设置短篇偏好
      final group = find_preference_group_by_item_id(
        WorkEditorStyle.short_work_id,
      );
      if (group != null) {
        _selected_preference_map[group] = <int>{WorkEditorStyle.short_work_id};
      }

      if (work == null) {
        set_default_preferences();
      }
    }

    _release_mode = _policy.is_published
        ? CreatorReleaseMode.immediate
        : work?.release_mode ?? CreatorReleaseMode.immediate;
    _scheduled_publish_time = work?.scheduled_publish_time;
    _rights_confirmed =
        _policy.is_published || (work?.rights_confirmed ?? false);

    if (work != null && work.saved_step > 0) {
      _current_step = work.saved_step.clamp(0, _lastStep);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _page_controller.hasClients) {
          _page_controller.jumpToPage(_current_step);
        }
      });
    }

    _has_changes = widget.restorePending;
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
    String? choice;
    await showMessage(
      message: easy.tr('creator_center.unsaved_changes_message'),
      iconData: Icons.save_outlined,
      leftButtonText: easy.tr('creator_center.no_save'),
      rightButtonText: easy.tr(
        _policy.can_save_draft
            ? 'creator_center.save_and_exit'
            : 'creator_center.publish_and_exit',
      ),
      allowMaskDismiss: true,
      onLeftPressed: () async => choice = 'discard',
      onRightPressed: () async => choice = 'save',
    );
    if (!mounted) return;
    if (choice == 'save') {
      if (_policy.can_save_draft) {
        await _persist_work(leave: true);
      } else {
        await _publish();
      }
    }
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
    if (!_language_initialized) {
      _language_initialized = true;
      if (widget.initial_work == null) {
        _language_code = context.locale.languageCode;
      }
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

  bool get _is_editing => widget.initial_work != null;

  EditorPublishPolicy get _policy => EditorPublishPolicy(widget.initial_work);

  bool get _show_publish_step =>
      !widget.metadataOnly && !widget.saveOnly && _policy.show_publish_step;

  int get _short_word_count {
    return _short_content_controller.text.replaceAll(RegExp(r'\s+'), '').length;
  }

  int get _lastStep => widget.metadataOnly
      ? 1
      : _show_publish_step
      ? 3
      : 2;

  Future<void> _go_to_step(int step) async {
    if (_is_saving || step < 0 || step > _lastStep || step == _current_step) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _current_step = step;
      refresh_error_steps();
    });
    await _page_controller.animateToPage(
      step,
      duration: WorkEditorStyle.step_animation_duration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _try_next_step() async {
    refresh_error_steps();
    await _go_to_step(_current_step + 1);
  }

  Future<void> _save_draft() async {
    if (_policy.can_save_draft) await _persist_work();
  }

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
    throw CreatorDraftException(easy.tr('creator_center.config_not_loaded'));
  }

  Future<void> _persist_work({bool publish = false, bool leave = false}) async {
    if (_is_saving || (!publish && !_policy.can_save_draft)) return;
    if (_is_uploading_cover) {
      showBottomTip(easy.tr('creator_center.cover_uploading'));
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _is_saving = true);
    try {
      refresh_error_steps();
      final draft = build_work(
        widget.initial_work?.status ?? CreatorWorkStatus.draft,
        local_id:
            widget.initial_work?.local_id ??
            _last_saved?.local_id ??
            'work_${DateTime.now().microsecondsSinceEpoch}',
        language_code: _language_code,
        current_step: _current_step,
        cover_url: _cover_url,
      ).copy_with(is_completed: true, chapter_title: '', chapter_content: '');
      final saved = await _persistence.save(
        draft,
        languageId: _resolve_language_id(),
        publish: publish,
      );
      if (!mounted) return;
      showBottomTip(
        easy.tr(
          publish
              ? (_release_mode == CreatorReleaseMode.scheduled
                    ? 'creator_center.scheduled_success'
                    : 'creator_center.published_success')
              : 'creator_center.draft_saved',
        ),
      );
      setState(() {
        _has_changes = false;
        _last_saved = saved;
      });
      if (publish || leave) await _leave_editor(saved);
    } catch (error) {
      logUtil(msg: '保存或发布作品失败: $error', type: 'e');
      if (!mounted) return;
      showBottomTip(
        error is CreatorDraftException
            ? error.message
            : (publish
                  ? easy.tr('creator_center.publish_failed')
                  : easy.tr('creator_center.save_draft_failed')),
      );
    } finally {
      if (mounted) setState(() => _is_saving = false);
    }
  }

  Future<void> _publish() async {
    if (_is_saving) return;
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
    if (_short_content_controller.text.trim().isEmpty) {
      _go_to_step(2);
      showBottomTip(easy.tr('creator_center.required_short_content'));
      return;
    }
    if (_show_publish_step &&
        _release_mode == CreatorReleaseMode.scheduled &&
        (_scheduled_publish_time == null ||
            !_scheduled_publish_time!.isAfter(DateTime.now()))) {
      _go_to_step(3);
      showBottomTip(easy.tr('creator_center.required_schedule'));
      return;
    }
    if (_show_publish_step && !_rights_confirmed) {
      _go_to_step(3);
      showBottomTip(easy.tr('creator_center.required_rights'));
      return;
    }
    await _persist_work(publish: true);
  }

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );

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
          resizeToAvoidBottomInset: _current_step != 2,
          backgroundColor: AuthorStyle.background(is_dark),
          appBar: AppBar(
            backgroundColor: AuthorStyle.surface(is_dark),
            surfaceTintColor: Colors.transparent,
            foregroundColor: AuthorStyle.primary_text(is_dark),
            elevation: 0,
            title: Text(
              _is_editing
                  ? easy.tr('creator_center.edit_work_title')
                  : easy.tr('creator_center.short_novel_editor_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: AuthorStyle.title_weight,
              ),
            ),
            actions: <Widget>[
              if (_policy.can_save_draft)
                EditorSaveDraftButton(
                  is_saving: _is_saving,
                  on_save: _save_draft,
                ),
            ],
          ),
          bottomNavigationBar: _current_step == 2
              ? null
              : AbsorbPointer(
                  absorbing: _is_saving,
                  child: _build_bottom_bar(is_dark, is_cjk),
                ),
          body: AbsorbPointer(
            absorbing: _is_saving,
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: EditorKeyboardLayout(
                collapse_when_editing: _current_step == 2,
                header: Column(
                  children: [
                    if (_policy.is_published || _policy.is_scheduled)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        color: AuthorStyle.gold.withValues(
                          alpha: is_dark ? .10 : .13,
                        ),
                        child: Text(
                          easy.tr(
                            _policy.is_scheduled
                                ? 'creator_center.scheduled_edit_hint'
                                : 'creator_center.editing_published_hint',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: is_dark
                                ? AuthorStyle.gold
                                : AuthorStyle.deep_gold,
                          ),
                        ),
                      ),
                    EditorStepIndicator(
                      current_step: _current_step,
                      labels: <String>[
                        easy.tr('creator_center.step_basic'),
                        easy.tr('creator_center.step_category'),
                        if (!widget.metadataOnly)
                          easy.tr('creator_center.step_content'),
                        if (_show_publish_step)
                          easy.tr('creator_center.step_publish'),
                      ],
                      is_dark: is_dark,
                      error_steps: _error_steps,
                      on_step_tap: (int step) => _go_to_step(step),
                    ),
                  ],
                ),
                content: AbsorbPointer(
                  absorbing: _is_saving,
                  child: PageView(
                    key: const PageStorageKey<String>(
                      'short_novel_editor_page_view',
                    ),
                    controller: _page_controller,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      StepBasic(
                        key: const ValueKey('step_basic'),
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
                        key: const ValueKey('step_category'),
                        is_dark: is_dark,
                        selected_preference_map: _selected_preference_map,
                        on_toggle_preference: toggle_preference,
                        showLength: false,
                      ),
                      if (!widget.metadataOnly)
                        StepContent(
                          key: const ValueKey('step_content'),
                          is_dark: is_dark,
                          work_type: CreatorWorkType.short,
                          is_editing: _is_editing,
                          chapters: _chapters,
                          short_content_controller: _short_content_controller,
                          chapter_title_controller: _chapter_title_controller,
                          chapter_content_controller:
                              _chapter_content_controller,
                          short_word_count: _short_word_count,
                          current_chapter_word_count: 0,
                          on_save_current_chapter: () {},
                          active_chapter_index: -1,
                          on_edit_chapter: (_) {},
                          on_delete_chapter: (_) {},
                          on_reorder_chapters: (_, __) {},
                          on_short_content_changed: () => setState(() {}),
                          on_chapter_content_changed: () => setState(() {}),
                          on_short_file_upload: upload_short_file,
                          on_long_file_upload: upload_long_file,
                        ),
                      if (_show_publish_step)
                        StepPublish(
                          key: const ValueKey('step_publish'),
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
                              setState(() {
                                _scheduled_publish_time = time;
                                _has_changes = true;
                              });
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
                footer: _current_step == 2
                    ? _build_bottom_bar(is_dark, is_cjk)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _build_bottom_bar(bool is_dark, bool is_cjk) {
    final is_last_step = _current_step == _lastStep;
    final save_only =
        (widget.saveOnly || widget.metadataOnly) && _policy.can_save_draft;
    return EditorBottomBar(
      is_dark: is_dark,
      is_cjk: is_cjk,
      current_step: _current_step,
      is_last_step: is_last_step,
      primary_title: easy.tr(
        is_last_step
            ? (save_only
                  ? 'creator_workspace.save_return'
                  : 'creator_center.publish')
            : 'creator_center.next',
      ),
      on_primary: _is_saving
          ? null
          : is_last_step
          ? (save_only ? () => _persist_work(leave: true) : _publish)
          : _try_next_step,
      on_previous: () => _go_to_step(_current_step - 1),
      on_save_draft: _policy.can_save_draft ? _save_draft : null,
    );
  }
}
