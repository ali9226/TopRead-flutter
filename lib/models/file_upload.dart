// TODO 文件上传的类型
class FileUpload {
  final bool status;
  final String content;
  final String message;
  final int? count; // 注意 count 可能为 null

  FileUpload({
    required this.status,
    required this.content,
    required this.message,
    this.count,
  });

  // 从 JSON 构造
  factory FileUpload.fromJson(Map<String, dynamic> json) {
    return FileUpload(
      status: json['status'] ?? false,
      content: json['content'] ?? '',
      message: json['message'] ?? '',
      count: json['count'], // 允许 null
    );
  }

  // 转回 JSON（可选）
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'content': content,
      'message': message,
      'count': count,
    };
  }
}
