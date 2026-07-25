// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/color_config.dart';
import 'package:app/components/image_source_sheet/index.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';

/// 弹出图片来源选择底部弹窗（相册 / 拍照）。
///
/// 使用公共组件 showImageSourceSheet。
/// 选择图片支持多选，拍照为单选。
/// 选择后返回本地文件路径列表（上传在 logic.dart 中后台处理）。
Future<List<String>?> show_image_source_sheet(BuildContext context, bool is_dark) async {
    final Completer<List<String>?> completer = Completer<List<String>?>();

    showImageSourceSheet(
        context: context,
        on_gallery: () async {
            final paths = await _pick_from_gallery(context, is_dark);
            if (!completer.isCompleted) completer.complete(paths);
        },
        on_camera: () async {
            final paths = await _pick_from_camera(context);
            if (!completer.isCompleted) completer.complete(paths);
        },
    );

    return completer.future;
}

/// 从相册多选图片。
Future<List<String>?> _pick_from_gallery(BuildContext context, bool is_dark) async {
    // TODO 请求相册权限
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
        await showMessage(
            message: easy.tr('UserInfo.take_photo_tips_01'),
            leftButtonText: easy.tr('constant.cancel'),
            rightButtonText: easy.tr('UserInfo.take_photo_tips_02'),
            onRightPressed: () async {
                await openAppSettings();
            },
        );
        return null;
    }

    // TODO 打开多选器（主题色背景+lightTextColor文字，适配夜间模式）
    final Color bg = is_dark ? const Color(0xFF1C1C2E) : Colors.white;
    final Color text = is_dark ? Colors.white : ColorConstants.lightTextColor;
    final List<AssetEntity>? selected = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
            maxAssets: 9,
            requestType: RequestType.image,
            pickerTheme: ThemeData(
                brightness: Brightness.light,
                colorScheme: ColorScheme(
                    brightness: Brightness.light,
                    primary: ColorConstants.themeColor,
                    onPrimary: ColorConstants.lightTextColor,
                    secondary: ColorConstants.themeColor,
                    onSecondary: ColorConstants.lightTextColor,
                    surface: is_dark ? const Color(0xFF2A2A3C) : Colors.white,
                    onSurface: text,
                    error: Colors.red,
                    onError: Colors.white,
                ),
                scaffoldBackgroundColor: bg,
                textTheme: TextTheme(
                    bodyLarge: TextStyle(color: ColorConstants.lightTextColor),
                    bodyMedium: TextStyle(color: ColorConstants.lightTextColor),
                    bodySmall: TextStyle(color: ColorConstants.lightTextColor),
                ),
                appBarTheme: AppBarTheme(
                    backgroundColor: bg,
                    foregroundColor: text,
                    elevation: 0,
                ),
            ),
            textDelegate: const AssetPickerTextDelegate(),
        ),
    );

    if (selected == null || selected.isEmpty) return null;

    // TODO 返回本地文件路径（上传在 logic.dart 中后台处理）
    return _get_file_paths(selected);
}

/// 拍照（单选）。
Future<List<String>?> _pick_from_camera(BuildContext context) async {
    // TODO 请求相机权限（与 user_info 完全一致）
    final PermissionStatus status = await Permission.camera.request();
    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
        await showMessage(
            message: easy.tr('UserInfo.take_photo_tips_01'),
            leftButtonText: easy.tr('constant.cancel'),
            allowMaskDismiss: true,
            rightButtonText: easy.tr('UserInfo.take_photo_tips_02'),
            onRightPressed: () async {
                final opened = await openAppSettings();
                if (!opened) {
                    showBottomTip(easy.tr('UserInfo.take_photo_error_02'));
                }
            },
        );
        return null;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return null;

    // TODO 返回本地文件路径（上传在 logic.dart 中后台处理）
    return [photo.path];
}

/// 获取资源的本地文件路径列表。
Future<List<String>> _get_file_paths(List<AssetEntity> assets) async {
    final List<String> paths = [];
    for (final asset in assets) {
        try {
            final File? file = await asset.file;
            if (file != null) paths.add(file.path);
        } catch (e) {
            logUtil(msg: 'TODO 获取文件路径失败: $e', type: 'e');
        }
    }
    return paths;
}
