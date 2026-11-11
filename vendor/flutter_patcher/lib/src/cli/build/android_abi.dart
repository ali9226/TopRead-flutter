import 'package:archive/archive.dart';

import '../core.dart';

/// TODO Reject every unsupported native ABI, including plugin libraries without a Flutter engine.
void verifyArm64NativeLibraries(Archive archive, {bool bundle = false}) {
  final index = bundle ? 1 : 0;
  for (final file in archive.where((file) => file.isFile)) {
    final parts = file.name.split('/');
    if (parts.length <= index || parts[index] != 'lib') continue;
    require(
      parts.length > index + 2 && parts[index + 1] == 'arm64-v8a',
      bundle ? 'BUILD_AAB_INVALID' : 'BUILD_APK_INVALID',
      'Unsupported native ABI in ${file.name}; release hosts require arm64-v8a only.',
    );
  }
}
