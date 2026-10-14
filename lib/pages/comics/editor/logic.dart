// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:app/api/comics.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/editor/draft_storage.dart';
import 'package:app/pages/comics/editor/models.dart';
import 'package:app/pages/comics/editor/upload_image.dart';
import 'package:app/pages/comics/logic.dart';

/// 漫画编辑器业务逻辑：装载、校验、保存、提交、下架与本地草稿。
///
/// 保存顺序固定为主漫画 → 语种 → 章节，每一步都刷新乐观锁版本。
class ComicEditorLogic extends ComicsController {
  /// 作品 id，0 表示新建。
  final int comic_id;

  /// 当前编辑数据。
  ComicEditorData data = ComicEditorData();

  /// 分类原始列表（含多语种翻译）。
  List<Map<String, dynamic>> categories = <Map<String, dynamic>>[];

  /// 是否正在装载页面数据。
  bool loading = false;

  /// 是否正在保存草稿。
  bool saving = false;

  /// 是否正在提交审核。
  bool submitting = false;

  /// 是否正在上传图片。
  bool uploading_image = false;

  /// 是否存在未保存修改。
  bool dirty = false;

  /// 是否已从本地草稿恢复。
  bool restored_draft = false;

  /// 当前选中的语种下标（语种版本编辑区）。
  int selected_language_index = 0;

  /// 防抖写入本地草稿的计时器。
  Timer? _draft_timer;

  ComicEditorLogic(this.comic_id);

  /// 当前选中的语种版本，无语种时返回 null。
  ComicEditorLanguage? get selected_language {
    if (selected_language_index < 0 ||
        selected_language_index >= data.languages.length) {
      return null;
    }
    return data.languages[selected_language_index];
  }

  /// 是否处于保存/提交中。
  bool get busy => saving || submitting;

  /// 装载编辑器：分类 + 作品详情 + 本地草稿。
  Future<void> load() async {
    loading = true;
    error = null;
    emit();
    try {
      await _load_categories();
      if (comic_id > 0) {
        await _load_remote();
      } else {
        data = ComicEditorData();
      }
      await _try_restore_draft();
    } catch (failure) {
      error = failure.toString();
    } finally {
      loading = false;
      emit();
    }
  }

  /// 拉取分类列表，供多选标签展示。
  Future<void> _load_categories() async {
    try {
      final Map<String, dynamic> result = await comics_request('categories');
      categories = comics_list(result['list']);
    } catch (_) {
      // 分类失败不阻断编辑器打开，用户仍可先保存标题封面。
    }
  }

  /// 拉取服务端作品详情，并按语种装载章节与图片。
  Future<void> _load_remote() async {
    final ComicDetail detail = await comics_detail(comic_id);
    final List<ComicEditorLanguage> languages = <ComicEditorLanguage>[];

    /// 首个语种的章节已在详情中（作者预览含图片）。
    final ComicLanguage? first = detail.selected_language;
    if (first != null) {
      languages.add(
        ComicEditorLanguage.from_model(first, chapters: detail.chapters),
      );
    }

    /// 其余语种逐个拉取，保证每章图片顺序完整。
    for (final ComicLanguage language in detail.languages) {
      if (first != null && language.id == first.id) continue;
      final ComicDetail extra = await comics_detail(
        comic_id,
        language: language.language,
      );
      languages.add(
        ComicEditorLanguage.from_model(language, chapters: extra.chapters),
      );
    }

    /// 详情里未出现在 selected 的语种（例如无章节）也要保留元数据。
    final Set<int> loaded_ids = languages
        .map((ComicEditorLanguage item) => item.id)
        .toSet();
    for (final ComicLanguage language in detail.languages) {
      if (!loaded_ids.contains(language.id)) {
        languages.add(ComicEditorLanguage.from_model(language));
      }
    }

    data = ComicEditorData.from_detail(detail, languages: languages);
    selected_language_index = 0;
    dirty = false;
    restored_draft = false;
  }

  /// 尝试恢复本地草稿；仅当草稿比服务端更新的编辑痕迹时提示使用。
  Future<void> _try_restore_draft() async {
    final ComicEditorData? draft = await ComicDraftStorage.load(comic_id);
    if (draft == null) return;

    /// 新建：直接恢复草稿。
    if (comic_id <= 0) {
      data = draft;
      restored_draft = true;
      dirty = true;
      return;
    }

    /// 编辑已有作品：草稿 id 匹配才恢复，避免串稿。
    if (draft.id == comic_id) {
      data = draft;
      restored_draft = true;
      dirty = true;
    }
  }

  /// 丢弃本地草稿并重新从服务端装载。
  Future<void> discard_draft() async {
    await ComicDraftStorage.clear(comic_id);
    restored_draft = false;
    dirty = false;
    if (comic_id > 0) {
      await _load_remote();
    } else {
      data = ComicEditorData();
      selected_language_index = 0;
    }
    emit();
  }

  /// 标记脏数据并防抖写入本地草稿。
  void _touch() {
    dirty = true;
    _draft_timer?.cancel();
    _draft_timer = Timer(const Duration(milliseconds: 600), () {
      unawaited(ComicDraftStorage.save(comic_id, data));
    });
    emit();
  }

