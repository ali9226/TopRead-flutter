// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/components/paragraph_comment_composer/logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('表情替换选区，并按后端 UTF-16 长度限制', () {
    final ParagraphCommentComposerLogic logic = ParagraphCommentComposerLogic(
      on_send: (_, _) async => true,
      on_close: () {},
    );
    addTearDown(logic.dispose);
    logic.controller.value = const TextEditingValue(
      text: '前替换后',
      selection: TextSelection(baseOffset: 1, extentOffset: 3),
    );
    logic.insert_emoji('😀');
    expect(logic.controller.text, '前😀后');
    expect(logic.controller.selection.baseOffset, 3);
    logic.controller.text = 'a' * 1999;
    logic.insert_emoji('😀');
    expect(logic.controller.text.length, 1999);
    final TextEditingValue previous = logic.controller.value;
    expect(
      logic.limit_content(previous, TextEditingValue(text: '${'a' * 1999}😀')),
      previous,
    );
  });

  test('发送失败保留草稿，重复点击不重复请求，成功才关闭', () async {
    final Completer<bool> response = Completer<bool>();
    int calls = 0;
    int closed = 0;
    final ParagraphCommentComposerLogic logic = ParagraphCommentComposerLogic(
      on_send: (String content, List<String> images) {
        calls += 1;
        expect(content, '保留这段草稿');
        expect(images, isEmpty);
        return response.future;
      },
      on_close: () => closed += 1,
    );
    addTearDown(logic.dispose);
    logic.controller.text = ' 保留这段草稿 ';
    final Future<void> first = logic.send();
    await logic.send();
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    response.complete(false);
    await first;
    expect(logic.controller.text, ' 保留这段草稿 ');
    expect(logic.error_key, 'paragraph_comment.send_failed');
    expect(closed, 0);
  });

  test('图片上传失败保留预览，重试不重复上传成功图片，允许纯图发送', () async {
    int uploads = 0;
    int sends = 0;
    int closed = 0;
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
    final ParagraphCommentComposerLogic logic = ParagraphCommentComposerLogic(
      pick_images: () async => <XFile>[
        XFile.fromData(bytes, name: 'one.png', path: 'one.png'),
        XFile.fromData(bytes, name: 'two.png', path: 'two.png'),
      ],
      upload_image: (_, String filename) async {
        uploads += 1;
        if (uploads == 2) return null;
        return 'https://example.test/$filename';
      },
      on_send: (String content, List<String> images) async {
        sends += 1;
        expect(content, isEmpty);
        expect(images, <String>[
          'https://example.test/one.png',
          'https://example.test/two.png',
        ]);
        return true;
      },
      on_close: () => closed += 1,
    );
    addTearDown(logic.dispose);
    await logic.add_images();
    expect(logic.images.length, 2);
    expect(logic.images.first.url, isNotNull);
    expect(logic.images.last.url, isNull);
    expect(logic.error_key, 'paragraph_comment.image_upload_failed');
    expect(logic.can_send, isTrue);
    await logic.send();
    expect(uploads, 3);
    expect(sends, 1);
    expect(closed, 1);
  });

  test('发送期间销毁弹窗不会在请求返回时访问已销毁控制器', () async {
    final Completer<bool> response = Completer<bool>();
    int closed = 0;
    final ParagraphCommentComposerLogic logic = ParagraphCommentComposerLogic(
      on_send: (_, _) => response.future,
      on_close: () => closed += 1,
    );
    logic.controller.text = '发送后立即关闭';
    final Future<void> pending = logic.send();
    await Future<void>.delayed(Duration.zero);
    logic.dispose();
    response.complete(true);
    await pending;
    expect(closed, 0);
  });

  test('选图期间关闭弹窗，迟到的图片不会上传或重新请求焦点', () async {
    final Completer<List<XFile>> selection = Completer<List<XFile>>();
    int uploads = 0;
    int closed = 0;
    final ParagraphCommentComposerLogic logic = ParagraphCommentComposerLogic(
      pick_images: () => selection.future,
      upload_image: (_, _) async {
        uploads += 1;
        return 'https://example.test/image.png';
      },
      on_send: (_, _) async => true,
      on_close: () => closed += 1,
    );
    addTearDown(logic.dispose);
    final Future<void> pending = logic.add_images();
    logic.close();
    logic.close();
    selection.complete(<XFile>[
      XFile.fromData(
        Uint8List.fromList(<int>[1, 2, 3]),
        name: 'image.png',
        path: 'image.png',
      ),
    ]);
    await pending;
    expect(closed, 1);
    expect(logic.images, isEmpty);
    expect(uploads, 0);
    expect(logic.focus_node.hasFocus, isFalse);
    expect(logic.can_send, isFalse);
  });

  test('关闭动画期间上传返回，不继续发送已关闭的草稿', () async {
    final Completer<String?> upload = Completer<String?>();
    int sends = 0;
    int closed = 0;
    final ParagraphCommentComposerLogic logic = ParagraphCommentComposerLogic(
      upload_image: (_, _) => upload.future,
      on_send: (_, _) async {
        sends += 1;
        return true;
      },
      on_close: () => closed += 1,
    );
    addTearDown(logic.dispose);
    logic.images.add(
      ParagraphCommentImage(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        filename: 'image.png',
      ),
    );
    final Future<void> pending = logic.send();
    // 等价于用户点击遮罩后 PopScope 已退出、控件尚处于退场动画。
    logic.deactivate();
    upload.complete('https://example.test/image.png');
    await pending;
    expect(sends, 0);
    expect(closed, 0);
    expect(logic.can_send, isFalse);
    expect(logic.focus_node.hasFocus, isFalse);
  });
}
