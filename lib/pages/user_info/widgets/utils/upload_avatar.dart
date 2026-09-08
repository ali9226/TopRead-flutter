import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/file_upload.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:dio/dio.dart';
import 'package:app/api/dio_client.dart';
import 'package:get/get.dart' as vuex;
import 'package:app/models/user_info.dart';

// TODO 上传头像
Future<void> uploadAvatar(File imageFile) async {
  // TODO 判断文件类型
  final allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'tif',
    'tiff',
    'ico',
    'raw',
    'heic',
    'heif',
  ];
  String extension = imageFile.path.split('.').last.toLowerCase();
  if (!allowedExtensions.contains(extension)) {
    showBottomTip(easy.tr("UserInfo.error_04"));
    return;
  }

  // TODO 判断文件大小
  final maxSize = 1;
  final maxSizeInBytes = maxSize * 1024 * 1024; // TODO 1MB
  final fileSize = await imageFile.length();

  // TODO 转换为 MB
  double fileSizeInMB = fileSize / 1024 / 1024;

  // TODO 格式化显示：有小数保留两位，无小数显示整数
  String fileSizeStr;
  if (fileSizeInMB % 1 == 0) {
    fileSizeStr = fileSizeInMB.toInt().toString(); // TODO 整数
  } else {
    fileSizeStr = fileSizeInMB.toStringAsFixed(2); // TODO 两位小数
  }

  if (fileSize > maxSizeInBytes) {
    String text = easy.tr(
      "UserInfo.error_05",
      namedArgs: {"size": "${fileSizeStr}M", "max_size": "${maxSize}M"},
    );

    showBottomTip(text);
    return;
  }

  FileUpload fileUpload = FileUpload(status: false, content: '', message: '');
  showBottomTip(easy.tr("UserInfo.tips_05"));
  try {
    // TODO 上传 API 地址
    String uploadUrl = "${Constant.requestUrl}${Constant.prefix}file/add";
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(imageFile.path),
    });
    final dio = DioClient().instance;
    final response = await dio.post(uploadUrl, data: formData);
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        fileUpload = FileUpload.fromJson(response.data);
      } else if (response.data is String) {
        // TODO 如果返回的是 JSON 字符串，需要先解析
        final Map<String, dynamic> jsonMap = json.decode(response.data);
        fileUpload = FileUpload.fromJson(jsonMap);
      } else {
        logUtil(msg: "无法解析上传返回数据");
      }
      //   // TODO: 这里可以更新 userInformation.userInfo.value.avatarUrl
      //   // setState(() {}); 触发头像刷新
    }
  } catch (e) {
    logUtil(msg: "上传出错：$e");
  }

  if (!fileUpload.status || fileUpload.content == "") {
    showBottomTip(easy.tr("UserInfo.choose_gallery_error_01"));
    return;
  }

  var parameter = {"avatar_url": fileUpload.content};
  final results = await postRequest<UserInfo>(
    path: 'user/update_avatar',
    parameter: parameter,
    fromJson: (json) => UserInfo.fromJson(json),
  );
  if (!results.status) {
    showBottomTip(easy.tr("UserInfo.error_06"));
    return;
  }
  if (results.content == null) return;
  final userInfo = results.content;
  showBottomTip(easy.tr("UserInfo.success_01"));
  // TODO 保存 userInfo
  final userController = vuex.Get.find<UserInformation>();

  if (userInfo != null) {
    userController.saveUserInfo(userInfo);
  }
}
