// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:app/api/dio_client.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/file_upload.dart';
import 'package:app/models/comics.dart';
import 'package:dio/dio.dart';

/// 漫画图片上传：走应用统一的 `file/add` 表单接口。
///
/// 返回可被漫画后端 `image_url` 校验接受的公开链接；
/// 失败返回 null，由调用方提示用户重试。
Future<ComicImageData?> upload_comic_image(
  Uint8List bytes,
  String filename, {
  int width = 0,
  int height = 0,
}) async {
  try {
    final Response<dynamic> response = await DioClient().instance.post<dynamic>(
      '${Constant.requestUrl}${Constant.prefix}file/add',
      data: FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final dynamic raw = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (response.statusCode != 200 || raw is! Map<String, dynamic>) {
      return null;
    }
    final FileUpload upload = FileUpload.fromJson(raw);
    if (!upload.status || upload.content.trim().isEmpty) return null;
    final String content = upload.content.trim();

    /// 已是绝对链接则直接使用；相对路径按请求域名补全。
    final Uri? parsed = Uri.tryParse(content);
    if (parsed == null) return null;
    final Uri absolute = parsed.hasScheme
        ? parsed
        : Uri.parse(Constant.requestUrl).resolveUri(parsed);
    if ((absolute.scheme != 'http' && absolute.scheme != 'https') ||
        absolute.host.isEmpty) {
      return null;
    }
    return ComicImageData(
      image_url: absolute.toString(),
      width: width,
      height: height,
    );
  } catch (_) {
    return null;
  }
}
