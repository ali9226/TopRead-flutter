// ignore_for_file: non_constant_identifier_names

/// 接口可能返回字符串数字，统一归一化，防止列表和阅读进度解析失败。
int comics_int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

/// 使用空对象兜底，所有漫画接口数据转换共用这一入口。
Map<String, dynamic> comics_map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// 过滤非法列表元素，避免单条异常数据阻止整页漫画加载。
List<Map<String, dynamic>> comics_list(dynamic value) => value is List
    ? value.whereType<Map>().map(comics_map).toList()
    : <Map<String, dynamic>>[];

bool comics_bool(dynamic value) => value == true || value == 1 || value == '1';

/// 漫画主作品；作者和分类属于主作品，翻译、章节和图片属于下级实体。
class ComicItem {
  final int id;
  final String title;
  final String cover_url;
  final int author_id;
  final String author_name;
  final String description;
  final List<Map<String, dynamic>> categories;
  final int chapter_count;
  final int language_count;
  final String status;
  final String completion_status;
  final String review_reason;
  final int lock_version;

  const ComicItem({
    required this.id,
    required this.title,
    required this.cover_url,
    required this.author_id,
    required this.author_name,
    this.description = '',
    required this.categories,
    required this.chapter_count,
    required this.language_count,
    required this.status,
    this.completion_status = 'ongoing',
    this.review_reason = '',
    this.lock_version = 0,
  });

  factory ComicItem.from_json(Map<String, dynamic> json) => ComicItem(
    id: comics_int(json['id']),
    title: json['title']?.toString() ?? '',
    cover_url: json['cover_url']?.toString() ?? '',
    author_id: comics_int(json['author_id']),
    author_name: json['author_name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    categories: comics_list(json['categories']),
    chapter_count: comics_int(json['chapter_count']),
    language_count: comics_int(json['language_count']),
    status: json['status']?.toString() ?? 'published',
    completion_status: json['completion_status']?.toString() ?? 'ongoing',
    review_reason:
        json['review_note']?.toString() ??
        json['review_reason']?.toString() ??
        '',
    lock_version: comics_int(json['lock_version']),
  );
}

/// 一个语种版本。id 是漫画翻译记录编号，与全局 language 表编号不同。
class ComicLanguage {
  final int id;
  final String language;
  final String title;
  final String description;
  final String cover_url;

  const ComicLanguage({
    required this.id,
    required this.language,
    required this.title,
    required this.description,
    required this.cover_url,
  });

  factory ComicLanguage.from_json(Map<String, dynamic> json) => ComicLanguage(
    id: comics_int(json['id']),
    language: json['language']?.toString() ?? 'en',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    cover_url: json['cover_url']?.toString() ?? '',
  );
}

/// 图片页的元数据。宽高用于读取之前预留尺寸，避免加载时阅读位置跳动。
class ComicImageData {
  final String image_url;
  final int width;
  final int height;

  const ComicImageData({
    required this.image_url,
    this.width = 0,
    this.height = 0,
  });

  factory ComicImageData.from_json(Map<String, dynamic> json) => ComicImageData(
    image_url: json['image_url']?.toString() ?? json['url']?.toString() ?? '',
    width: comics_int(json['width']),
    height: comics_int(json['height']),
  );

  Map<String, dynamic> to_json() => <String, dynamic>{
    'image_url': image_url,
    if (width > 0) 'width': width,
    if (height > 0) 'height': height,
  };
}

/// 章节图片严格按照接口顺序阅读，编辑器保存排序后的图片数组。
class ComicChapter {
  final int id;
  final String title;
  final int page_count;
  final int sort_order;
  final String status;
  final int lock_version;
  final List<ComicImageData> images;

  const ComicChapter({
    required this.id,
    required this.title,
    required this.page_count,
    required this.sort_order,
    required this.status,
    required this.images,
    this.lock_version = 0,
  });

  factory ComicChapter.from_json(Map<String, dynamic> json) => ComicChapter(
    id: comics_int(json['id']),
    title: json['title']?.toString() ?? '',
    page_count: comics_int(json['page_count']),
    sort_order: comics_int(json['sort_order']),
    status: json['status']?.toString() ?? 'published',
    lock_version: comics_int(json['lock_version']),
    images: comics_list(json['images']).map(ComicImageData.from_json).toList(),
  );
}

/// 漫画详情包括所有可用翻译和当前语种目录。
class ComicDetail {
  final ComicItem comic;
  final List<ComicLanguage> languages;
  final int selected_language_id;
  final List<ComicChapter> chapters;
  final bool is_collected;
  final Map<String, dynamic> read_record;

  const ComicDetail({
    required this.comic,
    required this.languages,
    required this.selected_language_id,
    required this.chapters,
    required this.is_collected,
    required this.read_record,
  });

  factory ComicDetail.from_json(Map<String, dynamic> json) => ComicDetail(
    comic: ComicItem.from_json(comics_map(json['comic'])),
    languages: comics_list(
      json['languages'],
    ).map(ComicLanguage.from_json).toList(),
    selected_language_id: comics_int(json['selected_language_id']),
    chapters: comics_list(
      json['chapters'],
    ).map(ComicChapter.from_json).toList(),
    is_collected: comics_bool(json['is_collected']),
    read_record: comics_map(json['read_record']),
  );

  ComicLanguage? get selected_language {
    for (final language in languages) {
      if (language.id == selected_language_id) return language;
    }
    return languages.isEmpty ? null : languages.first;
  }
}

/// 一个章节的完整阅读数据及相邻章节编号。
class ComicReading {
  final ComicItem comic;
  final ComicLanguage language;
  final ComicChapter chapter;
  final List<ComicImageData> images;
  final int previous_chapter_id;
  final int next_chapter_id;

  const ComicReading({
    required this.comic,
    required this.language,
    required this.chapter,
    required this.images,
    required this.previous_chapter_id,
    required this.next_chapter_id,
  });

  factory ComicReading.from_json(Map<String, dynamic> json) => ComicReading(
    comic: ComicItem.from_json(comics_map(json['comic'])),
    language: ComicLanguage.from_json(comics_map(json['language'])),
    chapter: ComicChapter.from_json(comics_map(json['chapter'])),
    images: comics_list(json['images']).map(ComicImageData.from_json).toList(),
    previous_chapter_id: comics_int(json['previous_chapter_id']),
    next_chapter_id: comics_int(json['next_chapter_id']),
  );
}
