import 'package:flutter/material.dart';

/// 首页书籍列表项类型。
class BookListItemType {
  /// 普通书籍项。
  static const int book = 1;

  /// 广告项。
  static const int ad = 2;
}

/// 首页书籍列表中的标签数据模型。
///
/// 这个模型用于描述单个标签的文案和主色，
/// 方便 UI 组件统一根据颜色生成浅色背景和文字颜色。
class BookListTagItem {
  /// 标签文案。
  final String label;

  /// 标签主色。
  final Color color;

  const BookListTagItem({required this.label, required this.color});
}

/// 首页书籍瀑布流卡片数据模型。
///
/// 这个模型统一承载封面、标题、简介、标签、角标和封面附加信息，
/// 后续接真实接口时只需要把接口字段映射到这里即可。
class BookListItem {
  /// 当前卡片的唯一标识。
  final String id;

  /// 书籍ID，用于跳转阅读页。
  final int story_id;

  /// 当前列表项类型。
  final int type;

  /// 书籍标题。
  final String title;

  /// 书籍简介。
  final String description;

  /// 封面图片地址。
  final String cover_url;

  /// 后端返回的封面原始宽度。
  final int cover_width;

  /// 后端返回的封面原始高度。
  final int cover_height;

  /// 封面宽高比（width / height）。
  ///
  /// 仅作为旧接口没有返回有效 [cover_width]、[cover_height] 时的回退值。
  /// 新数据通过后端宽高直接计算精确比例。
  final double cover_aspect_ratio;

  /// 封面左上角的小角标。
  final String cover_badge;

  /// 封面左下角附加信息。
  final String cover_meta_text;

  /// 标签列表。
  final List<BookListTagItem> tag_list;

  /// 广告图片列表。
  final List<String> ad_image_url_list;

  /// 出版状态。
  ///
  /// 4 表示短篇小说，需要跳转到短篇阅读页；
  /// 其他值表示普通小说，跳转到普通阅读页。
  final int publish_status;

  const BookListItem({
    required this.id,
    required this.story_id,
    required this.type,
    required this.title,
    required this.description,
    required this.cover_url,
    this.cover_width = 0,
    this.cover_height = 0,
    this.cover_aspect_ratio = 0.74,
    required this.cover_badge,
    required this.cover_meta_text,
    required this.tag_list,
    required this.ad_image_url_list,
    this.publish_status = 0,
  });

  /// 创建一个不承载业务素材的原生广告槽位。
  ///
  /// 广告内容由槽位对应的 Google [NativeAd] 动态填充，不把后端
  /// 广告配置或 SDK 对象混入小说数据模型。
  factory BookListItem.ad_slot({required String id}) {
    return BookListItem(
      id: id,
      story_id: 0,
      type: BookListItemType.ad,
      title: '',
      description: '',
      cover_url: '',
      cover_badge: '',
      cover_meta_text: '',
      tag_list: const <BookListTagItem>[],
      ad_image_url_list: const <String>[],
    );
  }

  /// 创建一个封面宽高比已填充的新实例。
  BookListItem withAspectRatio(double ratio) {
    return BookListItem(
      id: id,
      story_id: story_id,
      type: type,
      title: title,
      description: description,
      cover_url: cover_url,
      cover_width: cover_width,
      cover_height: cover_height,
      cover_aspect_ratio: ratio,
      cover_badge: cover_badge,
      cover_meta_text: cover_meta_text,
      tag_list: tag_list,
      ad_image_url_list: ad_image_url_list,
      publish_status: publish_status,
    );
  }

  /// 判断当前是否为普通书籍项。
  bool get is_book => type == BookListItemType.book;

  /// 后端是否已经返回可直接用于首帧布局的有效封面尺寸。
  bool get has_known_cover_dimensions => cover_width > 0 && cover_height > 0;

  /// 是否需要通过图片网络数据补充封面尺寸。
  bool get should_resolve_cover_dimensions => !has_known_cover_dimensions;

  /// 首帧应使用的封面宽高比（width / height）。
  double get effective_cover_aspect_ratio => has_known_cover_dimensions
      ? cover_width / cover_height
      : cover_aspect_ratio;

  /// 判断当前是否为广告项。
  bool get is_ad => type == BookListItemType.ad;

  /// 判断当前卡片是否存在简介。
  bool get has_description => description.trim().isNotEmpty;

  /// 判断当前卡片是否存在标签。
  bool get has_tags => tag_list.isNotEmpty;

  /// 判断当前卡片是否存在封面左上角角标。
  bool get has_cover_badge => cover_badge.trim().isNotEmpty;

  /// 判断当前卡片是否存在封面左下角附加信息。
  bool get has_cover_meta_text => cover_meta_text.trim().isNotEmpty;

  /// 判断当前广告项是否存在可展示的图片。
  bool get has_ad_images => ad_image_url_list.isNotEmpty;
}
