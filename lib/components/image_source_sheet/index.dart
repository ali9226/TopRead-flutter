// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';

/// 弹出图片来源选择底部弹窗（相册 / 拍照）。
///
/// 公共组件，user_info 和在线客服页面共用。
/// [on_gallery] 点击"从相册选择"的回调。
/// [on_camera] 点击"拍照上传"的回调。
Future<void> showImageSourceSheet({
  required BuildContext context,
  required VoidCallback on_gallery,
  required VoidCallback on_camera,
}) {
  final bool is_dark = Get.find<DeviceInfo>().dark.value;

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: ColorConstants.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheet_context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LayoutConfig.space_12,
            0,
            LayoutConfig.space_12,
            LayoutConfig.space_12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // TODO 顶部拖拽条
              Container(
                width: 52,
                height: 5,
                margin: const EdgeInsets.only(bottom: LayoutConfig.space_10),
                decoration: BoxDecoration(
                  color: is_dark
                      ? ColorConstants.components_image_source_sheet_index_tone
                      : ColorConstants.components_image_source_sheet_index_tone_ffcbd5e1,
                  borderRadius: BorderRadius.circular(LayoutConfig.radius_pill),
                ),
              ),
              // TODO 选项容器
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(LayoutConfig.space_14),
                decoration: BoxDecoration(
                  color: is_dark
                      ? ColorConstants.components_image_source_sheet_index_tone_ff191919
                      : ColorConstants.components_image_source_sheet_index_tone_fffdfdfe,
                  borderRadius: BorderRadius.circular(
                    LayoutConfig.section_radius,
                  ),
                  border: Border.all(
                    color: is_dark
                        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_14ffffff
                        : ColorConstants.components_image_source_sheet_index_tone_ffe7ecf3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.shadowColor.withValues(alpha: is_dark ? 0.26 : 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // TODO 从相册选择
                    _ActionTile(
                      icon: Icons.photo_library_rounded,
                      title: easy.tr('UserInfo.choose_gallery'),
                      subtitle: easy.tr('constant.album'),
                      dark: is_dark,
                      icon_bg: ColorConstants.components_image_source_sheet_index_tone_fffff3cc,
                      icon_color: ColorConstants.components_image_source_sheet_index_tone_ffc58a00,
                      onTap: () {
                        Navigator.of(sheet_context).pop();
                        // TODO 延迟一帧调用回调，避免 Navigator 状态冲突
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          on_gallery();
                        });
                      },
                    ),
                    const SizedBox(height: LayoutConfig.space_12),
                    // TODO 拍照上传
                    _ActionTile(
                      icon: Icons.camera_alt_rounded,
                      title: easy.tr('UserInfo.take_photo'),
                      subtitle: easy.tr('constant.camera'),
                      dark: is_dark,
                      icon_bg: ColorConstants.components_image_source_sheet_index_tone_ffdff4ff,
                      icon_color: ColorConstants.components_image_source_sheet_index_tone_ff0a84c6,
                      onTap: () {
                        Navigator.of(sheet_context).pop();
                        // TODO 延迟一帧调用回调，避免 Navigator 状态冲突
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          on_camera();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LayoutConfig.space_10),
              // TODO 取消按钮
              Material(
                color: is_dark
                    ? ColorConstants.components_image_source_sheet_index_tone_ff191919
                    : ColorConstants.components_image_source_sheet_index_tone_fffdfdfe,
                borderRadius: BorderRadius.circular(
                  LayoutConfig.section_radius,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    LayoutConfig.section_radius,
                  ),
                  onTap: () => Navigator.of(sheet_context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: LayoutConfig.space_16,
                    ),
                    child: Center(
                      child: Text(
                        easy.tr('constant.cancel'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          color: is_dark
                              ? ColorConstants.util_dialog_show_upgrade_dialog_tone_ff9ca3af
                              : ColorConstants.util_dialog_show_message_tone_ff6b7280,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 选项瓦片。
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dark;
  final Color icon_bg;
  final Color icon_color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dark,
    required this.icon_bg,
    required this.icon_color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? ColorConstants.components_image_source_sheet_index_tone_ff232323 : ColorConstants.components_image_source_sheet_index_tone_fff8fafd,
      borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LayoutConfig.space_14,
            vertical: LayoutConfig.space_14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
            border: Border.all(
              color: dark
                  ? ColorConstants.util_dialog_show_upgrade_dialog_tone_dffffff
                  : ColorConstants.components_image_source_sheet_index_tone_ffe7ecf3,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: icon_bg,
                  borderRadius: BorderRadius.circular(LayoutConfig.radius_14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: icon_color, size: 24),
              ),
              const SizedBox(width: LayoutConfig.space_12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: dark ? ColorConstants.whiteColor : ColorConstants.components_image_source_sheet_index_tone_ff111827,
                      ),
                    ),
                    const SizedBox(height: LayoutConfig.space_4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: dark
                            ? ColorConstants.components_image_source_sheet_index_tone_8cffffff
                            : ColorConstants.util_dialog_show_upgrade_dialog_tone_ff9ca3af,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: dark ? ColorConstants.components_image_source_sheet_index_tone_ff4b5563 : ColorConstants.components_image_source_sheet_index_tone_ffcbd5e1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
