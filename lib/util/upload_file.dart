// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/config/constant.dart';
import 'package:app/models/file_upload.dart';
import 'package:app/util/log_util.dart';
import 'package:dio/dio.dart';
import 'package:app/api/dio_client.dart';

/// TODO 上传文件到服务器，返回文件 URL。
///
/// 上传成功返回文件 URL 字符串，失败返回 null。
Future<String?> uploadFile(File file) async {
  try {
    final String uploadUrl = "${Constant.requestUrl}${Constant.prefix}file/add";
    final FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path),
    });

    final dio = DioClient().instance;
    final response = await dio.post(uploadUrl, data: formData);

    if (response.statusCode == 200) {
      FileUpload fileUpload;
      if (response.data is Map<String, dynamic>) {
        fileUpload = FileUpload.fromJson(response.data);
      } else if (response.data is String) {
        final Map<String, dynamic> jsonMap = json.decode(response.data);
        fileUpload = FileUpload.fromJson(jsonMap);
      } else {
        logUtil(msg: "无法解析上传返回数据");
        return null;
      }

      if (fileUpload.status && fileUpload.content.isNotEmpty) {
        return fileUpload.content;
      }
    }
  } catch (e) {
    logUtil(msg: "上传出错：$e");
  }
  return null;
}
