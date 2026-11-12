import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/hot_patch_support.dart';
import '../../scripts/obs_transport.dart';

Uint8List envelope_bytes({
  List<int> payload = const [1, 2, 3],
  bool signed = true,
}) {
  final bytes = Uint8List(146 + payload.length);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x46505443);
  data.setUint16(4, 1);
  data.setUint32(38, 1794400000);
  data.setUint64(42, payload.length);
  bytes.setRange(50, 82, sha256.convert(payload).bytes);
  if (signed) bytes[82] = 1;
  bytes.setRange(146, bytes.length, payload);
  return bytes;
}

void main() {
  test('iOS保留策略键须由SDK生成，预检拒绝旧键且不改源文件', () async {
    final temp = await Directory.systemTemp.createTemp('ios_host_trust_test_');
    addTearDown(() => temp.delete(recursive: true));
    final plist = File('${temp.path}/Info.plist');
    const old =
        '<plist><dict><key>FlutterPatcherHostTrust</key><string>old-host</string></dict></plist>';
    await plist.writeAsString(old);
    await expectLater(
      require_generated_ios_host_trust(plist),
      throwsFormatException,
    );
    expect(await plist.readAsString(), old);
    await plist.writeAsString(
      '<plist><dict><key>CFBundleName</key><string>TopRead</string></dict></plist>',
    );
    await require_generated_ios_host_trust(plist);
  });
  test('SDK默认宿主命名规范化，并与后台宿主锁保持一致', () {
    final target = parse_patch_target('25-arm64-v8a.fptc');
    expect(target.flavor, 'default');
    expect(target.channel, 'production');
    expect(target.file_name, '25-arm64-v8a.fptc');
    final hash = sha256
        .convert(
          utf8.encode(
            jsonEncode([
              'android',
              'arm64-v8a',
              '25',
              'default',
              'production',
              'a' * 64,
            ]),
          ),
        )
        .toString()
        .substring(0, 48);
    expect(target.lock_name('a' * 64), 'app_patch:$hash');
    expect(
      parse_patch_target('25-staging-preview-ios-arm64.fptc').channel,
      'preview',
    );
    expect(
      () => parse_patch_target('25-staging-arm64-v8a.fptc'),
      throwsFormatException,
    );
    expect(
      () => parse_patch_target('25-default-production-arm64-v8a.fptc'),
      throwsFormatException,
    );
  });

  test('北京时间跨年命名且存储对象包含时间唯一后缀，SDK目标名保持原名', () {
    final id = publication_id(
      now: DateTime.utc(2026, 12, 31, 16, 2, 3),
      nonce: 'abcdef123456',
    );
    expect(id, '20270101_000203_abcdef123456');
    final target = parse_patch_target('25-ios-arm64.fptc');
    final envelope = parse_patch_envelope(envelope_bytes());
    final key = patch_object_key(target, envelope, id);
    expect(key, contains('verification/patches/25/ios/'));
    expect(key, endsWith('25-ios-arm64_$id.fptc'));
    expect(target.file_name, '25-ios-arm64.fptc');
    expect(publication_id(), isNot(publication_id()));
  });

  test('预检拒绝破损或未签名文件，并识别空payload回滚', () {
    expect(parse_patch_envelope(envelope_bytes()).patch_type, 1);
    expect(parse_patch_envelope(envelope_bytes(payload: [])).patch_type, 2);
    expect(
      () => parse_patch_envelope(envelope_bytes(signed: false)),
      throwsFormatException,
    );
    final corrupted = envelope_bytes()..[146] = 7;
    expect(() => parse_patch_envelope(corrupted), throwsFormatException);
    final wrong_length = envelope_bytes();
    ByteData.sublistView(wrong_length).setUint64(42, 10000);
    expect(() => parse_patch_envelope(wrong_length), throwsFormatException);
  });

  test('默认双端且精确收集各自目录，拒绝错版本和空产物', () async {
    expect(target_platforms(null), ['android', 'ios']);
    final root = await Directory.systemTemp.createTemp('patch_outputs_test_');
    addTearDown(() => root.delete(recursive: true));
    final android = await Directory('${root.path}/run-android').create();
    final ios = await Directory('${root.path}/run-ios').create();
    final stale = await Directory('${root.path}/zzz-historical').create();
    await File(
      '${android.path}/25-arm64-v8a.fptc',
    ).writeAsBytes(envelope_bytes());
    await File('${ios.path}/25-ios-arm64.fptc').writeAsBytes(envelope_bytes());
    await File(
      '${stale.path}/24-arm64-v8a.fptc',
    ).writeAsBytes(envelope_bytes());
    final files = [
      ...await collect_patch_outputs(
        android,
        platform: 'android',
        version_code: 25,
      ),
      ...await collect_patch_outputs(ios, platform: 'ios', version_code: 25),
    ];
    expect(files.map((file) => file.uri.pathSegments.last), [
      '25-arm64-v8a.fptc',
      '25-ios-arm64.fptc',
    ]);
    await expectLater(
      collect_patch_outputs(stale, platform: 'android', version_code: 25),
      throwsFormatException,
    );
    await expectLater(
      collect_patch_outputs(
        Directory('${root.path}/missing'),
        platform: 'ios',
        version_code: 25,
      ),
      throwsFormatException,
    );
  });

  test('OBS端点拒绝明文、第三方host和URL凭据', () {
    expect(
      validate_obs_endpoint(
        Uri.parse('https://obs.af-south-1.myhuaweicloud.com'),
      ).scheme,
      'https',
    );
    for (final endpoint in [
      'http://obs.af-south-1.myhuaweicloud.com',
      'https://evil.example',
      'https://user:secret@obs.af-south-1.myhuaweicloud.com',
      'https://obs.af-south-1.myhuaweicloud.com/path',
    ]) {
      expect(
        () => validate_obs_endpoint(Uri.parse(endpoint)),
        throwsFormatException,
      );
    }
  });

  test('本地baseline解析软链且不创建目录，过大的宿主字段提前拒绝', () async {
    final temp = await Directory.systemTemp.createTemp('baseline_path_test_');
    addTearDown(() => temp.delete(recursive: true));
    final real = await Directory('${temp.path}/real').create();
    final link = await Link('${temp.path}/alias').create(real.path);
    final value = canonical_baseline_store(
      Directory('${link.path}/missing/deep').uri.toString(),
    );
    expect(
      value,
      Directory(
        '${real.resolveSymbolicLinksSync()}/missing/deep',
      ).uri.toString(),
    );
    expect(await Directory('${real.path}/missing').exists(), false);
    expect(
      () => parse_patch_target('4294967296-arm64-v8a.fptc'),
      throwsFormatException,
    );
    expect(
      () => parse_patch_target('25-${'a' * 33}-verification-ios-arm64.fptc'),
      throwsFormatException,
    );
  });

  test('OBS签名包含原子防覆盖头，日期和资源严格参与签名', () {
    const headers = {
      'date': 'Wed, 11 Nov 2026 12:00:00 GMT',
      'content-type': 'application/octet-stream',
      'x-obs-forbid-overwrite': 'true',
    };
    const canonical =
        'PUT\n\napplication/octet-stream\nWed, 11 Nov 2026 12:00:00 GMT\nx-obs-forbid-overwrite:true\n/obs.novel/example.txt';
    final expected = base64.encode(
      Hmac(
        sha1,
        utf8.encode('test-secret'),
      ).convert(utf8.encode(canonical)).bytes,
    );
    expect(
      obs_authorization(
        method: 'PUT',
        bucket: 'obs.novel',
        key: 'example.txt',
        access_key: 'test-access',
        secret_key: 'test-secret',
        headers: headers,
      ),
      'OBS test-access:$expected',
    );
  });

  test('dry-run不读取后端配置、不构建、不修改版本', () async {
    final app_dir = Directory.current;
    final pubspec = File('${app_dir.path}/pubspec.yaml');
    final before = sha256.convert(await pubspec.readAsBytes()).toString();
    for (final command in ['patch', 'release', 'withdraw']) {
      final result = await Process.run(
        'fvm',
        [
          'dart',
          'run',
          'scripts/hot_patch.dart',
          command,
          '--prod',
          '--yes',
          '--dry-run',
        ],
        environment: {
          'HOT_PATCH_BACKEND_DIR': '${app_dir.path}/definitely_missing_backend',
        },
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, contains('[dry-run]'));
      if (command == 'release') {
        expect(result.stdout, contains('Android格式=both'));
      }
    }
    expect(sha256.convert(await pubspec.readAsBytes()).toString(), before);
  });

  test('正式发版格式在读取凭据和构建前校验，APK单产物可演练', () async {
    final pubspec = File('pubspec.yaml');
    final before = sha256.convert(await pubspec.readAsBytes()).toString();
    final cases = [
      (args: ['--os', 'android', '--android-format', 'apk'], valid: true),
      (args: ['--os', 'both', '--android-format', 'aab'], valid: false),
      (args: ['--os', 'ios', '--android-format', 'both'], valid: false),
    ];
    for (final item in cases) {
      final result = await Process.run(
        'fvm',
        [
          'dart',
          'run',
          'scripts/hot_patch.dart',
          'release',
          '--prod',
          '--yes',
          '--dry-run',
          ...item.args,
        ],
        environment: {'HOT_PATCH_BACKEND_DIR': '/definitely_missing_backend'},
      );
      expect(result.exitCode, item.valid ? 0 : 1, reason: '${result.stderr}');
      if (item.valid) {
        expect(result.stdout, contains('Android格式=apk'));
      } else {
        expect(result.stderr, contains('--android-format'));
      }
    }
    expect(sha256.convert(await pubspec.readAsBytes()).toString(), before);
  });

  test('旧bump参数在读取凭据和构建前拒绝，并提示手动配置版本', () async {
    final pubspec = File('pubspec.yaml');
    final before = sha256.convert(await pubspec.readAsBytes()).toString();
    for (final args in [
      ['--bump', 'patch'],
      ['--bump=build'],
      ['--bump'],
    ]) {
      final result = await Process.run(
        'fvm',
        [
          'dart',
          'run',
          'scripts/hot_patch.dart',
          'release',
          '--prod',
          '--yes',
          ...args,
        ],
        environment: {'HOT_PATCH_BACKEND_DIR': '/definitely_missing_backend'},
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('--bump 已停用'));
      expect(result.stderr, contains('请手动修改 pubspec.yaml'));
      expect(result.stderr, contains('移除 --bump 参数'));
      expect(result.stderr, isNot(contains('找不到后端配置')));
      expect(result.stdout, isNot(contains('当前版本')));
      expect(sha256.convert(await pubspec.readAsBytes()).toString(), before);
    }
  });

  test('构建子进程失败仍恢复软链工具目录，保留实际退出码', () async {
    final temp = await Directory.systemTemp.createTemp('patcher_wrapper_test_');
    addTearDown(() => temp.delete(recursive: true));
    final project = await Directory('${temp.path}/project').create();
    final scripts = await Directory('${project.path}/scripts').create();
    await File('scripts/patcher_run.sh').copy('${scripts.path}/patcher_run.sh');
    final binaries = await Directory('${temp.path}/bin').create();
    final fake_fvm = File('${binaries.path}/fvm');
    await fake_fvm.writeAsString('#!/bin/sh\nexit 0\n');
    await Process.run('chmod', ['+x', fake_fvm.path]);
    for (final directory in ['.fvm', 'node_modules', 'nested/node_modules']) {
      final folder = await Directory(
        '${project.path}/$directory',
      ).create(recursive: true);
      await File('${folder.path}/sentinel').writeAsString(directory);
    }
    final result = await Process.run(
      'bash',
      [
        '${scripts.path}/patcher_run.sh',
        'bash',
        '-c',
        'test ! -e .fvm && test ! -e node_modules && test ! -e nested/node_modules || exit 99; exit 23',
      ],
      environment: {'PATH': '${binaries.path}:${Platform.environment['PATH']}'},
    );
    expect(result.exitCode, 23, reason: '${result.stderr}');
    for (final directory in ['.fvm', 'node_modules', 'nested/node_modules']) {
      expect(
        await File('${project.path}/$directory/sentinel').readAsString(),
        directory,
      );
    }
    // TODO macOS自带Bash3.2的nounset对空数组展开不同，隔离工程通常恰好没有工具目录。
    for (final directory in ['.fvm', 'node_modules', 'nested']) {
      await Directory('${project.path}/$directory').delete(recursive: true);
    }
    final empty = await Process.run(
      'bash',
      ['${scripts.path}/patcher_run.sh', 'bash', '-c', 'exit 27'],
      environment: {'PATH': '${binaries.path}:${Platform.environment['PATH']}'},
    );
    expect(empty.exitCode, 27, reason: '${empty.stderr}');
  });
}
