import 'dart:convert';
import 'dart:io';

/// TODO 托管 Flutter SDK 存在未提交源码改动时拒绝构建；只检测，不自动修复用户缓存。
Future<void> check_managed_sdk(Directory app_dir) async {
  final fvm =
      jsonDecode(await File('${app_dir.path}/.fvmrc').readAsString())
          as Map<String, dynamic>;
  final sdk = Directory(
    '${Platform.environment['HOME']}/.flutter_patcher/flutter/${fvm['flutter']}',
  );
  if (!await Directory('${sdk.path}/.git').exists()) return;
  final status = await Process.run('git', [
    '-C',
    sdk.path,
    'status',
    '--porcelain',
    '--untracked-files=no',
  ]);
  if (status.exitCode != 0) {
    throw const FormatException('无法检查 flutter_patcher 托管 SDK 状态');
  }
  final changed = (status.stdout as String).trim();
  if (changed.isNotEmpty) {
    throw FormatException(
      'flutter_patcher 托管 SDK 存在源码修改，可能来自中断或手工兼容修复。请先审查并备份恢复，脚本不会自动改全局 SDK：${sdk.path}\n$changed',
    );
  }
}

Future<void> main() async {
  try {
    await check_managed_sdk(File(Platform.script.toFilePath()).parent.parent);
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
