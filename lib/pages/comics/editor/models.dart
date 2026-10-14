// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';

/// 生成创建用的幂等标识，重试时后端会返回同一条记录。
///
/// 格式满足 `/^[a-zA-Z0-9_-]{8,64}$/`。
String comic_editor_client_key(String prefix) {
  final int stamp = DateTime.now().microsecondsSinceEpoch;
  final int noise = DateTime.now().microsecond * 7919 % 100000;
  final String raw = '${prefix}_${stamp}_$noise';
  return raw.length <= 64 ? raw : raw.substring(raw.length - 64);
}

/// 编辑器可变图片页：保存时提交 image_url / width / height。
class ComicEditorImage {
  /// 图片公开 HTTPS 链接。
  String image_url;

  /// 像素宽，0 表示未知（阅读页按原图自适应）。
  int width;

  /// 像素高。
  int height;

  ComicEditorImage({required this.image_url, this.width = 0, this.height = 0});

  /// 从阅读侧的不可变模型转换。
  factory ComicEditorImage.from_data(ComicImageData data) => ComicEditorImage(
    image_url: data.image_url,
    width: data.width,
    height: data.height,
  );

  /// 提交到 `save_chapter.images` 的结构。
  Map<String, dynamic> to_json() => <String, dynamic>{
    'image_url': image_url,
    if (width > 0) 'width': width,
    if (height > 0) 'height': height,
  };

  /// 本地草稿序列化。
  Map<String, dynamic> to_draft_json() => <String, dynamic>{
    'image_url': image_url,
    'width': width,
    'height': height,
  };

  factory ComicEditorImage.from_draft_json(Map<String, dynamic> json) =>
      ComicEditorImage(
        image_url: json['image_url']?.toString() ?? '',
        width: comics_int(json['width']),
        height: comics_int(json['height']),
      );
}

/// 编辑器可变章节：绑定在某个语种下，携带乐观锁版本。
class ComicEditorChapter {
  /// 章节 id，0 表示尚未在服务端创建。
  int id;

  /// 章节乐观锁版本，更新时必须回传。
  int lock_version;

  /// 章节标题。
  String title;

  /// 排序序号，越小越靠前。
  int sort_order;

  /// 章节状态：draft / pending / published / rejected / hidden。
  String status;

  /// 有序图片列表，顺序即阅读顺序。
  final List<ComicEditorImage> images;

  /// 新建幂等标识。
  String client_key;

  ComicEditorChapter({
    this.id = 0,
    this.lock_version = 0,
    this.title = '',
    this.sort_order = 0,
    this.status = 'draft',
    List<ComicEditorImage>? images,
    String? client_key,
  }) : images = images ?? <ComicEditorImage>[],
       client_key = client_key ?? comic_editor_client_key('ch');

  /// 从详情接口的章节转换，保留 id 与锁版本。
  factory ComicEditorChapter.from_model(ComicChapter chapter) =>
      ComicEditorChapter(
        id: chapter.id,
        lock_version: chapter.lock_version,
        title: chapter.title,
        sort_order: chapter.sort_order,
        status: chapter.status,
        images: chapter.images.map(ComicEditorImage.from_data).toList(),
      );

  /// 新建空白章节。
  factory ComicEditorChapter.blank({required int sort_order}) =>
      ComicEditorChapter(sort_order: sort_order);

  /// 提交到 `save_chapter` 的参数体。
  Map<String, dynamic> to_save_json(int language_id) => <String, dynamic>{
    'comic_language_id': language_id,
    if (id > 0) 'chapter_id': id else 'client_key': client_key,
    if (id > 0) 'lock_version': lock_version,
    'title': title,
    'images': images.map((ComicEditorImage image) => image.to_json()).toList(),
    'sort_order': sort_order,
    'chapter_number': sort_order,
  };

  /// 本地草稿序列化。
  Map<String, dynamic> to_draft_json() => <String, dynamic>{
    'id': id,
    'lock_version': lock_version,
    'title': title,
    'sort_order': sort_order,
    'status': status,
    'client_key': client_key,
    'images': images
        .map((ComicEditorImage image) => image.to_draft_json())
        .toList(),
  };

  factory ComicEditorChapter.from_draft_json(Map<String, dynamic> json) =>
      ComicEditorChapter(
        id: comics_int(json['id']),
        lock_version: comics_int(json['lock_version']),
        title: json['title']?.toString() ?? '',
        sort_order: comics_int(json['sort_order']),
        status: json['status']?.toString() ?? 'draft',
        client_key: json['client_key']?.toString() ?? '',
        images: comics_list(
          json['images'],
        ).map(ComicEditorImage.from_draft_json).toList(),
      );
}

/// 编辑器可变语种版本：一门语言一份标题、简介与章节列表。
class ComicEditorLanguage {
  /// 语种记录 id，0 表示尚未创建。
  int id;

  /// 标准语种短代码，如 en / zh-CN。
  String language;

  /// 该语种版本标题。
  String title;

  /// 该语种版本简介。
  String description;

  /// 该语种版本封面，可为空（回退主封面）。
  String cover_url;

  /// 章节列表。
  final List<ComicEditorChapter> chapters;

  ComicEditorLanguage({
    this.id = 0,
    this.language = 'en',
    this.title = '',
    this.description = '',
    this.cover_url = '',
    List<ComicEditorChapter>? chapters,
  }) : chapters = chapters ?? <ComicEditorChapter>[];

