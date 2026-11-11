import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../core.dart';

const androidPageSize = 16384;

/// TODO Validate every ARM64 PT_LOAD, including file/virtual congruence on 16 KB devices.
List<int> verifyElfPageAlignment(List<int> bytes, {String name = 'library'}) {
  void check(bool value) => require(
    value,
    'BUILD_ANDROID_PAGE_ALIGNMENT',
    '$name requires valid ARM64 ELF load segments aligned to at least 16 KB.',
  );
  check(bytes.length >= 64);
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  check(
    data.getUint32(0, Endian.big) == 0x7f454c46 &&
        bytes[4] == 2 &&
        bytes[5] == 1 &&
        data.getUint16(16, Endian.little) == 3 &&
        data.getUint16(18, Endian.little) == 183,
  );
  final offset = data.getUint64(32, Endian.little);
  final size = data.getUint16(54, Endian.little);
  final count = data.getUint16(56, Endian.little);
  check(
    offset >= 64 &&
        size >= 56 &&
        count > 0 &&
        offset + size * count <= bytes.length,
  );
  final alignments = <int>[];
  for (var index = 0; index < count; index++) {
    final start = offset + index * size;
    if (data.getUint32(start, Endian.little) != 1) continue;
    final fileOffset = data.getUint64(start + 8, Endian.little);
    final address = data.getUint64(start + 16, Endian.little);
    final fileSize = data.getUint64(start + 32, Endian.little);
    final memorySize = data.getUint64(start + 40, Endian.little);
    final alignment = data.getUint64(start + 48, Endian.little);
    check(
      alignment >= androidPageSize &&
          (alignment & (alignment - 1)) == 0 &&
          fileOffset >= 0 &&
          fileSize >= 0 &&
          fileOffset + fileSize <= bytes.length &&
          memorySize >= fileSize &&
          (address - fileOffset) % androidPageSize == 0,
    );
    alignments.add(alignment);
  }
  check(alignments.isNotEmpty);
  return alignments;
}

Map<String, List<int>> verifyAndroidPageAlignment(
  Archive archive, {
  bool bundle = false,
}) {
  final index = bundle ? 1 : 0;
  return {
    for (final file in archive.where((file) => file.isFile))
      if (file.name.split('/').length > index + 2 &&
          file.name.split('/')[index] == 'lib' &&
          file.name.endsWith('.so'))
        file.name: verifyElfPageAlignment(file.content, name: file.name),
  };
}

/// TODO Play-generated split APKs must request uncompressed, 16 KB-aligned native libraries.
void verifyBundlePageAlignment(Map<String, dynamic> config) {
  final native =
      (config['optimizations'] as Map?)?['uncompressNativeLibraries'];
  require(
    native is Map &&
        native['enabled'] == true &&
        native['alignment'] == 'PAGE_ALIGNMENT_16K',
    'BUILD_AAB_PAGE_ALIGNMENT',
    'AAB must declare PAGE_ALIGNMENT_16K; use AGP 8.5.1 or newer.',
  );
}
