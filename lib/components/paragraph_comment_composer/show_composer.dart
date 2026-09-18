// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'index.dart';

/// 独立的段评弹窗入口；调用方只负责引用文本、主题和提交操作。
Future<void> show_paragraph_comment_composer(
  BuildContext context, {
  required String quote,
  required bool is_dark,
  required Future<bool> Function(String content, List<String> images) on_send,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  // 背景延伸到窗口两侧，避免横屏安全区和宽屏限宽露出键盘后方的遮罩。
  useSafeArea: false,
  backgroundColor: Colors.transparent,
  constraints: const BoxConstraints(maxWidth: double.infinity),
  builder: (BuildContext sheet_context) {
    // 路由会移除 MediaQuery 的顶部 padding，直接读取窗口安全区保护顶部内容。
    final view = View.of(sheet_context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          ConstrainedBox(
            // 只限制高度，不在弹窗外增加透明留白，保证紧邻顶部的遮罩也能点击关闭。
            constraints: BoxConstraints(
              maxHeight: math.max(
                0,
                constraints.maxHeight -
                    view.viewPadding.top / view.devicePixelRatio,
              ),
            ),
            child: ParagraphCommentComposer(
              quote: quote,
              is_dark: is_dark,
              on_send: on_send,
            ),
          ),
    );
  },
);