  // ---------- 表单变更 ----------

  /// 更新主标题。
  void set_title(String value) {
    data.title = value;
    _touch();
  }

  /// 更新主封面。
  void set_cover(String value) {
    data.cover_url = value;
    _touch();
  }

  /// 切换分类选中状态。
  void toggle_category(int category_id) {
    if (data.category_ids.contains(category_id)) {
      data.category_ids.remove(category_id);
    } else {
      data.category_ids.add(category_id);
    }
    _touch();
  }

  /// 选中某个语种版本。
  void select_language(int index) {
    if (index < 0 || index >= data.languages.length) return;
    selected_language_index = index;
    emit();
  }

  /// 新增一个语种版本并选中。
  void add_language({String language = 'en'}) {
    /// 同一语种只允许一个版本，自动跳到已有版本。
    final int existing = data.languages.indexWhere(
      (ComicEditorLanguage item) => item.language == language,
    );
    if (existing >= 0) {
      selected_language_index = existing;
      emit();
      return;
    }
    data.languages.add(ComicEditorLanguage.blank(language: language));
    selected_language_index = data.languages.length - 1;
    _touch();
  }

  /// 删除语种版本。
  void remove_language(int index) {
    if (index < 0 || index >= data.languages.length) return;
    data.languages.removeAt(index);
    if (selected_language_index >= data.languages.length) {
      selected_language_index = data.languages.isEmpty
          ? 0
          : data.languages.length - 1;
    }
    _touch();
  }

  /// 更新当前语种的基础字段。
  void update_language({
    String? language,
    String? title,
    String? description,
    String? cover_url,
  }) {
    final ComicEditorLanguage? target = selected_language;
    if (target == null) return;
    if (language != null) target.language = language;
    if (title != null) target.title = title;
    if (description != null) target.description = description;
    if (cover_url != null) target.cover_url = cover_url;
    _touch();
  }

  /// 在当前语种下新增章节。
  void add_chapter() {
    final ComicEditorLanguage? target = selected_language;
    if (target == null) return;
    target.chapters.add(
      ComicEditorChapter.blank(sort_order: target.chapters.length + 1),
    );
    _touch();
  }

  /// 删除章节。
  void remove_chapter(int index) {
    final ComicEditorLanguage? target = selected_language;
    if (target == null || index < 0 || index >= target.chapters.length) return;
    target.chapters.removeAt(index);
    _renumber(target);
    _touch();
  }

  /// 调整章节顺序。
  void reorder_chapter(int old_index, int new_index) {
    final ComicEditorLanguage? target = selected_language;
    if (target == null) return;
    if (new_index > old_index) new_index -= 1;
    final ComicEditorChapter chapter = target.chapters.removeAt(old_index);
    target.chapters.insert(new_index, chapter);
    _renumber(target);
    _touch();
  }

  /// 更新章节标题。
  void update_chapter_title(int index, String value) {
    final ComicEditorLanguage? target = selected_language;
    if (target == null || index < 0 || index >= target.chapters.length) return;
    target.chapters[index].title = value;
    _touch();
  }

  /// 在章节末尾追加图片。
  void add_chapter_images(int chapter_index, List<ComicEditorImage> images) {
    final ComicEditorLanguage? target = selected_language;
    if (target == null ||
        chapter_index < 0 ||
        chapter_index >= target.chapters.length) {
      return;
    }
    target.chapters[chapter_index].images.addAll(images);
    _touch();
  }

  /// 移除章节中的单张图片。
  void remove_chapter_image(int chapter_index, int image_index) {
    final ComicEditorLanguage? target = selected_language;
    if (target == null ||
        chapter_index < 0 ||
        chapter_index >= target.chapters.length) {
      return;
    }
    final List<ComicEditorImage> images =
        target.chapters[chapter_index].images;
    if (image_index < 0 || image_index >= images.length) return;
    images.removeAt(image_index);
    _touch();
  }

  /// 调整章节内图片顺序。
  void reorder_chapter_image(
    int chapter_index,
    int old_index,
    int new_index,
  ) {
    final ComicEditorLanguage? target = selected_language;
    if (target == null ||
        chapter_index < 0 ||
        chapter_index >= target.chapters.length) {
      return;
    }
    final List<ComicEditorImage> images =
        target.chapters[chapter_index].images;
    if (new_index > old_index) new_index -= 1;
    final ComicEditorImage image = images.removeAt(old_index);
    images.insert(new_index, image);
    _touch();
  }

  /// 重新编号章节 sort_order，保证目录顺序稳定。
  void _renumber(ComicEditorLanguage language) {
    for (int i = 0; i < language.chapters.length; i++) {
      language.chapters[i].sort_order = i + 1;
    }
  }

  /// 上传图片到文件服务，失败返回 null。
  Future<ComicImageData?> upload_image(
    Uint8List bytes,
    String filename, {
    int width = 0,
    int height = 0,
  }) async {
    uploading_image = true;
    emit();
    try {
      return await upload_comic_image(
        bytes,
        filename,
        width: width,
        height: height,
      );
    } finally {
      uploading_image = false;
      emit();
    }
  }

