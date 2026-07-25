// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

/// 输入页提交函数签名。
///
/// 返回值含义：
/// 1. `true` 代表提交成功，页面应当自动关闭；
/// 2. `false` 代表提交失败或校验未通过，页面保持当前状态。
typedef UserInfoInputSubmit =
    Future<bool> Function(Map<String, String> input_value_map);

/// 单个输入框配置。
class UserInfoInputFieldConfig {
  /// 当前输入框唯一标识。
  final String field_key;

  /// 输入框提示文案。
  final String hint_text;

  /// 输入框是否使用密码模式。
  final bool obscure_text;

  /// 输入框键盘类型。
  final TextInputType keyboard_type;

  /// 输入框文本输入动作。
  final TextInputAction text_input_action;

  /// 最多输入长度。
  final int? max_length;

  /// 创建单个输入框配置对象。
  const UserInfoInputFieldConfig({
    required this.field_key,
    required this.hint_text,
    this.obscure_text = false,
    this.keyboard_type = TextInputType.text,
    this.text_input_action = TextInputAction.done,
    this.max_length,
  });
}

/// 独立输入页使用的视图配置对象。
///
/// 该对象由具体页面提供，输入壳组件只负责渲染和调用回调。
class UserInfoInputViewConfig {
  /// 页面顶部标题。
  final String title;

  /// 表单顶部补充信息。
  final String helper_text;

  /// 提交按钮文案。
  final String submit_button_text;

  /// 页面说明文案。
  final String description_text;

  /// 当前页面所有输入框配置。
  final List<UserInfoInputFieldConfig> field_list;

  /// 点击提交后的处理函数。
  final UserInfoInputSubmit on_submit;

  /// 创建配置对象。
  const UserInfoInputViewConfig({
    required this.title,
    required this.submit_button_text,
    required this.description_text,
    required this.field_list,
    required this.on_submit,
    this.helper_text = '',
  });
}
