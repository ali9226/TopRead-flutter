import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 扫描生产源码，防止页面绕过全局边距、圆角和间距阶梯。
///
/// 零表示无留白/无圆角，可直接表达；字号、正文行高、游戏几何与专用
/// 画布尺寸不属于间距阶梯，不按数值相等误合并。
void main() {
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => file.path != 'lib/config/layout_config.dart')
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('页面横向基础边距统一引用 LayoutConfig', () {
    final declaration = RegExp(
      r'\bdouble\s+(?:page_horizontal_padding|pageHorizontalPadding)'
      r'\s*=\s*([^;]+);',
    );
    final violations = <String>[];
    for (final file in files) {
      final source = _without_comments(file.readAsStringSync());
      for (final match in declaration.allMatches(source)) {
        if (match.group(1)!.trim() != 'LayoutConfig.page_horizontal_padding') {
          violations.add(_location(file, source, match.start));
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          '页面横向边距应共用 LayoutConfig.page_horizontal_padding。\n'
          '${violations.join('\n')}',
    );
  });

  test('控件圆角使用公共圆角阶梯', () {
    final raw_radius = RegExp(
      r'\b(?:BorderRadius|Radius)\.circular\s*\(\s*'
      r'([1-9][0-9]*)(?:\.0)?\s*[,)]',
    );
    final style_radius = RegExp(
      r'\b(?:const|final)\s+double\s+([A-Za-z_0-9]*[Rr]adius)'
      r'\s*=\s*([1-9][0-9]*)(?:\.0)?\s*;',
    );
    final violations = <String>[];
    for (final file in files) {
      final source = _without_comments(file.readAsStringSync());
      for (final match in raw_radius.allMatches(source)) {
        violations.add(_location(file, source, match.start));
      }
      for (final match in style_radius.allMatches(source)) {
        final name = match.group(1)!.toLowerCase();
        // 阴影与运动的半径是效果参数，不是形状圆角。
        if (name.contains('blur') ||
            name.contains('shadow') ||
            name.contains('particle') ||
            name.contains('motion')) {
          continue;
        }
        violations.add(_location(file, source, match.start));
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          '控件圆角应引用 LayoutConfig.radius_* 或语义样式入口。\n'
          '${violations.join('\n')}',
    );
  });

  test('EdgeInsets 使用公共间距阶梯', () {
    final shared_spacing = <num>{
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      14,
      15,
      16,
      18,
      20,
      22,
      24,
      26,
      28,
      30,
      32,
      34,
      36,
      40,
      44,
      48,
      56,
      60,
      64,
      72,
      80,
      96,
    };
    final padding_call = RegExp(
      r'\b(?:EdgeInsets|EdgeInsetsDirectional)\.'
      r'(?:all|symmetric|only|fromLTRB|fromSTEB)\s*\(',
    );
    final number = RegExp(r'(?<![\w.])[1-9][0-9]*(?:\.0)?(?![\w.])');
    final violations = <String>[];
    for (final file in files) {
      final source = _without_comments(file.readAsStringSync());
      for (final call in padding_call.allMatches(source)) {
        final end = _call_end(source, call.end - 1);
        final body = source.substring(call.end, end);
        for (final match in number.allMatches(body)) {
          if (shared_spacing.contains(num.parse(match.group(0)!))) {
            violations.add(_location(file, source, call.end + match.start));
          }
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'padding 应引用 LayoutConfig.space_* 或局部语义样式入口。\n'
          '${violations.join('\n')}',
    );
  });
}

int _call_end(String source, int start) {
  var depth = 0;
  for (var index = start; index < source.length; index++) {
    if (source[index] == '(') depth++;
    if (source[index] == ')' && --depth == 0) return index;
  }
  throw FormatException('Unclosed layout constructor', source, start);
}

String _location(File file, String source, int offset) {
  final line = '\n'.allMatches(source.substring(0, offset)).length + 1;
  return '${file.path}:$line';
}

String _without_comments(String source) => source.replaceAllMapped(
  RegExp(r'//[^\n]*|/\*[\s\S]*?\*/'),
  (match) => match.group(0)!.replaceAll(RegExp(r'[^\n]'), ' '),
);
