// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/stores/device_info.dart';
import 'package:get/get.dart';

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
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext sheet_context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // TODO 顶部拖拽条
              Container(
                width: 52,
                height: 5,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: is_dark
                      ? Colors.white.withValues(alpha: 0.18)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // TODO 选项容器
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: is_dark
                      ? const Color(0xFF191919)
                      : const Color(0xFFFDFDFE),
                  borderRadius: BorderRadius.circular(
                    LayoutConfig.section_radius,
                  ),
                  border: Border.all(
                    color: is_dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE7ECF3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: is_dark ? 0.26 : 0.10,
                      ),
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
                      icon_bg: const Color(0xFFFFF3CC),
                      icon_color: const Color(0xFFC58A00),
                      onTap: () {
                        Navigator.of(sheet_context).pop();
                        // TODO 延迟一帧调用回调，避免 Navigator 状态冲突
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          on_gallery();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // TODO 拍照上传
                    _ActionTile(
                      icon: Icons.camera_alt_rounded,
                      title: easy.tr('UserInfo.take_photo'),
                      subtitle: easy.tr('constant.camera'),
                      dark: is_dark,
                      icon_bg: const Color(0xFFDFF4FF),
                      icon_color: const Color(0xFF0A84C6),
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
              const SizedBox(height: 10),
              // TODO 取消按钮
              Material(
                color: is_dark
                    ? const Color(0xFF191919)
                    : const Color(0xFFFDFDFE),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        easy.tr('constant.cancel'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontConfig.adjustedWeight(
                            FontWeight.w500,
                          ),
                          color: is_dark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
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
      color: dark ? const Color(0xFF232323) : const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LayoutConfig.section_radius),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFE7ECF3),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: icon_bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: icon_color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        color: dark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: dark
                            ? Colors.white.withValues(alpha: 0.55)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: dark ? const Color(0xFF4B5563) : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
