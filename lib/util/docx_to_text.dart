import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

/// TODO 解析 docx 文件为纯文本。
///
/// [bytes] 为 docx 文件的完整字节（本质是 zip，取其中 word/document.xml）。
/// [handle_numbering] 为 true 时按段落编号生成 "1. 2. 3." 前缀（仅支持顶级编号）。
/// 返回按行拼接的文本；解析失败抛出 [xml.XmlException] 或 [ArchiveException]。
///
/// TODO 内联自 docx_to_text 1.0.1（该包锁死 archive 3.x，与 flutter_patcher 的
/// archive 4.x 冲突，且已停止维护），API 适配 archive 4.x。
String docx_to_text(Uint8List bytes, {bool handle_numbering = false}) {
  final archive = ZipDecoder().decodeBytes(bytes);

  final List<String> list = [];

  for (final file in archive) {
    if (file.isFile && file.name == 'word/document.xml') {
      final file_content = utf8.decode(file.content);
      final document = xml.XmlDocument.parse(file_content);

      final paragraph_nodes = document.findAllElements('w:p');

      int number = 0;
      String last_num_id = '0';

      for (final paragraph in paragraph_nodes) {
        final text_nodes = paragraph.findAllElements('w:t');
        var text = text_nodes.map((node) => node.innerText).join();

        if (handle_numbering) {
          var numbering = paragraph.getElement('w:pPr')?.getElement('w:numPr');
          if (numbering != null) {
            final num_id = numbering.getElement('w:numId')!.getAttribute('w:val')!;

            if (num_id != last_num_id) {
              number = 0;
              last_num_id = num_id;
            }
            number++;
            text = '$number. $text';
          }
        }

        list.add(text);
      }
    }
  }

  return list.join('\n');
}
