// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/api/post_request.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';

/// 申请成为作家页逻辑。
///
/// 负责：
/// 1. 验证表单数据合法性；
/// 2. 发送邮箱验证码；
/// 3. 调用申请入驻接口；
/// 4. 处理提交结果反馈。
class Logic {
  /// 页面上下文。
  final BuildContext context;

  Logic(this.context);

  /// 验证邮箱格式。
  ///
  /// [email] 用户输入的邮箱地址。
  /// 返回 null 表示验证通过，否则返回错误提示。
  String? validate_email(String email) {
    if (email.trim().isEmpty) {
      return easy.tr('installation.email_error');
    }
    final email_regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!email_regex.hasMatch(email.trim())) {
      return easy.tr('installation.email_error');
    }
    return null;
  }

  /// 验证验证码。
  ///
  /// [code] 用户输入的验证码。
  /// 返回 null 表示验证通过，否则返回错误提示。
  String? validate_code(String code) {
    if (code.trim().isEmpty) {
      return easy.tr('installation.verify_code_error');
    }
    if (code.trim().length < 4) {
      return easy.tr('installation.verify_code_error');
    }
    return null;
  }

  /// 发送邮箱验证码。
  ///
  /// [email] 目标邮箱地址。
  /// 返回 true 表示发送成功。
  Future<bool> send_verification_code(String email) async {
    try {
      final Map<String, dynamic> parameter = <String, dynamic>{
        'email': email.trim(),
      };

      final results = await postRequest<dynamic>(
        path: 'novel_mail/author_verification',
        parameter: parameter,
        showTips: false,
      );

      if (results.status) {
        showBottomTip(easy.tr('installation.send_code_success'));
        return true;
      } else {
        showBottomTip(easy.tr('installation.send_code_failed'));
        return false;
      }
    } catch (e) {
      logUtil(msg: '发送验证码失败: $e', type: 'e');
      showBottomTip(easy.tr('installation.send_code_failed'));
      return false;
    }
  }

  /// 提交作家申请。
  ///
  /// [email] 联系邮箱。
  /// [code] 邮箱验证码。
  /// [introduction] 自我介绍（选填）。
  /// 返回 Map：{success: bool, message: String}。
  Future<Map<String, dynamic>> submit_application({
    required String email,
    required String code,
    String? introduction,
  }) async {
    try {
      final Map<String, dynamic> parameter = <String, dynamic>{
        'email': email.trim(),
        'code': code.trim(),
        'self_introduction': introduction?.trim() ?? '',
      };

      final results = await postRequest<dynamic>(
        path: 'user/author_verification',
        parameter: parameter,
        showTips: false,
      );

      // 创作者申请提交成功后申请系统通知权限，用于后续审核结果通知。
      if (results.status) {
        unawaited(
          NotificationPermissionRequest.request_after_creator_application(),
        );
      }

      return {'success': results.status, 'message': results.message};
    } catch (e) {
      logUtil(msg: '提交作家申请失败: $e', type: 'e');
      return {
        'success': false,
        'message': easy.tr('installation.submit_failed'),
      };
    }
  }
}