  /// 从详情接口的语种转换。
  factory ComicEditorLanguage.from_model(
    ComicLanguage language, {
    List<ComicChapter> chapters = const <ComicChapter>[],
  }) => ComicEditorLanguage(
    id: language.id,
    language: language.language,
    title: language.title,
    description: language.description,
    cover_url: language.cover_url,
    chapters: chapters.map(ComicEditorChapter.from_model).toList(),
  );

  /// 新建空白语种版本。
  factory ComicEditorLanguage.blank({String language = 'en'}) =>
      ComicEditorLanguage(language: language);

  /// 提交到 `save_language` 的参数体。
  Map<String, dynamic> to_save_json(int comic_id) => <String, dynamic>{
    'comic_id': comic_id,
    if (id > 0) 'comic_language_id': id,
    'language': language,
    'title': title,
    'description': description,
    'cover_url': cover_url,
  };

  /// 本地草稿序列化。
  Map<String, dynamic> to_draft_json() => <String, dynamic>{
    'id': id,
    'language': language,
    'title': title,
    'description': description,
    'cover_url': cover_url,
    'chapters': chapters
        .map((ComicEditorChapter chapter) => chapter.to_draft_json())
        .toList(),
  };

  factory ComicEditorLanguage.from_draft_json(Map<String, dynamic> json) =>
      ComicEditorLanguage(
        id: comics_int(json['id']),
        language: json['language']?.toString() ?? 'en',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        cover_url: json['cover_url']?.toString() ?? '',
        chapters: comics_list(
          json['chapters'],
        ).map(ComicEditorChapter.from_draft_json).toList(),
      );
}

/// 编辑器可变主漫画：标题、封面、分类与语种版本。
class ComicEditorData {
  /// 漫画 id，0 表示尚未创建。
  int id;

  /// 主漫画乐观锁版本。
  int lock_version;

  /// 主标题。
  String title;

  /// 主封面 HTTPS 链接。
  String cover_url;

  /// 作品状态：draft / pending / published / rejected / hidden。
  String status;

  /// 审核备注。
  String review_note;

  /// 已选分类 id 列表。
  final List<int> category_ids;

  /// 语种版本列表。
  final List<ComicEditorLanguage> languages;

  /// 新建幂等标识。
  String client_key;

  ComicEditorData({
    this.id = 0,
    this.lock_version = 0,
    this.title = '',
    this.cover_url = '',
    this.status = 'draft',
    this.review_note = '',
    List<int>? category_ids,
    List<ComicEditorLanguage>? languages,
    String? client_key,
  }) : category_ids = category_ids ?? <int>[],
       languages = languages ?? <ComicEditorLanguage>[],
       client_key = client_key ?? comic_editor_client_key('cm');

  /// 是否为新建（尚未在服务端落库）。
  bool get is_new => id <= 0;

  /// 审核中禁止编辑（后端 lock_work 会直接拒绝写入）。
  bool get is_locked => status == 'pending';

  /// 提交到 `save` 的参数体。
  Map<String, dynamic> to_save_json() => <String, dynamic>{
    if (id > 0) 'comic_id': id else 'client_key': client_key,
    if (id > 0) 'lock_version': lock_version,
    'title': title,
    'cover_url': cover_url,
    'category_ids': category_ids.toList(),
  };

  /// 本地草稿序列化。
  Map<String, dynamic> to_draft_json() => <String, dynamic>{
    'id': id,
    'lock_version': lock_version,
    'title': title,
    'cover_url': cover_url,
    'status': status,
    'review_note': review_note,
    'client_key': client_key,
    'category_ids': category_ids.toList(),
    'languages': languages
        .map((ComicEditorLanguage language) => language.to_draft_json())
        .toList(),
  };

  factory ComicEditorData.from_draft_json(Map<String, dynamic> json) =>
      ComicEditorData(
        id: comics_int(json['id']),
        lock_version: comics_int(json['lock_version']),
        title: json['title']?.toString() ?? '',
        cover_url: json['cover_url']?.toString() ?? '',
        status: json['status']?.toString() ?? 'draft',
        review_note: json['review_note']?.toString() ?? '',
        client_key: json['client_key']?.toString() ?? '',
        category_ids: (json['category_ids'] is List)
            ? (json['category_ids'] as List)
                  .map((dynamic item) => comics_int(item))
                  .where((int id) => id > 0)
                  .toList()
            : <int>[],
        languages: comics_list(
          json['languages'],
        ).map(ComicEditorLanguage.from_draft_json).toList(),
      );

  /// 从详情接口装载主漫画。
  ///
  /// [languages] 已按语种装载章节。
  factory ComicEditorData.from_detail(
    ComicDetail detail, {
    required List<ComicEditorLanguage> languages,
  }) {
    final ComicItem comic = detail.comic;
    return ComicEditorData(
      id: comic.id,
      lock_version: comic.lock_version,
      title: comic.title,
      cover_url: comic.cover_url,
      status: comic.status,
      review_note: comic.review_reason,
      category_ids: comic.categories
          .map((Map<String, dynamic> item) => comics_int(item['id']))
          .where((int id) => id > 0)
          .toList(),
      languages: languages,
    );
  }
}
