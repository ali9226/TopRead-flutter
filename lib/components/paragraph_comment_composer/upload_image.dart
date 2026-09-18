// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:app/api/dio_client.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/file_upload.dart';

/// 沿用应用现有文件上传接口和响应模型，字节上传兼容移动端及 Web。
Future<String?> upload_paragraph_comment_image(
  Uint8List bytes,
  String filename,
) async {
  final Response<dynamic> response = await DioClient().instance.post<dynamic>(
    '${Constant.requestUrl}${Constant.prefix}file/add',
    data: FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    }),
  );
  final dynamic raw_data = response.data is String
      ? jsonDecode(response.data as String)
      : response.data;
  if (response.statusCode != 200 || raw_data is! Map<String, dynamic>) {
    return null;
  }
  final FileUpload upload = FileUpload.fromJson(raw_data);
  if (!upload.status || upload.content.trim().isEmpty) return null;
  final Uri? uploaded_uri = Uri.tryParse(upload.content.trim());
  if (uploaded_uri == null) return null;
  final Uri absolute_uri = Uri.parse(
    Constant.requestUrl,
  ).resolveUri(uploaded_uri);
  if ((absolute_uri.scheme != 'http' && absolute_uri.scheme != 'https') ||
      absolute_uri.host.isEmpty) {
    return null;
  }
  return absolute_uri.toString();
}
