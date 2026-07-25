// ignore_for_file: non_constant_identifier_names

import 'package:app/components/authorized_login/telegram_login.dart';
import 'package:flutter/material.dart';
import 'package:app/models/rotation.dart';
import 'package:app/util/customer_service/open_rotation_jump.dart';

import 'google_login.dart';

/// 授权登录组件逻辑处理。
class Logic {
  /// 当前上下文。
  final BuildContext context;

  Logic(this.context);

  /// 处理授权登录项点击事件。
  Future<void> handle_authorized_login_tap(Rotation item) async {
    if (item.title.trim().toLowerCase() == 'google') {
      await google_login();
      return;
    }

    if (item.title.trim().toLowerCase() == 'telegram') {
      await telegram_login(context);
      return;
    }
    await open_rotation_jump(item);
  }

  /// 获取授权登录展示标题。
  String get_authorized_login_title(Rotation item) {
    if (item.title.trim().isNotEmpty) {
      return item.title.trim();
    }
    if (item.represent.trim().isNotEmpty) {
      return item.represent.trim();
    }
    return item.note.trim();
  }

  /// 获取授权登录 svg 图标名称。
  String get_authorized_login_svg_name(Rotation item) {
    if (item.note.trim().isNotEmpty) {
      return item.note.trim();
    }
    if (item.represent.trim().isNotEmpty) {
      return item.represent.trim();
    }
    return 'public';
  }
}
