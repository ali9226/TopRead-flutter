// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/models/rotation.dart';
import 'package:app/util/customer_service/open_rotation_jump.dart';

/// 客服组件逻辑处理。
class Logic {
  /// 当前上下文。
  final BuildContext context;

  Logic(this.context);

  /// 处理客服项点击事件。
  Future<void> handle_customer_service_tap(Rotation item) async {
    await open_rotation_jump(item);
  }

  /// 获取客服展示标题。
  String get_customer_service_title(Rotation item) {
    if (item.title.trim().isNotEmpty) {
      return item.title.trim();
    }
    if (item.note.trim().isNotEmpty) {
      return item.note.trim();
    }
    return item.represent.trim();
  }

  /// 获取客服 svg 图标名称。
  String get_customer_service_svg_name(Rotation item) {
    if (item.represent.trim().isNotEmpty) {
      return item.represent.trim();
    }
    return 'public';
  }
}
