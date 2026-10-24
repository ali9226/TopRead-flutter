import 'dart:io';
import 'dart:convert';

import 'package:app/config/color_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// 颜色的唯一来源必须是调色板。扫描生产源码，防止页面重新写入局部色值。
///
/// 这里只约束颜色构造及 SDK 色板；Color.lerp、Color.alphaBlend 等依赖动画
/// 进度或主题状态的组合运算仍可留在使用处，输入色必须引用统一调色板。
void main() {
  const palette_path = 'lib/config/color_config.dart';
  final production_files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('颜色构造和 SDK 色板只出现在 color_config.dart', () {
    final violations = <String>[];
    final raw_color = RegExp(
      r'\b(?:Color|MaterialColor|MaterialAccentColor)\s*'
      r'(?:\.\s*(?:from|fromARGB|fromRGBO))?\s*\('
      r'|\b(?:Colors|CupertinoColors)\s*\.'
      r'''|\bhexToColor\s*\(\s*['"]''',
    );

    for (final file in production_files) {
      if (file.path == palette_path) continue;
      final source = _without_comments(file.readAsStringSync());
      for (final match in raw_color.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        violations.add('${file.path}:$line ${match.group(0)}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '请将颜色定义移入 $palette_path，并复用已有颜色变量。'
          '共 ${violations.length} 处，以下最多显示前 40 处：\n'
          '${violations.take(40).join('\n')}',
    );
  });

  test('调色板中一个 ARGB 色值只有一个定义，且不使用纯黑', () {
    final source = _without_comments(File(palette_path).readAsStringSync());
    final color_literal = RegExp(
      r'\bColor\s*\(\s*(0x[0-9a-fA-F]+|[0-9]+)\s*,?\s*\)',
    );
    final definitions = <int, int>{};
    final violations = <String>[];

    for (final match in color_literal.allMatches(source)) {
      final value = int.parse(match.group(1)!);
      final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
      final previous = definitions[value];
      final hex = value.toRadixString(16).padLeft(8, '0').toUpperCase();
      if (previous != null) {
        violations.add('$palette_path:$line 0x$hex 已在第 $previous 行定义');
      } else {
        definitions[value] = line;
      }
      // 全透明色允许 RGB 为零；有可见 alpha 的纯黑必须改用 lightTextColor。
      if (value & 0x00FFFFFF == 0 && value >> 24 != 0) {
        violations.add('$palette_path:$line 纯黑 0x$hex 应使用 lightTextColor');
      }
    }

    expect(definitions, isNotEmpty, reason: '调色板应使用可静态审计的 Color 常量。');
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('原生广告协议覆盖两端所有颜色并保持 ARGB alpha', () {
    final light_palette = ColorConstants.native_ad_palette(false);
    final dark_palette = ColorConstants.native_ad_palette(true);
    expect(light_palette.keys, unorderedEquals(dark_palette.keys));
    expect(
      light_palette['card_background'],
      ColorConstants.whiteColor.toARGB32(),
    );
    expect(dark_palette['primary_text'], ColorConstants.whiteColor.toARGB32());
    expect(
      light_palette['cta_background'],
      ColorConstants.themeColor.toARGB32(),
    );
    expect(
      light_palette['overlay_scrim'],
      ColorConstants.lightTextColor.withValues(alpha: 0.8).toARGB32(),
    );
    final tag = ColorConstants.tagColorList.last;
    final custom_palette = ColorConstants.native_ad_palette(
      true,
      tag_color: tag,
    );
    expect(custom_palette['overlay_tag'], tag.toARGB32());
    expect(
      custom_palette['overlay_tag_background'],
      tag.withValues(alpha: 0.15).toARGB32(),
    );
    for (final value in {...light_palette.values, ...dark_palette.values}) {
      expect(value, inInclusiveRange(0, 0xFFFFFFFF));
      expect(value & 0xFFFFFF, isNot(0), reason: '可见原生色不应使用纯黑。');
    }

    const native_sources = <String>[
      'ios/Runner/AppDelegate.swift',
      'android/app/src/main/kotlin/com/topread/novel/MasonryNativeAdFactory.kt',
      'android/app/src/main/kotlin/com/topread/novel/ShortStoryNativeAdFactory.kt',
    ];
    final palette_lookup = RegExp(r'palette\.color\("([a-z_]+)"\)');
    final raw_native_color = RegExp(
      r'\bColor\.(?:rgb|argb|WHITE|BLACK)\b'
      r'|\bUIColor\.(?:white|black|gray|red|green|blue)\b'
      r'|\.backgroundColor\s*=\s*\.(?:black|white)\b'
      r'|0x[0-9a-fA-F]{6,8}\b',
    );
    for (final path in native_sources) {
      final source = _without_comments(File(path).readAsStringSync());
      expect(raw_native_color.hasMatch(source), isFalse, reason: path);
      for (final lookup in palette_lookup.allMatches(source)) {
        expect(light_palette, contains(lookup.group(1)), reason: path);
      }
    }
    for (final path in <String>[
      'lib/services/masonry_native_ad_pool.dart',
      'lib/services/short_story_tab_ad_pool.dart',
      'lib/pages/short_story_read/widgets/native_ad_banner.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains("'palette': ColorConstants.native_ad_palette("),
        reason: '$path 必须将调色板传给原生视图。',
      );
    }
  });

  test('打包颜色资源由同一调色板生成且未漂移', () {
    String argb(int value) =>
        '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    for (final (qualifier, color) in [
      ('values', ColorConstants.whiteColor),
      ('values-night', ColorConstants.nightBackgroundColor),
    ]) {
      final path = 'android/app/src/main/res/$qualifier/design_colors.xml';
      expect(
        File(path).readAsStringSync(),
        contains(
          '<color name="app_launch_background">${argb(color.toARGB32())}</color>',
        ),
        reason: '修改调色板后请运行 python3 tool/sync_platform_colors.py。',
      );
    }
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final web_color = argb(
      ColorConstants.web_manifest_theme.toARGB32(),
    ).replaceFirst('#FF', '#');
    expect(manifest['theme_color'], web_color);
    expect(manifest['background_color'], web_color);
    final background = RegExp(r'<color key="backgroundColor"([^>]*)/>');
    for (final name in ['Main', 'LaunchScreen']) {
      final source = File(
        'ios/Runner/Base.lproj/$name.storyboard',
      ).readAsStringSync();
      final attributes = background.firstMatch(source)!.group(1)!;
      final channels = <String, double>{
        for (final match in RegExp(
          r'(red|green|blue|alpha)="([0-9.]+)"',
        ).allMatches(attributes))
          match.group(1)!: double.parse(match.group(2)!),
      };
      final color = ColorConstants.whiteColor;
      expect(channels['red'], closeTo(color.r, 0.000001));
      expect(channels['green'], closeTo(color.g, 0.000001));
      expect(channels['blue'], closeTo(color.b, 0.000001));
      expect(channels['alpha'], closeTo(color.a, 0.000001));
    }
  });
}

/// 删除注释但保留换行，审计信息中的行号可直接定位到原始文件。
/// 色值字符串不包含注释标记，源文件内的说明不应被误判为颜色定义。
String _without_comments(String source) => source.replaceAllMapped(
  RegExp(r'//[^\n]*|/\*[\s\S]*?\*/'),
  (match) => match.group(0)!.replaceAll(RegExp(r'[^\n]'), ' '),
);
