// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../baseline/manifest.dart';

const _collisions = <String, String>{
  'package:flutter/src/cupertino/desktop_text_selection_toolbar_button.dart':
      'CupertinoDesktopTextSelectionToolbarButton',
  'package:flutter/src/cupertino/text_selection_toolbar_button.dart':
      'CupertinoTextSelectionToolbarButton',
};

bool _collision(Map row) =>
    row['member'] == 'text' &&
    _collisions.containsKey(row['library']) &&
    _collisions[row['library']] == row['class'];

String _class_key(Map row) => jsonEncode([row['library'], row['class']]);

String _encode(Map document) =>
    '${const JsonEncoder.withIndent('  ').convert(document)}\n';

/// TODO Dart 3.13's member index resolves a constructor before an identically
/// named field. Preserve both Cupertino text fields through a class declaration
/// in the dynamic surface, leaving callable constructor declarations untouched.
/// This only changes extraction inputs: the official tools still generate the
/// final interface, source locations, provenance and hashes together.
Future<void> normalize_flutter_constructor_fields(String path) async {
  final file = File(path);
  final document = Map<String, dynamic>.from(
    jsonDecode(await file.readAsString()) as Map,
  );
  final rows = document['dynamically-callable'];
  if (rows is! List) return;
  var changed = false;
  final normalized = <Map<String, dynamic>>[];
  final seen = <String>{};
  for (final value in rows) {
    final row = Map<String, dynamic>.from(value as Map);
    if (_collision(row)) {
      row.remove('member');
      changed = true;
    }
    final key = jsonEncode([row['library'], row['class'], row['member']]);
    if (seen.add(key)) normalized.add(row);
  }
  if (!changed) return;
  document['dynamically-callable'] = normalized;
  await file.writeAsString(_encode(document), flush: true);
}

/// TODO Upstream defaults can add the ambiguous member again during merge.
/// Remove it only when the same class-wide declaration already covers its
/// instance field. The official class provenance/location remain unchanged;
/// callable constructor rows are never removed. Both original and transformed
/// complete detail sets must pass the upstream validator before publication.
Future<void> finalize_flutter_constructor_fields({
  required String interface_path,
  required String trim_path,
  required String details_path,
  required String evidence_directory,
}) async {
  final interface = Map<String, dynamic>.from(
    jsonDecode(await File(interface_path).readAsString()) as Map,
  );
  final rows = interface['dynamically-callable'];
  if (rows is! List || !rows.any((row) => _collision(row as Map))) return;

  final upstream = Directory('$evidence_directory/upstream');
  final normalized = Directory('$evidence_directory/normalized');
  await upstream.create(recursive: true);
  await normalized.create(recursive: true);
  await File(interface_path).copy('${upstream.path}/dynamic_interface.yaml');
  await File(trim_path).copy('${upstream.path}/trim_interface.yaml');
  await File(details_path).copy('${upstream.path}/interface_detailed.json');
  final original_hash = sha256
      .convert(await File(interface_path).readAsBytes())
      .toString();
  await validateDetails(upstream.path, original_hash);

  void remove_covered_members(Map<String, dynamic> document) {
    final rows = document['dynamically-callable'];
    if (rows is! List) return;
    final covered = <String>{
      for (final row in rows)
        if (!(row as Map).containsKey('member')) _class_key(row),
    };
    for (final row in rows) {
      if (_collision(row as Map) && !covered.contains(_class_key(row))) {
        throw const FormatException(
          'A constructor-field collision has no class-wide coverage',
        );
      }
    }
    document['dynamically-callable'] = rows
        .where((row) => !_collision(row as Map))
        .toList();
  }

  final trim = Map<String, dynamic>.from(
    jsonDecode(await File(trim_path).readAsString()) as Map,
  );
  final details = Map<String, dynamic>.from(
    jsonDecode(await File(details_path).readAsString()) as Map,
  );
  remove_covered_members(interface);
  remove_covered_members(trim);
  // TODO Retain the tools' real class rows, locations and sources verbatim.
  details['entries'] = (details['entries'] as List)
      .where(
        (row) =>
            (row as Map)['section'] != 'dynamically-callable' ||
            !_collision(row),
      )
      .toList();
  final interface_text = _encode(interface);
  final final_hash = sha256.convert(utf8.encode(interface_text)).toString();
  details['interface_sha256'] = final_hash;
  await File('${normalized.path}/dynamic_interface.yaml')
      .writeAsString(interface_text, flush: true);
  await File('${normalized.path}/trim_interface.yaml')
      .writeAsString(_encode(trim), flush: true);
  await File('${normalized.path}/interface_detailed.json')
      .writeAsString(_encode(details), flush: true);
  await validateDetails(normalized.path, final_hash);
  await File('${normalized.path}/dynamic_interface.yaml').copy(interface_path);
  await File('${normalized.path}/trim_interface.yaml').copy(trim_path);
  await File('${normalized.path}/interface_detailed.json').copy(details_path);
}