  // ---------- 校验 ----------

  /// 保存草稿校验：标题必填（后端硬性要求）。
  String? validate_for_save() {
    if (data.title.trim().isEmpty) return 'comics.title_required';
    return null;
  }

  /// 提交审核校验：标题、封面、分类、至少一章有图。
  String? validate_for_submit() {
    final String? basic = validate_for_save();
    if (basic != null) return basic;
    if (data.cover_url.trim().isEmpty) return 'comics.cover_required';
    if (data.category_ids.isEmpty) return 'comics.category_required';
    bool has_page = false;
    for (final ComicEditorLanguage language in data.languages) {
      for (final ComicEditorChapter chapter in language.chapters) {
        if (chapter.images.isNotEmpty) {
          has_page = true;
          break;
        }
      }
    }
    if (!has_page) return 'comics.pages_required';
    for (final ComicEditorLanguage language in data.languages) {
      if (language.title.trim().isEmpty) return 'comics.language_title_required';
      for (final ComicEditorChapter chapter in language.chapters) {
        if (chapter.title.trim().isEmpty) {
          return 'comics.chapter_title_required';
        }
        if (chapter.images.isEmpty) return 'comics.complete_chapters';
      }
    }
    return null;
  }

  // ---------- 保存 / 提交 / 下架 ----------

  /// 保存完整草稿：主漫画 → 语种 → 章节。
  ///
  /// 返回 null 表示成功；否则返回 i18n 错误键或服务端文案。
  Future<String?> save_draft() async {
    final String? invalid = validate_for_save();
    if (invalid != null) return invalid;
    if (busy) return null;
    saving = true;
    error = null;
    emit();
    try {
      await _save_all();
      dirty = false;
      restored_draft = false;
      await ComicDraftStorage.clear(comic_id);
      return null;
    } catch (failure) {
      final String message = failure.toString();
      error = message;
      /// 保存失败保留本地草稿，便于重试或恢复。
      await ComicDraftStorage.save(comic_id, data);
      return message;
    } finally {
      saving = false;
      emit();
    }
  }

  /// 执行保存管线并更新乐观锁版本。
  Future<void> _save_all() async {
    /// 1. 主漫画。
    final Map<String, dynamic> comic_result = await comics_request(
      'save',
      data.to_save_json(),
    );
    data.id = comics_int(comic_result['id']);
    data.lock_version = comics_int(comic_result['lock_version']);

    /// 2. 语种版本。
    for (final ComicEditorLanguage language in data.languages) {
      final Map<String, dynamic> language_result = await comics_request(
        'save_language',
        language.to_save_json(data.id),
      );
      language.id = comics_int(language_result['id']);
      data.lock_version = comics_int(
        language_result['comic_lock_version'] ?? data.lock_version,
      );

      /// 3. 该语种下的章节。
      for (final ComicEditorChapter chapter in language.chapters) {
        final Map<String, dynamic> chapter_result = await comics_request(
          'save_chapter',
          chapter.to_save_json(language.id),
        );
        chapter.id = comics_int(chapter_result['id']);
        chapter.lock_version = comics_int(chapter_result['lock_version']);
        data.lock_version = comics_int(
          chapter_result['comic_lock_version'] ?? data.lock_version,
        );
      }
    }
    data.status = 'draft';
  }

  /// 提交审核：先完整保存，再调用 submit。
  ///
  /// 返回 null 表示成功；否则返回 i18n 错误键或服务端文案。
  Future<String?> submit() async {
    final String? invalid = validate_for_submit();
    if (invalid != null) return invalid;
    if (busy) return null;
    submitting = true;
    error = null;
    emit();
    try {
      await _save_all();
      final Map<String, dynamic> result = await comics_request(
        'submit',
        <String, dynamic>{'comic_id': data.id},
      );
      data.status = result['status']?.toString() ?? 'pending';
      data.lock_version = comics_int(
        result['lock_version'] ?? data.lock_version,
      );
      dirty = false;
      restored_draft = false;
      await ComicDraftStorage.clear(comic_id);
      return null;
    } catch (failure) {
      final String message = failure.toString();
      error = message;
      await ComicDraftStorage.save(comic_id, data);
      return message;
    } finally {
      submitting = false;
      emit();
    }
  }

  /// 下架漫画（软删除，保留章节与评论）。
  ///
  /// 返回 null 表示成功。
  Future<String?> hide_comic() async {
    if (data.id <= 0) return 'comics.save_failed';
    try {
      final Map<String, dynamic> result = await comics_request(
        'remove',
        <String, dynamic>{'comic_id': data.id},
      );
      data.status = result['status']?.toString() ?? 'hidden';
      data.lock_version += 1;
      emit();
      return null;
    } catch (failure) {
      return failure.toString();
    }
  }

  @override
  void dispose() {
    _draft_timer?.cancel();
    super.dispose();
  }
}
