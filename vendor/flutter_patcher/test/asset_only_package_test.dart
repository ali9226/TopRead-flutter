import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_patcher/src/cli/baseline/resolve.dart';
import 'package:flutter_patcher/src/cli/patch/bytecode.dart';
import 'package:flutter_patcher/src/cli/patch/pipeline.dart';
import 'package:flutter_patcher/src/cli/patch/sources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory fixture;
  late PatchRun run;
  late BytecodeProducer producer;

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('patcher_asset_only_');
    Future<void> put(String path, String text) async {
      final file = File('${fixture.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }

    await put(
      'fixture_app/pubspec.yaml',
      'name: fixture_app\ndependencies:\n  asset_only: any\n  native_plugin: any\n',
    );
    await put('fixture_app/lib/main.dart', 'void main() {}\n');
    await put(
      'asset_only/pubspec.yaml',
      'name: asset_only\nversion: 1.0.0\nflutter:\n  assets:\n    - assets/icon.bin\n',
    );
    await put('asset_only/assets/icon.bin', 'real asset, no lib directory');
    await put(
      'native_plugin/pubspec.yaml',
      'name: native_plugin\nversion: 1.0.0\nflutter:\n  plugin:\n    platforms:\n      ios:\n        pluginClass: FixturePlugin\n',
    );
    await put('native_plugin/lib/plugin.dart', 'const pluginValue = 1;\n');
    Map<String, dynamic> package(String name) => {
      'name': name,
      'rootUri': Directory('${fixture.path}/$name').uri.toString(),
      'packageUri': 'lib/',
      'languageVersion': '3.13',
    };
    await put(
      'package_config.json',
      jsonEncode({
        'configVersion': 2,
        'packages': [
          package('fixture_app'),
          package('asset_only'),
          package('native_plugin'),
        ],
      }),
    );
    await put(
      'baseline/package_config.json',
      jsonEncode({
        'configVersion': 2,
        'packages': [package('fixture_app'), package('native_plugin')],
      }),
    );
    await put(
      'baseline/source_hashes.json',
      jsonEncode({
        'files': {
          'package:fixture_app/main.dart': sha256
              .convert(utf8.encode('void main() {}\n'))
              .toString(),
          'package:native_plugin/plugin.dart': sha256
              .convert(utf8.encode('const pluginValue = 1;\n'))
              .toString(),
        },
      }),
    );
    final resolved = ResolvedRelease(
      format: 'legacy',
      flavor: 'default',
      versionCode: '25',
      abi: 'ios-arm64',
      fingerprint: 'a' * 64,
      compileRoot: '${fixture.path}/baseline',
      releaseRoot: '${fixture.path}/baseline',
      compile: {},
      receipt: {'package_inputs': <String, dynamic>{}},
    );
    run =
        PatchRun(
            _UnusedPipeline(),
            PatchRequest(
              project: '${fixture.path}/fixture_app',
              output: '${fixture.path}/out',
              moduleId: 100,
              minBuild: 25,
            ),
            resolved,
            fixture.path,
          )
          ..config = '${fixture.path}/package_config.json'
          ..project = '${fixture.path}/fixture_app'
          ..app = 'fixture_app';
    producer = BytecodeProducer(run)
      ..compileReceipt = {
        'pinned_packages': {
          'native_plugin': {'reason': 'plugin'},
        },
      };
  });
  tearDown(() => fixture.delete(recursive: true));

  test('whole-tier input scan and remapping accept a real asset-only package without fake lib', () async {
    await producer.inputs(true);
    expect(producer.tier, 'whole');
    expect(producer.wholeOwn, contains('asset_only'));
    expect(run.facts.changedPinned, isEmpty);
    final remapped = await remapSources(
      run.config,
      '${fixture.path}/module',
      producer.wholeOwn!,
      100,
    );
    final names = remapped['names'] as Map;
    expect(names['fixture_app'], 'patch.100.fixture_app');
    expect(names.containsKey('asset_only'), isFalse);
    expect(names.containsKey('native_plugin'), isFalse);
    final config = jsonDecode(
      await File(remapped['packages'] as String).readAsString(),
    ) as Map;
    final rows = (config['packages'] as List).cast<Map>();
    expect(
      rows.singleWhere((row) => row['name'] == 'asset_only')['rootUri'],
      Directory('${fixture.path}/asset_only/lib').uri.toString(),
    );
    expect(await Directory('${fixture.path}/asset_only/lib').exists(), isFalse);
    expect(
      await Directory('${fixture.path}/module/asset_only').exists(),
      isFalse,
    );
    expect(
      await File('${fixture.path}/asset_only/assets/icon.bin').readAsString(),
      'real asset, no lib directory',
    );
  });

  test(
    'skipping asset-only sources does not bypass native plugin pin checks',
    () async {
      await File('${fixture.path}/native_plugin/lib/plugin.dart')
          .writeAsString('const pluginValue = 2;\n');
      await producer.inputs(true);
      expect(run.facts.changedPinned, contains('native_plugin'));
      expect(producer.wholeOwn, isNot(contains('native_plugin')));
      expect(
        await Directory('${fixture.path}/asset_only/lib').exists(),
        isFalse,
      );
    },
  );
}

/// TODO This input-only regression must never execute a compiler or network command.
class _UnusedPipeline implements PatchPipeline {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected pipeline command: ${invocation.memberName}');
}
