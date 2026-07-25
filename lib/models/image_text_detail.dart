/// image_text/seo_detailed 接口返回模型。
///
/// 当前用于解析单条图文详情数据，后续如果这个模块还有列表接口，
/// 可以在这个文件里继续扩展对应的列表模型，保持领域模型集中维护。
class ImageTextDetail {
  /// 主键 id。
  final int id;

  /// 业务类型。
  final int type;

  /// 标题。
  final String title;

  /// 排序值。
  final int sorting;

  /// 备注。
  final String note;

  /// 删除状态。
  final int removeStatus;

  /// 封面图地址。
  final String cover;

  /// 跳转地址。
  final String jump;

  /// 副标题。
  final String subtitle;

  /// 简介。
  final String briefIntroduction;

  /// 富文本内容（HTML 字符串）。
  final String content;

  /// 创建时间。
  final String createTime;

  /// 更新时间。
  final String updateTime;

  /// 发布时间。
  final String releaseTime;

  /// 语种 ID。
  final int language;

  /// 类型文案。
  final String typeStr;

  const ImageTextDetail({
    required this.id,
    required this.type,
    required this.title,
    required this.sorting,
    required this.note,
    required this.removeStatus,
    required this.cover,
    required this.jump,
    required this.subtitle,
    required this.briefIntroduction,
    required this.content,
    required this.createTime,
    required this.updateTime,
    required this.releaseTime,
    required this.language,
    required this.typeStr,
  });

  /// 把动态值转换为 int。
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  factory ImageTextDetail.fromJson(Map<String, dynamic> json) {
    return ImageTextDetail(
      id: _parseInt(json['id']),
      type: _parseInt(json['type']),
      title: json['title']?.toString() ?? '',
      sorting: _parseInt(json['sorting']),
      note: json['note']?.toString() ?? '',
      removeStatus: _parseInt(json['remove_status']),
      cover: json['cover']?.toString() ?? '',
      jump: json['jump']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      briefIntroduction: json['brief_introduction']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createTime: json['create_time']?.toString() ?? '',
      updateTime: json['update_time']?.toString() ?? '',
      releaseTime: json['release_time']?.toString() ?? '',
      language: _parseInt(json['language']),
      typeStr: json['type_str']?.toString() ?? '',
    );
  }
}
