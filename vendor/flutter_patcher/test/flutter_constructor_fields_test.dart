// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_patcher/src/cli/interfaces/flutter_constructor_fields.dart';

void main() {
  late Directory directory;
  late File input;
  const desktop = <String, String>{
    'library': 'package:flutter/src/cupertino/desktop_text_selection_toolbar_button.dart',
    'class': 'CupertinoDesktopTextSelectionToolbarButton',
    'member': 'text',
  };
  const mobile = <String, String>{
    'library':
        'package:flutter/src/cupertino/text_selection_toolbar_button.dart',
    'class': 'CupertinoTextSelectionToolbarButton',
    'member': 'text',
  };

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('patcher_collision_');
    input = File('${directory.path}/referenced.json');
  });
  tearDown(() => directory.delete(recursive: true));

  Future<Map<String, dynamic>> write_merged({
    bool covered = true,
    bool valid_hash = true,
  }) async {
    final classes = [
      Map<String, String>.from(desktop)..remove('member'),
      Map<String, String>.from(mobile)..remove('member'),
    ];
    final document = <String, dynamic>{
      'callable': [desktop, mobile],
      'dynamically-callable': [desktop, mobile, if (covered) ...classes],
    };
    final text = jsonEncode(document);
    final details = <String, dynamic>{
      'schema': 1,
      'interface_sha256': valid_hash
          ? sha256.convert(utf8.encode(text)).toString()
          : 'invalid',
      'entries': [
        for (final section in document.entries)
          for (final row in section.value as List)
            <String, dynamic>{
              'section': section.key,
              ...row as Map<String, String>,
              'sources': [
                row.containsKey('member') ? 'defaults' : 'referenced',
              ],
              'location': {
                'uri': row['library'],
                'line': row.containsKey('member') ? 64 : 27,
                'column': 7,
              },
            },
      ],
    };
    await input.writeAsString(text);
    await File('${directory.path}/trim.yaml').writeAsString(text);
    await File('${directory.path}/details.json')
        .writeAsString(jsonEncode(details));
    return details;
  }

  Future<void> finalize() => finalize_flutter_constructor_fields(
    interface_path: input.path,
    trim_path: '${directory.path}/trim.yaml',
    details_path: '${directory.path}/details.json',
    evidence_directory: '${directory.path}/evidence',
  );

  test('retains dynamic fields through class declarations and preserves constructors', () async {
    final original = <String, dynamic>{
      'callable': [desktop, mobile],
      'dynamically-callable': [desktop, mobile],
    };
    await input.writeAsString(jsonEncode(original));
    await normalize_flutter_constructor_fields(input.path);
    final result = jsonDecode(await input.readAsString()) as Map;
    expect(result['callable'], original['callable']);
    expect(result['dynamically-callable'], [
      Map<String, String>.from(desktop)..remove('member'),
      Map<String, String>.from(mobile)..remove('member'),
    ]);
    // TODO Class declarations retain the field; deleting the row would drop its surface.
    expect((result['dynamically-callable'] as List), hasLength(2));
  });

  test(
    'does not broaden unrelated text members, getters or alternate libraries',
    () async {
      final original = <String, dynamic>{
        'dynamically-callable': [
          {...desktop, 'library': 'package:my_app/toolbar.dart'},
          {...desktop, 'class': 'AnotherButton'},
          {...desktop, 'member': 'get:text'},
          {...desktop, 'member': 'createState'},
        ],
        'can-be-overridden': [desktop],
      };
      final encoded = jsonEncode(original);
      await input.writeAsString(encoded);
      await normalize_flutter_constructor_fields(input.path);
      expect(await input.readAsString(), encoded);
    },
  );

  test('normalization is idempotent and an existing class declaration is not duplicated', () async {
    await input.writeAsString(
      jsonEncode(<String, dynamic>{
        'dynamically-callable': [
          desktop,
          Map<String, String>.from(desktop)..remove('member'),
          desktop,
        ],
      }),
    );
    await normalize_flutter_constructor_fields(input.path);
    final first = await input.readAsString();
    await normalize_flutter_constructor_fields(input.path);
    expect(await input.readAsString(), first);
    expect((jsonDecode(first) as Map)['dynamically-callable'], hasLength(1));
  });

  test('finalization retains real class provenance and constructors, validates complete pairs', () async {
    final before_details = await write_merged();
    final before_text = await input.readAsString();
    await finalize();
    final after_text = await input.readAsString();
    final after = jsonDecode(after_text) as Map;
    final after_details = jsonDecode(
      await File('${directory.path}/details.json').readAsString(),
    ) as Map;
    expect(after['callable'], [desktop, mobile]);
    expect(after['dynamically-callable'], [
      Map<String, String>.from(desktop)..remove('member'),
      Map<String, String>.from(mobile)..remove('member'),
    ]);
    final original_classes = (before_details['entries'] as List)
        .where((row) => !(row as Map).containsKey('member'))
        .toList();
    final final_classes = (after_details['entries'] as List)
        .where((row) => !(row as Map).containsKey('member'))
        .toList();
    expect(final_classes, original_classes);
    expect(
      after_details['interface_sha256'],
      sha256.convert(utf8.encode(after_text)).toString(),
    );
    expect(
      await File('${directory.path}/evidence/upstream/dynamic_interface.yaml')
          .readAsString(),
      before_text,
    );
    expect(
      await File('${directory.path}/trim.yaml').readAsString(),
      after_text,
    );
    await finalize();
    expect(await input.readAsString(), after_text);
  });

  test(
    'never removes a field declaration without class-wide coverage',
    () async {
      await write_merged(covered: false);
      final before = await input.readAsString();
      await expectLater(finalize(), throwsFormatException);
      expect(await input.readAsString(), before);
    },
  );

  test(
    'rejects an already mismatched upstream detail hash instead of masking it',
    () async {
      await write_merged(valid_hash: false);
      final before = await input.readAsString();
      await expectLater(finalize(), throwsA(isA<Exception>()));
      expect(await input.readAsString(), before);
    },
  );
}
